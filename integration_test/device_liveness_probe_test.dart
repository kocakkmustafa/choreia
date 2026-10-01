import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/pose_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motion_core/motion_core.dart' show PoseFrame;

const String _acceptance = 'MANUAL-MOTION-DEVICE-20260818';
const String _deviceKind = String.fromEnvironment('MOTION_DEVICE_KIND');
const String _deviceId = String.fromEnvironment('MOTION_DEVICE_ID');
const int _windowSeconds =
    int.fromEnvironment('MOTION_DEVICE_WINDOW_SECONDS', defaultValue: 30);

String? _physicalDeviceFailureCode({
  required String kind,
  required String deviceId,
}) {
  final String normalizedKind = kind.trim().toLowerCase();
  final String normalizedId = deviceId.trim().toLowerCase();
  final bool suspiciousId = normalizedId.isEmpty ||
      normalizedId == 'default' ||
      normalizedId == 'auto' ||
      normalizedId.contains('simulator') ||
      normalizedId.contains('emulator') ||
      normalizedId.contains('sdk_gphone') ||
      normalizedId.contains('x86') ||
      normalizedId.contains('chrome') ||
      normalizedId.contains('macos') ||
      normalizedId.contains('localhost');
  if (normalizedKind != 'physical' || suspiciousId) {
    return 'physical_device_required';
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('physical-device preflight rejects ineligible targets before camera',
      () {
    for (final ({String kind, String id}) target
        in <({String kind, String id})>[
      (kind: '', id: ''),
      (kind: 'default', id: 'auto'),
      (kind: 'simulator', id: 'iPhone 17 Pro'),
      (kind: 'emulator', id: 'emulator-5554'),
      (kind: 'physical', id: ''),
      (kind: 'physical', id: 'default'),
      (kind: 'physical', id: 'sdk_gphone64_arm64'),
      (kind: 'physical', id: 'localhost'),
    ]) {
      expect(
        _physicalDeviceFailureCode(kind: target.kind, deviceId: target.id),
        'physical_device_required',
        reason: 'camera must not start for ${target.kind}/${target.id}',
      );
    }
  });

  test('physical-device preflight accepts an explicit hardware identifier', () {
    expect(
      _physicalDeviceFailureCode(
        kind: 'physical',
        deviceId: '00008110-001234567890801E',
      ),
      isNull,
    );
  });

  testWidgets('derived-only Choreia physical-device liveness probe',
      (WidgetTester tester) async {
    final Map<String, Object?> report = <String, Object?>{
      'sessionId':
          'choreia-device-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      'probe': 'choreia_device_liveness',
      'acceptance': _acceptance,
      'automatedAcceptance': false,
      'deviceKind': _deviceKind,
      'deviceId': _deviceId,
      'firstPoseLatencyMs': null,
      'fps': <String, Object?>{'p10': null, 'p50': null, 'p95': null},
      'validFrameRatio': null,
      'validFramePopulation': 'adapter_upright_pose_frames_only',
      'orientationCounts': <String, int>{'upright': 0},
      'orientationScope': 'CameraPoseSource exposes upright poses only',
      'thermal': <String, String>{
        'status': 'unavailable',
        'reason': 'no accepted Choreia thermal adapter in this task scope',
      },
      'failureCode': null,
    };

    final String? selectionFailure = _physicalDeviceFailureCode(
      kind: _deviceKind,
      deviceId: _deviceId,
    );
    if (selectionFailure != null || !(Platform.isIOS || Platform.isAndroid)) {
      report['failureCode'] = 'physical_device_required';
      _emit(report);
      _expectDerivedSchema(report);
      fail('physical_device_required: MOTION_DEVICE_KIND=physical and a '
          'non-empty non-simulator MOTION_DEVICE_ID must be bound before '
          'camera start on iOS or Android');
    }

    final CameraPoseSource source = CameraPoseSource();
    final Stopwatch sessionClock = Stopwatch()..start();
    final List<double> fpsSamples = <double>[];
    StreamSubscription<PoseFrame>? subscription;
    Object? streamError;
    int frameCount = 0;
    int? firstPoseLatencyMs;
    int? previousFrameAtMicros;
    String? failureCode;

    try {
      final LiveState? startState = await source.start(
        modelPath: await materialisePoseModel(),
        modelId: PoseModelPin.modelId,
      );
      if (startState is LivePermissionDenied) {
        failureCode = 'camera_permission_denied';
      } else if (startState is LiveCameraUnavailable) {
        failureCode = startState.failure.code;
      } else if (startState != null) {
        failureCode = 'camera_start_failed';
      } else {
        subscription = source.frames().listen(
          (PoseFrame frame) {
            final int nowMicros = sessionClock.elapsedMicroseconds;
            final int? previous = previousFrameAtMicros;
            if (previous != null && nowMicros > previous) {
              fpsSamples.add(1000000 / (nowMicros - previous));
            }
            previousFrameAtMicros = nowMicros;
            frameCount += 1;
            firstPoseLatencyMs ??= sessionClock.elapsedMilliseconds;
            final Map<String, int> orientations =
                report['orientationCounts']! as Map<String, int>;
            orientations['upright'] = frameCount;
          },
          onError: (Object error) => streamError = error,
        );
        await Future<void>.delayed(Duration(seconds: _windowSeconds));
        if (streamError != null) {
          failureCode = 'pose_stream_error';
        } else if (frameCount == 0) {
          failureCode = 'no_valid_pose';
        }
      }
    } on Object {
      failureCode = 'camera_or_model_start_failed';
    } finally {
      await subscription?.cancel();
      try {
        await source.stop();
      } on Object {
        // The named start/stream result remains authoritative.
      }
    }

    report['firstPoseLatencyMs'] = firstPoseLatencyMs;
    report['fps'] = <String, Object?>{
      'p10': _percentile(fpsSamples, 0.10),
      'p50': _percentile(fpsSamples, 0.50),
      'p95': _percentile(fpsSamples, 0.95),
    };
    // CameraPoseSource deliberately exposes only non-null upright poses. The
    // denominator is therefore the adapter-visible population, not raw camera
    // envelopes that this app layer is not allowed to inspect.
    report['validFrameRatio'] = frameCount == 0 ? null : 1.0;
    report['failureCode'] = failureCode;
    _emit(report);
    _expectDerivedSchema(report);
    expect(
      failureCode,
      isNull,
      reason: 'physical probe reported $failureCode; automatedAcceptance '
          'remains false even if this assertion passes',
    );
  }, timeout: Timeout(Duration(seconds: _windowSeconds + 120)));
}

double? _percentile(List<double> samples, double fraction) {
  if (samples.isEmpty) return null;
  final List<double> sorted = List<double>.of(samples)..sort();
  final double position = (sorted.length - 1) * fraction;
  final int lower = position.floor();
  final int upper = position.ceil();
  if (lower == upper) return sorted[lower];
  return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
}

void _expectDerivedSchema(Map<String, Object?> report) {
  expect(report['sessionId'], isA<String>());
  expect(report['acceptance'], _acceptance);
  expect(report['automatedAcceptance'], isFalse);
  expect(report.containsKey('firstPoseLatencyMs'), isTrue);
  expect(report['fps'], isA<Map<String, Object?>>());
  expect(report.containsKey('validFrameRatio'), isTrue);
  expect(report['orientationCounts'], isA<Map<String, int>>());
  expect(report['thermal'], isA<Map<String, String>>());
  expect(report.containsKey('failureCode'), isTrue);
}

void _emit(Map<String, Object?> report) {
  // Console-only derived JSON. No frame, landmark, image, audio, or binary
  // payload is persisted, cached, exported, uploaded, or printed.
  // ignore: avoid_print
  print(jsonEncode(report));
}
