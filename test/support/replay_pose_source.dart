import 'dart:math' as math;

import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:motion_core/motion_core.dart';

/// A [PoseSource] that replays generated frames instead of opening a camera.
///
/// **Replay is not a convenience, it is this project's only accepted
/// verification path for camera work** — `LiveSession` has taken a
/// `Stream<PoseFrame>` since it was written for exactly this reason. What was
/// missing was a source the *page* could accept; this is it.
///
/// [refusal] lets the twin case be driven too: a source that refuses is what a
/// denied camera looks like from the page's side, and the page must reach a
/// different screen for it.
class ReplayPoseSource implements PoseSource {
  ReplayPoseSource({required this.make, this.count = 90, this.refusal});

  final List<PoseLandmark> Function(int i) make;
  final int count;
  final LiveState? refusal;

  bool started = false;
  bool stopped = false;

  @override
  Future<LiveState?> begin() async {
    started = true;
    return refusal;
  }

  @override
  Stream<PoseFrame> frames() => framesFrom(make, count);

  @override
  Future<void> stop() async => stopped = true;
}

/// A frame stream on a monotonic clock, 30 fps.
Stream<PoseFrame> framesFrom(List<PoseLandmark> Function(int i) make, int n) =>
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
List<PoseLandmark> Function(int) blankBody() =>
    (int i) => List<PoseLandmark>.generate(
          33,
          (int _) => const PoseLandmark.invisible(),
        );

/// A body oscillating with a ~1 s period — enough structure for the core's
/// period estimator to find a cycle.
///
/// **Shared rather than copied.** `live_path_test.dart` grew this generator
/// first; the walk needs the same dancer, and two copies of a fixture drift
/// until one of them is quietly testing a different body (M-F-03).
List<PoseLandmark> Function(int) dancingBody() => (int i) {
      final double t = i / 30.0;
      final double sway = 0.04 * math.sin(2 * math.pi * t);
      PoseLandmark at(double x, double y) => PoseLandmark(x + sway, y, 0, 0.95);
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
