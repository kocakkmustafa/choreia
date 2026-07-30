import 'package:motion_core/motion_core.dart';

import 'course_catalog.dart';
import 'recorded_summary.dart';

/// One row of the **Recorded** section: MEASUREMENTS only.
///
/// Every lesson appears here, graded or not. The reasoning chain (UI-BRIEF
/// §3.9): K8 closes the SCORE, not the fact · "I worked through this lesson
/// start to finish" is a measurement that needs no camera · "you did it well"
/// is a JUDGEMENT and a demo-only lesson has none by definition · withholding
/// the completion mark too would make the lesson second class, which is exactly
/// what K10 exists to prevent.
final class RecordedRow {
  const RecordedRow({
    required this.lessonId,
    required this.displayName,
    required this.lessonClass,
    required this.sessions,
    required this.workedSeconds,
    required this.cyclesCompleted,
    required this.plannedCycles,
    required this.completedSessions,
    required this.unmeasuredCycles,
  });

  final String lessonId;
  final String displayName;

  /// The class RECORDED at write time, not derived from today's content.
  /// A lesson's class changes (`ss_l1_basic` has a promotion path); deriving it
  /// at read time would make pre-promotion sessions retroactively look scored.
  ///
  /// A STRING since the core promotion (M-F-193): the vocabulary is open and
  /// each app owns its words. The safety property is unchanged and now lives in
  /// exactly one place — only `'scored'` reads as scored, so an unknown class
  /// can never over-claim.
  final String lessonClass;

  final int sessions;
  final int workedSeconds;
  final int cyclesCompleted;
  final int plannedCycles;
  final int completedSessions;

  /// Cycles attempted but not judgeable. Kept per row so the surface can say
  /// which lesson the unmeasured work happened in — an aggregate alone would
  /// tell the user something went unmeasured without saying where.
  final int unmeasuredCycles;

  bool get isDemoOnly => lessonClass != ChoreiaLessonClass.scored;
}

/// One row of the **Evaluated** section: JUDGEMENTS.
///
/// Nothing constructs this today, and that is the honest state rather than a
/// gap: [SessionRecord] deliberately carries no judgement field, because
/// recording zeros while there is no camera bridge would mean drawing zeros on
/// a progress chart tomorrow. The class exists so the section has a SHAPE the
/// design pass can lay out, and so the day a judgement arrives it lands in the
/// section that was always reserved for it — never merged into Recorded.
final class EvaluatedRow {
  const EvaluatedRow({
    required this.lessonId,
    required this.displayName,
    required this.band,
  });

  final String lessonId;
  final String displayName;

  /// The judgement, in the user's language. Never a number without a band: a
  /// bare figure invites comparison the measurement cannot support.
  final String band;
}

/// The progress surface's data layer — TWO SECTIONS THAT CANNOT MERGE (M-F-156).
///
/// The type enforces the separation that a screen is supposed to show: there is
/// no field holding "all rows", so a surface cannot accidentally render one
/// list. Putting the contract in the type rather than in a comment is the same
/// move as kural-7 in `DanceJudge` — the side-dependent verdict is never
/// FORMED, not merely hidden.
final class ProgressSummary {
  const ProgressSummary({
    required this.recorded,
    required this.evaluated,
    required this.evaluatedUnavailableReason,
    required this.blockedGates,
    required this.totals,
  });

  /// Facts about what was practised. All lessons.
  final List<RecordedRow> recorded;

  /// Judgements. Only scored lessons ever appear; today always empty.
  final List<EvaluatedRow> evaluated;

  /// Why [evaluated] is empty, or null if it is not empty.
  ///
  /// A section that renders blank says "you have not earned anything yet",
  /// which is a claim about the USER. The true statement is about the PRODUCT,
  /// and it has to be on the screen (J-066: silence is a lie).
  final String? evaluatedUnavailableReason;

  /// Gates that cannot be passed today, derived from content.
  final List<BlockedGate> blockedGates;

  final RecordedSummary totals;

  /// Time already worked does NOT become retroactive credit when a gate opens.
  ///
  /// Stated on the surface because the storage design already guarantees it and
  /// the guarantee is invisible otherwise: `lessonClass` is stamped at write
  /// time, so resolving BPM tomorrow cannot reach back and re-grade sessions
  /// danced without a beat grid. A product that quietly back-filled scores
  /// would be inventing evidence about performances it never observed.
  static const String retroactiveCreditNote =
      'When a check opens up later, it applies from that point on. Practice '
      'time already recorded stays a record of practice — it is not converted '
      'into a score for something we were not measuring at the time.';

  factory ProgressSummary.build({
    required List<SessionRecord> history,
    required CourseCatalog catalog,
    required RecordedSummary totals,
  }) {
    final Map<String, List<SessionRecord>> byLesson =
        <String, List<SessionRecord>>{};
    for (final SessionRecord r in history) {
      byLesson.putIfAbsent(r.lessonId, () => <SessionRecord>[]).add(r);
    }

    final List<RecordedRow> recorded = <RecordedRow>[];
    for (final MapEntry<String, List<SessionRecord>> e in byLesson.entries) {
      final List<SessionRecord> rows = e.value;
      // The class comes from the RECORDS, not from the catalog, and the more
      // cautious one wins across a promotion: claiming the whole history is
      // scored because the lesson is scored TODAY would over-claim exactly the
      // sessions that were not.
      final bool anyDemoOnly = rows.any((SessionRecord r) => !r.isScoredClass);
      recorded.add(RecordedRow(
        lessonId: e.key,
        displayName: catalog.lessonById(e.key)?.displayName ?? e.key,
        lessonClass: anyDemoOnly
            ? ChoreiaLessonClass.demoOnly
            : ChoreiaLessonClass.scored,
        sessions: rows.length,
        workedSeconds: rows.fold(0, (int a, SessionRecord r) => a + r.workedSeconds),
        cyclesCompleted:
            rows.fold(0, (int a, SessionRecord r) => a + r.unitsCompleted),
        plannedCycles:
            rows.fold(0, (int a, SessionRecord r) => a + r.plannedUnits),
        completedSessions: rows.where((SessionRecord r) => r.isComplete).length,
        unmeasuredCycles:
            rows.fold(0, (int a, SessionRecord r) => a + r.unmeasuredUnits),
      ));
    }
    recorded.sort((a, b) => a.displayName.compareTo(b.displayName));

    // No judgement is stored, so none is reported. The reason names the missing
    // MECHANISM, not a missing effort by the user.
    const String reason =
        'No lesson has been graded yet. Grading needs the camera check, and '
        'that is not wired up in this build — so there is nothing here rather '
        'than a zero. Zeros would look like results.';

    return ProgressSummary(
      recorded: recorded,
      evaluated: const <EvaluatedRow>[],
      evaluatedUnavailableReason: reason,
      blockedGates: catalog.blockedGates,
      totals: totals,
    );
  }

  static Future<ProgressSummary> from({
    required SessionStore store,
    required CourseCatalog catalog,
  }) async =>
      ProgressSummary.build(
        history: await store.recent(),
        catalog: catalog,
        totals: await RecordedSummary.from(store),
      );

  bool get hasHistory => recorded.isNotEmpty;
}

/// Every user-facing string of the progress surface, in one place.
///
/// Not an i18n framework — a SEAM. SCHEMA.md binds the product language to EN
/// with translation keys from the start; a single class means the translation
/// wave edits one file instead of hunting a widget tree, without pretending the
/// l10n infrastructure exists yet.
///
/// **Units are part of the string, never left to the caller.** JabLab's K8
/// lesson: a bare number on a progress surface reads as a score.
abstract final class ProgressStrings {
  static const String recordedSection = 'Recorded';
  static const String recordedSubtitle =
      'What you practised. Measured, not graded.';

  static const String evaluatedSection = 'Evaluated';
  static const String evaluatedSubtitle =
      'Judgements about how you did. Graded lessons only.';

  static const String blockedSection = 'What we cannot check yet';
  static const String blockedSubtitle =
      'Named, with the reason. We would rather tell you than leave it out.';

  static const String emptyHistory =
      'No practice recorded yet. Nothing has been hidden — there is simply '
      'nothing here.';

  /// The band column for a demo-only lesson: a mark that there IS no judgement,
  /// which is different from a judgement of zero.
  static const String noBand = '—';

  static String duration(int seconds) {
    final int m = seconds ~/ 60;
    if (m < 60) return '$m min practised';
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0 ? '${h}h practised' : '${h}h ${rem}m practised';
  }

  static String cycles(int completed, int planned) =>
      '$completed of $planned cycles';

  static String sessionsCompleted(int completed, int total) =>
      '$completed of $total sessions finished';

  static String demoOnlyMark(String? reason) =>
      reason == null ? 'Taught, not graded' : 'Taught, not graded — $reason';

  /// Cycles the learner did that could not be judged.
  ///
  /// Shown rather than quietly dropped: without this line the screen would say
  /// "8 of 8 cycles" for a session where one went unmeasured, which is the
  /// silence the core's `unmeasuredUnits` field exists to prevent. Phrased so
  /// the fault is the product's, not the dancer's.
  static String unmeasured(int cycles) => cycles == 1
      ? '1 cycle we could not check (framing or lighting)'
      : '$cycles cycles we could not check (framing or lighting)';
}
