import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Are the honest states actually VISIBLE?
///
/// The transfer that produced this file (JabLab J-114) is short: an "no
/// analysis at all" icon measured 1.80:1 against its background, WCAG 1.4.11
/// asks 3.0 for non-text, and the icon was in practice invisible. Its test
/// could not see it because it asserted that three colours DIFFERED — `Color`
/// identity. All three did differ. One of them simply could not be seen.
///
/// **An honest state nobody can see is the same as saying nothing.**
///
/// Why this file is not optional here: this line's brief makes a VISUAL promise
/// by name — "demo-only İKİNCİ SINIF GÖRÜNMEZ — tam bir ders, yalnız skoru
/// yok". That is a contrast claim, and until now nothing measured it. It was a
/// hand-written assumption with nothing verifying it — the exact shape C-153
/// cleaned out of this suite's exemption lists.
///
/// TWO METHOD NOTES, both carried from JabLab:
///   1. Compute from the colour that ACTUALLY LANDS ON SCREEN — composite every
///      alpha onto what is behind it. Reading `Color.alpha` and calling it a
///      contrast is how 1.80:1 passed review.
///   2. The threshold is NOT invented. WCAG is an external standard and the
///      formula below is the standard's own.
///
/// AND THE LIMIT: WCAG measures LUMINANCE, not "can these two be told apart".
/// This file closes visibility. Whether amber reads as different from rose is
/// an eye question and stays one.
void main() {
  // ── WCAG 2.1, verbatim ───────────────────────────────────────────────

  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  double contrast(Color a, Color b) {
    final double la = luminance(a), lb = luminance(b);
    final double hi = math.max(la, lb), lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// `fg` painted over `bg` — the colour a camera would read off the screen.
  Color over(Color fg, Color bg) {
    final double a = fg.a;
    return Color.from(
      alpha: 1,
      red: fg.r * a + bg.r * (1 - a),
      green: fg.g * a + bg.g * (1 - a),
      blue: fg.b * a + bg.b * (1 - a),
    );
  }

  // ── The stack a pill actually sits on ────────────────────────────────
  //
  // Worst case is the LIGHTEST backdrop, because every foreground here is
  // light: the backdrop's drifting blob reaches alpha 0.30 and a GlassPanel
  // adds its own tint on top. Measuring against bare `stage` would flatter
  // every number on this screen.

  final Color stage = ChoreiaColors.stage;
  final Color litBackdrop =
      over(ChoreiaColors.rose.withValues(alpha: 0.18), stage);
  final Color panel =
      over(ChoreiaColors.rose.withValues(alpha: 0.06), litBackdrop);

  /// Every alpha any view actually asks [ChoreiaColors.text] for, READ FROM THE
  /// SOURCE.
  ///
  /// Not a literal list (C-153): a hand-written set of "alphas we use" is an
  /// assumption with nothing checking it, and the next screen written would not
  /// be in it. Scanning `lib/` means a call site added tomorrow is measured
  /// tomorrow.
  List<double> textAlphasInUse() {
    final RegExp call = RegExp(r'ChoreiaColors\.text\(\s*([0-9.]+)\s*\)');
    final Set<double> out = <double>{};
    for (final FileSystemEntity f
        in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final RegExpMatch m in call.allMatches(f.readAsStringSync())) {
        final double? v = double.tryParse(m.group(1)!);
        if (v != null) out.add(v);
      }
    }
    return out.toList()..sort();
  }

  /// The background a `StatusPill`'s text is read against.
  ///
  /// Takes no tone on purpose — the filled variant darkens with a scrim rather
  /// than tinting with the tone (C-156), so a badge added tomorrow inherits
  /// this floor instead of needing its own measurement. Reading the constant
  /// from the widget rather than restating 0.25 keeps the two from drifting.
  Color pillBackground({required Color on, required bool filled}) => filled
      ? over(const Color(0xFF000000).withValues(alpha: StatusPill.fillScrim), on)
      : on;

  test('the compositor is right before anything is judged by it', () {
    // Guards the instrument. Black on white is 21:1 by definition; a fully
    // transparent foreground must leave the background untouched.
    expect(contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01));
    expect(contrast(stage, stage), closeTo(1, 0.001));
    expect(over(const Color(0x00FFFFFF), stage), stage,
        reason: 'a zero-alpha foreground must composite to the background — if '
            'this fails every number below is measured against the wrong '
            'colour');
    // And compositing must actually MOVE the colour, or every check passes by
    // comparing something to itself.
    expect(over(const Color(0x80FFFFFF), stage), isNot(stage));
  });

  group('THE PROMISE: demo-only is not second class', () {
    test('the demo-only badge is legible where it is used', () {
      const Color tone = ChoreiaColors.amber;
      final Color bg = pillBackground(on: panel, filled: true);
      final double ratio = contrast(tone, bg);

      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'the pill label is ~9.5px — normal text by WCAG 1.4.3, so '
              '4.5:1. Measured $ratio. This badge is the most common label in '
              "the app and the brief promises it does not look second class.");
    });

    test('EVERY badge label clears the text threshold, not just this one', () {
      // Written after the first run of this file measured the SCORED badge at
      // 3.70 — lower than the demo-only badge it is supposed to outrank. A
      // gate aimed only at the badge the brief names would have left the
      // others failing, which is how one measured promise hides four unmeasured
      // ones.
      for (final StyleBadge b in StyleBadge.values) {
        final Color tone = badgeTone(b);
        final Color bg = pillBackground(on: panel, filled: true);
        expect(contrast(over(tone, bg), bg), greaterThanOrEqualTo(4.5),
            reason: '$b at ${contrast(over(tone, bg), bg).toStringAsFixed(2)}:1');
      }
    });

    test('demo-only is not dimmer than the graded badge it sits beside', () {
      // The promise is comparative, so the measurement has to be too. A badge
      // that clears 4.5 while the graded one clears 9 still LOOKS lesser.
      final Color bg = pillBackground(on: panel, filled: true);
      final double demo = contrast(ChoreiaColors.amber, bg);
      final double scored = contrast(ChoreiaColors.rose, bg);

      expect(demo, greaterThanOrEqualTo(scored * 0.8),
          reason: 'demo-only ($demo) reads markedly fainter than graded '
              '($scored). "Not second class" is a visual claim, and a large '
              'contrast gap breaks it even when both are technically legible.');
    });
  });

  group('the other honest states are visible at all', () {
    test('every library badge tone clears the non-text threshold', () {
      // 1.4.11 (3.0) rather than 4.5: these are the compact tiles, where the
      // pill is unfilled and reads as a marker as much as a word. The stricter
      // 4.5 is applied above to the badge the brief makes a promise about.
      for (final StyleBadge b in StyleBadge.values) {
        final Color tone = badgeTone(b);
        final Color bg = pillBackground(on: litBackdrop, filled: false);
        final double ratio = contrast(over(tone, bg), bg);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '$b renders at ${ratio.toStringAsFixed(2)}:1 — an honest '
                'state nobody can see is the same as saying nothing');
      }
    });
  });

  group('THE PATTERN, not one example (C-157)', () {
    // C-156 measured the badge the brief names and called the class closed.
    // JabLab hit the same wall one round later and named it: "I fixed the
    // EXAMPLE, not the PATTERN". Measured here afterwards: 40 call sites across
    // every screen were below the floor, and `ChoreiaType.label`'s own DEFAULT
    // was one of them — the shared token, inherited by 14 bare call sites.

    test('the scan finds real call sites', () {
      final List<double> alphas = textAlphasInUse();
      expect(alphas.length, greaterThan(10),
          reason: 'if this regex stops matching, every assertion below passes '
              'by measuring nothing (family lesson 4)');
    });

    test('EVERY text alpha any view asks for is legible', () {
      for (final double asked in textAlphasInUse()) {
        // Through the real token, so the clamp is part of what is measured —
        // testing the raw number would measure a colour the app never draws.
        final Color c = ChoreiaColors.text(asked);
        for (final MapEntry<String, Color> bg in <String, Color>{
          'panel': panel,
          'backdrop': litBackdrop,
        }.entries) {
          final Color rendered = over(c, bg.value);
          expect(contrast(rendered, bg.value), greaterThanOrEqualTo(4.5),
              reason: 'text($asked) on ${bg.key} renders '
                  '${contrast(rendered, bg.value).toStringAsFixed(2)}:1');
        }
      }
    });

    test('the shared type defaults are legible too', () {
      // `ChoreiaType.label()` defaulted to text(0.45) and 14 call sites used it
      // bare. This is the exact shape of JabLab's `JText.mono` default.
      // The named tokens, NOT `ChoreiaType.label()` — building the TextStyle
      // would pull google_fonts into a plain `test`, and the colour is the
      // whole claim. Both the widget and this line read the same constant, so
      // they cannot drift.
      for (final MapEntry<String, Color> e in <String, Color>{
        'label': ChoreiaType.labelDefaultColor,
        'body': ChoreiaType.bodyDefaultColor,
      }.entries) {
        final Color c = e.value;
        expect(contrast(over(c, panel), panel), greaterThanOrEqualTo(4.5),
            reason: '${e.key}() default renders '
                '${contrast(over(c, panel), panel).toStringAsFixed(2)}:1 for '
                'every surface that uses it without naming a colour');
      }
    });

    test('HIERARCHY SURVIVES the floor', () {
      // The cheap way to pass every check above is to drag everything to the
      // brightest tone, trading legibility for a flat page. The ramp has to
      // stay a ramp.
      final double brightest = contrast(ChoreiaColors.bright, panel);
      final Color floor = ChoreiaColors.text(ChoreiaColors.minReadableAlpha);
      final double faintest = contrast(over(floor, panel), panel);

      expect(faintest, greaterThanOrEqualTo(4.5));
      expect(brightest / faintest, greaterThanOrEqualTo(2.0),
          reason: 'primary and faintest are only '
              '${(brightest / faintest).toStringAsFixed(2)}x apart — the page '
              'has been flattened to pass a contrast gate');
    });

    test('the floor is a FLOOR, not a rewrite of the ramp', () {
      // Above the floor, a call site's own number must still decide. If the
      // clamp ever applied everywhere, hierarchy would be gone silently.
      expect(ChoreiaColors.text(0.86).a, greaterThan(ChoreiaColors.text(0.60).a));
      expect(ChoreiaColors.text(0.20).a,
          closeTo(ChoreiaColors.minReadableAlpha, 0.001),
          reason: 'a sub-floor request must be lifted TO the floor, not left '
              'alone and not pushed to full opacity');
    });
  });
}
