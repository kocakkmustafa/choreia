import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/live/dance_runtime.dart';
import 'package:choreia/app/live/dance_timeline.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/live/live_session.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/pose_model.dart';
import 'package:choreia/app/live/session_tally.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

import 'support/replay_pose_source.dart';
import 'support/test_catalog.dart';

class _BytesBundle extends CachingAssetBundle {
  _BytesBundle(this.bytes);
  final Uint8List bytes;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(bytes);
}

class _MissingRuntime extends DiskBundle {
  @override
  Future<ByteData> load(String key) => key == DanceRuntimeManifest.path
      ? Future.error(StateError('Missing runtime'))
      : super.load(key);
}

void main() {
  final source = File(DanceRuntimeManifest.path).readAsStringSync();
  final referenceBytes =
      File('content/references/hh_bounce.json').readAsBytesSync();
  final stepBytes =
      File('content/styles/hip_hop_foundations/steps/hh_bounce.json')
          .readAsBytesSync();
  final reference = DanceReference.fromJson(
      jsonDecode(utf8.decode(referenceBytes)) as Map<String, dynamic>);
  final step = jsonDecode(utf8.decode(stepBytes)) as Map<String, dynamic>;

  DanceProviderBinding bind(DanceRuntimeManifest manifest,
          {String id = 'hh_bounce', Uint8List? bytes}) =>
      manifest.bind(
          stepId: id,
          referenceBytes: bytes ?? referenceBytes,
          stepBytes: stepBytes);
  String altered(void Function(Map<String, dynamic>) mutate) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    mutate(json);
    return jsonEncode(json);
  }

  test('production manifest allows diagnostics, never trained judgments', () {
    final binding = bind(DanceRuntimeManifest.parse(source));
    expect(binding.status, DanceCapabilityStatus.calibrationRequired);
    expect(binding.diagnosticAngles, isTrue);
    expect([
      binding.stepIdentity,
      binding.beatTiming,
      binding.physicalSupport,
      binding.allowsScoring
    ], everyElement(isFalse));
  });
  test('unknown movement is explicitly unsupported', () {
    expect(bind(DanceRuntimeManifest.parse(source), id: 'line_dance').status,
        DanceCapabilityStatus.unsupported);
  });
  test('tampered reference closes diagnostics', () {
    final binding = bind(DanceRuntimeManifest.parse(source),
        bytes: Uint8List.fromList([1]));
    expect(binding.status, DanceCapabilityStatus.incompatible);
    expect(binding.diagnosticAngles, isFalse);
  });
  for (final field in [
    'schemaVersion',
    'providerProtocol',
    'modelId',
    'modelSha256',
    'calibration',
    'evaluation'
  ]) {
    test('incompatible $field cannot fall back or activate scoring', () {
      final changed = altered(
          (json) => json[field] = field == 'schemaVersion' ? 2 : 'unreviewed');
      expect(() => DanceRuntimeManifest.parse(changed), throwsA(anything));
    });
  }
  test('duplicate or promoted task cannot be admitted by metadata alone', () {
    expect(
        () => DanceRuntimeManifest.parse(altered(
            (j) => (j['tasks'] as List).add((j['tasks'] as List).first))),
        throwsFormatException);
    expect(
        () => DanceRuntimeManifest.parse(
            altered((j) => (j['tasks'] as List).first['status'] = 'validated')),
        throwsFormatException);
  });
  test('missing bundle manifest closes diagnostics with a typed reason',
      () async {
    final binding = await DanceRuntimeManifest.loadBinding(
        bundle: _MissingRuntime(),
        stepId: 'hh_bounce',
        stepPath: 'content/styles/hip_hop_foundations/steps/hh_bounce.json');
    expect(binding.status, DanceCapabilityStatus.incompatible);
  });
  testWidgets('incompatible live route does not acquire camera or permission',
      (tester) async {
    final replay = ReplayPoseSource(make: blankBody());
    var permissionCalls = 0;
    await tester.pumpWidget(MaterialApp(
        home: LiveLessonPage(
      stepId: 'hh_bounce',
      lessonId: 'hh_l1_bounce',
      lessonClass: 'demoOnly',
      env: LiveEnvironment(
          bundle: _MissingRuntime(),
          source: () => replay,
          cameraPermissionRequest: () async {
            permissionCalls++;
            return true;
          }),
    )));
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('versions do not match'), findsOneWidget);
    expect(replay.started, isFalse);
    expect(permissionCalls, 0);
    expect(find.byKey(const Key('live.finish')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('discontinuous camera timestamps never form a partial cycle', () async {
    final original = await framesFrom(dancingBody(), 3).toList();
    final frames = [
      original[0],
      PoseFrame(
          tUs: 900000,
          landmarks: original[1].landmarks,
          modelVersion: original[1].modelVersion),
      PoseFrame(tUs: 900000, landmarks: original[2].landmarks)
    ];
    final states = await LiveSession(
            reference: reference,
            stepConfig: step,
            lessonClass: 'scored',
            judge: DanceJudge(reference: reference))
        .run(Stream.fromIterable(frames))
        .toList();
    expect(states.whereType<LiveObservationUnavailable>(), hasLength(2));
    expect(states.whereType<LiveMeasured>(), isEmpty);
    expect(states.whereType<LiveJudged>(), isEmpty);
    final tally = SessionTally(lessonId: 'hh_l1_bounce', lessonClass: 'scored');
    for (final state in states) {
      tally.observe(state, const Duration(seconds: 1));
    }
    expect(tally.cyclesRead, 0);
  });

  group('model materialization', () {
    late Directory dir;
    setUp(() async =>
        dir = await Directory.systemTemp.createTemp('choreia-model-test-'));
    tearDown(() async => dir.delete(recursive: true));
    test('wrong bundled bytes are never installed', () async {
      await expectLater(
          materialisePoseModel(
              supportDirectory: dir,
              bundle: _BytesBundle(Uint8List.fromList([1, 2, 3]))),
          throwsFormatException);
      expect(dir.listSync(), isEmpty);
    });
    test('corrupt versioned cache is rejected and preserved for diagnosis',
        () async {
      final cached = File('${dir.path}/pose-${PoseModelPin.sha256}.task');
      await cached.writeAsBytes([1, 2, 3]);
      await expectLater(
          materialisePoseModel(supportDirectory: dir), throwsFormatException);
      expect(await cached.readAsBytes(), [1, 2, 3]);
    });
    test('pinned local model is installed atomically and checked on reuse',
        () async {
      final bytes = File(PoseModelPin.assetPath).readAsBytesSync();
      final path = await materialisePoseModel(
          supportDirectory: dir, bundle: _BytesBundle(bytes));
      expect(File(path).lengthSync(), bytes.length);
      expect(await materialisePoseModel(supportDirectory: dir), path);
      expect(dir.listSync(), hasLength(1));
    });
  });

  group('clock mapping: synthetic contract only', () {
    late DanceTimeline timeline;
    const c = DanceClockCalibration(
        cameraClockId: 'camera-a',
        presentationClockId: 'audio-a',
        cameraToPresentationUs: 100000,
        uncertaintyUs: 1000,
        maxUncertaintyUs: 2000,
        validUntilUs: 10000000);
    setUp(() {
      timeline = DanceTimeline(
          durationUs: 2000000, beatsUs: [0, 500000, 1000000, 1500000]);
      timeline.anchor(presentationUs: 1000000, mediaUs: 0, clockId: 'audio-a');
    });
    DanceTimingObservation observe(
            {int cameraUs = 1150000,
            int? epoch,
            int now = 1300000,
            DanceClockCalibration? calibration = c,
            String clock = 'camera-a'}) =>
        timeline.observe(
            cameraUs: cameraUs,
            cameraClockId: clock,
            resultEpoch: epoch ?? timeline.epoch,
            nowPresentationUs: now,
            maxResultAgeUs: 100000,
            calibration: calibration);
    test('measured offset maps a phase; never establishes correct dance', () {
      final result = observe();
      expect(result.status, DanceTimingStatus.aligned);
      expect(result.mediaUs, 250000);
      expect(result.beat, 1);
      expect(result.phase, .5);
      expect(result.confirmsCorrectStep, isFalse);
    });
    test('unknown clock or missing offset abstains', () {
      expect(observe(clock: 'unknown').status,
          DanceTimingStatus.calibrationRequired);
      expect(observe(calibration: null).status,
          DanceTimingStatus.calibrationRequired);
    });
    test('pause and seek invalidate in-flight observations; resume reanchors',
        () {
      final epoch = timeline.epoch;
      timeline.invalidate();
      expect(observe(epoch: epoch).status, DanceTimingStatus.stale);
      expect(observe().status, DanceTimingStatus.paused);
      timeline.anchor(
          presentationUs: 1000000, mediaUs: 500000, clockId: 'audio-a');
      expect(observe().mediaUs, 750000);
    });
    test('excessive latency, future frames and duplicate frames abstain', () {
      expect(observe(now: 1400000).status, DanceTimingStatus.stale);
      expect(observe(now: 1200000).status, DanceTimingStatus.stale);
      expect(observe().status, DanceTimingStatus.aligned);
      expect(observe().status, DanceTimingStatus.stale);
    });
    test('expired or uncertain calibration abstains', () {
      expect(
          observe(now: 10000001).status, DanceTimingStatus.calibrationRequired);
      const uncertain = DanceClockCalibration(
          cameraClockId: 'camera-a',
          presentationClockId: 'audio-a',
          cameraToPresentationUs: 100000,
          uncertaintyUs: 5000,
          maxUncertaintyUs: 2000,
          validUntilUs: 10000000);
      expect(observe(calibration: uncertain).status,
          DanceTimingStatus.calibrationRequired);
    });
    test('end of playback is out of range, never a wrapped beat', () {
      expect(observe(cameraUs: 2900000, now: 3000000).status,
          DanceTimingStatus.outOfRange);
    });
    test('nonmonotonic beat grids and invalid anchors are rejected', () {
      expect(() => DanceTimeline(durationUs: 100, beatsUs: [0, 0]),
          throwsFormatException);
      expect(
          () => timeline.anchor(
              presentationUs: -1, mediaUs: 0, clockId: 'audio-a'),
          throwsFormatException);
      expect(observe().status, DanceTimingStatus.paused);
    });
  });
}
