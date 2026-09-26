import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'course/salsa_progress.dart';

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

/// Pass this to the shared account page's `clearLocalData(userId)` callback.
/// The explicit id prevents deletion from ever targeting the guest journal.
Future<void> clearLocalHistoryFor(String accountUserId,
    {Directory? supportDirectory}) async {
  final Directory support =
      supportDirectory ?? await getApplicationSupportDirectory();
  await SalsaProgressStore.clearAccount(accountUserId,
      supportDirectory: support);
  final File file = sessionFileFor(support, accountUserId);
  await _deleteRegularFileIfPresent(file);
  await _deleteRegularFileIfPresent(File('${file.path}.tmp'));
}
