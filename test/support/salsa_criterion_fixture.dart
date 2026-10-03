import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';

const criterionLessons = {'so_16', 'so_19', 'so_21', 'so_27', 'so_39'};

Map<String, dynamic> criterionCourseJson() {
  final data =
      jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
          as Map<String, dynamic>;
  data['version'] = 2;
  data['unmappedSelfChecks'] = 'legacyV1';
  for (final raw in data['lessons'] as List) {
    final lesson = raw as Map<String, dynamic>;
    if (!criterionLessons.contains(lesson['id'])) continue;
    lesson['selfCheckByPractice'] = <String, dynamic>{
      'standard': {
        'mode': 'existingSelfCheck',
        'indices': [0, 1, 2]
      },
      'adapted': {
        'mode': 'existingSelfCheck',
        'indices': [0, 1, 2]
      },
      'rhythmOnly': {'mode': 'practiceOnly', 'indices': []},
    };
  }
  return data;
}

SalsaCourse criterionCourse() => SalsaCourse.fromJson(criterionCourseJson());

Map<String, dynamic> criterionLessonJson(Map<String, dynamic> course,
        [String id = 'so_16']) =>
    (course['lessons'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((lesson) => lesson['id'] == id);
