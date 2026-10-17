import 'dart:async';
import 'dart:convert';

import 'package:choreia/app/course/media/lesson_media_playback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Captions extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(
          'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:01.000\nSynthetic transport fixture.\n')));
}

class _SeekVideo implements SeekableLessonVideoHandle {
  @override
  final ValueNotifier<LessonVideoFrame> frame =
      ValueNotifier(const LessonVideoFrame());
  final operations = <String>[];
  Completer<void>? pauseGate;
  bool seekFails = false;
  @override
  Future<void> initialize() async {
    frame.value = const LessonVideoFrame(
        initialized: true, duration: Duration(seconds: 10));
  }

  @override
  Future<void> silence() async {}
  @override
  Future<void> pause() async {
    operations.add('pause');
    await pauseGate?.future;
  }

  @override
  Future<void> play() async {
    operations.add('play');
  }

  @override
  Future<void> seekTo(Duration at) async {
    operations.add('seek:${at.inSeconds}');
    if (seekFails) throw StateError('Native seek failed');
    frame.value = LessonVideoFrame(
        initialized: true, position: at, duration: const Duration(seconds: 10));
  }

  @override
  Future<void> close() async {
    operations.add('close');
    frame.dispose();
  }

  @override
  Widget buildVideo() => const SizedBox();
}

const fixture = LessonMediaPlaybackFixture(
    lessonId: 'synthetic',
    videoAssetPath: 'synthetic.mp4',
    captionAssetPaths: {'en': 'synthetic.en.vtt'});

void main() {
  Future<void> mount(WidgetTester tester, _SeekVideo video,
      {ValueNotifier<bool>? admission}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LessonMediaPlayback(
      fixture: fixture,
      bundle: _Captions(),
      locale: 'en',
      videoFactory: (_, __) => video,
      admissionOpen: admission,
    )))));
    await tester.pumpAndSettle();
  }

  void seek(WidgetTester tester) {
    tester
        .widget<Slider>(find.byKey(const Key('choreia.mediaPlaybackSeek')))
        .onChanged!(5);
  }

  testWidgets('seek pauses, acknowledges position and stays user-started',
      (tester) async {
    final video = _SeekVideo();
    await mount(tester, video);
    seek(tester);
    await tester.pumpAndSettle();
    expect(video.operations, ['pause', 'seek:5']);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 5);
    expect(find.text('Play'), findsOneWidget);
    expect(
        find.text(
            'Watching the demonstration does not change lesson progress.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('owner retirement during pending pause prevents late seek',
      (tester) async {
    final video = _SeekVideo()..pauseGate = Completer<void>();
    final admission = ValueNotifier(true);
    await mount(tester, video, admission: admission);
    seek(tester);
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    admission.value = false;
    video.pauseGate!.complete();
    await tester.pumpAndSettle();
    expect(video.operations.where((op) => op.startsWith('seek:')), isEmpty);
    expect(video.operations.last, 'close');
    expect(find.byType(Slider), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    admission.dispose();
  });
  testWidgets('seek error retires playback and leaves written fallback',
      (tester) async {
    final video = _SeekVideo()..seekFails = true;
    await mount(tester, video);
    seek(tester);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('choreia.mediaPlaybackFailure')), findsOneWidget);
    expect(video.operations, contains('close'));
    expect(video.operations, isNot(contains('play')));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
