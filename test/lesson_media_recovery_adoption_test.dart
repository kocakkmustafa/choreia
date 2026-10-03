import 'dart:async';
import 'dart:convert';

import 'package:choreia/app/course/media/lesson_media_playback.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class _CaptionBundle extends CachingAssetBundle {
  int reads = 0;
  @override
  Future<ByteData> load(String key) async {
    reads++;
    final bytes = Uint8List.fromList(utf8.encode(
        'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:00.500\nWritten demonstration.\n'));
    return ByteData.sublistView(bytes);
  }
}

final class _RecoveryVideo implements LessonVideoHandle {
  _RecoveryVideo({this.initializeGate});

  final Completer<void>? initializeGate;
  final initialized = Completer<void>();
  int silenceCalls = 0, playCalls = 0, pauseCalls = 0, closeCalls = 0;
  @override
  final ValueNotifier<LessonVideoFrame> frame =
      ValueNotifier<LessonVideoFrame>(const LessonVideoFrame());

  @override
  Future<void> initialize() async {
    initialized.complete();
    await initializeGate?.future;
    frame.value = const LessonVideoFrame(initialized: true);
  }

  @override
  Future<void> silence() async {
    silenceCalls++;
  }

  @override
  Future<void> play() async {
    playCalls++;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    frame.dispose();
  }

  @override
  Widget buildVideo() => const SizedBox(key: Key('recovery.video'));
}

const _fixture = LessonMediaPlaybackFixture(
  lessonId: 'so_01',
  videoAssetPath: 'test-only.mp4',
  captionAssetPaths: <String, String>{'en': 'test-only.en.vtt'},
);

void main() {
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump();
    }
  }

  Widget slot(_CaptionBundle bundle, ValueListenable<bool> recovery,
          LessonVideoFactory factory,
          {ValueListenable<int>? ownerEpoch}) =>
      MaterialApp(
          home: LessonMediaSlot.testingPlayback(
        key: const Key('stable.media'),
        lessonId: 'so_01',
        locale: 'en',
        fixture: _fixture,
        bundle: bundle,
        passwordRecovery: recovery,
        ownerEpoch: ownerEpoch,
        videoFactory: factory,
      ));

  testWidgets('initial recovery admits no caption or test player',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final recovery = ValueNotifier<bool>(true);
    addTearDown(recovery.dispose);
    final bundle = _CaptionBundle();
    var players = 0;
    await tester.pumpWidget(slot(bundle, recovery, (_, __) {
      players++;
      return _RecoveryVideo();
    }));
    await drain(tester);
    expect(bundle.reads, 0);
    expect(players, 0);
    recovery.value = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drain(tester);
    expect(bundle.reads, 0);
    expect(players, 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovery retires initialize before completion without a frame',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final recovery = ValueNotifier<bool>(false);
    addTearDown(recovery.dispose);
    final gate = Completer<void>();
    final video = _RecoveryVideo(initializeGate: gate);
    var players = 0;
    await tester.pumpWidget(slot(_CaptionBundle(), recovery, (_, __) {
      players++;
      return video;
    }));
    await drain(tester);
    expect(video.initialized.isCompleted, isTrue);
    expect(video.silenceCalls, 0);
    recovery.value = true;
    recovery.value = false;
    // Deliberately settle native initialization before any widget pump.
    gate.complete();
    await drain(tester);
    expect(video.silenceCalls, 0);
    expect(video.playCalls, 0);
    expect(video.pauseCalls, 1);
    expect(video.closeCalls, 1);
    expect(find.byType(LessonMediaPlayback), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drain(tester);
    expect(players, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('ready player stale action cannot play during recovery stack',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final recovery = ValueNotifier<bool>(false);
    addTearDown(recovery.dispose);
    final video = _RecoveryVideo();
    await tester.pumpWidget(slot(_CaptionBundle(), recovery, (_, __) => video));
    await drain(tester);
    expect(video.silenceCalls, 1);
    final action = tester
        .widget<TextButton>(
            find.byKey(const Key('choreia.mediaPlaybackToggle')))
        .onPressed!;
    recovery.value = true;
    action();
    expect(video.playCalls, 0);
    await drain(tester);
    expect(video.pauseCalls, 1);
    expect(video.closeCalls, 1);
    await tester.pumpWidget(const SizedBox());
    recovery.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacement recovery notifier closes old player and detaches',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final oldRecovery = ValueNotifier<bool>(false);
    final newRecovery = ValueNotifier<bool>(false);
    addTearDown(oldRecovery.dispose);
    addTearDown(newRecovery.dispose);
    final bundle = _CaptionBundle();
    final video = _RecoveryVideo();
    var players = 0;
    LessonVideoHandle factory(String _, String __) {
      players++;
      return video;
    }

    await tester.pumpWidget(slot(bundle, oldRecovery, factory));
    await drain(tester);
    await tester.pumpWidget(slot(bundle, newRecovery, factory));
    await drain(tester);
    expect(video.closeCalls, 1);
    oldRecovery.value = true;
    newRecovery.value = true;
    newRecovery.value = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drain(tester);
    expect(players, 1);
    expect(video.closeCalls, 1);
    await tester.pumpWidget(const SizedBox());
    oldRecovery.value = false;
    newRecovery.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'same UUID epoch retires pending native initialization synchronously',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final recovery = ValueNotifier<bool>(false);
    final epoch = ValueNotifier<int>(0);
    addTearDown(recovery.dispose);
    addTearDown(epoch.dispose);
    final gate = Completer<void>();
    final video = _RecoveryVideo(initializeGate: gate);
    var players = 0;
    await tester.pumpWidget(slot(_CaptionBundle(), recovery, (_, __) {
      players++;
      return video;
    }, ownerEpoch: epoch));
    await drain(tester);
    expect(video.initialized.isCompleted, isTrue);
    epoch.value++;
    gate.complete();
    await drain(tester);
    expect(video.silenceCalls, 0);
    expect(video.playCalls, 0);
    expect(video.pauseCalls, 1);
    expect(video.closeCalls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drain(tester);
    expect(players, 1);
    await tester.pumpWidget(const SizedBox());
    epoch.value++;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid background resume starts a fresh paused player lifetime',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final recovery = ValueNotifier<bool>(false);
    addTearDown(recovery.dispose);
    final videos = <_RecoveryVideo>[];
    await tester.pumpWidget(slot(_CaptionBundle(), recovery, (_, __) {
      final video = _RecoveryVideo();
      videos.add(video);
      return video;
    }));
    await drain(tester);
    expect(videos, hasLength(1));
    // Both notifications precede the next frame. The retired child must not
    // be kept by its old key when the parent paints foreground again.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drain(tester);
    expect(videos, hasLength(2));
    expect(videos.first.closeCalls, 1);
    expect(videos.last.playCalls, 0);
    expect(videos.last.silenceCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await drain(tester);
    expect(videos.last.closeCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
