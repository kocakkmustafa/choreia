import 'dart:convert';

import 'package:choreia/app/course/media/lesson_media_catalog.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_content/motion_content.dart';

import 'support/test_catalog.dart';

// Frozen v2 Choreia so_01 orientation source, independent of the candidate.
const _pin = LessonMediaSourcePin(
  lessonId: 'so_01',
  sceneId: 'choreia:so_01:orientation',
  variantStem:
      'choreia/so-01--becaa07c/orientation--816cb95c667096f5dc0c11e8a9f3de2ed6777cd898708b65fb67310f777fc2ed--master-16x9',
  courseSourceSha256:
      'bceece2f4264963578e0414985a34c55a45103b286c2b87e12bece711e693a83',
  lessonCanonicalSha256:
      '05b4bc7664a0143fd0f75bd4d98ef2934ab9ae9eeb381224d7bbb8f73ffe7a2b',
  productionSpecSha256:
      '816cb95c667096f5dc0c11e8a9f3de2ed6777cd898708b65fb67310f777fc2ed',
  sourceCueSha256:
      '15cc3828f0b88eedff915b7a2277befa358942030e1e3436a97ffe06367a7f18',
);
const _zeroSha =
    '0000000000000000000000000000000000000000000000000000000000000000';

final class _MediaBundle extends DiskBundle {
  _MediaBundle(this.files);
  final Map<String, Uint8List> files;
  final List<String> mediaReads = [];

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('content/media/')) {
      mediaReads.add(key);
      final bytes = files[key];
      if (bytes == null) throw FlutterError('missing bundled media: $key');
      return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    }
    return super.load(key);
  }
}

final class _Fixture {
  _Fixture()
      : videoBytes = Uint8List.fromList(<int>[
          0,
          0,
          0,
          24,
          0x66,
          0x74,
          0x79,
          0x70,
          0x69,
          0x73,
          0x6f,
          0x6d,
        ]),
        trBytes = Uint8List.fromList(utf8.encode(
            'WEBVTT - Motion locale=tr\n\n00:00:00.000 --> 00:00:00.500\nHazırlığı izle.\n')),
        enBytes = Uint8List.fromList(utf8.encode(
            'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:00.500\nWatch the preparation.\n'));

  final Uint8List videoBytes, trBytes, enBytes;
  String get prefix => 'content/media/${_pin.variantStem}';

  LessonMediaFile file(String path, Uint8List bytes) =>
      LessonMediaFile(path, bytes.length, computeSha256Hex(bytes));

  LessonMediaFile get video => file('$prefix.mp4', videoBytes);

  LessonMediaCaption caption(String locale,
      {LessonMediaFile? fileOverride, String? mediaSha}) {
    final bytes = locale == 'tr' ? trBytes : enBytes;
    return LessonMediaCaption(
      locale: locale,
      sceneId: _pin.sceneId,
      variantStem: _pin.variantStem,
      courseSourceSha256: _pin.courseSourceSha256,
      lessonCanonicalSha256: _pin.lessonCanonicalSha256,
      productionSpecSha256: _pin.productionSpecSha256,
      sourceCueSha256: _pin.sourceCueSha256,
      mediaSha256: mediaSha ?? video.sha256,
      file: fileOverride ?? file('$prefix.$locale.vtt', bytes),
    );
  }

  LessonMediaCandidate candidate({
    String? app,
    String? lessonId,
    String? sceneId,
    String? stem,
    String? courseSha,
    String? lessonSha,
    String? specSha,
    String? cueSha,
    LessonMediaFile? videoOverride,
    List<LessonMediaCaption>? captions,
    int? durationMs,
  }) =>
      LessonMediaCandidate(
        app: app ?? 'choreia',
        lessonId: lessonId ?? _pin.lessonId,
        sceneId: sceneId ?? _pin.sceneId,
        variantStem: stem ?? _pin.variantStem,
        manifestSha256: choreiaMediaManifestSha256,
        courseSourceSha256: courseSha ?? _pin.courseSourceSha256,
        lessonCanonicalSha256: lessonSha ?? _pin.lessonCanonicalSha256,
        productionSpecSha256: specSha ?? _pin.productionSpecSha256,
        sourceCueSha256: cueSha ?? _pin.sourceCueSha256,
        video: videoOverride ?? video,
        durationMs: durationMs ?? 1000,
        captions: captions ?? [caption('tr'), caption('en')],
      );

  _MediaBundle bundle({Uint8List? video, Uint8List? tr, Uint8List? en}) =>
      _MediaBundle({
        '$prefix.mp4': video ?? videoBytes,
        '$prefix.tr.vtt': tr ?? trBytes,
        '$prefix.en.vtt': en ?? enBytes,
      });

  LessonMediaCatalog catalog({
    List<LessonMediaCandidate>? candidates,
    List<LessonMediaSourcePin>? sourcePins,
  }) =>
      LessonMediaCatalog.synthetic(
        candidates: candidates ?? [candidate()],
        sourcePins: sourcePins ?? [_pin],
      );

  Future<InspectedLessonMedia?> inspect({
    LessonMediaCatalog? catalog,
    _MediaBundle? bundle,
    String locale = 'tr',
    MediaDurationProbe? probe,
  }) =>
      (catalog ?? this.catalog()).inspect(
        bundle: bundle ?? this.bundle(),
        lessonId: _pin.lessonId,
        sceneId: _pin.sceneId,
        variantStem: _pin.variantStem,
        locale: locale,
        durationProbe: probe ?? (_) async => 1000,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shipping catalog is empty and does not read media', () async {
    final fixture = _Fixture();
    final bundle = fixture.bundle();
    final result = await fixture.inspect(
        catalog: const LessonMediaCatalog.empty(), bundle: bundle);
    expect(result, isNull);
    expect(bundle.mediaReads, isEmpty);
  });

  test('exact frozen source, video bytes, two VTT hashes and locale inspect',
      () async {
    final fixture = _Fixture();
    for (final locale in ['tr', 'en']) {
      final result = await fixture.inspect(locale: locale);
      expect(result, isNotNull);
      expect(result!.locale, locale);
      expect(result.visible, isFalse);
      expect(result.releaseEligible, isFalse);
      expect(result.progressEffect, 0);
    }
  });

  test('wrong source identity, lesson SHA, scene, stem or cue stays absent',
      () async {
    final fixture = _Fixture();
    final wrong = <LessonMediaCandidate>[
      fixture.candidate(app: 'ostinato'),
      fixture.candidate(lessonId: 'so_02'),
      fixture.candidate(sceneId: 'choreia:so_01:other'),
      fixture.candidate(stem: '${_pin.variantStem}-other'),
      fixture.candidate(courseSha: _zeroSha),
      fixture.candidate(lessonSha: _zeroSha),
      fixture.candidate(specSha: _zeroSha),
      fixture.candidate(cueSha: _zeroSha),
    ];
    for (final candidate in wrong) {
      expect(
          await fixture.inspect(
              catalog: fixture.catalog(candidates: [candidate])),
          isNull);
    }
  });

  test('media SHA, caption SHA, locale pair and exact caption binding close',
      () async {
    final fixture = _Fixture();
    final wrong = <LessonMediaCandidate>[
      fixture.candidate(
          videoOverride: LessonMediaFile(
              fixture.video.path, fixture.video.bytes, _zeroSha)),
      fixture.candidate(captions: [fixture.caption('tr')]),
      fixture
          .candidate(captions: [fixture.caption('tr'), fixture.caption('tr')]),
      fixture.candidate(captions: [
        fixture.caption('tr',
            fileOverride: LessonMediaFile(
                '${fixture.prefix}.tr.vtt', fixture.trBytes.length, _zeroSha)),
        fixture.caption('en'),
      ]),
      fixture.candidate(captions: [
        fixture.caption('tr', mediaSha: _zeroSha),
        fixture.caption('en'),
      ]),
    ];
    for (final candidate in wrong) {
      expect(
          await fixture.inspect(
              catalog: fixture.catalog(candidates: [candidate])),
          isNull);
    }
  });

  test('missing/tampered bytes, VTT header and measured duration close',
      () async {
    final fixture = _Fixture();
    final missing = fixture.bundle()..files.remove('${fixture.prefix}.mp4');
    expect(await fixture.inspect(bundle: missing), isNull);
    final alteredVideo = Uint8List.fromList(fixture.videoBytes);
    alteredVideo[11] = 0x00;
    final tampered = fixture.bundle(video: alteredVideo);
    expect(await fixture.inspect(bundle: tampered), isNull);
    final wrongVtt = fixture.bundle(
        tr: Uint8List.fromList(utf8.encode(
            'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:00.500\nWrong.\n')));
    expect(await fixture.inspect(bundle: wrongVtt), isNull);
    expect(await fixture.inspect(probe: (_) async => 999), isNull);
    expect(await fixture.inspect(probe: (_) async => null), isNull);
    expect(await fixture.inspect(locale: 'fr'), isNull);
  });

  test('VTT profile closes invalid language and cue timing even with new SHA',
      () async {
    final fixture = _Fixture();
    for (final text in <String>[
      'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:00.500\nWrong language.\n',
      'WEBVTT - Motion locale=tr\n\n00:00:00.800 --> 00:00:01.200\nPast video.\n',
      'WEBVTT - Motion locale=tr\n\n00:00:00.000 --> 00:00:00.500\nFirst.\n\n00:00:00.400 --> 00:00:00.700\nOverlap.\n',
    ]) {
      final bytes = Uint8List.fromList(utf8.encode(text));
      final altered = fixture.candidate(captions: [
        fixture.caption('tr',
            fileOverride: fixture.file('${fixture.prefix}.tr.vtt', bytes)),
        fixture.caption('en'),
      ]);
      expect(
          await fixture.inspect(
            catalog: fixture.catalog(candidates: [altered]),
            bundle: fixture.bundle(tr: bytes),
          ),
          isNull);
    }
  });

  test('declared asset, caption and app budget plus unsafe path close',
      () async {
    final fixture = _Fixture();
    final wrong = <LessonMediaCandidate>[
      fixture.candidate(
          videoOverride: LessonMediaFile(
              fixture.video.path, 64 * 1024 * 1024 + 1, fixture.video.sha256)),
      fixture.candidate(captions: [
        fixture.caption('tr',
            fileOverride: LessonMediaFile('${fixture.prefix}.tr.vtt',
                1024 * 1024 + 1, fixture.caption('tr').file.sha256)),
        fixture.caption('en'),
      ]),
      fixture.candidate(
          videoOverride: LessonMediaFile('content/media/../escape.mp4',
              fixture.video.bytes, fixture.video.sha256)),
    ];
    for (final candidate in wrong) {
      expect(
          await fixture.inspect(
              catalog: fixture.catalog(candidates: [candidate])),
          isNull);
    }
    expect(
        await fixture.inspect(
            catalog: fixture.catalog(
                candidates: [fixture.candidate(), fixture.candidate()])),
        isNull);
  });

  testWidgets('slot remains absent and closes after account/lifecycle change',
      (tester) async {
    final fixture = _Fixture();
    final owner = ValueNotifier<String?>('alice');
    addTearDown(owner.dispose);
    final inspected = <InspectedLessonMedia?>[];
    await tester.pumpWidget(MaterialApp(
      home: LessonMediaSlot(
        catalog: fixture.catalog(),
        bundle: fixture.bundle(),
        lessonId: _pin.lessonId,
        sceneId: _pin.sceneId,
        variantStem: _pin.variantStem,
        locale: 'tr',
        durationProbe: (_) async => 1000,
        accountUserId: owner,
        onInspectionChanged: inspected.add,
      ),
    ));
    for (var i = 0; i < 20 && inspected.isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)));
      await tester.pump();
    }
    expect(inspected, isNotEmpty);
    expect(inspected.last, isNotNull);
    expect(find.byType(SizedBox), findsWidgets);
    expect(find.textContaining('Watch the preparation'), findsNothing);
    owner.value = 'bob';
    expect(inspected.last, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(inspected.last, isNull);
    expect(inspected.whereType<InspectedLessonMedia>(), hasLength(1));
  });
}
