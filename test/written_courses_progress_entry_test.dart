import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/library/written_courses_progress_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Progress tab states lesson counts without parsing five bundles; this
/// pins every stated count to the bundled course document it describes.
void main() {
  const documents = <String, String>{
    'salsa_shines': 'content/salsa_on1_course.json',
    'hip_hop_foundations': 'content/hip_hop_foundations_skill_course.json',
    'line_dance': 'content/line_dance_beginner_course.json',
    'latin_fusion_fitness': 'content/latin_fusion_beginner_course.json',
    'tiktok_format': 'content/original_short_form_beginner_course.json',
  };

  test('her yazılı kurs için ders sayısı paketlenmiş belgeyle aynı', () {
    expect(WrittenCoursesProgressEntry.lessonCounts.keys.toSet(),
        documents.keys.toSet());
    for (final entry in documents.entries) {
      final doc = jsonDecode(File(entry.value).readAsStringSync())
          as Map<String, dynamic>;
      final units = (doc['units'] ?? doc['lessons']) as List<dynamic>;
      expect(WrittenCoursesProgressEntry.lessonCounts[entry.key], units.length,
          reason: entry.key);
    }
  });

  test('ilerleme listesi yalnız gerçek yazılı kurs rotalarını sayar', () {
    for (final id in WrittenCoursesProgressEntry.lessonCounts.keys) {
      expect(WrittenCourseLink.supports(id), isTrue, reason: id);
    }
  });
}
