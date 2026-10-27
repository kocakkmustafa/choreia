import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/course_access.dart';
import 'package:flutter_test/flutter_test.dart';

// K-6 (founder decision 2026-10-27): store listing drafts in all 14 app
// languages. Each draft must keep the EN source shape and store field limits,
// name its App Store Connect / Play Console locale codes, repeat the counted
// facts that the courses and the paywall really have, and quote the camera
// rationale of its own InfoPlist.strings.
const _codes = <String, (String, String)>{
  'en': ('en-US', 'en-US'),
  'tr-TR': ('tr', 'tr-TR'),
  'de': ('de-DE', 'de-DE'),
  'es-419': ('es-MX', 'es-419'),
  'pt-BR': ('pt-BR', 'pt-BR'),
  'fr': ('fr-FR', 'fr-FR'),
  'it': ('it', 'it-IT'),
  'pl': ('pl', 'pl-PL'),
  'id': ('id', 'id'),
  'ja': ('ja', 'ja-JP'),
  'ko': ('ko', 'ko-KR'),
  'zh-Hans': ('zh-Hans', 'zh-CN'),
  'ar': ('ar-SA', 'ar'),
  'hi': ('hi', 'hi-IN'),
};

String _file(String locale) => locale == 'en'
    ? 'docs/store/listing.json'
    : 'docs/store/listing.$locale.json';

String _lproj(String locale) => switch (locale) {
      'tr-TR' => 'tr',
      _ => locale,
    };

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

int _units(String course, String key) =>
    ((_read('content/$course.json')[key]) as List).length;

void main() {
  final en = _read(_file('en'));
  final enParagraphs = (en['description']! as String).split('\n\n').length;

  test('the listed counts are the bundled courses and the paywall', () {
    expect(_units('salsa_on1_course', 'lessons'), 48);
    expect(_units('salsa_on1_course', 'modules'), 8);
    expect(_units('hip_hop_foundations_course', 'units'), 6);
    expect(_units('hip_hop_foundations_skill_course', 'units'), 8);
    expect(_units('line_dance_beginner_course', 'units'), 12);
    expect(_units('latin_fusion_beginner_course', 'units'), 10);
    expect(_units('original_short_form_beginner_course', 'units'), 10);
    // The Hip-Hop beginner course has no paywall; the skill course does.
    expect(CourseAccess.freeLessons, {
      'salsa_shines': 18,
      'hip_hop_foundations': 3,
      'line_dance': 4,
      'latin_fusion_fitness': 4,
      'tiktok_format': 4,
    });
    final free = CourseAccess.freeLessons.values.reduce((a, b) => a + b) + 6;
    expect(free, 39);
    expect(48 + 6 + 8 + 12 + 10 + 10, 94);
  });

  test('every app language has exactly one listing draft', () {
    final drafts = Directory('docs/store')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .where((name) => RegExp(r'^listing(\.[^.]+)?\.json$').hasMatch(name))
        .toSet();
    expect(drafts, {for (final locale in _codes.keys) _file(locale).split('/').last});
    expect(_codes, hasLength(14));
  });

  for (final MapEntry(key: locale, value: (asc, play)) in _codes.entries) {
    test('listing $locale: store codes, limits, counted facts, camera text', () {
      final l = _read(_file(locale));
      expect(l[r'$storeLocales'], {'appStoreConnect': asc, 'playConsole': play});
      if (locale != 'en' && locale != 'tr-TR') {
        expect(l.keys.toSet(), {
          r'$doc',
          r'$storeLocales',
          'appStore',
          'playStore',
          'description',
          'cameraPermissionRationale',
          'supportUrl',
          'privacyPolicyUrl',
        });
        expect(l[r'$doc'], contains('Not submitted'));
      }
      expect(l['supportUrl'], en['supportUrl']);
      expect(l['privacyPolicyUrl'], en['privacyPolicyUrl']);

      final app = l['appStore']! as Map<String, Object?>;
      const limits = {
        'name': 30,
        'subtitle': 30,
        'promotionalText': 170,
        'keywords': 100,
      };
      expect(app.keys.toSet(), limits.keys.toSet());
      for (final MapEntry(key: field, value: max) in limits.entries) {
        final text = app[field]! as String;
        expect(text.trim(), isNotEmpty, reason: field);
        expect(text.length, lessThanOrEqualTo(max), reason: field);
      }
      expect(app['name'], startsWith('Choreia'));
      final short =
          (l['playStore']! as Map<String, Object?>)['shortDescription']!
              as String;
      expect(short.length, inInclusiveRange(1, 80));

      final description = l['description']! as String;
      expect(description.length, lessThanOrEqualTo(4000));
      expect(description.split('\n\n').length, enParagraphs);
      // 94 units (48 Salsa in 8 modules, 6 + 8 Hip-Hop, 12, 10, 10), 39 free
      // (18 Salsa, 3 skill, 4 per flat course), 14-day trial, 14 languages.
      for (final number in [
        '94', '48', '8', '6', '12', '10', '39', '18', '3', '4', '14'
      ]) {
        expect(description, contains(number), reason: number);
      }
      expect(description, contains('Motion+'));
      expect(description, contains('Choreia'));
      expect(description, contains('https://yulalab.com/terms'));

      final camera = l['cameraPermissionRationale']! as Map<String, Object?>;
      final plist = File('ios/Runner/${_lproj(locale)}.lproj/InfoPlist.strings')
          .readAsStringSync();
      final match = RegExp(
        r'"NSCameraUsageDescription"\s*=\s*"((?:[^"\\]|\\.)*)";',
      ).firstMatch(plist)!;
      expect(camera['ios'], match.group(1));
    });
  }
}
