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
      (d) => (d['lessons'] as List)[0]['teaching']['en'].removeLast(),
      (d) => (d['lessons'] as List)[0]['selfCheck']['tr'].last = '',
      (d) => (d['sources'] as List).last['url'] = 'http://example.com',
    ]) {
      final data = content();
      mutate(data);
      expect(() => SalsaCourse.fromJson(data), throwsFormatException);
    }
  });
  test('the original course IDs and progress version remain compatible', () {
    final course = SalsaCourse.fromJson(content());
    expect(course.id, 'salsa_on1_solo');
    expect(course.version, 1);
    expect(course.lessons.map((l) => l.id),
        List.generate(48, (i) => 'so_${(i + 1).toString().padLeft(2, '0')}'));
    expect(
        course.modules.map((m) => m.id), List.generate(8, (i) => 'm${i + 1}'));
  });
  test('narrow teacher citations stay on five exact lessons', () {
    final course = SalsaCourse.fromJson(content());
    final added = <String>{
      'addicted2salsa_arm_layering',
      'ellmann_front_cross',
      'eld_jazz_box_b',
      'ellmann_pause_hold',
    };
    final bindings = <String, Set<String>>{
      for (final lesson in course.lessons)
        if (lesson.sourceIds.toSet().intersection(added).isNotEmpty)
          lesson.id: lesson.sourceIds.toSet().intersection(added),
    };
    expect(bindings, <String, Set<String>>{
      'so_15': <String>{'addicted2salsa_arm_layering'},
      'so_25': <String>{'ellmann_front_cross'},
      'so_26': <String>{'ellmann_front_cross'},
      'so_28': <String>{'eld_jazz_box_b'},
      'so_34': <String>{'ellmann_pause_hold'},
    });
    for (final source in course.sources.where((s) => added.contains(s.id))) {
      expect(source.supports!.en, isNotEmpty);
      expect(source.supports!.tr, isNotEmpty);
      expect(source.doesNotSupport!.en, isNotEmpty);
      expect(source.doesNotSupport!.tr, isNotEmpty);
    }
    final broken = content();
    ((broken['sources'] as List).last as Map).remove('doesNotSupport');
    expect(() => SalsaCourse.fromJson(broken), throwsFormatException);
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
