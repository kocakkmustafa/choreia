import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:motion_content/motion_content.dart' show computeSha256Hex;
import 'package:motion_media/motion_media.dart'
    show SourceProjectionData, SourceProjectionDecoder, SourceProjectionPin;

import 'choreia_source_projection_pin.dart';

typedef ChoreiaSourceProjectionObserver = FutureOr<void> Function(
    ChoreiaSourceProjectionResult result);

/// Source identity is an observation, never a release or learning receipt.
sealed class ChoreiaSourceProjectionResult {
  const ChoreiaSourceProjectionResult();

  String get code;
  bool get mediaAvailable => false;
  bool get releaseEligible => false;
  bool get paidAccess => false;
  int get progressEffect => 0;
}

final class ChoreiaSourceVerifiedNoMedia extends ChoreiaSourceProjectionResult {
  const ChoreiaSourceVerifiedNoMedia._(this.source);

  @override
  String get code => 'SOURCE_VERIFIED_NO_MEDIA';

  final SourceProjectionData source;
}

final class ChoreiaSourceUnavailableNoMedia
    extends ChoreiaSourceProjectionResult {
  const ChoreiaSourceUnavailableNoMedia();

  @override
  String get code => 'SOURCE_UNAVAILABLE_NO_MEDIA';
}

/// Reads app-owned raw v1 pins, then uses only Core's public decoder. A retired
/// route stops admission before the next asset read as well as after each await.
abstract final class ChoreiaSourceProjectionAdapter {
  static Future<ChoreiaSourceProjectionResult> load({
    AssetBundle? bundle,
    bool Function()? isCurrent,
  }) async {
    final assets = bundle ?? rootBundle;
    bool current() => isCurrent?.call() ?? true;
    try {
      if (!current()) return const ChoreiaSourceUnavailableNoMedia();
      await _readPinned(assets, ChoreiaSourceProjectionPin.coursePath,
          ChoreiaSourceProjectionPin.courseSha256);
      if (!current()) return const ChoreiaSourceUnavailableNoMedia();
      await _readPinned(assets, ChoreiaSourceProjectionPin.slicePath,
          ChoreiaSourceProjectionPin.sliceSha256);
      if (!current()) return const ChoreiaSourceUnavailableNoMedia();
      final projection = await _readPinned(
          assets,
          ChoreiaSourceProjectionPin.projectionPath,
          ChoreiaSourceProjectionPin.projectionSha256);
      if (!current()) return const ChoreiaSourceUnavailableNoMedia();
      final source = SourceProjectionDecoder.decode(
        projection,
        pin: SourceProjectionPin(
          appId: ChoreiaSourceProjectionPin.appId,
          projectionSha256: ChoreiaSourceProjectionPin.projectionSha256,
          sourceCatalogSha256: ChoreiaSourceProjectionPin.sourceCatalogSha256,
          sourceManifestSha256: ChoreiaSourceProjectionPin.sourceManifestSha256,
          courseSourceSha256: ChoreiaSourceProjectionPin.courseSha256,
          variantCount: ChoreiaSourceProjectionPin.variantCount,
          heldCount: ChoreiaSourceProjectionPin.heldCount,
        ),
      );
      return ChoreiaSourceVerifiedNoMedia._(source);
    } catch (_) {
      return const ChoreiaSourceUnavailableNoMedia();
    }
  }

  static Future<Uint8List> _readPinned(
      AssetBundle bundle, String path, String expectedSha256) async {
    final data = await bundle.load(path);
    if (data.lengthInBytes == 0 ||
        data.lengthInBytes > SourceProjectionDecoder.maxBytes) {
      throw StateError('Source asset size mismatch: $path');
    }
    final bytes = Uint8List.sublistView(data);
    if (computeSha256Hex(bytes) != expectedSha256) {
      throw StateError('Source asset SHA mismatch: $path');
    }
    return bytes;
  }
}
