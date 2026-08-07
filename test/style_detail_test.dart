import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// The style page's honesty rules, measured against real content.
///
/// Asset loading happens in `setUpAll` — see `library_view_test.dart` for the
/// measurement behind that (a >=50 KB asset inside `testWidgets` deadlocks on a
/// real isolate the fake clock never advances).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryCatalog lib;
  setUpAll(() async => lib = await testLibrary());

  /// THE HARNESS IS MORE PERMISSIVE THAN A DEVICE — measured 2026-08-07.
  ///
  /// `DiskBundle` serves any file that exists in the repository. A real
  /// `rootBundle` serves only what `pubspec.yaml` DECLARES. Those differ today:
  /// `content/references/hh_bounce.json` is on disk and is not declared, so the
  /// harness reports its step as runnable and a device does not.
  ///
  /// The runtime derivation is correct either way — it probes whatever bundle
  /// it is given, so on a device the undeclared reference simply fails to load
  /// and the lesson is correctly reported as blocked. What the harness cannot
  /// do is REPRODUCE that, so these tests pass an explicit set instead of
  /// `lib.runnableSteps` wherever the distinction matters, and the pubspec gap
  /// itself is gated separately in `content_assets_test.dart`.
  ///
  /// This is the same class of limit `DiskBundle` already documents about
  /// itself: it exercises the loader and the derivation, not Flutter's asset
  /// plumbing.
  const Set<String> deviceRunnable = <String>{'ss_shine_footwork'};

  Future<void> show(WidgetTester tester, String styleId,
      {Set<String> runnable = deviceRunnable}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home:
          StyleDetailView(card: lib.cardFor(styleId)!, runnableSteps: runnable),
    ));
    await tester.pump();
  }

  /// Bounded manual scrolling. NOT `scrollUntilVisible`: every screen sits on
  /// `ChoreiaBackdrop`, whose blobs animate forever, and that helper settles
  /// the tree between drags — which never returns (DEFTER C-141).
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (int i = 0; i < 30 && target.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pump();
    }
  }

  group('attribution is content, and its absence is visible', () {
    testWidgets('a style WITH attribution shows it', (WidgetTester tester) async {
      await show(tester, 'vogue');
      expect(find.byKey(StyleDetailView.attributionKey), findsOneWidget);
      expect(find.byKey(StyleDetailView.attributionGapKey), findsNothing);
      expect(
          find.descendant(
            of: find.byKey(StyleDetailView.attributionKey),
            matching: find.textContaining('ballroom'),
          ),
          findsOneWidget,
          reason: "Vogue's lineage must reach the screen IN THE ATTRIBUTION "
              'BOX. Asserting it anywhere on the page stopped meaning that '
              "once the intro — which also says 'ballroom' — was written.");
    });

    testWidgets('every style in the real catalogue shows real attribution',
        (WidgetTester tester) async {
      for (final String id in <String>['salsa_shines', 'hula', 'breaking']) {
        await show(tester, id);
        expect(find.byKey(StyleDetailView.attributionKey), findsOneWidget,
            reason: '$id should render written attribution');
        expect(find.byKey(StyleDetailView.attributionGapKey), findsNothing);
      }
    });

    testWidgets('a style WITHOUT attribution shows a named gap, not a blank',
        (WidgetTester tester) async {
      // Synthetic, because content no longer has a style like this — and the
      // branch must stay tested anyway. A gap-rendering path that only ever ran
      // against content is a path that stops being exercised the moment content
      // is complete, and then silently rots until the next style is added
      // (family lesson 4: removing the case makes its absence vacuum-true).
      final StyleCard real = lib.cardFor('bachata_solo')!;
      final StyleCard blank = StyleCard(
        entry: LibraryEntry(
          id: real.entry.id,
          displayName: real.entry.displayName,
          contentStatus: real.entry.contentStatus,
        ),
        view: real.view,
      );

      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          theme: ChoreiaTheme.dark, home: StyleDetailView(card: blank)));
      await tester.pump();

      expect(find.byKey(StyleDetailView.attributionGapKey), findsOneWidget,
          reason: 'an absent box would read as a dance with no origin, which '
              'is never true — the debt is carried in public instead');
      expect(find.textContaining('We have not written this'), findsOneWidget);
    });

    testWidgets('clearance reasoning never stands in for credit',
        (WidgetTester tester) async {
      await show(tester, 'salsa_shines');
      // salsa_shines has BOTH an `originAttribution` and a
      // `copyright.boundary`. They must appear under separate headings: being
      // allowed to teach a dance is not the same as having said whose it is.
      expect(find.text(StyleStrings.attributionTitle), findsOneWidget);
      expect(find.text(StyleStrings.boundaryTitle), findsOneWidget);
    });
  });

  group('the three lesson classes are equals', () {
    testWidgets('every lesson of every kind gets a card',
        (WidgetTester tester) async {
      await show(tester, 'salsa_shines');
      final List<LessonInfo> lessons = lib.cardFor('salsa_shines')!.lessons;
      expect(lessons, isNotEmpty);

      final Set<LessonKind> kinds =
          lessons.map((LessonInfo l) => l.kind).toSet();
      expect(kinds, contains(LessonKind.scored));
      expect(kinds, contains(LessonKind.demoOnly),
          reason: 'this style is the one that exercises both classes');
    });

    testWidgets('demo-only cards carry the SAME padding as graded ones',
        (WidgetTester tester) async {
      await show(tester, 'salsa_shines');
      final StyleCard card = lib.cardFor('salsa_shines')!;

      final LessonInfo scored =
          card.lessons.firstWhere((LessonInfo l) => l.kind == LessonKind.scored);
      final LessonInfo demo = card.lessons
          .firstWhere((LessonInfo l) => l.kind == LessonKind.demoOnly);

      Future<EdgeInsetsGeometry> paddingOf(String id) async {
        final Finder f = find.byKey(StyleDetailView.lessonKey(id));
        await scrollTo(tester, f);
        expect(f, findsOneWidget, reason: 'lesson $id did not render');
        return tester.widget<GlassPanel>(f).padding;
      }

      // Order matters: the scored lesson is above the demo-only one, so
      // measuring it second would mean scrolling back up.
      final EdgeInsetsGeometry scoredPadding = await paddingOf(scored.id);
      final EdgeInsetsGeometry demoPadding = await paddingOf(demo.id);

      expect(demoPadding, scoredPadding,
          reason: 'THE rule this screen exists to hold: a demo-only lesson is '
              'a whole lesson that happens not to produce a number. Rendering '
              'it tighter or smaller would say "lesser" — the claim K10 '
              'refuses.');
    });

    testWidgets('an ungraded lesson always states why', (WidgetTester tester) async {
      for (final String styleId in <String>[
        'salsa_shines',
        'hip_hop_foundations'
      ]) {
        await show(tester, styleId);
        for (final LessonOffer o in lib.cardFor(styleId)!.offers(lib.runnableSteps)) {
          if (o.lesson.kind == LessonKind.scored) continue;
          expect(o.contentReason, isNotNull,
              reason: '${o.lesson.id} is ungraded with no stated reason — the '
                  'silence K10 forbids');
          expect(o.contentReason, isNotEmpty);
        }
      }
    });
  });

  group('no button promises a door that does not open', () {
    testWidgets('MEASURED: no lesson in the app can be started today',
        (WidgetTester tester) async {
      // This is the honest state of the whole app, asserted rather than
      // described. Of the 15 declared lessons, 4 name a step; of those, only
      // `ss_shine_footwork` has a reference the bundle serves — and it belongs
      // to the release-gated style. When any of that changes, this test fails
      // LOUDLY and gets its number updated, which is the point.
      int startable = 0;
      for (final StyleCard c in lib.cards) {
        startable +=
            c.offers(deviceRunnable).where((LessonOffer o) => o.canStart).length;
      }
      expect(startable, 0,
          reason: 'if this is now non-zero, a lesson became runnable — verify '
              'its reference is BUNDLED (pubspec assets), not merely on disk');

      await show(tester, 'salsa_shines');
      expect(find.widgetWithText(FilledButton, StyleStrings.start), findsNothing,
          reason: 'a Start button here would call LiveLessonPage, which loads '
              'its reference asset with no error handling — an unhandled '
              'exception behind a button');
    });

    testWidgets('a blocked lesson gets a sentence, never a greyed-out button',
        (WidgetTester tester) async {
      await show(tester, 'hip_hop_foundations');
      // A disabled "Start" says the door might open if you tried harder.
      expect(find.widgetWithText(FilledButton, StyleStrings.start), findsNothing);

      final Finder sentence = find
          .textContaining(StyleStrings.blocked(LessonBlock.referenceMissing));
      await scrollTo(tester, sentence);
      expect(sentence, findsWidgets,
          reason: 'the blocked reason names what is missing, in words');
    });

    testWidgets('a step with no servable reference is blocked AS a reference '
        'gap, not as something else', (WidgetTester tester) async {
      final StyleCard hh = lib.cardFor('hip_hop_foundations')!;
      final LessonOffer bounce = hh
          .offers(deviceRunnable)
          .firstWhere((LessonOffer o) => o.lesson.id == 'hh_l1_bounce');

      expect(bounce.lesson.stepId, 'hh_bounce');
      expect(bounce.block, LessonBlock.referenceMissing,
          reason: 'the lesson is demo-only and its style IS open, so nothing '
              'else could be blocking it — if this reports styleShut or '
              'noLessonBuilt, the reasons are being ordered wrongly and a '
              'dancer gets a true sentence answering the wrong question');
    });
  });

  group('a style with nothing built says so plainly', () {
    testWidgets('an unbuilt style shows no lesson list and no invented content',
        (WidgetTester tester) async {
      await show(tester, 'bachata_solo');
      await scrollTo(tester, find.byKey(StyleDetailView.noLessonsKey));
      expect(find.byKey(StyleDetailView.noLessonsKey), findsOneWidget);
      expect(find.byKey(StyleDetailView.lessonKey('any')), findsNothing);
      expect(find.byKey(StyleDetailView.honestyKey), findsNothing,
          reason: 'an honesty box with nothing measured to report would be '
              'chrome pretending to be substance');
    });

    testWidgets('a style with a safety note shows it before the lessons',
        (WidgetTester tester) async {
      await show(tester, 'heels');
      await scrollTo(tester, find.byKey(StyleDetailView.cautionKey));
      expect(find.byKey(StyleDetailView.cautionKey), findsOneWidget,
          reason: "content marks this style 'ayakkabı güvenliği ZORUNLU' and a "
              'mandatory safety note that only appears once lessons exist is a '
              'note that arrives too late');
    });
  });

  group('intro and glossary (C-151)', () {
    testWidgets('a style with an intro shows it above the attribution box',
        (WidgetTester tester) async {
      await show(tester, 'breaking');
      expect(find.byKey(StyleDetailView.descriptionKey), findsOneWidget);
    });

    testWidgets('HULA is deliberately unwritten and still explains itself',
        (WidgetTester tester) async {
      // Its on-hold reason forbids producing content from generic sources
      // without a halau/kumu partnership. A description and a step list are
      // exactly that, so both are absent BY RULE — and the page must still say
      // something rather than render as an empty style.
      final StyleCard hula = lib.cardFor('hula')!;
      expect(hula.entry.description, isNull,
          reason: 'writing "what you do in this dance" from books is the thing '
              'the on-hold reason forbids');
      expect(hula.entry.stepGlossary, isEmpty);

      await show(tester, 'hula');
      expect(find.byKey(StyleDetailView.descriptionKey), findsNothing);
      expect(find.byKey(StyleDetailView.glossaryKey), findsNothing);
      expect(find.byKey(StyleDetailView.attributionKey), findsOneWidget);
      expect(find.textContaining('hālau'), findsWidgets,
          reason: 'the page carries the reason instead of the content');
    });

    testWidgets('a glossary never reads as a curriculum',
        (WidgetTester tester) async {
      await show(tester, 'vogue');
      final Finder glossary = find.byKey(StyleDetailView.glossaryKey);
      await scrollTo(tester, glossary);
      expect(glossary, findsOneWidget);

      // The note is the load-bearing part: vogue is NOT BUILT, so a list of
      // named steps under it is the easiest thing on this page to misread.
      expect(find.text(StyleStrings.glossaryNote), findsOneWidget);
      await scrollTo(tester, find.byKey(StyleDetailView.noLessonsKey));
      expect(find.byKey(StyleDetailView.noLessonsKey), findsOneWidget,
          reason: 'the same page must say plainly that nothing is built — a '
              'glossary without that is a curriculum');
    });

    testWidgets('a style with no glossary renders no glossary section',
        (WidgetTester tester) async {
      // The positive twin. 16 of 34 have none, deliberately; a section that
      // rendered an empty heading would turn a considered omission into a
      // broken-looking page.
      expect(lib.cardFor('kpop_point')!.entry.stepGlossary, isEmpty);
      await show(tester, 'kpop_point');
      expect(find.byKey(StyleDetailView.glossaryKey), findsNothing);
    });

    test('MEASURED: intro on 33/34, glossary on 18/34', () {
      final int described =
          lib.cards.where((StyleCard c) => c.entry.description != null).length;
      final int glossed = lib.cards
          .where((StyleCard c) => c.entry.stepGlossary.isNotEmpty)
          .length;

      expect(described, 33,
          reason: 'every style except hula, which is unwritten by rule');
      expect(glossed, 18,
          reason: 'the 16 omissions are deliberate — a style whose vocabulary '
              'IS the individual routine has no shared names to gloss, and '
              'guessing plausible-sounding ones reads as knowledge and is not. '
              'If this number moves, say which style gained a glossary and on '
              'what basis.');
    });
  });
}
