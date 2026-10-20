import 'dart:async';
import 'dart:io';

import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

class WrittenBundle extends CachingAssetBundle {
  WrittenBundle(this.source);
  final String source;
  bool fail = false;
  Completer<String>? pending;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (fail) throw const FormatException('Unavailable candidate');
    if (pending != null) return pending!.future;
    return source;
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  final source =
      File('content/hip_hop_foundations_course.json').readAsStringSync();

  for (final lang in ['en', 'tr']) {
    testWidgets(
        '$lang reader exposes review and complete capstone at large text',
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
          child: child!,
        ),
        home: HipHopCoursePage(bundle: WrittenBundle(source)),
      ));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(
              lang == 'tr' ? 'Hazırlanma, sayım' : 'A six-stage introduction'),
          findsOneWidget);
      for (var n = 1; n <= 6; n++) {
        final key = find.byKey(ValueKey('hhf_0$n'));
        await tester.scrollUntilVisible(key, 250);
        expect(key, findsOneWidget);
      }
      final finalStage = find.byKey(const ValueKey('hhf_06'));
      await Scrollable.ensureVisible(tester.element(finalStage),
          alignment: 0.2);
      await tester.pumpAndSettle();
      await tester.tap(finalStage);
      await tester.pumpAndSettle();
      final check = find.text(
          lang == 'tr' ? 'Öz kontrol ve tekrar' : 'Self-check and revisit');
      await tester.scrollUntilVisible(check, 250);
      expect(check, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byType(Checkbox), findsNothing);
    });
  }

  testWidgets('load failure stays visible and retry loads the written path',
      (tester) async {
    final bundle = WrittenBundle(source)..fail = true;
    await tester
        .pumpWidget(MaterialApp(home: HipHopCoursePage(bundle: bundle)));
    await tester.pumpAndSettle();
    expect(find.textContaining('No progress was recorded'), findsOneWidget);
    bundle.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A six-stage introduction'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeout is handled without treating the path as completed',
      (tester) async {
    final bundle = WrittenBundle(source)..pending = Completer<String>();
    await tester
        .pumpWidget(MaterialApp(home: HipHopCoursePage(bundle: bundle)));
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.textContaining('No progress was recorded'), findsOneWidget);
    bundle.pending!.complete(source);
    await tester.pump();
    expect(find.textContaining('No progress was recorded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Hip-Hop detail links to the written reader through existing route',
      (tester) async {
    final library = await tester.runAsync(testLibrary);
    await tester.pumpWidget(MaterialApp(
        home: StyleDetailView(card: library!.cardFor('hip_hop_foundations')!)));
    final link = find.byKey(const Key('style.hipHopWrittenPath'));
    await tester.scrollUntilVisible(link, 200);
    await tester.tap(link);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(HipHopCoursePage), findsOneWidget);
    expect(tester.takeException(), isNull);
    final bundled = await tester.runAsync(
        () => rootBundle.loadString('content/hip_hop_foundations_course.json'));
    expect(bundled, contains('written introduction'));
    await tester.pumpAndSettle();
    expect(
        find.text('Hip-Hop Foundations: written introduction'), findsOneWidget);
    expect(find.textContaining('A six-stage introduction'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
