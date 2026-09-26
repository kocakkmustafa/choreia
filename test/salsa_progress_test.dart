import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const alice = '11111111-1111-4111-8111-111111111111';
  const bob = '22222222-2222-4222-8222-222222222222';
  late Directory temp;
  late SalsaCourse course;
  setUp(() {
    temp = Directory.systemTemp.createTempSync('choreia-course-');
    course = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
  });
  tearDown(() => temp.deleteSync(recursive: true));
  Future<SalsaProgressStore> open([String? id]) =>
      SalsaProgressStore.open(accountUserId: id, supportDirectory: temp);

  test('reopening preserves evidence type, repeated attempts and adaptation',
      () async {
    final store = await open();
    final lesson = course.lessons.first;
    await store.record(course, lesson, SalsaEvidence.viewed);
    await store.record(course, lesson, SalsaEvidence.viewed);
    await store.record(course, lesson, SalsaEvidence.practised,
        option: SalsaPracticeOption.rhythmOnly);
    await store.record(course, lesson, SalsaEvidence.selfReportedComplete,
        option: SalsaPracticeOption.rhythmOnly);
    await store.record(course, lesson, SalsaEvidence.practised,
        option: SalsaPracticeOption.adapted);
    final progress = await (await open()).read();
    expect(progress.events.length, 4);
    expect(progress.lessonIds(course, SalsaEvidence.viewed), {lesson.id});
    expect(progress.lessonIds(course, SalsaEvidence.practised), {lesson.id});
    expect(progress.lessonIds(course, SalsaEvidence.selfReportedComplete),
        {lesson.id});
    expect(progress.events[2].option, SalsaPracticeOption.rhythmOnly);
    expect(progress.events.last.option, SalsaPracticeOption.adapted);
    expect(await File('${store.file.path}.tmp').exists(), isFalse);
  });
  test('completion requires practice with the same declared option', () async {
    final store = await open();
    final lesson = course.lessons.first;
    await expectLater(
        store.record(course, lesson, SalsaEvidence.selfReportedComplete),
        throwsStateError);
    await store.record(course, lesson, SalsaEvidence.practised);
    await expectLater(
        store.record(course, lesson, SalsaEvidence.selfReportedComplete,
            option: SalsaPracticeOption.rhythmOnly),
        throwsStateError);
    expect(
        (await store.read())
            .lessonIds(course, SalsaEvidence.selfReportedComplete),
        isEmpty);
  });
  test('concurrent stores serialize writes without losing attempts', () async {
    final a = await open(alice), b = await open(alice);
    await Future.wait(List.generate(
        12,
        (i) => (i.isEven ? a : b)
            .record(course, course.lessons[i], SalsaEvidence.practised)));
    expect((await a.read()).events.length, 12);
  });
  test('guest, accounts and content versions remain separate', () async {
    final guest = await open(), a = await open(alice), b = await open(bob);
    await guest.record(course, course.lessons.first, SalsaEvidence.practised);
    await a.record(course, course.lessons[1], SalsaEvidence.practised);
    expect((await b.read()).events, isEmpty);
    expect((await guest.read()).events.single.lessonId, 'so_01');
    expect((await a.read()).events.single.lessonId, 'so_02');
    final newer =
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>;
    newer['version'] = 2;
    final nextVersion = SalsaCourse.fromJson(newer);
    expect((await a.read()).forCourse(nextVersion), isEmpty);
    expect((await a.read()).events, hasLength(1));
  });
  test(
      'account deletion discovers course-only history and prevents stale writes',
      () async {
    final a = await open(alice), b = await open(bob), guest = await open();
    for (final store in [a, b, guest]) {
      await store.record(course, course.lessons.first, SalsaEvidence.practised);
    }
    expect(await localHistoryAccountIds(supportDirectory: temp), [alice, bob]);
    final queued = a.record(course, course.lessons[1], SalsaEvidence.practised);
    await clearLocalHistoryFor(alice, supportDirectory: temp);
    await queued;
    await expectLater(
        a.record(course, course.lessons[2], SalsaEvidence.practised),
        throwsStateError);
    expect(await a.file.exists(), isFalse);
    expect((await (await open(alice)).read()).events, isEmpty);
    expect((await b.read()).events, hasLength(1));
    expect((await guest.read()).events, hasLength(1));
    expect(await localHistoryAccountIds(supportDirectory: temp), [bob]);
  });
  test(
      'corrupt, owner-mismatched and future schema records are not overwritten',
      () async {
    final store = await open(alice);
    for (final raw in [
      'broken json',
      jsonEncode({'schemaVersion': 99, 'owner': alice, 'events': []}),
      jsonEncode({'schemaVersion': 1, 'owner': bob, 'events': []}),
      jsonEncode({
        'schemaVersion': 1,
        'owner': alice,
        'events': [
          {'kind': 'cameraMastery'}
        ]
      })
    ]) {
      await store.file.writeAsString(raw);
      await expectLater(store.read(), throwsA(anything));
      await expectLater(
          store.record(course, course.lessons.first, SalsaEvidence.practised),
          throwsA(anything));
      expect(await store.file.readAsString(), raw);
    }
  });
  test(
      'symlink files are neither followed nor deleted; temp-only owners are found',
      () async {
    final store = await open(alice);
    final target = File('${temp.path}/keep')..writeAsStringSync('keep');
    final link = Link(store.file.path)..createSync(target.path);
    await expectLater(store.read(), throwsA(isA<FileSystemException>()));
    await clearLocalHistoryFor(alice, supportDirectory: temp);
    expect(await link.exists(), isTrue);
    expect(await target.readAsString(), 'keep');
    expect(await localHistoryAccountIds(supportDirectory: temp), isEmpty);
    final b = await open(bob);
    await File('${b.file.path}.tmp').writeAsString('interrupted write');
    expect(await localHistoryAccountIds(supportDirectory: temp), [bob]);
    await clearLocalHistoryFor(bob, supportDirectory: temp);
    expect(await File('${b.file.path}.tmp').exists(), isFalse);
  });
}
