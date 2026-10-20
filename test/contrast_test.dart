import 'dart:io';
import 'dart:math' as math;
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Arithmetic checks of real semantic tokens, including composited decoration.
// These do not certify rendered fonts, video frames or native screen readers.
void main() {
  double luminance(Color color) {
    double channel(double c) => c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
    return .2126 * channel(color.r) + .7152 * channel(color.g) + .0722 * channel(color.b);
  }
  double contrast(Color a, Color b) {
    final x = luminance(a), y = luminance(b);
    return (math.max(x, y) + .05) / (math.min(x, y) + .05);
  }
  Color over(Color foreground, Color background) => Color.alphaBlend(foreground, background);
  List<double> alphasInUse() {
    final pattern = RegExp(r'ChoreiaPalette\.of\(context\)\.text\(\s*([0-9.]+)\s*\)');
    return {
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          for (final match in pattern.allMatches(entity.readAsStringSync())) double.parse(match[1]!),
    }.toList();
  }
  test('contrast instrument and source inventory are nonempty', () {
    expect(contrast(Colors.white, Colors.black), closeTo(21, .001));
    expect(over(Colors.transparent, Colors.black), Colors.black);
    expect(alphasInUse().length, greaterThan(10));
  });
  for (final entry in {'light': ChoreiaPalette.light, 'dark': ChoreiaPalette.dark}.entries) {
    final p = entry.value;
    final backdrop = over(p.glowWarm.withValues(alpha: p.glowWarmAlpha), over(p.rose.withValues(alpha: p.glowRoseAlpha), p.stage));
    final surfaces = [p.stage, p.raisedSurface, backdrop,
      over(p.rose.withValues(alpha: p.panelTintAlpha), backdrop),
      over(Colors.white.withValues(alpha: p.panelWhiteAlpha), backdrop),
    ];
    test('${entry.key}: every requested text alpha clears 4.5 on composed surfaces', () {
      for (final surface in surfaces) {
        for (final alpha in alphasInUse()) {
          expect(contrast(over(p.text(alpha), surface), surface), greaterThanOrEqualTo(4.5), reason: '${entry.key} alpha $alpha on $surface');
        }
        expect(contrast(p.bright, surface) / contrast(over(p.text(0), surface), surface), greaterThanOrEqualTo(1.7));
      }
      expect(p.text(.2).a, closeTo(p.textAlphaFloor, .001));
      expect(p.text(.95).a, greaterThan(p.text(.8).a));
    });
    test('${entry.key}: all badge states stay readable filled and unfilled', () {
      for (final surface in surfaces) {
        for (final filled in [false, true]) {
          final bg = filled ? over(p.pillFill.withValues(alpha: p.pillFillAlpha), surface) : surface;
          for (final badge in StyleBadge.values) {
            final tone = badgeTone(badge, palette: p);
            expect(contrast(over(tone, bg), bg), greaterThanOrEqualTo(4.5), reason: '${entry.key} $badge filled=$filled');
          }
          final demo = contrast(badgeTone(StyleBadge.openUngraded, palette: p), bg);
          final scored = contrast(badgeTone(StyleBadge.scored, palette: p), bg);
          expect(demo / scored, inInclusiveRange(.85, 1.05));
        }
      }
    });
    test('${entry.key}: errors, focus and active button labels stay legible', () {
      for (final surface in surfaces) {
        expect(contrast(p.error, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.focusRing, surface), greaterThanOrEqualTo(3));
      }
      expect(contrast(p.stage, p.rose), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onErrorContainer, p.errorContainer), greaterThanOrEqualTo(4.5));
    });
    testWidgets('${entry.key}: rendered style defaults resolve from their own tree', (tester) async {
      late Color body, label, display;
      await tester.pumpWidget(MaterialApp(theme: entry.key == 'dark' ? ChoreiaTheme.dark : ChoreiaTheme.light,
        home: Builder(builder: (context) {
          body = ChoreiaType.of(context).body().color!;
          label = ChoreiaType.of(context).label().color!;
          display = ChoreiaType.of(context).display().color!;
          return const Scaffold();
        })));
      expect(body, p.text(.78)); expect(label, p.text(.55)); expect(display, p.bright);
      expect(tester.takeException(), isNull);
    });
  }
}
