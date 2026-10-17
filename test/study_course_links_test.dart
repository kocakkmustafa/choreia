import 'package:choreia/app/study_review.dart';
import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/course/support_hold_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapVisible(WidgetTester t, String key) async {
  final target = find.byKey(Key(key));
  if (target.hitTestable().evaluate().isEmpty) {
    await t.scrollUntilVisible(target, 300,
        maxScrolls: 100, scrollable: find.byType(Scrollable).first);
  }
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await t.runAsync(() async {
    await t.tap(target.hitTestable());
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    final pending = find.byWidgetPredicate((widget) => widget is FutureBuilder<dynamic>);
    if (pending.evaluate().isNotEmpty) {
      // Start and await real bundle decoding in the host async zone.
      await t.widget<FutureBuilder<dynamic>>(pending.first).future;
    }
  });
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

Future<void> mount(WidgetTester t, Widget home, String language) async {
  t.view.physicalSize = const Size(320, 900);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.localeTestValue = Locale(language);
  addTearDown(t.platformDispatcher.clearLocaleTestValue);
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!),
      home: home));
  await t.pumpAndSettle();
}

void main() {
  for (final language in ['en', 'tr']) {
    testWidgets(
        '$language recall opens existing written courses and symbolic diagram at 320px/2x',
        (t) async {
      await mount(t, const Scaffold(body: StudyReviewEntry()), language);
      await tapVisible(t, 'study-review-entry');
      for (final entry in <String, Type>{
        'hiphop': HipHopCoursePage,
        'salsa': SupportHoldDemo,
        'line': LineDanceCoursePage,
        'latin': LatinFusionCoursePage,
        'shortform': ShortFormCoursePage
      }.entries) {
        await tapVisible(t, 'study-related-${entry.key}');
        expect(find.byType(entry.value), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        if (entry.key == 'salsa') {
          await tapVisible(t, 'supportHold.count.4');
          expect(
              t.widget<Text>(find.byKey(const Key('supportHold.current'))).data,
              contains(language == 'tr'
                  ? 'aynı destek / durak'
                  : 'same support / hold'));
        } else {
          expect(find.byType(Text), findsWidgets);
          expect(
              find.textContaining(language == 'tr' ? 'Tekrar dene' : 'Retry'),
              findsNothing,
              reason: 'Loaded course ${entry.key}');
        }
        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();
        expect(find.byType(StudyReviewPage), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    });
  }
}
