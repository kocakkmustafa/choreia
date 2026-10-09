import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/course/salsa_self_check_policy.dart';
import 'package:choreia/app/course/salsa_weekly_activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';

import 'support/salsa_criterion_fixture.dart';

void main() {
  test('staged course bytes decode to the reviewed version-two fixture', () {
    final bytes = File(
      'test/fixtures/salsa_criterion_v2/course-version2-candidate.json',
    ).readAsBytesSync();
    expect(sha256.convert(bytes).toString(),
        '3ec9ca3cf12bacaed6e4454ad769b9c1c3a3300643d50e7de2252601e782d52c');
    final staged = jsonDecode(utf8.decode(bytes));
    expect(staged, criterionCourseJson());
    final parsed = SalsaCourse.fromJson(staged as Map<String, dynamic>);
    expect(parsed.version, 2);
    expect(parsed.lessons, hasLength(48));
  });
  test('version one still reads the unchanged bundled course', () {
    final data =
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(SalsaCourse.fromJson(data).version, 1);
  });
  test('typed selections freeze source indices and keep bilingual alignment',
      () {
    final data = criterionCourseJson();
    final course = SalsaCourse.fromJson(data);
    final selection =
        course.lesson('so_16').selfChecksFor(SalsaPracticeOption.standard);
    final raw = (criterionLessonJson(data)['selfCheckByPractice']
        as Map)['standard'] as Map;
    (raw['indices'] as List)[0] = 2;
    expect(selection.indices, [0, 1, 2]);
    expect(() => selection.indices.add(1), throwsUnsupportedError);
    for (final option in [
      SalsaPracticeOption.standard,
      SalsaPracticeOption.adapted
    ]) {
      final lesson = course.lesson('so_16');
      final indices = lesson.selfChecksFor(option).indices;
      expect(indices.map((index) => lesson.selfCheck.tr[index]).toList(),
          lesson.selfCheck.tr);
      expect(indices.map((index) => lesson.selfCheck.en[index]).toList(),
          lesson.selfCheck.en);
    }
    final spoken =
        course.lesson('so_16').selfChecksFor(SalsaPracticeOption.rhythmOnly);
    expect(spoken.mode, SalsaSelfCheckMode.practiceOnly);
    expect(spoken.indices, isEmpty);
    expect(spoken.completionAllowed, isFalse);
  });
  test(
      'narrow revision refuses conceptual completion and changed physical subset',
      () {
    final conceptual = criterionCourseJson();
    (criterionLessonJson(conceptual, 'so_27')['selfCheckByPractice']
        as Map)['rhythmOnly'] = {
      'mode': 'existingSelfCheck',
      'indices': [2]
    };
    expect(() => SalsaCourse.fromJson(conceptual), throwsFormatException);
    final subset = criterionCourseJson();
    (criterionLessonJson(subset)['selfCheckByPractice'] as Map)['adapted'] = {
      'mode': 'existingSelfCheck',
      'indices': [0, 1]
    };
    expect(() => SalsaCourse.fromJson(subset), throwsFormatException);
    final extra = criterionCourseJson();
    criterionLessonJson(extra, 'so_01')['selfCheckByPractice'] =
        criterionLessonJson(extra)['selfCheckByPractice'];
    expect(() => SalsaCourse.fromJson(extra), throwsFormatException);
  });
  test('version two requires the five policy maps and explicit legacy scope',
      () {
    final missing = criterionCourseJson();
    criterionLessonJson(missing).remove('selfCheckByPractice');
    expect(() => SalsaCourse.fromJson(missing), throwsFormatException);
    final unspecified = criterionCourseJson()..remove('unmappedSelfChecks');
    expect(() => SalsaCourse.fromJson(unspecified), throwsFormatException);
    final oldVersion = criterionCourseJson()..['version'] = 1;
    expect(() => SalsaCourse.fromJson(oldVersion), throwsFormatException);
  });
  for (final invalid in <String, Object?>{
    'null': null,
    'empty': <String, Object?>{},
    'partial': {
      'rhythmOnly': {'mode': 'practiceOnly', 'indices': []}
    },
    'extra option': {
      'standard': {
        'mode': 'existingSelfCheck',
        'indices': [0, 1, 2]
      },
      'adapted': {
        'mode': 'existingSelfCheck',
        'indices': [0, 1, 2]
      },
      'rhythmOnly': {'mode': 'practiceOnly', 'indices': []},
      'cameraMastery': {'mode': 'practiceOnly', 'indices': []},
    },
  }.entries) {
    test('present policy rejects ${invalid.key} without fallback', () {
      final data = criterionCourseJson();
      criterionLessonJson(data)['selfCheckByPractice'] = invalid.value;
      expect(() => SalsaCourse.fromJson(data), throwsFormatException);
    });
  }
  for (final invalid in <String, Map<String, Object?>>{
    'empty completion': {'mode': 'existingSelfCheck', 'indices': []},
    'duplicate': {
      'mode': 'existingSelfCheck',
      'indices': [0, 0]
    },
    'negative': {
      'mode': 'existingSelfCheck',
      'indices': [-1]
    },
    'out of bounds': {
      'mode': 'existingSelfCheck',
      'indices': [3]
    },
    'unknown mode': {
      'mode': 'mastery',
      'indices': [0]
    },
    'wrong index type': {
      'mode': 'existingSelfCheck',
      'indices': ['0']
    },
    'nonempty practice only': {
      'mode': 'practiceOnly',
      'indices': [0]
    },
  }.entries) {
    test('policy rejects ${invalid.key}', () {
      final data = criterionCourseJson();
      (criterionLessonJson(data)['selfCheckByPractice'] as Map)['rhythmOnly'] =
          invalid.value;
      expect(() => SalsaCourse.fromJson(data), throwsFormatException);
    });
  }
  for (final id in criterionLessons) {
    test('$id saves spoken practice but writer rejects completion', () async {
      final directory =
          Directory.systemTemp.createTempSync('criterion-writer-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final store = await SalsaProgressStore.open(supportDirectory: directory);
      final course = criterionCourse(), lesson = criterionCourse().lesson(id);
      // A lesson object from another course must still be refused.
      await expectLater(store.record(course, lesson, SalsaEvidence.practised),
          throwsArgumentError);
      final own = course.lesson(id);
      await store.record(course, own, SalsaEvidence.viewed);
      await store.record(course, own, SalsaEvidence.practised,
          option: SalsaPracticeOption.rhythmOnly);
      final before = await store.file.readAsBytes();
      await expectLater(
          store.record(course, own, SalsaEvidence.selfReportedComplete,
              option: SalsaPracticeOption.rhythmOnly),
          throwsStateError);
      expect(await store.file.readAsBytes(), before);
      expect((await store.read()).lessonIds(course, SalsaEvidence.practised),
          {id});
    });
  }
  test(
      'standard adapted conceptual and conditional positives retain completion',
      () async {
    final directory =
        Directory.systemTemp.createTempSync('criterion-positives-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = await SalsaProgressStore.open(supportDirectory: directory);
    final course = criterionCourse();
    for (final option in [
      SalsaPracticeOption.standard,
      SalsaPracticeOption.adapted
    ]) {
      await store.record(
          course, course.lesson('so_16'), SalsaEvidence.practised,
          option: option);
      await store.record(
          course, course.lesson('so_16'), SalsaEvidence.selfReportedComplete,
          option: option);
    }
    for (final id in ['so_01', 'so_11', 'so_20', 'so_22', 'so_32', 'so_44']) {
      await store.record(course, course.lesson(id), SalsaEvidence.practised,
          option: SalsaPracticeOption.rhythmOnly);
      await store.record(
          course, course.lesson(id), SalsaEvidence.selfReportedComplete,
          option: SalsaPracticeOption.rhythmOnly);
    }
    expect(
        (await store.read())
            .lessonIds(course, SalsaEvidence.selfReportedComplete),
        {'so_16', 'so_01', 'so_11', 'so_20', 'so_22', 'so_32', 'so_44'});
  });
  test(
      'version migration retains all old evidence and excludes old current totals',
      () async {
    final directory =
        Directory.systemTemp.createTempSync('criterion-migration-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final store = await SalsaProgressStore.open(supportDirectory: directory);
    final old = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
    final now = DateTime(2026, 10, 2, 12);
    for (final kind in SalsaEvidence.values) {
      await store.record(old, old.lesson('so_01'), kind, at: now);
    }
    final next = criterionCourse();
    final retained =
        (await store.read()).events.map((e) => e.toJson()).toList();
    expect((await store.read()).forCourse(next), isEmpty);
    expect(
        salsaWeeklyActivity(await store.read(), next, now: now)
            .weeks
            .first
            .practiceAttempts,
        0);
    await store.record(next, next.lesson('so_16'), SalsaEvidence.practised,
        option: SalsaPracticeOption.rhythmOnly, at: now);
    final progress =
        await (await SalsaProgressStore.open(supportDirectory: directory))
            .read();
    expect(progress.events.take(3).map((e) => e.toJson()).toList(), retained);
    expect(progress.lessonIds(next, SalsaEvidence.viewed), isEmpty);
    expect(
        progress.lessonIds(next, SalsaEvidence.selfReportedComplete), isEmpty);
    expect(progress.lessonIds(next, SalsaEvidence.practised), {'so_16'});
    expect(
        salsaWeeklyActivity(progress, next, now: now)
            .weeks
            .first
            .practiceAttempts,
        1);
  });
  test(
      'all forty-three unmapped lessons retain full legacy indices for every option',
      () {
    final course = criterionCourse();
    final legacy =
        course.lessons.where((lesson) => !criterionLessons.contains(lesson.id));
    expect(legacy, hasLength(43));
    for (final lesson in legacy) {
      expect(lesson.selfCheckPolicy, isNull);
      for (final option in SalsaPracticeOption.values) {
        final selection = lesson.selfChecksFor(option);
        expect(selection.indices,
            List.generate(lesson.selfCheck.en.length, (index) => index));
        expect(selection.completionAllowed, isTrue);
      }
    }
  });
}
