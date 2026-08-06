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
      expect(find.textContaining('ballroom'), findsOneWidget,
          reason: "Vogue's lineage is the one piece of attribution content "
              'currently written, and it must reach the screen');
    });

    testWidgets('a style WITHOUT attribution shows a named gap, not a blank',
        (WidgetTester tester) async {
      await show(tester, 'salsa_shines');
      expect(find.byKey(StyleDetailView.attributionGapKey), findsOneWidget,
          reason: 'an absent box would read as a dance with no origin, which '
              'is never true — the debt is carried in public instead');
      expect(find.textContaining('We have not written this yet'), findsOneWidget);
    });

    testWidgets('clearance reasoning never stands in for credit',
        (WidgetTester tester) async {
      await show(tester, 'salsa_shines');
      // salsa_shines HAS a `copyright.boundary` and NO `originAttribution`.
      // The boundary text must appear under its own heading, and must not
      // silence the attribution gap above it.
      expect(find.text(StyleStrings.boundaryTitle), findsOneWidget);
      expect(find.byKey(StyleDetailView.attributionGapKey), findsOneWidget,
          reason: 'having a legal boundary is not the same as having said '
              'whose dance this is');
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
      expect(find.byKey(StyleDetailView.noLessonsKey), findsOneWidget);
      expect(find.byKey(StyleDetailView.lessonKey('any')), findsNothing);
      expect(find.byKey(StyleDetailView.honestyKey), findsNothing,
          reason: 'an honesty box with nothing measured to report would be '
              'chrome pretending to be substance');
    });

    testWidgets('a style with a safety note shows it before the lessons',
        (WidgetTester tester) async {
      await show(tester, 'heels');
      expect(find.byKey(StyleDetailView.cautionKey), findsOneWidget,
          reason: "content marks this style 'ayakkabı güvenliği ZORUNLU' and a "
              'mandatory safety note that only appears once lessons exist is a '
              'note that arrives too late');
    });
  });
}
