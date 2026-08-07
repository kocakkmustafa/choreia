import 'package:choreia/app/library/library_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// Does the CONTENT claim only what the BADGE allows?
///
/// The transfer that produced this file (JabLab J-113) is the inverse of
/// M-F-287: writing a LIMIT too broadly is a known failure, but writing a
/// CAPABILITY too broadly is the more dangerous one, because it errs against
/// the user. JabLab's version had one list conflating "we detect and coach
/// this" with "we score this".
///
/// Choreia has the richest not-graded vocabulary in the family, so the risk here
/// is not a missing mechanism — it is TWO REPRESENTATIONS DRIFTING APART. The
/// badge (`StyleBadge`, derived) is one claim; the prose written for each style
/// is another, and nothing tied them together until this file.
///
/// Measured 2026-08-07, on prose written the same night: 8 of 33 descriptions
/// said "You learn / You drill / You follow / You work", and every one of those
/// styles was unopenable. New content is a new surface for the old
/// contradiction.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryCatalog lib;
  setUpAll(() async => lib = await testLibrary());

  /// Verbs that promise INSTRUCTION rather than describe a dance. Banned
  /// outright rather than only on unopenable styles: no lesson in this app can
  /// be started today, so "you learn" is a promise everywhere — and a rule
  /// conditioned on openability would silently relax the day one style opens,
  /// which is exactly when the prose would need re-reading, not less checking.
  final RegExp deliveryVerb =
      RegExp(r'\byou (learn|drill|practise|practice|work|follow|build|train)\b',
          caseSensitive: false);

  /// The app's own voice. It belongs in the attribution box, the honesty box
  /// and the blocked reasons — surfaces that are ABOUT what we do or cannot do.
  /// A style description is about the dance.
  final RegExp appVoice = RegExp(r'\bwe\b', caseSensitive: false);

  test('the corpus is big enough for these gates to mean something', () {
    final int described =
        lib.cards.where((StyleCard c) => c.entry.description != null).length;
    expect(described, greaterThan(30),
        reason: 'if descriptions vanish, every assertion below passes by '
            'measuring nothing (family lesson 4)');
  });

  test('no description promises instruction this app does not provide', () {
    final List<String> offenders = <String>[
      for (final StyleCard c in lib.cards)
        if (c.entry.description != null &&
            deliveryVerb.hasMatch(c.entry.description!))
          '${c.entry.id} (${c.badge.name}): '
              '"${deliveryVerb.firstMatch(c.entry.description!)!.group(0)}"',
    ];
    expect(offenders, isEmpty,
        reason: 'a description is about the DANCE. "You learn X" on a style '
            'page reads as "you learn X here", and here there is no lesson: '
            '$offenders');
  });

  test('no description speaks in the app\'s voice', () {
    final List<String> offenders = <String>[
      for (final StyleCard c in lib.cards)
        if (c.entry.description != null &&
            appVoice.hasMatch(c.entry.description!))
          c.entry.id,
    ];
    expect(offenders, isEmpty,
        reason: '"we" in a description turns a note about the dance into a '
            'claim about the product: $offenders');
  });

  test('a judging word never leaves the app as the implied judge', () {
    // Not banned — vogue's elements really are judged, at balls, and saying so
    // is part of what the dance is. What must never happen is the word sitting
    // in a sentence whose only available subject is us.
    final RegExp judge =
        RegExp(r'\b(judged|scored|graded)\b', caseSensitive: false);
    for (final StyleCard c in lib.cards) {
      final String? text = c.entry.description;
      if (text == null || !judge.hasMatch(text)) continue;

      expect(
          text,
          matches(RegExp(r'at a ball|in competition|at balls',
              caseSensitive: false)),
          reason: '${c.entry.id} uses a judging word without naming who is '
              'doing the judging. On a page whose badge says the style is not '
              'graded here, an unattributed "judged" is read as ours.');
    }
  });

  test('a glossary entry never claims a step is checked or taught here', () {
    final RegExp claim = RegExp(
        r'\b(we check|we measure|we grade|we score|graded|scored|feedback)\b',
        caseSensitive: false);
    final List<String> offenders = <String>[
      for (final StyleCard c in lib.cards)
        for (final GlossaryEntry g in c.entry.stepGlossary)
          if (claim.hasMatch(g.gloss)) '${c.entry.id}/${g.name}',
    ];
    expect(offenders, isEmpty,
        reason: 'a glossary is vocabulary. A gloss that says a step is graded '
            'contradicts the badge above it: $offenders');
  });

  test('THE CROSS-CHECK: nothing claims grading while nothing IS graded', () {
    // The badge side of the same question, tied to the prose side above. If a
    // style ever becomes genuinely scored-and-openable, this fails and the
    // prose rules deserve a fresh read rather than an automatic pass.
    final Iterable<StyleCard> gradedAndOpen = lib.cards
        .where((StyleCard c) => c.badge == StyleBadge.scored);
    expect(gradedAndOpen, isEmpty,
        reason: 'a style is now scored AND openable. The description rules '
            'above were written while nothing was — re-read them before '
            'relaxing anything.');
  });

  group('the honesty block an unbuilt style CAN have (C-161)', () {
    test('every style that could have camera limits has them', () {
      // A RULE, not a count (C-160). Two styles carry a real `honesty` block
      // in their own document and need no substitute; hula is unwritten by its
      // own on-hold reason. Everything else must say what a camera cannot see
      // in it — and a 35th unbuilt style added tomorrow falls under this
      // automatically.
      final Iterable<StyleCard> owed = lib.cards.where((StyleCard c) =>
          c.courses == null && c.entry.id != 'hula');
      expect(owed, isNotEmpty);

      final List<String> silent = <String>[
        for (final StyleCard c in owed)
          if (c.entry.cameraLimits.isEmpty) c.entry.id,
      ];
      expect(silent, isEmpty,
          reason: 'these styles say nothing about what we cannot see in them: '
              '$silent');
    });

    test('a style with a REAL honesty block does not get the substitute', () {
      for (final StyleCard c in lib.cards.where((c) => c.courses != null)) {
        expect(c.entry.cameraLimits, isEmpty,
            reason: '${c.entry.id} has measured honesty in its own document. A '
                'second, weaker block beside it would let a claim about the '
                'DANCE be read as a claim about the measurements we took.');
        expect(c.prose!.notMeasured, isNotEmpty,
            reason: '${c.entry.id} must carry the real block if it is skipping '
                'the substitute');
      }
    });

    test('hula carries neither, and that is the rule', () {
      final StyleCard hula = lib.cardFor('hula')!;
      expect(hula.entry.cameraLimits, isEmpty);
      expect(hula.entry.onHoldReason, isNotNull,
          reason: 'the page must still have something to say');
    });

    test('a camera limit never promises a future measurement', () {
      // The danger specific to this field: "a camera cannot see X" is one word
      // away from "a camera cannot see X YET", which would turn a statement
      // about a sensor into a roadmap.
      final RegExp promise = RegExp(
          r'\byet\b|\bsoon\b|coming|\bwill be able\b|\bonce we\b',
          caseSensitive: false);
      final List<String> offenders = <String>[
        for (final StyleCard c in lib.cards)
          for (final String line in c.entry.cameraLimits)
            if (promise.hasMatch(line)) '${c.entry.id}: $line',
      ];
      expect(offenders, isEmpty, reason: '$offenders');
    });

    test('and never claims a measurement we do not make', () {
      // The other direction: a limit that says "we check Y" would be a
      // capability claim smuggled into a limits list — the J-113 shape.
      final RegExp claims =
          RegExp(r'\bwe (check|measure|score|grade)\b', caseSensitive: false);
      final List<String> offenders = <String>[
        for (final StyleCard c in lib.cards)
          for (final String line in c.entry.cameraLimits)
            if (claims.hasMatch(line)) '${c.entry.id}: $line',
      ];
      expect(offenders, isEmpty, reason: '$offenders');
    });
  });
}
