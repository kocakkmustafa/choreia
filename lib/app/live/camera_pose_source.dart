import 'dart:async';

import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'live_state.dart';
import 'pose_model.dart';

/// Everything the live page needs from a source of poses.
///
/// **Extracted so the live page can be WALKED.** `LiveSession` was already
/// replay-driven — it takes a `Stream<PoseFrame>` and runs identically under a
/// fixture and under a device. The PAGE was not: it constructed a
/// [CameraPoseSource] inline, so the one screen where a lesson actually
/// happens could not be entered by any test, and the navigability measurement
/// had to list it as unreachable WITH A REASON rather than walk it.
///
/// This is Lissom's `8843a30` shape, measured rather than copied: the bridge
/// there was not a new pattern either — it was a screen that could not reach a
/// seam the rest of the code already had. Same here, one layer up.
abstract interface class PoseSource {
  /// Acquire whatever this source needs and start producing frames.
  ///
  /// Returns the typed refusal, or `null` for "started". Everything a real
  /// camera needs to locate first (the pose model on disk) belongs to the
  /// IMPLEMENTATION — a caller that had to materialise a model before opening
  /// a fixture would be doing device work to replay a recording.
  Future<LiveState?> begin();

  Stream<PoseFrame> frames();

  /// Retire both active capture and any pending [begin] acquisition.
  Future<void> stop();
}

/// Materialises the bundled model before entering the native camera bridge.
final class DeviceCameraPoseSource implements PoseSource {
  DeviceCameraPoseSource({
    CameraPoseSource? camera,
    Future<String> Function()? modelPathOpener,
  })  : _camera = camera ?? CameraPoseSource(),
        _modelPathOpener = modelPathOpener ?? materialisePoseModel;

  final CameraPoseSource _camera;
  final Future<String> Function() _modelPathOpener;
  int _generation = 0;

  @override
  Future<LiveState?> begin() async {
    final generation = ++_generation;
    final captureLease = _camera.prepareForStart();
    try {
      final path = await _modelPathOpener();
      if (generation != _generation) return const LiveInterrupted();
      return await _camera.start(
          modelPath: path,
          modelId: PoseModelPin.modelId,
          captureLease: captureLease);
    } on Object catch (error) {
      if (generation != _generation) return const LiveInterrupted();
      return LiveCameraUnavailable(CameraFailure.modelLoadFailed, '$error');
    }
  }

  @override
  Stream<PoseFrame> frames() => _camera.frames();

  @override
  Future<void> stop() {
    _generation++;
    return _camera.stop();
  }
}

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
      : _controller = controller ?? MotionCameraController() {
    // Allocate before the page can request permission or materialize a model.
    _lease = _controller.createCaptureLease();
  }

  final MotionCameraController _controller;
  late CameraCaptureLease _lease;
  CameraCaptureLease? _closingLease;
  Future<void>? _closing;
  static Future<void>? _shutdown;
  // A new wrapper/controller must not bypass uncertain native closure.
  static CameraException? _closureFailure;
  int _generation = 0;
  CameraSessionInfo? _session;
  CameraSessionInfo? get session => _session;

  /// Capture this ticket before awaiting the model. An old ticket is never
  /// rebound to a replacement lease when its delayed result arrives.
  CameraCaptureLease prepareForStart() {
    if (_lease.isRetired) {
      _lease = _controller.createCaptureLease();
      _session = null;
    }
    return _lease;
  }

  Future<LiveState?> start({
    required String modelPath,
    required String modelId,
    CameraLens lens = CameraLens.front,
    CameraCaptureLease? captureLease,
  }) async {
    final generation = ++_generation;
    final lease = captureLease ?? prepareForStart();
    bool active() =>
        generation == _generation &&
        identical(lease, _lease) &&
        !lease.isRetired;
    while (true) {
      final pending = _shutdown;
      if (pending == null) break;
      await pending;
      if (!active()) return const LiveInterrupted();
      if (identical(_shutdown, pending)) break;
    }
    if (!active()) return const LiveInterrupted();
    final closureFailure = _closureFailure;
    if (closureFailure != null) {
      return LiveCameraUnavailable(
          closureFailure.failure, closureFailure.detail);
    }
    try {
      final session = await lease.start(
        modelPath: modelPath,
        modelId: modelId,
        lens: lens,
      );
      if (!active()) return const LiveInterrupted();
      _session = session;
      return null;
    } on CameraException catch (error) {
      // A rejected lease can close only itself; it never issues legacy stop.
      _publishClosure(lease);
      if (generation != _generation) return const LiveInterrupted();
      if (error.failure == CameraFailure.permissionDenied) {
        return const LivePermissionDenied();
      }
      return LiveCameraUnavailable(error.failure, error.detail);
    } on Object {
      // Core retires on every start failure, including unknown platform errors.
      // Publish that exact closure before another wrapper can acquire a camera.
      _publishClosure(lease);
      rethrow;
    }
  }

  /// Retirement is synchronous. The returned Future still exposes failure;
  /// the global barrier observes it immediately to avoid an unhandled error.
  Future<void> stop() {
    _generation++;
    final lease = _lease;
    lease.retire();
    return _publishClosure(lease);
  }

  Future<void> _publishClosure(CameraCaptureLease lease) {
    if (identical(_closingLease, lease)) return _closing!;
    _closingLease = lease;
    final previous = _shutdown;
    final run = _closeLease(lease);
    _closing = run;
    final observed =
        run.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    final barrier = Future.wait<void>([
      if (previous != null) previous,
      observed,
    ]).then((_) {});
    _shutdown = barrier;
    unawaited(barrier.then((_) {
      if (identical(_shutdown, barrier)) _shutdown = null;
    }));
    return run;
  }

  Future<void> _closeLease(CameraCaptureLease lease) async {
    try {
      await lease.close();
    } on CameraException catch (error) {
      _closureFailure = error;
      rethrow;
    } on Object {
      _closureFailure = const CameraException(CameraFailure.closeUncertain,
          'Capture closure could not be verified.');
      throw _closureFailure!;
    } finally {
      if (identical(lease, _lease)) _session = null;
    }
  }

  /// Only the owned local frame bus is consumed. A late app subscription
  /// cancellation cannot clear a successor's native EventChannel handler.
  Stream<PoseFrame> frames() => _lease
      .frames()
      .where((envelope) => envelope.ran(BodyOrientation.upright))
      .map((envelope) => envelope.pass(BodyOrientation.upright))
      .where((PoseFrame? frame) => frame != null)
      .cast<PoseFrame>();

  bool get clockFusableWithAudio =>
      _session != null && _session!.clockDomain == ClockDomain.monotonic;
}
