import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/course/salsa_session_preparation.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yesterday is not preparation for a new day even if the app stayed open',
      () {
    var now = DateTime(2026, 9, 28, 23, 59);
    final session = SalsaPreparationSession(now: () => now);
    session.acknowledged = true;
    expect(session.acknowledged, isTrue);
    now = DateTime(2026, 9, 29);
    expect(session.acknowledged, isFalse);
  });

  late Directory directory;
  late SalsaCourse course;
  late SalsaProgressStore store;
  late LiveEnvironment env;
  late ValueNotifier<String?> owner;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('salsa-preparation-');
    owner = ValueNotifier(null);
    course = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
    env = LiveEnvironment(
        historyDirectoryOverride: directory,
        accountUserId: owner,
        source: () => throw StateError('No camera in preparation.'));
  });
  tearDown(() {
    owner.dispose();
    directory.deleteSync(recursive: true);
  });

  Future<void> io(WidgetTester tester) async {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 80));
  }

  Future<SalsaProgress> readSaved(WidgetTester tester,
      {int expected = 1}) async {
    final file =
        File('${directory.path}/${SalsaProgressStore.fileNameFor(null)}');
    for (var i = 0; i < 80; i++) {
      await io(tester);
      if (!file.existsSync()) continue;
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final events = (raw['events'] as List)
          .map((dynamic e) =>
              SalsaProgressEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      if (events.length >= expected) return SalsaProgress(events);
    }
    throw StateError('Expected $expected persisted events');
  }

  Future<void> open(WidgetTester tester, String id,
      {bool tr = false,
      SalsaPreparationSession? session,
      double scale = 1}) async {
    await tester.pumpWidget(const SizedBox());
    store = (await tester
        .runAsync(() => SalsaProgressStore.open(supportDirectory: directory)))!;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ChoreiaTheme.dark,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: SalsaLessonPage(
            course: course,
            lesson: course.lesson(id),
            store: store,
            env: env,
            initialTurkish: tr,
            preparationSession: session)));
    for (var i = 0; i < 5; i++) {
      await io(tester);
    }
  }

  Future<Finder> reveal(WidgetTester tester, String key) async {
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await tester.pump();
    final target = find.byKey(Key(key));
    await tester.scrollUntilVisible(target, 250,
        scrollable: find.byType(Scrollable).first, maxScrolls: 100);
    await tester.pump(const Duration(milliseconds: 100));
    return target;
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final target = await reveal(tester, key);
    bool enabled() {
      final widget = tester.widget(target);
      if (widget is ButtonStyleButton) return widget.onPressed != null;
      if (widget is ChoiceChip) return widget.onSelected != null;
      if (widget is CheckboxListTile) return widget.onChanged != null;
      return true;
    }

    for (var i = 0; i < 80 && !enabled(); i++) {
      await io(tester);
    }
    expect(enabled(), isTrue, reason: '$key must become available');
    await tester.tap(target);
    await io(tester);
  }

  for (final id in ['so_19', 'so_21', 'so_27', 'so_30', 'so_43']) {
    for (final tr in [false, true]) {
      testWidgets('$id ${tr ? 'TR' : 'EN'} fresh entry gates physical practice',
          (tester) async {
        await open(tester, id, tr: tr);
        expect(find.byKey(const Key('salsa.preparation')), findsOneWidget);
        await reveal(tester, 'salsa.preparation.required');
        expect(
            find.text(course.lesson(id).practice.inLanguage(tr)), findsNothing);
        final save = await reveal(tester, 'salsa.savePractice');
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        final before = (await readSaved(tester));
        expect(before.events.map((e) => e.kind), [SalsaEvidence.viewed]);
        await tap(tester, 'salsa.preparation.spokenOnly');
        expect(find.byKey(const Key('salsa.preparation')), findsNothing);
        await reveal(tester, 'salsa.spokenPractice');
        expect(
            find.text(course.lesson(id).practice.inLanguage(tr)), findsNothing);
        expect(find.byKey(const Key('salsa.spokenPractice')), findsOneWidget);
        await tap(tester, 'salsa.savePractice');
        final after = await readSaved(tester, expected: 2);
        expect(after.events.last.kind, SalsaEvidence.practised);
        expect(after.events.last.option, SalsaPracticeOption.rhythmOnly);
        expect(
            after.events
                .any((e) => e.kind == SalsaEvidence.selfReportedComplete),
            isFalse);
        // A spoken attempt does not silently prepare the physical option.
        await tap(tester, 'salsa.option.standard');
        await reveal(tester, 'salsa.preparation.required');
        expect(find.byKey(const Key('salsa.preparation.required')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'acknowledgement is transient and foreground loss requires preparation again',
      (tester) async {
    await open(tester, 'so_27');
    await tap(tester, 'salsa.preparation.acknowledge');
    expect((await readSaved(tester)).events.length, 1);
    await tap(tester, 'salsa.option.adapted');
    await tap(tester, 'salsa.counter');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final blocked = await reveal(tester, 'salsa.savePractice');
    expect(tester.widget<FilledButton>(blocked).onPressed, isNull);
    await tap(tester, 'salsa.preparation.acknowledge');
    await tap(tester, 'salsa.savePractice');
    expect((await readSaved(tester, expected: 2)).events.last.option,
        SalsaPracticeOption.adapted);
    // The persisted practice record cannot acknowledge a new direct route.
    await open(tester, 'so_27');
    expect(find.byKey(const Key('salsa.preparation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final reset in ['manual break', 'foreground loss']) {
    testWidgets('$reset invalidates physical practice before completion',
        (tester) async {
      await open(tester, 'so_27');
      await tap(tester, 'salsa.preparation.acknowledge');
      await tap(tester, 'salsa.savePractice');
      await readSaved(tester, expected: 2);
      for (var i = 0; i < course.lesson('so_27').selfCheck.en.length; i++) {
        await tap(tester, 'salsa.check.$i');
      }
      final completeBefore = await reveal(tester, 'salsa.complete');
      expect(tester.widget<FilledButton>(completeBefore).onPressed, isNotNull);

      if (reset == 'manual break') {
        await tap(tester, 'salsa.preparation.restart');
      } else {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
      }
      await tap(tester, 'salsa.preparation.acknowledge');
      final completeAfter = await reveal(tester, 'salsa.complete');
      expect(tester.widget<FilledButton>(completeAfter).onPressed, isNull,
          reason: 'Preparation alone must not reuse the earlier practice.');
      expect((await readSaved(tester, expected: 2)).events.length, 2);

      await tap(tester, 'salsa.savePractice');
      await readSaved(tester, expected: 3);
      for (var i = 0; i < course.lesson('so_27').selfCheck.en.length; i++) {
        final check = await reveal(tester, 'salsa.check.$i');
        if (tester.widget<CheckboxListTile>(check).value != true) {
          await tap(tester, 'salsa.check.$i');
        }
      }
      await tap(tester, 'salsa.complete');
      final saved = await readSaved(tester, expected: 4);
      expect(saved.events.map((e) => e.kind), [
        SalsaEvidence.viewed,
        SalsaEvidence.practised,
        SalsaEvidence.practised,
        SalsaEvidence.selfReportedComplete,
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'same course session shares preparation; break and owner change revoke it',
      (tester) async {
    final session = SalsaPreparationSession();
    await open(tester, 'so_19', session: session);
    await tap(tester, 'salsa.preparation.acknowledge');
    await open(tester, 'so_21', session: session);
    expect(find.byKey(const Key('salsa.preparation')), findsNothing);
    await tap(tester, 'salsa.preparation.restart');
    expect(session.acknowledged, isFalse);
    await tap(tester, 'salsa.preparation.acknowledge');
    owner.value = '11111111-1111-4111-8111-111111111111';
    await tester.pump();
    expect(session.acknowledged, isFalse);
    final save = await reveal(tester, 'salsa.savePractice');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spoken/context lessons do not require dance preparation',
      (tester) async {
    for (final id in ['so_01', 'so_03', 'so_46']) {
      await open(tester, id);
      expect(find.byKey(const Key('salsa.preparation')), findsNothing);
      await tap(tester, 'salsa.savePractice');
    }
  });

  testWidgets(
      'next lesson keeps preparation within the same uninterrupted session',
      (tester) async {
    await open(tester, 'so_26');
    await tap(tester, 'salsa.preparation.acknowledge');
    await tap(tester, 'salsa.savePractice');
    await readSaved(tester, expected: 2);
    for (var i = 0; i < course.lesson('so_26').selfCheck.en.length; i++) {
      await tap(tester, 'salsa.check.$i');
    }
    await tap(tester, 'salsa.complete');
    await readSaved(tester, expected: 3);
    // Atomic file rename can precede the widget's async save continuation.
    for (var i = 0;
        i < 80 && find.byKey(const Key('salsa.next')).evaluate().isEmpty;
        i++) {
      await io(tester);
    }
    await tap(tester, 'salsa.next');
    await reveal(tester, 'salsa.savePractice');
    expect(
        find.byKey(const ValueKey('salsa.lessonBody.so_27')), findsOneWidget);
    expect(find.byKey(const Key('salsa.preparation')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Turkish preparation remains usable at 200 percent text size',
      (tester) async {
    await open(tester, 'so_27', tr: true, scale: 2);
    await tap(tester, 'salsa.preparation.acknowledge');
    expect(find.byKey(const Key('salsa.preparation')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
