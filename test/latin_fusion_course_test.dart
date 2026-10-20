import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/latin_fusion_course.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hip_hop_course_page_test.dart' show WrittenBundle;
import 'support/test_catalog.dart';

// Source-only queued qualification; no test result is claimed for this candidate.
void main() {
  final source = File('content/latin_fusion_beginner_course.json')
      .readAsStringSync();

  Future<void> checkHorizontalLedger(WidgetTester tester, Finder pattern, String lang) async {
    final table = find.descendant(of: pattern, matching: find.byType(Table));
    expect(tester.widget<Table>(table).children.every((row) => row.children.length == 5), true);
    expect(tester.getSize(table).width, greaterThan(tester.view.physicalSize.width));
    final scroll = find.descendant(of: pattern, matching: find.byType(SingleChildScrollView));
    expect(tester.widget<SingleChildScrollView>(scroll).scrollDirection, Axis.horizontal);
    await tester.ensureVisible(scroll);
    await tester.pumpAndSettle();
    final state = tester.state<ScrollableState>(find.descendant(of: scroll, matching: find.byType(Scrollable)).first);
    final minimum = state.position.minScrollExtent;
    final maximum = state.position.maxScrollExtent;
    expect(minimum, 0);
    expect(maximum, greaterThan(minimum));
    expect(state.position.pixels, closeTo(minimum, .5));
    final viewport = tester.getRect(scroll);
    final y = (viewport.top + 20).clamp(80.0, tester.view.physicalSize.height - 20).toDouble();
    final origin = Offset(viewport.left + 30, y);
    final rightHeading = find.descendant(of: pattern, matching: find.text(lang == 'tr' ? 'Destek' : 'Support'));
    expect(rightHeading, findsOneWidget);
    for (var attempt = 0; attempt < 4 && state.position.pixels < maximum - .5; attempt++) {
      await tester.dragFrom(origin, Offset(-(maximum + viewport.width), 0));
      await tester.pumpAndSettle();
    }
    expect(state.position.pixels, closeTo(maximum, .5));
    final right = tester.getRect(rightHeading);
    expect(right.left, greaterThanOrEqualTo(viewport.left - .5));
    expect(right.right, lessThanOrEqualTo(viewport.right + .5));
    // Return by the opposite real gesture, not jumpTo or a changed expectation.
    for (var attempt = 0; attempt < 4 && state.position.pixels > minimum + .5; attempt++) {
      await tester.dragFrom(origin, Offset(maximum + viewport.width, 0));
      await tester.pumpAndSettle();
    }
    expect(state.position.pixels, closeTo(minimum, .5));
    final leftHeading = find.descendant(of: pattern, matching: find.text(lang == 'tr' ? 'Sayı' : 'Count'));
    expect(leftHeading, findsOneWidget);
    final left = tester.getRect(leftHeading);
    expect(left.left, greaterThanOrEqualTo(viewport.left - .5));
    expect(left.right, lessThanOrEqualTo(viewport.right + .5));
    expect(tester.takeException(), isNull);
  }

  test('bilingual endpoint, authored ledgers and recorded attempt order', () {
    final course = LatinFusionCourse.decode(source);
    expect(course.units.length, 8);
    expect(course.patterns.keys, ['M', 'S', 'T', 'C', 'M-side', 'P']);
    for (final pair in course.copy.values) {
      expect(pair['en'], isNotEmpty);
      expect(pair['tr'], isNotEmpty);
    }
    expect(
      course.units.last.copy['practice']!['en'],
      contains('First recorded attempt'),
    );
    expect(
      course.units.last.copy['practice']!['en'],
      contains('Second recorded attempt'),
    );
    expect(
      course.units.last.copy['practice']!['tr'],
      contains('ayrı ve puansız'),
    );
  });
  test('gates, prerequisites, transfer drift and P boundary fail closed', () {
    for (final gate in LatinFusionCourse.gates) {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      (raw['acceptance'] as Map)[gate] = true;
      expect(
        () => LatinFusionCourse.decode(jsonEncode(raw)),
        throwsFormatException,
        reason: gate,
      );
    }
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (r) => r['units'][1]['answer'].remove('tr'),
      (r) => r['units'][1]['prerequisiteIds'] = ['lf_08'],
      (r) => r['units'][1]['patternIds'] = ['unknown'],
      (r) => r['patterns'][1]['rows'][3]['supportAfter'] = 'R',
      (r) => r['patterns'][0]['rows'][0]['direction'] = 'back',
      (r) => r['patterns'][5]['nextFree'] = 'L',
      (r) => r['openTeachingComponents'][0]['physicalAccepted'] = true,
      (r) => r['finalTaskContract']['pulseExcludedFrom32'] = false,
    ]) {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      mutate(raw);
      expect(
        () => LatinFusionCourse.decode(jsonEncode(raw)),
        throwsFormatException,
      );
    }
  });
  for (final lang in ['en', 'tr']) {
    testWidgets(
      '$lang answer hidden in text/semantics until expansion, large text final reachable',
      (tester) async {
        tester.binding.platformDispatcher.localeTestValue = Locale(lang);
        addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: LatinFusionCoursePage(bundle: WrittenBundle(source)),
          ),
        );
        await tester.pumpAndSettle();
        final stage = find.byKey(const ValueKey('lf_02'));
        await tester.scrollUntilVisible(stage, 250, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(stage);
        await tester.pumpAndSettle();
        await tester.tap(stage);
        await tester.pumpAndSettle();
        final pattern = find.byKey(const ValueKey('latin.pattern.T'));
        await tester.scrollUntilVisible(pattern, 250, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(pattern);
        await tester.pumpAndSettle();
        await checkHorizontalLedger(tester, pattern, lang);
        final text = LatinFusionCourse.decode(source)
            .units[1]
            .copy['answer']![lang]!;
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          expect(find.text(text, skipOffstage: false), findsNothing);
          expect(find.bySemanticsLabel(text), findsNothing);
          final answer = find.byKey(const ValueKey('latin.answer'));
          await tester.scrollUntilVisible(answer, 250, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
          await tester.ensureVisible(answer);
          await tester.pumpAndSettle();
          await tester.tap(answer);
          await tester.pumpAndSettle();
          expect(find.text(text, skipOffstage: false), findsOneWidget);
          expect(find.bySemanticsLabel(text), findsOneWidget);
        } finally {
          semantics.dispose();
        }
        final last = find.byKey(const ValueKey('lf_08'));
        await tester.scrollUntilVisible(last, 250, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        await tester.tap(last);
        await tester.pumpAndSettle();
        final practice = find.text(lang == 'tr' ? 'Çalış' : 'Practise').last;
        await tester.scrollUntilVisible(practice, 250, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
        expect(practice, findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('real bundled written route leaves physical catalog comingSoon', (
    tester,
  ) async {
    final library = await tester.runAsync(testLibrary);
    final card = library!.cardFor('latin_fusion_fitness')!;
    expect(card.entry.contentStatus, 'comingSoon');
    // Prime the real bundled asset outside the fake clock. Above 50 KB,
    // AssetBundle.loadString uses compute; starting that read inside a widget
    // frame can leave its isolate waiting on the test's fake clock.
    final primed = await tester.runAsync(() => rootBundle.loadString('content/latin_fusion_beginner_course.json'));
    expect(primed, isNotEmpty);
    await tester.pumpWidget(MaterialApp(home: StyleDetailView(card: card)));
    final link = find.byKey(const Key('style.latinFusionWrittenCourse'));
    await tester.scrollUntilVisible(link, 200, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final bundled = await tester.runAsync(
      () => rootBundle.loadString('content/latin_fusion_beginner_course.json'),
    );
    expect(LatinFusionCourse.decode(bundled!).units.length, 8);
    await tester.pumpAndSettle();
    expect(find.byType(LatinFusionCoursePage), findsOneWidget);
    expect(card.entry.contentStatus, 'comingSoon');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Back and unmount while loading discard late Latin content', (tester) async {
    final pending = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      Scaffold(body: TextButton(onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => LatinFusionCoursePage(bundle: pending))),
        child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(LatinFusionCoursePage), findsNothing);
    pending.pending!.complete(source);
    await tester.pump();
    expect(find.byType(LatinFusionCoursePage), findsNothing);
    final next = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: LatinFusionCoursePage(bundle: next)));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    next.pending!.complete('invalid');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('error/retry, pending replacement and ten-second timeout', (
    tester,
  ) async {
    final failing = WrittenBundle(source)..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: LatinFusionCoursePage(bundle: failing)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    failing.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('Latin Fusion: low-impact written foundations'),
      findsOneWidget,
    );
    final pending = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(
      MaterialApp(home: LatinFusionCoursePage(bundle: pending)),
    );
    await tester.pump();
    expect(
      find.text('Latin Fusion: low-impact written foundations'),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    pending.pending!.complete(source);
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
