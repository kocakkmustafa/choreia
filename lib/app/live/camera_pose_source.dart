import 'dart:async';

import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'live_state.dart';

/// Opens the camera and turns its envelopes into `PoseFrame`s.
///
/// Kept OUT of [LiveSession] on purpose: the session takes a
/// `Stream<PoseFrame>` and therefore runs identically under a recorded
/// fixture and under a real device. That split is what makes camera work
/// verifiable without a device — replay is the only verification path this
/// project accepts, and a session that opened its own camera could not be
/// replayed at all.
///
/// This file is also the reason the `motion_camera` dependency is REAL. An
/// unused dependency is not free: C-121 measured one blocking an adoption
/// through pub's solver, and the pin was dropped for exactly that.
final class CameraPoseSource {
  CameraPoseSource({MotionCameraController? controller})
      : _controller = controller ?? MotionCameraController();

  final MotionCameraController _controller;

  CameraSessionInfo? _session;
  CameraSessionInfo? get session => _session;

  /// Start the camera, or return the typed refusal.
  ///
  /// Returns a [LiveState] rather than throwing: every failure the plugin
  /// names is a state this app already has to render, and converting an
  /// exception into a screen at the call site is how one of them ends up
  /// silently swallowed. `null` means "started, no refusal".
  Future<LiveState?> start({
    required String modelPath,
    required String modelId,
    CameraLens lens = CameraLens.front,
  }) async {
    try {
      _session = await _controller.start(
        modelPath: modelPath,
        modelId: modelId,
        lens: lens,
      );
      return null;
    } on CameraException catch (e) {
      // Permission gets its OWN state: it is the single failure the user can
      // fix, and it routes to a different screen than "this device cannot".
      if (e.failure == CameraFailure.permissionDenied) {
        return const LivePermissionDenied();
      }
      return LiveCameraUnavailable(e.failure, e.detail);
    }
  }

  Future<void> stop() async {
    try {
      await _controller.stop();
    } on CameraException {
      // Already stopped is not a failure worth surfacing: the caller asked
      // for "not running" and that is the state it is in.
    } finally {
      _session = null;
    }
  }

  /// Envelopes → `PoseFrame`, the only shape the rest of the app knows.
  ///
  /// The clock domain is CARRIED, not assumed. `ClockDomain.unknown` means
  /// the platform would not guarantee a shared timebase (an Android vendor
  /// picking its own zero); such a stream is still internally consistent, so
  /// shape and phase work — but fusing it with an audio/beat clock without a
  /// measured offset is the bug class the core explicitly warns about. It is
  /// the SECOND independent reason timing verdicts stay gated here, alongside
  /// the content's own `beatsStatus: PENDING`.
  /// Only the UPRIGHT pass is consumed today. The envelope can carry several
  /// orientation passes; picking one here rather than averaging is deliberate
  /// — a blended pose is a pose nobody struck. Frames with no upright pass
  /// are DROPPED rather than substituted, so `LiveNoPerson` comes from the
  /// confidence gate seeing nothing, not from a filled-in guess.
  Stream<PoseFrame> frames() => _controller
      .frames()
      .map((CameraFrameEnvelope e) => e.pass(BodyOrientation.upright))
      .where((PoseFrame? f) => f != null)
      .cast<PoseFrame>();

  /// Whether this session's clock may be fused with a beat grid.
  ///
  /// False both when unknown AND when there is no session — "we have not
  /// looked" must not read as "yes".
  bool get clockFusableWithAudio =>
      _session != null && _session!.clockDomain == ClockDomain.monotonic;
}
