import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/notation_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readMap(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<String> _diagrams(String language) {
  final course = _readMap('content/line_dance_beginner_course.json');
  final index = _readMap('content/l10n/course.index.json');
  final arabic = _readMap('content/l10n/course.ar.json');
  return [
    for (final unit in course['units'] as List<dynamic>)
      if (language == 'ar')
        arabic[index[(unit as Map<String, dynamic>)['diagram']['en']]] as String
      else
        (unit as Map<String, dynamic>)['diagram'][language] as String,
  ];
}

Widget _screen(
  String text, {
  String language = 'en',
  TextDirection? direction,
  double scale = 1,
}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('tr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Directionality(
            textDirection: direction ??
                (language == 'ar' ? TextDirection.rtl : TextDirection.ltr),
            child: SizedBox(
              width: 288,
              child: NotationText(
                text,
                key: const ValueKey('notation-under-test'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );

Finder _line(int index) => find.byKey(ValueKey('notation-line-$index'));

List<Text> _texts(WidgetTester tester, int line) => tester
    .widgetList<Text>(
        find.descendant(of: _line(line), matching: find.byType(Text)))
    .toList();

List<Rect> _rects(WidgetTester tester, int line) => [
      for (final text in _texts(tester, line))
        tester.getRect(find.byWidget(text)),
    ];

void _expectPhysicalOrder(WidgetTester tester, int line) {
  final rects = _rects(tester, line);
  for (var index = 1; index < rects.length; index++) {
    expect(
        rects[index].left, greaterThanOrEqualTo(rects[index - 1].right - 0.01),
        reason: 'line $line, run $index must follow the previous physical box');
  }
}

Rect _runRect(WidgetTester tester, int line, String data) {
  final texts = _texts(tester, line);
  final index = texts.indexWhere((text) => text.data == data);
  expect(index, greaterThanOrEqualTo(0), reason: 'line $line has $data');
  return tester.getRect(find.byWidget(texts[index]));
}

void main() {
  for (final sample in <String>[
    'R क्षण → L भार',
    'R क्\u200Dषि → L बाएँ',
    'R 한국어 → L 왼발',
    'R 左脚 → L 支持'
  ]) {
    testWidgets('connected script words remain complete visual runs: $sample',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: NotationText(sample))));
        final visual = tester
            .widgetList<Text>(find.descendant(
                of: find.byType(NotationText), matching: find.byType(Text)))
            .map((widget) => widget.data!)
            .toList();
        expect(visual.join().replaceAll('\u00A0', ' '), sample);
        for (final word in sample
            .split(' ')
            .where((word) => word != 'R' && word != 'L' && word != '→')) {
          expect(visual, contains(word),
              reason:
                  'letters, matras, virama and joiners of one word must stay in one Text');
        }
        expect(find.bySemanticsLabel(sample), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  final english = _diagrams('en');
  final arabic = _diagrams('ar');

  testWidgets('EN to AR keeps dancer left and right in physical source order',
      (tester) async {
    await tester.pumpWidget(_screen(english.first));
    await tester.pumpAndSettle();
    expect(_runRect(tester, 1, 'LEFT').left,
        lessThan(_runRect(tester, 1, '←').left));
    expect(_runRect(tester, 1, '←').left,
        lessThan(_runRect(tester, 1, 'YOU').left));
    expect(_runRect(tester, 1, 'YOU').left,
        lessThan(_runRect(tester, 1, '→').left));
    expect(_runRect(tester, 1, '→').left,
        lessThan(_runRect(tester, 1, 'RIGHT').left));
    final sourceStart = tester.getTopLeft(_line(1));

    await tester.pumpWidget(_screen(arabic.first, language: 'ar'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_line(1)).dx, sourceStart.dx);
    expect(_runRect(tester, 1, 'يسار').left,
        lessThan(_runRect(tester, 1, '←').left));
    expect(_runRect(tester, 1, '←').left,
        lessThan(_runRect(tester, 1, 'أنت').left));
    expect(_runRect(tester, 1, 'أنت').left,
        lessThan(_runRect(tester, 1, '→').left));
    expect(_runRect(tester, 1, '→').left,
        lessThan(_runRect(tester, 1, 'يمين').left));
    for (final text in _texts(tester, 1)) {
      expect(
          text.textDirection,
          ['يسار', 'أنت', 'يمين'].contains(text.data)
              ? TextDirection.rtl
              : TextDirection.ltr);
    }
    expect(tester.takeException(), isNull);
  });

  // Every shipped EN/TR diagram and its actual AR overlay is exercised. For
  // unchanged content, changing interface direction cannot move any run.
  for (final language in ['en', 'tr', 'ar']) {
    final diagrams = _diagrams(language);
    for (var unit = 0; unit < diagrams.length; unit++) {
      final text = diagrams[unit];
      testWidgets('$language unit ${unit + 1}: RTL does not mirror any token',
          (tester) async {
        await tester.pumpWidget(
            _screen(text, language: language, direction: TextDirection.ltr));
        await tester.pumpAndSettle();
        final before = [
          for (var line = 0; line < text.split('\n').length; line++)
            _rects(tester, line),
        ];
        await tester.pumpWidget(
            _screen(text, language: language, direction: TextDirection.rtl));
        await tester.pumpAndSettle();
        for (var line = 0; line < before.length; line++) {
          expect(_rects(tester, line), before[line]);
          _expectPhysicalOrder(tester, line);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Arabic phrases stay connected inside individual RTL labels',
      (tester) async {
    await tester.pumpWidget(_screen(arabic[4], language: 'ar'));
    await tester.pumpAndSettle();
    final phrase = _texts(tester, 0)
        .singleWhere((text) => text.data == 'القدم\u00A0المتحركة');
    expect(phrase.textDirection, TextDirection.rtl);
    expect(phrase.softWrap, isFalse);
    final separators = _texts(tester, 0).where((text) => text.data == '|');
    expect(separators, hasLength(4));
    expect(separators.every((text) => text.textDirection == TextDirection.ltr),
        isTrue);
    _expectPhysicalOrder(tester, 0);
  });

  testWidgets('Arabic clock row keeps 9 left of 3 and turn sequence unchanged',
      (tester) async {
    await tester.pumpWidget(_screen(arabic[7], language: 'ar'));
    await tester.pumpAndSettle();
    expect(
        _runRect(tester, 0, '9').left, lessThan(_runRect(tester, 0, '3').left));
    expect(
        _runRect(tester, 0, '←').left, lessThan(_runRect(tester, 0, '→').left));
    final numbers = _texts(tester, 2)
        .where((text) => RegExp(r'^\d+$').hasMatch(text.data!))
        .toList();
    expect(numbers.map((text) => text.data), ['12', '9', '6', '3', '12']);
    for (var index = 1; index < numbers.length; index++) {
      expect(tester.getRect(find.byWidget(numbers[index])).left,
          greaterThan(tester.getRect(find.byWidget(numbers[index - 1])).right));
    }
    _expectPhysicalOrder(tester, 2);
  });

  for (final language in ['en', 'tr', 'ar']) {
    testWidgets('$language: narrow 200% notation scrolls with full text size',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        final text = _diagrams(language)[7];
        await tester.pumpWidget(_screen(text, language: language));
        await tester.pumpAndSettle();
        final normalHeight = _rects(tester, 0).first.height;
        await tester.pumpWidget(_screen(text, language: language, scale: 2));
        await tester.pumpAndSettle();
        expect(_rects(tester, 0).first.height, closeTo(normalHeight * 2, 1));
        expect(find.bySemanticsLabel(text), findsOneWidget);
        final scrollView = tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
        final controller = scrollView.controller!;
        expect(controller.position.maxScrollExtent, greaterThan(0));
        expect(controller.offset, 0);
        // The Scrollable widget's outer semantics boundary need not own the
        // gesture action. Find the actual accessible horizontal-scroll node.
        final accessibleScroll =
            find.semantics.scrollable(axis: Axis.horizontal);
        expect(accessibleScroll.evaluate(), hasLength(1));
        final scrollNode = accessibleScroll.evaluate().single;
        expect(
            scrollNode.getSemanticsData().hasAction(SemanticsAction.scrollLeft),
            isTrue);
        tester.semantics.scrollLeft(scrollable: accessibleScroll);
        await tester.pumpAndSettle();
        expect(controller.offset, greaterThan(0));
        controller.jumpTo(0);
        await tester.pump();
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(-180, 0));
        await tester.pumpAndSettle();
        expect(controller.offset, greaterThan(0));
        for (var line = 0; line < text.split('\n').length; line++) {
          _expectPhysicalOrder(tester, line);
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('blank lines and original semantic spaces are retained',
      (tester) async {
    const text = 'L   ←\n\nالقدم المتحركة\tR →';
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_screen(text, language: 'ar'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(text), findsOneWidget);
      expect(find.byType(Row), findsNWidgets(3));
      expect(tester.getSize(_line(1)).height, greaterThan(0));
      expect(_texts(tester, 0).map((text) => text.data),
          ['L', '\u00A0\u00A0\u00A0', '←']);
      expect(_texts(tester, 2).map((text) => text.data), [
        'القدم\u00A0المتحركة',
        '\u00A0\u00A0\u00A0\u00A0',
        'R',
        '\u00A0',
        '→',
      ]);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
