import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/hip_hop_course.dart';
import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hip_hop_course_page_test.dart' show WrittenBundle;
import 'support/test_catalog.dart';

void main() {
  final source =
      File('content/hip_hop_foundations_skill_course.json').readAsStringSync();
  test('intro and skill-course assets cannot be silently exchanged', () {
    expect(() => HipHopCourse.decode(source), throwsFormatException);
    final intro =
        File('content/hip_hop_foundations_course.json').readAsStringSync();
    expect(() => HipHopCourse.decode(intro, skillCourse: true),
        throwsFormatException);
    final course = HipHopCourse.decode(source, skillCourse: true);
    expect(course.units.length, 8);
    expect(course.displayFields, contains('provenance'));
    for (final unit in course.units) {
      for (final pair in unit.copy.values) {
        expect(pair['tr'], isNotEmpty);
        expect(pair['en'], isNotEmpty);
      }
    }
    expect(course.units.last.copy['practice']!['en'], contains('attempt B'));
  });
  test('release or physical acceptance cannot be opened by asset change', () {
    for (final field in [
      'scoring',
      'progressWrites',
      'releaseEligible',
      'physicalInstructionAccepted',
      'mediaRightsAccepted',
      'completeCurriculumAccepted'
    ]) {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      (raw['acceptance'] as Map<String, dynamic>)[field] = true;
      expect(() => HipHopCourse.decode(jsonEncode(raw), skillCourse: true),
          throwsFormatException,
          reason: field);
    }
    final raw = jsonDecode(source) as Map<String, dynamic>;
    (raw['units'] as List<dynamic>).removeLast();
    expect(() => HipHopCourse.decode(jsonEncode(raw), skillCourse: true),
        throwsFormatException);
  });
  for (final lang in ['en', 'tr']) {
    testWidgets('$lang full endpoint and reassessment reachable at 200% text',
        (tester) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(lang);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home:
            HipHopCoursePage(skillCourse: true, bundle: WrittenBundle(source)),
      ));
      await tester.pumpAndSettle();
      final notice = find.textContaining(
          lang == 'tr' ? 'Müzikle sayım' : 'An eight-stage beginner Hip-Hop');
      await tester.scrollUntilVisible(notice, 200);
      expect(notice, findsOneWidget);
      for (var n = 1; n <= 8; n++) {
        final stage = find.byKey(ValueKey('hhs_0$n'));
        await tester.scrollUntilVisible(stage, 250, maxScrolls: 100);
        expect(stage, findsOneWidget);
      }
      final last = find.byKey(const ValueKey('hhs_08'));
      await Scrollable.ensureVisible(tester.element(last), alignment: 0.2);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      final check = find.text(
          lang == 'tr' ? 'Öz kontrol ve tekrar' : 'Self-check and revisit');
      await tester.scrollUntilVisible(check, 250, maxScrolls: 100);
      expect(check, findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('skill course uses existing navigation and separate asset',
      (tester) async {
    final library = await tester.runAsync(testLibrary);
    // Start the real large-asset read outside the widget fake-async zone.
    // The subsequent route still loads the actual bundled skill asset.
    final bundled = await tester.runAsync(() =>
        rootBundle.loadString('content/hip_hop_foundations_skill_course.json'));
    expect(bundled, source);
    expect(HipHopCourse.decode(bundled!, skillCourse: true).units.length, 8);
    await tester.pumpWidget(MaterialApp(
        home: StyleDetailView(card: library!.cardFor('hip_hop_foundations')!)));
    final link = find.byKey(const Key('style.hipHopSkillCourse'));
    await tester.scrollUntilVisible(link, 200);
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final page = tester.widget<HipHopCoursePage>(find.byType(HipHopCoursePage));
    expect(page.skillCourse, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Hip-Hop Foundations: beginner course'), findsOneWidget);
    expect(
        find.textContaining('An eight-stage beginner Hip-Hop'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('mode change rejects late old completion and hides prior data',
      (tester) async {
    final introSource =
        File('content/hip_hop_foundations_course.json').readAsStringSync();
    final old = WrittenBundle(introSource)..pending = Completer<String>();
    final next = WrittenBundle(source)..pending = Completer<String>();
    const key = ValueKey('reader');
    await tester
        .pumpWidget(MaterialApp(home: HipHopCoursePage(key: key, bundle: old)));
    await tester.pumpWidget(MaterialApp(
        home: HipHopCoursePage(key: key, skillCourse: true, bundle: next)));
    old.pending!.complete(introSource);
    await tester.pump();
    expect(
        find.text('Hip-Hop Foundations: written introduction'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    next.pending!.complete(source);
    await tester.pumpAndSettle();
    expect(find.text('Hip-Hop Foundations: beginner course'), findsOneWidget);
    final replacement = WrittenBundle(introSource)
      ..pending = Completer<String>();
    await tester.pumpWidget(
        MaterialApp(home: HipHopCoursePage(key: key, bundle: replacement)));
    await tester.pump();
    expect(find.text('Hip-Hop Foundations: beginner course'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    replacement.pending!.complete(introSource);
    await tester.pumpAndSettle();
    expect(
        find.text('Hip-Hop Foundations: written introduction'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
