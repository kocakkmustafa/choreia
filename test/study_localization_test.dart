import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/study_review.dart';
import 'package:choreia/app/study_review_content.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

void main() {
  testWidgets('Arabic recall keeps the written draft and revealed reference',
      (tester) async {
    final locales = ChoreiaLocaleController.memory(const Locale('en'));
    addTearDown(locales.dispose);
    final area = studyAreas.first;
    final lesson = area.lessons.first;
    final arabic = (jsonDecode(File('content/l10n/ui.ar.json').readAsStringSync())
        as Map).cast<String, String>();
    await tester.pumpWidget(ChoreiaApp(localeController: locales,
      localeBundle: DiskBundle(), shellBuilder: (_, __) =>
          RecallLessonPage(area: area, lesson: lesson)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('study-answer')), 'my draft');
    await tester.ensureVisible(find.byKey(const Key('study-reference-toggle')));
    await tester.tap(find.byKey(const Key('study-reference-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('study-reference')), findsOneWidget);

    await locales.select(const Locale('ar'));
    await tester.pumpAndSettle();
    final answer = tester.widget<TextField>(find.byKey(const Key('study-answer')));
    expect(answer.controller!.text, 'my draft');
    expect(find.text(arabic[lesson.title.en]!), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('study-reference'))).data,
        arabic[lesson.answer.en]);
    expect(Directionality.of(tester.element(find.byKey(const Key('study-answer')))),
        TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
