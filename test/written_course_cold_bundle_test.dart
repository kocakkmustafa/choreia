import 'dart:io';

import 'package:choreia/app/course/latin_fusion_course.dart';
import 'package:choreia/app/course/short_form_course.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Proposed cold asset-read probe, not cold first-route/device acceptance.
// Plain test uses its real async zone; no widget fake-clock asset read,
// preflight warming, DiskBundle or WrittenBundle substitution.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final asset in [
    'content/latin_fusion_beginner_course.json',
    'content/original_short_form_beginner_course.json',
  ]) {
    test('cold uncached real bundle read and decoder: $asset', () async {
      rootBundle.evict(asset);
      // A stalled asset/compute read is a failure, never an implicit skip.
      final loaded = await rootBundle.loadString(asset, cache: false)
          .timeout(const Duration(seconds: 8));
      expect(loaded, File(asset).readAsStringSync());
      if (asset.contains('latin_fusion')) {
        expect(LatinFusionCourse.decode(loaded).units.length, 8);
      } else {
        expect(ShortFormCourse.decode(loaded).units.length, 7);
      }
      rootBundle.evict(asset);
    }, timeout: const Timeout(Duration(seconds: 15)));
  }
}
