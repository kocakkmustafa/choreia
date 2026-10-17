import 'dart:async';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:motion_core/motion_core.dart';

import 'live_state.dart';
import 'dance_runtime.dart';

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
    this.provider,
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
  final DanceProviderBinding? provider;
  final ConfidenceGate _gate;

  // Geometry comes from the core, unchanged. Two copies of an angle
  // definition drift and one of them starts lying (M-F-03).
  final PoseNormalizer _normalizer;
  final JointAngleExtractor _angles;

  late final DanceAssessmentGate assessmentGate =
      DanceAssessmentGate.forReference(reference);

  bool get isScored =>
      lessonClass == 'scored' &&
      assessmentGate.allowsScoring &&
      provider?.allowsScoring != false;

  /// Checks this lesson cannot make, derived FROM CONTENT.
  ///
  /// `status: blocked` in the step's own error list is the source of truth.
  /// The user-facing sentence is written here rather than taken from
  /// `blockedBy`, because `blockedBy` is engineering provenance —
  /// "beatsStatus:PENDING" says nothing to a dancer (C-117's rule: the raw
  /// technical string never reaches the surface, a generic honest sentence
  /// does).
  List<GatedCheck> gatedChecks() {
    final List<GatedCheck> out = <GatedCheck>[
      if (provider != null)
        const GatedCheck(
            code: 'CALIBRATION_REQUIRED',
            why:
                'Dance assessment needs independent calibration. These camera observations do not confirm a correct step, beat timing or physical weight transfer.'),
    ];
    if (lessonClass == 'scored' && !assessmentGate.allowsScoring) {
      out.add(const GatedCheck(
        code: 'ASSESSMENT_UNVALIDATED',
        why: 'You can practise this movement, but its camera assessment has '
            'not been validated. These observations do not confirm that '
            'you performed the step correctly.',
      ));
    }
    for (final Object? e
        in (stepConfig['errors'] as List<Object?>? ?? const [])) {
      if (e is! Map) continue;
      final Object? status = e['status'];
      final bool blocked = status is String && status.startsWith('blocked');
      if (!blocked) continue;
      final String code = '${e['code']}';
      out.add(GatedCheck(code: code, why: _whyFor(code)));
    }

    // RUNTIME SUPPRESSION IS ALSO A GATE (C-179).
    //
    // The loop above reads CONFIG: `status: blocked` in the step document.
    // kural-7 suppresses a check at RUNTIME instead — when a reference cannot
    // resolve left from right, no WRONG_FOOT finding is FORMED at all. That is
    // the right engine behaviour and it was invisible here: a check nobody
    // performs was reaching neither the verdict list nor the "what we are NOT
    // checking" list.
    //
    // A defensive mechanism that produces SILENCE instead of a stated limit is
    // the same defect as a defensive default that produces a positive verdict
    // — both let an unmeasured thing pass as settled. The surface would have
    // said "Nothing we check came out wrong this time" while a named check was
    // quietly skipped.
    //
    // Today no scored lesson runs on a mirror-uncertain reference
    // (`ss_shine_footwork` is mirrorConfident:true), so this adds nothing to
    // the live screen right now. It is written before the case exists because
    // the case is one content change away — every hip-hop reference is
    // mirrorConfident:false.
    if (!reference.mirrorConfident &&
        !out.any((GatedCheck g) => g.code == 'WRONG_FOOT')) {
      out.add(GatedCheck(code: 'WRONG_FOOT', why: _whyFor('WRONG_FOOT')));
    }
    return out;
  }

  static String _whyFor(String code) => switch (code) {
        // Reached only through the runtime branch above: this code is never
        // `status: blocked` in config, because whether it can be judged
        // depends on the REFERENCE, not on the step.
        'WRONG_FOOT' => 'We are not checking which foot you start on. The '
            'measured reference does not distinguish left and right reliably '
            'for this movement, so calling your starting foot wrong would be '
            'a coin flip presented as a judgement.',
        // NOT a deferral. There is no beat grid for this style at all, so
        // this is a MISSING MEASUREMENT, not a late one — and the sentence has
        // to carry that class (M-F-287). "yet" sold a structural absence as a
        // schedule.
        'STEP_LATE' => 'We do not check your timing. Doing that honestly needs '
            'the beat of the music pinned down, and for this style it is not — '
            'so rather than guess at a count and blame you for our own '
            'uncertainty, we leave timing out and say so.',
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
      'would not say "wrong step". A reading or a lack of findings here is not '
      'proof that you practiced this step.';

  /// Drive the session from a source of pose frames.
  ///
  /// The source is injected rather than constructed here, which is what makes
  /// the whole chain testable without a device: the e2e test feeds recorded
  /// frames through the SAME code the camera drives (replay is the only
  /// verification path this project accepts for camera work).
  Stream<LiveState> run(Stream<PoseFrame> frames) async* {
    yield const LiveIdle();

    if (provider?.diagnosticAngles == false) {
      yield LiveObservationUnavailable(
          provider!.status == DanceCapabilityStatus.unsupported
              ? ObservationBlocker.unsupported
              : ObservationBlocker.incompatible);
      return;
    }
    final CyclePeriodEstimator estimator = CyclePeriodEstimator();
    final List<JointAngleVector> window = <JointAngleVector>[];
    int cyclesSeen = 0;
    int? previousUs;

    await for (final PoseFrame frame in frames) {
      final previous = previousUs;
      previousUs = frame.tUs;
      // Never infer a continuously observed cycle over a missing/reordered
      // interval. 250 ms is an input continuity ceiling, not dance accuracy.
      if (frame.tUs < 0 ||
          (previous != null &&
              (frame.tUs <= previous || frame.tUs - previous > 250000))) {
        window.clear();
        yield const LiveObservationUnavailable(
            ObservationBlocker.clockDiscontinuity);
        continue;
      }
      final FrameQuality quality = _gate.evaluate(frame);
      if (!quality.judgeable) {
        // A cycle must be continuously observed. Joining visible fragments
        // across missing feet/occlusion would invent the unseen movement.
        window.clear();
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
      if (cycle == null || assessmentGate.cycleIssues(cycle).isNotEmpty) {
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

  int _moment(String id) =>
      resolveScoredMomentBin(stepConfig, reference.phaseBins, id);

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

/// Resolves a scored-moment label (`'a'`/`'b'`) to its phase bin, by
/// cross-referencing `scoredMoments[].phase` against `phases[].id` →
/// `phases[].enter.phaseBin` — the SAME resolution `test/end_to_end_test.dart`
/// and `test/fallback_liveness_test.dart` already do by hand when deriving
/// their own `momentA`/`momentB` (their comment: "a copy of a threshold in a
/// test is a second source of truth"). This file had silently grown its OWN,
/// wrong copy.
///
/// Extracted as a free function (rather than a private method) so it is
/// testable without constructing a full [LiveSession] — no `Stream<PoseFrame>`
/// chain needed, see `test/live_session_test.dart`.
///
/// PREVIOUSLY this looked for `phaseBin` directly ON the `scoredMoments`
/// entry — a key the content schema never puts there
/// (`content/SCHEMA.md`: `scoredMoments[]` is `{id, phase, beat, label}`).
/// The lookup ALWAYS missed, for every style, and fell straight to the
/// arbitrary default below. Measured against real content this session:
/// for `ss_shine_footwork` the correct bins are `settle_a`→1, `settle_b`→29
/// (of 64); the old code silently returned 0 and 32 instead — close enough
/// to look plausible, wrong enough to matter once this style's BPM gate
/// opens and its live path is actually exercised by a user.
///
/// Still falls to the SAME arbitrary default when the named phase has no
/// `phaseBin` — true today for `hip_hop_foundations`'s phases, which are
/// live-FSM-style gates (`metric`/`op`/`valueDeg`, entered in real time as
/// frames arrive) rather than fixed positions in an already-resampled
/// replay cycle. There is no bin for this function to find there; that is
/// a separate, larger, known gap (DEFTER C-319), not something this fix
/// resolves.
int resolveScoredMomentBin(
  Map<String, dynamic> stepConfig,
  int phaseBins,
  String label,
) {
  String? phaseId;
  for (final Object? m
      in (stepConfig['scoredMoments'] as List<Object?>? ?? const [])) {
    if (m is Map && '${m['label']}' == label) {
      phaseId = m['phase'] as String?;
      break;
    }
  }
  if (phaseId != null) {
    for (final Object? p
        in (stepConfig['phases'] as List<Object?>? ?? const [])) {
      if (p is Map && p['id'] == phaseId) {
        final Object? enter = p['enter'];
        if (enter is Map) {
          final Object? bin = enter['phaseBin'];
          if (bin is int) return bin;
        }
        break;
      }
    }
  }
  return label == 'a' ? 0 : phaseBins ~/ 2;
}
