import 'dart:async';

import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/live_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

import 'support/test_catalog.dart';

final class _CountingPoseSource implements PoseSource {
  _CountingPoseSource({this.firstStart});

  final Completer<LiveState?>? firstStart;
  final StreamController<PoseFrame> _frames =
      StreamController<PoseFrame>.broadcast();
  int starts = 0;
  int stops = 0;

  @override
  Future<LiveState?> begin() async {
    starts++;
    if (starts == 1 && firstStart != null) return firstStart!.future;
    return null;
  }

  @override
  Stream<PoseFrame> frames() => _frames.stream;

  @override
  Future<void> stop() async => stops++;

  Future<void> dispose() => _frames.close();
}

void main() {
  Widget lesson(
    _CountingPoseSource source, {
    Future<bool> Function()? permissionRequest,
  }) =>
      MaterialApp(
        home: LiveLessonPage(
          stepId: 'hh_bounce',
          lessonId: 'hh_l1_bounce',
          lessonClass: 'demoOnly',
          styleId: 'hip_hop_foundations',
          env: LiveEnvironment(
            bundle: DeviceBundle(declaredReferences()),
            source: () => source,
            cameraPermissionRequest: permissionRequest,
          ),
        ),
      );

  testWidgets('background releases the source and resume requires a restart',
      (WidgetTester tester) async {
    final _CountingPoseSource source = _CountingPoseSource();
    addTearDown(source.dispose);

    await tester.pumpWidget(lesson(source));
    for (int i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(source.stops, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveInterrupted>());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final Finder restart = find.byKey(LiveView.actionKey);
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    for (int i = 0; i < 12 && source.starts == 1; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(source.stops, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(source.stops, 2);
  });

  testWidgets('late camera open is released after background and resume',
      (WidgetTester tester) async {
    final Completer<LiveState?> gate = Completer<LiveState?>();
    final _CountingPoseSource source = _CountingPoseSource(firstStart: gate);
    addTearDown(source.dispose);

    await tester.pumpWidget(lesson(source));
    for (int i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    gate.complete(null);
    await tester.pump();
    await tester.pump();
    expect(source.stops, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveInterrupted>());

    final Finder restart = find.byKey(LiveView.actionKey);
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    for (int i = 0; i < 12 && source.starts == 1; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 2);
  });

  testWidgets('permission dialog resumes before camera opens',
      (WidgetTester tester) async {
    final Completer<bool> grant = Completer<bool>();
    final _CountingPoseSource source = _CountingPoseSource();
    addTearDown(source.dispose);
    int requests = 0;

    await tester.pumpWidget(lesson(source, permissionRequest: () {
      requests++;
      return grant.future;
    }));
    for (int i = 0; i < 12 && requests == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(requests, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    grant.complete(true);
    await tester.pump();
    expect(source.starts, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (int i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isNot(isA<LiveInterrupted>()));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(source.stops, 1);
  });

  testWidgets('an open camera without a pose leaves the loading screen',
      (WidgetTester tester) async {
    final _CountingPoseSource source = _CountingPoseSource();
    addTearDown(source.dispose);
    await tester.pumpWidget(lesson(source));
    for (int i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);
    await tester.pump(const Duration(seconds: 6));
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveNoPerson>());

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(source.stops, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveInterrupted>());
  });
}
