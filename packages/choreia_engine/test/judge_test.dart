import 'dart:io';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:test/test.dart';

/// The Dart counterpart of `tools/ss_shine_footwork_liveness.py`, run against
/// the REAL artifacts rather than synthetic data — same discipline the Python
/// side established: a controlled corruption of known-good material, never an
/// invented "bad" example (M-C-01).
void main() {
  final Directory repo = _findRepoRoot();
  final File shineRef =
      File('${repo.path}/content/references/ss_shine_footwork.json');
  final File rmRef =
      File('${repo.path}/content/references/hh_running_man.json');

  // Phase bins the step config declares as its two settle moments.
  const int momentA = 1;
  const int momentB = 29;

  group('DanceReference', () {
    test('reads the built shine reference', () {
      final DanceReference ref = DanceReference.load(shineRef);
      expect(ref.step, 'ss_shine_footwork');
      expect(ref.phaseBins, 64);
      expect(ref.takeCount, 3);
      expect(ref.mirrorConfident, isTrue,
          reason: 'the 3-source rebuild resolved mirroring (M-F-115)');
      expect(ref.joints, hasLength(17));
    });

    test('KNOWN INCONSISTENCY (C-111): artifact status is null while the step '
        'config calls the same reference provisional', () {
      // Found by this test, not by inspection. build_reference.py sets
      // status=provisional ONLY when mirroring is unresolved; the 3-source
      // rebuild resolved mirroring, so status went null — even though the
      // reference is still provisional on the OTHER axis it records itself
      // (3 of 6 preferred sources, one carrying thinEvidence).
      //
      // Two records of one fact drifting apart is the C-091 defect. The fix
      // belongs in build_reference.py (widen the provisional condition) plus a
      // rebuild, NOT in a hand-patched artifact. Asserted as the CURRENT state
      // so this test fails the day it is fixed and forces the update.
      final DanceReference ref = DanceReference.load(shineRef);
      expect(ref.status, isNull,
          reason: 'when this starts failing, the fix landed — update this test '
              'and drop the C-111 note');
      expect(ref.takeCount, lessThan(6),
          reason: 'the independent reason it is still provisional');
    });

    test('scoredPhases is read per joint — a false bin carries no verdict', () {
      final DanceReference ref = DanceReference.load(shineRef);
      // Arms are coached_only on this reference; legs score at 100%.
      expect(ref.isScoredAt('left_knee', momentA), isTrue);
      expect(ref.isScoredAt('left_elbow', momentA), isFalse);
    });

    test('refuses an unbuilt artifact instead of loading partial data', () {
      expect(
        () => DanceReference.fromJson(<String, dynamic>{'built': false}),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing mirrorConfident reads as FALSE, not as probably-fine', () {
      final DanceReference ref = DanceReference.fromJson(<String, dynamic>{
        'built': true,
        'step': 's',
        'phaseBins': 2,
        'takeCount': 3,
        'reference': <String, dynamic>{'left_knee': <double>[1, 2]},
        'toleranceDeg': <String, dynamic>{'left_knee': <double>[6, 6]},
      });
      expect(ref.mirrorConfident, isFalse);
    });
  });

  group('mirroring algebra', () {
    test('mirroring NEGATES orientation angles and swaps names', () {
      final Cycle c = <String, List<double>>{
        'left_thigh': <double>[30, 30],
        'right_thigh': <double>[-20, -20],
      };
      final Cycle m = mirrorCycle(c);
      expect(m['right_thigh']!.first, -30);
      expect(m['left_thigh']!.first, 20);
    });

    test('flexion angles are swapped but NOT negated', () {
      final Cycle c = <String, List<double>>{
        'left_knee': <double>[140, 140],
        'right_knee': <double>[100, 100],
      };
      final Cycle m = mirrorCycle(c);
      expect(m['right_knee']!.first, 140);
      expect(m['left_knee']!.first, 100);
    });

    test('C-093 REGRESSION: a single left-minus-right difference is '
        'mirror-INVARIANT and therefore useless for side detection', () {
      final Cycle c = <String, List<double>>{
        'left_thigh': <double>[30],
        'right_thigh': <double>[-20],
      };
      final Cycle m = mirrorCycle(c);
      final double before = angDiff(c['left_thigh']![0], c['right_thigh']![0]);
      final double after = angDiff(m['left_thigh']![0], m['right_thigh']![0]);
      expect(after, closeTo(before, 1e-9),
          reason: 'identical by construction — this is WHY side detection uses '
              'the whole joint vector compared both ways round');
    });
  });

  group('DanceJudge on the real reference', () {
    late DanceReference ref;
    late DanceJudge judge;
    late Cycle self;

    setUp(() {
      ref = DanceReference.load(shineRef);
      judge = DanceJudge(reference: ref);
      // The reference's own consensus cycle stands in for a perfect learner.
      self = <String, List<double>>{
        for (final String j in ref.joints) j: List<double>.of(ref.angles[j]!),
      };
    });

    test('a perfect learner trips nothing', () {
      final JudgeResult r = judge.judge(self, momentA: momentA, momentB: momentB);
      expect(r.anyFired, isFalse);
      expect(r['WRONG_FOOT']!.verdict, Verdict.ok);
      expect(r['STEP_TOO_LARGE']!.verdict, Verdict.ok);
    });

    test('CONTROLLED CORRUPTION: dancing the whole step on the other foot '
        'fires WRONG_FOOT', () {
      final JudgeResult r =
          judge.judge(mirrorCycle(self), momentA: momentA, momentB: momentB);
      expect(r['WRONG_FOOT']!.fired, isTrue);
      expect(r.measurements['sideMarginDeg']!, greaterThan(minToleranceDeg),
          reason: 'the margin must clear the noise floor to justify a verdict');
    });

    test('CONTROLLED CORRUPTION: an exaggerated step fires STEP_TOO_LARGE', () {
      final Cycle wide = <String, List<double>>{
        for (final MapEntry<String, List<double>> e in self.entries)
          e.key: List<double>.of(e.value),
      };
      for (final String j in <String>['left_thigh', 'right_thigh']) {
        wide[j]![momentB] = wide[j]![momentA] + 40;
      }
      final JudgeResult r = judge.judge(wide, momentA: momentA, momentB: momentB);
      expect(r['STEP_TOO_LARGE']!.fired, isTrue);
    });

    test('measurement ALWAYS flows, even where judgement is withheld', () {
      final JudgeResult r = judge.judge(self, momentA: momentA, momentB: momentB);
      expect(r.measurements.containsKey('kneeDeltaDeg'), isTrue,
          reason: 'NO_WEIGHT_TRANSFER is blocked but its measurement is not');
      expect(r['NO_WEIGHT_TRANSFER']!.verdict, Verdict.noVerdict);
      expect(r['NO_WEIGHT_TRANSFER']!.why, contains('noiseFloor'));
    });

    test('blocked codes never fire, even on material that would trip them', () {
      final Cycle flat = <String, List<double>>{
        for (final MapEntry<String, List<double>> e in self.entries)
          e.key: List<double>.of(e.value),
      };
      // Erase the weight-transfer signal entirely: knees identical at both
      // moments. NO_WEIGHT_TRANSFER would have caught exactly this.
      for (final String j in <String>['left_knee', 'right_knee']) {
        flat[j]![momentB] = flat[j]![momentA];
      }
      final JudgeResult r = judge.judge(flat, momentA: momentA, momentB: momentB);
      expect(r['NO_WEIGHT_TRANSFER']!.fired, isFalse,
          reason: 'the block is INERT, not merely unlucky not to fire');
      expect(r.measurements['kneeDeltaDeg'], 0);
    });
  });

  group('kural-7 enforcement (M-F-117)', () {
    test('on a mirror-UNCERTAIN reference, WRONG_FOOT is never FORMED', () {
      final DanceReference rm = DanceReference.load(rmRef);
      expect(rm.mirrorConfident, isFalse,
          reason: 'hh_running_man is mirror-uncertain — the premise of this test');

      final DanceReference shine = DanceReference.load(shineRef);
      final Cycle learner = <String, List<double>>{
        for (final String j in shine.joints)
          j: List<double>.of(shine.angles[j]!),
      };

      final JudgeResult r = DanceJudge(reference: rm)
          .judge(learner, momentA: momentA, momentB: momentB);

      // Absent, not false: a consumer iterating findings cannot read a verdict
      // that was never formed. "Hiç oluşmadı" != "ateşlenmedi".
      expect(r['WRONG_FOOT'], isNull);
      expect(r.measurements.containsKey('sideMarginDeg'), isFalse);
      // The side-agnostic error still works — it does not depend on mirroring.
      expect(r['STEP_TOO_LARGE'], isNotNull);
    });
  });
}

Directory _findRepoRoot() {
  Directory d = Directory.current;
  for (int i = 0; i < 6; i++) {
    if (Directory('${d.path}/content/references').existsSync()) return d;
    d = d.parent;
  }
  throw StateError('content/references not found above ${Directory.current.path}');
}
