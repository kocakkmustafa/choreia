import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';

/// CHO-P1-02: while the camera flag is closed the merged Android manifest must
/// not declare CAMERA or camera hardware features. The `motion_camera` plugin
/// merges both in, so the app manifest must strip them with
/// `tools:node="remove"` (both elements must be present and carry it).
void main() {
  test('camera flag closed => app manifest strips CAMERA permission/feature',
      () {
    expect(motionCameraCoachingAvailable, isFalse,
        reason: 'Camera flag opened: remove the tools:node="remove" camera '
            'elements from AndroidManifest.xml '
            '(see docs/camera/ANDROID-MANIFEST-CAMERA.md), then update this '
            'test.');
    final String path = Platform.environment['CHOREIA_MANIFEST_UNDER_TEST'] ??
        'android/app/src/main/AndroidManifest.xml';
    final String xml = File(path)
        .readAsStringSync()
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    final RegExp element = RegExp(r'<(uses-permission|uses-feature)\b[^>]*>',
        dotAll: true);
    final List<String> tags =
        element.allMatches(xml).map((RegExpMatch m) => m.group(0)!).toList();
    bool isRemoved(String t) => RegExp(r'tools:node\s*=\s*"remove"').hasMatch(t);

    final List<String> perm = tags
        .where((String t) =>
            t.startsWith('<uses-permission') &&
            t.contains('"android.permission.CAMERA"'))
        .toList();
    final List<String> feat = tags
        .where((String t) =>
            t.startsWith('<uses-feature') &&
            t.contains('"android.hardware.camera"'))
        .toList();

    expect(perm, isNotEmpty, reason: 'CAMERA uses-permission removal missing');
    expect(feat, isNotEmpty, reason: 'camera uses-feature removal missing');
    for (final String t in <String>[...perm, ...feat]) {
      expect(isRemoved(t), isTrue, reason: 'must carry tools:node="remove": $t');
    }
  });
}
