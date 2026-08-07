import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// The catalogue screen, rendered against the repository's real content.
///
/// EVERY SIZED TEST IS PINNED TO 375x812.
/// `flutter_test`'s default surface is 800x600 — a viewport wider than any
/// phone this app ships on, which makes overflow tests pass on layouts that
/// break on a real device. This family has already paid for that lesson three
/// times; the pin is the fix, and the real content is the other half of it,
/// because the strings here (a 90-word `demoOnlyReason`) are far longer than
/// any fixture anyone would write by hand.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const Size phone = Size(375, 812);

  // THE CATALOG IS LOADED HERE, NOT INSIDE A TEST — and this is not a style
  // preference, it is the difference between a suite that runs and one that
  // hangs forever (measured 2026-08-07, DEFTER C-142).
  //
  // `AssetBundle.loadString` decodes payloads under 50 KB inline and hands
  // anything larger to `compute()`, which is a REAL isolate. `testWidgets` runs
  // its body inside a fake-async zone whose clock never advances real isolate
  // work, so that round-trip never completes: the process sits at 0% CPU with
  // no output, which is what distinguishes a deadlock from a slow machine.
  //
  // `LibraryCatalog.load` crossed that threshold the moment it started probing
  // `content/references/*.json` for runnable steps — those files are 74-79 KB,
  // while `library.json` (15 KB) and the two `style.json` documents (16-17 KB)
  // are all comfortably under it. `setUpAll` runs outside the fake zone, so the
  // isolate completes normally there.
  //
  // The app is unaffected: nothing on a device runs in fake-async. This is a
  // TEST-HARNESS rule, and it applies to every sibling app the day its content
  // grows past 50 KB — which is why it is written here as a pattern rather than
  // as a note about one file.
  late LibraryCatalog lib;
  setUpAll(() async => lib = await testLibrary());

  /// `wrap` is false for a widget that already builds its own `Scaffold`
  /// (the style page does; the catalogue does not).
  Future<void> pumpAt(WidgetTester tester, Widget child,
      {Size size = phone, bool wrap = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: wrap ? Scaffold(body: child) : child,
    ));
    await tester.pump();
  }

  group('the catalogue shows all of the scope and none of it as available', () {
    testWidgets('all 34 styles are on the screen', (WidgetTester tester) async {
      await pumpAt(tester, LibraryView(library: lib));

      // Scroll the whole list and collect every tile that appears. A tile can
      // only be found while it is mounted, so counting requires walking.
      final Set<String> seen = <String>{};
      for (int i = 0; i < 40; i++) {
        for (final LibraryEntry e in lib.entries) {
          if (find.byKey(LibraryView.tileKey(e.id)).evaluate().isNotEmpty) {
            seen.add(e.id);
          }
        }
        if (seen.length == lib.entries.length) break;
        await tester.drag(
            find.byKey(LibraryView.gridKey), const Offset(0, -300));
        await tester.pump();
      }

      expect(seen, hasLength(34),
          reason: 'a style missing from the grid is scope hidden from the '
              'user; the ones that reached this screen were: ${seen.length}');
    });

    testWidgets('the panel says one style is open and none of it is graded',
        (WidgetTester tester) async {
      await pumpAt(tester, LibraryView(library: lib));

      final Finder panel = find.byKey(LibraryView.tallyKey);
      expect(panel, findsOneWidget);

      final String text = tester
          .widgetList<Text>(find.descendant(of: panel, matching: find.byType(Text)))
          .map((Text t) => t.data ?? '')
          .join(' ');

      expect(text, contains('34 styles'));
      expect(text, contains('One of them is open to practise'));
      expect(text, contains('none of the open ones is graded'),
          reason: "the mockup's panel claims '1 scored'. The one scored style "
              'is release-gated, so saying so here would promise a door that '
              'does not open.');
    });

    testWidgets('no promise language anywhere on the screen (M-F-186)',
        (WidgetTester tester) async {
      await pumpAt(tester, LibraryView(library: lib));

      // 'yet' is on this list by coordinator ruling (2026-08-07, via Ostinato):
      // "gerekçenin varlığı 'yet'i affetmiyor — 'yet' bir zaman taahhüdü."
      // A named reason after the word does not redeem it; the word itself
      // promises a schedule we have not committed to.
      final List<String> banned = <String>[
        'coming soon',
        'yakında',
        'soon',
        ' yet',
      ];
      for (int i = 0; i < 40; i++) {
        final String screen = tester
            .widgetList<Text>(find.byType(Text))
            .map((Text t) => (t.data ?? '').toLowerCase())
            .join(' ');
        for (final String word in banned) {
          expect(screen, isNot(contains(word)),
              reason: '"$word" is promise language — a style that is not built '
                  'says WHAT IS TRUE OF IT, never when it might change');
        }
        if (find.byKey(LibraryView.gridKey).evaluate().isEmpty) break;
        await tester.drag(
            find.byKey(LibraryView.gridKey), const Offset(0, -400));
        await tester.pump();
      }
    });
  });

  group('grouping, not hiding', () {
    testWidgets('the on-hold style is present with its reason, not dropped',
        (WidgetTester tester) async {
      await pumpAt(tester, LibraryView(library: lib));

      // NOT `scrollUntilVisible`. Every screen in this app sits on
      // `ChoreiaBackdrop`, whose two drifting blobs run on `..repeat()`
      // FOREVER, and `scrollUntilVisible` settles the tree between drags —
      // against a never-ending animation that never returns. Measured
      // 2026-08-07: the run produced no output at all for 10 minutes, which is
      // what separates a deadlock from a slow machine. Bounded manual drags
      // with plain `pump()` are the pattern for this whole family, not just
      // this test (DEFTER C-141).
      final Finder section =
          find.byKey(LibraryView.sectionKey(StyleBadge.onHold));
      for (int i = 0; i < 40 && section.evaluate().isEmpty; i++) {
        await tester.drag(
            find.byKey(LibraryView.gridKey), const Offset(0, -350));
        await tester.pump();
      }
      expect(section, findsOneWidget);
      expect(find.byKey(LibraryView.tileKey('hula')), findsOneWidget);
    });

    testWidgets('OPEN NOW narrows to exactly the openable styles',
        (WidgetTester tester) async {
      await pumpAt(tester, LibraryView(library: lib));

      await tester.tap(find.textContaining(LibraryStrings.filterOpenNow));
      await tester.pump();

      expect(find.byKey(LibraryView.tileKey('hip_hop_foundations')),
          findsOneWidget);
      expect(find.byKey(LibraryView.tileKey('salsa_shines')), findsNothing,
          reason: 'salsa has the only scored lesson AND a closed release gate '
              '— it is not something a dancer can open now');
      expect(find.byKey(LibraryView.tileKey('vogue')), findsNothing);
    });
  });

  group('layout holds at a real phone width', () {
    testWidgets('the catalogue does not overflow at 375x812',
        (WidgetTester tester) async {
      await pumpAt(tester, LibraryView(library: lib));

      for (int i = 0; i < 40; i++) {
        expect(tester.takeException(), isNull,
            reason: 'a RenderFlex overflow while scrolling the catalogue');
        await tester.drag(
            find.byKey(LibraryView.gridKey), const Offset(0, -350));
        await tester.pump();
      }
    });

    testWidgets('every style page renders at 375x812 without overflowing',
        (WidgetTester tester) async {
      // ALL 34, not a sample. The two with authored documents carry paragraphs
      // an order of magnitude longer than the rest, and the 32 without them
      // exercise the empty branches — sampling would test neither reliably.
      for (final StyleCard card in lib.cards) {
        await pumpAt(
          tester,
          StyleDetailView(card: card, runnableSteps: lib.runnableSteps),
          wrap: false,
        );
        expect(tester.takeException(), isNull,
            reason: '${card.entry.id} overflowed on first paint');

        for (int i = 0; i < 12; i++) {
          final Finder scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isEmpty) break;
          await tester.drag(scrollable.first, const Offset(0, -400));
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: '${card.entry.id} overflowed while scrolling');
        }
      }
    });
  });
}
