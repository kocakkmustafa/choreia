import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show SemanticsRole;

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/theme/theme_preference.dart';
import 'package:choreia/app/ui_language.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

void main() {
  // Each definition visits every locale on the same real course page. The
  // iterations are not separate executed test bodies or native AT acceptance.
  for (final completed in [0, 1, 48]) {
    testWidgets(
        'Salsa numeric progress semantics $completed of 48 in 14 locales',
        (tester) async {
      final fixtureZone = Zone.current;
      final directory =
          Directory.systemTemp.createTempSync('choreia-progress-semantics-');
      final owners = AppStoreOwnerRegistry();
      final locales = ChoreiaLocaleController.memory(const Locale('en'));
      final themes = ChoreiaThemeController.memory(ThemeMode.dark);
      var cameraCalls = 0;
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        var drained = false;
        Object? drainError;
        StackTrace? drainStack;
        fixtureZone.run<void>(() {
          unawaited(owners.retireOwner(null).then<void>((_) {
            drained = true;
          }, onError: (Object error, StackTrace stack) {
            drainError = error;
            drainStack = stack;
            drained = true;
          }));
        });
        for (var turn = 0; turn < 300 && !drained; turn++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 2)));
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(drained, isTrue,
            reason:
                'The actual owner drain must finish before fixture deletion');
        final failure = drainError;
        if (failure != null) Error.throwWithStackTrace(failure, drainStack!);
        directory.deleteSync(recursive: true);
        locales.dispose();
        themes.dispose();
        expect(cameraCalls, 0);
        expect(tester.takeException(), isNull);
      });

      final course = SalsaCourse.fromJson(
          jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
              as Map<String, dynamic>);
      expect(course.lessons, hasLength(48));
      final events = <SalsaProgressEvent>[];
      for (final lesson in course.lessons.take(completed)) {
        expect(
            lesson
                .selfChecksFor(SalsaPracticeOption.standard)
                .completionAllowed,
            isTrue);
        for (final kind in [
          SalsaEvidence.practised,
          SalsaEvidence.selfReportedComplete
        ]) {
          events.add(SalsaProgressEvent(
              courseId: course.id,
              version: course.version,
              lessonId: lesson.id,
              kind: kind,
              option: SalsaPracticeOption.standard,
              at: DateTime.utc(2026, 10, 20)));
        }
      }
      final journal =
          File('${directory.path}/${SalsaProgressStore.fileNameFor(null)}');
      journal.writeAsStringSync(jsonEncode({
        'schemaVersion': 1,
        'owner': 'guest',
        'events': events.map((event) => event.toJson()).toList(),
      }));
      final before = journal.readAsBytesSync();
      final env = LiveEnvironment(
          bundle: DeviceBundle(declaredReferences()),
          historyDirectoryOverride: directory,
          storeOwners: owners,
          source: () {
            cameraCalls++;
            throw StateError('A semantics check must not start the camera');
          },
          cameraPermissionRequest: () async {
            cameraCalls++;
            throw StateError('A semantics check must not request permission');
          });
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);
      await tester.pumpWidget(ChoreiaApp(
        localeController: locales,
        themeController: themes,
        localeBundle: DiskBundle(),
        shellBuilder: (_, __) => SalsaCoursePage(env: env),
      ));
      final progress = find.byType(LinearProgressIndicator);
      await _waitFor(tester, () => progress.evaluate().length == 1,
          'The real Salsa overview must finish its course and journal read');
      await tester.ensureVisible(progress);
      await tester.pump();
      final pageState = tester.state(find.byType(SalsaCoursePage));
      final expectedValue = (100 * completed / course.lessons.length).round();
      for (final locale in ChoreiaLocaleController.supported) {
        await locales.select(locale, persist: false);
        await _waitFor(tester, () {
          final context = tester.element(progress);
          return Localizations.localeOf(context) == locale &&
              ChoreiaMessages.of(context).localeTag ==
                  ChoreiaLocaleController.tag(locale);
        }, 'Both inherited locale and actual app resources must be ready');
        final context = tester.element(progress);
        final label = UiLanguage.text(context,
            en: 'Self-reported completion', tr: 'Öz beyanla tamamlanma');
        expect(label, isNotEmpty);
        expect(ChoreiaMessages.of(context).translationUnavailable, isFalse);
        final semanticWidget = find.descendant(
            of: find.byKey(const Key('salsa.overview')),
            matching: find.byWidgetPredicate((widget) =>
                widget is Semantics &&
                widget.properties.role == SemanticsRole.progressBar &&
                widget.properties.label == label));
        expect(semanticWidget, findsOneWidget);
        final data = tester.getSemantics(semanticWidget).getSemanticsData();
        expect(data.role, SemanticsRole.progressBar);
        expect(data.label, label);
        expect(data.minValue, '0');
        expect(data.maxValue, '100');
        expect(double.tryParse(data.value), expectedValue.toDouble());
        expect(tester.widget<LinearProgressIndicator>(progress).value,
            completed / course.lessons.length);
        expect(tester.state(find.byType(SalsaCoursePage)), same(pageState));
        expect(journal.readAsBytesSync(), before,
            reason: 'Changing presentation must not mutate the study record');
        expect(tester.takeException(), isNull);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}

Future<void> _waitFor(
    WidgetTester tester, bool Function() ready, String witness) async {
  for (var turn = 0; turn < 120 && !ready(); turn++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull, reason: witness);
  }
  expect(ready(), isTrue, reason: witness);
  await tester.pump();
}
