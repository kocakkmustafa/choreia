import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart';

import '../../flutter_bundle_content_asset_reader.dart';
import '../salsa_course_repository.dart';
import 'choreia_source_projection_pin.dart';

// Closed v2k source identity for QA only. These pins are not media trust roots.
const String choreiaMediaManifestSha256 =
    ChoreiaSourceProjectionPin.sourceManifestSha256;
const String choreiaMediaSourceCatalogSha256 =
    'd7ca7827a8b703b2cc420b9fe97c73600a063640ac4cba94617158f477c10267';
const String _sourceCatalogPath =
    'content/motion_content/choreia_source_pins_v2k.json';
const String _opsSourceCatalogSha256 =
    ChoreiaSourceProjectionPin.sourceCatalogSha256;
const String _sourceProofSha256 =
    '8adca6131462048b24f531a2fe9ebcb999794e7fbcd7cad6514e02a8ad7ba8cd';
const String _courseSourceSha256 = ChoreiaSourceProjectionPin.courseSha256;
const int _maxMediaBytes = 64 * 1024 * 1024;
const int _maxCaptionBytes = 1024 * 1024;
const int _maxAppMediaBytes = 512 * 1024 * 1024;
final RegExp _sha = RegExp(r'^[0-9a-f]{64}$');

/// Exact QA source row from the code-pinned Choreia subset of ops v2k pins.
/// No media candidates are installed in the shipping catalog.
final class LessonMediaSourcePin {
  const LessonMediaSourcePin({
    required this.assetId,
    required this.lessonId,
    required this.sceneId,
    required this.variantStem,
    required this.courseSourceSha256,
    required this.lessonCanonicalSha256,
    required this.productionSpecSha256,
    required this.sourceCueSha256,
    required this.idempotencyKey,
    required this.productionState,
    required this.sourcePinSha256,
  });

  final String assetId, lessonId, sceneId, variantStem;
  final String courseSourceSha256, lessonCanonicalSha256;
  final String productionSpecSha256, sourceCueSha256;
  final String idempotencyKey, productionState, sourcePinSha256;

  String get key => '$lessonId\u0000$sceneId\u0000$variantStem';
}

final class LessonMediaFile {
  const LessonMediaFile(this.path, this.bytes, this.sha256);
  final String path, sha256;
  final int bytes;
}

/// Mirrors the v3 sidecar's repeated source and media binding for one locale.
final class LessonMediaCaption {
  const LessonMediaCaption({
    required this.locale,
    required this.sceneId,
    required this.variantStem,
    required this.courseSourceSha256,
    required this.lessonCanonicalSha256,
    required this.productionSpecSha256,
    required this.sourceCueSha256,
    required this.mediaSha256,
    required this.file,
  });

  final String locale, sceneId, variantStem;
  final String courseSourceSha256, lessonCanonicalSha256;
  final String productionSpecSha256, sourceCueSha256, mediaSha256;
  final LessonMediaFile file;
}

/// Staging data only. There is deliberately no mutable publication flag.
final class LessonMediaCandidate {
  LessonMediaCandidate({
    required this.app,
    required this.lessonId,
    required this.sceneId,
    required this.variantStem,
    required this.manifestSha256,
    required this.courseSourceSha256,
    required this.lessonCanonicalSha256,
    required this.assetId,
    required this.productionSpecSha256,
    required this.sourceCueSha256,
    required this.idempotencyKey,
    required this.productionState,
    required this.sourcePinSha256,
    required this.video,
    required this.durationMs,
    required List<LessonMediaCaption> captions,
  }) : captions = List<LessonMediaCaption>.unmodifiable(captions);

  final String app, lessonId, sceneId, variantStem, manifestSha256;
  final String courseSourceSha256, lessonCanonicalSha256, assetId;
  final String productionSpecSha256, sourceCueSha256;
  final String idempotencyKey, productionState, sourcePinSha256;
  final LessonMediaFile video;
  final int durationMs;
  final List<LessonMediaCaption> captions;

  String get key => '$lessonId\u0000$sceneId\u0000$variantStem';
  bool get releaseEligible => false;
  bool get visible => false;
  int get progressEffect => 0;
}

/// Successful source/byte inspection is still a hidden test candidate.
final class InspectedLessonMedia {
  const InspectedLessonMedia(this.candidate, this.locale);
  final LessonMediaCandidate candidate;
  final String locale;
  bool get releaseEligible => false;
  bool get visible => false;
  int get progressEffect => 0;
}

typedef MediaDurationProbe = Future<int?> Function(Uint8List videoBytes);

/// App-local, offline staging boundary. The production instance is empty.
/// A future release needs a separate signed acceptance root before a widget
/// can show any of these candidates.
final class LessonMediaCatalog {
  const LessonMediaCatalog.empty() : _candidates = const [];

  /// Synthetic injection for tests; not an app publication path.
  LessonMediaCatalog.synthetic({
    required List<LessonMediaCandidate> candidates,
  }) : _candidates = List.unmodifiable(candidates);

  final List<LessonMediaCandidate> _candidates;

  bool get isEmpty => _candidates.isEmpty;

  Future<InspectedLessonMedia?> inspect({
    required AssetBundle bundle,
    required String lessonId,
    required String sceneId,
    required String variantStem,
    required String locale,
    MediaDurationProbe? durationProbe,
  }) async {
    if (kReleaseMode ||
        _candidates.isEmpty ||
        (locale != 'tr' && locale != 'en')) {
      return null;
    }
    final key = '$lessonId\u0000$sceneId\u0000$variantStem';
    final matches = _candidates.where((candidate) => candidate.key == key);
    if (matches.length != 1 || durationProbe == null) {
      return null;
    }
    final candidate = matches.single;
    if (!_catalogSizeIsSafe() ||
        !_fileShape(candidate.video, '$variantStem.mp4', _maxMediaBytes) ||
        candidate.captions.length != 2 ||
        candidate.durationMs <= 0) {
      return null;
    }
    final captions = <String, LessonMediaCaption>{};
    for (final caption in candidate.captions) {
      if (!{'tr', 'en'}.contains(caption.locale) ||
          captions.containsKey(caption.locale) ||
          !_captionMatches(caption, candidate) ||
          !_fileShape(caption.file, '$variantStem.${caption.locale}.vtt',
              _maxCaptionBytes)) {
        return null;
      }
      captions[caption.locale] = caption;
    }
    if (captions.keys.toSet().length != 2) return null;

    try {
      final source = await _pinnedSource(bundle, candidate);
      if (source == null || !_sourceMatches(candidate, source)) return null;
      // The existing manifest validates exact course bytes before we derive
      // the canonical lesson hash from the same bundled source.
      final course = await SalsaCourseRepository.load(bundle);
      if (course.lesson(lessonId).id != lessonId) return null;
      final reader = FlutterBundleContentAssetReader(bundle: bundle);
      final courseBytes = await reader.read(salsaCourseAssetPath);
      if (computeSha256Hex(courseBytes) != source.courseSourceSha256 ||
          !_canonicalLessonMatches(
              courseBytes, lessonId, source.lessonCanonicalSha256)) {
        return null;
      }
      final video = await reader.read(candidate.video.path);
      if (!_bytesMatch(video, candidate.video, _maxMediaBytes) ||
          !_mp4Signature(video) ||
          await durationProbe(video) != candidate.durationMs) {
        return null;
      }
      for (final caption in captions.values) {
        final bytes = await reader.read(caption.file.path);
        if (!_bytesMatch(bytes, caption.file, _maxCaptionBytes) ||
            !_validMotionVtt(bytes, caption.locale, candidate.durationMs)) {
          return null;
        }
      }
      return InspectedLessonMedia(candidate, locale);
    } catch (_) {
      // Missing/tampered bundle data, an unmeasurable video, or a bad VTT is
      // absence of media. It must never break the existing written lesson.
      return null;
    }
  }

  bool _catalogSizeIsSafe() {
    var total = 0;
    final paths = <String>{};
    final keys = <String>{};
    const supportedLocales = <String>{'tr', 'en'};
    for (final candidate in _candidates) {
      if (!keys.add(candidate.key) ||
          candidate.durationMs <= 0 ||
          !_fileShape(candidate.video, '${candidate.variantStem}.mp4',
              _maxMediaBytes) ||
          candidate.captions.length != 2) {
        return false;
      }
      final locales = <String>{};
      for (final caption in candidate.captions) {
        if (!supportedLocales.contains(caption.locale) ||
            !locales.add(caption.locale) ||
            !_captionMatches(caption, candidate) ||
            !_fileShape(
                caption.file,
                '${candidate.variantStem}.${caption.locale}.vtt',
                _maxCaptionBytes)) {
          return false;
        }
      }
      if (locales.length != 2) return false;
      for (final file in <LessonMediaFile>[
        candidate.video,
        ...candidate.captions.map((caption) => caption.file),
      ]) {
        if (file.bytes <= 0 || !paths.add(file.path)) return false;
        total += file.bytes;
        if (total > _maxAppMediaBytes) return false;
      }
    }
    return true;
  }
}

bool _sourceMatches(LessonMediaCandidate candidate, LessonMediaSourcePin pin) =>
    candidate.app == 'choreia' &&
    candidate.manifestSha256 == choreiaMediaManifestSha256 &&
    candidate.assetId == pin.assetId &&
    candidate.lessonId == pin.lessonId &&
    candidate.sceneId == pin.sceneId &&
    candidate.variantStem == pin.variantStem &&
    candidate.courseSourceSha256 == pin.courseSourceSha256 &&
    candidate.lessonCanonicalSha256 == pin.lessonCanonicalSha256 &&
    candidate.productionSpecSha256 == pin.productionSpecSha256 &&
    candidate.sourceCueSha256 == pin.sourceCueSha256 &&
    candidate.idempotencyKey == pin.idempotencyKey &&
    candidate.productionState == pin.productionState &&
    candidate.sourcePinSha256 == pin.sourcePinSha256 &&
    candidate.productionState == 'PREPRODUCTION_UNGENERATED' &&
    candidate.idempotencyKey ==
        'motion-media-v1:${candidate.productionSpecSha256}' &&
    _computedSourcePin(candidate) == pin.sourcePinSha256 &&
    _sha.hasMatch(candidate.courseSourceSha256) &&
    _sha.hasMatch(candidate.lessonCanonicalSha256) &&
    _sha.hasMatch(candidate.productionSpecSha256) &&
    _sha.hasMatch(candidate.sourceCueSha256) &&
    _sha.hasMatch(candidate.sourcePinSha256);

String _computedSourcePin(LessonMediaCandidate candidate) {
  // Insertion order is the ops canonical JSON key order (sort_keys=True).
  final identity = <String, String>{
    'app': candidate.app,
    'assetId': candidate.assetId,
    'courseSourceSHA256': candidate.courseSourceSha256,
    'idempotencyKey': candidate.idempotencyKey,
    'lessonCanonicalSHA256': candidate.lessonCanonicalSha256,
    'lessonId': candidate.lessonId,
    'manifestSHA256': candidate.manifestSha256,
    'productionSpecSHA256': candidate.productionSpecSha256,
    'productionState': candidate.productionState,
    'sceneId': candidate.sceneId,
    'sourceCueSHA256': candidate.sourceCueSha256,
    'variantStem': candidate.variantStem,
  };
  return computeSha256Hex(
      Uint8List.fromList(utf8.encode(jsonEncode(identity))));
}

Future<LessonMediaSourcePin?> _pinnedSource(
    AssetBundle bundle, LessonMediaCandidate candidate) async {
  final reader = FlutterBundleContentAssetReader(bundle: bundle);
  final bytes = await reader.read(_sourceCatalogPath);
  if (computeSha256Hex(bytes) != choreiaMediaSourceCatalogSha256) return null;
  final value = jsonDecode(utf8.decode(bytes));
  if (value is! Map<String, dynamic> ||
      value['schemaVersion'] != 1 ||
      value['kind'] != 'CHOREIA_V2K_SOURCE_PINS_QA_ONLY' ||
      value['sourceCatalogSHA256'] != _opsSourceCatalogSha256 ||
      value['manifestSHA256'] != choreiaMediaManifestSha256 ||
      value['sourceProofSHA256'] != _sourceProofSha256 ||
      value['courseSourceSHA256'] != _courseSourceSha256 ||
      value['visible'] != false ||
      value['releaseEligible'] != false ||
      value['progressEffect'] != 0 ||
      value['counts'] is! Map<String, dynamic> ||
      value['lessons'] is! List) {
    return null;
  }
  final counts = value['counts'] as Map<String, dynamic>;
  if (counts['lessons'] != 48 ||
      counts['scenes'] != 436 ||
      counts['variants'] != 872 ||
      counts['generatedMedia'] != 0 ||
      counts['qualifiedMedia'] != 0) {
    return null;
  }
  final lessons = (value['lessons'] as List)
      .whereType<Map<String, dynamic>>()
      .where((row) =>
          row['app'] == 'choreia' && row['lessonId'] == candidate.lessonId);
  if (lessons.length != 1) return null;
  final lesson = lessons.single;
  if (lesson['membershipStatus'] != 'SOURCE_PINNED_TEST_ONLY' ||
      lesson['scenes'] is! List) {
    return null;
  }
  final scenes = (lesson['scenes'] as List)
      .whereType<Map<String, dynamic>>()
      .where((row) => row['sceneId'] == candidate.sceneId);
  if (scenes.length != 1) return null;
  final scene = scenes.single;
  if (scene['productionState'] != 'PREPRODUCTION_UNGENERATED' ||
      scene['variants'] is! List) {
    return null;
  }
  final variants = (scene['variants'] as List)
      .whereType<Map<String, dynamic>>()
      .where((row) => row['stem'] == candidate.variantStem);
  if (variants.length != 1) return null;
  final variant = variants.single;
  return LessonMediaSourcePin(
    assetId: lesson['assetId'] as String,
    lessonId: lesson['lessonId'] as String,
    sceneId: scene['sceneId'] as String,
    variantStem: variant['stem'] as String,
    courseSourceSha256: lesson['courseSourceSHA256'] as String,
    lessonCanonicalSha256: lesson['lessonCanonicalSHA256'] as String,
    productionSpecSha256: scene['productionSpecSHA256'] as String,
    sourceCueSha256: scene['sourceCueSHA256'] as String,
    idempotencyKey: scene['idempotencyKey'] as String,
    productionState: scene['productionState'] as String,
    sourcePinSha256: variant['sourcePinSHA256'] as String,
  );
}

bool _captionMatches(
        LessonMediaCaption caption, LessonMediaCandidate candidate) =>
    caption.sceneId == candidate.sceneId &&
    caption.variantStem == candidate.variantStem &&
    caption.courseSourceSha256 == candidate.courseSourceSha256 &&
    caption.lessonCanonicalSha256 == candidate.lessonCanonicalSha256 &&
    caption.productionSpecSha256 == candidate.productionSpecSha256 &&
    caption.sourceCueSha256 == candidate.sourceCueSha256 &&
    caption.mediaSha256 == candidate.video.sha256;

bool _fileShape(LessonMediaFile file, String suffix, int maxBytes) {
  if (file.bytes <= 0 || file.bytes > maxBytes || !_sha.hasMatch(file.sha256)) {
    return false;
  }
  try {
    PathPolicy.validate(file.path);
  } catch (_) {
    return false;
  }
  return file.path == 'content/media/$suffix';
}

bool _bytesMatch(Uint8List bytes, LessonMediaFile file, int maxBytes) =>
    bytes.isNotEmpty &&
    bytes.length <= maxBytes &&
    bytes.length == file.bytes &&
    computeSha256Hex(bytes) == file.sha256;

bool _canonicalLessonMatches(
    Uint8List courseBytes, String lessonId, String sha) {
  final value = jsonDecode(utf8.decode(courseBytes));
  if (value is! Map<String, dynamic> || value['lessons'] is! List) return false;
  final lessons = (value['lessons'] as List).where(
      (lesson) => lesson is Map<String, dynamic> && lesson['id'] == lessonId);
  if (lessons.length != 1) return false;
  final canonical = utf8.encode(canonicalJsonEncode(lessons.single));
  return computeSha256Hex(Uint8List.fromList(canonical)) == sha;
}

bool _mp4Signature(Uint8List bytes) =>
    bytes.length >= 12 &&
    bytes[4] == 0x66 &&
    bytes[5] == 0x74 &&
    bytes[6] == 0x79 &&
    bytes[7] == 0x70;

final RegExp _timing = RegExp(
    r'^(\d{2,}):([0-5]\d):([0-5]\d)\.(\d{3}) --> (\d{2,}):([0-5]\d):([0-5]\d)\.(\d{3})$');

bool _validMotionVtt(Uint8List bytes, String locale, int durationMs) {
  final value = utf8.decode(bytes);
  if (value.contains('\r') ||
      value.contains('\ufeff') ||
      value.contains('\u0000')) {
    return false;
  }
  final header = 'WEBVTT - Motion locale=$locale\n\n';
  if (!value.startsWith(header)) return false;
  final body = value.substring(header.length).replaceFirst(RegExp(r'\n+$'), '');
  if (body.isEmpty) return false;
  var previousEnd = 0;
  for (final block in body.split('\n\n')) {
    final lines = block.split('\n');
    if (lines.length < 2 || lines.any((line) => line.trim().isEmpty)) {
      return false;
    }
    final match = _timing.firstMatch(lines.first);
    if (match == null) return false;
    int ms(int offset) =>
        ((int.parse(match.group(offset)!) * 60 +
                        int.parse(match.group(offset + 1)!)) *
                    60 +
                int.parse(match.group(offset + 2)!)) *
            1000 +
        int.parse(match.group(offset + 3)!);
    final start = ms(1), end = ms(5);
    if (end <= start || start < previousEnd || end > durationMs) return false;
    for (final line in lines.skip(1)) {
      if (line.contains('<') ||
          line.contains('>') ||
          line.contains('-->') ||
          line.runes.any((rune) => rune < 32 && rune != 9)) {
        return false;
      }
    }
    previousEnd = end;
  }
  return true;
}
