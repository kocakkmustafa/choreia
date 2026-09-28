import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart';

import '../../flutter_bundle_content_asset_reader.dart';
import '../salsa_course_repository.dart';

// This is the frozen production v2 source index, not a media acceptance root.
const String choreiaMediaManifestSha256 =
    '2ab9b9fbff2fd5d829160a2d3ef925ac99a4aa3bdd39ac1fe15a1e57248261b3';
const int _maxMediaBytes = 64 * 1024 * 1024;
const int _maxCaptionBytes = 1024 * 1024;
const int _maxAppMediaBytes = 512 * 1024 * 1024;
final RegExp _sha = RegExp(r'^[0-9a-f]{64}$');

/// One independent source pin from the frozen v2 lesson/scene/variant index.
/// No source pins or media candidates are installed in the shipping catalog.
final class LessonMediaSourcePin {
  const LessonMediaSourcePin({
    required this.lessonId,
    required this.sceneId,
    required this.variantStem,
    required this.courseSourceSha256,
    required this.lessonCanonicalSha256,
    required this.productionSpecSha256,
    required this.sourceCueSha256,
  });

  final String lessonId, sceneId, variantStem;
  final String courseSourceSha256, lessonCanonicalSha256;
  final String productionSpecSha256, sourceCueSha256;

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
  const LessonMediaCandidate({
    required this.app,
    required this.lessonId,
    required this.sceneId,
    required this.variantStem,
    required this.manifestSha256,
    required this.courseSourceSha256,
    required this.lessonCanonicalSha256,
    required this.productionSpecSha256,
    required this.sourceCueSha256,
    required this.video,
    required this.durationMs,
    required this.captions,
  });

  final String app, lessonId, sceneId, variantStem, manifestSha256;
  final String courseSourceSha256, lessonCanonicalSha256;
  final String productionSpecSha256, sourceCueSha256;
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
  const LessonMediaCatalog.empty()
      : _candidates = const [],
        _sourcePins = const [];

  /// Synthetic injection for tests; not an app publication path.
  LessonMediaCatalog.synthetic({
    required List<LessonMediaCandidate> candidates,
    required List<LessonMediaSourcePin> sourcePins,
  })  : _candidates = List.unmodifiable(candidates),
        _sourcePins = List.unmodifiable(sourcePins);

  final List<LessonMediaCandidate> _candidates;
  final List<LessonMediaSourcePin> _sourcePins;

  bool get isEmpty => _candidates.isEmpty;

  Future<InspectedLessonMedia?> inspect({
    required AssetBundle bundle,
    required String lessonId,
    required String sceneId,
    required String variantStem,
    required String locale,
    MediaDurationProbe? durationProbe,
  }) async {
    if (_candidates.isEmpty || (locale != 'tr' && locale != 'en')) return null;
    final key = '$lessonId\u0000$sceneId\u0000$variantStem';
    final matches = _candidates.where((candidate) => candidate.key == key);
    final sources = _sourcePins.where((pin) => pin.key == key);
    if (matches.length != 1 || sources.length != 1 || durationProbe == null) {
      return null;
    }
    final candidate = matches.single;
    final source = sources.single;
    if (!_sourceMatches(candidate, source) ||
        !_catalogSizeIsSafe() ||
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
    for (final candidate in _candidates) {
      if (!keys.add(candidate.key)) return false;
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
    candidate.lessonId == pin.lessonId &&
    candidate.sceneId == pin.sceneId &&
    candidate.variantStem == pin.variantStem &&
    candidate.courseSourceSha256 == pin.courseSourceSha256 &&
    candidate.lessonCanonicalSha256 == pin.lessonCanonicalSha256 &&
    candidate.productionSpecSha256 == pin.productionSpecSha256 &&
    candidate.sourceCueSha256 == pin.sourceCueSha256 &&
    _sha.hasMatch(candidate.courseSourceSha256) &&
    _sha.hasMatch(candidate.lessonCanonicalSha256) &&
    _sha.hasMatch(candidate.productionSpecSha256) &&
    _sha.hasMatch(candidate.sourceCueSha256);

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
