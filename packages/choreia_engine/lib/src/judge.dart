import 'dart:math' as math;

import 'reference.dart';

/// Joint names whose value is a SIGNED orientation (where a limb points), as
/// opposed to an unsigned flexion angle. Mirroring negates these as well as
/// swapping their left/right names — getting that wrong is silent, which is
/// why it lives in one place (mirrored by build_reference.py's ORIENTATION_JOINTS).
const Set<String> orientationJoints = <String>{
  'left_upper_arm', 'right_upper_arm', 'left_forearm', 'right_forearm',
  'left_thigh', 'right_thigh', 'left_shin', 'right_shin', 'trunk_tilt',
};

const Set<String> legJoints = <String>{
  'left_hip', 'right_hip', 'left_knee', 'right_knee',
  'left_thigh', 'right_thigh', 'left_shin', 'right_shin',
};

/// This pipeline's landmark-jitter floor, in degrees.
///
/// Any decision line BELOW this cannot distinguish signal from tracking noise.
/// It is the constant that blocked NO_WEIGHT_TRANSFER (M-F-117): a 1.0 deg
/// threshold inside a 6 deg noise floor is wrong whether it fires or stays
/// silent. Kept as one named constant so a future threshold gets checked
/// against it instead of rediscovering the lesson.
const double minToleranceDeg = 6.0;

/// Shortest signed difference a-b in (-180, 180].
double angDiff(double a, double b) => (a - b + 180.0) % 360.0 - 180.0;

String mirrorJoint(String name) {
  if (name.startsWith('left_')) return 'right_${name.substring(5)}';
  if (name.startsWith('right_')) return 'left_${name.substring(6)}';
  return name;
}

/// One cycle of a learner's movement, resampled onto the reference's phase axis.
typedef Cycle = Map<String, List<double>>;

Cycle mirrorCycle(Cycle cycle) {
  final Cycle out = <String, List<double>>{};
  cycle.forEach((String k, List<double> v) {
    out[mirrorJoint(k)] = orientationJoints.contains(k)
        ? v.map((double x) => -x).toList(growable: false)
        : List<double>.of(v);
  });
  return out;
}

/// Mean absolute angular distance over shared joints and phases.
double cycleDistance(Cycle a, Cycle b) {
  double total = 0;
  int count = 0;
  for (final String j in a.keys) {
    final List<double>? other = b[j];
    if (other == null) continue;
    final bool circular = orientationJoints.contains(j);
    final int n = math.min(a[j]!.length, other.length);
    for (int i = 0; i < n; i++) {
      final double d = circular
          ? angDiff(a[j]![i], other[i]).abs()
          : (a[j]![i] - other[i]).abs();
      total += d;
      count++;
    }
  }
  return count == 0 ? double.infinity : total / count;
}

/// Which side is the learner dancing on, relative to the reference?
///
/// WHY THIS IS NOT A SINGLE-NUMBER MEASURE — the mistake is easy and silent,
/// so the reason is kept next to the code (C-093): a signed left-minus-right
/// difference at one phase bin is INVARIANT under mirroring, because mirroring
/// both swaps the names and negates the values. The first implementation did
/// exactly that and returned a bit-identical -6.43 deg for a deliberately
/// mirrored clip. Only the WHOLE joint vector, compared both ways round,
/// carries the information.
final class SideAgreement {
  const SideAgreement({
    required this.matchesReferenceSide,
    required this.directDeg,
    required this.mirroredDeg,
    required this.confident,
  });

  final bool matchesReferenceSide;
  final double directDeg;
  final double mirroredDeg;

  /// False when the two orientations fit within the noise floor of each other
  /// — what a genuinely left/right-symmetric movement looks like. The question
  /// is then unanswerable, and NO verdict is emitted.
  final bool confident;

  double get marginDeg => (mirroredDeg - directDeg).abs();

  static SideAgreement of(Cycle learner, Cycle reference) {
    final double direct = cycleDistance(learner, reference);
    final double flipped = cycleDistance(mirrorCycle(learner), reference);
    return SideAgreement(
      matchesReferenceSide: direct <= flipped,
      directDeg: direct,
      mirroredDeg: flipped,
      confident: (flipped - direct).abs() >= minToleranceDeg,
    );
  }
}

/// A judgement the engine is willing to publish, or an explicit refusal.
///
/// `noVerdict` is a first-class outcome, not an error and not a zero: "I did
/// not look" and "you did it badly" are different statements and the surface
/// has to be able to tell them apart (the ölçülemedi != başarısızlık rule).
enum Verdict { ok, error, noVerdict }

final class ErrorFinding {
  const ErrorFinding(this.code, this.verdict, {this.why, this.measuredDeg});

  final String code;
  final Verdict verdict;

  /// Why there is no verdict — required whenever [verdict] is noVerdict, so a
  /// refusal is never silent.
  final String? why;
  final double? measuredDeg;

  bool get fired => verdict == Verdict.error;
}

/// The measurement/judgement split, in one object.
///
/// M-F-71's contract: measurement ALWAYS flows, judgement is separate and may
/// be withheld. [measurements] is populated even when every error returns
/// noVerdict — that is what lets a progress surface show "recorded" facts
/// without implying a score.
final class JudgeResult {
  const JudgeResult({required this.measurements, required this.findings});

  final Map<String, double> measurements;
  final List<ErrorFinding> findings;

  Iterable<ErrorFinding> get fired => findings.where((ErrorFinding f) => f.fired);
  bool get anyFired => fired.isNotEmpty;

  ErrorFinding? operator [](String code) =>
      findings.where((ErrorFinding f) => f.code == code).firstOrNull;
}

/// Scores one learner cycle against a reference, for the errors that are LIVE.
///
/// Two error codes are deliberately absent from this engine and their absence
/// is checked by tests rather than trusted:
///   * NO_WEIGHT_TRANSFER — calibration-blocked (threshold under the noise
///     floor, M-F-117). Its measurement is still returned.
///   * STEP_LATE — needs a beat grid; salsa's BPM is disputed.
/// "Not computed" is stronger than "computed and suppressed": a consumer
/// cannot read a verdict that was never formed.
final class DanceJudge {
  const DanceJudge({
    required this.reference,
    this.stepTooLargeMaxDeg = 20.0,
  });

  final DanceReference reference;
  final double stepTooLargeMaxDeg;

  JudgeResult judge(Cycle learner, {required int momentA, required int momentB}) {
    final Map<String, double> measurements = <String, double>{};
    final List<ErrorFinding> findings = <ErrorFinding>[];

    double maxDelta(String left, String right) {
      double best = 0;
      for (final String j in <String>[left, right]) {
        final List<double>? s = learner[j];
        if (s == null || momentA >= s.length || momentB >= s.length) continue;
        final bool circular = orientationJoints.contains(j);
        final double d = circular
            ? angDiff(s[momentB], s[momentA]).abs()
            : (s[momentB] - s[momentA]).abs();
        best = math.max(best, d);
      }
      return best;
    }

    // Measured over BOTH legs rather than "the loaded leg": picking a leg
    // would need a side call, and this measure has to hold regardless of
    // mirrorConfident.
    final double kneeDelta = maxDelta('left_knee', 'right_knee');
    final double thighDelta = maxDelta('left_thigh', 'right_thigh');
    measurements['kneeDeltaDeg'] = kneeDelta;
    measurements['thighDeltaDeg'] = thighDelta;

    findings.add(ErrorFinding(
      'STEP_TOO_LARGE',
      thighDelta > stepTooLargeMaxDeg ? Verdict.error : Verdict.ok,
      measuredDeg: thighDelta,
    ));

    // NO_WEIGHT_TRANSFER: measured, never judged. The measurement is above.
    findings.add(const ErrorFinding(
      'NO_WEIGHT_TRANSFER',
      Verdict.noVerdict,
      why: 'calibration-blocked: threshold(1.0deg) < noiseFloor(6.0deg) — a '
          'decision line inside landmark jitter cannot tell a light weight '
          'transfer from tracking noise (M-F-117)',
    ));

    findings.add(const ErrorFinding(
      'STEP_LATE',
      Verdict.noVerdict,
      why: 'no beat grid: this style\'s bpmRange is unresolved (DISPUTED), so '
          'timing cannot be judged without risking a 2x-wrong grid',
    ));

    // The side-dependent path, gated on the reference's own honesty flag.
    if (reference.mirrorConfident) {
      final SideAgreement side = SideAgreement.of(learner, reference.angles);
      measurements['sideDirectDeg'] = side.directDeg;
      measurements['sideMirroredDeg'] = side.mirroredDeg;
      measurements['sideMarginDeg'] = side.marginDeg;
      findings.add(side.confident
          ? ErrorFinding(
              'WRONG_FOOT',
              side.matchesReferenceSide ? Verdict.ok : Verdict.error,
              measuredDeg: side.marginDeg,
            )
          : ErrorFinding(
              'WRONG_FOOT',
              Verdict.noVerdict,
              why: 'orientation costs within the noise floor '
                  '(${minToleranceDeg}deg): direct ${side.directDeg.toStringAsFixed(2)} '
                  'vs mirrored ${side.mirroredDeg.toStringAsFixed(2)} — a '
                  'left/right-symmetric movement, the question is unanswerable',
              measuredDeg: side.marginDeg,
            ));
    }
    // else: no WRONG_FOOT finding AT ALL. Not suppressed — never formed
    // (kural-7). A consumer iterating findings cannot encounter it.

    return JudgeResult(measurements: measurements, findings: findings);
  }
}
