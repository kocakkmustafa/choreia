import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/hip_hop_course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source =
      File('content/hip_hop_foundations_course.json').readAsStringSync();

  test(
    'real path has bilingual instruction and a terminal reflective task',
    () {
      final course = HipHopCourse.decode(source);
      expect(course.units.map((u) => u.id), [
        'hhf_01',
        'hhf_02',
        'hhf_03',
        'hhf_04',
        'hhf_05',
        'hhf_06',
      ]);
      expect(course.units.last.copy['practice']!['en'], contains('revision'));
      expect(course.units.last.copy['check']!['tr'],
          contains('Fiziksel deneme listesi'));
      for (final unit in course.units) {
        for (final pair in unit.copy.values) {
          expect(pair['en'], isNotEmpty);
          expect(pair['tr'], isNotEmpty);
        }
      }
    },
  );

  test('missing translation and duplicate units fail closed', () {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final units = raw['units'] as List<dynamic>;
    final first = units.first as Map<String, dynamic>;
    final instruction = first['instruction'] as Map<String, dynamic>;
    instruction.remove('tr');
    expect(() => HipHopCourse.decode(jsonEncode(raw)), throwsFormatException);
    instruction['tr'] = 'Metin';
    units.add(first);
    expect(() => HipHopCourse.decode(jsonEncode(raw)), throwsFormatException);
  });

  test('written path cannot silently become progress or scoring content', () {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final acceptance = raw['acceptance'] as Map<String, dynamic>;
    acceptance['progressWrites'] = true;
    expect(() => HipHopCourse.decode(jsonEncode(raw)), throwsFormatException);
    acceptance['progressWrites'] = false;
    acceptance['scoring'] = true;
    expect(() => HipHopCourse.decode(jsonEncode(raw)), throwsFormatException);
  });

  test('forward prerequisite or missing first stage is rejected', () {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final units = raw['units'] as List<dynamic>;
    (units.first as Map<String, dynamic>)['prerequisiteIds'] = ['hhf_06'];
    expect(() => HipHopCourse.decode(jsonEncode(raw)), throwsFormatException);
    units.removeAt(0);
    expect(() => HipHopCourse.decode(jsonEncode(raw)), throwsFormatException);
  });
}
