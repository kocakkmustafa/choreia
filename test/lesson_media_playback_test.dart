import 'dart:async';
import 'dart:convert';

import 'package:choreia/app/course/media/lesson_media_playback.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptionBundle extends CachingAssetBundle {
  _CaptionBundle(this.files);

  final Map<String, String> files;
  final List<String> reads = <String>[];

  @override
  Future<ByteData> load(String key) async {
    reads.add(key);
    final text = files[key];
    if (text == null) throw FlutterError('Missing test caption');
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ByteData.view(bytes.buffer);
  }
}

class _FakeVideo implements LessonVideoHandle {
  _FakeVideo(this.path, this.captionText);

  final String path, captionText;
  @override
  final ValueNotifier<LessonVideoFrame> frame =
      ValueNotifier<LessonVideoFrame>(const LessonVideoFrame());
  int initializeCalls = 0,
      silenceCalls = 0,
      playCalls = 0,
      pauseCalls = 0,
      closeCalls = 0;
  Completer<void>? initializeGate, silenceGate, playGate, pauseGate;
  final List<String> operations = <String>[];
  bool closed = false;
  bool errorDuringInitialize = false;
  bool errorDuringSilence = false;
  bool errorDuringPlay = false;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    operations.add('initialize');
    if (errorDuringInitialize) {
      frame.value = const LessonVideoFrame(hasError: true);
    }
    await initializeGate?.future;
    if (!closed) frame.value = const LessonVideoFrame(initialized: true);
  }

  @override
  Future<void> silence() async {
    silenceCalls++;
    operations.add('silence');
    await silenceGate?.future;
    if (errorDuringSilence) throw StateError('Native volume failed');
  }

  @override
  Future<void> play() async {
    playCalls++;
    operations.add('play');
    if (errorDuringPlay) {
      frame.value = const LessonVideoFrame(initialized: true, hasError: true);
    }
    await playGate?.future;
    if (!closed) {
      frame.value = LessonVideoFrame(
        initialized: true,
        playing: true,
        caption: captionText.contains('locale=tr')
            ? 'Hazırlığı izle.'
            : 'Watch the preparation.',
      );
    }
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    await pauseGate?.future;
    if (!closed) frame.value = const LessonVideoFrame(initialized: true);
  }

  @override
  Future<void> close() async {
    closeCalls++;
    closed = true;
    frame.dispose();
  }

  @override
  Widget buildVideo() => const ColoredBox(
        key: Key('fake.lessonVideo'),
        color: Colors.black,
      );
}

const _trPath = 'content/media/so-01.tr.vtt';
const _enPath = 'content/media/so-01.en.vtt';
const _fixture = LessonMediaPlaybackFixture(
  lessonId: 'so_01',
  videoAssetPath: 'content/media/so-01.mp4',
  captionAssetPaths: <String, String>{'tr': _trPath, 'en': _enPath},
);

_CaptionBundle _bundle() => _CaptionBundle(<String, String>{
      _trPath:
          'WEBVTT - Motion locale=tr\n\n00:00:00.000 --> 00:00:00.500\nHazırlığı izle.\n',
      _enPath:
          'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:00.500\nWatch the preparation.\n',
    });

void main() {
  testWidgets('test fixture is user-started, captioned, and progress-neutral',
      (tester) async {
    final videos = <_FakeVideo>[];
    final bundle = _bundle();
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'tr',
        fixture: _fixture,
        bundle: bundle,
        videoFactory: (path, captions) {
          final video = _FakeVideo(path, captions);
          videos.add(video);
          return video;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(videos, hasLength(1));
    expect(videos.single.path, _fixture.videoAssetPath);
    expect(videos.single.captionText, contains('locale=tr'));
    expect(videos.single.playCalls, 0);
    expect(videos.single.operations, <String>['initialize', 'silence']);
    expect(find.byKey(const Key('fake.lessonVideo')), findsOneWidget);
    expect(find.text('Gösterimi izlemek ders ilerlemesini değiştirmez.'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('choreia.mediaPlaybackToggle')));
    await tester.pump();
    expect(videos.single.playCalls, 1);
    expect(videos.single.operations, <String>['initialize', 'silence', 'play']);
    expect(find.text('Hazırlığı izle.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('choreia.mediaPlaybackToggle')));
    await tester.pump();
    expect(videos.single.pauseCalls, 1);
  });

  testWidgets('background closes video; foreground reopens paused',
      (tester) async {
    final videos = <_FakeVideo>[];
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'en',
        fixture: _fixture,
        bundle: _bundle(),
        videoFactory: (path, captions) {
          final video = _FakeVideo(path, captions);
          videos.add(video);
          return video;
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(videos, hasLength(1));

    final dynamic slotState = tester.state(find.byType(LessonMediaSlot));
    slotState.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);
    for (var i = 0; i < 3 && videos.first.closeCalls == 0; i++) {
      await tester.pump();
    }
    expect(videos.first.closeCalls, 1);

    slotState.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(videos, hasLength(2));
    expect(videos.last.playCalls, 0);
    expect(find.byKey(const Key('fake.lessonVideo')), findsOneWidget);
  });

  testWidgets('account change revokes playback through later resume',
      (tester) async {
    final owner = ValueNotifier<String?>('alice');
    addTearDown(owner.dispose);
    final videos = <_FakeVideo>[];
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'en',
        fixture: _fixture,
        bundle: _bundle(),
        accountUserId: owner,
        videoFactory: (path, captions) {
          final video = _FakeVideo(path, captions);
          videos.add(video);
          return video;
        },
      ),
    ));
    await tester.pumpAndSettle();
    owner.value = 'bob';
    await tester.pumpAndSettle();
    expect(videos.single.closeCalls, 1);
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(videos, hasLength(1));
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);
  });

  testWidgets('lesson and locale switches release previous video',
      (tester) async {
    final videos = <_FakeVideo>[];
    final bundle = _bundle();
    _FakeVideo factory(String path, String captions) {
      final video = _FakeVideo(path, captions);
      videos.add(video);
      return video;
    }

    Widget slot(
            String lesson, String locale, LessonMediaPlaybackFixture fixture) =>
        MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            key: const Key('same.slot'),
            lessonId: lesson,
            locale: locale,
            fixture: fixture,
            bundle: bundle,
            videoFactory: factory,
          ),
        );

    await tester.pumpWidget(slot('so_01', 'tr', _fixture));
    await tester.pumpAndSettle();
    await tester.pumpWidget(slot('so_01', 'en', _fixture));
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos.last.captionText, contains('locale=en'));

    await tester.pumpWidget(slot('so_02', 'en', _fixture));
    await tester.pumpAndSettle();
    expect(videos.last.closeCalls, 1);
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(videos.every((video) => video.closeCalls == 1), isTrue);
  });

  testWidgets('missing caption fails closed without creating a player',
      (tester) async {
    final videos = <_FakeVideo>[];
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'tr',
        fixture: _fixture,
        bundle: _CaptionBundle(<String, String>{}),
        videoFactory: (path, captions) {
          final video = _FakeVideo(path, captions);
          videos.add(video);
          return video;
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(videos, isEmpty);
    expect(
        find.byKey(const Key('choreia.mediaPlaybackFailure')), findsOneWidget);
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native mute failure fails closed before playback',
      (tester) async {
    late _FakeVideo video;
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'en',
        fixture: _fixture,
        bundle: _bundle(),
        videoFactory: (path, captions) {
          video = _FakeVideo(path, captions)..errorDuringSilence = true;
          return video;
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(video.operations, <String>['initialize', 'silence']);
    expect(video.playCalls, 0);
    expect(video.closeCalls, 1);
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);
    expect(
        find.byKey(const Key('choreia.mediaPlaybackFailure')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty cue track fails closed before native player creation',
      (tester) async {
    final videos = <_FakeVideo>[];
    final bundle = _bundle();
    bundle.files[_trPath] = 'WEBVTT - Motion locale=tr\n\n';
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'tr',
        fixture: _fixture,
        bundle: bundle,
        videoFactory: (path, captions) {
          final video = _FakeVideo(path, captions);
          videos.add(video);
          return video;
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(videos, isEmpty);
    expect(
        find.byKey(const Key('choreia.mediaPlaybackFailure')), findsOneWidget);
  });

  testWidgets('late player error disposes handle and preserves written lesson',
      (tester) async {
    late _FakeVideo video;
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot.testingPlayback(
        lessonId: 'so_01',
        locale: 'en',
        fixture: _fixture,
        bundle: _bundle(),
        videoFactory: (path, captions) => video = _FakeVideo(path, captions),
      ),
    ));
    await tester.pumpAndSettle();
    video.frame.value = const LessonVideoFrame(
      initialized: true,
      hasError: true,
    );
    await tester.pumpAndSettle();
    expect(video.closeCalls, 1);
    expect(
        find.byKey(const Key('choreia.mediaPlaybackFailure')), findsOneWidget);
    expect(find.textContaining('continue with the written lesson'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('route remount waits while the old native pause is pending',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) video.pauseGate = gate;
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    expect(videos.single.closeCalls, 0);
    gate.complete();
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(2));
  });

  testWidgets('route remount waits for an in-flight play command',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) video.playGate = gate;
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choreia.mediaPlaybackToggle')));
    await tester.pump();
    expect(videos.single.playCalls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    gate.complete();
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(2));
  });

  testWidgets('route remount waits for an in-flight initialization',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) video.initializeGate = gate;
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    gate.complete();
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(2));
  });

  testWidgets('route remount waits for an in-flight native mute',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) video.silenceGate = gate;
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    expect(videos.single.silenceCalls, 1);
    expect(videos.single.playCalls, 0);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    gate.complete();
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(2));
    expect(videos.last.operations, <String>['initialize', 'silence']);
  });

  testWidgets('synchronous init error still fences its pending native Future',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) {
                video.errorDuringInitialize = true;
                video.initializeGate = gate;
              }
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    gate.complete();
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(2));
  });

  testWidgets('synchronous play error still fences its pending native Future',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) {
                video.errorDuringPlay = true;
                video.playGate = gate;
              }
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choreia.mediaPlaybackToggle')));
    await tester.pump();
    expect(videos.first.playCalls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump();
    expect(videos, hasLength(1));
    gate.complete();
    await tester.pumpAndSettle();
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(2));
  });

  testWidgets('hung pause attempts close and quarantines later routes',
      (tester) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final videos = <_FakeVideo>[];
    Widget route() => MaterialApp(
          home: LessonMediaSlot.testingPlayback(
            lessonId: 'so_01',
            locale: 'tr',
            fixture: _fixture,
            bundle: _bundle(),
            videoFactory: (path, captions) {
              final video = _FakeVideo(path, captions);
              if (videos.isEmpty) video.pauseGate = gate;
              videos.add(video);
              return video;
            },
          ),
        );
    await tester.pumpWidget(route());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpWidget(route());
    await tester.pump(const Duration(seconds: 3));
    expect(videos.first.closeCalls, 1);
    expect(videos, hasLength(1));
    expect(find.byKey(const Key('fake.lessonVideo')), findsNothing);
  });
}
