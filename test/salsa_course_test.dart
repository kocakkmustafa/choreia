import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> content() =>
    jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('all 48 bilingual lessons form the complete eight-module learning path',
      () {
    final course = SalsaCourse.fromJson(content());
    expect(course.lessons.length, 48);
    expect(course.modules.length, 8);
    for (final lesson in course.lessons) {
      expect(lesson.teaching.tr.length, greaterThanOrEqualTo(3));
      expect(lesson.teaching.en.length, lesson.teaching.tr.length);
      expect(lesson.selfCheck.en.length, lesson.selfCheck.tr.length);
      expect(lesson.practice.tr.length, greaterThan(40));
      expect(lesson.practice.en.length, greaterThan(40));
      expect(lesson.adaptation.tr, isNotEmpty);
      expect(lesson.sourceIds, isNotEmpty);
    }
    expect(course.lessons.last.order, 48);
    expect(course.lessons.map((l) => l.practice.en).toSet().length, 48);
    expect(course.lessons.map((l) => l.goal.en).toSet().length, 48);
  });
  test(
      'broken prerequisites, duplicate IDs and missing translations fail closed',
      () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (d) => (d['lessons'] as List)[0]['prerequisites'] = ['so_48'],
      (d) => (d['lessons'] as List)[1]['id'] = 'so_01',
      (d) => (d['lessons'] as List)[47]['prerequisites'] = [],
      (d) => (d['lessons'] as List)[8]['goal']['tr'] = '',
      (d) => (d['lessons'] as List)[8]['selfCheck']['tr'] = ['only one'],
      (d) => (d['lessons'] as List)[8]['sourceIds'] = ['unreviewed'],
      (d) => (d['lessons'] as List)[8]['moduleId'] = 'missing',
    ]) {
      final data = content();
      mutate(data);
      expect(() => SalsaCourse.fromJson(data), throwsFormatException);
    }
  });
  test('content flags cannot publish unreviewed media, music or scoring', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (d) => d['assessment'] = 'cameraScored',
      (d) => (d['lessons'] as List)[0]['assessment'] = 'scored',
      (d) => d['music']['provided'] = true,
      (d) => d['music']['beatEvidence'] = 'assumed',
      (d) => (d['lessons'] as List)[0]['mediaBrief']['status'] = 'published',
    ]) {
      final data = content();
      mutate(data);
      expect(() => SalsaCourse.fromJson(data), throwsFormatException);
    }
  });
  test(
      'every planned media brief has a distinct stable identity and bilingual sequence',
      () {
    final data = content();
    final lessons = (data['lessons'] as List).cast<Map<String, dynamic>>();
    final ids = <String>{};
    for (final lesson in lessons) {
      final brief = lesson['mediaBrief'] as Map<String, dynamic>;
      expect(ids.add(brief['id'] as String), isTrue);
      expect(brief['status'], 'planned');
      expect(brief['sequence'], lesson['teaching']);
      expect(brief['rights'], contains('No asset exists yet'));
    }
  });
}
