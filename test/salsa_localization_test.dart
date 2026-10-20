import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import 'support/test_catalog.dart';

const _entryTemplate =
    '{modules} modules · {lessons} lessons · {languages} languages';

Widget _localized(ChoreiaLocaleController controller, Widget home) =>
    ChoreiaLocaleScope(
      controller: controller,
      child: ValueListenableBuilder<Locale?>(
        valueListenable: controller,
        builder: (_, locale, __) => MaterialApp(
          locale: locale,
          supportedLocales: ChoreiaLocaleController.supported,
          localeResolutionCallback: ChoreiaLocaleController.resolve,
          localizationsDelegates: [
            ChoreiaMessagesDelegate(bundle: DiskBundle()),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ChoreiaTheme.dark,
          home: home,
        ),
      ),
    );

Future<void> _loaded(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

void main() {
  for (final locale in ChoreiaLocaleController.supported) {
    final tag = ChoreiaLocaleController.tag(locale);
    testWidgets('$tag entry translates before inserting all three counts',
        (tester) async {
      final controller = ChoreiaLocaleController.memory(locale);
      addTearDown(controller.dispose);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          _localized(controller, const Scaffold(body: SalsaCourseEntry())));
      await _loaded(tester, find.byKey(const Key('salsa.open')));

      final template = switch (tag) {
        'en' => _entryTemplate,
        'tr' => '{modules} modül · {lessons} ders · {languages} dil',
        _ => (jsonDecode(File('content/l10n/ui.$tag.json').readAsStringSync())
            as Map<String, dynamic>)[_entryTemplate] as String,
      };
      final number = NumberFormat.decimalPattern(tag.replaceAll('-', '_'));
      final expected = template
          .replaceAll('{modules}', number.format(8))
          .replaceAll('{lessons}', number.format(48))
          .replaceAll('{languages}',
              number.format(ChoreiaLocaleController.supported.length));
      expect(find.text(expected), findsOneWidget);
      expect(find.textContaining('{modules}'), findsNothing);
      if (tag != 'en') {
        expect(find.text('8 modules · 48 lessons · 8 languages'), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('German overview localizes next title, numbers and calendar date',
      (tester) async {
    final directory = Directory.systemTemp.createTempSync('choreia-locale-');
    final controller = ChoreiaLocaleController.memory(const Locale('de'));
    addTearDown(controller.dispose);
    addTearDown(() => directory.deleteSync(recursive: true));
    final env = LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        historyDirectoryOverride: directory);
    final asOf = DateTime(2027, 1, 1, 12);
    await tester.pumpWidget(_localized(controller,
        SalsaCoursePage(env: env, nowForWeeklyPractice: () => asOf)));
    await _loaded(tester, find.byKey(const Key('salsa.completedCount')));
    expect(find.text('0 / 48 selbst berichtet abgeschlossen'), findsOneWidget);
    expect(find.text('Weiter: 1. Salsa kennenlernen'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const Key('salsa.weeklyPractice')), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining(DateFormat.yMMMd('de').format(asOf)),
        findsOneWidget);
    expect(find.textContaining('Four calendar weeks as of'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TR to Arabic changes the open lesson without clearing checks',
      (tester) async {
    final directory =
        Directory.systemTemp.createTempSync('choreia-route-locale-');
    final controller = ChoreiaLocaleController.memory(const Locale('tr'));
    addTearDown(controller.dispose);
    addTearDown(() => directory.deleteSync(recursive: true));
    final course = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
    final store = (await tester
        .runAsync(() => SalsaProgressStore.open(supportDirectory: directory)))!;
    final env = LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        historyDirectoryOverride: directory,
        source: () =>
            throw StateError('Locale changes must not start camera.'));
    await tester.pumpWidget(_localized(
        controller,
        SalsaLessonPage(
            course: course,
            lesson: course.lessons.first,
            store: store,
            env: env,
            initialTurkish: true)));
    final check = find.byKey(const Key('salsa.check.0'));
    await _loaded(tester, find.byKey(const ValueKey('salsa.lessonBody.so_01')));
    await tester.scrollUntilVisible(check, 400,
        scrollable: find.byType(Scrollable).first);
    // The body can render before its real viewed-record write finishes.
    // Wait for the enabled control, not merely for the row to exist.
    for (var i = 0; i < 60; i++) {
      if (tester.widget<CheckboxListTile>(check).onChanged != null) break;
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.widget<CheckboxListTile>(check).onChanged, isNotNull);
    await tester.tap(check);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(check).value, isTrue);
    final file =
        File('${directory.path}/${SalsaProgressStore.fileNameFor(null)}');
    for (var i = 0; i < 60 && !file.existsSync(); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
    expect(file.existsSync(), isTrue);
    final before = file.readAsBytesSync();

    await controller.select(const Locale('ar'), persist: false);
    // The backdrop repeats; wait for applied resources rather than idle frames.
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
      if (ChoreiaMessages.of(tester.element(check)).localeTag == 'ar') break;
    }
    expect(ChoreiaMessages.of(tester.element(check)).localeTag, 'ar');
    // The resources getter can update before the inherited tree's next frame.
    await tester.pump();
    expect(Localizations.localeOf(tester.element(check)), const Locale('ar'));
    expect(tester.widget<CheckboxListTile>(check).value, isTrue);
    expect(Directionality.of(tester.element(check)), TextDirection.rtl);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('salsa.mediaSlot.so_01')), -400,
        scrollable: find.byType(Scrollable).first);
    final slot = tester.widget<LessonMediaSlot>(
        find.byKey(const ValueKey('salsa.mediaSlot.so_01')));
    expect(slot.locale, 'ar');
    expect(slot.catalog.isEmpty, isTrue);
    expect(file.readAsBytesSync(), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
