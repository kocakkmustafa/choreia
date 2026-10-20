import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/short_form_course.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hip_hop_course_page_test.dart' show WrittenBundle;
import 'support/test_catalog.dart';

// Queued source only. No executable qualification is claimed.
void main() {
  final source = File('content/original_short_form_beginner_course.json').readAsStringSync();
  final course = ShortFormCourse.decode(source);
  String answer(String lang) => course.units[1].copy['answer']![lang]!;
  final stage2 = find.byKey(const ValueKey('sf_02'));
  final reveal = find.byKey(const ValueKey('shortForm.answer.sf_02'));

  Future<void> reach(WidgetTester tester, Finder target, {bool animatedStyle = false}) async {
    await tester.scrollUntilVisible(target, 220, maxScrolls: 500, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(target);
    if (animatedStyle) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pumpAndSettle();
    }
  }
  Future<void> openAnswer(WidgetTester tester) async {
    await reach(tester, stage2);
    await tester.tap(stage2);
    await tester.pumpAndSettle();
    await reach(tester, reveal);
    await tester.tap(reveal);
    await tester.pumpAndSettle();
  }


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

  test('seven bilingual stages and original independent endpoint', () {
    expect(course.units.map((u) => u.id), ['sf_01', 'sf_02', 'sf_03', 'sf_04', 'sf_05', 'sf_06', 'sf_07']);
    expect(course.patterns.keys, ['A', 'A-var', 'B']);
    for (final pair in course.copy.values) {
      expect(pair['en'], isNotEmpty);
      expect(pair['tr'], isNotEmpty);
    }
    final raw = jsonDecode(source) as Map<String, dynamic>;
    expect(raw['finalTaskContract']['learnerAuthored'], true);
    expect(raw['finalTaskContract']['merelyRenamingWorkedExampleEligible'], false);
    expect(raw['finalTaskContract']['beats'], 16);
    expect(course.copy['provenance']!['tr'], contains('Yalnızca terimler ve kategoriler'));
    expect(course.copy['provenance']!['tr'], isNot(contains('Vocabulary/categories only')));
  });

  test('closed gates, answer pairs, stage links and movement contracts reject drift', () {
    for (final gate in ShortFormCourse.gates) {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      raw['acceptance'][gate] = true;
      expect(() => ShortFormCourse.decode(jsonEncode(raw)), throwsFormatException, reason: gate);
    }
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (r) => r['units'][1]['answer'].remove('tr'),
      (r) => r['units'][1]['answer']['en'] = 'W/W/T/W; support L/R/R/L',
      (r) => r['units'][1]['exercise']['tr'] = 'Değişmiş soru',
      (r) => r['units'][1]['prerequisiteIds'] = ['sf_07'],
      (r) => r['units'][1]['patternIds'] = ['B'],
      (r) => r['units'][0]['sourceIds'] = ['unknown'],
      (r) => r['patterns'][0]['rows'][1]['action'] = 'W',
      (r) => r['patterns'][0]['rows'][0]['direction'] = 'right',
      (r) => r['patterns'][1]['rows'][2]['optionalGesture'] = 'rest',
      (r) => r['patterns'][2]['rows'][0]['supportAfter'] = 'L',
      (r) => r['patterns'][2]['nextFree'] = 'R',
      (r) => r['patterns'][0]['physicalTeachingAccepted'] = true,
      (r) => r['openTeachingComponents'][0]['status'] = 'accepted',
      (r) => r['finalTaskContract']['cameraRequired'] = true,
      (r) => r['finalTaskContract']['merelyRenamingWorkedExampleEligible'] = true,
    ]) {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      mutate(raw);
      expect(() => ShortFormCourse.decode(jsonEncode(raw)), throwsFormatException);
    }
  });

  test('exact serialization is intentional: row key order fails; outer order/spacing does not', () {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    expect(ShortFormCourse.decode(const JsonEncoder.withIndent(' ').convert(raw)).units.length, 7);
    final outer = Map<String, dynamic>.fromEntries(raw.entries.toList().reversed);
    expect(ShortFormCourse.decode(jsonEncode(outer)).patterns.length, 3);
    final row = Map<String, dynamic>.from(raw['patterns'][0]['rows'][0] as Map);
    raw['patterns'][0]['rows'][0] = Map<String, dynamic>.fromEntries(row.entries.toList().reversed);
    expect(() => ShortFormCourse.decode(jsonEncode(raw)), throwsFormatException);
    final answerOrder = jsonDecode(source) as Map<String, dynamic>;
    final pair = Map<String, dynamic>.from(answerOrder['units'][1]['answer'] as Map);
    answerOrder['units'][1]['answer'] = Map<String, dynamic>.fromEntries(pair.entries.toList().reversed);
    // pairs() canonicalizes EN/TR before exact answer comparison.
    expect(ShortFormCourse.decode(jsonEncode(answerOrder)).units[1].copy['answer']!['en'], answer('en'));
  });

  for (final lang in ['en', 'tr']) {
    testWidgets('$lang large text: hidden/open Text+semantics, five-column tables, final navigation', (tester) async {
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
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
        home: ShortFormCoursePage(bundle: WrittenBundle(source))));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, lang == 'tr' ? 'Özgün kısa dans yazılı temeller' : 'Original short-form written foundations'), findsOneWidget);
      await reach(tester, stage2);
      await tester.tap(stage2);
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(find.text(answer(lang), skipOffstage: false), findsNothing);
        expect(find.bySemanticsLabel(answer(lang)), findsNothing);
        await reach(tester, find.byKey(const ValueKey('shortForm.pattern.A')));
        final table = find.descendant(of: find.byKey(const ValueKey('shortForm.pattern.A')), matching: find.byType(Table));
        expect(tester.widget<Table>(table).children.every((r) => r.children.length == 5), true);
        await checkHorizontalLedger(tester, find.byKey(const ValueKey('shortForm.pattern.A')), lang);
        expect(tester.takeException(), isNull);
        await reach(tester, reveal);
        await tester.tap(reveal);
        await tester.pumpAndSettle();
        expect(find.text(answer(lang), skipOffstage: false), findsOneWidget);
        expect(find.bySemanticsLabel(answer(lang)), findsOneWidget);
        final answerHeader = find.descendant(of: reveal, matching: find.text(lang == 'tr' ? 'Cevabı göster' : 'Reveal the answer'));
        await reach(tester, answerHeader);
        await tester.tap(answerHeader);
        await tester.pumpAndSettle();
        expect(find.text(answer(lang), skipOffstage: false), findsNothing);
        expect(find.bySemanticsLabel(answer(lang)), findsNothing);
      } finally {
        semantics.dispose();
      }
      // Close through the actual title, not the expanded card/body center.
      final stageHeader = find.descendant(of: stage2,
          matching: find.text(course.units[1].copy['title']![lang]!));
      await reach(tester, stageHeader);
      await tester.tap(stageHeader);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('shortForm.pattern.A'), skipOffstage: false), findsNothing);
      final composition = find.byKey(const ValueKey('sf_04'));
      await reach(tester, composition);
      await tester.tap(composition);
      await tester.pumpAndSettle();
      for (final id in ['A', 'A-var', 'B']) {
        final diagram = find.byKey(ValueKey('shortForm.pattern.$id'));
        await reach(tester, diagram);
        final table = find.descendant(of: diagram, matching: find.byType(Table));
        expect(tester.widget<Table>(table).children.length, 9);
        expect(tester.widget<Table>(table).children.every((r) => r.children.length == 5), true);
        expect(tester.takeException(), isNull);
      }
      final last = find.byKey(const ValueKey('sf_07'));
      await reach(tester, last);
      await tester.tap(last);
      await tester.pumpAndSettle();
      final finalPractice = find.text(course.units.last.copy['practice']![lang]!);
      await reach(tester, finalPractice);
      expect(finalPractice, findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('answer resets on bundle reload and stale old answer is absent while pending', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: WrittenBundle(source))));
    await tester.pumpAndSettle();
    await openAnswer(tester);
    expect(find.text(answer('en'), skipOffstage: false), findsOneWidget);
    final replacement = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: replacement)));
    await tester.pump();
    expect(find.text(answer('en'), skipOffstage: false), findsNothing);
    replacement.pending!.complete(source);
    await tester.pumpAndSettle();
    await reach(tester, stage2);
    await tester.tap(stage2);
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      expect(find.text(answer('en'), skipOffstage: false), findsNothing);
      expect(find.bySemanticsLabel(answer('en')), findsNothing);
      await reach(tester, reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(find.text(answer('en'), skipOffstage: false), findsOneWidget);
      expect(find.bySemanticsLabel(answer('en')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual bundled style route retains comingSoon and named route; Back returns', (tester) async {
    final library = await tester.runAsync(testLibrary);
    final card = library!.cardFor('tiktok_format')!;
    expect(card.entry.contentStatus, 'comingSoon');
    final spy = _RouteSpy();
    // Prime the real bundled asset outside the fake clock. Above 50 KB,
    // AssetBundle.loadString uses compute; starting that read inside a widget
    // frame can leave its isolate waiting on the test's fake clock.
    final primed = await tester.runAsync(() => rootBundle.loadString('content/original_short_form_beginner_course.json'));
    expect(primed, isNotEmpty);
    await tester.pumpWidget(MaterialApp(navigatorObservers: [spy], home: StyleDetailView(card: card)));
    final link = find.byKey(const Key('style.shortFormWrittenCourse'));
    await reach(tester, link, animatedStyle: true);
    expect(find.descendant(of: link, matching: find.text('Open written course')),
        findsOneWidget);
    expect(tester.widget<FilledButton>(link).onPressed, isNotNull);
    expect(find.textContaining('Demonstration and instructor review remain open'), findsOneWidget);
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final bundled = await tester.runAsync(() => rootBundle.loadString('content/original_short_form_beginner_course.json'));
    expect(ShortFormCourse.decode(bundled!).units.length, 7);
    await tester.pumpAndSettle();
    expect(find.byType(ShortFormCoursePage), findsOneWidget);
    expect(spy.lastPushed, 'course/original-short-form-written');
    expect(card.entry.contentStatus, 'comingSoon');
    await tester.pageBack();
    // The style backdrop repeats; settle only the bounded route transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(StyleDetailView), findsOneWidget);
    expect(find.byType(ShortFormCoursePage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry, ten-second timeout, late timed-out result and stale replaced result', (tester) async {
    final failing = WrittenBundle(source)..fail = true;
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: failing)));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    failing.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(course.copy['title']!['en']!), findsOneWidget);
    final pending = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: pending)));
    await tester.pump();
    expect(find.text(course.copy['title']!['en']!), findsNothing);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('Retry'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    pending.pending!.complete(source);
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text(course.copy['title']!['en']!), findsNothing);
    pending.pending = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(course.copy['title']!['en']!), findsOneWidget);
    final stale = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: stale)));
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: WrittenBundle(source)..fail = true)));
    await tester.pumpAndSettle();
    stale.pending!.complete(source);
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text(course.copy['title']!['en']!), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back/unmount while pending safely ignore late completion', (tester) async {
    final pending = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ShortFormCoursePage(bundle: pending))), child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    pending.pending!.complete(source);
    await tester.pump();
    expect(find.byType(ShortFormCoursePage), findsNothing);
    final next = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: ShortFormCoursePage(bundle: next)));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    next.pending!.complete('invalid');
    await tester.pump();
    expect(find.byType(ShortFormCoursePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _RouteSpy extends NavigatorObserver {
  String? lastPushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) lastPushed = route.settings.name;
  }
}
