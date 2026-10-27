import 'dart:io';

import 'package:choreia/app/course/course_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';

// K-2 (owner decision 2026-10-27, all five Motion apps) on Core R4: Choreia
// leaves 13–17 purchases to the store's family controls. Core keeps
// parentalConsentRequired as its default, so every Core entry point Choreia
// opens must carry the app's choice; a missing argument silently falls back to
// the Core default.
void main() {
  test('Choreia selects store family controls, not the Core default', () {
    expect(
      choreiaTeenPurchasePolicy,
      MotionTeenPurchasePolicy.storeFamilyControls,
    );
    expect(
      const MotionAccountPage(account: _NeverAccount()).teenPurchasePolicy,
      MotionTeenPurchasePolicy.parentalConsentRequired,
      reason: 'Core default unchanged; Choreia must pass its policy',
    );
  });

  // The paid and camera gates open Core's default MotionMembershipPage, which
  // takes the policy from these calls (Core R4 tests that forwarding). Guard
  // the app side: each Core purchase entry point in main.dart passes it.
  test('every Core purchase entry point in main.dart passes the policy', () {
    final source = File('lib/main.dart').readAsStringSync();
    for (final entry in [
      'MotionAccountPage(',
      'requireMotionPaidAccess(',
      'requireMotionCameraAccess(',
    ]) {
      final start = source.indexOf(entry);
      expect(start, isNonNegative, reason: entry);
      expect(source.indexOf(entry, start + 1), -1,
          reason: '$entry appears once; guard each new call site');
      final call = source.substring(start, _closingParen(source, start));
      expect(
        call,
        contains('teenPurchasePolicy: choreiaTeenPurchasePolicy'),
        reason: entry,
      );
    }
    final lib = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in lib) {
      expect(file.readAsStringSync(), isNot(contains('MotionMembershipPage(')),
          reason: '${file.path} builds its own membership page');
    }
  });
}

int _closingParen(String source, int from) {
  var depth = 0;
  for (var i = source.indexOf('(', from); i < source.length; i++) {
    if (source[i] == '(') depth++;
    if (source[i] == ')' && --depth == 0) return i;
  }
  throw StateError('unbalanced call at $from');
}

final class _NeverAccount implements MotionAccountClient {
  const _NeverAccount();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used');
}
