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

/// How far is this cycle from the reference, in SHAPE alone?
///
/// Mirror-independent by construction (best of the two orientations), because
/// identity and side are different questions: a learner on the wrong foot is
/// still doing THIS step, and must not be measured as if they were doing a
/// different one.
///
/// **REPORT-ONLY. No threshold, no verdict, no error code** (M-F-207 (i)).
/// The measurement exists so a distribution can accumulate; the gate comes
/// only once separation is MEASURED. Choreia's own numbers say why the
/// shortcut is unavailable: an in-vocabulary shine cycle sits at 15.2deg and an
/// out-of-vocabulary Running Man at 18.6deg — one measure cannot separate
/// those, and the family precedent (M-F-60(2), squat identity) needed TWO
/// signals.
double shapeDistance(Cycle learner, Cycle reference) => math.min(
      cycleDistance(learner, reference),
      cycleDistance(mirrorCycle(learner), reference),
    );

/// [shapeDistance] restricted to the leg joints.
///
/// A second candidate signal, deliberately different in kind from the first:
/// arms are styling and the references themselves disagree on them by 11-58deg,
/// so whole-body distance mixes real shape with authored noise. If a composite
/// gate is ever built, two signals that fail the same way would be one signal.
double legShapeDistance(Cycle learner, Cycle reference) {
  Cycle legsOf(Cycle c) => <String, List<double>>{
        for (final MapEntry<String, List<double>> e in c.entries)
          if (legJoints.contains(e.key)) e.key: e.value,
      };
  return shapeDistance(legsOf(learner), legsOf(reference));
}

/// The single WORST joint distance — a third candidate, sensitive where the
/// means are blunt: a step that differs in one limb only averages away.
double worstJointDistance(Cycle learner, Cycle reference) {
  double worst = 0;
  for (final String j in learner.keys) {
    final List<double>? other = reference[j];
    if (other == null) continue;
    final Cycle one = <String, List<double>>{j: learner[j]!};
    final Cycle ref = <String, List<double>>{j: other};
    final double d = shapeDistance(one, ref);
    if (d.isFinite && d > worst) worst = d;
  }
  return worst;
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

  /// THE one correction to show, or null when nothing fired.
  ///
  /// The rule ("score + ONE correction — the single most important error") is
  /// written in three places and was blocked for a long time on a reasonable
  /// objection: choosing "the most important" without a derived order is
  /// threshold-invention, and Choreia had no severity ladder like JabLab's.
  ///
  /// **It turned out not to need one.** Measured 2026-08-07: at most TWO codes
  /// can ever carry a verdict here, so this is not an n-way ranking — it is a
  /// single binary tie-break. And content had already made that call: the
  /// level-1 `unlockRule` gates progression on "zero WRONG_FOOT" and does not
  /// mention STEP_TOO_LARGE at all. [correctionPriority] READS that, it does
  /// not invent it.
  ErrorFinding? get correction {
    ErrorFinding? best;
    int bestRank = correctionPriority.length + 1;
    for (final ErrorFinding f in fired) {
      final int i = correctionPriority.indexOf(f.code);
      // An unknown code ranks LAST rather than first. If a new code is added
      // and nobody ranks it, the failure should be "it lost a tie-break", not
      // "it silently outranked the one content says blocks progression".
      // `judge_priority_test.dart` fails outright in that case, so this
      // fallback is a floor, not the plan.
      final int rank = i < 0 ? correctionPriority.length : i;
      if (rank < bestRank) {
        best = f;
        bestRank = rank;
      }
    }
    return best;
  }

  /// How many OTHER findings fired besides [correction].
  ///
  /// Surfaced as a count, never as a list: showing one correction is the rule,
  /// but letting the learner believe it was the only thing we saw would be a
  /// different claim than the rule makes. One number keeps the focus without
  /// the silence.
  int get otherFiredCount => fired.isEmpty ? 0 : fired.length - 1;
}

/// Fired codes ordered most-blocking first — the basis for [JudgeResult.correction].
///
/// **DERIVED, NOT INVENTED.** `content/styles/salsa_shines/style.json`, level 1:
///
/// > `unlockRule.description`: "3 consecutive attempts at ss_shine_footwork
/// > with shapeScore >= 0.75 and **zero WRONG_FOOT**"
///
/// WRONG_FOOT blocks progression; STEP_TOO_LARGE does not, and the rule's own
/// note explains which codes were deliberately excluded and why. Content made
/// the severity statement about exactly this pair before this list existed.
///
/// The basis is pinned by a test: if STEP_TOO_LARGE ever enters that unlock
/// rule, the derivation is void and this order must be re-derived rather than
/// defended.
const List<String> correctionPriority = <String>[
  'WRONG_FOOT',
  'STEP_TOO_LARGE',
];

/// Scores one learner cycle against a reference, for the errors that are LIVE.
///
/// Two error codes are never JUDGED here, and each says so in its own result:
///   * NO_WEIGHT_TRANSFER — calibration-blocked (threshold under the noise
///     floor, M-F-117). Its measurement is still returned.
///   * STEP_LATE — needs a beat grid; salsa's BPM is disputed.
///
/// They are emitted with [Verdict.noVerdict] and a `why`, NOT omitted. An
/// earlier version of this comment claimed the opposite ("deliberately absent")
/// while the code below already did this — the code was right and the comment
/// was stale. Reason: an absent code tells a consumer nothing, and cannot be
/// told apart from a code that was forgotten. A `noVerdict` finding says "we
/// looked, we cannot judge this, and here is why" — the same discipline the
/// surface follows by NAMING blocked gates on screen instead of hiding them.
///
/// The genuinely NEVER-FORMED case is different and lives below: under
/// `mirrorConfident == false` no WRONG_FOOT finding is created at all, because
/// there the question itself is unanswerable rather than merely uncalibrated
/// (kural-7).
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

    // STEP-IDENTITY INSTRUMENTATION — report-first (M-F-207 (i)).
    //
    // Measured on EVERY judgement, including when `mirrorConfident` is false:
    // identity is not the side question, and gating it behind the mirror flag
    // would leave the very references that need it most unmeasured.
    //
    // No code, no verdict, no threshold. Choreia currently cannot tell that a
    // learner is dancing a different step at all (measured: a hip-hop Running
    // Man cycle returns zero errors against the salsa shine reference), and
    // that limit is stated in the style's `notMeasured`. These numbers are how
    // the distribution needed to close it gets collected — not a gate wearing
    // a measurement's clothes.
    measurements['identityShapeDeg'] = shapeDistance(learner, reference.angles);
    measurements['identityLegShapeDeg'] =
        legShapeDistance(learner, reference.angles);
    measurements['identityWorstJointDeg'] =
        worstJointDistance(learner, reference.angles);

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
