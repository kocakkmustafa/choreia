import 'dart:async';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:motion_core/motion_core.dart';

import 'live_state.dart';

/// Turns camera frames into honest live readings for ONE lesson.
///
/// The chain: camera envelopes → `PoseFrame` → joint angles → a cycle on the
/// reference's phase axis → `DanceJudge` → a state the surface can render.
/// Everything upstream of the judge comes from `motion_core`; nothing in this
/// file re-implements geometry or segmentation (M-F-03).
///
/// THIS IS THE ENGINE PIN'S NAMED RE-ENTRY (C-121). The pin was DROPPED when
/// measurement showed the engine imported nothing from the core, with the
/// trigger written down as "the first real import day, probably the camera
/// bridge". This is that day, and the pin came back as a PAIR at one commit
/// (J-071, `test/pin_equality_test.dart`).
///
/// WHAT THIS DELIBERATELY DOES NOT DO
///
/// Beat-dependent verdicts stay closed. Two independent reasons, and either
/// alone would be enough:
///   1. CONTENT: the step declares them blocked — `STEP_LATE` carries
///      `blockedBy: beatsStatus:PENDING — no beat grid to be late against`.
///      The gate is read from content, never from a list in this file: a
///      hardcoded list goes stale the day the founder's beat tap lands.
///   2. CLOCK: `CameraFrameEnvelope.clock` may be `ClockDomain.unknown`
///      (Android vendors that pick their own zero). The core's own contract
///      says such a stream must NOT be fused with the audio/beat clock
///      without a measured offset. So even with a beat grid, timing verdicts
///      would need that measurement first.
/// Blocked checks are not hidden — they surface as [GatedCheck] with a
/// user-language reason.
final class LiveSession {
  LiveSession({
    required this.reference,
    required this.stepConfig,
    required this.lessonClass,
    required this.judge,
    ConfidenceGate? gate,
  })  : _gate = gate ?? ConfidenceGate.forVariant(PoseModelVariant.full),
        _normalizer = PoseNormalizer(),
        _angles = const JointAngleExtractor();

  final DanceReference reference;

  /// The step document, read for its OWN declarations — blocked checks,
  /// phase driver, error vocabulary.
  final Map<String, dynamic> stepConfig;

  /// `'scored'` or anything else. Anything else means demo-only, and the
  /// safety property lives in exactly one place (the core's `isScoredClass`
  /// reasoning): only `'scored'` reads as scored, so an unknown class can
  /// never over-claim.
  final String lessonClass;

  final DanceJudge judge;
  final ConfidenceGate _gate;

  // Geometry comes from the core, unchanged. Two copies of an angle
  // definition drift and one of them starts lying (M-F-03).
  final PoseNormalizer _normalizer;
  final JointAngleExtractor _angles;

  bool get isScored => lessonClass == 'scored';

  /// Checks this lesson cannot make, derived FROM CONTENT.
  ///
  /// `status: blocked` in the step's own error list is the source of truth.
  /// The user-facing sentence is written here rather than taken from
  /// `blockedBy`, because `blockedBy` is engineering provenance —
  /// "beatsStatus:PENDING" says nothing to a dancer (C-117's rule: the raw
  /// technical string never reaches the surface, a generic honest sentence
  /// does).
  List<GatedCheck> gatedChecks() {
    final List<GatedCheck> out = <GatedCheck>[];
    for (final Object? e in (stepConfig['errors'] as List<Object?>? ?? const [])) {
      if (e is! Map) continue;
      final Object? status = e['status'];
      final bool blocked = status is String && status.startsWith('blocked');
      if (!blocked) continue;
      final String code = '${e['code']}';
      out.add(GatedCheck(code: code, why: _whyFor(code)));
    }
    return out;
  }

  static String _whyFor(String code) => switch (code) {
        'STEP_LATE' => 'We are not checking your timing yet. Getting that '
            'right needs the beat of the music pinned down first, and we '
            'have not measured it — so rather than guess, we are leaving '
            'timing out and telling you.',
        'NO_WEIGHT_TRANSFER' => 'We are not checking whether your weight '
            'really lands on the stepping foot. The difference we would be '
            'looking for is smaller than what the camera can reliably see, '
            'so any answer would mostly be our own noise.',
        _ => 'This check is switched off for now, and we would rather say so '
            'than let you assume it passed.',
      };

  /// The honest limit of a live reading, in user language.
  ///
  /// Carries the measured step-identity boundary (C-120) onto the live
  /// surface: nothing in this chain asks "is this THE step" — every check
  /// asks "how did you do the step". The canary in the engine tests fails the
  /// day an identity gate lands, and this sentence is updated with it.
  static const String notMeasuredNote =
      'One thing we are not doing: checking that the move you are dancing is '
      'the one this lesson teaches. If you danced something else entirely, we '
      'would not say "wrong step" — we would just fail to find anything wrong.';

  /// Drive the session from a source of pose frames.
  ///
  /// The source is injected rather than constructed here, which is what makes
  /// the whole chain testable without a device: the e2e test feeds recorded
  /// frames through the SAME code the camera drives (replay is the only
  /// verification path this project accepts for camera work).
  Stream<LiveState> run(Stream<PoseFrame> frames) async* {
    yield const LiveIdle();

    final CyclePeriodEstimator estimator = CyclePeriodEstimator();
    final List<JointAngleVector> window = <JointAngleVector>[];
    int cyclesSeen = 0;

    await for (final PoseFrame frame in frames) {
      final FrameQuality quality = _gate.evaluate(frame);
      if (!quality.judgeable) {
        // "We cannot see you" — never scored as zero.
        // `issue` is nullable and single: a frame is rejected for ONE named
        // reason, and the surface says which.
        yield LiveNoPerson(<QualityIssue>{
          if (quality.issue != null) quality.issue!,
        });
        continue;
      }

      window.add(_angles.extract(_normalizer.normalize(frame)));
      final CyclePeriodEstimate estimate = estimator.estimate(window);
      if (!estimate.measured) {
        yield LiveWatching(cyclesSeen: cyclesSeen);
        continue;
      }

      final Cycle? cycle = _resample(window, estimate);
      if (cycle == null) {
        yield LiveWatching(cyclesSeen: cyclesSeen);
        continue;
      }
      cyclesSeen++;

      yield _read(cycle);
      window.clear();
    }
  }

  /// Judge one cycle and shape it into the state this lesson is ALLOWED to
  /// produce.
  ///
  /// The demo-only branch returns a type with no band and no findings field
  /// at all. Not a filtered list — a different type. A filter is a rule
  /// somebody can forget; a missing field is a compile error.
  LiveState _read(Cycle cycle) {
    final List<GatedCheck> gated = gatedChecks();
    final Set<String> gatedCodes = gated.map((GatedCheck g) => g.code).toSet();

    final JudgeResult raw = judge.judge(
      cycle,
      momentA: _moment('a'),
      momentB: _moment('b'),
    );

    if (!isScored) {
      return LiveMeasured(
        measurements: raw.measurements,
        gated: gated,
        notMeasuredNote: notMeasuredNote,
      );
    }

    // A blocked check must never reach the learner AS A VERDICT, even if the
    // engine formed one. Belt and braces on purpose: the engine already keeps
    // blocked codes at `noVerdict`, and if that ever regresses this filter is
    // what stops a timing verdict from appearing while the beat grid is still
    // disputed.
    final JudgeResult filtered = JudgeResult(
      measurements: raw.measurements,
      findings: raw.findings
          .where((ErrorFinding f) => !gatedCodes.contains(f.code))
          .toList(growable: false),
    );
    return LiveJudged(
      result: filtered,
      gated: gated,
      notMeasuredNote: notMeasuredNote,
    );
  }

  int _moment(String id) {
    for (final Object? m
        in (stepConfig['scoredMoments'] as List<Object?>? ?? const [])) {
      if (m is Map && '${m['label']}' == id) {
        final Object? bin = m['phaseBin'];
        if (bin is int) return bin;
      }
    }
    return id == 'a' ? 0 : reference.phaseBins ~/ 2;
  }

  /// Resample the observed window onto the reference's phase axis.
  ///
  /// Returns null when the window cannot honestly fill the axis — a partially
  /// filled cycle judged as if complete is a judgement about frames we never
  /// saw.
  Cycle? _resample(List<JointAngleVector> window, CyclePeriodEstimate est) {
    final int bins = reference.phaseBins;
    final int period = est.periodFrames;
    if (period < 2 || window.length < period) return null;

    final List<JointAngleVector> last =
        window.sublist(window.length - period, window.length);
    final Cycle out = <String, List<double>>{};
    for (final String joint in reference.joints) {
      final List<double> series = <double>[];
      for (int b = 0; b < bins; b++) {
        final double at = b * period / bins;
        final int i = at.floor().clamp(0, period - 1);
        final double? v = last[i].byId(joint);
        if (v == null) return null; // missing joint: no invented number
        series.add(v);
      }
      out[joint] = series;
    }
    return out;
  }
}
