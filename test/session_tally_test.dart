import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/session_tally.dart';
import 'package:choreia/app/recorded_summary.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart' show CameraFailure;
import 'package:motion_core/motion_core.dart';

/// What a finished session is ALLOWED to claim.
///
/// The walk (`first_walk_test.dart`) proves the record reaches the disk and the
/// surface. This file pins what is IN it — the rules that decide which states
/// count as practice, which as nothing, and which number may not be written at
/// all. Kept out of the walk because a rule proved only inside a UI flow is a
/// rule nobody can find, and because these cases (a session of only-unjudgeable
/// frames, a camera that never opened) are cheap here and expensive there.
void main() {
  SessionTally tally({String lessonClass = ChoreiaLessonClass.demoOnly}) =>
      SessionTally(lessonId: 'hh_l1_bounce', lessonClass: lessonClass);

  LiveState judged() => const LiveJudged(
        result: JudgeResult(findings: <ErrorFinding>[], measurements: {}),
        gated: <GatedCheck>[],
        notMeasuredNote: '',
      );

  Duration s(int seconds) => Duration(seconds: seconds);

  group('what counts as practice', () {
    test('a camera that never delivered a frame produced NOTHING', () {
      final SessionTally t = tally();
      t.observe(const LiveIdle(), s(0));
      t.observe(const LivePermissionDenied(), s(3));
      t.observe(const LiveCameraUnavailable(CameraFailure.noSuchCamera, null),
          s(4));

      // "Never started" is not zero (M-F-268). The page reads this to decide
      // whether to write at all; a `true` here would put a 0-cycle session in
      // the learner's history that never happened.
      expect(t.sawCamera, isFalse);
      expect(t.workedSeconds, 0);
      expect(t.cyclesRead, 0);
    });

    test('the clock runs across frames we could NOT judge, not only the ones '
        'we could', () {
      // The direction is chosen, and the other one is the "you did less" lie:
      // a learner dancing in poor light produces `LiveNoPerson` for minutes,
      // and a clock that only ticks on judged cycles would record almost no
      // practice for a session that really happened.
      final SessionTally t = tally();
      t.observe(const LiveIdle(), s(0)); // before the camera: not counted
      t.observe(const LiveNoPerson(<QualityIssue>{QualityIssue.outOfFrame}),
          s(10));
      t.observe(const LiveWatching(cyclesSeen: 0), s(40));
      t.observe(judged(), s(70));

      expect(t.sawCamera, isTrue);
      expect(t.sawUnjudgeableFrames, isTrue);
      // 70 − 10: from the FIRST frame, not from when the page opened. The ten
      // seconds spent opening the camera are not practice.
      expect(t.workedSeconds, 60);
      expect(t.cyclesRead, 1);
    });

    test('POSITIVE TWIN — a clean session reports no unjudgeable frames', () {
      // Without this, `sawUnjudgeableFrames` could be hard-wired to `true` and
      // the test above would still pass. The result surface prints a whole
      // paragraph off this flag, so an always-on version would caption every
      // clean session with a warning about work that was never lost.
      final SessionTally t = tally();
      t.observe(const LiveWatching(cyclesSeen: 0), s(0));
      t.observe(judged(), s(30));
      expect(t.sawUnjudgeableFrames, isFalse);
      expect(t.cyclesRead, 1);
    });
  });

  group('what the record may say', () {
    test('unmeasured units are 0 AS A DECLARATION — this pipeline cannot '
        'produce another number', () {
      // A cycle only exists after the confidence gate accepts its frames, so
      // work lost to light or framing never becomes a countable unit. The fact
      // is not dropped: `sawUnjudgeableFrames` carries it and the result
      // surface says so in words. What must not happen is a number derived
      // from rejected FRAMES — frames are not cycles, and the ratio between
      // them is precisely what the period estimator failed to establish.
      final SessionTally t = tally();
      for (int i = 0; i < 50; i++) {
        t.observe(
            const LiveNoPerson(<QualityIssue>{QualityIssue.outOfFrame}), s(i));
      }
      t.observe(judged(), s(60));

      expect(t.sawUnjudgeableFrames, isTrue,
          reason: '50 yargılanamayan kare geldi ve bayrak bunu söylemiyor');
      expect(t.unmeasuredUnits, 0,
          reason: '50 kareden bir DÖNGÜ sayısı türetilirse o sayı uydurmadır');
      expect(t.toRecord(endedAt: DateTime.utc(2026, 8, 13)).unmeasuredUnits, 0);
    });

    test('NO DECLARED TARGET reaches the record, and `isComplete` is the '
        'consequence we accept', () {
      final SessionTally t = tally();
      t.observe(const LiveWatching(cyclesSeen: 0), s(0));
      t.observe(judged(), s(120));
      t.observe(judged(), s(180));

      final SessionRecord r = t.toRecord(endedAt: DateTime.utc(2026, 8, 13, 9));
      expect(r.plannedUnits, noDeclaredTarget);
      expect(r.unitsCompleted, 2);
      expect(r.unitLabel, choreiaUnitLabel);
      expect(r.lessonId, 'hh_l1_bounce');
      expect(r.completedAt, DateTime.utc(2026, 8, 13, 9));

      // ⚠️ NAMED, not hidden: with no target, `attempted >= planned` is true
      // for every record, so the core reads every session as complete. That is
      // why `ProgressStrings.sessionsCompleted` refuses to print "1 of 1
      // finished" when the row carries no target — the arithmetic of an absent
      // plan must not reach a learner as an achievement.
      expect(r.isComplete, isTrue,
          reason: 'hedefsiz bir kayıt için bu DAİMA true — yüzeyin bunu '
              '"bitirdin" diye okumaması gerekiyor, ve okumadığı '
              'progress_test\'te çivili');
    });

    test('the class is stored AT WRITE TIME, whatever it is', () {
      // Written, never derived later: classes change as measurement matures,
      // and a class computed after the fact silently reinterprets history.
      final SessionTally scored = tally(lessonClass: ChoreiaLessonClass.scored);
      scored.observe(judged(), s(0));
      expect(scored.toRecord(endedAt: DateTime.utc(2026)).isScoredClass, isTrue);

      final SessionTally demo = tally();
      demo.observe(judged(), s(0));
      expect(demo.toRecord(endedAt: DateTime.utc(2026)).isScoredClass, isFalse);
      expect(demo.toRecord(endedAt: DateTime.utc(2026)).lessonClass,
          ChoreiaLessonClass.demoOnly);
    });
  });
}
