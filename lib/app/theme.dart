import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'theme_palette.dart';
export 'theme_palette.dart';

/// Choreia's visual language — design panel v1, 2026-08-05
/// (`docs/design/DESIGN-PANEL-PROMPT.md`; `claude.ai/design` project
/// `choreia`, file `Choreia.dc.html`).
///
/// STYLE ONLY. Nothing in this file changes what a screen's tests can find —
/// every widget below is a decoration or a motion primitive that another
/// file's existing state, Keys and copy get wrapped in. See `live_view.dart`
/// and `progress_view.dart` for the actual restyle; they inherit their
/// structure from before this file existed and keep it unchanged.
///
/// The one rule this file exists to hold the line on (design brief §1, the
/// "kardeş çakışması" clause): Choreia's glass is TRANSPARENT — blur never
/// exceeds 3px, [GlassPanel.blur]'s default — and its motion FLOWS. JabLab,
/// the family's other dark-and-glass app, is frosted and cuts on snap; no
/// curve in this file bounces or overshoots, and no opacity jumps untweened.

// ── Colour ───────────────────────────────────────────────────────────────

abstract final class ChoreiaColors {
  ChoreiaColors._();

  static const Color stage = Color(0xFF0A0508);
  static const Color oxblood = Color(0xFF2A1220);

  /// Judgement — a lesson or a live reading that carries a verdict. Never
  /// applied to something merely open: the two tones are a status language
  /// and design brief §2 is explicit that they do not mix on one element.
  static const Color rose = Color(0xFFF0A6BD);
  static const Color roseBright = Color(0xFFF6B9CB);
  static const Color roseDeep = Color(0xFFE8A2B6);

  /// Open-but-ungraded, in-preparation, or "we cannot check this right now"
  /// — a status, not a warning.
  static const Color amber = Color(0xFFECC49B);
  static const Color amberDeep = Color(0xFFE6C49A);

  static const Color bright = Color(0xFFFBF2F5);
  static const Color _base = Color(0xFFF6EEF1);

  /// The faintest text this app will draw, whatever a call site asks for.
  ///
  /// Measured 2026-08-07 against the worst-case backdrop: below this, body and
  /// label text falls under the 4.5:1 that WCAG 1.4.3 asks of type this size.
  /// At this value the same text renders 4.66:1, and [bright] still sits 2.59x
  /// above it — so the ramp keeps its hierarchy instead of flattening to one
  /// safe tone, which is the cheap way to pass a contrast gate and the wrong
  /// one.
  static const double minReadableAlpha = 0.55;

  /// Body text at a named opacity — CLAMPED to [minReadableAlpha].
  ///
  /// The clamp lives here rather than at the call sites on purpose (C-157).
  /// 40 call sites asked for something below the floor, spread across every
  /// screen, and the first fix of this class went only to the badge the brief
  /// named — fixing the EXAMPLE and leaving the PATTERN. A floor on the token
  /// covers the 40, and covers the ones written next week too.
  ///
  /// Call sites keep their own number because it still carries INTENT: 0.42
  /// means "the quietest thing here" and stays quieter than 0.78 wherever both
  /// clear the floor. What they can no longer do is ask for invisible.
  static Color text(double opacity) => _base.withValues(
        alpha: opacity < minReadableAlpha ? minReadableAlpha : opacity,
      );

  static Color hairline(double opacity) =>
      Colors.white.withValues(alpha: opacity);
}

// ── Type ─────────────────────────────────────────────────────────────────

/// Three families, three jobs (design notes, "Tipografi ölçeği"): serif for
/// what the learner reads as a headline or a count, sans for body and
/// buttons, mono for anything that is a MEASUREMENT or a STATUS — never a
/// feeling. Mixing them tells "this is a fact" from "this is prose" before
/// the words are read.
abstract final class ChoreiaType {
  ChoreiaType._();
  static ChoreiaTypography of(BuildContext context) => ChoreiaTypography(
      ChoreiaPalette.of(context),
      Localizations.maybeLocaleOf(context)?.languageCode ?? 'en');

  /// The colours [body] and [label] fall back to when a call site names none.
  ///
  /// Named constants rather than literals inside the factories so the contrast
  /// gate can read the SAME value the widget draws. `label` in particular is
  /// used bare by 14 call sites; that made its default a shared token, and a
  /// shared token nobody measures is how JabLab shipped a 3.51:1 default
  /// across a whole screen (J-116).
  static final Color bodyDefaultColor = ChoreiaColors.text(0.78);
  static final Color labelDefaultColor = ChoreiaColors.text(0.55);

  static TextStyle display(
          {double size = 34, Color? color, double height = 1.06}) =>
      TextStyle(
        fontFamily: 'Instrument Serif',
        fontSize: size,
        height: height,
        color: color ?? ChoreiaColors.bright,
        letterSpacing: -0.2,
      );

  static TextStyle body(
          {double size = 13.5,
          Color? color,
          FontWeight weight = FontWeight.w400,
          double height = 1.55}) =>
      TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        height: height,
        fontWeight: weight,
        color: color ?? bodyDefaultColor,
      );

  /// Measurement/status language. `letterSpacing` is an em-multiplier here
  /// (matching the design's CSS `em` units), converted to Flutter's absolute
  /// logical pixels by the font size — so the tracking stays proportional at
  /// every size the way it does in the source spec.
  static TextStyle label(
          {double size = 10, Color? color, double letterSpacingEm = 0.16}) =>
      TextStyle(
        fontFamily: 'IBM Plex Mono',
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: letterSpacingEm * size,
        color: color ?? labelDefaultColor,
      );
}

/// Context-bound typography keeps independent app trees and scripts separate.
class ChoreiaTypography {
  const ChoreiaTypography(this.palette, this.language);
  final ChoreiaPalette palette;
  final String language;
  bool get untracked => const {'ar', 'hi', 'ja', 'ko', 'zh'}.contains(language);
  TextStyle display({double size = 34, Color? color, double height = 1.06}) =>
      ChoreiaType.display(
              size: size, color: color ?? palette.bright, height: height)
          .copyWith(letterSpacing: untracked ? 0 : -0.2);
  TextStyle body(
          {double size = 13.5,
          Color? color,
          FontWeight weight = FontWeight.w400,
          double height = 1.55}) =>
      ChoreiaType.body(
          size: size,
          color: color ?? palette.text(.78),
          weight: weight,
          height: height);
  TextStyle label(
          {double size = 10, Color? color, double letterSpacingEm = .16}) =>
      ChoreiaType.label(
          size: size,
          color: color ?? palette.text(.55),
          letterSpacingEm: untracked ? 0 : letterSpacingEm);
}

// ── Motion ───────────────────────────────────────────────────────────────

/// Numbers straight from the design's "Hareket spec'i" panel. What is absent
/// matters as much as what is here: no bounce/elastic curve appears anywhere
/// in this file (see the file doc comment).
abstract final class ChoreiaMotion {
  ChoreiaMotion._();

  static const Duration sceneGlow = Duration(seconds: 19);
  static const Duration sceneGlowReverse = Duration(seconds: 26);
  static const Duration breathe = Duration(milliseconds: 2400);
  static const Duration ringTurn = Duration(seconds: 12);
  static const Duration screenTransition = Duration(milliseconds: 400);

  /// cubic-bezier(.4,0,.2,1) — Flutter ships this exact curve pre-named.
  static const Curve transition = Curves.fastOutSlowIn;
}

/// A child that scales gently between 1.0 and [peak] forever — the design's
/// "nefes" (breath), used for live counts and idle rings. Not a spinner: it
/// never implies progress toward completion, only "this is alive and
/// listening."
class SlowBreath extends StatefulWidget {
  const SlowBreath({
    super.key,
    required this.child,
    this.peak = 1.07,
    this.duration = ChoreiaMotion.breathe,
  });

  final Widget child;
  final double peak;
  final Duration duration;

  @override
  State<SlowBreath> createState() => _SlowBreathState();
}

class _SlowBreathState extends State<SlowBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else {
      _c.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SlowBreath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _c.duration = widget.duration;
      if (_reduceMotion == false) _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: 1 + (widget.peak - 1) * Curves.easeInOut.transform(_c.value),
          child: child,
        ),
      );
}

/// A full, steady rotation forever — the live-tour tracking ring. Linear on
/// purpose: a ring that eases would read as arriving somewhere, and this one
/// never does.
class SlowSpin extends StatefulWidget {
  const SlowSpin({
    super.key,
    required this.child,
    this.duration = ChoreiaMotion.ringTurn,
  });

  final Widget child;
  final Duration duration;

  @override
  State<SlowSpin> createState() => _SlowSpinState();
}

class _SlowSpinState extends State<SlowSpin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else {
      _c.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SlowSpin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _c.duration = widget.duration;
      if (_reduceMotion == false) _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _c, child: widget.child);
}

/// The stage-light backdrop: two soft, warm blobs drifting in slow, opposite
/// loops behind the glass. This is the "arkası görünür" (see-through) layer
/// the brief asks for — [GlassPanel]s sit on top of THIS, not a flat colour,
/// which is what makes their blur read as glass rather than a tinted box.
class ChoreiaBackdrop extends StatefulWidget {
  const ChoreiaBackdrop({super.key, this.child});

  final Widget? child;

  @override
  State<ChoreiaBackdrop> createState() => _ChoreiaBackdropState();
}

class _ChoreiaBackdropState extends State<ChoreiaBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: ChoreiaMotion.sceneGlow);
  late final AnimationController _b = AnimationController(
      vsync: this, duration: ChoreiaMotion.sceneGlowReverse);
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    for (final AnimationController controller in <AnimationController>[
      _a,
      _b
    ]) {
      if (reduceMotion) {
        controller.stop();
        controller.value = 0;
      } else {
        controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: ChoreiaPalette.of(context).stage,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _blob(_a,
                alignment: const Alignment(-0.75, -0.9),
                color: ChoreiaPalette.of(context).rose,
                size: 460,
                peakAlpha: ChoreiaPalette.of(context).glowRoseAlpha),
            _blob(_b,
                alignment: const Alignment(0.85, 0.95),
                color: ChoreiaPalette.of(context).glowWarm,
                size: 420,
                peakAlpha: ChoreiaPalette.of(context).glowWarmAlpha,
                reverse: true),
            if (widget.child != null) widget.child!,
          ],
        ),
      );

  Widget _blob(
    AnimationController c, {
    required Alignment alignment,
    required Color color,
    required double size,
    required double peakAlpha,
    bool reverse = false,
  }) =>
      AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final double t = Curves.easeInOut.transform(c.value);
          final double dx = (reverse ? -1 : 1) * (0.09 - 0.18 * t);
          final double dy = 0.05 - 0.1 * t;
          return Align(
            alignment: Alignment(alignment.x + dx, alignment.y + dy),
            child: Transform.scale(
              scale: 1 + 0.14 * t,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      // 0.18, not 0.30 (C-157). The blob is DECORATION and the
                      // text on top of it is CONTENT; at 0.30 its peak lifted
                      // the background far enough that muted text needed alpha
                      // 0.66 to stay legible, which would have flattened the
                      // whole type ramp. Dimming the decoration bought the
                      // floor back down to 0.55 and RAISED the hierarchy
                      // spread from 1.86x to 2.59x — the trade runs the right
                      // way round.
                      color.withValues(alpha: peakAlpha),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

// ── Glass ────────────────────────────────────────────────────────────────

/// One glass card/panel — the shared decoration primitive for both restyled
/// screens. Radius follows the design's three named sizes (design notes,
/// "Şeffaf cam spesifikasyonu"): 14 for a tile, 18 for a panel (the default),
/// 22 for a hero card.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 18,
    this.tint,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.blur = 3,
  });

  final Widget child;
  final double radius;
  final Color? tint;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  /// Sigma for the backdrop blur. Design brief §1's line in the sand against
  /// JabLab's frosted glass: this stays at 3 everywhere it is not explicitly
  /// overridden, and nothing in this app overrides it upward.
  final double blur;

  @override
  Widget build(BuildContext context) {
    final Color base = tint ?? ChoreiaPalette.of(context).rose;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                // 0.06, not 0.09 — same reasoning as the backdrop blob
                // (C-157): a panel tint that lightens the surface is paid for
                // by every string sitting on it.
                base.withValues(
                    alpha: ChoreiaPalette.of(context).panelTintAlpha),
                Colors.white.withValues(
                    alpha: ChoreiaPalette.of(context).panelWhiteAlpha),
              ],
            ),
            border: Border.all(
                color:
                    borderColor ?? ChoreiaPalette.of(context).hairline(0.13)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: ChoreiaPalette.of(context).shadowAlpha),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A ring with a glyph at its centre — the shared shape for "something needs
/// your attention" states (permission, camera, no-person). [breathing] gives
/// it the same slow life as a live count; a state that is not currently
/// live (idle, a settled error) can leave it still.
class StatusRing extends StatelessWidget {
  const StatusRing({
    super.key,
    required this.icon,
    this.tone,
    this.size = 64,
    this.breathing = true,
  });

  final IconData icon;
  final Color? tone;
  final double size;
  final bool breathing;

  @override
  Widget build(BuildContext context) {
    final Color c = tone ?? ChoreiaPalette.of(context).text(0.7);
    final Widget ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.4), width: 1.4),
      ),
      child: Icon(icon, color: c, size: size * 0.4),
    );
    return breathing ? SlowBreath(peak: 1.05, child: ring) : ring;
  }
}

/// A named-status pill — "SCORED", "OPEN · NOT SCORED", "NOT BUILT" and this
/// app's own live/progress equivalents. Mono type; [filled] draws the solid
/// treatment the design reserves for a state that IS, leaving the hollow
/// outline for a state that is named but not active.
///
/// THE FILL DARKENS, IT DOES NOT TINT (C-156)
/// ------------------------------------------
/// It used to be `tone.withValues(alpha: 0.14)` — the tone itself, lightening
/// the pill. On a dark app with light labels that works against legibility:
/// every pill raised its own background toward its own text. Measured against
/// the worst-case backdrop (drifting blob at peak, plus a GlassPanel tint), the
/// scored badge came out at **3.70:1** and the demo-only badge at **4.25:1**,
/// both under the 4.5 WCAG 1.4.3 asks of text this size — and the brief makes a
/// promise about the second one by name.
///
/// A scrim fixes every tone at once, which a per-tone tweak could not: the fill
/// no longer depends on the tone, so a badge added tomorrow inherits the floor
/// instead of needing its own measurement. The palette is untouched — same
/// hues, same border, same type.
class StatusPill extends StatelessWidget {
  const StatusPill(
      {super.key, required this.label, required this.tone, this.filled = true});

  final String label;
  final Color tone;
  final bool filled;

  /// How far the filled variant darkens what is behind it. Pinned by
  /// `contrast_test.dart`; lowering it lowers every badge in the app.
  static const double fillScrim = 0.25;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: filled
              ? ChoreiaPalette.of(context)
                  .pillFill
                  .withValues(alpha: ChoreiaPalette.of(context).pillFillAlpha)
              : null,
          border:
              Border.all(color: tone.withValues(alpha: filled ? 0.4 : 0.55)),
        ),
        child: Text(label,
            style: ChoreiaType.of(context)
                .label(size: 9.5, color: tone, letterSpacingEm: 0.1)),
      );
}

/// A title beside its status pill — which becomes a title ABOVE its status
/// pill when there is not room for both.
///
/// Why not a `Row` with an `Expanded` title (C-158)
/// -----------------------------------------------
/// That was the shape in all three places this is used, and it overflowed by
/// 62px at 2x text scale: `Expanded` makes the TITLE yield, but the pill beside
/// it is rigid, and at large text the pill alone is wider than the row.
///
/// The obvious repairs are both wrong here. Truncating the pill would clip a
/// status label — "OPEN · NOT GRADED" cut to "OPEN · NOT" is worse than no
/// badge at all, and this app's badges are the honesty surface. Truncating the
/// title hides which lesson you are looking at. `Wrap` is the only arrangement
/// that keeps BOTH whole: they sit side by side while they fit, and the pill
/// drops to its own line when they do not.
class TitleWithPill extends StatelessWidget {
  const TitleWithPill({super.key, required this.title, required this.pill});

  final Widget title;
  final Widget pill;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 10,
        runSpacing: 8,
        children: <Widget>[title, pill],
      );
}

// ── App theme ────────────────────────────────────────────────────────────

/// Material and custom surfaces share the same immutable semantic palette.
abstract final class ChoreiaTheme {
  ChoreiaTheme._();
  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final p = brightness == Brightness.dark
        ? ChoreiaPalette.dark
        : ChoreiaPalette.light;
    return SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness,
        systemNavigationBarColor: p.stage,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark);
  }

  static ThemeData get light => _build(Brightness.light, ChoreiaPalette.light);
  static ThemeData get dark => _build(Brightness.dark, ChoreiaPalette.dark);
  static ThemeData _build(Brightness brightness, ChoreiaPalette p) {
    final scheme =
        ColorScheme.fromSeed(seedColor: p.rose, brightness: brightness)
            .copyWith(
      primary: p.rose,
      onPrimary: p.stage,
      secondary: p.amber,
      onSecondary: p.stage,
      surface: p.stage,
      onSurface: p.ink,
      surfaceContainerHighest: p.raisedSurface,
      error: p.error,
      onError: p.stage,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onErrorContainer,
      outline: p.outline,
      outlineVariant: p.hairline(.3),
    );
    final base = ThemeData(
        useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final text = base.textTheme.apply(
        fontFamily: 'Manrope', bodyColor: p.text(.86), displayColor: p.bright);
    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[p],
      scaffoldBackgroundColor: p.stage,
      canvasColor: p.stage,
      textTheme: text,
      disabledColor: p.disabledForeground,
      dividerColor: p.hairline(.2),
      focusColor: p.focusRing.withValues(alpha: .2),
      hoverColor: p.rose.withValues(alpha: .08),
      highlightColor: p.rose.withValues(alpha: .12),
      splashColor: p.rose.withValues(alpha: .16),
      appBarTheme: AppBarTheme(
        backgroundColor: p.stage,
        foregroundColor: p.bright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: ChoreiaType.display(size: 22, color: p.bright),
        iconTheme: IconThemeData(color: p.text(.8)),
        systemOverlayStyle: overlayFor(brightness),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled) ? p.disabledSurface : p.rose),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? p.disabledForeground
                : p.stage),
        textStyle: WidgetStatePropertyAll(ChoreiaType.body(
            size: 14, weight: FontWeight.w600, color: p.stage)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 50)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        side: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.focused)
                ? BorderSide(color: p.focusRing, width: 2)
                : BorderSide.none),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.raisedSurface.withValues(alpha: .5),
        labelStyle: TextStyle(color: p.text(.85)),
        hintStyle: TextStyle(color: p.text(.72)),
        helperStyle: TextStyle(color: p.text(.78)),
        errorStyle: TextStyle(color: p.error),
        border: OutlineInputBorder(borderSide: BorderSide(color: p.outline)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: p.focusRing, width: 2)),
        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: p.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: p.error, width: 2)),
      ),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: p.rose,
          selectionColor: p.rose.withValues(alpha: .25),
          selectionHandleColor: p.rose),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: p.raisedSurface,
          indicatorColor: p.rose.withValues(alpha: .14)),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: p.raisedSurface,
          contentTextStyle: text.bodyMedium,
          actionTextColor: p.rose),
      dialogTheme: DialogThemeData(
          backgroundColor: p.stage, surfaceTintColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(
          color: p.stage,
          textStyle: text.bodyMedium,
          surfaceTintColor: Colors.transparent),
    );
  }
}
