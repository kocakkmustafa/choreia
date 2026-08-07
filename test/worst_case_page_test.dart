import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// The style page under the LONGEST content the catalogue can produce.
///
/// Family lesson #3 has five layers now, and this file is the fifth. It began
/// here — "real text is longer than a fixture", found on this line — then
/// Lissom pinned 375pt, Ostinato named `flutter_test`'s 800pt default, JabLab
/// made it a permanent gate. J-118 adds the layer that matters while a content
/// queue is being emptied: **real content is longer than YESTERDAY's content.**
/// An overflow test can pass today and break tomorrow, not because any string
/// grew, but because the product did.
///
/// WHY THE REAL PAGES ARE NOT ENOUGH
/// ---------------------------------
/// `library_view_test.dart` already renders all 34 real style pages. Measured
/// 2026-08-07, the maxima are spread across DIFFERENT styles — longest
/// attribution on `ballroom_latin_solo` (405 chars), longest description on
/// `vogue`, longest lesson reason on `salsa_shines` (708), longest gloss on
/// `hip_hop_foundations`. No real page carries them together, so rendering all
/// 34 never measures the page this app can actually produce.
///
/// WHY IT IS DERIVED AND NOT WRITTEN DOWN
/// --------------------------------------
/// Every field below takes the maximum found in real content. A fixture with
/// hand-copied "long" strings is a constant, and a constant goes quietly stale
/// the moment the 33rd style is written — the same failure C-153 cleaned out of
/// this suite's exemption lists. When the content queue empties, this test gets
/// harder on its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryCatalog lib;
  setUpAll(() async => lib = await testLibrary());

  String longestOf(Iterable<String?> xs) {
    String best = '';
    for (final String? x in xs) {
      if (x != null && x.length > best.length) best = x;
    }
    return best;
  }

  /// A style no one wrote, made only of maxima that someone did.
  StyleCard worstCase() {
    final List<StyleCard> all = lib.cards;

    final List<GlossaryEntry> glossaries = <GlossaryEntry>[
      for (final StyleCard c in all) ...c.entry.stepGlossary,
    ];
    final int mostEntries = all
        .map((StyleCard c) => c.entry.stepGlossary.length)
        .fold(0, (int a, int b) => a > b ? a : b);
    final String longestGlossName =
        longestOf(glossaries.map((GlossaryEntry g) => g.name));
    final String longestGloss =
        longestOf(glossaries.map((GlossaryEntry g) => g.gloss));

    final List<LessonInfo> lessons =
        <LessonInfo>[for (final StyleCard c in all) ...c.lessons];
    final int mostLessons =
        all.map((StyleCard c) => c.lessons.length).fold(0, (a, b) => a > b ? a : b);
    final String longestLessonName =
        longestOf(lessons.map((LessonInfo l) => l.displayName));
    final String longestReason =
        longestOf(lessons.map((LessonInfo l) => l.reason));

    final List<StyleProse> prose = lib.proseByStyle.values.toList();
    final String longestMeasured =
        longestOf(prose.expand((StyleProse p) => p.measured));
    final String longestNotMeasured =
        longestOf(prose.expand((StyleProse p) => p.notMeasured));
    final int mostNotMeasured = prose
        .map((StyleProse p) => p.notMeasured.length)
        .fold(0, (int a, int b) => a > b ? a : b);

    return StyleCard(
      entry: LibraryEntry(
        id: 'worst_case',
        displayName: longestOf(all.map((StyleCard c) => c.entry.displayName)),
        contentStatus: 'demoOpen',
        originAttribution:
            longestOf(all.map((StyleCard c) => c.entry.originAttribution)),
        description: longestOf(all.map((StyleCard c) => c.entry.description)),
        stepGlossary: <GlossaryEntry>[
          for (int i = 0; i < mostEntries; i++)
            GlossaryEntry(name: longestGlossName, gloss: longestGloss),
        ],
        subDances: all
            .map((StyleCard c) => c.entry.subDances)
            .reduce((List<String> a, List<String> b) =>
                a.join().length >= b.join().length ? a : b),
        safetyOnboarding:
            longestOf(all.map((StyleCard c) => c.entry.safetyOnboarding)),
        safetyExclusions: all
            .map((StyleCard c) => c.entry.safetyExclusions)
            .reduce((a, b) => a.join().length >= b.join().length ? a : b),
        hardwareRequired: all
            .map((StyleCard c) => c.entry.hardwareRequired)
            .reduce((a, b) => a.join().length >= b.join().length ? a : b),
      ),
      view: lib.cardFor('hip_hop_foundations')!.view,
      prose: StyleProse(
        measured: <String>[longestMeasured, longestMeasured],
        notMeasured: <String>[
          for (int i = 0; i < mostNotMeasured; i++) longestNotMeasured,
        ],
        reproductionBoundary: longestOf(
            prose.map((StyleProse p) => p.reproductionBoundary)),
      ),
      courses: CourseCatalog(
        lessons: <LessonInfo>[
          for (int i = 0; i < mostLessons; i++)
            LessonInfo(
              id: 'worst_$i',
              styleId: 'worst_case',
              level: 1,
              displayName: longestLessonName,
              // Rotate the three classes so every card treatment is exercised
              // at maximum length, not just the one the first lesson happens
              // to be.
              kind: LessonKind.values[i % LessonKind.values.length],
              plannedMinutes: 88,
              reason: longestReason,
            ),
        ],
        blockedGates: const <BlockedGate>[],
      ),
    );
  }

  test('the composite really is worse than any real page', () {
    final StyleCard worst = worstCase();

    int weight(StyleCard c) {
      int total = (c.entry.description?.length ?? 0) +
          (c.entry.originAttribution?.length ?? 0);
      for (final GlossaryEntry g in c.entry.stepGlossary) {
        total += g.name.length + g.gloss.length;
      }
      for (final LessonInfo l in c.lessons) {
        total += l.reason?.length ?? 0;
      }
      return total;
    }

    final int heaviestReal =
        lib.cards.map(weight).fold(0, (int a, int b) => a > b ? a : b);

    expect(weight(worst), greaterThan(heaviestReal),
        reason: 'if the composite is not heavier than every real page, it is '
            'measuring nothing the existing tests do not already cover');
    expect(worst.entry.stepGlossary, isNotEmpty);
    expect(worst.lessons, isNotEmpty);
    expect(worst.prose!.notMeasured, isNotEmpty);
  });

  testWidgets('the worst page this catalogue can produce fits 375x812',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: StyleDetailView(card: worstCase()),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'the composite page overflowed on first paint');

    for (int i = 0; i < 60; i++) {
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable.first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'the composite page overflowed while scrolling (drag $i)');
    }
  });

  testWidgets('and it still fits when the reader doubles the text size',
      (WidgetTester tester) async {
    // The other axis content growth arrives on. A page that only fits at 1.0x
    // fits by luck: the text this app writes is long AND a reader can enlarge
    // it, and those two multiply.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: StyleDetailView(card: worstCase()),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'overflowed at 2x text scale on first paint');

    for (int i = 0; i < 60; i++) {
      final Finder scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable.first, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'overflowed at 2x text scale while scrolling (drag $i)');
    }
  });

  testWidgets('the CATALOGUE survives the same two pressures',
      (WidgetTester tester) async {
    // The overflowing Row lived in three places, not one (C-158) — the lesson
    // card, the hero tile and the compact tile all had the same shape. Fixing
    // only the page the composite exercised would have been fixing the example
    // again, so the catalogue is measured under the same 2x pressure here.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: Scaffold(body: LibraryView(library: lib)),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'the catalogue overflowed at 2x on first paint');

    for (int i = 0; i < 60; i++) {
      await tester.drag(
          find.byKey(LibraryView.gridKey), const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'the catalogue overflowed at 2x while scrolling (drag $i)');
    }
  });
}
