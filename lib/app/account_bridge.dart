import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:motion_account/motion_account.dart';

import 'course/salsa_progress.dart';
import 'history/account_store_lifetime.dart';

/// Must match `MotionApp.choreia.name` when the shared account package is pinned.
const String motionAppId = 'choreia';

/// The existing guest journal keeps its path. Signing in never copies it into
/// an account journal; moving guest history requires a separate user choice.
const String guestSessionsFileName = 'sessions.jsonl';

final RegExp _accountIdPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String sessionFileNameFor(String? accountUserId) {
  if (accountUserId == null) return guestSessionsFileName;
  if (!_accountIdPattern.hasMatch(accountUserId)) {
    throw ArgumentError.value(accountUserId, 'accountUserId', 'Expected UUID');
  }
  return 'sessions-$motionAppId-${accountUserId.toLowerCase()}.jsonl';
}

File sessionFileFor(Directory support, String? accountUserId) =>
    File('${support.path}/${sessionFileNameFor(accountUserId)}');

/// Core's confirmation dialog pins a UUID; this route wrapper also pins the
/// host lifetime and actual Session. Reject stale initiation before Core RPC,
/// including same-UUID replacement between dialog open and confirmation.
class OwnerBoundMotionAccountClient extends MotionAccountClient {
  OwnerBoundMotionAccountClient(
    this._inner, {
    required AppStoreOwnerTicket? expectedOwner,
    AppStoreOwnerRegistry? owners,
  })  : _initiatingSession = _inner.supabase.auth.currentSession,
        _expectedOwner = expectedOwner,
        _owners = owners ?? appStoreOwners,
        super(
            supabase: _inner.supabase,
            app: _inner.app,
            emailRedirectTo: _inner.emailRedirectTo);
  final MotionAccountClient _inner;
  final Object? _initiatingSession;
  final AppStoreOwnerTicket? _expectedOwner;
  final AppStoreOwnerRegistry _owners;

  @override
  get currentUser => _inner.currentUser;
  @override
  get authChanges => _inner.authChanges;
  @override
  Future<Map<String, dynamic>?> loadProfile() => _inner.loadProfile();
  @override
  Future<void> saveDisplayName(String name) => _inner.saveDisplayName(name);
  @override
  Future<MotionMembershipStatus> membershipStatus() =>
      _inner.membershipStatus();
  @override
  Future<bool> hasActiveMembership() => _inner.hasActiveMembership();

  @override
  Future<void> deleteCommonAccount({
    Future<void> Function(String userId)? afterRemoteDelete,
  }) {
    final ticket = _expectedOwner;
    final userId = currentUser?.id;
    if (_initiatingSession == null ||
        !identical(_inner.supabase.auth.currentSession, _initiatingSession) ||
        ticket == null ||
        !ticket.isActive ||
        userId == null ||
        appStoreOwnerFor(userId) != ticket.owner ||
        !identical(_owners.currentTicket(userId), ticket)) {
      return Future<void>.error(const StaleAccountDeletionException());
    }
    return _inner.deleteCommonAccount(afterRemoteDelete: afterRemoteDelete);
  }
}

/// Lists canonical app-owned account journals and unfinished atomic writes for
/// deletion-receipt reconciliation. Guest, malformed and symlink paths are
/// ignored, including when only a crash-left `.jsonl.tmp` file remains.
Future<Iterable<String>> localHistoryAccountIds(
    {Directory? supportDirectory}) async {
  final Directory support =
      supportDirectory ?? await getApplicationSupportDirectory();
  if (!await support.exists()) return const <String>[];
  final Set<String> ids = await SalsaProgressStore.accountIds(support);
  await for (final FileSystemEntity entity
      in support.list(followLinks: false)) {
    if (entity is! File) continue;
    final String name = entity.uri.pathSegments.last;
    const String prefix = 'sessions-$motionAppId-';
    const String baseSuffix = '.jsonl';
    const String tmpSuffix = '.jsonl.tmp';
    final String suffix = name.endsWith(tmpSuffix) ? tmpSuffix : baseSuffix;
    if (!name.startsWith(prefix) || !name.endsWith(suffix)) continue;
    final String id =
        name.substring(prefix.length, name.length - suffix.length);
    if (!_accountIdPattern.hasMatch(id)) continue;
    final String canonical =
        '${sessionFileNameFor(id)}${suffix == tmpSuffix ? '.tmp' : ''}';
    if (canonical == name) ids.add(id);
  }
  return ids.toList()..sort();
}

Future<void> _deleteRegularFileIfPresent(File file) async {
  if (await FileSystemEntity.type(file.path, followLinks: false) ==
      FileSystemEntityType.file) {
    await file.delete();
  }
}

/// A data-admission fence, not an Auth or recovery decision. Only the exact
/// namespace erase below can create this notice after its registry is closed.
final class ChoreiaNamespaceFence {
  ChoreiaNamespaceFence._(this.owners, this.userId);
  final AppStoreOwnerRegistry owners;
  final String userId;
  bool get isActive => owners.isErasing(userId);
}

/// Pass this to the shared account page's `clearLocalData(userId)` callback.
/// The explicit id prevents deletion from ever targeting the guest journal.
/// A confirmed UUID erase is account-wide across all its data epochs. Keep a
/// captured ticket for before-RPC initiation, not for an acknowledged receipt.
Future<void> clearLocalHistoryFor(
  String accountUserId, {
  Directory? supportDirectory,
  Future<Directory> Function()? directoryResolver,
  AppStoreOwnerRegistry? owners,
  AppStoreOwnerTicket? expectedOwner,
  void Function(ChoreiaNamespaceFence fence)? onNamespaceFenced,
}) {
  try {
    // Validate and close admission before locating the directory. This also
    // fences an opener whose directory request is still pending.
    sessionFileNameFor(accountUserId);
    final registry = owners ?? appStoreOwners;
    final acceptsTicket = expectedOwner == null ||
        (expectedOwner.owner == appStoreOwnerFor(accountUserId) &&
            identical(registry.currentTicket(accountUserId), expectedOwner));
    final erasing = registry.erase(accountUserId, () async {
      final support = supportDirectory ??
          await (directoryResolver ?? getApplicationSupportDirectory)();
      final file = sessionFileFor(support, accountUserId);
      final courseFile = File(
          '${support.path}/${SalsaProgressStore.fileNameFor(accountUserId)}');
      for (final exactFile in [
        file,
        File('${file.path}.tmp'),
        courseFile,
        File('${courseFile.path}.tmp')
      ]) {
        await _deleteRegularFileIfPresent(exactFile);
      }
    }, expectedOwner: expectedOwner);
    if (acceptsTicket && registry.isErasing(accountUserId) &&
        onNamespaceFenced != null) {
      // erase publishes the UUID fence and retires every admitted data lease
      // synchronously. Resource listeners run here before its first IO await.
      final notifying = Future<void>.sync(() => onNamespaceFenced(
          ChoreiaNamespaceFence._(registry, appStoreOwnerFor(accountUserId))));
      return Future.wait<void>([erasing, notifying]).then((_) {});
    }
    return erasing;
  } catch (error, stack) {
    return Future<void>.error(error, stack);
  }
}
