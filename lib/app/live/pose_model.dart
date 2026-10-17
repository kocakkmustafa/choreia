import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:motion_content/motion_content.dart' show computeSha256Hex;
import 'package:path_provider/path_provider.dart';

/// The pose model this app runs, pinned.
///
/// Why a pin and not just a path
/// -----------------------------
/// The family measured (M-L-01) that MediaPipe's `/float16/latest/` and
/// `/float16/1/` bundles for the `full` variant are DIFFERENT files at
/// IDENTICAL size — 9,398,198 bytes either way, different hashes. A size check
/// would pass; the joint angles would not match the ones the reference
/// artefacts were built from, and every score would drift for a reason no
/// screen could explain. So the version segment is pinned, the hash is
/// declared, and `tool/fetch_pose_model.sh` refuses a file that does not match.
///
/// The file is NOT in git: the family keeps `.task` binaries out of the tree.
/// It arrives via that script, which prefers a copy from the family line over
/// a download.
final class PoseModelPin {
  const PoseModelPin._();

  static const String assetPath = 'assets/models/pose_landmarker_full.v1.task';

  /// Stamped into every frame envelope's provenance by `motion_camera`, so a
  /// model swap can never silently reinterpret a session.
  static const String modelId = 'pose_landmarker_full/float16/1';

  static const String sha256 =
      '5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1';

  /// `latest` may never appear here — see the note above.
  static const String versionSegment = '1';
}

/// Turns the bundled model into something the camera plugin can open.
///
/// **This step was missing, and its absence was invisible.** `LiveLessonPage`
/// passed `'assets/pose_landmarker_full.task'` straight to
/// `MotionCameraController.start`, whose contract says `modelPath` is an
/// ABSOLUTE FILESYSTEM PATH — a plugin cannot read a Flutter asset key,
/// because assets live inside the app bundle's own archive and the native side
/// wants a file it can open. The string was wrong in three ways at once (wrong
/// form, wrong directory, no such file), and nothing failed at compile time
/// because a path is just a string.
///
/// `path_provider` sat in `pubspec.yaml` unimported for exactly as long as this
/// function was missing: the dependency was the fossil of a step someone had
/// planned and never written.
Future<String> materialisePoseModel({
  Directory? supportDirectory,
  AssetBundle? bundle,
}) async {
  final dir = supportDirectory ?? await getApplicationSupportDirectory();
  // A new model pin never silently reuses an older version's cache.
  final out = File('${dir.path}/pose-${PoseModelPin.sha256}.task');
  if (await out.exists()) {
    if (computeSha256Hex(await out.readAsBytes()) != PoseModelPin.sha256) {
      throw const FormatException('Cached pose model integrity mismatch');
    }
    return out.path;
  }
  final data = await (bundle ?? rootBundle).load(PoseModelPin.assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  if (computeSha256Hex(bytes) != PoseModelPin.sha256) {
    throw const FormatException('Bundled pose model integrity mismatch');
  }
  final staging = await dir.createTemp('choreia-model-');
  try {
    final pending = File('${staging.path}/verified.task');
    await pending.writeAsBytes(bytes, flush: true);
    await pending.rename(out.path);
  } finally {
    // Only this invocation's derived temporary file is retired.
    await staging.delete(recursive: true);
  }
  return out.path;
}
