import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Native asset/plugin/file smoke only. This harness never authenticates,
/// starts a camera, reads guest journals, or assesses physical dance skill.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Salsa adapted self-report survives native file readback',
      (tester) async {
    // The path comes from the real native plugin; all writes are confined to
    // a newly created child. This UUID cannot address a real account outside it.
    const testAccount = 'c0000000-0000-4000-8000-000000000001';
    final support = await getApplicationSupportDirectory();
    final directory = await support.createTemp('salsa-smoke-');
    final owner = ValueNotifier<String?>(testAccount);
    var cameraAttempts = 0;
    final env = LiveEnvironment(
      accountUserId: owner,
      historyDirectoryOverride: directory,
      source: () {
        cameraAttempts++;
        throw StateError('A text course must not open the camera.');
      },
    );
    final file = File(
        '${directory.path}/${SalsaProgressStore.fileNameFor(testAccount)}');
    try {
      // No DiskBundle or plugin mock: native packaging must contain this asset.
      final course = SalsaCourse.fromJson(jsonDecode(
              await rootBundle.loadString('content/salsa_on1_course.json'))
          as Map<String, dynamic>);
      expect(course.lessons, hasLength(48));
      expect(course.lessons.first.id, 'so_01');
      expect(await file.exists(), isFalse);
      await _openEntry(tester, env);
      await _waitFor(tester, find.byKey(const Key('salsa.continue')));
      // Course locale follows the OS; use its actual switch for stable labels.
      if (find.text('English').evaluate().isNotEmpty) {
        await tester.tap(find.text('English'));
        await tester.pump();
      }
      expect(find.text('0 / 48 self-reported complete'), findsOneWidget);
      await _tap(tester, const Key('salsa.continue'));
      await _waitFor(
          tester, find.byKey(const ValueKey('salsa.lessonBody.so_01')));
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('salsa.lessonBody.so_01')),
              matching: find.text('Meet Salsa')),
          findsOneWidget);
      await _tap(tester, const Key('salsa.option.adapted'));
      await _tap(tester, const Key('salsa.savePractice'));
      await _waitFor(
          tester, find.text('Practice saved · save another attempt'));
      for (var i = 0; i < course.lessons.first.selfCheck.en.length; i++) {
        await _tap(tester, Key('salsa.check.$i'));
      }
      await _tap(tester, const Key('salsa.complete'));
      await _waitFor(tester, find.byKey(const Key('salsa.saved')));

      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(raw['schemaVersion'], 1);
      expect(raw['owner'], testAccount);
      final events = (raw['events'] as List)
          .map((value) => value as Map<String, dynamic>)
          .toList();
      expect(events.map((value) => value['kind']),
          ['viewed', 'practised', 'selfReportedComplete']);
      expect(events.skip(1).every((value) => value['option'] == 'adapted'),
          isTrue);
      for (final event in events) {
        expect(event['courseId'], course.id);
        expect(event['version'], course.version);
        expect(event['lessonId'], 'so_01');
        expect(event.keys.toSet(),
            {'courseId', 'version', 'lessonId', 'kind', 'option', 'at'});
      }

      // Dispose every page and store reference, then re-enter via the same UI.
      // This proves fresh file readback, not a process force-quit/relaunch.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await _openEntry(tester, env);
      await _waitFor(tester, find.byKey(const Key('salsa.continue')));
      if (find.text('English').evaluate().isNotEmpty) {
        await tester.tap(find.text('English'));
        await tester.pump();
      }
      expect(find.text('1 / 48 self-reported complete'), findsOneWidget);
      expect(find.text('1 opened · 1 practised lessons'), findsOneWidget);
      final reopened = await SalsaProgressStore.open(
          accountUserId: testAccount, supportDirectory: directory);
      final readback = await reopened.read();
      expect(readback.events, hasLength(3));
      expect(readback.events.last.kind, SalsaEvidence.selfReportedComplete);
      expect(readback.events.last.option, SalsaPracticeOption.adapted);
      expect(cameraAttempts, 0);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await SalsaProgressStore.clearAccount(testAccount,
          supportDirectory: directory);
      expect(await file.exists(), isFalse);
      final cleared = await SalsaProgressStore.open(
          accountUserId: testAccount, supportDirectory: directory);
      expect((await cleared.read()).events, isEmpty);
      binding.reportData = {
        ...?binding.reportData,
        'salsa_course_smoke': {
          'asset': 'content/salsa_on1_course.json',
          'lessons': course.lessons.length,
          'lesson': 'so_01',
          'practiceOption': 'adapted',
          'eventsReadBack': readback.events.length,
          'nativePathProvider': true,
          'freshStoreReadBack': true,
          'accountJournalCleared': true,
          'cameraAttempts': cameraAttempts,
          'physicalDanceAssessment': false,
        },
      };
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      owner.dispose();
      // The only recursive deletion is the exact directory this test created.
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _openEntry(WidgetTester tester, LiveEnvironment env) async {
  await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: Scaffold(body: SafeArea(child: SalsaCourseEntry(env: env)))));
  await tester.pump();
  await tester.tap(find.byKey(const Key('salsa.open')));
  await tester.pump();
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets, reason: 'Native course UI did not become ready');
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300,
        maxScrolls: 40, scrollable: find.byType(Scrollable).last);
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pump(const Duration(milliseconds: 450));
  bool enabled() {
    final widget = tester.widget(finder);
    if (widget is FilledButton) return widget.onPressed != null;
    if (widget is ChoiceChip) return widget.onSelected != null;
    if (widget is CheckboxListTile) return widget.onChanged != null;
    return true;
  }

  for (var i = 0; i < 100 && !enabled(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(enabled(), isTrue, reason: 'Native course action $key is disabled');
  await tester.tap(finder);
  await tester.pump();
}
