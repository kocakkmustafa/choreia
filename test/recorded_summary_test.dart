import 'dart:io';

import 'package:choreia/app/recorded_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

/// What is left to test AFTER the store moved to the core.
///
/// The local `session_store_test.dart` was DELETED, not kept: the core's own
/// suite already covers every invariant it asserted (corrupt line, half-written
/// tail, unknown schema version, v1 legacy lines, no leaked `.tmp`, per-record
/// unit labels), and a second copy would be two places claiming one contract —
/// they drift, and then one of them is lying. The pinned tag is what makes that
/// safe: the contract is verified upstream AT the version Choreia consumes.
///
/// What stays here is the part Choreia actually owns:
///   * the split by class, which is THIS product's honesty rule, not the
///     family's — another app may have no such split;
///   * the ADOPTION itself: that Choreia writes the words and the unit it
///     claims to write, and that its reading never over-claims.
void main() {
  late Directory tmp;
  late SessionStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('choreia_summary_');
    store = JsonlSessionStore(File('${tmp.path}/sessions.jsonl'));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  SessionRecord rec({
    String lesson = 'ss_l1_footwork',
    String klass = ChoreiaLessonClass.scored,
    int worked = 300,
    int units = 8,
    int planned = 8,
    int unmeasured = 0,
    String? unmeasuredReason,
  }) =>
      SessionRecord(
        lessonId: lesson,
        completedAt: DateTime.utc(2026, 7, 30, 12),
        workedSeconds: worked,
        unitsCompleted: units,
        plannedUnits: planned,
        unitLabel: choreiaUnitLabel,
        lessonClass: klass,
        unmeasuredUnits: unmeasured,
        unmeasuredReason: unmeasuredReason,
      );

  group('adoption — Choreia writes what it says it writes', () {
    test('the unit is the CYCLE, and it round-trips', () async {
      await store.append(rec());
      expect((await store.recent()).single.unitLabel, 'cycle');
      expect(choreiaUnitLabel, 'cycle',
          reason: 'dance has no time box; the cycle is already this repo unit '
              'of measurement (cyclesInSegment, cyclesPerTake)');
    });

    test('Choreia class words survive the open vocabulary', () async {
      await store.append(rec(klass: ChoreiaLessonClass.demoOnly));
      final SessionRecord r = (await store.recent()).single;
      expect(r.lessonClass, 'demoOnly');
      expect(r.isScoredClass, isFalse);
    });

    test('POSITIVE TWIN — the scored word actually READS as scored', () async {
      // Added by the M-F-194 absence-gate scan, which found this the one
      // unpaired absence claim in the suite. Without it, an `isScoredClass`
      // that always returned false would pass every test: least-privilege
      // stops OVER-claiming, but a read so restrictive that nothing ever
      // counts as scored is its own defect — under-claiming every graded
      // session the product does have.
      await store.append(rec(klass: ChoreiaLessonClass.scored));
      expect((await store.recent()).single.isScoredClass, isTrue);
      expect((await RecordedSummary.from(store)).scoredSessions, 1);
    });

    test('a class Choreia never writes NEVER reads as scored', () async {
      // The open vocabulary removed the enum that used to make this
      // impossible; the safety property moved into the core's
      // least-privilege read. Asserted from HERE too, because it is the
      // property Choreia depends on — if it ever loosened upstream, this
      // product would start over-claiming grades and should find out.
      await store.append(rec(klass: 'Scored'));   // wrong case
      await store.append(rec(klass: 'gibberish'));
      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.scoredSessions, 0);
      expect(s.demoOnlySessions, 2,
          reason: 'when in doubt, claim less');
    });
  });

  group('the split by class — Choreia own honesty rule', () {
    test('counts split, and no field claims quality', () async {
      await store.append(rec(worked: 600));
      await store.append(rec(klass: ChoreiaLessonClass.demoOnly, worked: 300));
      await store.append(rec(
          klass: ChoreiaLessonClass.demoOnly, worked: 60, units: 1, planned: 8));

      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.sessions, 3);
      expect(s.completed, 2);
      expect(s.stoppedEarly, 1);
      expect(s.scoredSessions, 1);
      expect(s.demoOnlySessions, 2,
          reason: '"you completed 3 lessons" would hide that two are never '
              'graded — the surface needs the split to stay honest');
      expect(s.workedSeconds, 960);
    });

    test('demoOnly sessions DO earn completion marks', () async {
      await store.append(rec(klass: ChoreiaLessonClass.demoOnly));
      expect((await RecordedSummary.from(store)).completed, 1,
          reason: 'completion is a MEASUREMENT; withholding it too would make '
              'the lesson second class, which is what K10 prevents');
    });

    test('duration label hides seconds', () async {
      await store.append(rec(worked: 3661));
      expect((await RecordedSummary.from(store)).workedLabel, '1h 1m');
    });

    test('empty history summarises to zeros without throwing', () async {
      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.sessions, 0);
      expect(s.workedLabel, '0 min');
      expect(s.unmeasuredUnits, 0);
    });
  });

  group('unmeasured cycles reach the summary', () {
    test('an unmeasurable cycle is COUNTED, not dropped', () async {
      await store.append(rec(
          units: 7, planned: 8, unmeasured: 1, unmeasuredReason: 'framing'));
      final RecordedSummary s = await RecordedSummary.from(store);
      expect(s.unmeasuredUnits, 1,
          reason: 'dropping it would let the screen say "7 of 8" for a session '
              'where the learner danced 8 — silence lies');
      expect(s.completed, 1,
          reason: 'completion counts ATTEMPTS: a cycle we could not analyse '
              'still happened, and must not lower the learner progress');
    });
  });
}
