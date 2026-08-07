import 'dart:convert';
import 'dart:io';

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

  bool isParked(StyleCard c) =>
      c.badge == StyleBadge.onHold;

  group('the catalogue is content, not a hand-written list', () {
    test('every style in the content file reaches the catalogue', () async {
      // A RULE, NOT A COUNT (C-160). This asserted `hasLength(34)`, which is
      // today's inventory rather than the property worth defending — and a
      // 35th style, correctly added, would have turned it red. Correct growth
      // must not look like a defect. What actually matters is that the loader
      // drops nothing and invents nothing.
      final LibraryCatalog lib = await testLibrary();
      final Map<String, dynamic> doc = (jsonDecode(
              File('content/library.json').readAsStringSync()) as Map)
          .cast<String, dynamic>();
      final List<String> declared = <String>[
        for (final Object? s in (doc['styles'] as List))
          (s as Map)['id'] as String,
      ];

      expect(declared, isNotEmpty,
          reason: 'if the content file cannot be read, every comparison below '
              'is between two empty lists (family lesson 4)');
      expect(lib.entries.map((LibraryEntry e) => e.id).toList(), declared,
          reason: 'the roadmap is DERIVED — same ids, same order, nothing '
              'dropped and nothing added. A literal style list anywhere in the '
              'app would break this.');
      expect(declared.toSet(), hasLength(declared.length),
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
      final List<StyleCard> cards = (await testLibrary()).cards;
      final LibraryTally t = LibraryTally.from(cards);

      expect(t.total, greaterThan(30));

      // THE TRIPWIRE — deliberately exact, and it is a RULE about the surface,
      // not an inventory count. The design's stat panel says "1 scored"; that
      // is the CONTENT count, and the only scored style is release-gated, so a
      // dancer can open no scored style at all. If this ever becomes non-zero
      // the panel's wording and the prose rules in `content_claims_test` both
      // need re-reading — which is why it fails loudly instead of adapting.
      expect(t.scored, 0,
          reason: 'repeating the content count on the surface would be the '
              'C-101 proxy defect');

      // The rest are RULES, not counts (C-160): writing content for a style is
      // correct progress and must not read as a regression.
      expect(t.openable, t.scored + t.openUngraded,
          reason: 'openable is exactly the two open buckets, whatever their '
              'sizes');
      for (final StyleCard c in cards) {
        final bool authored = c.courses != null;
        expect(c.badge == StyleBadge.inPreparation, !authored && !isParked(c),
            reason: '${c.entry.id}: "in preparation" must mean exactly "no '
                'authored document", in both directions — not a number that '
                'happens to be 31 today');
      }
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

  group('attribution', () {
    test('every style names where its dance comes from', () async {
      final List<StyleCard> cards = (await testLibrary()).cards;
      final Iterable<String> without = cards
          .where((StyleCard c) => c.attributionIsMissing)
          .map((StyleCard c) => c.entry.id);

      // This assertion INVERTED on 2026-08-07. It previously read
      // `expect(withAttribution, ['vogue'])` — a measurement of a gap, written
      // so it would fail loudly the day content landed. It did, and this is
      // what it became. Kept as a gate rather than deleted: a style added to
      // the catalogue tomorrow with no attribution must not slip in quietly.
      expect(without, isEmpty,
          reason: 'a style with no attribution renders a named gap to the '
              'user, which is honest but is a debt, not a resting state: '
              '$without');
    });

    test('attribution is prose for a reader, not a note to ourselves',
        () async {
      final List<StyleCard> cards = (await testLibrary()).cards;
      for (final StyleCard c in cards) {
        final String text = c.entry.originAttribution!;

        // The ORIGINAL value of this field on `vogue` was
        // "Black/Latino LGBTQ+ ballroom kültürü — atıf kutusu ZORUNLU" — an
        // instruction to whoever built the screen, in Turkish, sitting in a
        // field the style page renders VERBATIM to a dancer. It was never
        // wrong as a reminder; it was wrong as copy, and nothing caught it
        // because nothing rendered the field until now.
        expect(text, isNot(contains('ZORUNLU')),
            reason: '${c.entry.id}: an authoring directive is reaching the '
                'user-facing attribution box');
        expect(text.split(' ').length, greaterThan(20),
            reason: '${c.entry.id}: a phrase this short is a label, and the '
                'brief is explicit that credit is not a footnote');
      }
    });
  });
}
