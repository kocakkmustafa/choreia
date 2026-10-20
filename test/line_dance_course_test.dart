import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:choreia/app/theme.dart';
import 'package:choreia/app/course/line_dance_course.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/line_dance_direction_diagram.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'hip_hop_course_page_test.dart' show WrittenBundle;
import 'support/test_catalog.dart';

Finder get _verticalCourseScroll => find.byWidgetPredicate((widget) =>
    widget is Scrollable && widget.axisDirection == AxisDirection.down);

void main() {
  final source =
      File('content/line_dance_beginner_course.json').readAsStringSync();
  test('bilingual endpoint, diagrams and same-condition task decode', () {
    final course = LineDanceCourse.decode(source);
    expect(course.units.length, 9);
    for (final u in course.units) {
      for (final pair in u.copy.values) {
        expect(pair['en'], isNotEmpty);
        expect(pair['tr'], isNotEmpty);
      }
    }
    expect(course.units[6].copy['instruction']!['en'], contains('24 beats'));
    final preparation = course.units[6].copy;
    expect(preparation['practice']!['en'], contains('do blocks A/B/C once'));
    expect(preparation['practice']!['tr'],
        contains('A/B/C bloklarını bir kez yap'));
    expect(preparation['mistakes']!['tr'], contains('ilk ve ikinci denemeyi'));
    expect(preparation['check']!['en'],
        contains('error block/beat location and type'));

    expect(
        course.units.last.copy['practice']!['tr'], contains('taze ilk deneme'));
  });
  test(
      'missing translation, malformed prerequisite and all gate promotions fail closed',
      () {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    ((raw['units'] as List).first['diagram'] as Map).remove('tr');
    expect(
        () => LineDanceCourse.decode(jsonEncode(raw)), throwsFormatException);
    for (final gate in LineDanceCourse.gates) {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      (raw['acceptance'] as Map)[gate] = true;
      expect(
          () => LineDanceCourse.decode(jsonEncode(raw)), throwsFormatException,
          reason: gate);
    }
    final bad = jsonDecode(source) as Map<String, dynamic>;
    (bad['units'] as List)[1]['prerequisiteIds'] = ['ld_07'];
    expect(
        () => LineDanceCourse.decode(jsonEncode(bad)), throwsFormatException);
  });
  for (final lang in ['en', 'tr']) {
    testWidgets('$lang final task and diagram reachable at 200 percent text',
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
          home: LineDanceCoursePage(bundle: WrittenBundle(source))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byType(LineDanceDirectionDiagram), 250,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      expect(find.byType(LineDanceDirectionDiagram), findsOneWidget);
      for (var n = 1; n <= 9; n++) {
        final unit = find.byKey(ValueKey('ld_0$n'));
        await tester.scrollUntilVisible(unit, 250,
            maxScrolls: 100, scrollable: _verticalCourseScroll);
        expect(unit, findsOneWidget);
      }
      final last = find.byKey(const ValueKey('ld_09'));
      await Scrollable.ensureVisible(tester.element(last), alignment: 0.2);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      final diagram = find.text(lang == 'tr'
          ? 'Özgün sayı ve ayak haritası'
          : 'Original count and foot map');
      await tester.scrollUntilVisible(diagram, 250,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      expect(diagram, findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'actual line style opens real bundled course without promoting physical catalog',
      (tester) async {
    final library = await tester.runAsync(testLibrary);
    final card = library!.cardFor('line_dance')!;
    expect(card.entry.contentStatus, 'comingSoon');
    await tester.pumpWidget(MaterialApp(home: StyleDetailView(card: card)));
    final link = find.byKey(const Key('style.lineDanceWrittenCourse'));
    await tester.scrollUntilVisible(link, 200,
        scrollable: _verticalCourseScroll);
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final text = await tester.runAsync(
        () => rootBundle.loadString('content/line_dance_beginner_course.json'));
    expect(LineDanceCourse.decode(text!).units.length, 9);
    await tester.pumpAndSettle();
    expect(find.text('Line Dance: beginner written course'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('error retry and bundle replacement reject stale content',
      (tester) async {
    final bundle = WrittenBundle(source)..fail = true;
    await tester
        .pumpWidget(MaterialApp(home: LineDanceCoursePage(bundle: bundle)));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    bundle.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Line Dance: beginner written course'), findsOneWidget);
    final pending = WrittenBundle(source)..pending = Completer<String>();
    await tester
        .pumpWidget(MaterialApp(home: LineDanceCoursePage(bundle: pending)));
    await tester.pump();
    expect(find.text('Line Dance: beginner written course'), findsNothing);
    final current = WrittenBundle(source);
    await tester
        .pumpWidget(MaterialApp(home: LineDanceCoursePage(bundle: current)));
    await tester.pumpAndSettle();
    pending.pending!.complete('invalid');
    await tester.pump();
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('bounded timeout rejects late completion', (tester) async {
    final bundle = WrittenBundle(source)..pending = Completer<String>();
    await tester
        .pumpWidget(MaterialApp(home: LineDanceCoursePage(bundle: bundle)));
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    bundle.pending!.complete(source);
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Back and unmount while loading do not resurrect the reader',
      (tester) async {
    final bundle = WrittenBundle(source)..pending = Completer<String>();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                LineDanceCoursePage(bundle: bundle))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(LineDanceCoursePage), findsNothing);
    bundle.pending!.complete(source);
    await tester.pump();
    expect(find.byType(LineDanceCoursePage), findsNothing);
    expect(tester.takeException(), isNull);
    final next = WrittenBundle(source)..pending = Completer<String>();
    await tester
        .pumpWidget(MaterialApp(home: LineDanceCoursePage(bundle: next)));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    next.pending!.complete('invalid');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['en', 'tr']) {
    testWidgets('$lang actual themed lesson-body and wall-map render',
        (tester) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(lang);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const shot = ValueKey('render.reader');
      await tester.pumpWidget(MaterialApp(
          locale: Locale(lang),
          supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ChoreiaTheme.dark,
          home: RepaintBoundary(
              key: shot,
              child: LineDanceCoursePage(bundle: WrittenBundle(source)))));
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(shot));
        final bytes = await tester.runAsync(() async {
          final picture = await boundary.toImage(pixelRatio: 1);
          final data = await picture.toByteData(format: ui.ImageByteFormat.png);
          picture.dispose();
          return data!.buffer.asUint8List();
        });
        await tester.runAsync(() async {
          final file = File('../renders/$lang-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!);
        });
      }

      final walls = find.byType(LineDanceWallMaps);
      await tester.scrollUntilVisible(walls, 250,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      await tester.pumpAndSettle();
      await capture('wall-map-first');
      final lastWall = find.text(lang == 'tr'
          ? 'Bakış 3: kendi uzuv yönlerin'
          : 'Facing 3: your own-limb directions');
      await tester.scrollUntilVisible(lastWall, 250,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      await tester.pumpAndSettle();
      await capture('wall-map-last');
      final row = find.byKey(const ValueKey('ld_05'));
      await tester.scrollUntilVisible(row, 250,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      await Scrollable.ensureVisible(tester.element(row), alignment: 0.1);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      final question =
          find.text(lang == 'tr' ? 'Yeni satırı çöz' : 'Solve a new row');
      await tester.scrollUntilVisible(question, 220,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      await Scrollable.ensureVisible(tester.element(question), alignment: 0.1);
      await tester.pumpAndSettle();
      final answer = find.byKey(const ValueKey('line.answer'));
      expect(answer, findsOneWidget);
      final answerText =
          LineDanceCourse.decode(source).units[4].copy['answer']![lang]!;
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(find.text(answerText, skipOffstage: false), findsNothing);
        expect(find.bySemanticsLabel(answerText), findsNothing);
        await capture('new-row');
        await tester.scrollUntilVisible(answer, 180,
            maxScrolls: 100, scrollable: _verticalCourseScroll);
        await tester.tap(answer);
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(answer), alignment: 0.1);
        await tester.pumpAndSettle();
        expect(find.text(answerText, skipOffstage: false), findsOneWidget);
        expect(find.bySemanticsLabel(answerText), findsOneWidget);
      } finally {
        semantics.dispose();
      }
      await capture('answer');
      final turn = find.byKey(const ValueKey('ld_08'));
      await tester.scrollUntilVisible(turn, 250,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      await Scrollable.ensureVisible(tester.element(turn), alignment: 0.1);
      await tester.pumpAndSettle();
      await tester.tap(turn);
      await tester.pumpAndSettle();
      final ledger = find.byType(LineDanceWeightLedger);
      await tester.scrollUntilVisible(ledger, 200,
          maxScrolls: 100, scrollable: _verticalCourseScroll);
      await Scrollable.ensureVisible(tester.element(ledger), alignment: 0.1);
      await tester.pumpAndSettle();
      await capture('turn-weight-ledger');
      expect(tester.takeException(), isNull);
    });
  }
}
