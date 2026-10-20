import 'package:flutter/material.dart';
import '../study_review.dart';

import '../live/live_environment.dart';
import '../shell/choreia_page_route.dart';
import '../theme.dart';
import '../ui_language.dart';
import 'library_catalog.dart';
import 'style_content_copy.dart';
import 'style_detail_view.dart';
import 'style_status_copy.dart';

/// All catalogue styles, with written courses and camera references kept
/// distinct. A camera-content gate never hides an existing written route.
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
  static const Key writtenCoursesKey = Key('library.writtenCourses');

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

  String _text(String value) => UiLanguage.text(context, en: value, tr: value);
  String _pair(String en, String tr) =>
      UiLanguage.text(context, en: en, tr: tr);

  String get _cameraNotice => _pair(
      LibraryStrings.sessionNotice(widget.cameraSessionsAvailable),
      LibraryStrings.sessionNotice(widget.cameraSessionsAvailable,
          turkish: true));

  String _sectionNote(StyleBadge badge) => switch (badge) {
        StyleBadge.scored ||
        StyleBadge.openUngraded =>
          '${_pair('Read the written explanations and recorded references.', 'Yazılı açıklamaları ve kayıtlı referansları oku.')} $_cameraNotice',
        StyleBadge.builtButGated =>
          '${_pair('Reference notes are written; this style still has incomplete content checks.', 'Referans notları yazılmış; bu stilin içerik kontrolleri tamamlanmamış.')} $_cameraNotice',
        _ => _pair(LibraryStrings.sectionNote(badge),
            LibraryStrings.sectionNoteTr(badge)),
      };

  String _lessonLine(StyleCard card) {
    final startable = card
        .offers(widget.library.runnableSteps)
        .where((offer) => offer.canStart)
        .length;
    if (WrittenCourseLink.supports(card.entry.id)) {
      return widget.cameraSessionsAvailable
          ? UiLanguage.format(context,
              en: 'WRITTEN COURSE AVAILABLE · {count} CAMERA REFERENCES READY',
              tr: 'YAZILI KURS AÇIK · {count} KAMERA REFERANSI HAZIR',
              values: {'count': startable})
          : _pair('WRITTEN COURSE AVAILABLE · CAMERA OFF · NO SCORING',
              'YAZILI KURS AÇIK · KAMERA KAPALI · PUAN YOK');
    }
    if (card.lessons.isEmpty) return _pair('NO LESSONS BUILT', 'DERS YOK');
    return widget.cameraSessionsAvailable
        ? UiLanguage.format(context,
            en: '{total} LESSONS WRITTEN · {count} CAMERA REFERENCES READY',
            tr: '{total} DERS YAZILDI · {count} KAMERA REFERANSI HAZIR',
            values: {'total': card.lessons.length, 'count': startable})
        : UiLanguage.format(context,
            en: '{total} LESSONS WRITTEN · CAMERA OFF · NO SCORING',
            tr: '{total} DERS YAZILDI · KAMERA KAPALI · PUAN YOK',
            values: {'total': card.lessons.length});
  }

  @override
  Widget build(BuildContext context) {
    final List<StyleCard> cards = widget.library.cards;
    final LibraryTally tally = LibraryTally.from(cards);
    final List<StyleCard> shown = cards.where(_matches).toList(growable: false);
    final List<StyleCard> written = shown
        .where((StyleCard c) => WrittenCourseLink.supports(c.entry.id))
        .toList(growable: false);
    final List<StyleCard> other = shown
        .where((StyleCard c) => !WrittenCourseLink.supports(c.entry.id))
        .toList(growable: false);

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
              _pair('What you can learn', 'ÖĞRENEBİLECEKLERİN'),
              style: ChoreiaType.of(context).label(
                size: 10,
                color: ChoreiaPalette.of(context).text(0.42),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _pair('Styles', 'Stiller'),
                    style: ChoreiaType.of(context).display(size: 33),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: const Key('study-review-entry'),
                    padding: EdgeInsets.zero,
                    tooltip: _pair('Written recall and review',
                        'Yazılı hatırlama ve değerlendirme'),
                    icon: const Icon(Icons.menu_book_outlined, size: 20),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => StudyReviewPage(env: widget.env),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _tallyPanel(tally),
            const SizedBox(height: 18),
            _chips(tally),
            const SizedBox(height: 22),
            if (written.isNotEmpty)
              Column(
                key: LibraryView.writtenCoursesKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(_pair('Written courses', 'Yazılı kurslar'),
                        style: ChoreiaType.of(context).display(size: 25)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pair(
                        'Self-guided lessons are available. Written progress does not verify movement skill.',
                        'Öz denetimli dersler açık. Yazılı ilerleme, hareket becerisi doğrulaması değildir.'),
                    style: ChoreiaType.of(context).body(size: 12.5),
                  ),
                  const SizedBox(height: 12),
                  for (final StyleCard c in written)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _heroCard(c, writtenCourse: true),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            if (shown.isEmpty)
              _emptyFilter()
            else
              for (final StyleBadge badge in order)
                if (other.any((StyleCard c) => c.badge == badge))
                  _section(
                    badge,
                    other
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
              UiLanguage.format(context,
                  en: '{count} styles are in the catalogue.',
                  tr: 'Katalogda {count} dans stili var.',
                  values: {'count': t.total}),
              style: ChoreiaType.of(context).body(
                  size: 13.5, color: ChoreiaPalette.of(context).text(0.85)),
            ),
            const SizedBox(height: 10),
            Text(
              UiLanguage.format(context,
                  en: t.openable == 1
                      ? '{count} style has camera-session reference notes. {status} Use the written courses below for guided lessons. Other catalogue entries show their current status.'
                      : '{count} styles have camera-session reference notes. {status} Use the written courses below for guided lessons. Other catalogue entries show their current status.',
                  tr: 'Kamera referans notları: {count} stil. {status} Rehberli dersler için aşağıdaki yazılı kursları kullan. Diğer girdiler mevcut durumlarıyla gösterilir.',
                  values: {'count': t.openable, 'status': _cameraNotice}),
              style: ChoreiaType.of(context).body(
                  size: 12.5, color: ChoreiaPalette.of(context).text(0.62)),
            ),
          ],
        ),
      );

  Widget _chips(LibraryTally t) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _chip(_Filter.all, _pair(LibraryStrings.filterAll, 'TÜMÜ'), t.total),
          _chip(
            _Filter.openNow,
            _pair(LibraryStrings.filterOpenNow, 'REFERANSLAR'),
            t.openable,
          ),
          _chip(
            _Filter.notOpen,
            _pair(LibraryStrings.filterNotOpen, 'REFERANS EKSİKLERİ'),
            t.total - t.openable,
          ),
        ],
      );

  Widget _chip(_Filter f, String label, int count) {
    final bool on = _filter == f;
    return ChoiceChip(
      selected: on,
      onSelected: (_) => setState(() => _filter = f),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      showCheckmark: false,
      selectedColor: ChoreiaPalette.of(context).rose.withValues(alpha: 0.14),
      side: BorderSide(
          color: ChoreiaPalette.of(context).hairline(on ? 0.32 : 0.13)),
      label: Text(
        '$label · ${UiLanguage.number(context, count)}',
        style: ChoreiaType.of(context).label(
          size: 9.5,
          letterSpacingEm: 0.1,
          color: on
              ? ChoreiaPalette.of(context).rose
              : ChoreiaPalette.of(context).text(0.55),
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
          style: ChoreiaType.of(context)
              .body(size: 13, color: ChoreiaPalette.of(context).text(0.65)),
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
                  _pair(LibraryStrings.sectionTitle(badge),
                      LibraryStrings.sectionTitleTr(badge)),
                  style: ChoreiaType.of(context).display(size: 19),
                ),
              ),
              Text(
                UiLanguage.number(context, cards.length),
                style: ChoreiaType.of(context).label(
                  size: 11,
                  color: ChoreiaPalette.of(context).text(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _sectionNote(badge),
            style: ChoreiaType.of(context)
                .body(size: 12, color: ChoreiaPalette.of(context).text(0.55)),
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

  Widget _heroCard(StyleCard c, {bool writtenCourse = false}) => _tappable(
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
                  _text(StyleContentCopy.styleName(c.entry, turkish: _tr)),
                  style: ChoreiaType.of(context).display(size: 25),
                ),
                pill: StatusPill(
                  label: writtenCourse
                      ? (_pair('WRITTEN COURSE', 'YAZILI KURS'))
                      : (_tr
                          ? _text(LibraryStrings.badgeTr(c.badge))
                          : _text(LibraryStrings.badge(c.badge))),
                  tone: _tone(c.badge),
                ),
              ),
              const SizedBox(height: 10),
              // The lesson count is CONTENT truth and belongs on an openable
              // card; on a gated one it would read as an inventory the user can
              // reach. Both are shown, worded to say which is which.
              Text(
                _lessonLine(c),
                style: ChoreiaType.of(context).label(
                    size: 10, color: ChoreiaPalette.of(context).text(0.48)),
              ),
              if (!writtenCourse && _reason(c) != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _reason(c)!,
                  style: ChoreiaType.of(context).body(
                    size: 12.5,
                    color: ChoreiaPalette.of(context).text(0.72),
                  ),
                ),
              ],
              if (writtenCourse) ...<Widget>[
                const SizedBox(height: 12),
                if (c.badge == StyleBadge.builtButGated && _reason(c) != null)
                  Text(
                    '${_pair('Camera references', 'Kamera referansları')}: ${_reason(c)}',
                    style: ChoreiaType.of(context).body(size: 12.5),
                  ),
                Text(
                  LibraryStrings.sessionNotice(widget.cameraSessionsAvailable,
                      turkish: _tr),
                  style: ChoreiaType.of(context).body(size: 12.5),
                ),
                const SizedBox(height: 12),
                WrittenCourseLink(styleId: c.entry.id, env: widget.env),
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
            border:
                Border.all(color: ChoreiaPalette.of(context).hairline(0.10)),
          ),
          child: TitleWithPill(
            title: Text(
              _text(StyleContentCopy.styleName(c.entry, turkish: _tr)),
              style: ChoreiaType.of(context).body(
                  size: 13.5, color: ChoreiaPalette.of(context).text(0.8)),
            ),
            pill: StatusPill(
              label: _tr
                  ? _text(LibraryStrings.badgeTr(c.badge))
                  : _text(LibraryStrings.badge(c.badge)),
              tone: _tone(c.badge),
              filled: false,
            ),
          ),
        ),
      );

  Widget _tappable(StyleCard c, Widget child) => Semantics(
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: child,
            ),
          ),
        ),
      );

  /// The user-facing reason a style is shut, taken from the DERIVATION rather
  /// than written here. One source of truth: `AvailabilityStrings` already
  /// owns this copy and is tested against leaking technical text.
  String? _reason(StyleCard c) {
    final source = StyleStatusCopy.reason(c, turkish: false);
    return source == null
        ? null
        : _pair(source, StyleStatusCopy.reason(c, turkish: true) ?? source);
  }

  Color _tone(StyleBadge b) =>
      badgeTone(b, palette: ChoreiaPalette.of(context));
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
Color badgeTone(StyleBadge b, {ChoreiaPalette palette = ChoreiaPalette.dark}) =>
    switch (b) {
      // roseBright, not rose (C-159). Raising the demo-only badge to the
      // legibility floor in C-156 pushed it PAST the graded one — 9.59 against
      // 8.08, so "not graded" was reading louder than "graded". The brief's
      // promise has two sides: a floor (demo-only must not look second class)
      // and a ceiling (it must not look FIRST class either). Using the
      // palette's existing brighter rose puts them level at 1.017x, which
      // leaves the distinction where it belongs — in the HUE, not the volume.
      StyleBadge.scored => palette.roseBright,
      StyleBadge.openUngraded => palette.amber,
      StyleBadge.builtButGated => palette.amber,
      StyleBadge.onHold => palette.amberDeep,
      // 0.65, not 0.35. At 0.35 this measured 2.58:1 — below even the 3.0
      // WCAG asks of non-text, on the badge worn by 31 of the 34 tiles. An
      // honest state nobody can see is the same as saying nothing (C-156).
      // It is still the quietest tone here; quiet is not the same as invisible.
      StyleBadge.inPreparation => palette.text(0.65),
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
  static String sessionNotice(bool available, {bool turkish = false}) => turkish
      ? (available
          ? 'Kamera seansları cihaz izni ve erişim kontrolü gerektirir. Puansız canlı pratik seanslarına puan verilmez.'
          : 'Bu sürümde kamera çalışması ve puanlama kapalı. Referanslar oynatılabilir bir önizleme değildir.')
      : (available
          ? 'Camera sessions require device permission and access checks. Demo-only live practice is not scored.'
          : 'Camera practice and scoring are unavailable in this release. References are not a playable preview.');

  static String availabilityLine(LibraryTally t,
          {bool cameraSessionsAvailable = false}) =>
      '${t.openable} ${t.openable == 1 ? 'style has' : 'styles have'} camera-session reference notes. '
      '${sessionNotice(cameraSessionsAvailable)} Use the written courses below '
      'for guided lessons. Other catalogue entries show their current status.';

  static String availabilityLineTr(LibraryTally t,
          {bool cameraSessionsAvailable = false}) =>
      '${t.openable} stilde kamera seansı referans notları var. '
      '${sessionNotice(cameraSessionsAvailable, turkish: true)} Rehberli dersler '
      'için aşağıdaki yazılı kursları kullan. Diğer girdiler mevcut durumlarıyla gösterilir.';

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
          {bool cameraSessionsAvailable = false}) =>
      switch (b) {
        StyleBadge.scored ||
        StyleBadge.openUngraded =>
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
          {bool cameraSessionsAvailable = false}) =>
      switch (b) {
        StyleBadge.scored ||
        StyleBadge.openUngraded =>
          'Yazılı açıklamaları ve kayıtlı referansları oku. ${sessionNotice(cameraSessionsAvailable, turkish: true)}',
        StyleBadge.builtButGated =>
          'Referans notları yazılmış; bu stilin içerik kontrolleri tamamlanmamış. ${sessionNotice(cameraSessionsAvailable, turkish: true)}',
        StyleBadge.inPreparation =>
          'Stil adı katalogda var; arkasında açılabilir bir ders yok.',
        StyleBadge.onHold => 'Bu stil duraklatıldı. Gerekçesi stil sayfasında.',
      };

  static String lessonLineTr(StyleCard c,
      {required int startable, bool cameraSessionsAvailable = false}) {
    if (WrittenCourseLink.supports(c.entry.id)) {
      return cameraSessionsAvailable
          ? 'YAZILI KURS AÇIK · $startable KAMERA REFERANSI HAZIR'
          : 'YAZILI KURS AÇIK · KAMERA KAPALI · PUAN YOK';
    }
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
    if (WrittenCourseLink.supports(c.entry.id)) {
      return cameraSessionsAvailable
          ? 'WRITTEN COURSE AVAILABLE · $startable CAMERA REFERENCES READY'
          : 'WRITTEN COURSE AVAILABLE · CAMERA OFF · NO SCORING';
    }
    if (c.lessons.isEmpty) return 'NO LESSONS BUILT';
    final int total = c.lessons.length;
    return cameraSessionsAvailable
        ? '$total LESSONS WRITTEN · $startable CAMERA REFERENCES READY'
        : '$total LESSONS WRITTEN · CAMERA OFF · NO SCORING';
  }
}
