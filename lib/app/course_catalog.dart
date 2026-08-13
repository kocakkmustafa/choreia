import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

/// What the product will actually DO with a lesson, as content declares it.
///
/// Three classes, not two: `locked` is not a weaker `demoOnly`. A demo-only
/// lesson OPENS and teaches; a locked one cannot be opened at all because the
/// measurement behind it does not exist yet. Collapsing them would let a style
/// with nothing but locked lessons advertise itself as openable — the
/// under/over-claiming pair the status lattice exists to prevent.
enum LessonKind { scored, demoOnly, locked }

/// One lesson as content declares it. No progress, no history — that belongs to
/// [ProgressSummary]; this is the CATALOG half.
final class LessonInfo {
  const LessonInfo({
    required this.id,
    required this.styleId,
    required this.level,
    required this.displayName,
    required this.kind,
    required this.plannedMinutes,
    this.cycleTarget,
    this.stepId,
    this.reason,
    this.demoOnlyClass,
    this.whyPermanent,
  });

  final String id;
  final String styleId;
  final int level;
  final String displayName;
  final LessonKind kind;

  /// The movement this lesson teaches, when it names one.
  ///
  /// Null for most lessons, and that is content being accurate rather than
  /// incomplete: a drill ("keep the steps small") corrects an error across a
  /// step rather than being one, and an ungradeable lesson like "finding the 1"
  /// has no movement to point at. Only a lesson with a step could ever run the
  /// live path — see `LibraryCatalog.runnableSteps` for the second condition.
  final String? stepId;

  /// Content's own estimate, in MINUTES. Carried as a number with its unit
  /// named in the field, so a surface cannot render it as a bare figure.
  final int plannedMinutes;

  /// How many cycles this lesson IS, when content declares a number.
  ///
  /// **Null is the normal case and it is a DECLARATION, not a gap** — no
  /// lesson shipping today names one, because naming one requires a measured
  /// basis (`cycleTargetBasis`, enforced by `validate_content.py`) and nothing
  /// in this content has one yet. A ratio is a claim about a plan; inventing
  /// the plan to have something to divide by is how "6 of 8 cycles" ends up on
  /// a screen blaming the learner for a number this app made up.
  ///
  /// Typed `int?` rather than sentinel-zero HERE, at the product boundary,
  /// even though the family's `SessionRecord.plannedUnits` is a non-nullable
  /// `int` and absence crosses that wire as `0`. The encoding lives in exactly
  /// one place (`SessionTally.toRecord`); every reader above it gets a type
  /// that cannot be confused with a target of nothing.
  final int? cycleTarget;

  /// Why this lesson is not scored, in the user's language. Non-null whenever
  /// [kind] is not [LessonKind.scored]: an ungraded lesson without a stated
  /// reason is the silence K10 forbids.
  final String? reason;

  /// `permanent` | `structural-circular` — only for demo-only lessons.
  final String? demoOnlyClass;

  /// Why this lesson will NEVER be scored, in the learner's language.
  ///
  /// The deepest honesty text in the whole app, and until 2026-08-07 nothing
  /// read it: 11 lessons carried 184-383 characters each explaining that a
  /// limit is permanent rather than pending, and every one of them was dropped
  /// on the floor by a parser that did not know the key (C-167).
  ///
  /// `demoOnlyReason` says what is not scored. THIS says the limit will not
  /// lift — and those are different promises. Without it, a reader can take
  /// every ungraded lesson as a queue.
  final String? whyPermanent;

  bool get isScored => kind == LessonKind.scored;
}

/// Where a blocked gate was declared. The three are separate because they
/// answer different user questions.
enum GateScope {
  /// Style-wide release gate (`style.json` `shipGates[]`): nothing in this
  /// style ships until it clears.
  style,

  /// One error code the judge will not compute (`steps/*.json`
  /// `errors[].status == "blocked"`): the lesson runs, this check does not.
  errorCode,

  /// One lesson that cannot be graded at all (`demoOnly` / `locked`).
  lesson,
}

/// A gate that CANNOT be passed today, with the measured reason.
///
/// Derived from content, never written as prose on a screen. A hand-written
/// list would go stale the moment BPM lands — and a screen whose job is "we
/// tell you what we cannot do" must not be the thing that lies. This is the
/// same reasoning as `beats: null` + a named `beatsStatus` rather than a
/// plausible default.
final class BlockedGate {
  const BlockedGate({
    required this.scope,
    required this.id,
    required this.why,
    this.unblockedBy,
  });

  final GateScope scope;

  /// `bpmResolved`, `NO_WEIGHT_TRANSFER`, `ss_l1_basic` …
  final String id;
  final String why;

  /// What would lift THIS gate. Null when content does not name one — and a
  /// null here is itself information: nobody has written down the way out.
  final String? unblockedBy;
}

/// The content side of the progress surface: lessons plus what is blocked.
///
/// Constructed from parsed JSON so tests build it directly; [load] is the thin
/// runtime path over the asset bundle. Keeping the pure constructor primary is
/// deliberate — the interesting behaviour is the DERIVATION of blocked gates,
/// and a test that needs an asset bundle to exercise it would be testing
/// Flutter, not the derivation.
final class CourseCatalog {
  const CourseCatalog({
    required this.lessons,
    required this.blockedGates,
    this.unreadableSteps = const <String>{},
  });

  /// Reads one style document plus its step documents.
  ///
  /// `steps` is keyed by step id, because a lesson points at a step and the
  /// blocked error codes live on the STEP, not the lesson.
  factory CourseCatalog.fromStyles(
    List<Map<String, dynamic>> styles, {
    Map<String, Map<String, dynamic>> steps = const {},
    Set<String> unreadableSteps = const <String>{},
  }) {
    final List<LessonInfo> lessons = <LessonInfo>[];
    final List<BlockedGate> gates = <BlockedGate>[];
    final Set<String> seenStepGates = <String>{};

    for (final Map<String, dynamic> style in styles) {
      final String styleId = style['id'] as String;

      for (final Object? raw in (style['shipGates'] as List? ?? const [])) {
        final Map<String, dynamic> gate = (raw as Map).cast<String, dynamic>();
        if (gate['blocked'] != true) continue;
        gates.add(BlockedGate(
          scope: GateScope.style,
          id: gate['gate'] as String,
          why: gate['why'] as String? ?? '',
          unblockedBy: gate['unblockedBy'] as String?,
        ));
      }

      for (final Object? rawLevel in (style['levels'] as List? ?? const [])) {
        final Map<String, dynamic> level =
            (rawLevel as Map).cast<String, dynamic>();
        for (final Object? rawLesson
            in (level['lessons'] as List? ?? const [])) {
          final Map<String, dynamic> l =
              (rawLesson as Map).cast<String, dynamic>();
          final LessonKind kind = l['scored'] == true
              ? LessonKind.scored
              : l['demoOnly'] == true
                  ? LessonKind.demoOnly
                  : LessonKind.locked;
          final String? reason = _en(l['demoOnlyReason']) ?? _en(l['lockedReason']);

          lessons.add(LessonInfo(
            id: l['id'] as String,
            styleId: styleId,
            level: (level['level'] as num).toInt(),
            displayName: _en(l['displayName']) ?? l['id'] as String,
            kind: kind,
            plannedMinutes: (l['minutes'] as num?)?.toInt() ?? 0,
            // No `?? 0` twin here, deliberately: `plannedMinutes` falls back to
            // zero because a missing estimate and a zero-minute lesson are both
            // just "no time shown", while a missing TARGET and a target of zero
            // are different claims. The absent case must survive as null all
            // the way to the one line that encodes it for the wire.
            cycleTarget: (l['cycleTarget'] as num?)?.toInt(),
            stepId: l['step'] as String?,
            reason: reason,
            demoOnlyClass: l['demoOnlyClass'] as String?,
            whyPermanent: _en(l['whyPermanent']),
          ));

          if (kind != LessonKind.scored) {
            gates.add(BlockedGate(
              scope: GateScope.lesson,
              id: l['id'] as String,
              // An ungraded lesson with no stated reason must not render as a
              // blank: the empty string would read as "no reason needed".
              why: reason ?? 'No reason recorded in content.',
              unblockedBy: l['promotionPath'] is Map
                  ? (l['promotionPath'] as Map)['unblockedBy'] as String?
                  : null,
            ));
          }

          // Blocked error codes come from the STEP this lesson teaches. Two
          // lessons can share a step, so the same gate is emitted once.
          final Object? stepId = l['step'];
          final Map<String, dynamic>? step =
              stepId is String ? steps[stepId] : null;

          // A MISSING step document is not "this step has no blocked checks".
          // Content legitimately contains a lesson whose step is not written
          // yet (`hh_l1_rock`: "this step's movement description isn't finished
          // yet"), and reading that absence as a clean bill of health would
          // make the screen say "nothing here needs checking" when the truth is
          // "we do not know". Same ruling as `beats: null` plus a named
          // `beatsStatus` instead of a plausible default — absence travels as
          // absence.
          if (step == null && stepId is String && stepId.isNotEmpty) {
            if (unreadableSteps.contains(stepId) &&
                seenStepGates.add('missing/$stepId')) {
              gates.add(BlockedGate(
                scope: GateScope.errorCode,
                id: stepId,
                why: 'The movement description for this step is not written, '
                    'so we cannot say which checks it needs — not that it '
                    'needs none.',
              ));
            }
            continue;
          }
          if (step == null) continue;
          // The step document's key is `errors` — checked against the real
          // files, not assumed. My first fixture said `errorCodes` and 17 unit
          // tests went green against a schema that does not exist; the
          // real-content test is what refuted it. A hand-built fixture agrees
          // with whatever its author believed.
          for (final Object? rawCode
              in (step['errors'] as List? ?? const [])) {
            final Map<String, dynamic> code =
                (rawCode as Map).cast<String, dynamic>();
            if (code['status'] != 'blocked') continue;
            final String key = '$stepId/${code['code']}';
            if (!seenStepGates.add(key)) continue;
            gates.add(BlockedGate(
              scope: GateScope.errorCode,
              id: code['code'] as String,
              why: code['blockedBy'] as String? ?? '',
              unblockedBy: code['unblockedBy'] as String?,
            ));
          }
        }
      }
    }

    return CourseCatalog(
      lessons: lessons,
      blockedGates: gates,
      unreadableSteps: unreadableSteps,
    );
  }

  /// Runtime path: reads the declared content assets.
  static Future<CourseCatalog> load(
    AssetBundle bundle, {
    List<String> styleIds = const ['salsa_shines', 'hip_hop_foundations'],
  }) async {
    final List<Map<String, dynamic>> styles = <Map<String, dynamic>>[];
    final Map<String, Map<String, dynamic>> steps =
        <String, Map<String, dynamic>>{};
    final Set<String> unreadable = <String>{};

    for (final String id in styleIds) {
      // A missing STYLE document is a different matter and is NOT tolerated:
      // the caller named this style, so its absence is a wiring error, not a
      // content state. Failing loudly here is the difference between "this
      // style teaches nothing yet" (content says so) and "we never loaded it".
      final Map<String, dynamic> style = (jsonDecode(
              await bundle.loadString('content/styles/$id/style.json')) as Map)
          .cast<String, dynamic>();
      styles.add(style);

      for (final Object? rawLevel in (style['levels'] as List? ?? const [])) {
        for (final Object? rawLesson
            in ((rawLevel as Map)['lessons'] as List? ?? const [])) {
          final Object? stepId = (rawLesson as Map)['step'];
          if (stepId is! String ||
              steps.containsKey(stepId) ||
              unreadable.contains(stepId)) {
            continue;
          }
          // A lesson may point at a step whose document is not written yet —
          // content does this on purpose for locked lessons. Recorded, not
          // swallowed: `unreadableSteps` keeps the difference between "no
          // blocked checks" and "we could not look".
          try {
            steps[stepId] = (jsonDecode(await bundle
                    .loadString('content/styles/$id/steps/$stepId.json')) as Map)
                .cast<String, dynamic>();
          } on Object {
            // `Object`, not `Exception`: Flutter raises `FlutterError` — an
            // ERROR, not an Exception — for a missing asset, so an
            // `on Exception` clause here does not catch the one failure it was
            // written for. Found by a test whose fake bundle threw the same
            // TYPE the real one does; a fake that threw `Exception` would have
            // gone green while the device path crashed.
            //
            // Catching broadly is right for this branch: the meaning is "this
            // step document could not be read", whatever the cause. It is not
            // swallowed — the id lands in `unreadableSteps` and surfaces as
            // something we cannot check.
            unreadable.add(stepId);
          }
        }
      }
    }
    return CourseCatalog.fromStyles(styles,
        steps: steps, unreadableSteps: unreadable);
  }

  final List<LessonInfo> lessons;

  /// Everything that cannot be passed today, across all three scopes.
  final List<BlockedGate> blockedGates;

  /// Steps a lesson points at whose document could not be read.
  ///
  /// Kept as its own field rather than folded into [blockedGates] alone, so a
  /// caller can tell "we listed this step's blocked checks" from "we could not
  /// look". A count of blocked gates that quietly includes unknowns would be
  /// the wrong denominator.
  final Set<String> unreadableSteps;

  LessonInfo? lessonById(String id) {
    for (final LessonInfo l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  Iterable<LessonInfo> get scoredLessons => lessons.where((l) => l.isScored);

  /// Product language is EN (plan §3); content carries `{en: ...}` maps from the
  /// start so the translation wave is a content pass, not a code change.
  static String? _en(Object? value) {
    if (value is Map) return value['en'] as String?;
    if (value is String) return value;
    return null;
  }
}
