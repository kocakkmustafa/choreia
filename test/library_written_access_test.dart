import 'dart:io';
import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, LogicalKeyboardKey;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

final class _ReadbackBundle extends DiskBundle {
  final Set<String> requested = <String>{};

  @override
  Future<ByteData> load(String key) {
    requested.add(key);
    return super.load(key);
  }
}

final class _RouteReadback extends NavigatorObserver {
  String? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route.settings.name;
  }
}

/// Repository content + widget navigation; not physical camera, native asset
/// packaging, VoiceOver/TalkBack or movement-skill acceptance.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const written = <String>[
    'salsa_shines',
    'hip_hop_foundations',
    'line_dance',
    'latin_fusion_fitness',
    'tiktok_format',
  ];
  const courseTypes = <String, Type>{
    'salsa_shines': SalsaCoursePage,
    'hip_hop_foundations': HipHopCoursePage,
    'line_dance': LineDanceCoursePage,
    'latin_fusion_fitness': LatinFusionCoursePage,
    'tiktok_format': ShortFormCoursePage,
  };
  const assets = <String, String>{
    'salsa_shines': 'content/salsa_on1_course.json',
    'hip_hop_foundations': 'content/hip_hop_foundations_skill_course.json',
    'line_dance': 'content/line_dance_beginner_course.json',
    'latin_fusion_fitness': 'content/latin_fusion_beginner_course.json',
    'tiktok_format': 'content/original_short_form_beginner_course.json',
  };
  const routeNames = <String, String>{
    'salsa_shines': 'course/salsa-on1',
    'hip_hop_foundations': 'course/hip-hop-written',
    'line_dance': 'course/line-dance-written',
    'latin_fusion_fitness': 'course/latin-fusion-written',
    'tiktok_format': 'course/original-short-form-written',
  };

  late LibraryCatalog library;
  setUpAll(() async => library = await testLibrary());

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    String language = 'en',
    double scale = 1,
    NavigatorObserver? observer,
  }) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ChoreiaTheme.dark,
      navigatorObservers: <NavigatorObserver>[if (observer != null) observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: home is LibraryView ? Scaffold(body: home) : home,
    ));
    await tester.pump();
  }

  Future<void> reach(WidgetTester tester, Finder target) async {
    for (var n = 0; n < 60 && target.evaluate().isEmpty; n++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pump();
    }
    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.pump();
  }

  test('written access copy is independent of camera reference readiness', () {
    expect(
        library.cards
            .where((c) => WrittenCourseLink.supports(c.entry.id))
            .map((c) => c.entry.id),
        unorderedEquals(written));
    for (final id in written) {
      final card = library.cardFor(id)!;
      for (final camera in <bool>[false, true]) {
        final en = LibraryStrings.lessonLine(card,
            startable: 0, cameraSessionsAvailable: camera);
        final tr = LibraryStrings.lessonLineTr(card,
            startable: 0, cameraSessionsAvailable: camera);
        expect(en, contains('WRITTEN COURSE AVAILABLE'), reason: id);
        expect(tr, contains('YAZILI KURS AÇIK'), reason: id);
        expect(en, isNot(contains('NO LESSONS')), reason: id);
        expect(tr, isNot(contains('DERS YOK')), reason: id);
        if (!camera) {
          expect(en, contains('CAMERA OFF'));
          expect(tr, contains('KAMERA KAPALI'));
        }
      }
    }
    expect(WrittenCourseLink.supports('bachata_solo'), isFalse);
  });

  for (final language in <String>['en', 'tr']) {
    testWidgets('$language five written cards survive 200% text and camera off',
        (tester) async {
      await show(tester, LibraryView(library: library),
          language: language, scale: 2);
      for (final id in written) {
        final tile = find.byKey(LibraryView.tileKey(id));
        await reach(tester, tile);
        final copy = tester
            .widgetList<Text>(find.descendant(
              of: tile,
              matching: find.byType(Text),
            ))
            .map((text) => text.data ?? '')
            .join(' ');
        expect(copy,
            contains(language == 'tr' ? 'YAZILI KURS' : 'WRITTEN COURSE'));
        expect(
            copy, isNot(contains(language == 'tr' ? 'DERS YOK' : 'NOT BUILT')));
        final link = find.descendant(
            of: tile, matching: find.byKey(WrittenCourseLink.startKey(id)));
        expect(link, findsOneWidget);
        expect(tester.getSize(link).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  }

  testWidgets('all five catalogue CTAs load the right written course and Back',
      (tester) async {
    final directory =
        Directory.systemTemp.createTempSync('choreia-written-ui-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final bundle = _ReadbackBundle();
    var cameraStarts = 0;
    final env = LiveEnvironment(
      bundle: bundle,
      historyDirectoryOverride: directory,
      storeOwners: AppStoreOwnerRegistry(),
      source: () {
        cameraStarts++;
        throw StateError('A written course must not start the camera.');
      },
    );
    final observer = _RouteReadback();
    await show(tester, LibraryView(library: library, env: env),
        observer: observer);

    for (final id in written) {
      final link = find.byKey(WrittenCourseLink.startKey(id));
      await reach(tester, link);
      await tester.tap(link);
      await tester.pump();
      final page = find.byType(courseTypes[id]!);
      final lessons =
          find.descendant(of: page, matching: find.byType(ListView));
      for (var n = 0; n < 80 && lessons.evaluate().isEmpty; n++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(page, findsOneWidget, reason: id);
      expect(lessons, findsWidgets, reason: '$id did not render its course');
      expect(bundle.requested, contains(assets[id]), reason: id);
      expect(observer.lastPushed, routeNames[id], reason: id);
      expect(find.byType(LiveLessonPage), findsNothing);
      expect(cameraStarts, 0);
      if (id == 'hip_hop_foundations') {
        expect(tester.widget<HipHopCoursePage>(page).skillCourse, isTrue);
      }
      Navigator.of(tester.element(page)).pop();
      await tester.pump();
      await tester.pump(ChoreiaMotion.screenTransition);
      expect(find.byType(LibraryView), findsOneWidget);
      expect(page, findsNothing);
      expect(tester.takeException(), isNull, reason: id);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'written detail never claims that an empty camera list is no course',
      (tester) async {
    for (final id in <String>[
      'line_dance',
      'latin_fusion_fitness',
      'tiktok_format'
    ]) {
      await show(tester, StyleDetailView(card: library.cardFor(id)!));
      await reach(tester, find.byKey(StyleDetailView.writtenCourseKey));
      expect(find.byKey(WrittenCourseLink.startKey(id)), findsOneWidget);
      await reach(tester, find.byKey(StyleDetailView.noCameraLessonsKey));
      expect(find.byKey(StyleDetailView.noLessonsKey), findsNothing);
      expect(find.text('NOT BUILT'), findsNothing);
      expect(find.textContaining('The written course is available above'),
          findsOneWidget);
      expect(
          find.widgetWithText(FilledButton, StyleStrings.start), findsNothing);
      expect(tester.takeException(), isNull, reason: id);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
      'review target, filter state and card navigation support keyboard',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await show(tester, Scaffold(body: LibraryView(library: library)));
      final review = find.byKey(const Key('study-review-entry'));
      expect(tester.getSize(review), const Size(48, 48));
      final reviewData = tester.getSemantics(review).getSemanticsData();
      expect(reviewData.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(reviewData.hasAction(SemanticsAction.tap), isTrue);

      final references = find.widgetWithText(ChoiceChip,
          '${LibraryStrings.filterOpenNow} · ${LibraryTally.from(library.cards).openable}');
      await reach(tester, references);
      expect(tester.getSize(references).height, greaterThanOrEqualTo(48));
      await tester.tap(references);
      await tester.pump();
      expect(tester.widget<ChoiceChip>(references).selected, isTrue);
      expect(
          tester
              .getSemantics(references)
              .getSemanticsData()
              .hasFlag(SemanticsFlag.isSelected),
          isTrue);

      final tile = find.byKey(LibraryView.tileKey('hip_hop_foundations'));
      await reach(tester, tile);
      final focus = Focus.of(tester.element(tile));
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(ChoreiaMotion.screenTransition);
      expect(find.byType(StyleDetailView), findsOneWidget);
      expect(
          tester
              .widget<StyleDetailView>(find.byType(StyleDetailView))
              .card
              .entry
              .id,
          'hip_hop_foundations');
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('stale owner and recovery callbacks cannot open a written route',
      (tester) async {
    final epoch = ValueNotifier(1);
    final recovering = ValueNotifier(false);
    addTearDown(epoch.dispose);
    addTearDown(recovering.dispose);
    final observer = _RouteReadback();
    await show(
        tester,
        Scaffold(
            body: WrittenCourseLink(
          styleId: 'line_dance',
          env: LiveEnvironment(ownerEpoch: epoch, passwordRecovery: recovering),
        )),
        observer: observer);
    final button = tester.widget<FilledButton>(
        find.byKey(WrittenCourseLink.startKey('line_dance')));
    final initialRoute = observer.lastPushed;
    epoch.value = 2;
    button.onPressed!();
    await tester.pump();
    expect(observer.lastPushed, initialRoute);
    await tester.pumpWidget(const SizedBox.shrink());
    await show(
        tester,
        Scaffold(
            body: WrittenCourseLink(
          styleId: 'line_dance',
          env: LiveEnvironment(ownerEpoch: epoch, passwordRecovery: recovering),
        )),
        observer: observer);
    final freshButton = tester.widget<FilledButton>(
        find.byKey(WrittenCourseLink.startKey('line_dance')));
    recovering.value = true;
    freshButton.onPressed!();
    await tester.pump();
    expect(observer.lastPushed, initialRoute);
    expect(find.byType(LineDanceCoursePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
