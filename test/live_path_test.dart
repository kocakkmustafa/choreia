import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:choreia/app/live/live_session.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

/// LIVE CAMERA PATH — verified WITHOUT a device.
///
/// The session takes a `Stream<PoseFrame>`, so these tests drive the exact
/// code the camera drives; only the source differs. That is the whole reason
/// `CameraPoseSource` is a separate class (replay is this project's only
/// accepted verification path for camera work).
///
/// SCOPE THESE TESTS PIN, in the coordinator's words:
///   · beat-dependent verdicts stay GATED and are NAMED, never silent
///   · a demoOnly lesson cannot leak a score, even live
///   · permission / camera-unavailable / no-person are TYPED, not a blank
void main() {
  late DanceReference reference;
  late Map<String, dynamic> shineStep;
  late DanceJudge judge;

  setUpAll(() {
    reference = DanceReference.fromJson(jsonDecode(
        File('content/references/ss_shine_footwork.json')
            .readAsStringSync()) as Map<String, dynamic>);
    shineStep = jsonDecode(File(
                'content/styles/salsa_shines/steps/ss_shine_footwork.json')
            .readAsStringSync())
        as Map<String, dynamic>;
    judge = DanceJudge(reference: reference);
  });

  LiveSession session(String lessonClass) => LiveSession(
        reference: reference,
        stepConfig: shineStep,
        lessonClass: lessonClass,
        judge: judge,
      );

  group('gated checks come FROM CONTENT', () {
    test('STEP_LATE is gated, and the reason is in USER language', () {
      final List<GatedCheck> gated = session('scored').gatedChecks();
      final GatedCheck late =
          gated.firstWhere((GatedCheck g) => g.code == 'STEP_LATE');

      // The dancer-facing sentence must not leak engineering provenance.
      expect(late.why, isNot(contains('beatsStatus')));
      expect(late.why, isNot(contains('PENDING')));
      expect(late.why.toLowerCase(), contains('timing'));
      expect(late.why.toLowerCase(), contains('beat'));
    });

    test('POSITIVE TWIN — a check that is NOT blocked is NOT gated', () {
      final Set<String> codes = session('scored')
          .gatedChecks()
          .map((GatedCheck g) => g.code)
          .toSet();
      // WRONG_FOOT ships live (status: live, M-F-117). If it appeared here,
      // the gate would be reporting everything and the first test would pass
      // for the wrong reason.
      expect(codes, isNot(contains('WRONG_FOOT')));
      expect(codes, contains('STEP_LATE'));
      expect(codes, contains('NO_WEIGHT_TRANSFER'));
    });

    test('the gate is DERIVED, not a list in the code', () {
      // Flip the content and the gate must follow. A hardcoded list would go
      // stale the day the founder's beat tap lands and STEP_LATE unblocks.
      final Map<String, dynamic> unblocked =
          jsonDecode(jsonEncode(shineStep)) as Map<String, dynamic>;
      for (final Object? e in unblocked['errors'] as List<Object?>) {
        if (e is Map && e['code'] == 'STEP_LATE') e.remove('status');
      }
      final LiveSession s = LiveSession(
        reference: reference,
        stepConfig: unblocked,
        lessonClass: 'scored',
        judge: judge,
      );
      expect(s.gatedChecks().map((GatedCheck g) => g.code),
          isNot(contains('STEP_LATE')),
          reason: 'content unblocked it; the live path must stop gating it');
    });
  });

  group('typed honest states', () {
    test('no judgeable person => LiveNoPerson, never a zero score', () async {
      final List<LiveState> states =
          await session('scored').run(_frames(_blank(), 12)).toList();
      expect(states.whereType<LiveNoPerson>(), isNotEmpty);
      // The critical negative: nothing scored the empty room.
      expect(states.whereType<LiveJudged>(), isEmpty);
      expect(states.whereType<LiveMeasured>(), isEmpty);
    });

    test('POSITIVE TWIN — a real dancing body DOES get past the gate',
        () async {
      final List<LiveState> states =
          await session('scored').run(_frames(_dancer(), 90)).toList();
      // Without this twin, a session that emitted LiveNoPerson unconditionally
      // would satisfy the test above.
      expect(states.whereType<LiveNoPerson>(), isEmpty,
          reason: 'a visible, well-tracked body must not read as absent');
      expect(states.length, greaterThan(1));
    });
  });

  group('demoOnly cannot leak a score — structurally', () {
    test('a demoOnly lesson never produces LiveJudged', () async {
      final List<LiveState> states =
          await session('demoOnly').run(_frames(_dancer(), 90)).toList();
      expect(states.whereType<LiveJudged>(), isEmpty,
          reason: 'kural-8: a demo-only lesson has no judgement to leak');
      for (final LiveMeasured m in states.whereType<LiveMeasured>()) {
        // The type has no band and no findings field at all — this asserts
        // what it DOES carry, so the guarantee is visible in a test too.
        expect(m.notMeasuredNote, isNotEmpty);
      }
    });

    test('the identity limit is carried onto the LIVE surface', () {
      // C-120's measured limit, in the dancer's language: nothing here checks
      // that you are dancing THIS step.
      expect(LiveSession.notMeasuredNote.toLowerCase(),
          contains('would not say'));
      expect(LiveSession.notMeasuredNote.toLowerCase(),
          contains('wrong step'));
    });
  });
}

/// A frame stream on a monotonic clock, 30 fps.
Stream<PoseFrame> _frames(List<PoseLandmark> Function(int i) make, int n) =>
    Stream<PoseFrame>.fromIterable(<PoseFrame>[
      for (int i = 0; i < n; i++)
        PoseFrame(
          tUs: i * 33333,
          landmarks: make(i),
          modelVersion: 'fixture+pose_landmarker_full',
        ),
    ]);

/// Nothing trackable: every landmark at zero visibility. The failure mode a
/// real empty room produces, not a synthetic "absent" flag.
List<PoseLandmark> Function(int) _blank() => (int i) => List<PoseLandmark>.generate(
      33,
      (int _) => const PoseLandmark.invisible(),
    );

/// A body oscillating with a ~1 s period — enough structure for the core's
/// period estimator to find a cycle.
List<PoseLandmark> Function(int) _dancer() => (int i) {
      final double t = i / 30.0;
      final double sway = 0.04 * math.sin(2 * math.pi * t);
      PoseLandmark at(double x, double y) =>
          PoseLandmark(x + sway, y, 0, 0.95);
      return <PoseLandmark>[
        for (int k = 0; k < 33; k++)
          switch (k) {
            11 => at(0.42, 0.38), // shoulders
            12 => at(0.58, 0.38),
            13 => at(0.38, 0.50),
            14 => at(0.62, 0.50),
            15 => at(0.36, 0.60),
            16 => at(0.64, 0.60),
            23 => at(0.45, 0.60), // hips
            24 => at(0.55, 0.60),
            25 => at(0.44, 0.75 + sway), // knees
            26 => at(0.56, 0.75 - sway),
            27 => at(0.43, 0.90), // ankles
            28 => at(0.57, 0.90),
            _ => at(0.50, 0.50),
          },
      ];
    };
