import 'package:flutter/material.dart';
import '../study_review.dart';

import '../live/live_environment.dart';
import '../course/salsa_course_page.dart';
import '../shell/choreia_page_route.dart';
import '../theme.dart';
import '../ui_language.dart';
import 'library_catalog.dart';
import 'style_content_copy.dart';
import 'style_detail_view.dart';
import 'style_status_copy.dart';

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
  const LibraryView({
    required this.library,
    this.env = const LiveEnvironment(),
    this.beforeLessonStart,
    this.cameraSessionsAvailable = false,
    super.key,
  });

  final LibraryCatalog library;

  /// Forwarded, untouched, to whatever lesson the learner opens. This widget
  /// has no business knowing what a bundle or a store is — it carries the
  /// object rather than its three parts precisely so it cannot half-forward it.
  final LiveEnvironment env;
  final Future<bool> Function(BuildContext)? beforeLessonStart;
  final bool cameraSessionsAvailable;

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

  bool get _tr => UiLanguage.isTurkish(context);

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
            Text(
              _tr ? 'ÖĞRENEBİLECEKLERİN' : 'What you can learn',
              style: ChoreiaType.label(
                size: 10,
                color: ChoreiaColors.text(0.42),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _tr ? 'Stiller' : 'Styles',
                    style: ChoreiaType.display(size: 33),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 32,
                  child: IconButton(
                    key: const Key('study-review-entry'),
                    padding: EdgeInsets.zero,
                    tooltip: _tr
                        ? 'Yazılı hatırlama ve değerlendirme'
                        : 'Written recall and review',
                    icon: const Icon(Icons.menu_book_outlined, size: 20),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const StudyReviewPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SalsaCourseEntry(env: widget.env),
            const SizedBox(height: 24),
            Text(_tr ? 'Kamera seansı referans notları' : 'Camera-session reference notes',
                style: ChoreiaType.display(size: 25)),
            const SizedBox(height: 12),
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
            Text(
              _tr ? LibraryStrings.scopeLineTr(t) : LibraryStrings.scopeLine(t),
              style:
                  ChoreiaType.body(size: 13.5, color: ChoreiaColors.text(0.85)),
            ),
            const SizedBox(height: 10),
            Text(
              _tr
                  ? LibraryStrings.availabilityLineTr(t,
                      cameraSessionsAvailable: widget.cameraSessionsAvailable)
                  : LibraryStrings.availabilityLine(t,
                      cameraSessionsAvailable: widget.cameraSessionsAvailable),
              style:
                  ChoreiaType.body(size: 12.5, color: ChoreiaColors.text(0.62)),
            ),
          ],
        ),
      );

  Widget _chips(LibraryTally t) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _chip(_Filter.all, _tr ? 'TÜMÜ' : LibraryStrings.filterAll, t.total),
          _chip(
            _Filter.openNow,
            _tr ? 'REFERANSLAR' : LibraryStrings.filterOpenNow,
            t.openable,
          ),
          _chip(
            _Filter.notOpen,
            _tr ? 'REFERANS EKSİKLERİ' : LibraryStrings.filterNotOpen,
            t.total - t.openable,
          ),
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
          border: Border.all(color: ChoreiaColors.hairline(on ? 0.32 : 0.13)),
        ),
        // The count travels WITH the label. A chip that says "Open now" and
        // reveals "1" only after a tap invites the assumption that it is many.
        child: Text(
          '$label · $count',
          style: ChoreiaType.label(
            size: 9.5,
            letterSpacingEm: 0.1,
            color: on ? ChoreiaColors.rose : ChoreiaColors.text(0.55),
          ),
        ),
      ),
    );
  }

  Widget _emptyFilter() => GlassPanel(
        key: LibraryView.emptyFilterKey,
        child: Text(
          _tr
              ? 'Bu filtreye uyan stil yok. Hiçbir şey gizlenmedi.'
              : LibraryStrings.emptyFilter,
          style: ChoreiaType.body(size: 13, color: ChoreiaColors.text(0.65)),
        ),
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
                child: Text(
                  _tr
                      ? LibraryStrings.sectionTitleTr(badge)
                      : LibraryStrings.sectionTitle(badge),
                  style: ChoreiaType.display(size: 19),
                ),
              ),
              Text(
                '${cards.length}',
                style: ChoreiaType.label(
                  size: 11,
                  color: ChoreiaColors.text(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _tr
                ? LibraryStrings.sectionNoteTr(badge,
                      cameraSessionsAvailable: widget.cameraSessionsAvailable)
                : LibraryStrings.sectionNote(badge,
                      cameraSessionsAvailable: widget.cameraSessionsAvailable),
            style: ChoreiaType.body(size: 12, color: ChoreiaColors.text(0.55)),
          ),
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
              TitleWithPill(
                title: Text(
                  StyleContentCopy.styleName(c.entry, turkish: _tr),
                  style: ChoreiaType.display(size: 25),
                ),
                pill: StatusPill(
                  label: _tr
                      ? LibraryStrings.badgeTr(c.badge)
                      : LibraryStrings.badge(c.badge),
                  tone: _tone(c.badge),
                ),
              ),
              const SizedBox(height: 10),
              // The lesson count is CONTENT truth and belongs on an openable
              // card; on a gated one it would read as an inventory the user can
              // reach. Both are shown, worded to say which is which.
              Text(
                (_tr ? LibraryStrings.lessonLineTr : LibraryStrings.lessonLine)(
                  c,
                  cameraSessionsAvailable: widget.cameraSessionsAvailable,
                  startable: c
                      .offers(widget.library.runnableSteps)
                      .where((LessonOffer o) => o.canStart)
                      .length,
                ),
                style: ChoreiaType.label(
                    size: 10, color: ChoreiaColors.text(0.48)),
              ),
              if (_reason(c) != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _reason(c)!,
                  style: ChoreiaType.body(
                    size: 12.5,
                    color: ChoreiaColors.text(0.72),
                  ),
                ),
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
          child: TitleWithPill(
            title: Text(
              StyleContentCopy.styleName(c.entry, turkish: _tr),
              style:
                  ChoreiaType.body(size: 13.5, color: ChoreiaColors.text(0.8)),
            ),
            pill: StatusPill(
              label: _tr
                  ? LibraryStrings.badgeTr(c.badge)
                  : LibraryStrings.badge(c.badge),
              tone: _tone(c.badge),
              filled: false,
            ),
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
              env: widget.env,
              beforeStart: widget.beforeLessonStart,
              cameraSessionsAvailable: widget.cameraSessionsAvailable,
            ),
          ),
        ),
        child: child,
      );

  /// The user-facing reason a style is shut, taken from the DERIVATION rather
  /// than written here. One source of truth: `AvailabilityStrings` already
  /// owns this copy and is tested against leaking technical text.
  String? _reason(StyleCard c) => StyleStatusCopy.reason(c, turkish: _tr);

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
      // roseBright, not rose (C-159). Raising the demo-only badge to the
      // legibility floor in C-156 pushed it PAST the graded one — 9.59 against
      // 8.08, so "not graded" was reading louder than "graded". The brief's
      // promise has two sides: a floor (demo-only must not look second class)
      // and a ceiling (it must not look FIRST class either). Using the
      // palette's existing brighter rose puts them level at 1.017x, which
      // leaves the distinction where it belongs — in the HUE, not the volume.
      StyleBadge.scored => ChoreiaColors.roseBright,
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

  static String scopeLineTr(LibraryTally t) =>
      'Katalogda ${t.total} dans stili var.';

  // Content readiness never implies an accessible camera session.
  static String sessionNotice(bool available, {bool turkish = false}) =>
      turkish
          ? (available
              ? 'Kamera seansları cihaz izni ve erişim kontrolü gerektirir. Puansız canlı pratik seanslarına puan verilmez.'
              : 'Bu sürümde kamera çalışması ve puanlama kapalı. Referanslar oynatılabilir bir önizleme değildir.')
          : (available
              ? 'Camera sessions require device permission and access checks. Demo-only live practice is not scored.'
              : 'Camera practice and scoring are unavailable in this release. References are not a playable preview.');

  static String availabilityLine(LibraryTally t,
          {bool cameraSessionsAvailable = false}) =>
      '${t.openable} ${t.openable == 1 ? 'style has' : 'styles have'} camera-session reference notes. '
      '${sessionNotice(cameraSessionsAvailable)} Use the written courses above '
      'for guided lessons. Other catalogue entries show their current status.';

  static String availabilityLineTr(LibraryTally t,
          {bool cameraSessionsAvailable = false}) =>
      '${t.openable} stilde kamera seansı referans notları var. '
      '${sessionNotice(cameraSessionsAvailable, turkish: true)} Rehberli dersler '
      'için yukarıdaki yazılı kursları kullan. Diğer girdiler mevcut durumlarıyla gösterilir.';

  static const String filterAll = 'ALL';
  static const String filterOpenNow = 'REFERENCES';
  static const String filterNotOpen = 'REFERENCE GAPS';

  static const String emptyFilter =
      'Nothing matches that filter. Nothing has been hidden — there is simply '
      'nothing in this group.';

  static String badge(StyleBadge b) => switch (b) {
        StyleBadge.scored => 'REFERENCE',
        StyleBadge.openUngraded => 'CAMERA REFERENCES',
        StyleBadge.builtButGated => 'CAMERA UNAVAILABLE',
        StyleBadge.inPreparation => 'NOT BUILT',
        StyleBadge.onHold => 'ON HOLD',
      };

  static String badgeTr(StyleBadge b) => switch (b) {
        StyleBadge.scored => 'REFERANS',
        StyleBadge.openUngraded => 'KAMERA REFERANSLARI',
        StyleBadge.builtButGated => 'KAMERA KAPALI',
        StyleBadge.inPreparation => 'DERS YOK',
        StyleBadge.onHold => 'DURAKLATILDI',
      };

  static String sectionTitle(StyleBadge b) => switch (b) {
        StyleBadge.scored => 'Posture references',
        StyleBadge.openUngraded => 'Camera-session references',
        StyleBadge.builtButGated => 'Camera practice unavailable',
        StyleBadge.inPreparation => 'In the catalogue, not built',
        StyleBadge.onHold => 'On hold',
      };

  static String sectionTitleTr(StyleBadge b) => switch (b) {
        StyleBadge.scored => 'Duruş referansları',
        StyleBadge.openUngraded => 'Kamera seansı referansları',
        StyleBadge.builtButGated => 'Kamera çalışması kapalı',
        StyleBadge.inPreparation => 'Katalogda, ders yok',
        StyleBadge.onHold => 'Duraklatıldı',
      };

  static String sectionNote(StyleBadge b,
          {bool cameraSessionsAvailable = false}) => switch (b) {
        StyleBadge.scored || StyleBadge.openUngraded =>
          'Read the written explanations and recorded references. ${sessionNotice(cameraSessionsAvailable)}',
        StyleBadge.builtButGated =>
          'Reference notes are written; this style still has incomplete content checks. ${sessionNotice(cameraSessionsAvailable)}',
        StyleBadge.inPreparation =>
          'Named here so you can see the whole plan. Nothing is built for '
              'these — there is no lesson behind the name.',
        StyleBadge.onHold =>
          'Deliberately parked. The reason is on the style page, and it is not '
              'a scheduling one.',
      };

  static String sectionNoteTr(StyleBadge b,
          {bool cameraSessionsAvailable = false}) => switch (b) {
        StyleBadge.scored || StyleBadge.openUngraded =>
          'Yazılı açıklamaları ve kayıtlı referansları oku. ${sessionNotice(cameraSessionsAvailable, turkish: true)}',
        StyleBadge.builtButGated =>
          'Referans notları yazılmış; bu stilin içerik kontrolleri tamamlanmamış. ${sessionNotice(cameraSessionsAvailable, turkish: true)}',
        StyleBadge.inPreparation =>
          'Stil adı katalogda var; arkasında açılabilir bir ders yok.',
        StyleBadge.onHold => 'Bu stil duraklatıldı. Gerekçesi stil sayfasında.',
      };

  static String lessonLineTr(StyleCard c,
      {required int startable, bool cameraSessionsAvailable = false}) {
    if (c.lessons.isEmpty) return 'DERS YOK';
    final int total = c.lessons.length;
    return cameraSessionsAvailable
        ? '$total DERS YAZILDI · $startable KAMERA REFERANSI HAZIR'
        : '$total DERS YAZILDI · KAMERA KAPALI · PUAN YOK';
  }

  /// What a card says about its lessons — worded so a style's inventory cannot
  /// read as something reachable.
  ///
  /// 🔴 **THE CARE WAS ON ONE BRANCH ONLY (C-283).** The gated branch has
  /// always said `9 LESSONS WRITTEN · 1 GRADED · NONE OPEN` — three words doing
  /// real work (*written*, *none open*). The OPENABLE branch said a bare
  /// `6 LESSONS · NONE GRADED` next to an `OPEN` badge, and of those six
  /// exactly **one** could be started. This line is a TILE: it is scanned, not
  /// read, and next to `OPEN` a bare count reads as *six lessons you can do*.
  ///
  /// Same class as `C-282` (badge vs body) one screen earlier, and the same
  /// shape as `C-279`: ⇒ ***CARE APPLIED TO THE HARD CASE DOES NOT TRANSFER TO
  /// THE EASY ONE*** — the gated branch got the attention precisely because it
  /// looked like the risky one, and the risk was on the other side.
  ///
  /// [startable] is passed rather than derived here: only the catalogue knows
  /// which references the bundle actually serves, and a count computed from
  /// content alone would claim lessons the device cannot open — the exact
  /// distinction `LibraryCatalog.runnableSteps` exists to make.
  static String lessonLine(StyleCard c,
      {required int startable, bool cameraSessionsAvailable = false}) {
    if (c.lessons.isEmpty) return 'NO LESSONS BUILT';
    final int total = c.lessons.length;
    return cameraSessionsAvailable
        ? '$total LESSONS WRITTEN · $startable CAMERA REFERENCES READY'
        : '$total LESSONS WRITTEN · CAMERA OFF · NO SCORING';
  }
}
