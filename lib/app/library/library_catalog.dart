import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../course_catalog.dart';
import '../style_availability.dart';

/// The catalogue half of the Library surface: all 34 styles, derived.
///
/// Where the 34 come from
/// ----------------------
/// `content/library.json` — a REAL, versioned content document, not a screen's
/// private list. This matters enough to write down, because the design-ahead
/// inventory (`docs/design/DESIGN-AHEAD-OF-CODE.md` §2 and its addendum) says
/// twice that this file does not exist and that the 32 unbuilt styles live
/// "only inside `Choreia.dc.html`'s own mock `WAVES` array". **Measured
/// 2026-08-07: that is wrong.** The file is 15.6 KB, carries all 34 entries
/// with `status`, `wave`, `legalFlag`, `onHoldReason` and `brandWarning`, and
/// is already shipped as an asset. Nothing on this screen is hand-listed.
///
/// That correction is the whole reason this file can obey the app's own rule
/// that derived lists are never written by hand: the roadmap IS content.
///
/// Why gates are held per style and never flattened
/// ------------------------------------------------
/// [BlockedGate] carries no style id. `CourseCatalog.fromStyles` accepts a LIST
/// of styles and flattens their gates into one list, which is unambiguous for
/// one style and lossy for two — salsa's BPM gate and a hip-hop gate would be
/// indistinguishable in the flattened list. Rather than add a field that a
/// future caller could forget to set, this class keeps **one catalogue per
/// style**, so mixing them up is not a mistake you can make (family lesson 7:
/// prefer the structure in which the error is impossible over the fix).
final class LibraryCatalog {
  const LibraryCatalog({required this.entries, required this.coursesByStyle});

  /// Reads `content/library.json` plus the style documents that exist on disk.
  ///
  /// `diskStyleIds` names the styles whose `style.json` is authored. It is a
  /// parameter rather than a scan because the asset bundle cannot be listed,
  /// and because a style whose document is expected but missing must fail
  /// loudly (`CourseCatalog.load`'s own rule) instead of quietly degrading to
  /// "this style teaches nothing".
  static Future<LibraryCatalog> load(
    AssetBundle bundle, {
    List<String> diskStyleIds = const <String>[
      'salsa_shines',
      'hip_hop_foundations',
    ],
  }) async {
    final Map<String, dynamic> doc =
        (jsonDecode(await bundle.loadString('content/library.json')) as Map)
            .cast<String, dynamic>();

    final Map<String, CourseCatalog> courses = <String, CourseCatalog>{};
    for (final String id in diskStyleIds) {
      courses[id] = await CourseCatalog.load(bundle, styleIds: <String>[id]);
    }

    return LibraryCatalog(
      entries: <LibraryEntry>[
        for (final Object? raw in (doc['styles'] as List? ?? const []))
          LibraryEntry.fromJson((raw as Map).cast<String, dynamic>()),
      ],
      coursesByStyle: courses,
    );
  }

  /// Every style the catalogue declares, in the file's own order.
  final List<LibraryEntry> entries;

  /// Loaded course documents, keyed by style id. Absent for a style whose
  /// `style.json` is not authored — which is most of them, and is not an error.
  final Map<String, CourseCatalog> coursesByStyle;

  /// One card per style: the declared entry plus its DERIVED availability.
  ///
  /// Computed on every call, never cached — same reasoning as
  /// [StyleView.derive] itself. The moment the BPM gate opens, every surface
  /// must change together, and that only holds while nobody stored the answer.
  List<StyleCard> get cards => <StyleCard>[
        for (final LibraryEntry e in entries)
          StyleCard(
            entry: e,
            view: StyleView.derive(
              styleId: e.id,
              contentStatus: e.contentStatus,
              blockedGates:
                  coursesByStyle[e.id]?.blockedGates ?? const <BlockedGate>[],
            ),
            courses: coursesByStyle[e.id],
          ),
      ];

  StyleCard? cardFor(String styleId) {
    for (final StyleCard c in cards) {
      if (c.entry.id == styleId) return c;
    }
    return null;
  }
}

/// One style as `library.json` declares it. Declaration only — nothing here is
/// a judgement about whether the user can open it; that is [StyleCard.view].
final class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.displayName,
    required this.contentStatus,
    this.wave,
    this.legalFlag,
    this.onHoldReason,
    this.originAttribution,
    this.brandWarning,
    this.safetyOnboarding,
    this.cautionClass,
    this.pack,
    this.hardwareRequired = const <String>[],
    this.safetyExclusions = const <String>[],
    this.subDances = const <String>[],
  });

  factory LibraryEntry.fromJson(Map<String, dynamic> json) => LibraryEntry(
        id: json['id'] as String,
        displayName: _en(json['name']) ?? json['id'] as String,
        contentStatus: json['status'] as String?,
        wave: (json['wave'] as num?)?.toInt(),
        legalFlag: json['legalFlag'] as String?,
        onHoldReason: json['onHoldReason'] as String?,
        originAttribution: json['originAttribution'] as String?,
        brandWarning: json['brandWarning'] as String?,
        safetyOnboarding: json['safetyOnboarding'] as String?,
        cautionClass: json['cautionClass'] as String?,
        pack: json['pack'] as String?,
        hardwareRequired: _strings(json['hardwareRequired']),
        safetyExclusions: _strings(json['safetyExclusions']),
        subDances: _strings(json['subDances']),
      );

  final String id;
  final String displayName;

  /// The library lattice value: `live` | `demoOpen` | `comingSoon` | `onHold`.
  final String? contentStatus;

  /// Rollout order. Null for a style outside the waves (`hula`, on hold).
  ///
  /// Deliberately NOT surfaced as a date or a position in a queue — a wave is
  /// engineering sequence, and rendering it as "coming in wave 3" would turn a
  /// build order into a promise.
  final int? wave;

  final String? legalFlag;

  /// Why this style is parked, in content's own words. Shown, never hidden.
  final String? onHoldReason;

  /// Whose dance this is. Measured 2026-08-07: present on 1 of 34 entries
  /// (`vogue`). Its absence elsewhere is a CONTENT gap, not a schema gap — see
  /// [StyleCard.attributionIsMissing].
  final String? originAttribution;

  /// A trademark that must not appear in copy (`latin_fusion_fitness`).
  final String? brandWarning;

  final String? safetyOnboarding;
  final String? cautionClass;
  final String? pack;
  final List<String> hardwareRequired;
  final List<String> safetyExclusions;
  final List<String> subDances;

  static List<String> _strings(Object? v) => v is List
      ? <String>[for (final Object? e in v) if (e is String) e]
      : const <String>[];

  static String? _en(Object? value) {
    if (value is Map) return value['en'] as String?;
    if (value is String) return value;
    return null;
  }
}

/// What a library tile actually says.
///
/// FOUR, where the design drew three. The extra one is [builtButGated], and it
/// exists because the app's own derivation already distinguishes a case the
/// mockup's three badges cannot express: `salsa_shines` is BOTH `live` (its
/// scored lesson is real and tested) AND unopenable (its BPM gate is closed).
///
/// Collapsing that into [inPreparation] would under-sell finished work;
/// collapsing it into [scored] would promise a door that does not open. Both
/// directions are the same defect — presenting one axis as a proxy for the
/// other — which is exactly what `style_availability.dart` was written to stop.
enum StyleBadge { scored, openUngraded, builtButGated, inPreparation, onHold }

/// One style, ready to render: declaration + derivation held apart.
final class StyleCard {
  const StyleCard({required this.entry, required this.view, this.courses});

  final LibraryEntry entry;

  /// The derived answer to "can this be opened, and if not, why".
  final StyleView view;

  /// Present only for the styles whose documents exist on disk.
  final CourseCatalog? courses;

  StyleBadge get badge {
    switch (view.availability) {
      case Availability.onHold:
        return StyleBadge.onHold;
      case Availability.gatedByRelease:
        return StyleBadge.builtButGated;
      case Availability.openable:
        return entry.contentStatus == 'live'
            ? StyleBadge.scored
            : StyleBadge.openUngraded;
      case Availability.comingSoon:
      case Availability.excluded:
        return StyleBadge.inPreparation;
    }
  }

  bool get isOpenable => view.isOpenable;

  /// Lessons this style declares, or empty when its document is not authored.
  List<LessonInfo> get lessons => courses?.lessons ?? const <LessonInfo>[];

  int get scoredLessonCount => lessons.where((LessonInfo l) => l.isScored).length;

  /// A style whose culture is named nowhere. Rendered as a visible, named gap
  /// rather than an empty box: an attribution box that is simply absent looks
  /// like a style with no lineage, which is never true of a dance.
  bool get attributionIsMissing =>
      (entry.originAttribution == null || entry.originAttribution!.isEmpty);
}

/// The counts above the grid.
///
/// Derived from [StyleCard.badge], NOT from `library.json`'s raw `status`
/// field. The two disagree today and the disagreement is the point: content
/// says "1 live · 1 demoOpen · 31 comingSoon · 1 onHold", but the surface truth
/// is that the one `live` style cannot be opened, so a panel repeating the
/// content counts would tell a dancer they have a scored style to practise when
/// they do not.
final class LibraryTally {
  const LibraryTally({
    required this.total,
    required this.scored,
    required this.openUngraded,
    required this.builtButGated,
    required this.inPreparation,
    required this.onHold,
  });

  factory LibraryTally.from(List<StyleCard> cards) {
    int scored = 0, open = 0, gated = 0, prep = 0, hold = 0;
    for (final StyleCard c in cards) {
      switch (c.badge) {
        case StyleBadge.scored:
          scored++;
        case StyleBadge.openUngraded:
          open++;
        case StyleBadge.builtButGated:
          gated++;
        case StyleBadge.inPreparation:
          prep++;
        case StyleBadge.onHold:
          hold++;
      }
    }
    return LibraryTally(
      total: cards.length,
      scored: scored,
      openUngraded: open,
      builtButGated: gated,
      inPreparation: prep,
      onHold: hold,
    );
  }

  final int total;
  final int scored;
  final int openUngraded;
  final int builtButGated;
  final int inPreparation;
  final int onHold;

  /// How many styles a dancer can actually open right now. The honest headline
  /// number, and deliberately not the same as [scored] + [openUngraded] being
  /// read off content.
  int get openable => scored + openUngraded;
}
