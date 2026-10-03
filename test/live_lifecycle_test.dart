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
import 'support/round_trip_store.dart';

final class _ObservedAccount extends ValueNotifier<String?> {
  _ObservedAccount(super.value);
  bool get hasActiveListener => hasListeners;
}

final class _CountingPoseSource implements PoseSource {
  _CountingPoseSource({this.firstStart, this.cancelStartOnStop = false});

  final Completer<LiveState?>? firstStart;
  final bool cancelStartOnStop;
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
  Future<void> stop() async {
    stops++;
    if (cancelStartOnStop && firstStart != null && !firstStart!.isCompleted) {
      firstStart!.complete(const LiveInterrupted());
    }
  }

  Future<void> dispose() => _frames.close();
}

void main() {
  Widget lesson(
    _CountingPoseSource source, {
    Future<bool> Function()? permissionRequest,
    ValueNotifier<String?>? account,
    Future<SessionStore> Function()? storeOpener,
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
            accountUserId: account,
            storeOpener: storeOpener,
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

  testWidgets('sign out retires capture even if the original account returns',
      (tester) async {
    final source = _CountingPoseSource();
    final account = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
    addTearDown(source.dispose);
    addTearDown(account.dispose);
    await tester.pumpWidget(lesson(source, account: account));
    for (var i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);

    account.value = null;
    account.value = '11111111-1111-4111-8111-111111111111';
    await tester.pump();
    expect(source.stops, 1);
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveInterrupted>());
    expect(find.textContaining('The account changed.'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(source.starts, 1);
    expect(source.stops, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(source.stops, 1);
  });

  testWidgets('a pending camera open cannot join a changed account lease',
      (tester) async {
    final opened = Completer<LiveState?>();
    final source = _CountingPoseSource(firstStart: opened);
    final account = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
    addTearDown(source.dispose);
    addTearDown(account.dispose);
    await tester.pumpWidget(lesson(source, account: account));
    for (var i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(source.starts, 1);

    account.value = '22222222-2222-4222-8222-222222222222';
    opened.complete(null);
    await tester.pump();
    await tester.pump();
    expect(source.stops, 1);
    expect(find.textContaining('The account changed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account replacement revokes capture and detaches old listener',
      (tester) async {
    final source = _CountingPoseSource();
    final oldAccount = _ObservedAccount('11111111-1111-4111-8111-111111111111');
    final newAccount = _ObservedAccount('11111111-1111-4111-8111-111111111111');
    addTearDown(source.dispose);
    addTearDown(oldAccount.dispose);
    addTearDown(newAccount.dispose);
    await tester.pumpWidget(lesson(source, account: oldAccount));
    for (var i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pumpWidget(lesson(source, account: newAccount));
    expect(source.stops, 1);
    expect(oldAccount.hasActiveListener, isFalse);
    expect(newAccount.hasActiveListener, isTrue);
    oldAccount.value = '22222222-2222-4222-8222-222222222222';
    await tester.pump();
    expect(source.stops, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(newAccount.hasActiveListener, isFalse);
  });

  for (final cancellation in ['account', 'background', 'dispose']) {
    testWidgets('$cancellation cancels camera acquisition before it completes',
        (tester) async {
      final opened = Completer<LiveState?>();
      final source =
          _CountingPoseSource(firstStart: opened, cancelStartOnStop: true);
      final account = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
      addTearDown(source.dispose);
      addTearDown(account.dispose);
      await tester.pumpWidget(lesson(source, account: account));
      for (var i = 0; i < 12 && source.starts == 0; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(source.starts, 1);
      expect(opened.isCompleted, isFalse);

      switch (cancellation) {
        case 'account':
          account.value = '22222222-2222-4222-8222-222222222222';
        case 'background':
          tester.binding
              .handleAppLifecycleStateChanged(AppLifecycleState.paused);
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      expect(source.stops, 1);
      expect(opened.isCompleted, isTrue);
      await tester.pump();
      expect(source.stops, 1);
      expect(tester.takeException(), isNull);
      if (cancellation == 'background') {
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(source.stops, 1);
    });
  }

  testWidgets('an account change while opening the journal cannot append',
      (tester) async {
    final source = _CountingPoseSource();
    final account = ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
    final opening = Completer<SessionStore>();
    final store = RoundTripStore();
    var storeOpens = 0;
    addTearDown(source.dispose);
    addTearDown(account.dispose);
    await tester.pumpWidget(lesson(source, account: account, storeOpener: () {
      storeOpens++;
      return opening.future;
    }));
    for (var i = 0; i < 12 && source.starts == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    source._frames.add(PoseFrame(
        tUs: 0,
        landmarks: List.generate(33, (_) => const PoseLandmark.invisible())));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<LiveView>(find.byType(LiveView)).state,
        isA<LiveNoPerson>());
    tester.widget<LiveView>(find.byType(LiveView)).onFinish!.call();
    await tester.pump();
    expect(storeOpens, 1);
    account.value = '22222222-2222-4222-8222-222222222222';
    opening.complete(store);
    await tester.pump();
    await tester.pump();
    expect(store.records, isEmpty);
    expect(source.stops, 1);
    expect(find.textContaining('The account changed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
