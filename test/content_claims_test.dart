import 'package:choreia/app/course_catalog.dart';
import 'dart:io';
import 'dart:convert';
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

  group('a stated limit must be a REAL, SPECIFIC limit (C-168)', () {
    // NEW FAMILY BOUNDARY: *declaring a limit that does not exist is not
    // honesty, it is NOISE.* Honesty gates built one-way inflate the thing they
    // protect — a caveat on everything is a caveat nobody reads, and the real
    // limit disappears among the invented ones.
    //
    // This line carries the family's heaviest load of them: 62 limit lines
    // across 31 styles tonight, with 32 more styles queued. Measured before
    // this gate existed: mean pairwise overlap 0.023 — the lines really are
    // distinct — but ONE pair sat at 0.43, both saying "that is a timing
    // judgement, and timing needs a beat grid". Both limits are real; the
    // SENTENCE was boilerplate, and boilerplate is where inflation starts.

    const Set<String> stop = <String>{
      'the', 'a', 'an', 'and', 'or', 'is', 'it', 'of', 'to', 'in', 'that',
      'this', 'we', 'you', 'your', 'not', 'no', 'our', 'own', 'are', 'be',
      'can', 'cannot', 'what', 'which', 'for', 'with', 'on', 'at', 'as',
      'from', 'by', 'than', 'so', 'but', 'one', 'two', 'same', 'most', 'more',
      'its', 'has', 'have', 'would', 'will', 'do', 'does', 'they', 'them',
      'there', 'see', 'sees', 'seeing',
    };

    Set<String> words(String t) => RegExp(r"[a-z']+")
        .allMatches(t.toLowerCase())
        .map((RegExpMatch m) => m.group(0)!)
        .where((String w) => !stop.contains(w))
        .toSet();

    test('no two styles state the same limit in the same words', () {
      final List<MapEntry<String, String>> lines = <MapEntry<String, String>>[
        for (final StyleCard c in lib.cards)
          for (final String l in c.entry.cameraLimits)
            MapEntry<String, String>(c.entry.id, l),
      ];
      expect(lines.length, greaterThan(20),
          reason: 'too few lines for this comparison to mean anything');

      final List<String> tooAlike = <String>[];
      for (int i = 0; i < lines.length; i++) {
        for (int j = i + 1; j < lines.length; j++) {
          if (lines[i].key == lines[j].key) continue;
          final Set<String> a = words(lines[i].value);
          final Set<String> b = words(lines[j].value);
          if (a.isEmpty || b.isEmpty) continue;
          final double overlap =
              a.intersection(b).length / a.union(b).length;
          if (overlap > 0.40) {
            tooAlike.add('${lines[i].key} ↔ ${lines[j].key} '
                '(${overlap.toStringAsFixed(2)})');
          }
        }
      }
      expect(tooAlike, isEmpty,
          reason: 'these limits are stated in near-identical words: $tooAlike. '
              'Both may be real, but a boilerplate caveat reads as filler and '
              'takes the real ones down with it.');
    });

    test('a style never states the same limit twice', () {
      for (final StyleCard c in lib.cards) {
        final List<String> ls = c.entry.cameraLimits;
        for (int i = 0; i < ls.length; i++) {
          for (int j = i + 1; j < ls.length; j++) {
            final Set<String> a = words(ls[i]);
            final Set<String> b = words(ls[j]);
            if (a.isEmpty || b.isEmpty) continue;
            expect(a.intersection(b).length / a.union(b).length,
                lessThanOrEqualTo(0.40),
                reason: '${c.entry.id} says the same thing twice');
          }
        }
      }
    });

    test('a limit is a sentence about a limit, not a shrug', () {
      // The cheapest way to satisfy "every unbuilt style needs a limits box"
      // is a one-line placeholder. Length is a crude proxy, but a real limit
      // names WHAT cannot be seen and WHY, and that does not fit in six words.
      for (final StyleCard c in lib.cards) {
        for (final String l in c.entry.cameraLimits) {
          expect(l.split(' ').length, greaterThan(10),
              reason: '${c.entry.id}: "$l" is too short to name a limit and '
                  'its reason — a box filled to have a box is noise');
        }
      }
    });
  });

  group('THE OTHER LAYER: style.json user text (C-169)', () {
    // LAYER BEFORE WORDS. Every rule above reads `library.json` only, and
    // `style.json` carries 53 more pieces of user-facing text — lesson reasons,
    // honesty lines, `whyPermanent` — that no claims gate had ever seen.
    //
    // ⚠️ AND THE LIBRARY RULES DO NOT TRANSFER. Scanning this layer with them
    // produced 16 hits and ALL SIXTEEN ARE CORRECT: "we check HOW you do the
    // step" belongs in an honesty block, whose whole subject is what WE do;
    // "(not graded)" belongs in a lesson title. The no-"we" rule was written
    // for style DESCRIPTIONS, which are about the dance.
    //
    // Porting rules across layers unexamined is how a gate manufactures
    // findings — the cousin of caveat inflation, and it would have buried the
    // one rule that DOES hold here.
    List<MapEntry<String, String>> styleTexts() {
      final List<MapEntry<String, String>> out = <MapEntry<String, String>>[];
      String en(Object? v) =>
          (v is Map ? v['en'] as String? : v as String?) ?? '';
      for (final FileSystemEntity e
          in Directory('content/styles').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('style.json')) continue;
        final Map<String, dynamic> d =
            (jsonDecode(e.readAsStringSync()) as Map).cast<String, dynamic>();
        final String id = d['id'] as String;
        final Map<String, dynamic> h =
            (d['honesty'] as Map?)?.cast<String, dynamic>() ?? const {};
        for (final String k in const <String>['measured', 'notMeasured']) {
          for (final Object? t in (h[k] as List? ?? const [])) {
            out.add(MapEntry<String, String>('$id/$k', t! as String));
          }
        }
        for (final Object? lv in (d['levels'] as List? ?? const [])) {
          for (final Object? rl in ((lv! as Map)['lessons'] as List? ?? const [])) {
            final Map<String, dynamic> l = (rl! as Map).cast<String, dynamic>();
            for (final String k in const <String>[
              'demoOnlyReason', 'lockedReason', 'whyPermanent', 'displayName',
            ]) {
              final String t = en(l[k]);
              if (t.isNotEmpty) {
                out.add(MapEntry<String, String>('$id/${l['id']}.$k', t));
              }
            }
          }
        }
      }
      return out;
    }

    test('the layer is actually being read', () {
      expect(styleTexts().length, greaterThan(30),
          reason: 'this scan found almost nothing — the gate is vacuous');
    });

    test('THE RULE THAT DOES TRANSFER: no promise language, any layer', () {
      // Measured: 0 hits today, so this is a real rule being held rather than
      // a bar lowered to fit. `yet` is banned family-wide (M-F-186); the rest
      // are the same commitment worded differently.
      final RegExp promise = RegExp(
          r'\byet\b|\bsoon\b|\bwill be able\b|\bonce we\b|\bcoming\b',
          caseSensitive: false);
      final List<String> offenders = <String>[
        for (final MapEntry<String, String> t in styleTexts())
          if (promise.hasMatch(t.value)) '${t.key}: "${t.value}"',
      ];
      expect(offenders, isEmpty, reason: '$offenders');
    });

    test('"never scored" is claimed ONLY where content classes it permanent',
        () {
      // `whyPermanent` is the strongest honesty claim in the app — it says a
      // limit will not lift. It must not appear on a lesson whose class says
      // the limit is structural-and-possibly-solvable, or the two contradict
      // on the same card.
      for (final FileSystemEntity e
          in Directory('content/styles').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('style.json')) continue;
        final Map<String, dynamic> d =
            (jsonDecode(e.readAsStringSync()) as Map).cast<String, dynamic>();
        for (final Object? lv in (d['levels'] as List? ?? const [])) {
          for (final Object? rl in ((lv! as Map)['lessons'] as List? ?? const [])) {
            final Map<String, dynamic> l = (rl! as Map).cast<String, dynamic>();
            if (l['whyPermanent'] == null) continue;
            expect(l['demoOnlyClass'], 'permanent',
                reason: '${l['id']} explains why a limit is permanent while '
                    'its class says "${l['demoOnlyClass']}" — the card would '
                    'carry both claims at once');
          }
        }
      }
    });

    test('a permanent lesson SAYS why, or the class is an unsupported claim',
        () {
      // The reverse twin. Without it, `demoOnlyClass: permanent` would be a
      // bare assertion — the strongest thing this app says about a limit,
      // with nothing behind it.
      for (final StyleCard c in lib.cards) {
        for (final LessonInfo l in c.lessons) {
          if (l.demoOnlyClass != 'permanent') continue;
          expect(l.whyPermanent, isNotNull,
              reason: '${l.id} is classed permanent and never says why');
          expect(l.whyPermanent!.split(' ').length, greaterThan(10));
        }
      }
    });
  });

  group('a shipped claim must break when it STOPS being true (C-170)', () {
    // NEW CRITERION (J-133): for a sentence already shipped, ask what the most
    // PLAUSIBLE change is that would turn it into a lie. If that change is
    // plausible, a gate is owed — nobody decides to start lying, they make a
    // fix and a sentence quietly stops matching.
    //
    // Applied to the 62 limit lines, two candidates:
    //
    //   A. A style gains an authored `style.json`. Already covered: C-161
    //      forbids `cameraLimits` on any style with a real honesty block, so
    //      building content makes the suite red until the substitute is
    //      removed. Verified by construction, not by hope.
    //
    //   B. THE BEAT GRID LANDS. Three limits say a beat grid is something we
    //      do not have — and resolving it is on the founder's queue TODAY
    //      (`tools/beat_annotate.py`, ~10 minutes). Nothing tied those
    //      sentences to the content state that makes them true, so the day the
    //      tap happens, three shipped claims become false and every gate stays
    //      green. That is the gap this group closes.

    test('claims about an absent beat grid are tied to its actual state', () {
      final List<MapEntry<String, String>> claims = <MapEntry<String, String>>[
        for (final StyleCard c in lib.cards)
          for (final String l in c.entry.cameraLimits)
            if (l.toLowerCase().contains('beat grid'))
              MapEntry<String, String>(c.entry.id, l),
      ];
      expect(claims, isNotEmpty,
          reason: 'no line mentions a beat grid — this gate would then be '
              'measuring nothing (family lesson 4)');

      // The content state those sentences depend on. While BOTH of these say
      // unresolved, the claims are true; the moment either resolves, they must
      // be re-read rather than left standing.
      final Map<String, dynamic> style = (jsonDecode(
              File('content/styles/salsa_shines/style.json').readAsStringSync())
          as Map).cast<String, dynamic>();
      final Map<String, dynamic> step = (jsonDecode(File(
                  'content/styles/salsa_shines/steps/ss_shine_footwork.json')
              .readAsStringSync()) as Map)
          .cast<String, dynamic>();

      expect('${style['bpmStatus']}', startsWith('DISPUTED'),
          reason: 'the BPM is resolved now, so ${claims.length} shipped limit '
              'lines saying we have no beat grid may be false: '
              '${claims.map((MapEntry<String, String> e) => e.key).toList()}. '
              'Re-read them before clearing this.');
      expect('${step['beatsStatus']}', startsWith('PENDING'),
          reason: 'beats are filled in now — same re-read is owed');
      expect(step['beats'], isNull,
          reason: 'a beat grid exists in content while three styles tell the '
              'user there is none');
    });

    test('and the style-level ship gate agrees with those sentences', () {
      // A second, independent tie. If the two ever disagree, one of them is
      // already wrong and the suite should say so rather than pick a winner.
      final Map<String, dynamic> style = (jsonDecode(
              File('content/styles/salsa_shines/style.json').readAsStringSync())
          as Map).cast<String, dynamic>();
      final List<Object?> gates = style['shipGates'] as List? ?? const [];
      final Iterable<Map<String, dynamic>> bpm = <Map<String, dynamic>>[
        for (final Object? g in gates)
          (g! as Map<String, dynamic>),
      ].where((Map<String, dynamic> g) => g['gate'] == 'bpmResolved');

      expect(bpm, hasLength(1),
          reason: 'the bpmResolved gate is gone — the limit lines that lean on '
              'it need re-reading');
      expect(bpm.first['blocked'], isTrue,
          reason: 'the BPM gate has opened while three styles still tell the '
              'user we have no beat grid');
    });
  });
}
