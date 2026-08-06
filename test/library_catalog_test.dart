import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/style_availability.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// The Library's numbers, measured against the repository's real content.
///
/// These run against `content/library.json` itself rather than a fixture, on
/// purpose. The claim worth defending is not "my derivation is self-consistent"
/// — a fixture proves that and agrees with whatever its author believed (M-F-03)
/// — it is "the counts this screen shows are the counts the shipped content
/// implies". Only real content can fail that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the catalogue is content, not a hand-written list', () {
    test('all 34 styles come from content/library.json', () async {
      final LibraryCatalog lib = await testLibrary();
      expect(lib.entries, hasLength(34),
          reason: 'the roadmap is DERIVED. If this file ever needs a literal '
              'style list to make this pass, the rule "türetimli listeler elle '
              'yazılmaz" has been broken somewhere upstream.');
      expect(lib.entries.map((LibraryEntry e) => e.id).toSet(), hasLength(34),
          reason: 'duplicate ids would silently double a tile');
    });

    test('every entry carries a display name that is not its raw id', () async {
      final LibraryCatalog lib = await testLibrary();
      for (final LibraryEntry e in lib.entries) {
        expect(e.displayName, isNotEmpty);
        expect(e.displayName, isNot(e.id),
            reason: '${e.id} would render as a snake_case identifier');
      }
    });
  });

  group('THE CASE THAT MATTERS: content truth is not surface truth', () {
    test('salsa_shines is `live` in content AND cannot be opened', () async {
      final StyleCard? salsa = (await testLibrary()).cardFor('salsa_shines');
      expect(salsa, isNotNull);

      // Content axis: the scored lesson is real.
      expect(salsa!.entry.contentStatus, 'live');
      expect(salsa.scoredLessonCount, greaterThan(0),
          reason: 'the one scored lesson in the app lives here');

      // Release axis: the BPM gate is closed, so the door is not open.
      expect(salsa.view.availability, Availability.gatedByRelease);
      expect(salsa.isOpenable, isFalse);
      expect(salsa.badge, StyleBadge.builtButGated,
          reason: 'neither `scored` (promises a door that does not open) nor '
              '`inPreparation` (denies finished work) is honest here — this is '
              'why the badge set has four values and the mockup drew three');

      // And the user is told why, in dance words.
      expect(salsa.view.userFacingReason, isNotNull);
      expect(salsa.view.userFacingReason, contains('beat'));
      expect(salsa.view.userFacingReason, isNot(contains('bpm')));
      expect(salsa.view.userFacingReason, isNot(contains('BPM')));
    });

    test('hip_hop_foundations is open to practise and scores nothing',
        () async {
      final StyleCard? hh =
          (await testLibrary()).cardFor('hip_hop_foundations');
      expect(hh, isNotNull);
      expect(hh!.entry.contentStatus, 'demoOpen');
      expect(hh.isOpenable, isTrue,
          reason: 'teaching counts — a style with openable lessons must not '
              'advertise itself as unavailable');
      expect(hh.badge, StyleBadge.openUngraded);
      expect(hh.scoredLessonCount, 0,
          reason: 'demoOpen means exactly this: lessons open, none graded');
      expect(hh.lessons, isNotEmpty);
    });

    test('the honest headline: ZERO scored styles can be opened today',
        () async {
      final LibraryTally t = LibraryTally.from((await testLibrary()).cards);

      expect(t.total, 34);
      expect(t.scored, 0,
          reason: "the design's stat panel says '1 scored'. That is the "
              'CONTENT count. The only scored style is release-gated, so a '
              'dancer can open no scored style at all — repeating the content '
              'count on the surface would be the C-101 proxy defect.');
      expect(t.openUngraded, 1);
      expect(t.builtButGated, 1);
      expect(t.onHold, 1);
      expect(t.inPreparation, 31);
      expect(t.openable, 1);
    });

    test('the five badge buckets account for every style, with none double '
        'counted', () async {
      final LibraryTally t = LibraryTally.from((await testLibrary()).cards);
      expect(
          t.scored + t.openUngraded + t.builtButGated + t.inPreparation +
              t.onHold,
          t.total,
          reason: 'a style that fell out of every bucket would vanish from the '
              'grid while still being counted in the headline');
    });
  });

  group('nothing is hidden and nothing is invented', () {
    test('the on-hold style is present and states its reason', () async {
      final StyleCard? hula = (await testLibrary()).cardFor('hula');
      expect(hula, isNotNull,
          reason: 'a parked style is shown WITH its reason, never dropped from '
              'the catalogue');
      expect(hula!.badge, StyleBadge.onHold);
      expect(hula.entry.onHoldReason, isNotNull);
      expect(hula.entry.onHoldReason, isNotEmpty);
    });

    test('a style with no authored document declares no lessons', () async {
      final LibraryCatalog lib = await testLibrary();
      for (final StyleCard c in lib.cards) {
        if (c.courses != null) continue;
        expect(c.lessons, isEmpty,
            reason: '${c.entry.id} has no style.json — any lesson here would '
                'be invented');
        expect(c.isOpenable, isFalse,
            reason: '${c.entry.id} cannot be openable with nothing to open');
      }
    });

    test('every unopenable style carries a reason the user can read', () async {
      for (final StyleCard c in (await testLibrary()).cards) {
        if (c.isOpenable) continue;
        final String? reason = c.view.userFacingReason ?? c.entry.onHoldReason;
        expect(reason, isNotNull,
            reason: '${c.entry.id} would render as a closed door with no '
                'explanation — the silence K10 forbids');
        expect(reason, isNotEmpty);
      }
    });

    test('gates are never mixed between styles', () async {
      final LibraryCatalog lib = await testLibrary();
      final List<BlockedGate> salsaStyleGates = lib
              .coursesByStyle['salsa_shines']!
              .blockedGates
              .where((BlockedGate g) => g.scope == GateScope.style)
              .toList();
      final List<BlockedGate> hhStyleGates = lib
          .coursesByStyle['hip_hop_foundations']!
          .blockedGates
          .where((BlockedGate g) => g.scope == GateScope.style)
          .toList();

      expect(salsaStyleGates.map((BlockedGate g) => g.id), contains('bpmResolved'));
      expect(hhStyleGates, isEmpty,
          reason: 'hip-hop declares no ship gate. If salsa\'s BPM gate leaks '
              'into this list, the per-style split has been flattened back and '
              'hip-hop would falsely read as gated.');
    });
  });

  group('measured content gaps (these SHOULD fail when content is written)',
      () {
    test('origin/attribution is present on exactly one of the 34 styles',
        () async {
      final List<StyleCard> cards = (await testLibrary()).cards;
      final Iterable<String> withAttribution = cards
          .where((StyleCard c) => !c.attributionIsMissing)
          .map((StyleCard c) => c.entry.id);

      // Written as a measurement, not a target. When attribution lands for more
      // styles this test fails LOUDLY and gets its number updated — which is
      // the point: a silent pass would let the gap stop being visible.
      expect(withAttribution, <String>['vogue'],
          reason: 'measured 2026-08-07 — 1 of 34. Every other style renders '
              'its attribution box as a NAMED GAP rather than an empty panel.');
    });
  });
}
