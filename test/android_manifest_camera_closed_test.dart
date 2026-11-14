import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';

/// CHO-P1-02: while the camera flag is closed the Android manifest must not
/// declare CAMERA or camera hardware features.
void main() {
  test('camera flag closed => manifest declares no camera permission/feature',
      () {
    expect(motionCameraCoachingAvailable, isFalse,
        reason: 'Camera flag opened: restore CAMERA permission and '
            'android.hardware.camera uses-feature in AndroidManifest.xml '
            '(see docs/camera/ANDROID-MANIFEST-CAMERA.md), then update this test.');
    final String xml =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    // The motion_camera plugin merges CAMERA + camera uses-feature in; the app
    // manifest may only mention them to strip them (tools:node="remove").
    final Iterable<String> mentions = xml.split('\n').where((String l) =>
        l.contains('android.permission.CAMERA') ||
        l.contains('android.hardware.camera'));
    for (final String l in mentions) {
      expect(l, contains('tools:node="remove"'),
          reason: 'camera closed: manifest must not declare camera: $l');
    }
  });
}
