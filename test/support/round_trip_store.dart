import 'dart:convert';

import 'package:motion_core/motion_core.dart';

/// An in-memory store that keeps records **through the shipping line format**.
///
/// WHY NOT THE REAL `JsonlSessionStore` HERE — measured, not preferred.
/// Real disk IO does not complete under `flutter_test`'s fake clock, so the
/// write needs `runAsync`; and letting real time pass in a test that has built
/// `ChoreiaType` widgets resumes `google_fonts`' suspended runtime-fetch
/// attempt, which `flutter_test_config` deliberately forbids. The walk then
/// fails on a font, not on the flow. (`google_fonts`' packaging stance is a
/// FOUNDER item — B5 — so the fix cannot be to allow the fetch.)
///
/// WHAT KEEPS THIS FROM BEING A LIE. *A test double that does not enforce the
/// real thing's rule proves nothing.* So every record goes through
/// `jsonEncode(record.toJson())` and comes back through
/// `SessionRecord.fromJson` — the exact two calls `JsonlSessionStore.append`
/// and its reader make. A record the disk would reject is rejected here, in
/// the same place, for the same reason.
///
/// WHAT IT STILL DOES NOT PROVE: the atomic tmp+rename, the corrupt-line
/// counting, and the first-launch missing-file branch. Those are the real
/// store's own, they have their own tests (`history_integrity_test`), and the
/// walk hands its record to the real store in `disk round trip` below.
class RoundTripStore implements SessionStore {
  final List<String> lines = <String>[];

  @override
  Future<void> append(SessionRecord record) async => lines.add(jsonEncode(
      <String, dynamic>{'v': JsonlSessionStore.schemaVersion, ...record.toJson()}));

  List<SessionRecord> get records => <SessionRecord>[
        for (final String l in lines)
          SessionRecord.fromJson((jsonDecode(l) as Map).cast<String, dynamic>()),
      ];

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => records;

  @override
  Future<int> workedSecondsFor(String lessonId) async => records
      .where((SessionRecord r) => r.lessonId == lessonId)
      .fold<int>(0, (int a, SessionRecord r) => a + r.workedSeconds);

  @override
  Future<int> unreadableRecords() async => 0;
}
