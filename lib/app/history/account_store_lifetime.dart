import 'dart:async';

import 'package:motion_core/motion_core.dart';

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String appStoreOwnerFor(String? userId) {
  if (userId == null) return 'guest';
  if (!_uuid.hasMatch(userId)) {
    throw ArgumentError.value(userId, 'accountUserId', 'Expected UUID');
  }
  return userId.toLowerCase();
}

/// A page's deletion callback must not erase a later same-UUID lifetime.
final class StaleAccountDeletionException implements Exception {
  const StaleAccountDeletionException();
}

/// JSONL uses Core's public lease; Salsa operations join this same host-owned
/// lifetime through [run]. Both drain before an exact owner-file erase.
final class AppStoreOwnerTicket {
  AppStoreOwnerTicket._(this.owner);
  final String owner;
  final SessionStoreWriteLease journalLease = SessionStoreWriteLease();
  final Set<Future<void>> _pending = {};
  Future<void>? _retirement;
  final Set<Future<void> Function()> _resources = {};
  Future<void>? _resourceRetirement;
  bool get hasResourceRetirement => _resources.isNotEmpty || _resourceRetirement != null;

  Future<void> retireResources() {
    if (_resourceRetirement != null) return _resourceRetirement!;
    if (_resources.isEmpty) return Future<void>.value();
    return _resourceRetirement = Future.wait<void>([
      for (final close in _resources.toList()) Future<void>.sync(close),
    ]).then((_) {});
  }

  void registerResource(Future<void> Function() close) {
    checkActive();
    _resources.add(close);
  }

  void unregisterResource(Future<void> Function() close) => _resources.remove(close);

  bool get isActive => journalLease.isActive;

  void checkActive() {
    if (!isActive) throw const SessionStoreRetiredException();
  }

  Future<T> run<T>(Future<T> Function() action) async {
    checkActive();
    final settled = Completer<void>();
    _pending.add(settled.future);
    try {
      final value = await action();
      checkActive();
      return value;
    } finally {
      _pending.remove(settled.future);
      settled.complete();
    }
  }

  Future<void> retireAndDrain() {
    // Core retirement closes admission synchronously, including JSONL handles
    // that were opened independently for this owner.
    final journalDrain = journalLease.retireAndDrain();
    return _retirement ??= Future.wait<void>([
      journalDrain,
      retireResources(),
      ..._pending,
    ]).then((_) {});
  }
}

final class _OwnerErase {
  final Completer<void> settled = Completer<void>();
  final List<Future<void> Function()> deletions = [];
}

/// One registry belongs to the app host. Tests may supply a private registry.
/// Owner identity is captured before locating a directory; no delayed opener
/// may look up a fresh ticket after its original lifetime was retired.
final class AppStoreOwnerRegistry {
  final Map<String, AppStoreOwnerTicket> _current = {};
  final Map<String, Set<AppStoreOwnerTicket>> _tickets = {};
  final Set<String> _paused = {};
  final Set<String> _erasePending = {};
  final Map<String, _OwnerErase> _erasures = {};
  final Map<String, Future<void>> _retirements = {};
  final Set<String> _failedRetirements = {};

  Future<void>? get retirementBarrier => _retirements.isEmpty ? null :
      Future.wait<void>(_retirements.values.toList()).then((_) {});

  Future<void> _retireTickets(String owner, Iterable<AppStoreOwnerTicket> tickets) {
    final retiring = tickets.toList();
    final resources = retiring.where((ticket) => ticket.hasResourceRetirement).toList();
    final previous = _retirements[owner];
    if (previous != null) {
      return Future.wait<void>([
        previous,
        for (final ticket in retiring) ticket.retireAndDrain(),
      ]).then((_) {});
    }
    if (resources.isEmpty) {
      return Future.wait<void>([
        for (final ticket in retiring) ticket.retireAndDrain(),
      ]).then((_) {});
    }
    // Publish admission retirement before calling any app/native close hook.
    final settled = Completer<void>();
    late final Future<void> drain;
    drain = settled.future.then<void>((_) {
      if (identical(_retirements[owner], drain)) _retirements.remove(owner);
    }, onError: (Object error, StackTrace stack) {
      _failedRetirements.add(owner);
      Error.throwWithStackTrace(error, stack);
    });
    _retirements[owner] = drain;
    final dataDrain = Future.wait<void>([
      for (final ticket in retiring) ticket.retireAndDrain(),
    ]).then((_) {});
    unawaited(Future.wait<void>([
      for (final ticket in resources) ticket.retireResources(),
    ]).then<void>((_) => settled.complete(),
        onError: (Object error, StackTrace stack) => settled.completeError(error, stack)));
    return Future.wait<void>([dataDrain, drain]).then((_) {});
  }

  AppStoreOwnerTicket? currentTicket(String? userId) =>
      _current[appStoreOwnerFor(userId)];

  bool isErasing(String? userId) =>
      _erasePending.contains(appStoreOwnerFor(userId));

  AppStoreOwnerTicket capture(String? userId) {
    final owner = appStoreOwnerFor(userId);
    if (_retirements.isNotEmpty || _failedRetirements.isNotEmpty ||
        _paused.contains(owner) || _erasePending.contains(owner)) {
      throw const SessionStoreRetiredException();
    }
    final previous = _current[owner];
    if (previous != null && previous.isActive) return previous;
    if (previous != null) _forgetAfterDrain(previous);
    final ticket = AppStoreOwnerTicket._(owner);
    _current[owner] = ticket;
    (_tickets[owner] ??= {}).add(ticket);
    return ticket;
  }

  void _forgetAfterDrain(AppStoreOwnerTicket ticket) {
    unawaited(ticket.retireAndDrain().then((_) {
      if (!identical(_current[ticket.owner], ticket)) {
        _tickets[ticket.owner]?.remove(ticket);
      }
    }, onError: (Object _, StackTrace __) {
      _failedRetirements.add(ticket.owner);
    }));
  }

  Future<void> retireOwner(String? userId) {
    final owner = appStoreOwnerFor(userId);
    _paused.add(owner);
    final tickets = (_tickets[owner] ?? <AppStoreOwnerTicket>{}).toList();
    return _retireTickets(owner, tickets).then<void>((_) {
      // Only fully acknowledged lifetimes can leave the retained drain set.
      // Keep failed/pending native receipts available to a cold host.
      for (final ticket in tickets) {
        if (ticket.isActive) continue;
        _tickets[owner]?.remove(ticket);
        if (identical(_current[owner], ticket)) _current.remove(owner);
      }
    });
  }

  /// Only the host's new verified/guest route lifetime resumes admission.
  /// Recovery's false edge creates a fresh route, never revives an old ticket.
  void resumeOwner(String? userId) {
    final owner = appStoreOwnerFor(userId);
    if (_retirements.isNotEmpty || _failedRetirements.isNotEmpty) return;
    _paused.remove(owner);
    // A confirmed erase still owns the admission fence until deletion settles.
    if (!_erasePending.contains(owner)) capture(userId);
  }

  Future<void> erase(String userId, Future<void> Function() deleteFiles,
      {AppStoreOwnerTicket? expectedOwner}) {
    final owner = appStoreOwnerFor(userId);
    if (expectedOwner != null &&
        (expectedOwner.owner != owner ||
            !identical(_current[owner], expectedOwner))) {
      return Future<void>.error(const StaleAccountDeletionException());
    }
    final existing = _erasures[owner];
    if (existing != null) {
      // Course-only and whole-account clears may overlap. Join their exact
      // deletions under one fence rather than silently dropping the latter.
      existing.deletions.add(deleteFiles);
      return existing.settled.future;
    }

    final erase = _OwnerErase()..deletions.add(deleteFiles);
    _erasePending.add(owner);
    _erasures[owner] = erase; // Publish before any filesystem await.
    final retiring = (_tickets[owner] ?? <AppStoreOwnerTicket>{}).toList();
    final drain = _retireTickets(owner, retiring);
    unawaited(() async {
      try {
        await drain;
        for (var index = 0; index < erase.deletions.length; index++) {
          await erase.deletions[index]();
        }
        for (final ticket in retiring) {
          if (identical(_current[owner], ticket)) _current.remove(owner);
          _tickets[owner]?.remove(ticket);
        }
        _erasePending.remove(owner);
        erase.settled.complete();
      } catch (error, stack) {
        // A failed exact erase remains closed to new handles. A later receipt
        // retry can retry deletion; a normal route resume cannot bypass it.
        erase.settled.completeError(error, stack);
      } finally {
        if (identical(_erasures[owner], erase)) {
          _erasures.remove(owner);
        }
      }
    }());
    return erase.settled.future;
  }
}

final AppStoreOwnerRegistry appStoreOwners = AppStoreOwnerRegistry();
