import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'account_bridge.dart';
import 'history/account_store_lifetime.dart';

/// Session identity is opaque and never emitted as diagnostics. Auth events
/// retire host resources; they never establish a verified identity.
final class ChoreiaAuthSessionEvent {
  const ChoreiaAuthSessionEvent(this.event, this.sessionIdentity);
  final String event;
  final Object? sessionIdentity;
}

/// Routes and resources close only after an actual fence in this host's data
/// registry. This controller neither verifies identities nor mutates Auth.
final class ChoreiaAccountHostController {
  Object? _binding;
  bool Function(ChoreiaNamespaceFence)? _retireNamespace;
  bool Function()? _requiresAccountRoute;

  bool get requiresAccountRoute => _requiresAccountRoute?.call() ?? false;

  bool namespaceFenced(ChoreiaNamespaceFence fence) =>
      _retireNamespace?.call(fence) ?? false;

  void _attach(Object binding, bool Function(ChoreiaNamespaceFence) retire,
      bool Function() requiresAccountRoute) {
    if (_binding != null && !identical(_binding, binding)) {
      throw StateError('Account resource controller already has a host.');
    }
    _binding = binding;
    _retireNamespace = retire;
    _requiresAccountRoute = requiresAccountRoute;
  }

  void _detach(Object binding) {
    if (!identical(_binding, binding)) return;
    _binding = null;
    _retireNamespace = null;
    _requiresAccountRoute = null;
  }
}

/// The public runtime recovery listenable is the only recovery authority.
/// Retirement runs during its notification; a fresh navigator root then
/// removes every pushed lesson/account route on the next Flutter frame.
class ChoreiaAccountHost extends StatefulWidget {
  const ChoreiaAccountHost({
    super.key,
    required this.accountUserId,
    required this.passwordRecovery,
    required this.builder,
    this.owners,
    this.authSessionChanges,
    this.initialSessionIdentity,
    this.currentSessionIdentity,
    this.identityChanges,
    this.verificationChanges,
    this.canAdmitOwner,
    this.controller,
  });
  final ValueListenable<String?> accountUserId;
  final ValueListenable<bool> passwordRecovery;
  final AppStoreOwnerRegistry? owners;
  final Stream<ChoreiaAuthSessionEvent>? authSessionChanges;
  final Object? initialSessionIdentity;
  final Object? Function()? currentSessionIdentity;
  final Listenable? identityChanges;
  final Listenable? verificationChanges;
  final bool Function()? canAdmitOwner;
  final ChoreiaAccountHostController? controller;
  final Widget Function(BuildContext context, Key navigationKey, bool recovery,
      ValueListenable<int> ownerEpoch) builder;

  @override
  State<ChoreiaAccountHost> createState() => _ChoreiaAccountHostState();
}

class _ChoreiaAccountHostState extends State<ChoreiaAccountHost> {
  int _navigationEpoch = 0;
  final ValueNotifier<int> _ownerEpoch = ValueNotifier<int>(0);
  bool _namespaceRetired = false;
  Future<void>? _pendingDrain;
  bool _drainFailed = false;
  StreamSubscription<ChoreiaAuthSessionEvent>? _authSubscription;
  String? _ownerUserId;
  Object? _sessionIdentity;
  AppStoreOwnerRegistry get _owners => widget.owners ?? appStoreOwners;

  @override
  void initState() {
    super.initState();
    _ownerUserId = widget.accountUserId.value;
    _sessionIdentity = widget.initialSessionIdentity;
    _namespaceRetired = _owners.isErasing(_ownerUserId);
    _attachController();
    widget.accountUserId.addListener(_onAccountChanged);
    widget.passwordRecovery.addListener(_onRecoveryChanged);
    widget.identityChanges?.addListener(_onIdentityChanged);
    widget.verificationChanges?.addListener(_onVerificationChanged);
    _listenToAuth();
    final inheritedDrain = _owners.retirementBarrier;
    if (inheritedDrain != null) _joinDrain(inheritedDrain);
    _admitCurrentRoute();
  }

  void _retireCurrentOwner({AppStoreOwnerRegistry? owners}) {
    _joinDrain((owners ?? _owners).retireOwner(_ownerUserId));
  }

  void _joinDrain(Future<void> current) {
    final previous = _pendingDrain;
    final drain = previous == null ? current :
        Future.wait<void>([previous, current]).then((_) {});
    _pendingDrain = drain;
    unawaited(drain.then<void>((_) {
      if (!mounted || !identical(_pendingDrain, drain)) return;
      _pendingDrain = null;
      _admitCurrentRoute();
      setState(() {});
    }, onError: (Object _, StackTrace __) {
      if (!mounted || !identical(_pendingDrain, drain)) return;
      _drainFailed = true;
      setState(() {});
    }));
  }

  void _admitCurrentRoute() {
    if (_pendingDrain != null || _drainFailed) return;
    if (_namespaceRetired || _owners.isErasing(_ownerUserId) ||
        widget.passwordRecovery.value ||
        widget.canAdmitOwner?.call() == false) {
      // Keep a closed route paused; retry only on a new identity signal.
      unawaited(_owners.retireOwner(_ownerUserId).then<void>((_) {},
          onError: (Object _, StackTrace __) {}));
    } else {
      _owners.resumeOwner(_ownerUserId);
    }
  }

  void _attachController() => widget.controller?._attach(
      this, _onNamespaceFenced,
      () => _namespaceRetired || _pendingDrain != null || _drainFailed);

  bool _onNamespaceFenced(ChoreiaNamespaceFence fence) {
    if (!mounted || !identical(fence.owners, _owners) || !fence.isActive ||
        _ownerUserId == null ||
        appStoreOwnerFor(_ownerUserId) != fence.userId) {
      return false;
    }
    if (_namespaceRetired) return true;
    // The immutable UUID fence may invalidate E+1's A resources as well as E's.
    // This is data-admission retirement, not a stale token/session callback.
    _namespaceRetired = true;
    _retireCurrentOwner();
    _resetNavigation();
    return true;
  }

  void _onAccountChanged() {
    _retireCurrentOwner();
    _ownerUserId = widget.accountUserId.value;
    _namespaceRetired = _owners.isErasing(_ownerUserId);
    _resetNavigation();
    _admitCurrentRoute();
  }

  void _onRecoveryChanged() {
    _retireCurrentOwner();
    _resetNavigation();
    _admitCurrentRoute();
  }

  void _resetNavigation() {
    // Pages hear retirement before Flutter replaces the navigator. A stale
    // dialog/client is already barred from initiating a remote request.
    _ownerEpoch.value++;
    setState(() => _navigationEpoch++);
  }

  void _onVerificationChanged() {
    // SDK events classify refresh/replacement before the proof readmission.
    scheduleMicrotask(() {
      if (!mounted || widget.canAdmitOwner?.call() == false) return;
      _admitCurrentRoute();
      setState(() {});
    });
  }

  void _onIdentityChanged() {
    _retireCurrentOwner();
    _resetNavigation();
    _admitCurrentRoute();
  }

  void _listenToAuth() {
    _authSubscription = widget.authSessionChanges?.listen((event) {
      final actual = widget.currentSessionIdentity;
      if (actual != null && !identical(event.sessionIdentity, actual())) {
        return;
      }
      // Credential refresh preserves storage lifetime. Actual Session identity
      // distinguishes a repeated event from a fresh same-token login (ABA).
      if (event.event == 'tokenRefreshed') {
        _sessionIdentity = event.sessionIdentity;
        return;
      }
      if (event.event != 'signedIn' && event.event != 'signedOut') return;
      if (event.event == 'signedIn' && event.sessionIdentity != null &&
          identical(_sessionIdentity, event.sessionIdentity)) {
        return;
      }
      _sessionIdentity = event.sessionIdentity;
      _retireCurrentOwner();
      _namespaceRetired = _owners.isErasing(_ownerUserId);
      _resetNavigation();
      _admitCurrentRoute();
    }, onError: (Object _, StackTrace __) {
      _retireCurrentOwner();
      _resetNavigation();
    });
  }

  @override
  void didUpdateWidget(covariant ChoreiaAccountHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId == widget.accountUserId &&
        oldWidget.passwordRecovery == widget.passwordRecovery &&
        oldWidget.owners == widget.owners &&
        oldWidget.authSessionChanges == widget.authSessionChanges &&
        oldWidget.identityChanges == widget.identityChanges &&
        oldWidget.verificationChanges == widget.verificationChanges &&
        oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.accountUserId.removeListener(_onAccountChanged);
    oldWidget.passwordRecovery.removeListener(_onRecoveryChanged);
    oldWidget.identityChanges?.removeListener(_onIdentityChanged);
    oldWidget.verificationChanges?.removeListener(_onVerificationChanged);
    oldWidget.controller?._detach(this);
    unawaited(_authSubscription?.cancel());
    _retireCurrentOwner(owners: oldWidget.owners ?? appStoreOwners);
    final previousOwner = appStoreOwnerFor(_ownerUserId);
    _ownerUserId = widget.accountUserId.value;
    _sessionIdentity = widget.initialSessionIdentity;
    _namespaceRetired = _owners.isErasing(_ownerUserId) ||
        (_namespaceRetired && previousOwner == appStoreOwnerFor(_ownerUserId));
    _attachController();
    widget.accountUserId.addListener(_onAccountChanged);
    widget.passwordRecovery.addListener(_onRecoveryChanged);
    widget.identityChanges?.addListener(_onIdentityChanged);
    widget.verificationChanges?.addListener(_onVerificationChanged);
    _listenToAuth();
    _ownerEpoch.value++;
    _admitCurrentRoute();
    _navigationEpoch++;
  }

  @override
  void dispose() {
    widget.accountUserId.removeListener(_onAccountChanged);
    widget.passwordRecovery.removeListener(_onRecoveryChanged);
    widget.identityChanges?.removeListener(_onIdentityChanged);
    widget.verificationChanges?.removeListener(_onVerificationChanged);
    widget.controller?._detach(this);
    unawaited(_authSubscription?.cancel());
    unawaited(_owners.retireOwner(_ownerUserId).then<void>((_) {},
          onError: (Object _, StackTrace __) {}));
    _ownerEpoch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
      context,
      ValueKey<int>(_navigationEpoch),
      widget.passwordRecovery.value,
      _ownerEpoch);
}
