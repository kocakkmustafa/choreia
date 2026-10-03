import 'dart:async';

import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/live_view.dart';
import 'package:choreia/app/live/session_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'support/round_trip_store.dart';
import 'support/test_catalog.dart';

final class _Recovery extends ValueNotifier<bool> {
  _Recovery(super.value);
  bool get listening => hasListeners;
}

final class _Source implements PoseSource {
  _Source({this.opening, this.closing, this.closeFailure});
  final Completer<LiveState?>? opening;
  final Completer<void>? closing;
  final CameraException? closeFailure;
  final framesController = StreamController<PoseFrame>.broadcast();
  int starts = 0, stops = 0;
  @override
  Future<LiveState?> begin() async {
    starts++;
    return opening?.future;
  }

  @override
  Stream<PoseFrame> frames() => framesController.stream;
  @override
  Future<void> stop() async {
    stops++;
    if (closeFailure != null) throw closeFailure!;
    if (closing != null) await closing!.future;
  }
}

void main() {
  Widget lesson(LiveEnvironment env) => MaterialApp(
      home: LiveLessonPage(
          stepId: 'hh_bounce',
          lessonId: 'hh_l1_bounce',
          lessonClass: 'demoOnly',
          styleId: 'hip_hop_foundations',
          env: env));

  Future<void> waitForStart(WidgetTester tester, _Source source) async {
    for (var i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);
  }

  Future<void> observeFrame(WidgetTester tester, _Source source) async {
    source.framesController.add(PoseFrame(
        tUs: 0,
        landmarks: List.generate(33, (_) => const PoseLandmark.invisible())));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveNoPerson>());
  }

  testWidgets('same-UUID recovery retires pending camera before open resolves',
      (tester) async {
    final opening = Completer<LiveState?>();
    final source = _Source(opening: opening);
    final recovery = _Recovery(false);
    final owner = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
    addTearDown(source.framesController.close);
    addTearDown(recovery.dispose);
    addTearDown(owner.dispose);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        accountUserId: owner,
        passwordRecovery: recovery)));
    await waitForStart(tester, source);
    recovery.value = true;
    expect(source.stops, 1);
    recovery.value = false;
    opening.complete(null);
    await tester.pump();
    await tester.pump();
    expect(source.starts, 1);
    expect(source.stops, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveInterrupted>());
    await tester.pumpWidget(const SizedBox.shrink());
    expect(source.stops, 1);
    expect(recovery.listening, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial recovery and delayed permission cannot acquire capture',
      (tester) async {
    final source = _Source();
    final recovery = _Recovery(true);
    addTearDown(source.framesController.close);
    addTearDown(recovery.dispose);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        passwordRecovery: recovery)));
    await tester.pump(const Duration(seconds: 1));
    expect(source.starts, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    recovery.value = false;
    final permission = Completer<bool>();
    var requests = 0;
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        passwordRecovery: recovery,
        cameraPermissionRequest: () {
          requests++;
          return permission.future;
        })));
    for (var i = 0; i < 12 && requests == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(requests, 1);
    recovery.value = true;
    permission.complete(true);
    await tester.pump();
    await tester.pump();
    expect(source.starts, 0);
    expect(source.stops, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('recovery during journal opening cannot append or show a result',
      (tester) async {
    final source = _Source();
    final recovery = _Recovery(false);
    final opened = Completer<SessionStore>();
    final store = RoundTripStore();
    var opens = 0;
    addTearDown(source.framesController.close);
    addTearDown(recovery.dispose);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        passwordRecovery: recovery,
        storeOpener: () {
          opens++;
          return opened.future;
        })));
    await waitForStart(tester, source);
    await observeFrame(tester, source);
    tester.widget<LiveView>(find.byType(LiveView)).onFinish!();
    await tester.pump();
    expect(opens, 1);
    recovery.value = true;
    opened.complete(store);
    await tester.pump();
    await tester.pump();
    expect(store.records, isEmpty);
    expect(find.byType(SessionResultView), findsNothing);
    expect(source.stops, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('finish waits for close acknowledgement before journal admission',
      (tester) async {
    final closing = Completer<void>();
    final source = _Source(closing: closing);
    final store = RoundTripStore();
    var opens = 0;
    addTearDown(source.framesController.close);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        storeOpener: () async {
          opens++;
          return store;
        })));
    await waitForStart(tester, source);
    await observeFrame(tester, source);
    tester.widget<LiveView>(find.byType(LiveView)).onFinish!();
    await tester.pump();
    expect(source.stops, 1);
    expect(opens, 0);
    expect(store.records, isEmpty);
    closing.complete();
    // The result surface intentionally has a repeating status animation.
    // Pump the write/route transition, not an impossible global idle state.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(opens, 1);
    expect(store.records, hasLength(1));
    expect(find.byType(SessionResultView), findsOneWidget);
    expect(source.stops, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'uncertain finish close is bounded and cannot save or retry capture',
      (tester) async {
    final source = _Source(
        closeFailure: const CameraException(
            CameraFailure.closeUncertain, 'private native detail'));
    var opens = 0;
    addTearDown(source.framesController.close);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        storeOpener: () async {
          opens++;
          return RoundTripStore();
        })));
    await waitForStart(tester, source);
    await observeFrame(tester, source);
    tester.widget<LiveView>(find.byType(LiveView)).onFinish!();
    await tester.pump();
    await tester.pump();
    final view = tester.widget<LiveView>(find.byType(LiveView));
    expect(view.state, isA<LiveCameraUnavailable>());
    expect((view.state as LiveCameraUnavailable).failure,
        CameraFailure.closeUncertain);
    expect(view.onFinish, isNull);
    expect(find.text('Back to lesson'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.textContaining('private native detail'), findsNothing);
    view.onRetry!();
    await tester.pump();
    expect(source.starts, 1);
    expect(source.stops, 1);
    expect(opens, 0);
    expect(find.byType(SessionResultView), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(source.stops, 1);
  });

  testWidgets(
      'false replacement detaches old recovery without revoking capture',
      (tester) async {
    final source = _Source();
    final oldSignal = _Recovery(false), nextSignal = _Recovery(false);
    final bundle = DeviceBundle(declaredReferences());
    PoseSource sourceFactory() => source;
    addTearDown(source.framesController.close);
    addTearDown(oldSignal.dispose);
    addTearDown(nextSignal.dispose);
    LiveEnvironment env(_Recovery recovery) => LiveEnvironment(
        bundle: bundle, source: sourceFactory, passwordRecovery: recovery);
    await tester.pumpWidget(lesson(env(oldSignal)));
    await waitForStart(tester, source);
    await tester.pumpWidget(lesson(env(nextSignal)));
    expect(oldSignal.listening, isFalse);
    expect(nextSignal.listening, isTrue);
    expect(source.stops, 0);
    oldSignal.value = true;
    await tester.pump();
    expect(source.stops, 0);
    nextSignal.value = true;
    expect(source.stops, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(nextSignal.listening, isFalse);
  });

  testWidgets('same-UUID host epoch synchronously cancels pending capture',
      (tester) async {
    final opening = Completer<LiveState?>();
    final source = _Source(opening: opening);
    final epoch = ValueNotifier<int>(0);
    addTearDown(source.framesController.close);
    addTearDown(epoch.dispose);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        ownerEpoch: epoch)));
    await waitForStart(tester, source);
    epoch.value++;
    expect(source.stops, 1);
    opening.complete(null);
    await tester.pump();
    await tester.pump();
    expect(source.starts, 1);
    expect(source.stops, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveInterrupted>());
    await tester.pumpWidget(const SizedBox.shrink());
    expect(source.stops, 1);
  });

  testWidgets(
      'owner retirement while finish awaits close cannot admit a journal',
      (tester) async {
    final closing = Completer<void>();
    final source = _Source(closing: closing);
    final epoch = ValueNotifier<int>(0);
    var opens = 0;
    addTearDown(source.framesController.close);
    addTearDown(epoch.dispose);
    await tester.pumpWidget(lesson(LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        source: () => source,
        ownerEpoch: epoch,
        storeOpener: () async {
          opens++;
          return RoundTripStore();
        })));
    await waitForStart(tester, source);
    await observeFrame(tester, source);
    tester.widget<LiveView>(find.byType(LiveView)).onFinish!();
    await tester.pump();
    expect(source.stops, 1);
    expect(opens, 0);
    epoch.value++;
    closing.complete();
    await tester.pump();
    await tester.pump();
    expect(opens, 0);
    expect(find.byType(SessionResultView), findsNothing);
    expect(source.stops, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(source.stops, 1);
  });
}
