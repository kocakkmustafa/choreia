import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/media/lesson_media_catalog.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_content/motion_content.dart';

import 'support/test_catalog.dart';

// Exact ops v2m so_01 row for the live course; synthetic QA bytes, no release
// acceptance.
const _pin = LessonMediaSourcePin(
  assetId: 'choreia.so_01.v6.demo',
  lessonId: 'so_01',
  sceneId: 'choreia:so_01:orientation',
  variantStem:
      'choreia/so-01--becaa07c/orientation--0ca858650586c9d903921063f9206f6230778faf491d0dd17beb68c7a1c38d7d--master-16x9',
  courseSourceSha256:
      '284d429656ec8ca56fd10674685cf61069d157a6ee985eb764818ae9db11907d',
  lessonCanonicalSha256:
      '05b4bc7664a0143fd0f75bd4d98ef2934ab9ae9eeb381224d7bbb8f73ffe7a2b',
  productionSpecSha256:
      '0ca858650586c9d903921063f9206f6230778faf491d0dd17beb68c7a1c38d7d',
  sourceCueSha256:
      '15cc3828f0b88eedff915b7a2277befa358942030e1e3436a97ffe06367a7f18',
  idempotencyKey:
      'motion-media-v1:0ca858650586c9d903921063f9206f6230778faf491d0dd17beb68c7a1c38d7d',
  productionState: 'PREPRODUCTION_UNGENERATED',
  sourcePinSha256:
      '61d7ec47bfb2134f913c9d921a869ff402929da322f246b8086b557aea93d16a',
);
const _zeroSha =
    '0000000000000000000000000000000000000000000000000000000000000000';

final class _MediaBundle extends DiskBundle {
  _MediaBundle(this.files);
  final Map<String, Uint8List> files;
  final List<String> loadedKeys = [];
  final List<String> mediaReads = [];
  final List<String> pinReads = [];

  @override
  Future<ByteData> load(String key) async {
    loadedKeys.add(key);
    if (key == 'content/motion_content/choreia_source_pins_v2m.json') {
      pinReads.add(key);
    }
    if (key.startsWith('content/media/') || files.containsKey(key)) {
      if (key.startsWith('content/media/')) mediaReads.add(key);
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
    String? manifestSha,
    String? courseSha,
    String? lessonSha,
    String? assetId,
    String? specSha,
    String? cueSha,
    String? idempotencyKey,
    String? productionState,
    String? sourcePinSha,
    LessonMediaFile? videoOverride,
    List<LessonMediaCaption>? captions,
    int? durationMs,
  }) =>
      LessonMediaCandidate(
        app: app ?? 'choreia',
        lessonId: lessonId ?? _pin.lessonId,
        sceneId: sceneId ?? _pin.sceneId,
        variantStem: stem ?? _pin.variantStem,
        manifestSha256: manifestSha ?? choreiaMediaManifestSha256,
        courseSourceSha256: courseSha ?? _pin.courseSourceSha256,
        lessonCanonicalSha256: lessonSha ?? _pin.lessonCanonicalSha256,
        assetId: assetId ?? _pin.assetId,
        productionSpecSha256: specSha ?? _pin.productionSpecSha256,
        sourceCueSha256: cueSha ?? _pin.sourceCueSha256,
        idempotencyKey: idempotencyKey ?? _pin.idempotencyKey,
        productionState: productionState ?? _pin.productionState,
        sourcePinSha256: sourcePinSha ?? _pin.sourcePinSha256,
        video: videoOverride ?? video,
        durationMs: durationMs ?? 1000,
        captions: captions ?? [caption('tr'), caption('en')],
      );

  _MediaBundle bundle(
          {Uint8List? video,
          Uint8List? tr,
          Uint8List? en,
          Uint8List? sourcePins}) =>
      _MediaBundle({
        '$prefix.mp4': video ?? videoBytes,
        '$prefix.tr.vtt': tr ?? trBytes,
        '$prefix.en.vtt': en ?? enBytes,
        if (sourcePins != null)
          'content/motion_content/choreia_source_pins_v2m.json': sourcePins,
      });

  LessonMediaCatalog catalog({
    List<LessonMediaCandidate>? candidates,
  }) =>
      LessonMediaCatalog.synthetic(
        candidates: candidates ?? [candidate()],
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
    expect(bundle.pinReads, isEmpty);
  });

  test('exact authored source row, video bytes, two VTT hashes and locale inspect',
      () async {
    final fixture = _Fixture();
    for (final locale in ['tr', 'en']) {
      final result = await fixture.inspect(locale: locale);
      expect(result, isNotNull);
      expect(result!.locale, locale);
      expect(result.visible, isFalse);
      expect(result.releaseEligible, isFalse);
      expect(result.progressEffect, 0);
      expect(result.candidate.sourcePinSha256, _pin.sourcePinSha256);
    }
  });

  test('caption metadata stays fixed while the duration probe is pending',
      () async {
    final fixture = _Fixture();
    final suppliedCaptions = <LessonMediaCaption>[
      fixture.caption('tr'),
      fixture.caption('en'),
    ];
    final originalTr = suppliedCaptions.first;
    final wrongTrPath = 'content/other/${_pin.variantStem}.tr.vtt';
    final wrongTr = fixture.caption('tr',
        fileOverride: fixture.file(wrongTrPath, fixture.trBytes));
    expect(() => PathPolicy.validate(wrongTrPath), returnsNormally);
    expect(wrongTr.file.bytes, originalTr.file.bytes);
    expect(wrongTr.file.sha256, originalTr.file.sha256);
    final candidate = fixture.candidate(captions: suppliedCaptions);
    final bundle = fixture.bundle()..files[wrongTrPath] = fixture.trBytes;
    final probeStarted = Completer<void>();
    final resumeProbe = Completer<int?>();
    addTearDown(() {
      if (!resumeProbe.isCompleted) resumeProbe.complete(1000);
    });
    final pending = fixture.inspect(
      catalog: fixture.catalog(candidates: [candidate]),
      bundle: bundle,
      probe: (_) {
        probeStarted.complete();
        return resumeProbe.future;
      },
    );

    await probeStarted.future.timeout(const Duration(seconds: 5));
    suppliedCaptions[0] = wrongTr;
    resumeProbe.complete(1000);
    final inspected = await pending;

    expect(inspected, isNotNull);
    final media = inspected!;
    expect(media.candidate.captions.first, same(originalTr));
    expect(media.candidate.captions.first.file.path, originalTr.file.path);
    expect(bundle.loadedKeys, contains(originalTr.file.path));
    expect(bundle.loadedKeys, isNot(contains(wrongTrPath)));
    expect(() => candidate.captions[0] = wrongTr, throwsUnsupportedError);
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
      // The actual frozen predecessor is stale for this authored revision.
      fixture.candidate(courseSha: 'b96ba7c9e83c84c229500f2e896dd3641d55833aa53843e94a6f9f90f92d4ca7'),
      fixture.candidate(manifestSha: 'd887683c9a9b9bdb8d4ab7c51cdc5a5b4b4de6a918079e4cfd9cf543e9751e60'),
      // The pre-v2m app-local row: unresolvable course and manifest roots, and
      // the v2l projection manifest this catalog used to borrow.
      fixture.candidate(
          courseSha:
              'd04ef4c413c6db0ca8858c1cf11d231cd9614adecff71aa41cc752481007cbfc'),
      fixture.candidate(
          specSha:
              '1ed099b8a8d6dcaa4fd41ed0d54c69c3b4fdbc3fc297bc96ce7643a8aa60daa7',
          idempotencyKey:
              'motion-media-v1:1ed099b8a8d6dcaa4fd41ed0d54c69c3b4fdbc3fc297bc96ce7643a8aa60daa7',
          sourcePinSha:
              '67cfed6b6266f23a7204887f59f2686a38b67678b63d6e8e277786e9d9061a9d'),
      fixture.candidate(
          manifestSha:
              'c98bde343ed0529d0717ca70b56cae529e0fbededecdbaf4ef6934230c324b64'),
      fixture.candidate(
          manifestSha:
              'ef6eaa2ba38d0b3abdc7300e6bbf7af419ec9484c1fbd7dca8de174ddadb0adc'),
      fixture.candidate(specSha: '645453e973c9403268dd65bc740e21e304bb1036f52b00ac7006bb10262ee9f3'),
      fixture.candidate(sourcePinSha: '6e5af428a718c6aa135f9049114a7d0b96b5ca73ea2762fcf999bfaf86d7f6fc'),
      fixture.candidate(
          courseSha:
              'd81c48841905ece680c58467032c6f6126f335eecbbfe77c6e812e3ad9ef1598'),
      fixture.candidate(lessonSha: _zeroSha),
      fixture.candidate(assetId: 'choreia.so_02.v6.demo'),
      fixture.candidate(specSha: _zeroSha),
      fixture.candidate(cueSha: _zeroSha),
      fixture.candidate(idempotencyKey: 'motion-media-v1:old'),
      fixture.candidate(productionState: 'GENERATED'),
      fixture.candidate(sourcePinSha: _zeroSha),
      fixture.candidate(
          sourcePinSha:
              '229fe0ec2be21db118e61e19093781b856a9c993376748cb34dfd4b6662be676'),
      fixture.candidate(
          manifestSha:
              'deb767cc1060cb475bf5664e0c662b44b0a0ad8318288b4e65faa3c472cb6324'),
      fixture.candidate(
          manifestSha:
              '21008cbf5a58d01c3ef4a12c879f1b6da4e8d8ea5111f8340d53d35f9ec02c8b'),
      fixture.candidate(
          manifestSha:
              '5399b0fd21bd7148de9c845ecaf288e391fef4c6e2ae98503fd9134fd39e8628'),
      // Real v2d/v2g specs with a freshly computed v2k-labelled pin still
      // cannot claim this current source row.
      fixture.candidate(
          specSha:
              '6ed07abbf32c3d8a212cd82f5d237b830e5a307789c315a59415c531fcf0a28c',
          idempotencyKey:
              'motion-media-v1:6ed07abbf32c3d8a212cd82f5d237b830e5a307789c315a59415c531fcf0a28c',
          sourcePinSha:
              'f3ceb1b9ed55be5b9e6fc22555f5efeb7008723c76e4d5b3f8f3724cc461533c'),
      fixture.candidate(
          specSha:
              'b6f2b2b57fc374d01084bf7dccac6eee90755d049187d9c80f86236ee4ad5098',
          idempotencyKey:
              'motion-media-v1:b6f2b2b57fc374d01084bf7dccac6eee90755d049187d9c80f86236ee4ad5098',
          sourcePinSha:
              '50336cfff92652bd47a2462c5f17867e5e6d3d24da3d811669c5816f62cd9584'),
    ];
    for (final candidate in wrong) {
      expect(
          await fixture.inspect(
              catalog: fixture.catalog(candidates: [candidate])),
          isNull);
    }
  });

  test('forged QA source catalog cannot supply its own pin', () async {
    final fixture = _Fixture();
    final path = File('content/motion_content/choreia_source_pins_v2m.json');
    final original = await path.readAsBytes();
    final decoded = jsonDecode(utf8.decode(original)) as Map<String, dynamic>;
    final lessons = decoded['lessons'] as List;
    final lesson = (lessons.cast<Map<String, dynamic>>())
        .singleWhere((row) => row['lessonId'] == 'so_01');
    final scene = (lesson['scenes'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((row) => row['sceneId'] == _pin.sceneId);
    final variant = (scene['variants'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((row) => row['stem'] == _pin.variantStem);
    variant['sourcePinSHA256'] = _zeroSha;
    final forged = Uint8List.fromList(utf8.encode(jsonEncode(decoded)));
    final bundle = fixture.bundle(sourcePins: forged);
    final result = await fixture.inspect(
        catalog: fixture.catalog(candidates: [
          fixture.candidate(sourcePinSha: _zeroSha),
        ]),
        bundle: bundle);
    expect(result, isNull);
    expect(bundle.pinReads, hasLength(1));
    expect(bundle.mediaReads, isEmpty);
    expect(computeSha256Hex(original), choreiaMediaSourceCatalogSha256);
    expect(decoded['counts'], containsPair('variants', 872));
    expect(lessons, hasLength(48));
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

  test('an unselected wrong-root file rejects the entire catalog before reads',
      () async {
    final fixture = _Fixture();
    final selected = fixture.candidate();
    final otherSceneId = '${selected.sceneId}-unselected';
    final otherStem = '${selected.variantStem}-unselected';
    final expectedVideo =
        fixture.file('content/media/$otherStem.mp4', fixture.videoBytes);
    final wrongVideo =
        fixture.file('content/other/$otherStem.mp4', fixture.videoBytes);
    final expectedTr =
        fixture.file('content/media/$otherStem.tr.vtt', fixture.trBytes);
    final wrongTr =
        fixture.file('content/other/$otherStem.tr.vtt', fixture.trBytes);
    final expectedEn =
        fixture.file('content/media/$otherStem.en.vtt', fixture.enBytes);
    expect(() => PathPolicy.validate(wrongVideo.path), returnsNormally);
    expect(() => PathPolicy.validate(wrongTr.path), returnsNormally);
    expect(wrongVideo.sha256, expectedVideo.sha256);
    expect(wrongTr.sha256, expectedTr.sha256);

    LessonMediaCaption caption(String locale, LessonMediaFile file) =>
        LessonMediaCaption(
          locale: locale,
          sceneId: otherSceneId,
          variantStem: otherStem,
          courseSourceSha256: selected.courseSourceSha256,
          lessonCanonicalSha256: selected.lessonCanonicalSha256,
          productionSpecSha256: selected.productionSpecSha256,
          sourceCueSha256: selected.sourceCueSha256,
          mediaSha256: expectedVideo.sha256,
          file: file,
        );

    LessonMediaCandidate unselected(
      LessonMediaFile video,
      LessonMediaFile tr,
    ) =>
        LessonMediaCandidate(
          app: selected.app,
          lessonId: selected.lessonId,
          sceneId: otherSceneId,
          variantStem: otherStem,
          manifestSha256: selected.manifestSha256,
          courseSourceSha256: selected.courseSourceSha256,
          lessonCanonicalSha256: selected.lessonCanonicalSha256,
          assetId: selected.assetId,
          productionSpecSha256: selected.productionSpecSha256,
          sourceCueSha256: selected.sourceCueSha256,
          idempotencyKey: selected.idempotencyKey,
          productionState: selected.productionState,
          sourcePinSha256: selected.sourcePinSha256,
          video: video,
          durationMs: selected.durationMs,
          captions: [caption('tr', tr), caption('en', expectedEn)],
        );

    for (final poisoned in [
      unselected(wrongVideo, expectedTr),
      unselected(expectedVideo, wrongTr),
    ]) {
      final bundle = fixture.bundle()
        ..files[wrongVideo.path] = fixture.videoBytes
        ..files[wrongTr.path] = fixture.trBytes;
      final result = await fixture.inspect(
        catalog: fixture.catalog(candidates: [selected, poisoned]),
        bundle: bundle,
      );
      expect(result, isNull);
      expect(bundle.loadedKeys, isEmpty);
    }
  });

  for (final revocation in <String>[
    'empty catalog',
    'null scene',
    'null variant'
  ]) {
    testWidgets('pending inspection is revoked by $revocation on the same slot',
        (tester) async {
      final fixture = _Fixture();
      final catalog = fixture.catalog();
      final bundle = fixture.bundle();
      final inspected = <InspectedLessonMedia?>[];
      final probeStarted = Completer<void>();
      final resumeProbe = Completer<int?>();
      addTearDown(() {
        if (!resumeProbe.isCompleted) resumeProbe.complete(1000);
      });
      Future<int?> probe(Uint8List _) {
        if (!probeStarted.isCompleted) probeStarted.complete();
        return resumeProbe.future;
      }

      Widget slot({required bool revoked}) => MaterialApp(
            home: Align(
                child: LessonMediaSlot(
              key: const Key('same.inspection.slot'),
              catalog: revoked && revocation == 'empty catalog'
                  ? const LessonMediaCatalog.empty()
                  : catalog,
              bundle: bundle,
              lessonId: _pin.lessonId,
              sceneId:
                  revoked && revocation == 'null scene' ? null : _pin.sceneId,
              variantStem: revoked && revocation == 'null variant'
                  ? null
                  : _pin.variantStem,
              locale: 'tr',
              durationProbe: probe,
              onInspectionChanged: inspected.add,
            )),
          );

      await tester.pumpWidget(slot(revoked: false));
      await tester.runAsync(
          () => probeStarted.future.timeout(const Duration(seconds: 5)));
      expect(inspected.whereType<InspectedLessonMedia>(), isEmpty);
      final originalState =
          tester.state(find.byKey(const Key('same.inspection.slot')));

      await tester.pumpWidget(slot(revoked: true));
      expect(tester.state(find.byKey(const Key('same.inspection.slot'))),
          same(originalState));
      resumeProbe.complete(1000);
      await tester.pump();
      await tester.pump();

      // Witness that the old inspection really finished its remaining byte
      // checks; absence of a callback must come from revocation, not a hang.
      expect(
          bundle.mediaReads,
          containsAll(<String>[
            '${fixture.prefix}.mp4',
            '${fixture.prefix}.tr.vtt',
            '${fixture.prefix}.en.vtt',
          ]));
      expect(inspected, isNotEmpty);
      expect(inspected.last, isNull);
      expect(inspected.whereType<InspectedLessonMedia>(), isEmpty);
      expect(
          tester.getSize(find.byKey(const Key('same.inspection.slot'))).height,
          0);
      expect(find.textContaining('Watch the preparation'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

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
