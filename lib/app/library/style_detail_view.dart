import 'package:flutter/material.dart';

import '../course_catalog.dart';
import '../live/live_lesson_page.dart';
import '../shell/choreia_page_route.dart';
import '../theme.dart';
import 'library_catalog.dart';
// For the badge vocabulary only. The catalogue screen owns those words, and a
// style page that invented its own would let a tile and its page disagree about
// what the same style is called.
import 'library_view.dart';

/// One style's page.
///
/// THE ATTRIBUTION BOX IS CONTENT, NOT CHROME
/// ------------------------------------------
/// Every style here belongs to people. Vogue is Black and Latino LGBTQ+
/// ballroom culture; Afrobeats, Bhangra, Hula and most of the rest carry
/// lineages that are the reason the dance exists. The brief for this screen is
/// explicit that credit is part of the material and may not be shrunk into a
/// footnote, so [_attributionSection] sits directly under the title — above the
/// lessons, above the honesty box — at full body size.
///
/// **Where content has no attribution, the box does not disappear.** It renders
/// a named gap instead. An absent box would read as a dance with no origin,
/// which is never true; a visible "we have not written this" is a debt the
/// screen carries in public. Measured 2026-08-07: attribution has since been
/// written for all 34 styles, so no page shows the gap today — the branch stays
/// tested against a synthetic card so it cannot rot before the next style lands.
///
/// THREE LESSON CLASSES, ONE CARD WEIGHT
/// -------------------------------------
/// Graded, locked and demo-only get the SAME card size, padding and title
/// treatment. Only the pill and the reason line differ. A demo-only lesson is a
/// whole lesson that happens not to produce a number — rendering it smaller or
/// greyer would say "lesser", which is the claim K10 exists to refuse.
class StyleDetailView extends StatelessWidget {
  const StyleDetailView({
    required this.card,
    this.runnableSteps = const <String>{},
    super.key,
  });

  final StyleCard card;

  /// Which steps the bundle can really serve. Passed in rather than looked up
  /// so this widget stays renderable in a test without an asset bundle.
  final Set<String> runnableSteps;

  static const Key attributionKey = Key('style.attribution');
  static const Key attributionGapKey = Key('style.attributionGap');
  static const Key honestyKey = Key('style.honesty');
  static const Key lessonsKey = Key('style.lessons');
  static const Key noLessonsKey = Key('style.noLessons');
  static const Key cautionKey = Key('style.caution');
  static const Key cameraLimitsKey = Key('style.cameraLimits');
  static const Key descriptionKey = Key('style.description');
  static const Key glossaryKey = Key('style.glossary');

  static Key lessonKey(String id) => Key('style.lesson.$id');
  static Key permanenceKey(String id) => Key('style.permanent.$id');

  @override
  Widget build(BuildContext context) {
    final List<LessonOffer> offers = card.offers(runnableSteps);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(card.entry.displayName)),
      body: ChoreiaBackdrop(
        child: SafeArea(
          child: ListView(
            // TOP PADDING IS A CONTENT MARGIN, NOT AN APPBAR OFFSET (C-154).
            //
            // It used to be 96. Measured 2026-08-07 at 375x812 with a 47pt
            // notch inset: that left 96pt of DEAD SPACE between the AppBar's
            // bottom edge and the first content. The cause is a double count —
            // `extendBodyBehindAppBar: true` makes Scaffold hand the body a top
            // inset that ALREADY INCLUDES the AppBar (47 status + 56 toolbar =
            // 103), `SafeArea` consumes all of it, and the padding then added
            // the AppBar's height a second time.
            //
            // Screen evidence found this; no test could. An overflow test asks
            // whether content fits, never whether it starts where it should.
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: <Widget>[
              _header(),
              const SizedBox(height: 20),
              if (card.entry.description != null) ...<Widget>[
                Text(card.entry.description!,
                    key: descriptionKey,
                    style: ChoreiaType.body(
                        size: 14.5, color: ChoreiaColors.text(0.82))),
                const SizedBox(height: 20),
              ],
              _attributionSection(),
              if (card.entry.stepGlossary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                _glossarySection(),
              ],
              if (_cautions().isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _cautionSection(),
              ],
              const SizedBox(height: 24),
              _lessonsSection(offers, context),
              if (card.prose != null && !card.prose!.isEmpty) ...<Widget>[
                const SizedBox(height: 24),
                _honestySection(card.prose!),
              ],
              if (card.entry.cameraLimits.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                _cameraLimitsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StatusPill(
              label: LibraryStrings.badge(card.badge), tone: _badgeTone()),
          const SizedBox(height: 12),
          Text(card.entry.displayName, style: ChoreiaType.display(size: 34)),
          if (card.entry.subDances.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            // A family page names its members rather than implying one dance.
            Text(card.entry.subDances.join(' · '),
                style: ChoreiaType.body(
                    size: 12.5, color: ChoreiaColors.text(0.6))),
          ],
          if (_statusSentence() != null) ...<Widget>[
            const SizedBox(height: 14),
            GlassPanel(
              tint: ChoreiaColors.amber,
              borderColor: ChoreiaColors.amber.withValues(alpha: 0.22),
              child: Text(_statusSentence()!,
                  style: ChoreiaType.body(
                      size: 13, color: ChoreiaColors.text(0.82))),
            ),
          ],
        ],
      );

  /// Why this style is shut, in the user's language — from the derivation, not
  /// written here. Null when the style is open, because an open style has
  /// nothing to explain.
  String? _statusSentence() =>
      card.entry.onHoldReason ?? card.view.userFacingReason;

  // ── Attribution ──────────────────────────────────────────────────────

  Widget _attributionSection() {
    final String? attribution = card.entry.originAttribution;
    final String? boundary = card.prose?.reproductionBoundary;

    return GlassPanel(
      key: attribution == null ? attributionGapKey : attributionKey,
      radius: 18,
      tint: attribution == null
          ? ChoreiaColors.text(0.2)
          : ChoreiaColors.roseDeep,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(StyleStrings.attributionTitle,
              style: ChoreiaType.label(
                  size: 10, color: ChoreiaColors.text(0.5))),
          const SizedBox(height: 10),
          Text(
            attribution ?? StyleStrings.attributionMissing,
            // Full body size in both branches. A gap rendered in small grey
            // type would be a way of apologising quietly; this one is meant to
            // be read.
            style: ChoreiaType.body(
                size: 13.5,
                color: ChoreiaColors.text(attribution == null ? 0.62 : 0.85)),
          ),
          if (boundary != null) ...<Widget>[
            const SizedBox(height: 14),
            Divider(color: ChoreiaColors.hairline(0.10), height: 1),
            const SizedBox(height: 14),
            Text(StyleStrings.boundaryTitle,
                style: ChoreiaType.label(
                    size: 10, color: ChoreiaColors.text(0.45))),
            const SizedBox(height: 8),
            // Kept BELOW a divider and under its own heading: clearance
            // reasoning is not credit, and letting it sit in the attribution
            // paragraph would let "we are allowed to teach this" read as
            // "we have said whose it is".
            Text(boundary,
                style: ChoreiaType.body(
                    size: 12.5, color: ChoreiaColors.text(0.68))),
          ],
        ],
      ),
    );
  }

  // ── Step glossary ────────────────────────────────────────────────────
  //
  // NAMES, NOT A CURRICULUM. This is the single easiest thing on the page to
  // misread: a list of steps under a style that is not built reads as "here is
  // what we teach". The heading, the note and the flat chip treatment all work
  // against that — no chip is tappable, none carries a status pill, and none
  // is styled like the lesson cards below it.

  Widget _glossarySection() => Column(
        key: glossaryKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(StyleStrings.glossaryTitle, style: ChoreiaType.display(size: 21)),
          const SizedBox(height: 4),
          Text(StyleStrings.glossaryNote,
              style:
                  ChoreiaType.body(size: 12, color: ChoreiaColors.text(0.55))),
          const SizedBox(height: 12),
          for (final GlossaryEntry g in card.entry.stepGlossary)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(g.name,
                      style: ChoreiaType.label(
                          size: 10.5, color: ChoreiaColors.text(0.72))),
                  const SizedBox(height: 3),
                  Text(g.gloss,
                      style: ChoreiaType.body(
                          size: 12.5, color: ChoreiaColors.text(0.66))),
                ],
              ),
            ),
        ],
      );

  // ── Cautions ─────────────────────────────────────────────────────────

  List<String> _cautions() => <String>[
        if (card.entry.safetyOnboarding != null) card.entry.safetyOnboarding!,
        for (final String e in card.entry.safetyExclusions)
          StyleStrings.excluded(e),
        if (card.entry.hardwareRequired.isNotEmpty)
          StyleStrings.needs(card.entry.hardwareRequired),
      ];

  Widget _cautionSection() => GlassPanel(
        key: cautionKey,
        tint: ChoreiaColors.amber,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(StyleStrings.cautionTitle,
                style: ChoreiaType.label(
                    size: 10, color: ChoreiaColors.amber)),
            const SizedBox(height: 10),
            for (final String c in _cautions())
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('· $c',
                    style: ChoreiaType.body(
                        size: 12.5, color: ChoreiaColors.text(0.78))),
              ),
          ],
        ),
      );

  // ── Lessons ──────────────────────────────────────────────────────────

  Widget _lessonsSection(List<LessonOffer> offers, BuildContext context) =>
      Column(
        key: lessonsKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(StyleStrings.lessonsTitle, style: ChoreiaType.display(size: 21)),
          const SizedBox(height: 12),
          if (offers.isEmpty)
            GlassPanel(
              key: noLessonsKey,
              child: Text(StyleStrings.noLessons,
                  style: ChoreiaType.body(
                      size: 13, color: ChoreiaColors.text(0.66))),
            )
          else
            for (final LessonOffer o in offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _lessonCard(o, context),
              ),
        ],
      );

  Widget _lessonCard(LessonOffer o, BuildContext context) {
    final LessonInfo l = o.lesson;
    final Color tone = switch (l.kind) {
      LessonKind.scored => ChoreiaColors.rose,
      LessonKind.demoOnly => ChoreiaColors.amber,
      // 0.7, not 0.4 — same measurement as the inPreparation badge (C-156).
      // A locked lesson names the measurement it is missing; that sentence is
      // worth nothing if its own label cannot be read.
      LessonKind.locked => ChoreiaColors.text(0.7),
    };

    return GlassPanel(
      key: lessonKey(l.id),
      radius: 18,
      tint: tone,
      // IDENTICAL padding across all three classes. The one place where
      // "demo-only is not second class" either holds or quietly stops holding.
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TitleWithPill(
            title: Text(l.displayName, style: ChoreiaType.display(size: 19)),
            pill: StatusPill(label: StyleStrings.kind(l.kind), tone: tone),
          ),
          const SizedBox(height: 8),
          Text(StyleStrings.minutes(l.plannedMinutes),
              style: ChoreiaType.label(
                  size: 10, color: ChoreiaColors.text(0.45))),
          if (o.contentReason != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(o.contentReason!,
                style: ChoreiaType.body(
                    size: 12.5, color: ChoreiaColors.text(0.75))),
          ],
          // PERMANENT is a different promise from NOT SCORED (C-167).
          //
          // Without this line every ungraded lesson reads as a queue: "not
          // scored" invites "not scored yet". Content had written the
          // distinction for 11 lessons — 184 to 383 characters each — and a
          // parser that did not know the key dropped all of it.
          if (l.whyPermanent != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              key: permanenceKey(l.id),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: tone.withValues(alpha: 0.35), width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(StyleStrings.permanentTitle,
                      style: ChoreiaType.label(size: 9.5, color: tone)),
                  const SizedBox(height: 5),
                  Text(l.whyPermanent!,
                      style: ChoreiaType.body(
                          size: 12, color: ChoreiaColors.text(0.7))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (o.canStart)
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                ChoreiaPageRoute<void>(
                  settings: RouteSettings(name: 'live/${l.id}'),
                  builder: (_) => LiveLessonPage(
                    stepId: l.stepId!,
                    styleId: l.styleId,
                    lessonClass: l.isScored ? 'scored' : 'demoOnly',
                  ),
                ),
              ),
              child: Text(StyleStrings.start),
            )
          else
            // NOT a disabled button. A greyed-out "Start" says the door might
            // open if you tried harder; a sentence says what is actually
            // missing and whose job it is. M-F-268's rule is that a dead end
            // must not be dressed as an action.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChoreiaColors.hairline(0.12)),
              ),
              child: Text(StyleStrings.blocked(o.block!),
                  style: ChoreiaType.body(
                      size: 12, color: ChoreiaColors.text(0.6))),
            ),
        ],
      ),
    );
  }

  // ── What a camera cannot see ─────────────────────────────────────────
  //
  // The honesty block for a style with nothing built. It sits at the BOTTOM,
  // after the lessons section has already said plainly that nothing exists —
  // reading "what a camera cannot see" before that could be taken as the
  // caveat on a product that is here, rather than a fact about the dance.

  Widget _cameraLimitsSection() => Column(
        key: cameraLimitsKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(StyleStrings.limitsTitle, style: ChoreiaType.display(size: 21)),
          const SizedBox(height: 4),
          Text(StyleStrings.limitsNote,
              style:
                  ChoreiaType.body(size: 12, color: ChoreiaColors.text(0.55))),
          const SizedBox(height: 12),
          GlassPanel(
            tint: ChoreiaColors.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String line in card.entry.cameraLimits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line,
                        style: ChoreiaType.body(
                            size: 12.5, color: ChoreiaColors.text(0.76))),
                  ),
              ],
            ),
          ),
        ],
      );

  // ── Honesty ──────────────────────────────────────────────────────────

  Widget _honestySection(StyleProse p) => Column(
        key: honestyKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(StyleStrings.honestyTitle, style: ChoreiaType.display(size: 21)),
          const SizedBox(height: 4),
          Text(StyleStrings.honestyNote,
              style:
                  ChoreiaType.body(size: 12, color: ChoreiaColors.text(0.55))),
          const SizedBox(height: 12),
          if (p.measured.isNotEmpty)
            _honestyBlock(
                StyleStrings.measuredTitle, p.measured, ChoreiaColors.rose),
          if (p.measured.isNotEmpty && p.notMeasured.isNotEmpty)
            const SizedBox(height: 10),
          if (p.notMeasured.isNotEmpty)
            _honestyBlock(StyleStrings.notMeasuredTitle, p.notMeasured,
                ChoreiaColors.amber),
        ],
      );

  Widget _honestyBlock(String title, List<String> lines, Color tone) =>
      GlassPanel(
        tint: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: ChoreiaType.label(size: 10, color: tone)),
            const SizedBox(height: 10),
            for (final String line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line,
                    style: ChoreiaType.body(
                        size: 12.5, color: ChoreiaColors.text(0.76))),
              ),
          ],
        ),
      );

  /// The SAME map the catalogue tile uses — see `badgeTone`. This used to be a
  /// second copy of the switch, which meant a tile and its page could drift
  /// apart on any one-sided edit.
  Color _badgeTone() => badgeTone(card.badge);
}

/// The style page's copy.
///
/// Same rule as `LibraryStrings`: no promise language, and every closed door
/// names what is behind it rather than when it might open.
abstract final class StyleStrings {
  StyleStrings._();

  static const String attributionTitle = 'WHERE THIS DANCE COMES FROM';

  /// The named gap. Says who owes the work and refuses to imply the dance has
  /// no lineage — only that we have not written it down.
  static const String attributionMissing =
      'We have not written this. Every dance in this catalogue was made by '
      'specific people in a specific place, and saying so properly takes more '
      'than a sentence we could improvise here. This space stays open rather '
      'than being filled with something vague.';

  static const String boundaryTitle = 'WHAT WE DO AND DO NOT REPRODUCE';

  static const String cautionTitle = 'BEFORE YOU START';

  static String excluded(String what) => 'Not taught here: $what';

  static String needs(List<String> items) => 'You will need: ${items.join(', ')}';

  static const String glossaryTitle = 'Steps you will hear named';

  /// The sentence that stops a glossary reading as a curriculum.
  static const String glossaryNote =
      'Names, not lessons. These are what the steps are called so you can '
      'follow along and look them up — none of them is taught or graded here, '
      'and a name on this list is not a promise of a lesson behind it.';

  static const String lessonsTitle = 'Lessons';

  static const String noLessons =
      'Nothing is built for this style. It is in the catalogue because we '
      'intend to teach it, and there is no lesson behind the name today.';

  static const String limitsTitle = 'What a camera cannot see here';

  /// The sentence that stops this from reading as a caveat on a live product.
  static const String limitsNote =
      'About this dance and a phone camera — not about lessons. Nothing is '
      'built for this style, and these are the parts we would still not be '
      'able to read if it were.';

  static const String honestyTitle = 'What this style can tell you';

  static const String honestyNote =
      'And what it cannot. Both lists come from measurements, not from what we '
      'would prefer to claim.';

  static const String measuredTitle = 'WE CHECK THIS';
  static const String notMeasuredTitle = 'WE DO NOT CHECK THIS';

  /// Names the difference between "not scored" and "never scored".
  static const String permanentTitle = 'THIS ONE WILL NOT CHANGE';

  static const String start = 'Start';

  static String kind(LessonKind k) => switch (k) {
        LessonKind.scored => 'GRADED',
        LessonKind.demoOnly => 'OPEN · NOT GRADED',
        LessonKind.locked => 'LOCKED',
      };

  static String minutes(int m) => m > 0 ? '$m MIN' : 'LENGTH NOT SET';

  static String blocked(LessonBlock b) => switch (b) {
        LessonBlock.styleShut =>
          'This lesson is finished, and the style it belongs to is not open — '
              'the reason is at the top of this page.',
        LessonBlock.measurementMissing =>
          'This one stays locked because the measurement it would grade does '
              'not exist. The note above names which one.',
        LessonBlock.referenceMissing =>
          'The movement reference behind this lesson is not built, so there is '
              'nothing to check you against. The teaching is written; the '
              'measurement is not.',
        LessonBlock.noLessonBuilt =>
          'There is nothing built to walk you through this one — only the note '
              'above. It is a real lesson in the plan and an empty one today.',
      };
}
