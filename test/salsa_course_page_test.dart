import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData;
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

final class _RejectMediaBundle extends DeviceBundle {
  _RejectMediaBundle() : super(declaredReferences());

  int mediaRequests = 0;

  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('content/media/')) {
      mediaRequests++;
      throw FlutterError('The empty production catalog must not read media.');
    }
    return super.load(key);
  }
}

void main() {
  const alice = '11111111-1111-4111-8111-111111111111';
  const bob = '22222222-2222-4222-8222-222222222222';
  late Directory temp;
  late ValueNotifier<String?> owner;
  late LiveEnvironment env;
  setUp(() {
    temp = Directory.systemTemp.createTempSync('choreia-course-ui-');
    owner = ValueNotifier(alice);
    env = LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        historyDirectoryOverride: temp,
        accountUserId: owner,
        source: () => throw StateError('Teaching must not start the camera.'));
  });
  tearDown(() {
    owner.dispose();
    temp.deleteSync(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester, Widget home,
      {double scale = 1}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ChoreiaTheme.dark,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: home));
    await tester.pump();
  }

  Future<void> loaded(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 60; i++) {
      // Real file IO lives outside Flutter's fake animation clock.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 450));
        return;
      }
    }
    expect(finder, findsWidgets);
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 300,
          scrollable: find.byType(Scrollable).first);
    } else {
      await tester.ensureVisible(finder);
    }
    await tester.pump(const Duration(milliseconds: 400));
    bool enabled() {
      final widget = tester.widget(finder);
      if (widget is FilledButton) return widget.onPressed != null;
      if (widget is ChoiceChip) return widget.onSelected != null;
      if (widget is CheckboxListTile) return widget.onChanged != null;
      return true;
    }

    for (var i = 0; i < 60 && !enabled(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(enabled(), isTrue, reason: 'Action $key should be available');
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('empty media slot leaves the Salsa lesson and viewed bytes alone',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final bundle = _RejectMediaBundle();
    env = LiveEnvironment(
      bundle: bundle,
      historyDirectoryOverride: temp,
      accountUserId: owner,
      source: () => throw StateError('Media must not start the camera.'),
    );
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    expect(find.text('0 / 48 self-reported complete'), findsOneWidget);
    await tapVisible(tester, const Key('salsa.continue'));
    await loaded(tester, find.byKey(const ValueKey('salsa.lessonBody.so_01')));
    expect(find.text('Meet Salsa'), findsOneWidget);
    expect(find.text('1 / 48'), findsOneWidget);

    final slotFinder = find.byKey(const ValueKey('salsa.mediaSlot.so_01'));
    expect(slotFinder, findsOneWidget);
    final slot = tester.widget<LessonMediaSlot>(slotFinder);
    expect(slot.catalog.isEmpty, isTrue);
    expect(slot.sceneId, isNull);
    expect(slot.variantStem, isNull);
    expect(slot.locale, 'en');
    expect(tester.getSize(slotFinder).height, 0);

    // Opening a written lesson already records one viewed event. The media
    // seam must add no second viewed, practice, completion, or mastery record.
    final file = File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}');
    for (var i = 0; i < 60 && !file.existsSync(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(file.existsSync(), isTrue);
    final before = file.readAsBytesSync();
    final saved = jsonDecode(utf8.decode(before)) as Map<String, dynamic>;
    final events = saved['events'] as List;
    expect(events, hasLength(1));
    expect(events.single['kind'], SalsaEvidence.viewed.name);
    expect(bundle.mediaRequests, 0);

    await tester.tap(find.text('Türkçe'));
    await tester.pump();
    expect(find.text('Salsa ile tanış'), findsOneWidget);
    expect(tester.widget<LessonMediaSlot>(slotFinder).locale, 'tr');
    expect(tester.getSize(slotFinder).height, 0);
    owner.value = bob;
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(file.readAsBytesSync(), before);
    expect(bundle.mediaRequests, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'entry to saved self-check survives reopening with an adapted record',
      (tester) async {
    await pumpApp(tester, Scaffold(body: SalsaCourseEntry(env: env)));
    await tester.tap(find.byKey(const Key('salsa.open')));
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    expect(find.text('0 / 48 self-reported complete'), findsOneWidget);
    await tester.tap(find.byKey(const Key('salsa.continue')));
    await loaded(tester, find.byKey(const ValueKey('salsa.lessonBody.so_01')));
    await loaded(tester, find.text('Meet Salsa'));
    expect(find.byType(SalsaLessonPage), findsOneWidget);
    await tapVisible(tester, const Key('salsa.option.rhythmOnly'));
    await tapVisible(tester, const Key('salsa.savePractice'));
    await loaded(tester, find.text('Practice saved · save another attempt'));
    final course = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
    for (var i = 0; i < course.lessons.first.selfCheck.en.length; i++) {
      await tapVisible(tester, Key('salsa.check.$i'));
    }
    await tapVisible(tester, const Key('salsa.complete'));
    await loaded(tester, find.byKey(const Key('salsa.saved')));
    final raw = jsonDecode(
        File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}')
            .readAsStringSync()) as Map<String, dynamic>;
    final stored = SalsaProgress((raw['events'] as List)
        .map((e) => SalsaProgressEvent.fromJson(e as Map<String, dynamic>)));
    expect(stored.events.map((e) => e.kind), [
      SalsaEvidence.viewed,
      SalsaEvidence.practised,
      SalsaEvidence.selfReportedComplete
    ]);
    expect(stored.events.last.option, SalsaPracticeOption.rhythmOnly);
    await tester.pageBack();
    await loaded(tester, find.text('1 / 48 self-reported complete'));
    // Recreate the widget tree, then read the same owner journal from disk.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.text('1 / 48 self-reported complete'));
    expect(
        find.text('Lessons opened: 1 · Lessons practised: 1'), findsOneWidget);
    expect(find.byKey(const Key('salsa.weeklyPractice')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('salsa.weeklyPractice.week0')),
            matching:
                find.text('Saved attempts: 1 · Lessons with attempts: 1')),
        findsOneWidget);
    owner.value = bob;
    await loaded(tester, find.text('0 / 48 self-reported complete'));
    expect(
        find.descendant(
            of: find.byKey(const Key('salsa.weeklyPractice.week0')),
            matching:
                find.text('Saved attempts: 0 · Lessons with attempts: 0')),
        findsOneWidget);
    owner.value = alice;
    await loaded(tester, find.text('1 / 48 self-reported complete'));
    expect(
        find.descendant(
            of: find.byKey(const Key('salsa.weeklyPractice.week0')),
            matching:
                find.text('Saved attempts: 1 · Lessons with attempts: 1')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final lessonId in <String>[
    'so_11',
    'so_20',
    'so_22',
    'so_32',
    'so_44'
  ]) {
    for (final tr in <bool>[false, true]) {
      testWidgets(
          '$lessonId ${tr ? 'TR' : 'EN'} adapted self-check records only the chosen option',
          (tester) async {
        final course = SalsaCourse.fromJson(
            jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
                as Map<String, dynamic>);
        final lesson = course.lesson(lessonId);
        final option = lessonId == 'so_22'
            ? SalsaPracticeOption.adapted
            : SalsaPracticeOption.rhythmOnly;
        final checks = lesson.selfCheck.inLanguage(tr);
        final checkText = checks.join(' ').toLowerCase();
        final omittedSkillMarker = lessonId == 'so_32'
            ? (tr ? 'test etmediğimi' : 'untested')
            : (tr ? 'denenmedi' : 'untried');
        expect(checkText, contains(omittedSkillMarker),
            reason:
                'The adapted route must not claim an untried physical skill.');
        final store = (await tester.runAsync(() => SalsaProgressStore.open(
            accountUserId: alice, supportDirectory: temp)))!;
        await pumpApp(
            tester,
            SalsaLessonPage(
                course: course,
                lesson: lesson,
                store: store,
                env: env,
                initialTurkish: tr));
        await loaded(
            tester, find.byKey(ValueKey('salsa.lessonBody.$lessonId')));
        if (option != SalsaPracticeOption.rhythmOnly) {
          await tapVisible(tester, const Key('salsa.preparation.acknowledge'));
        }
        await tapVisible(tester, Key('salsa.option.${option.name}'));
        await tapVisible(tester, const Key('salsa.savePractice'));
        await loaded(
            tester,
            find.text(tr
                ? 'Pratik kaydedildi · yeni denemeyi kaydet'
                : 'Practice saved · save another attempt'));
        final complete = find.byKey(const Key('salsa.complete'));
        if (complete.evaluate().isEmpty) {
          await tester.scrollUntilVisible(complete, 300,
              scrollable: find.byType(Scrollable).first);
        } else {
          await tester.ensureVisible(complete);
        }
        expect(tester.widget<FilledButton>(complete).onPressed, isNull);
        for (var i = 0; i < checks.length; i++) {
          await tapVisible(tester, Key('salsa.check.$i'));
          final tile = tester
              .widget<CheckboxListTile>(find.byKey(Key('salsa.check.$i')));
          expect((tile.title! as Text).data, checks[i]);
        }
        await tapVisible(tester, const Key('salsa.complete'));
        await loaded(tester, find.byKey(const Key('salsa.saved')));
        final saved = (await tester.runAsync(store.read))!;
        final records = saved
            .forCourse(course)
            .where((event) => event.lessonId == lessonId)
            .toList();
        expect(records.map((event) => event.kind), <SalsaEvidence>[
          SalsaEvidence.viewed,
          SalsaEvidence.practised,
          SalsaEvidence.selfReportedComplete,
        ]);
        expect(records.last.option, option);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final tr in [false, true]) {
    testWidgets(
        'enriched ${tr ? 'TR' : 'EN'} lesson saves through real back and reopen',
        (tester) async {
      final course = SalsaCourse.fromJson(
          jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
              as Map<String, dynamic>);
      final lesson = course.lessons.first;
      await pumpApp(tester, SalsaCoursePage(env: env));
      await loaded(tester, find.byKey(const Key('salsa.continue')));
      if (tr) {
        await tester.tap(find.text('Türkçe'));
        await tester.pump();
      }
      await tapVisible(tester, const Key('salsa.continue'));
      await loaded(tester, find.byType(SalsaLessonPage));
      final error = find
          .textContaining((tr ? lesson.teaching.tr : lesson.teaching.en).last);
      await tester.scrollUntilVisible(error, 300,
          scrollable: find.byType(Scrollable).last);
      expect(error, findsOneWidget);
      final practice = find.text(lesson.practice.inLanguage(tr));
      await tester.scrollUntilVisible(practice, 300,
          scrollable: find.byType(Scrollable).last);
      expect(practice, findsOneWidget);
      await tapVisible(tester, const Key('salsa.savePractice'));
      await loaded(
          tester,
          find.text(tr
              ? 'Pratik kaydedildi · yeni denemeyi kaydet'
              : 'Practice saved · save another attempt'));
      for (var i = 0; i < lesson.selfCheck.en.length; i++) {
        await tapVisible(tester, Key('salsa.check.$i'));
      }
      await tapVisible(tester, const Key('salsa.complete'));
      await loaded(tester, find.byKey(const Key('salsa.saved')));
      await tester.tap(find.byType(BackButton));
      await loaded(
          tester,
          find.text(tr
              ? '1 / 48 öz beyanla tamamlandı'
              : '1 / 48 self-reported complete'));
      final file =
          File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}');
      final saved = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
          (saved['events'] as List)
              .where((dynamic event) =>
                  event['lessonId'] == 'so_01' && event['kind'] == 'practised')
              .length,
          1);
      expect(
          (saved['events'] as List)
              .where((dynamic event) =>
                  event['lessonId'] == 'so_01' &&
                  event['kind'] == 'selfReportedComplete')
              .length,
          1);
      final row = find.byKey(const Key('salsa.lesson.so_01'));
      await tester.scrollUntilVisible(row, 300,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(row);
      await loaded(tester, find.byType(SalsaLessonPage));
      expect(find.text(lesson.title.inLanguage(tr)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'pre-enrichment v1 completion remains readable without rewriting it',
      (tester) async {
    final file = File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}');
    final old = jsonEncode({
      'schemaVersion': 1,
      'owner': alice,
      'events': [
        for (final kind in ['viewed', 'practised', 'selfReportedComplete'])
          {
            'courseId': 'salsa_on1_solo',
            'version': 1,
            'lessonId': 'so_01',
            'kind': kind,
            'option': 'standard',
            'at': '2026-09-26T12:00:00Z'
          }
      ]
    });
    file.writeAsStringSync(old);
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.text('1 / 48 self-reported complete'));
    expect(
        find.text('Lessons opened: 1 · Lessons practised: 1'), findsOneWidget);
    expect(file.readAsStringSync(), old);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account switch pauses counting and blocks the old lesson save',
      (tester) async {
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    await tester.tap(find.byKey(const Key('salsa.continue')));
    await loaded(tester, find.byKey(const ValueKey('salsa.lessonBody.so_01')));
    await tapVisible(tester, const Key('salsa.counter'));
    await tester.pump(const Duration(seconds: 1));
    owner.value = bob;
    await tester.pump();
    await tester.scrollUntilVisible(
        find.byKey(const Key('salsa.savePractice')), 300,
        scrollable: find.byType(Scrollable).last);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('salsa.savePractice')))
            .onPressed,
        isNull);
    await tester.pageBack();
    await loaded(tester, find.text('0 / 48 self-reported complete'));
    expect(
        File('${temp.path}/${SalsaProgressStore.fileNameFor(bob)}')
            .existsSync(),
        isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Turkish teaching remains usable at 200 percent on a narrow phone',
      (tester) async {
    await pumpApp(tester, SalsaCoursePage(env: env), scale: 2);
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    await tester.tap(find.text('Türkçe'));
    await tester.pump();
    await tapVisible(tester, const Key('salsa.continue'));
    await loaded(tester, find.text('Salsa ile tanış'));
    for (var i = 0; i < 18; i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'four course practice weeks wrap at 200 percent on a narrow phone',
      (tester) async {
    await pumpApp(tester, SalsaCoursePage(env: env), scale: 2);
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    await tester.scrollUntilVisible(
        find.byKey(const Key('salsa.weeklyPractice.week3')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('salsa.weeklyPractice.week3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('future-dated practice explains its mismatch with course totals',
      (tester) async {
    final course = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
    final store = (await tester.runAsync(() => SalsaProgressStore.open(
        accountUserId: alice, supportDirectory: temp)))!;
    await tester.runAsync(() => store.record(
        course, course.lessons.first, SalsaEvidence.practised,
        at: DateTime.now().add(const Duration(days: 1))));
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.text('Lessons opened: 0 · Lessons practised: 1'));
    expect(
        find.descendant(
            of: find.byKey(const Key('salsa.weeklyPractice.week0')),
            matching:
                find.text('Saved attempts: 0 · Lessons with attempts: 0')),
        findsOneWidget);
    expect(find.byKey(const Key('salsa.weeklyPractice.futureDateNote')),
        findsOneWidget);
    expect(
        find.textContaining('Future-dated saved attempts: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resuming after Monday refreshes the dated weekly snapshot',
      (tester) async {
    var clock = DateTime(2026, 9, 27, 23, 59);
    await pumpApp(
        tester, SalsaCoursePage(env: env, nowForWeeklyPractice: () => clock));
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    await tester.scrollUntilVisible(
        find.byKey(const Key('salsa.weeklyPractice.week0')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('as of 27.09.2026'), findsOneWidget);
    clock = DateTime(2026, 9, 28, 0, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.textContaining('as of 28.09.2026'), findsOneWidget);
    expect(find.text('28.09.2026 – 04.10.2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real disk save failure preserves the journal and retry recovers',
      (tester) async {
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.byKey(const Key('salsa.continue')));
    await tester.tap(find.byKey(const Key('salsa.continue')));
    await loaded(tester, find.byKey(const ValueKey('salsa.lessonBody.so_01')));
    await tapVisible(tester, const Key('salsa.option.rhythmOnly'));
    final journal =
        File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}');
    final before = journal.readAsBytesSync();
    final obstruction = Directory('${journal.path}.tmp')..createSync();
    await tapVisible(tester, const Key('salsa.savePractice'));
    await loaded(tester, find.byKey(const Key('salsa.saveError')));
    expect(journal.readAsBytesSync(), before);
    expect(find.byKey(const Key('salsa.saved')), findsNothing);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('salsa.complete')))
            .onPressed,
        isNull);

    // Remove only the obstruction created by this test, then retry in place.
    obstruction.deleteSync();
    await tapVisible(tester, const Key('salsa.savePractice'));
    await loaded(tester, find.text('Practice saved · save another attempt'));
    expect(find.byKey(const Key('salsa.saveError')), findsNothing);
    final raw = jsonDecode(journal.readAsStringSync()) as Map<String, dynamic>;
    expect(
        (raw['events'] as List).map((e) => e['kind']), ['viewed', 'practised']);
    expect((raw['events'] as List).last['option'], 'rhythmOnly');
    await tester.pageBack();
    await loaded(tester, find.text('Lessons opened: 1 · Lessons practised: 1'));
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.text('Lessons opened: 1 · Lessons practised: 1'));
    expect(find.text('0 / 48 self-reported complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unreadable progress shows a retry state without invented totals',
      (tester) async {
    File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}')
        .writeAsStringSync('broken');
    await pumpApp(tester, SalsaCoursePage(env: env));
    await loaded(tester, find.byKey(const Key('salsa.loadError')));
    expect(find.byKey(const Key('salsa.completedCount')), findsNothing);
    expect(find.byKey(const Key('salsa.weeklyPractice')), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(
        File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}')
            .readAsStringSync(),
        'broken');
  });
}
