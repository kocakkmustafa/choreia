import 'dart:io';

import 'package:choreia/app/course/course_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';

/// Core R3 (`f43d71a`) adoption: the split flags, the camera-only gate and the
/// Declared Age Range entitlement that lets the store age signal reach Core.
void main() {
  String source(String path) => File(path)
      .readAsStringSync()
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('sales follow Core while camera practice stays closed', () {
    expect(choreiaSubscriptionSalesOpen, motionSubscriptionSalesAvailable);
    expect(choreiaSubscriptionSalesOpen, isTrue);
    expect(motionCameraCoachingAvailable, isFalse);
  });

  test('main binds camera to the camera flag and paid lessons to sales', () {
    final main = source('lib/main.dart');
    expect(main,
        contains('cameraSessionsAvailable: motionCameraCoachingAvailable'));
    expect(main, contains('requireMotionCameraAccess('));
    expect(main, contains('salesAvailable: choreiaSubscriptionSalesOpen'));
    expect(main, contains('membershipAvailable: choreiaSubscriptionSalesOpen'));
    expect('requireMotionPaidAccess('.allMatches(main), hasLength(1),
        reason: 'only the paid written lesson gate may ask for a membership');
  });

  test('no deprecated Core flag or parameter is left in the app', () {
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = source(entity.path);
      expect(text, isNot(contains('motionPaidFeaturesAvailable')),
          reason: entity.path);
      expect(text, isNot(contains('paidFeaturesAvailable:')),
          reason: entity.path);
    }
  });

  test('Runner carries the Declared Age Range entitlement in every config', () {
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(
        entitlements,
        matches(RegExp(r'<key>com\.apple\.developer\.declared-age-range</key>'
            r'\s*<true/>')));
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(
        'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
            .allMatches(project),
        hasLength(3));
    expect('INFOPLIST_FILE = Runner/Info.plist;'.allMatches(project),
        hasLength(3));
  });
}
