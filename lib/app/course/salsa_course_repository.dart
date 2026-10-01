import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:motion_content/motion_content.dart';

import '../flutter_bundle_content_asset_reader.dart';
import 'salsa_course.dart';

const String salsaCourseAssetPath = 'content/salsa_on1_course.json';
const String salsaIntegrityManifestPath =
    'content/motion_content/manifest.json';

/// Verifies the exact bundled course bytes before interpreting any lesson.
/// The manifest is an asset-integrity envelope, not a second course catalogue.
final class SalsaCourseRepository {
  const SalsaCourseRepository._();

  static Future<SalsaCourse> load(AssetBundle bundle) async {
    final ContentLoadResult result = await ContentBundleLoader(
      reader: FlutterBundleContentAssetReader(bundle: bundle),
      expectedAppId: 'com.yulalab.choreia',
      currentCoreContract: currentMotionContentContract,
      manifestPath: salsaIntegrityManifestPath,
    ).load();
    if (result is ContentBlocked) throw ContentException(result.error);
    if (result is! ContentReady) {
      throw const ContentException(
        ContentError(code: ContentErrorCode.capability),
      );
    }

    final bytes = await result.assets.read(salsaCourseAssetPath);
    try {
      return SalsaCourse.fromJson(
        (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>(),
      );
    } on FormatException {
      throw const ContentException(ContentError(code: ContentErrorCode.schema));
    } on TypeError {
      throw const ContentException(ContentError(code: ContentErrorCode.schema));
    }
  }
}
