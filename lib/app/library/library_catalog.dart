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
  const LibraryCatalog({
    required this.entries,
    required this.coursesByStyle,
    this.proseByStyle = const <String, StyleProse>{},
    this.runnableSteps = const <String>{},
  });

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
    final Map<String, StyleProse> prose = <String, StyleProse>{};
    for (final String id in diskStyleIds) {
      courses[id] = await CourseCatalog.load(bundle, styleIds: <String>[id]);
      // Read a second time for the PROSE fields. `CourseCatalog` parses this
      // same document for lessons and gates and deliberately keeps none of the
      // copy — it is the catalogue half, not the page half. Re-reading a 12 KB
      // asset is cheaper than widening a tested type to carry fields it has no
      // opinion about.
      prose[id] = StyleProse.fromJson((jsonDecode(
              await bundle.loadString('content/styles/$id/style.json')) as Map)
          .cast<String, dynamic>());
    }

    // WHICH LESSONS CAN ACTUALLY RUN — probed, never assumed.
    //
    // The live path needs `content/references/<step>.json`. A lesson can name a
    // step whose reference was never built (`ss_basic`, `hh_rock`) or whose file
    // exists on disk but is not declared in `pubspec.yaml` (`hh_bounce`,
    // measured 2026-08-07). `LiveLessonPage._start` loads that asset with no
    // error handling, so offering "start" for any of them is not a cosmetic
    // mistake — it is an unhandled exception behind a button.
    //
    // Probing the real bundle is the only thing that answers this. A list of
    // "steps we think have references" would be a fourth copy of a truth that
    // already lives in the filesystem and the asset manifest, and it would be
    // wrong in exactly the `hh_bounce` case that motivated the check.
    final Set<String> runnable = <String>{};
    for (final CourseCatalog c in courses.values) {
      for (final LessonInfo l in c.lessons) {
        final String? step = l.stepId;
        if (step == null || runnable.contains(step)) continue;
        try {
          await bundle.loadString('content/references/$step.json');
          runnable.add(step);
        } on Object {
          // `Object`, not `Exception`: Flutter raises `FlutterError` — an
          // ERROR — for a missing asset, so `on Exception` would not catch the
          // one failure this probe exists for (the same trap `CourseCatalog`
          // already documents).
        }
      }
    }

    return LibraryCatalog(
      entries: <LibraryEntry>[
        for (final Object? raw in (doc['styles'] as List? ?? const []))
          LibraryEntry.fromJson((raw as Map).cast<String, dynamic>()),
      ],
      coursesByStyle: courses,
      proseByStyle: prose,
      runnableSteps: runnable,
    );
  }

  /// Every style the catalogue declares, in the file's own order.
  final List<LibraryEntry> entries;

  /// Loaded course documents, keyed by style id. Absent for a style whose
  /// `style.json` is not authored — which is most of them, and is not an error.
  final Map<String, CourseCatalog> coursesByStyle;

  /// The style page's copy, keyed by style id. Same absence rule as
  /// [coursesByStyle].
  final Map<String, StyleProse> proseByStyle;

  /// Step ids whose reference document the bundle really serves.
  ///
  /// A step's ABSENCE here means the live path cannot run for it, whatever the
  /// lesson's kind says. Measured 2026-08-07 against real content: exactly one
  /// of the four steps any lesson names clears this — and it belongs to the
  /// release-gated style, so the honest total is that no lesson in the app can
  /// be started today.
  final Set<String> runnableSteps;

  /// One card per style: the declared entry plus its DERIVED availability.
  ///
  /// Computed on every call, never cached — same reasoning as
  /// [StyleView.derive] itself. The moment the BPM gate opens, every surface
  /// must change together, and that only holds while nobody stored the answer.
  ///
  /// **`excluded` STYLES ARE NOT CARDS** (2026-08-13). `Availability.excluded`
  /// documents itself as *"Out of scope. Rendered silently — no 'why not'
  /// page"* and returns a null `userFacingReason` accordingly. But nothing
  /// enforced the silence: [StyleCard.badge] mapped `excluded` into the SAME
  /// bucket as `comingSoon` (`inPreparation`), so an out-of-scope style would
  /// have appeared in the catalogue wearing a "we are preparing this" badge
  /// **with no sentence under it** — a promise of future work for something
  /// nobody is building, and a silent unopenable surface at the same time.
  ///
  /// Two contradictory intents lived in one file and neither was wrong on its
  /// own. Nothing showed, because the population is zero: content declares
  /// `demoOpen 1 · comingSoon 31 · live 1 · onHold 1` and no `excluded` at all.
  /// ⇒ ***A BRANCH WITH NO POPULATION IS NOT A BRANCH THAT WORKS — IT IS A
  /// BRANCH NOBODY HAS SEEN.*** The library's own copy is what makes this a
  /// defect rather than a preference: it tells the reader the list IS the whole
  /// plan.
  ///
  /// The filter is here rather than at each surface on purpose: a rule applied
  /// per-screen is a rule the next screen forgets.
  List<StyleCard> get cards => <StyleCard>[
        for (final LibraryEntry e in entries)
          if (e.contentStatus != excludedStatus)
            StyleCard(
              entry: e,
              view: StyleView.derive(
                styleId: e.id,
                contentStatus: e.contentStatus,
                blockedGates:
                    coursesByStyle[e.id]?.blockedGates ?? const <BlockedGate>[],
              ),
              courses: coursesByStyle[e.id],
              prose: proseByStyle[e.id],
            ),
      ];

  /// Styles content declares OUT OF SCOPE, named so the filter above and any
  /// test can agree on one string. Zero of them today — the constant exists so
  /// the first one that appears does not have to be discovered on a screen.
  List<LibraryEntry> get excludedEntries => <LibraryEntry>[
        for (final LibraryEntry e in entries)
          if (e.contentStatus == excludedStatus) e,
      ];

  StyleCard? cardFor(String styleId) {
    for (final StyleCard c in cards) {
      if (c.entry.id == styleId) return c;
    }
    return null;
  }

  /// Every authored style as ONE catalogue, for surfaces that are cross-style.
  ///
  /// This is exactly the flattening [coursesByStyle] exists to avoid — and it
  /// is the RIGHT shape here, which is why it is a separate, named getter
  /// rather than the default. Progress asks "what can this app not check for
  /// me", and that question's answer genuinely is the union across every style;
  /// the Library and the style page ask a per-style question and must not use
  /// this. Making the union opt-in keeps the lossy direction deliberate.
  CourseCatalog get allCourses => CourseCatalog(
        lessons: <LessonInfo>[
          for (final CourseCatalog c in coursesByStyle.values) ...c.lessons,
        ],
        blockedGates: <BlockedGate>[
          for (final CourseCatalog c in coursesByStyle.values) ...c.blockedGates,
        ],
        unreadableSteps: <String>{
          for (final CourseCatalog c in coursesByStyle.values)
            ...c.unreadableSteps,
        },
      );
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
    this.description,
    this.stepGlossary = const <GlossaryEntry>[],
    this.cameraLimits = const <String>[],
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
        description: json['description'] as String?,
        cameraLimits: LibraryEntry._strings(json['cameraLimits']),
        stepGlossary: <GlossaryEntry>[
          for (final Object? g in (json['stepGlossary'] as List? ?? const []))
            GlossaryEntry(
              name: (g as Map)['name'] as String,
              gloss: g['gloss'] as String,
            ),
        ],
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

  /// What this dance is and what a person actually does in it.
  ///
  /// Null for `hula` alone, and that is the point rather than an oversight:
  /// its own on-hold reason forbids producing content from generic sources
  /// without a halau/kumu partnership, and a written description of "what you
  /// do in this dance" is exactly that. The page carries the reason instead.
  final String? description;

  /// Names a learner will hear, each with a plain one-line gloss.
  ///
  /// **VOCABULARY, NOT LESSONS.** Nothing here is taught, openable or graded,
  /// and the surface has to keep saying so — a list of step names under a
  /// style is the easiest thing on this screen to misread as a curriculum.
  ///
  /// Empty for 16 of the 34, and the omissions are deliberate: a style whose
  /// vocabulary IS the individual routine (`kpop_point`, `tiktok_format`) has
  /// no shared names to gloss, `latin_fusion_fitness` borrows its steps from
  /// styles that gloss them on their own pages, and the rest were left empty
  /// where the names could not be given with confidence. Guessing
  /// plausible-sounding step names reads as knowledge and is not — the same
  /// failure as inventing a threshold.
  final List<GlossaryEntry> stepGlossary;

  /// What one phone camera cannot see in THIS dance.
  ///
  /// The honesty block for a style that has none. The two authored styles carry
  /// a real `honesty` block — `measured` / `notMeasured`, every line traceable
  /// to a measurement someone actually took. The other 32 have no lessons and
  /// no pipeline, so they cannot have that: writing "we do not check X" about a
  /// style with nothing built would describe a product that does not exist.
  ///
  /// This says the thing that IS true of an unbuilt style — a limit of the
  /// dance and the sensor, present tense, true whether or not a lesson is ever
  /// built. Every line reuses a limit this app has already measured (toe/heel
  /// contact · weight transfer inside the noise floor · left/right on a
  /// symmetric movement · anything the dancer HEARS) rather than inventing one.
  ///
  /// Empty for `hula`, by the same rule that leaves its description empty.
  final List<String> cameraLimits;

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

/// One named step and what it means, in plain words.
final class GlossaryEntry {
  const GlossaryEntry({required this.name, required this.gloss});

  final String name;
  final String gloss;
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

/// What a style page can say about itself, in the learner's language.
///
/// Only fields that are WRITTEN FOR A READER live here. `bpmCandidates`,
/// `stepInventory` and `errorTaxonomy` are authoring state — real, useful, and
/// not addressed to a dancer — so they are deliberately absent rather than
/// paraphrased onto a screen.
final class StyleProse {
  const StyleProse({
    this.measured = const <String>[],
    this.notMeasured = const <String>[],
    this.reproductionBoundary,
  });

  factory StyleProse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> honesty =
        (json['honesty'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final Map<String, dynamic> copyright =
        (json['copyright'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return StyleProse(
      measured: LibraryEntry._strings(honesty['measured']),
      notMeasured: LibraryEntry._strings(honesty['notMeasured']),
      reproductionBoundary: copyright['boundary'] as String?,
    );
  }

  /// What this style grades, each line traceable to a measurement.
  final List<String> measured;

  /// What it deliberately does not grade, and why. Never empty on a style with
  /// a scored lesson — an unstated limit is the silence K10 forbids.
  final List<String> notMeasured;

  /// What the product does and does not reproduce from other people's work.
  ///
  /// From `copyright.boundary`. Shown NEXT TO attribution and never AS it:
  /// clearance reasoning is about our legal position, credit is about whose
  /// dance this is, and letting the first stand in for the second is precisely
  /// how an attribution box becomes decoration.
  final String? reproductionBoundary;

  bool get isEmpty =>
      measured.isEmpty && notMeasured.isEmpty && reproductionBoundary == null;
}

/// One style, ready to render: declaration + derivation held apart.
final class StyleCard {
  const StyleCard({
    required this.entry,
    required this.view,
    this.courses,
    this.prose,
  });

  final LibraryEntry entry;

  /// The derived answer to "can this be opened, and if not, why".
  final StyleView view;

  /// Present only for the styles whose documents exist on disk.
  final CourseCatalog? courses;

  /// The style page's copy. Null for a style with no authored document.
  final StyleProse? prose;

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

  /// What this style's lessons actually offer, one entry per lesson.
  ///
  /// Takes [runnableSteps] rather than reading it from anywhere, so a caller
  /// cannot accidentally ask this question without the measurement that
  /// answers it.
  List<LessonOffer> offers(Set<String> runnableSteps) => <LessonOffer>[
        for (final LessonInfo l in lessons) _offer(l, runnableSteps),
      ];

  LessonOffer _offer(LessonInfo l, Set<String> runnableSteps) {
    // ORDER IS THE MEANING. Each branch names the FIRST thing that is missing,
    // and they are ordered outermost-first: a dancer told "this movement has no
    // reference built" about a style that is shut anyway has been given a true
    // sentence that answers the wrong question.
    if (!isOpenable) {
      return LessonOffer._(l, LessonBlock.styleShut,
          entry.onHoldReason ?? view.userFacingReason);
    }
    if (l.kind == LessonKind.locked) {
      return LessonOffer._(l, LessonBlock.measurementMissing, l.reason);
    }
    if (l.stepId == null) {
      return LessonOffer._(l, LessonBlock.noLessonBuilt, l.reason);
    }
    if (!runnableSteps.contains(l.stepId)) {
      return LessonOffer._(l, LessonBlock.referenceMissing, l.reason);
    }
    return LessonOffer._(l, null, l.reason);
  }

  /// A style whose culture is named nowhere. Rendered as a visible, named gap
  /// rather than an empty box: an attribution box that is simply absent looks
  /// like a style with no lineage, which is never true of a dance.
  bool get attributionIsMissing =>
      (entry.originAttribution == null || entry.originAttribution!.isEmpty);
}

/// Why a lesson cannot be started. Null on [LessonOffer.block] means it can.
///
/// Four reasons, kept apart because they are four different sentences and three
/// different people's work: a shut style is a release decision, a missing
/// measurement is a research result, a missing reference is a build artifact,
/// and an unbuilt lesson is unwritten teaching. Collapsing them into "not
/// available" would be the same undersell the status lattice already forbids at
/// style level.
enum LessonBlock {
  /// The style itself is not open — nothing inside it can be.
  styleShut,

  /// `LessonKind.locked`: the measurement this lesson would grade does not
  /// exist. Content names which one.
  measurementMissing,

  /// The lesson names no movement, so there is no camera path to run. True of
  /// drills and of lessons about hearing rather than moving — not a defect,
  /// but not something that can be started either.
  noLessonBuilt,

  /// The lesson names a movement whose reference document the bundle does not
  /// serve. Measured, not assumed — see [LibraryCatalog.runnableSteps].
  referenceMissing,
}

/// One lesson and what the user may actually do with it.
final class LessonOffer {
  const LessonOffer._(this.lesson, this.block, this.contentReason);

  final LessonInfo lesson;

  /// Null when the lesson can be started.
  final LessonBlock? block;

  /// Content's own words about this lesson, when it has any. Carried even for a
  /// startable lesson, because a demo-only lesson that OPENS still has to say
  /// why it is not graded.
  final String? contentReason;

  bool get canStart => block == null;
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
