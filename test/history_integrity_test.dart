import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/progress_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

import 'support/test_catalog.dart';

/// SessionStore 0.10.0 adoption: the surface READS `unreadableRecords()`.
///
/// The core can expose the number; it cannot make anyone look at it. A field
/// written and never read is a failure class this repo already named (R12), so
/// these tests assert the READING, not the existence of the field.
///
/// Every assertion here is paired. A test suite that only proves "the warning
/// appears when data is corrupt" is satisfied by a surface that warns
/// unconditionally — the twin that a CLEAN store stays silent is what makes
/// the first one mean something (M-F-194).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('choreia_integrity');
  });
  tearDown(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  SessionRecord rec(String lessonId) => SessionRecord(
        lessonId: lessonId,
        completedAt: DateTime.utc(2026, 8, 4),
        workedSeconds: 300,
        unitsCompleted: 4,
        plannedUnits: 4,
        unitLabel: 'cycle',
        lessonClass: 'demoOnly',
        unmeasuredUnits: 0,
      );

  group('three-state reading', () {
    test('POSITIVE TWIN A — a clean store reads as ok and says NOTHING', () {
      final HistoryIntegrity i =
          HistoryIntegrity.opened(unreadable: 0, readable: 3);
      expect(i.fidelity, HistoryFidelity.ok);
      // The twin that gives the others meaning: silence when there is nothing
      // to report. Without this, an always-warning surface passes every other
      // test in this file.
      expect(i.note, isNull);
      expect(i.showsTotals, isTrue);
    });

    test('POSITIVE TWIN B — partial reading SAYS SO and keeps its totals', () {
      final HistoryIntegrity i =
          HistoryIntegrity.opened(unreadable: 2, readable: 3);
      expect(i.fidelity, HistoryFidelity.partial);
      expect(i.note, isNotNull);
      // The claim that matters is "at least" — the wording that stops the
      // totals below from reading as a complete count.
      expect(i.note, contains('at least'));
      expect(i.note, contains('2'));
      expect(i.showsTotals, isTrue,
          reason: 'a partial reading still shows numbers; it stops calling '
              'them complete');
    });

    test('NONE-readable is a SEPARATE sentence from partial', () {
      final String partial =
          HistoryIntegrity.opened(unreadable: 2, readable: 3).note!;
      final String none =
          HistoryIntegrity.opened(unreadable: 2, readable: 0).note!;
      expect(none, isNot(equals(partial)));
      // Telling someone their totals are "a floor" when that floor is zero is
      // true and useless; the none-readable sentence has to say the actual
      // thing instead.
      expect(none, isNot(contains('at least')));
      expect(none, contains('not the same as'));
    });

    test('unavailable shows NO numbers at all', () {
      const HistoryIntegrity i = HistoryIntegrity.unavailable;
      expect(i.fidelity, HistoryFidelity.unavailable);
      expect(i.showsTotals, isFalse);
      expect(i.note, contains('could not open'));
    });
  });

  group('real file, real corruption', () {
    test('a store with an INJECTED corrupt line reports partial — and the '
        'summary carries it', () async {
      final File f = File('${tmp.path}/sessions.jsonl');
      final JsonlSessionStore store = JsonlSessionStore(f);
      await store.append(rec('hh_l1_bounce'));
      await store.append(rec('ss_l1_footwork'));

      // Corrupt the middle of a REAL file the store itself wrote. A synthetic
      // store returning a hard-coded count would prove the plumbing and not
      // the behaviour — the failure mode has to be the real one (C-115).
      final List<String> lines = await f.readAsLines();
      expect(lines.length, 2, reason: 'append-only, one line per session');
      await f.writeAsString('${lines.first}\n{"this is not json\n'
          '${lines.last}\n');

      final int unreadable = await store.unreadableRecords();
      expect(unreadable, 1);

      final ProgressSummary s = await ProgressSummary.from(
        store: store,
        catalog: await testCatalog(),
      );
      expect(s.integrity.fidelity, HistoryFidelity.partial);
      expect(s.integrity.unreadableRecords, 1);
      expect(s.integrity.note, contains('at least'));
      // The readable ones still made it through — a partial reading is not an
      // excuse to drop everything.
      expect(s.totals, isNotNull);
      expect(s.totals!.sessions, 2);
    });

    test('POSITIVE TWIN — the SAME file uncorrupted stays silent', () async {
      final File f = File('${tmp.path}/clean.jsonl');
      final JsonlSessionStore store = JsonlSessionStore(f);
      await store.append(rec('hh_l1_bounce'));
      await store.append(rec('ss_l1_footwork'));

      final ProgressSummary s = await ProgressSummary.from(
        store: store,
        catalog: await testCatalog(),
      );
      expect(s.integrity.fidelity, HistoryFidelity.ok);
      expect(s.integrity.note, isNull);
      expect(s.totals!.sessions, 2);
    });

    // F1 audit (H-21): the app's OWN test/ tree had no wrong-typed-JSON or
    // unknown-schema-version case — `recorded_summary_test.dart` deliberately
    // deferred both to `motion_core`'s pinned package test suite, which does
    // not run under this app's `flutter test`. Closing that gap here rather
    // than trusting the deferral: a store this app OPENS is a contract this
    // app should verify, pin or no pin.
    test(
        'SABOTAJ — GEÇERLİ JSON + YANLIŞ TİP (H-21): "as num" cast '
        '`FormatException` DEĞİL `TypeError` atar; çökmeden partial okunur',
        () async {
      final File f = File('${tmp.path}/wrong_type.jsonl');
      final JsonlSessionStore store = JsonlSessionStore(f);
      await store.append(rec('hh_l1_bounce'));
      await store.append(rec('ss_l1_footwork'));

      final List<String> lines = await f.readAsLines();
      expect(lines.length, 2);
      // Sentaks GEÇERLİ, alan TİPİ yanlış — `FormatException` bunu yakalamaz,
      // yakalayan `(j['workedSeconds'] as num)` cast'inin attığı `TypeError`.
      final Map<String, dynamic> wrongType =
          jsonDecode(lines.first) as Map<String, dynamic>;
      wrongType['workedSeconds'] = 'not-a-number';
      await f.writeAsString('${jsonEncode(wrongType)}\n${lines.last}\n');

      final int unreadable = await store.unreadableRecords();
      expect(unreadable, 1,
          reason: 'geçerli-JSON+yanlış-tip satırı ÇÖKMEMELİ, kayıp SAYILMALI');

      final ProgressSummary s = await ProgressSummary.from(
        store: store,
        catalog: await testCatalog(),
      );
      expect(s.integrity.fidelity, HistoryFidelity.partial);
      expect(s.totals, isNotNull);
      expect(s.totals!.sessions, 1,
          reason: 'sağlam kalan satır okunmaya devam etmeli');
    });

    test(
        'SABOTAJ — BİLİNMEYEN ŞEMA SÜRÜMÜ (H-21): istisna değil, adlandırılmış '
        'atlama — çökmeden kayıp sayılır', () async {
      final File f = File('${tmp.path}/unknown_version.jsonl');
      final JsonlSessionStore store = JsonlSessionStore(f);
      await store.append(rec('hh_l1_bounce'));
      await store.append(rec('ss_l1_footwork'));

      final List<String> lines = await f.readAsLines();
      final Map<String, dynamic> future =
          jsonDecode(lines.first) as Map<String, dynamic>;
      future['v'] = 999; // henüz yazılmamış, gelecekteki bir şema
      await f.writeAsString('${jsonEncode(future)}\n${lines.last}\n');

      final int unreadable = await store.unreadableRecords();
      expect(unreadable, 1,
          reason: 'gelecekteki bir şema sürümü ÇÖKMEMELİ, kayıp SAYILMALI');

      final ProgressSummary s = await ProgressSummary.from(
        store: store,
        catalog: await testCatalog(),
      );
      expect(s.integrity.fidelity, HistoryFidelity.partial);
      expect(s.totals, isNotNull);
      expect(s.totals!.sessions, 1);
    });
  });

  test('an unreadable STORE yields no totals object at all', () async {
    final ProgressSummary s = await ProgressSummary.from(
      store: _ExplodingStore(),
      catalog: await testCatalog(),
    );
    expect(s.integrity.fidelity, HistoryFidelity.unavailable);
    // Not "totals of zero" — NO totals. A zero-filled summary is what lets a
    // surface render "0 sessions" out of our own failure to open a file.
    expect(s.totals, isNull);
    expect(s.recorded, isEmpty);
  });
}

/// Fails the way a real unreadable store fails: on open, not on parse.
final class _ExplodingStore implements SessionStore {
  @override
  Future<void> append(SessionRecord record) async =>
      throw const FileSystemException('unwritable');
  @override
  Future<List<SessionRecord>> recent({int? limit}) async =>
      throw const FileSystemException('unreadable');
  @override
  Future<int> workedSecondsFor(String lessonId) async =>
      throw const FileSystemException('unreadable');
  @override
  Future<int> unreadableRecords() async =>
      throw const FileSystemException('unreadable');
}
