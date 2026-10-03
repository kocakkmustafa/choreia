import 'dart:async';

import 'package:choreia/app/course/media/lesson_media_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Exercises the real Dart controller without a texture or media decoder.
/// A call is only "applied" after the platform Future has settled.
final class _StartupPlatform extends VideoPlayerPlatform {
  final StreamController<VideoEvent> events = StreamController<VideoEvent>();
  final List<String> calls = <String>[];
  final List<int> eventPlayerIds = <int>[];
  final Completer<void> volumeStarted = Completer<void>();
  final Completer<void> loopStarted = Completer<void>();
  final Completer<void> pauseStarted = Completer<void>();
  Completer<void>? volumeGate;
  Completer<void>? loopGate;
  Completer<void>? pauseGate;
  String? failingOperation;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failingOperation == 'create') throw StateError('create failed');
    if (failingOperation == 'null-create') return null;
    return 1;
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {
    if (failingOperation == 'mix') throw StateError('mix failed');
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    eventPlayerIds.add(playerId);
    scheduleMicrotask(() {
      events.add(VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(160, 90),
        duration: const Duration(seconds: 2),
      ));
    });
    return events.stream;
  }

  Future<void> _apply(String operation, Completer<void>? gate) async {
    calls.add('$operation-start');
    await gate?.future;
    if (failingOperation == operation) {
      throw StateError('$operation failed');
    }
    calls.add('$operation-applied');
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    expect(volume, 0);
    if (!volumeStarted.isCompleted) volumeStarted.complete();
    await _apply('volume', volumeGate);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    if (!loopStarted.isCompleted) loopStarted.complete();
    await _apply('loop', loopGate);
  }

  @override
  Future<void> pause(int playerId) async {
    if (!pauseStarted.isCompleted) pauseStarted.complete();
    await _apply('pause', pauseGate);
  }

  @override
  Future<void> play(int playerId) => _apply('play', null);

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
    await events.close();
  }

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();
}

Future<void> _turn() => Future<void>.delayed(Duration.zero);

VideoPlayerController _controller() =>
    VideoPlayerController.asset('content/media/no-real-file.mp4');

final class _FailedCreationController extends VideoPlayerController {
  _FailedCreationController()
      : super.asset(
          'content/media/no-real-file.mp4',
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

  int lifecyclePauseCalls = 0;

  @override
  Future<void> pause() async {
    lifecyclePauseCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initialize owns volume, loop, pause in applied order', () async {
    final platform = _StartupPlatform()
      ..volumeGate = Completer<void>()
      ..loopGate = Completer<void>()
      ..pauseGate = Completer<void>();
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    final controller = _controller();
    try {
      await controller.setVolume(0);
      var initialized = false;
      final initializing = controller.initialize()
        ..then((_) => initialized = true);
      await platform.volumeStarted.future;
      await _turn();
      expect(initialized, isFalse);
      expect(platform.calls, <String>['volume-start']);

      platform.volumeGate!.complete();
      await platform.loopStarted.future;
      await _turn();
      expect(initialized, isFalse);
      expect(platform.calls, <String>[
        'volume-start',
        'volume-applied',
        'loop-start',
      ]);

      platform.loopGate!.complete();
      await platform.pauseStarted.future;
      await _turn();
      expect(initialized, isFalse);
      expect(platform.calls, <String>[
        'volume-start',
        'volume-applied',
        'loop-start',
        'loop-applied',
        'pause-start',
      ]);

      platform.pauseGate!.complete();
      await initializing;
      expect(initialized, isTrue);
      await controller.play();
      expect(platform.calls, <String>[
        'volume-start',
        'volume-applied',
        'loop-start',
        'loop-applied',
        'pause-start',
        'pause-applied',
        'play-start',
        'play-applied',
      ]);
    } finally {
      if (!platform.volumeGate!.isCompleted) platform.volumeGate!.complete();
      if (!platform.loopGate!.isCompleted) platform.loopGate!.complete();
      if (!platform.pauseGate!.isCompleted) platform.pauseGate!.complete();
      await controller.dispose();
    }
  });

  for (final operation in <String>['volume', 'loop', 'pause']) {
    test('initialize reports automatic $operation failure', () async {
      final platform = _StartupPlatform()..failingOperation = operation;
      final original = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      final controller = _controller();
      try {
        await controller.setVolume(0);
        await expectLater(
            controller.initialize(),
            throwsA(isA<StateError>().having(
                (error) => error.message, 'message', '$operation failed')));
        expect(platform.calls, isNot(contains('play-start')));
      } finally {
        await controller.dispose();
        expect(platform.calls, contains('dispose'));
      }
    });
  }

  test('dispose waits for automatic pause before platform teardown', () async {
    final platform = _StartupPlatform()..pauseGate = Completer<void>();
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    final controller = _controller();
    try {
      await controller.setVolume(0);
      final initializing = controller.initialize();
      await platform.pauseStarted.future;
      var disposed = false;
      final disposing = controller.dispose().then((_) => disposed = true);
      await _turn();
      expect(disposed, isFalse);
      expect(platform.calls, isNot(contains('dispose')));

      platform.pauseGate!.complete();
      await initializing;
      await disposing;
      expect(platform.calls.indexOf('dispose'),
          greaterThan(platform.calls.indexOf('pause-applied')));
    } finally {
      if (!platform.pauseGate!.isCompleted) platform.pauseGate!.complete();
      await controller.dispose();
    }
  });

  test('stream error while pause is pending still orders native disposal',
      () async {
    final platform = _StartupPlatform()..pauseGate = Completer<void>();
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    final controller = _controller();
    try {
      await controller.setVolume(0);
      final initializing = controller.initialize();
      final failure =
          expectLater(initializing, throwsA(isA<PlatformException>()));
      await platform.pauseStarted.future;
      platform.events.addError(
        PlatformException(code: 'failed', message: 'Media failed'),
      );
      await failure;
      final disposing = controller.dispose();
      await _turn();
      expect(platform.calls, isNot(contains('dispose')));
      platform.pauseGate!.complete();
      await disposing;
      expect(platform.calls.indexOf('dispose'),
          greaterThan(platform.calls.indexOf('pause-applied')));
    } finally {
      if (!platform.pauseGate!.isCompleted) platform.pauseGate!.complete();
      await controller.dispose();
    }
  });

  test('asset lesson adapter cannot initialize before automatic pause',
      () async {
    final platform = _StartupPlatform()..pauseGate = Completer<void>();
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    final video = createAssetLessonVideo(
      'content/media/no-real-file.mp4',
      'WEBVTT - Motion locale=tr\n\n'
          '00:00:00.000 --> 00:00:00.500\nHazırlığı izle.\n',
    );
    try {
      var initialized = false;
      final initializing = video.initialize()..then((_) => initialized = true);
      await platform.pauseStarted.future;
      await _turn();
      expect(initialized, isFalse);
      expect(platform.calls, isNot(contains('play-start')));
      platform.pauseGate!.complete();
      await initializing;
      await video.silence();
      await video.play();
      expect(platform.calls.indexOf('play-start'),
          greaterThan(platform.calls.indexOf('pause-applied')));
    } finally {
      if (!platform.pauseGate!.isCompleted) platform.pauseGate!.complete();
      await video.close();
    }
  });

  for (final operation in <String>['mix', 'create']) {
    test('dispose settles after $operation fails before player creation',
        () async {
      final platform = _StartupPlatform()..failingOperation = operation;
      final original = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      // These failures precede videoEventsFor, so own the otherwise unlistened
      // single-subscription stream; closing it without a listener would hang.
      final unusedEvents = platform.events.stream.listen((_) {});
      addTearDown(() async {
        await platform.events.close();
        await unusedEvents.cancel();
      });
      final controller = _FailedCreationController();

      await expectLater(
        controller.initialize(),
        throwsA(isA<StateError>()
            .having((error) => error.message, 'message', '$operation failed')),
      );
      expect(controller.playerId, VideoPlayerController.kUninitializedPlayerId);
      // A failed creation has no native player to retire. Its creation barrier
      // must still settle so disposal can release the lifecycle observer.
      await expectLater(
        controller.dispose().timeout(const Duration(seconds: 1)),
        completes,
      );
      expect(platform.calls, isNot(contains('dispose')));
      expect(platform.calls, isNot(contains('play-start')));
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);
      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _turn();
      expect(controller.lifecyclePauseCalls, 0);
    });
  }

  test('null native player ID rejects initialization and releases its observer',
      () async {
    final platform = _StartupPlatform()..failingOperation = 'null-create';
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    final controller = _FailedCreationController();
    addTearDown(() async {
      await controller.dispose().timeout(const Duration(seconds: 1));
      // The green path never listens for events; the red path does. Both must
      // close the fixture stream without trying to listen to it twice.
      final unusedEvents = platform.eventPlayerIds.isEmpty
          ? platform.events.stream.listen((_) {})
          : null;
      await platform.events.close();
      await unusedEvents?.cancel();
    });

    await controller.setVolume(0);
    await expectLater(
      controller.initialize().timeout(const Duration(seconds: 1)),
      throwsA(isA<StateError>().having((error) => error.message, 'message',
          'VideoPlayerPlatform did not create a player')),
    );
    expect(platform.eventPlayerIds, isEmpty);
    expect(controller.playerId, VideoPlayerController.kUninitializedPlayerId);
    await controller.dispose().timeout(const Duration(seconds: 1));
    expect(platform.calls, isNot(contains('dispose')));
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _turn();
    expect(controller.lifecyclePauseCalls, 0);
  });
}
