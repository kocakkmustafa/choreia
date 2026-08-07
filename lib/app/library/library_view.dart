import 'package:flutter/material.dart';

import '../shell/choreia_page_route.dart';
import '../theme.dart';
import 'library_catalog.dart';
import 'style_detail_view.dart';

/// The catalogue screen — 34 styles, one of which can be opened.
///
/// THE PROBLEM THIS SCREEN EXISTS TO SOLVE
/// ---------------------------------------
/// Show the full scope of what Choreia intends to teach without looking full.
/// Those pull against each other: hiding the 31 unbuilt styles would understate
/// the product, and listing them as if they were courses would be the "sahte
/// dolu" (fake-full) failure — a catalogue that reads as 34 dances you could
/// start tonight when the number is one.
///
/// The resolution here is GROUPING, not filtering. Every style is on this
/// screen, always; what changes between them is which group they sit in and
/// what their tile says. A dancer scrolling sees breadth immediately and sees,
/// just as immediately, that breadth is not availability. No tile ever
/// advertises a lesson that cannot be opened, and no style is dropped to make
/// the screen look tidier.
///
/// WHY THE COUNTS ARE NOT THE DESIGN'S COUNTS
/// ------------------------------------------
/// The mockup's stat panel reads "1 scored · 1 open, ungraded · 32 in
/// preparation". Those are `library.json`'s own `status` values — CONTENT
/// truth. The surface truth is different, because `salsa_shines` is `live` AND
/// release-gated: **no scored style can be opened today**. Every number on this
/// screen comes from [LibraryTally], which counts derived badges, so the panel
/// cannot drift from what the tiles below it show.
class LibraryView extends StatefulWidget {
  const LibraryView({required this.library, super.key});

  final LibraryCatalog library;

  static const Key tallyKey = Key('library.tally');
  static const Key emptyFilterKey = Key('library.emptyFilter');
  static const Key gridKey = Key('library.grid');

  static Key sectionKey(StyleBadge b) => Key('library.section.${b.name}');
  static Key tileKey(String styleId) => Key('library.tile.$styleId');

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

/// What the chips narrow to. Deliberately three, not one per badge: chips are
/// for narrowing a long list, and the meaningful distinctions between the four
/// badges are carried by the tiles themselves, where each one sits next to its
/// own reason.
enum _Filter { all, openNow, notOpen }

class _LibraryViewState extends State<LibraryView> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final List<StyleCard> cards = widget.library.cards;
    final LibraryTally tally = LibraryTally.from(cards);
    final List<StyleCard> shown = cards.where(_matches).toList(growable: false);

    // Order is the honesty here: what you can do, then what is built but shut,
    // then what is deliberately parked, then what does not exist. Putting
    // "not built" last is not burying it — it is the largest group and the
    // least actionable, and leading with it would bury the one openable style.
    const List<StyleBadge> order = <StyleBadge>[
      StyleBadge.scored,
      StyleBadge.openUngraded,
      StyleBadge.builtButGated,
      StyleBadge.onHold,
      StyleBadge.inPreparation,
    ];

    return ChoreiaBackdrop(
      child: SafeArea(
        child: ListView(
          key: LibraryView.gridKey,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: <Widget>[
            Text('What you can learn',
                style: ChoreiaType.label(
                    size: 10, color: ChoreiaColors.text(0.42))),
            const SizedBox(height: 8),
            Text('Styles', style: ChoreiaType.display(size: 33)),
            const SizedBox(height: 18),
            _tallyPanel(tally),
            const SizedBox(height: 18),
            _chips(tally),
            const SizedBox(height: 22),
            if (shown.isEmpty)
              _emptyFilter()
            else
              for (final StyleBadge badge in order)
                if (shown.any((StyleCard c) => c.badge == badge))
                  _section(
                    badge,
                    shown
                        .where((StyleCard c) => c.badge == badge)
                        .toList(growable: false),
                  ),
          ],
        ),
      ),
    );
  }

  bool _matches(StyleCard c) => switch (_filter) {
        _Filter.all => true,
        _Filter.openNow => c.isOpenable,
        _Filter.notOpen => !c.isOpenable,
      };

  // ── The panel ────────────────────────────────────────────────────────
  //
  // Two sentences, and the second one is the load-bearing one. The first
  // states scope; the second states what scope does NOT mean. Written as
  // prose rather than a row of big numerals on purpose — three large figures
  // side by side read as a scoreboard, and 34/1/31 as a scoreboard makes the
  // 34 the headline when the 1 is the fact.
  Widget _tallyPanel(LibraryTally t) => GlassPanel(
        key: LibraryView.tallyKey,
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(LibraryStrings.scopeLine(t),
                style: ChoreiaType.body(
                    size: 13.5, color: ChoreiaColors.text(0.85))),
            const SizedBox(height: 10),
            Text(LibraryStrings.availabilityLine(t),
                style: ChoreiaType.body(
                    size: 12.5, color: ChoreiaColors.text(0.62))),
          ],
        ),
      );

  Widget _chips(LibraryTally t) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _chip(_Filter.all, LibraryStrings.filterAll, t.total),
          _chip(_Filter.openNow, LibraryStrings.filterOpenNow, t.openable),
          _chip(_Filter.notOpen, LibraryStrings.filterNotOpen,
              t.total - t.openable),
        ],
      );

  Widget _chip(_Filter f, String label, int count) {
    final bool on = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: on ? ChoreiaColors.rose.withValues(alpha: 0.14) : null,
          border: Border.all(
              color: ChoreiaColors.hairline(on ? 0.32 : 0.13)),
        ),
        // The count travels WITH the label. A chip that says "Open now" and
        // reveals "1" only after a tap invites the assumption that it is many.
        child: Text('$label · $count',
            style: ChoreiaType.label(
                size: 9.5,
                letterSpacingEm: 0.1,
                color: on ? ChoreiaColors.rose : ChoreiaColors.text(0.55))),
      ),
    );
  }

  Widget _emptyFilter() => GlassPanel(
        key: LibraryView.emptyFilterKey,
        child: Text(LibraryStrings.emptyFilter,
            style:
                ChoreiaType.body(size: 13, color: ChoreiaColors.text(0.65))),
      );

  // ── Sections ─────────────────────────────────────────────────────────

  Widget _section(StyleBadge badge, List<StyleCard> cards) {
    // Styles with an authored document get the full card; the rest get compact
    // tiles. Derived from whether content EXISTS, never from a position in the
    // list — a hero card is what having something to say looks like.
    final bool hero = badge != StyleBadge.inPreparation;
    return Padding(
      key: LibraryView.sectionKey(badge),
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(LibraryStrings.sectionTitle(badge),
                    style: ChoreiaType.display(size: 19)),
              ),
              Text('${cards.length}',
                  style: ChoreiaType.label(
                      size: 11, color: ChoreiaColors.text(0.4))),
            ],
          ),
          const SizedBox(height: 4),
          Text(LibraryStrings.sectionNote(badge),
              style: ChoreiaType.body(
                  size: 12, color: ChoreiaColors.text(0.55))),
          const SizedBox(height: 12),
          for (final StyleCard c in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: hero ? _heroCard(c) : _compactTile(c),
            ),
        ],
      ),
    );
  }

  Widget _heroCard(StyleCard c) => _tappable(
        c,
        GlassPanel(
          key: LibraryView.tileKey(c.entry.id),
          radius: 22,
          tint: _tone(c.badge),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(c.entry.displayName,
                        style: ChoreiaType.display(size: 25)),
                  ),
                  const SizedBox(width: 10),
                  StatusPill(
                      label: LibraryStrings.badge(c.badge),
                      tone: _tone(c.badge)),
                ],
              ),
              const SizedBox(height: 10),
              // The lesson count is CONTENT truth and belongs on an openable
              // card; on a gated one it would read as an inventory the user can
              // reach. Both are shown, worded to say which is which.
              Text(LibraryStrings.lessonLine(c),
                  style: ChoreiaType.label(
                      size: 10, color: ChoreiaColors.text(0.48))),
              if (_reason(c) != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(_reason(c)!,
                    style: ChoreiaType.body(
                        size: 12.5, color: ChoreiaColors.text(0.72))),
              ],
            ],
          ),
        ),
      );

  Widget _compactTile(StyleCard c) => _tappable(
        c,
        Container(
          key: LibraryView.tileKey(c.entry.id),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ChoreiaColors.hairline(0.10)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(c.entry.displayName,
                    style: ChoreiaType.body(
                        size: 13.5, color: ChoreiaColors.text(0.8))),
              ),
              const SizedBox(width: 10),
              StatusPill(
                  label: LibraryStrings.badge(c.badge),
                  tone: _tone(c.badge),
                  filled: false),
            ],
          ),
        ),
      );

  Widget _tappable(StyleCard c, Widget child) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          ChoreiaPageRoute<void>(
            settings: RouteSettings(name: 'style/${c.entry.id}'),
            builder: (_) => StyleDetailView(
              card: c,
              runnableSteps: widget.library.runnableSteps,
            ),
          ),
        ),
        child: child,
      );

  /// The user-facing reason a style is shut, taken from the DERIVATION rather
  /// than written here. One source of truth: `AvailabilityStrings` already
  /// owns this copy and is tested against leaking technical text.
  String? _reason(StyleCard c) =>
      c.entry.onHoldReason ?? c.view.userFacingReason;

  Color _tone(StyleBadge b) => badgeTone(b);
}

/// The badge tone map — ONE copy.
///
/// Rose carries a VERDICT, amber carries a STATUS (design brief §2 — the two
/// tones are a language and do not mix on one element). Nothing in this
/// catalogue is a verdict about the dancer, so rose appears only on the scored
/// badge, where it marks the presence of grading itself.
///
/// Public and top-level because it was DUPLICATED: an identical switch lived in
/// `style_detail_view.dart`, so a tile and its own page could have disagreed
/// about a style's colour after any one-sided edit. The duplication surfaced
/// when `contrast_test.dart` needed to measure these tones and found two
/// candidates for the truth — the same "two copies of a truth drift" rule this
/// app applies to derived data (C-091), reaching styling.
Color badgeTone(StyleBadge b) => switch (b) {
      StyleBadge.scored => ChoreiaColors.rose,
      StyleBadge.openUngraded => ChoreiaColors.amber,
      StyleBadge.builtButGated => ChoreiaColors.amber,
      StyleBadge.onHold => ChoreiaColors.amberDeep,
      // 0.65, not 0.35. At 0.35 this measured 2.58:1 — below even the 3.0
      // WCAG asks of non-text, on the badge worn by 31 of the 34 tiles. An
      // honest state nobody can see is the same as saying nothing (C-156).
      // It is still the quietest tone here; quiet is not the same as invisible.
      StyleBadge.inPreparation => ChoreiaColors.text(0.65),
    };

/// Every user-facing string on the catalogue screen.
///
/// ONE RULE GOVERNS ALL OF IT (M-F-186): no promise language. Nothing here says
/// "coming soon", "yakında", or dates a style that is not built. A style that
/// cannot be opened is described by WHAT IS TRUE OF IT NOW and, where content
/// knows one, why — never by when it might change.
abstract final class LibraryStrings {
  LibraryStrings._();

  static String scopeLine(LibraryTally t) =>
      '${t.total} styles are in the catalogue.';

  /// The sentence that stops scope from reading as availability.
  ///
  /// Built from the tally rather than written as a constant so it cannot go
  /// stale: when the BPM gate opens, this line changes on its own.
  static String availabilityLine(LibraryTally t) {
    final String open = t.openable == 1
        ? 'One of them is open to practise right now'
        : '${t.openable} of them are open to practise right now';
    final String scored = t.scored == 0
        ? ', and none of the open ones is graded'
        : '';
    return '$open$scored. The rest are listed so you can see the whole plan, '
        'not because they are ready — each one says where it stands.';
  }

  static const String filterAll = 'ALL';
  static const String filterOpenNow = 'OPEN NOW';
  static const String filterNotOpen = 'NOT OPEN';

  static const String emptyFilter =
      'Nothing matches that filter. Nothing has been hidden — there is simply '
      'nothing in this group.';

  static String badge(StyleBadge b) => switch (b) {
        StyleBadge.scored => 'SCORED',
        StyleBadge.openUngraded => 'OPEN · NOT SCORED',
        StyleBadge.builtButGated => 'BUILT · NOT OPEN',
        StyleBadge.inPreparation => 'NOT BUILT',
        StyleBadge.onHold => 'ON HOLD',
      };

  static String sectionTitle(StyleBadge b) => switch (b) {
        StyleBadge.scored => 'Open and graded',
        StyleBadge.openUngraded => 'Open, not graded',
        StyleBadge.builtButGated => 'Built, not open',
        StyleBadge.inPreparation => 'In the catalogue, not built',
        StyleBadge.onHold => 'On hold',
      };

  static String sectionNote(StyleBadge b) => switch (b) {
        StyleBadge.scored =>
          'Lessons you can start, with a camera check behind them.',
        StyleBadge.openUngraded =>
          'Lessons you can start. We teach these and we do not put a number '
              'on them — each lesson says why.',
        StyleBadge.builtButGated =>
          'The lessons exist and are finished. Something we check before '
              'opening a style has not cleared, so they stay shut.',
        StyleBadge.inPreparation =>
          'Named here so you can see the whole plan. Nothing is built for '
              'these — there is no lesson behind the name.',
        StyleBadge.onHold =>
          'Deliberately parked. The reason is on the style page, and it is not '
              'a scheduling one.',
      };

  /// What a card says about its lessons — worded so a gated style's inventory
  /// cannot read as something reachable.
  static String lessonLine(StyleCard c) {
    if (c.lessons.isEmpty) return 'NO LESSONS BUILT';
    final int total = c.lessons.length;
    final int scored = c.scoredLessonCount;
    final String lessons = '$total ${total == 1 ? 'lesson' : 'lessons'}';
    final String graded =
        scored == 0 ? 'none graded' : '$scored graded';
    return c.isOpenable
        ? '$lessons · $graded'.toUpperCase()
        : '$lessons written · $graded · none open'.toUpperCase();
  }
}
