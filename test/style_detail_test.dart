import 'dart:convert';
import 'dart:io';
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
  ///
  /// DERIVED FROM `pubspec.yaml`, NOT HAND-WRITTEN (C-153). It used to be the
  /// literal `{'ss_shine_footwork'}`, which is the exemption-list failure
  /// JabLab measured: a constant asserting a fact about the world, with nothing
  /// checking that the fact still holds. If `hh_bounce.json` were declared
  /// tomorrow, that literal would stay unchanged and the "no lesson can be
  /// started" test below would keep passing while the app gained a startable
  /// lesson. Reading the manifest makes the assumption impossible to hold
  /// stale.
  late final Set<String> deviceRunnable;
  setUpAll(() {
    final Set<String> declared = _declaredAssets();
    deviceRunnable = <String>{
      for (final StyleCard c in lib.cards)
        for (final LessonInfo l in c.lessons)
          if (l.stepId != null &&
              declared.contains('content/references/${l.stepId}.json'))
            l.stepId!,
    };
    expect(deviceRunnable, isNotEmpty,
        reason: 'if the manifest parser breaks, every assertion built on this '
            'set silently becomes "nothing runs" and passes for the wrong '
            'reason');
  });

  Future<void> show(WidgetTester tester, String styleId,
      {Set<String>? runnable}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: StyleDetailView(
          card: lib.cardFor(styleId)!,
          runnableSteps: runnable ?? deviceRunnable),
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

    test('MEASURED: WHICH styles are unwritten, not merely how many', () {
      // SETS, NOT COUNTS (C-153). `expect(described, 33)` passes while hula
      // gains a description and some other style loses one — the count is
      // preserved and the one omission that is a RULE rather than a backlog
      // item has been quietly reversed.
      final Set<String> undescribed = lib.cards
          .where((StyleCard c) => c.entry.description == null)
          .map((StyleCard c) => c.entry.id)
          .toSet();
      expect(undescribed, <String>{'hula'},
          reason: 'hula is unwritten BY RULE — its on-hold reason forbids '
              'producing content from generic sources. Any other style landing '
              'here is a gap; hula leaving here is a rule being broken.');

      final Set<String> unglossed = lib.cards
          .where((StyleCard c) => c.entry.stepGlossary.isEmpty)
          .map((StyleCard c) => c.entry.id)
          .toSet();

      // ASYMMETRIC ON PURPOSE (C-160). Writing a glossary is correct progress
      // and must not read as a regression, so a style LEAVING this set passes
      // silently. A style ENTERING it is the thing worth catching: it means a
      // new style shipped with no vocabulary and no recorded reason.
      // `containsAll` would be the wrong direction — it is `subsetOf` that
      // says "no new unexplained omissions".
      const Set<String> explainedOmissions = <String>{
            'hula',
            'kpop_point',
            'tiktok_format',
            'latin_fusion_fitness',
            'heels',
            'bollywood',
            'contemporary',
            'irish_dance',
            'cumbia_solo',
            'bhangra',
            'samba_no_pe',
            'dancehall',
            'shuffle',
            'merengue_solo',
            'twerk_reggaeton',
            'kizomba_zouk_solo',
      };

      // THE FIFTH EXEMPTION STRUCTURE (C-165), and I wrote it myself an hour
      // AFTER the commit that was about exactly this class. C-153 converted
      // four hand-written assumptions into derivations and proved each by
      // sabotage; this one arrived in C-160 and shipped without the
      // self-audit the other four got. A style removed from content would
      // leave a dead id here and `containsAll` would stay green forever.
      final Set<String> allIds =
          lib.cards.map((StyleCard c) => c.entry.id).toSet();
      expect(explainedOmissions.difference(allIds), isEmpty,
          reason: 'these ids are exempted from needing a glossary but no '
              'longer exist in content: '
              '${explainedOmissions.difference(allIds)}. An exemption that '
              'outlives the thing it exempts is folklore.');

      expect(explainedOmissions.containsAll(unglossed), isTrue,
          reason: 'a style has no glossary and no recorded reason: '
              '${unglossed.difference(explainedOmissions)}. Each existing '
              'omission has one (routine-specific vocabulary · steps belong to '
              'other styles · no settled named vocabulary · not nameable with '
              'confidence) — a new one needs its own.');

      // hula is the one omission that is a RULE rather than a backlog item,
      // so it is pinned exactly in both directions.
      expect(unglossed, contains('hula'),
          reason: 'hula must stay unglossed — its on-hold reason forbids '
              'producing content from generic sources');
    });
  });

  group('the attribution box is not the quieter thing on the page (C-174)', () {
    // A HARD RULE WITH NO GATE, found by sweeping the brief's ⛔ list: "köken/
    // atıf kutusu küçültülmez, dipnota indirilmez". That is a COMPARATIVE
    // visual commitment, and nothing measured it — the same shape as
    // "demo-only is not second class" before C-156 turned it into numbers.
    //
    // Measured before the fix: attribution 13.5 under a 14.5 intro. One point
    // is not a footnote, but credit was rendering smaller than the paragraph
    // directly above it.

    testWidgets('no prose on the page is larger than the attribution',
        (WidgetTester tester) async {
      for (final String id in <String>['vogue', 'salsa_shines', 'hula']) {
        await show(tester, id);

        double attribution = 0;
        final List<String> larger = <String>[];
        for (final Element e in find.byType(Text).evaluate()) {
          final Text w = e.widget as Text;
          final double? size = w.style?.fontSize;
          final String text = w.data ?? '';
          if (size == null || text.isEmpty) continue;
          // Headings are a different register and are allowed to be bigger;
          // this rule is about PROSE, which is what a footnote demotion would
          // target.
          if (size >= 17) continue;
          if (text.startsWith(StyleStrings.attributionMissing.substring(0, 20)) ||
              (lib.cardFor(id)!.entry.originAttribution != null &&
                  text == lib.cardFor(id)!.entry.originAttribution)) {
            attribution = size;
            continue;
          }
          if (size > StyleDetailView.attributionSize) {
            larger.add('"${text.substring(0, text.length.clamp(0, 30))}" @$size');
          }
        }

        expect(attribution, StyleDetailView.attributionSize,
            reason: '$id renders its attribution at $attribution, not at the '
                'declared ${StyleDetailView.attributionSize}');
        expect(larger, isEmpty,
            reason: '$id sets prose larger than the attribution box, which '
                'makes credit the quieter thing on the page: $larger');
      }
    });
  });

  group('the protected sentence is still ON SCREEN (C-172)', () {
    // A gate that accepts the DELETION of the sentence it protects guards a
    // SILENCE, not an honesty. Measured by sabotage 2026-08-07: removing the
    // `whyPermanent` render block left all 180 tests green — the content gate
    // says a permanent lesson must SAY why, and nothing said it must REACH a
    // reader.

    testWidgets('whyPermanent reaches the card, not just the JSON',
        (WidgetTester tester) async {
      final StyleCard salsa = lib.cardFor('salsa_shines')!;
      final LessonInfo permanent = salsa.lessons.firstWhere(
          (LessonInfo l) => l.demoOnlyClass == 'permanent',
          orElse: () => throw StateError('no permanent lesson to check'));
      expect(permanent.whyPermanent, isNotNull);

      await show(tester, 'salsa_shines');
      final Finder block =
          find.byKey(StyleDetailView.permanenceKey(permanent.id));
      await scrollTo(tester, block);
      expect(block, findsOneWidget,
          reason: 'the strongest honesty claim in the app — "this limit will '
              'not lift" — is in content and not on the screen');
      expect(find.text(StyleStrings.permanentTitle), findsWidgets);
      expect(find.textContaining(permanent.whyPermanent!.split('.').first),
          findsWidgets,
          reason: 'the heading rendered but the sentence did not');
    });

    testWidgets('a lesson that is NOT permanent gets no such block',
        (WidgetTester tester) async {
      // The positive twin: a block rendered unconditionally would pass the
      // test above while telling every learner a limit is permanent.
      final StyleCard salsa = lib.cardFor('salsa_shines')!;
      final LessonInfo other = salsa.lessons.firstWhere(
          (LessonInfo l) => l.whyPermanent == null,
          orElse: () => throw StateError('every lesson is permanent'));

      await show(tester, 'salsa_shines');
      expect(find.byKey(StyleDetailView.permanenceKey(other.id)), findsNothing);
    });
  });

  group('camera limits on the page (C-161)', () {
    testWidgets('an unbuilt style shows them, under a note that says why',
        (WidgetTester tester) async {
      await show(tester, 'tap');
      final Finder section = find.byKey(StyleDetailView.cameraLimitsKey);
      await scrollTo(tester, section);
      expect(section, findsOneWidget);

      // The note is the load-bearing part: without it, "what a camera cannot
      // see" reads as the caveat on a working product rather than a fact about
      // the dance.
      expect(find.text(StyleStrings.limitsNote), findsOneWidget);

      // And the page must still say plainly that nothing is built.
      await scrollTo(tester, find.byKey(StyleDetailView.noLessonsKey));
      expect(find.byKey(StyleDetailView.noLessonsKey), findsOneWidget);
    });

    testWidgets('an authored style shows the REAL honesty block instead',
        (WidgetTester tester) async {
      await show(tester, 'salsa_shines');
      final Finder honesty = find.byKey(StyleDetailView.honestyKey);
      await scrollTo(tester, honesty);
      expect(honesty, findsOneWidget);
      expect(find.byKey(StyleDetailView.cameraLimitsKey), findsNothing,
          reason: 'a measured block and a substitute block on one page would '
              'let a claim about the dance be read as a measurement');
    });

    testWidgets('hula shows neither block and still explains itself',
        (WidgetTester tester) async {
      await show(tester, 'hula');
      expect(find.byKey(StyleDetailView.cameraLimitsKey), findsNothing);
      expect(find.byKey(StyleDetailView.honestyKey), findsNothing);
      expect(find.byKey(StyleDetailView.attributionKey), findsOneWidget);
    });
  });

  group('BUNU KİM GÖRÜYOR — her alan bir yüzeyde çiziliyor (C-176)', () {
    // "Doğruluk denetimi pahalı, izleyici denetimi ucuz — ve ikincisi çoğu
    // zaman birincisini de yapıyor" (JabLab J-147). Sorulan soru "bu doğru mu"
    // değil, "bunu KİM görüyor": içeriğin var olması, birinin onu görmesi
    // demek değil, ve bu ailede bir alan yazıp render etmemek ("içerik var,
    // yüzeyi yok") ölçülmüş bir sınıf.
    //
    // Ölçüm 2026-08-07: 34 stilin HER alanı çiziliyor, çizilmeyen yok. Bu kapı
    // o durumu çiviliyor — 32 stil daha yazılacak ve her yeni alan aynı
    // soruyla karşılaşmalı.

    testWidgets('34 stilin hiçbir alanı içerikte kalmıyor',
        (WidgetTester tester) async {
      // Uzun yüzey: kaydırma gerekmeden her blok ağaçta olsun. Dokunuş yolu
      // olmadığı için (C-146) tek güvenilir yol bu.
      tester.view.physicalSize = const Size(375, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final List<String> unseen = <String>[];
      for (final StyleCard c in lib.cards) {
        await tester.pumpWidget(MaterialApp(
            theme: ChoreiaTheme.dark, home: StyleDetailView(card: c)));
        await tester.pump();
        final String id = c.entry.id;
        bool shown(Key k) => find.byKey(k).evaluate().isNotEmpty;

        if (c.entry.originAttribution != null && !shown(StyleDetailView.attributionKey)) {
          unseen.add('$id/originAttribution');
        }
        if (c.entry.description != null && !shown(StyleDetailView.descriptionKey)) {
          unseen.add('$id/description');
        }
        if (c.entry.stepGlossary.isNotEmpty && !shown(StyleDetailView.glossaryKey)) {
          unseen.add('$id/stepGlossary');
        }
        if (c.entry.cameraLimits.isNotEmpty && !shown(StyleDetailView.cameraLimitsKey)) {
          unseen.add('$id/cameraLimits');
        }
        if (c.entry.onHoldReason != null &&
            find.textContaining(c.entry.onHoldReason!.substring(0, 25))
                .evaluate()
                .isEmpty) {
          unseen.add('$id/onHoldReason');
        }
      }

      expect(lib.cards.length, greaterThan(30),
          reason: 'katalog boşaldıysa bu kapı hiçbir şey ölçmez');
      expect(unseen, isEmpty,
          reason: 'bu alanlar içerikte var ve hiçbir yüzeyde çizilmiyor — '
              'yazmak ilerleme gibi gelir, dansçı hiçbir şey görmez: $unseen');
    });
  });

  group('atıf DOĞRULANMIŞ gibi sunulamaz (C-176)', () {
    // JabLab'ın en pahalı vakası burada olurdu: 34 kültürel iddia, YAŞAYAN
    // topluluklar hakkında, ve KAYNAK KAYDI YOK — oysa bu repodaki her diğer
    // içerik sınıfı taşıyor (stepInventory.sourcedFrom · ders evidence ·
    // referans sources). Durum content'e kaydedildi; bu kapı yüzeyin o
    // durumdan FAZLASINI iddia etmemesini sağlıyor.

    test('kaynak durumu içerikte KAYITLI ve dürüst', () {
      final Map<String, dynamic> doc = (jsonDecode(
              File('content/library.json').readAsStringSync()) as Map)
          .cast<String, dynamic>();
      final Object? prov = doc['originAttributionProvenance'];
      expect(prov, isNotNull,
          reason: '34 kültürel iddia kaynak kaydı olmadan duruyor ve bunu '
              'söyleyen bir kayıt da yok');
      final Map<String, dynamic> p = (prov! as Map).cast<String, dynamic>();
      expect('${p['status']}', startsWith('UNSOURCED'),
          reason: 'kaynak bulunduysa bu kaydı GÜNCELLE — kapı da, aşağıdaki '
              'yasak da o gün yeniden okunmalı');
      expect(p['whatIsStillOwed'], isNotNull);
    });

    testWidgets('yüzey ASLA panel/inceleme/doğrulama iddia etmez',
        (WidgetTester tester) async {
      // Tasarım mockup'ı "reviewed with our salsa teacher panel · 6 names
      // credited" gösteriyordu. Kaynaksız metnin üstüne o cümle konulursa
      // UYDURULMUŞ BİR KİMLİK olur — icat edilen gerekçenin en pahalı hâli.
      final RegExp claim = RegExp(
          r'reviewed with|teacher panel|names credited|verified by|'
          r'in consultation with|fact-checked',
          caseSensitive: false);

      for (final String id in <String>['vogue', 'salsa_shines', 'hula', 'bhangra']) {
        await show(tester, id);
        final String screen = tester
            .widgetList<Text>(find.byType(Text))
            .map((Text t) => t.data ?? '')
            .join(' ');
        expect(claim.hasMatch(screen), isFalse,
            reason: '$id sayfası atıf için bir doğrulama iddia ediyor, ama '
                'metinlerin kaynak kaydı YOK');
      }
    });

    test('hiçbir atıf metni kendi içinde doğrulama iddia etmez', () {
      final RegExp claim = RegExp(
          r'reviewed|verified|confirmed by|according to our|our panel',
          caseSensitive: false);
      final List<String> offenders = <String>[
        for (final StyleCard c in lib.cards)
          if (c.entry.originAttribution != null &&
              claim.hasMatch(c.entry.originAttribution!))
            c.entry.id,
      ];
      expect(offenders, isEmpty, reason: '$offenders');
    });
  });

  group('ÇERÇEVE DE BİR İDDİADIR (C-177)', () {
    // "Doğru bir cümle yanlış bir çerçevede yanlış okunur." Bu kapı tek tek
    // cümlelerin doğruluğunu değil, KOMŞULUKLARIN ürettiği iddiayı ölçüyor —
    // bu gece bulunan iki kusurun ikisi de her cümlesi doğru olan bloklardı.

    test('sınır listesi TAM LİSTE gibi sunulamaz', () {
      // Ölçülen kusur: not "these are the parts" diyordu (kapalı küme) ve
      // hemen ÜSTÜNDE 5 maddelik adım sözlüğü vardı. Birlikte okununca:
      // "işte adımlar · işte göremediklerimiz" → geri kalanı kontrol ediliyor.
      expect(StyleStrings.limitsNote, contains('not a full list'),
          reason: 'sınırlar örneklem; kapalı küme gibi sunmak, adlandırılmayan '
              'her şeyin kontrol edildiği iddiasını üretir');
      expect(StyleStrings.limitsNote, isNot(contains('these are the parts')));
    });

    testWidgets('sözlük ve sınırlar aynı sayfadayken not MUTLAKA görünür',
        (WidgetTester tester) async {
      // Komşuluk kapısı: kusuru üreten şey ikisinin YAN YANA olmasıydı, tek
      // başına hiçbiri değil. Sözlüğü olan her stilde not aranıyor.
      for (final StyleCard c in lib.cards) {
        if (c.entry.stepGlossary.isEmpty || c.entry.cameraLimits.isEmpty) {
          continue;
        }
        tester.view.physicalSize = const Size(375, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
            theme: ChoreiaTheme.dark, home: StyleDetailView(card: c)));
        await tester.pump();

        expect(find.text(StyleStrings.limitsNote), findsOneWidget,
            reason: '${c.entry.id}: sözlük ve sınırlar aynı sayfada ve '
                '"tam liste değil" notu görünmüyor');
        expect(find.text(StyleStrings.glossaryNote), findsOneWidget,
            reason: '${c.entry.id}: sözlük "ders değil" notu olmadan '
                'duruyor');
      }
    });

    test('iki dürüstlük listesi BÖLÜNTÜ gibi sunulamaz', () {
      // measured TAM (skorlanan her şey), notMeasured ÖRNEKLEM (kontrol
      // edilmeyen sonsuz). Aynı registerde yan yana iki başlık kapalı bir
      // bölüntü okutur — ve bu, sınırları EKSİK gösterir, yani bu uygulamanın
      // asla yanılmaması gereken yön.
      expect(StyleStrings.measuredTitle, contains('ALL OF IT'));
      expect(StyleStrings.notMeasuredTitle, contains('AMONG OTHERS'));
      expect(StyleStrings.honestyNote, contains('complete'));
      expect(StyleStrings.honestyNote, contains('is not, and cannot be'),
          reason: 'ikinci listenin tamamlanamaz olduğu SÖYLENMELİ — yoksa '
              'dört madde, kontrol edilmeyen her şey sanılır');
    });

    testWidgets('authored stilde iki liste birlikte ve notuyla görünür',
        (WidgetTester tester) async {
      // Gerçek telefon genişliğinde + kaydırarak: salsa 9 uzun ders taşıyor ve
      // sayfa herhangi bir sabit yüzeye sığmıyor. Yükseklik büyütmek yerine
      // kaydırmak, gerçek okuma yolunu ölçüyor.
      await show(tester, 'salsa_shines');
      final Finder note = find.text(StyleStrings.honestyNote);
      await scrollTo(tester, note);

      expect(note, findsOneWidget,
          reason: 'iki liste notsuz yan yana durursa bölüntü okunur');
      expect(find.text(StyleStrings.measuredTitle), findsOneWidget);
      expect(find.text(StyleStrings.notMeasuredTitle), findsOneWidget,
          reason: 'iki başlık aynı ekranda olmalı — biri kaydırma dışında '
              'kalırsa okur yalnız "kontrol ediyoruz" tarafını görür');
    });
  });
}

/// Asset paths declared under `flutter: assets:`.
///
/// A second copy of `content_assets_test.dart`'s parser, deliberately: that
/// file gates the manifest, this one DERIVES from it, and importing across test
/// files to share eight lines would couple two gates that should be able to
/// fail independently. Both are pinned by their own non-empty assertions.
Set<String> _declaredAssets() {
  final List<String> lines = File('pubspec.yaml').readAsLinesSync();
  final Set<String> out = <String>{};
  bool inAssets = false;
  for (final String line in lines) {
    if (RegExp(r'^\s{2}assets:\s*$').hasMatch(line)) {
      inAssets = true;
      continue;
    }
    if (inAssets) {
      final RegExpMatch? m = RegExp(r'^\s{4}-\s+(\S+)\s*$').firstMatch(line);
      if (m != null) {
        out.add(m.group(1)!);
        continue;
      }
      if (line.trim().isNotEmpty && !line.trim().startsWith('#')) break;
    }
  }
  return out;

}
