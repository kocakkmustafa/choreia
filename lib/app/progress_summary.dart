import 'package:motion_core/motion_core.dart';

import 'course_catalog.dart';
import 'recorded_summary.dart';

/// Keeps the data layer independent of Flutter while the view supplies its
/// current locale. Templates reach this seam before values are interpolated.
typedef ProgressMessageFormatter = String Function(
    String template, Map<String, Object> values);

String _progressMessage(String template, Map<String, Object> values,
    ProgressMessageFormatter? format) {
  if (format != null) return format(template, values);
  var result = template;
  for (final value in values.entries) {
    result = result.replaceAll('{${value.key}}', value.value.toString());
  }
  return result;
}

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
    required this.targetedSessions,
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

  /// Only sessions with a positive declared target can be finished against it.
  final int targetedSessions;
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

/// How much of the stored history this reading actually saw.
///
/// The core answers `unreadableRecords()`; it does NOT decide what a surface
/// should say about it, and that split is deliberate — the number is a fact,
/// the sentence is a product decision (core doc: "surfaces derive their own
/// three-state reading").
///
/// Three states, because two would collapse the distinction that matters:
///
///   ok          opened, nothing unreadable — totals are exact
///   partial(n)  opened, n records unreadable — totals are a FLOOR
///   unavailable could not open at all — NO numbers, because a zero here
///               would read as "you did nothing" (J-066: "hiç yapmadın ≠
///               bilmiyorum")
///
/// The measured case this exists for is JabLab's: 40 of 50 lines corrupt and
/// the summary said "10 sessions" with full confidence. The number was not
/// wrong about what it counted; it was wrong about what it CLAIMED.
enum HistoryFidelity {
  ok,
  partial,

  /// The store existed and would not open.
  unavailable,

  /// There is NO store — nothing is written at all.
  ///
  /// Separate from [unavailable] because the sentences are opposites in the
  /// way that matters to a person (C-163). "We could not open your practice
  /// history" describes a mechanism that failed; a reader takes it to mean
  /// their practice was recorded and is now out of reach. Nothing is recorded
  /// in this build, so that reassurance — "until we can read it" — is a
  /// failure mode invented for a thing that does not exist.
  ///
  /// The absence was not silent, it was TALKATIVE: the surface described the
  /// mechanism while the mechanism was missing.
  notRecorded,
}

final class HistoryIntegrity {
  const HistoryIntegrity._(
      this.fidelity, this.unreadableRecords, this.readableRecords);

  /// The store opened. [unreadable] comes from the core; [readable] is what
  /// this reading actually got, and both are needed because "some of it" and
  /// "none of it" are different sentences to a person.
  factory HistoryIntegrity.opened({
    required int unreadable,
    required int readable,
  }) =>
      HistoryIntegrity._(
        unreadable == 0 ? HistoryFidelity.ok : HistoryFidelity.partial,
        unreadable,
        readable,
      );

  /// The store could not be opened. Deliberately carries no counts: there is
  /// nothing to be a floor OF.
  static const HistoryIntegrity unavailable =
      HistoryIntegrity._(HistoryFidelity.unavailable, 0, 0);

  /// Nothing is written in this build. See [HistoryFidelity.notRecorded].
  static const HistoryIntegrity notRecorded =
      HistoryIntegrity._(HistoryFidelity.notRecorded, 0, 0);

  final HistoryFidelity fidelity;
  final int unreadableRecords;
  final int readableRecords;

  /// Whether totals may be shown at all.
  ///
  /// An EXHAUSTIVE switch, not `!= unavailable` (C-163). The `!=` form treated
  /// every future state as "show the numbers" by default, and it did exactly
  /// that the moment [HistoryFidelity.notRecorded] was added — a build that
  /// writes nothing would have shown totals for a record it never kept. The
  /// compiler now refuses a new state until someone says which side it is on.
  bool get showsTotals => switch (fidelity) {
        HistoryFidelity.ok => true,
        // A partial reading still shows numbers; it just stops calling them
        // complete.
        HistoryFidelity.partial => true,
        HistoryFidelity.unavailable => false,
        HistoryFidelity.notRecorded => false,
      };

  /// Whether an EMPTY list may be reported as "there is nothing here".
  ///
  /// 🔴 **FOUND ON SCREEN (C-280).** The Recorded section rendered
  /// `ProgressStrings.emptyHistory` — *"No practice recorded. Nothing has been
  /// hidden — there is simply nothing here."* — whenever the row list was
  /// empty, **without asking why it was empty.** During a walk the store failed
  /// to open, and the screen said, in the same view:
  ///
  ///   *"We could not open your practice history."*  (the note, correct)
  ///   *"…there is simply nothing here."*            (the section, a LIE)
  ///
  /// An unreadable history and an empty one produce the same empty list and
  /// mean opposite things. Claiming the second from the first is precisely the
  /// *"you did nothing"* statement this file avoids everywhere else — a claim
  /// about the USER manufactured out of OUR failure (J-066).
  ///
  /// Separate from [showsTotals] on purpose: that one answers *may I print
  /// NUMBERS*, this one answers *may I assert ABSENCE*. They are different
  /// questions and `partial` is where they visibly part — a partial read still
  /// shows the numbers it has, and still cannot call the gaps empty.
  ///
  /// Exhaustive for the same reason [showsTotals] is (C-163): a new state must
  /// not inherit "yes" by default.
  bool get canClaimEmpty => switch (fidelity) {
        // Read cleanly, nothing in it. The only honest empty.
        HistoryFidelity.ok => true,
        // Some records could not be read. If the readable ones came to zero,
        // the unreadable ones are exactly what we cannot speak for.
        HistoryFidelity.partial => false,
        HistoryFidelity.unavailable => false,
        // Nothing is written by design, so nothing being here is a FACT about
        // the build rather than a guess about the user — and the note above
        // already says which.
        HistoryFidelity.notRecorded => true,
      };

  /// The sentence for this state, or null when there is nothing to say.
  String? get note => noteFor();

  String? noteFor({ProgressMessageFormatter? format}) => switch (fidelity) {
        HistoryFidelity.ok => null,
        HistoryFidelity.unavailable => _progressMessage(
            ProgressStrings.historyUnavailable, const {}, format),
        HistoryFidelity.notRecorded => _progressMessage(
            ProgressStrings.historyNotRecorded, const {}, format),
        // "SOME of it" and "NONE of it" are separate sentences on purpose.
        // Collapsing them would let "your totals are a floor" appear above a
        // screen whose floor is zero — technically true, and useless.
        HistoryFidelity.partial => readableRecords == 0
            ? ProgressStrings.historyNoneReadable(unreadableRecords,
                format: format)
            : ProgressStrings.historyPartial(unreadableRecords, format: format),
      };
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
    required this.integrity,
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

  /// Totals, or NULL when the history could not be read at all.
  ///
  /// Nullable rather than zero-filled, and that is the whole design: a
  /// `RecordedSummary` of zeros would let a surface render "0 sessions, 0 min"
  /// from OUR failure to open a file, which is the "you did nothing" lie in
  /// its most confident form. With no object there is no number to render —
  /// the same move as kural-7 in `DanceJudge` and as this class having no
  /// merged-rows field: the wrong output is never FORMED, not merely hidden.
  final RecordedSummary? totals;

  /// How much of the stored history this reading saw. Never null: "we read
  /// everything" is itself a claim and has to be stated, not assumed.
  final HistoryIntegrity integrity;

  /// Time already worked does NOT become retroactive credit when a gate opens.
  ///
  /// Stated on the surface because the storage design already guarantees it and
  /// the guarantee is invisible otherwise: `lessonClass` is stamped at write
  /// time, so resolving BPM tomorrow cannot reach back and re-grade sessions
  /// danced without a beat grid. A product that quietly back-filled scores
  /// would be inventing evidence about performances it never observed.
  ///
  /// WHY THIS TAKES THE FIDELITY (C-191)
  /// -----------------------------------
  /// The single-sentence version said "practice time ALREADY RECORDED stays a
  /// record of practice" — true wherever a store exists, and a quiet lie in
  /// the state this build actually ships. Nothing is written at all, so a
  /// reader was told their practice was being kept, in a paragraph whose real
  /// subject was something else entirely.
  ///
  /// It is the same defect as `historyNotRecorded` fixed at the TOP of this
  /// screen, surviving one section lower because the earlier sweep asked
  /// "which sentence describes the store" and this sentence describes a
  /// POLICY — and only presupposes the store in passing. A presupposition is
  /// the cheapest place for a false claim to hide: nobody re-reads the clause
  /// that is not the point of the sentence.
  static String retroactiveCreditNote(HistoryFidelity fidelity,
          {ProgressMessageFormatter? format}) =>
      _progressMessage(
          switch (fidelity) {
            HistoryFidelity.notRecorded =>
              'When a check opens up later, it applies from that point on — never '
                  'backwards over dancing we were not measuring at the time. '
                  'This history source saves no camera sessions, so it has no '
                  'past sessions waiting to be re-scored. Written-course records '
                  'are separate.',
            HistoryFidelity.ok ||
            HistoryFidelity.partial ||
            HistoryFidelity.unavailable =>
              'When a check opens up later, it applies from that point on. '
                  'Practice time already recorded stays a record of practice — it '
                  'is not converted into a score for something we were not '
                  'measuring at the time.',
          },
          const {},
          format);

  factory ProgressSummary.build({
    required List<SessionRecord> history,
    required CourseCatalog catalog,
    HistoryIntegrity? integrity,
    RecordedSummary? totals,
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
        workedSeconds:
            rows.fold(0, (int a, SessionRecord r) => a + r.workedSeconds),
        cyclesCompleted:
            rows.fold(0, (int a, SessionRecord r) => a + r.unitsCompleted),
        plannedCycles:
            rows.fold(0, (int a, SessionRecord r) => a + r.plannedUnits),
        targetedSessions:
            rows.where((SessionRecord r) => r.plannedUnits > 0).length,
        completedSessions: rows
            .where((SessionRecord r) => r.plannedUnits > 0 && r.isComplete)
            .length,
        unmeasuredCycles:
            rows.fold(0, (int a, SessionRecord r) => a + r.unmeasuredUnits),
      ));
    }
    recorded.sort((a, b) => a.displayName.compareTo(b.displayName));

    // The record format has no verdict field. This explains that fact without
    // promising that a camera route is currently available or describing the
    // separate written-course self reports as measured dance skill.
    return ProgressSummary(
      recorded: recorded,
      evaluated: const <EvaluatedRow>[],
      evaluatedUnavailableReason: ProgressStrings.evaluatedUnavailableReason,
      blockedGates: catalog.blockedGates,
      totals: totals,
      integrity: integrity ??
          HistoryIntegrity.opened(unreadable: 0, readable: history.length),
    );
  }

  static Future<ProgressSummary> from({
    required SessionStore store,
    required CourseCatalog catalog,
  }) async {
    // The store's own answer about what it could not read (core 0.10.0,
    // REQUIRED member). Reading it is the whole point of the adoption: the
    // core can only expose the number, it cannot make a surface look at it —
    // a field written and never read is the failure class this repo already
    // named once (R12).
    try {
      final List<SessionRecord> history =
          List<SessionRecord>.unmodifiable(await store.recent());
      final int unreadable = await store.unreadableRecords();
      return ProgressSummary.build(
        history: history,
        catalog: catalog,
        totals: RecordedSummary.fromRecords(history),
        integrity: HistoryIntegrity.opened(
          unreadable: unreadable,
          readable: history.length,
        ),
      );
    } on Exception {
      // The store did not open. NOT the same as an empty history, and the
      // difference is the entire reason this branch exists: an empty summary
      // renders "no practice recorded yet", which is a claim about the user.
      return ProgressSummary.build(
        history: const <SessionRecord>[],
        catalog: catalog,
        integrity: HistoryIntegrity.unavailable,
      );
    }
  }

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
  static const String historyScope =
      'The session history below covers camera practice only. Written-course '
      'practice and self reports are kept separately in each course; they are '
      'not included in these session counts.';

  static const String recordedSection = 'Camera-session records';
  static const String recordedSubtitle =
      'Saved session measurements, not dance-skill grades.';

  static const String evaluatedSection = 'Evaluated';
  static const String evaluatedSubtitle =
      'Judgements about how you did. Graded lessons only.';
  static const String evaluatedUnavailableReason =
      'No camera-session grades are shown here. A verdict is not kept in '
      'these session records, so they never turn into a score. Written-course '
      'practice and self reports are separate learning records, not measured '
      'dance skill. An absent grade is not a zero.';

  static const String blockedSection = 'What we cannot check';
  static const String blockedSubtitle =
      'Named, with the reason. We would rather tell you than leave it out.';

  /// The store opened but some records could not be read back.
  ///
  /// The word that does the work is "at least". Without it the totals below
  /// make a claim they cannot support — JabLab's measured case said
  /// "10 sessions" over a file where 40 of 50 lines were corrupt, and every
  /// number on that screen was a confident understatement.
  static String historyPartial(int unreadable,
          {ProgressMessageFormatter? format}) =>
      _progressMessage(
          unreadable == 1
              ? 'One saved session could not be read back. Everything below counts '
                  'what we could read, so treat it as "at least this much" rather '
                  'than a full total.'
              : '{count} saved sessions could not be read back. Everything below '
                  'counts what we could read, so treat it as "at least this much" '
                  'rather than a full total.',
          unreadable == 1 ? const <String, Object>{} : {'count': unreadable},
          format);

  /// The store opened and NOTHING in it could be read.
  ///
  /// A separate sentence from [historyPartial] on purpose: telling someone
  /// their totals are "a floor" when that floor is zero is technically true
  /// and useless. This says the actual thing — the practice happened, we
  /// just cannot read it back.
  static String historyNoneReadable(int unreadable,
          {ProgressMessageFormatter? format}) =>
      _progressMessage(
          unreadable == 1
              ? 'We found one saved session but could not read it. That is not the '
                  'same as you not having practised — we simply cannot tell you '
                  'what is in it.'
              : 'We found {count} saved sessions but could not read any of '
                  'them. That is not the same as you not having practised — we '
                  'simply cannot tell you what is in them.',
          unreadable == 1 ? const <String, Object>{} : {'count': unreadable},
          format);

  /// The store never opened. NO numbers accompany this string.
  ///
  /// Showing a zero here would say "you did nothing", which is a claim about
  /// the user made from our own failure (J-066).
  /// Says the mechanism is ABSENT, and says the thing the old sentence took
  /// away by accident: nothing has been lost.
  static const String historyNotRecorded =
      'This session-history source does not save camera practice. There is '
      'nothing in this source to show or lose. Written-course learning '
      'records are kept separately.';

  static const String historyUnavailable =
      'We could not open your camera-session history. Rather than show you a zero '
      'that would be wrong, we are not showing numbers until we can read it.';

  static const String emptyHistory =
      'No camera sessions are saved in this history. Written-course practice '
      'may still be recorded in the courses.';

  /// What the Recorded section says when the list is empty **and we cannot say
  /// why** — see `HistoryIntegrity.canClaimEmpty`.
  ///
  /// Says the DIFFERENCE out loud rather than going silent. A blank section
  /// under a "could not open" note would leave the learner to guess which of
  /// the two it meant, and the guess a blank invites is "nothing" — the very
  /// reading this string exists to prevent.
  static const String unknownHistory =
      'We cannot show these camera-session records because the history could '
      'not be read. That is not the same as an empty history; its contents '
      'cannot be confirmed. Written-course records are separate.';

  /// The band column for a demo-only lesson: a mark that there IS no judgement,
  /// which is different from a judgement of zero.
  static const String noBand = '—';

  static String duration(int seconds, {ProgressMessageFormatter? format}) {
    final int m = seconds ~/ 60;
    if (m < 60) {
      return _progressMessage(
          '{minutes} min practised', {'minutes': m}, format);
    }
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0
        ? _progressMessage('{hours}h practised', {'hours': h}, format)
        : _progressMessage('{hours}h {minutes}m practised',
            {'hours': h, 'minutes': rem}, format);
  }

  /// Cycles read, against a target ONLY when one exists.
  ///
  /// **A ratio is a claim about a plan, and Choreia's lessons declare none**
  /// (see `noDeclaredTarget`). Rendering "6 of 0 cycles" is a broken sentence;
  /// rendering "6 of 6" — which is what storing the attempt as the target
  /// would produce — is worse, because it reads as a target the learner hit.
  /// So the ratio appears when there is something to compare against, and a
  /// bare fact when there is not.
  ///
  /// The rule is `planned <= 0`, not `== 0`: a negative target is a bug
  /// upstream, and the safe rendering of a bug is the sentence that claims
  /// least.
  static String cycles(int completed, int planned,
          {ProgressMessageFormatter? format}) =>
      planned <= 0
          ? _progressMessage(
              completed == 1 ? '{count} cycle read' : '{count} cycles read',
              {'count': completed},
              format)
          : _progressMessage('{completed} of {planned} cycles',
              {'completed': completed, 'planned': planned}, format);

  /// How many of these sessions were finished.
  ///
  /// [anyTarget] is FALSE when no session in the row declared a target — and
  /// then "finished" is not a fact this app holds. `SessionRecord.isComplete`
  /// is `attempted >= planned`, so with no target it is true for EVERY record;
  /// printing "1 of 1 sessions finished" would be reporting the arithmetic of
  /// an absent plan as an achievement. The count of sessions is still a fact,
  /// so it is the one that is shown.
  static String sessionsCompleted(int completed, int total,
          {required bool anyTarget, ProgressMessageFormatter? format}) =>
      anyTarget
          ? _progressMessage('{completed} of {total} sessions finished',
              {'completed': completed, 'total': total}, format)
          : _progressMessage(
              total == 1 ? '{count} session' : '{count} sessions',
              {'count': total},
              format);

  static String demoOnlyMark(String? reason,
          {ProgressMessageFormatter? format}) =>
      reason == null
          ? _progressMessage('Taught, not graded', const {}, format)
          : _progressMessage(
              'Taught, not graded — {reason}', {'reason': reason}, format);

  /// Cycles the learner did that could not be judged.
  ///
  /// Shown rather than quietly dropped: without this line the screen would say
  /// "8 of 8 cycles" for a session where one went unmeasured, which is the
  /// silence the core's `unmeasuredUnits` field exists to prevent. Phrased so
  /// the fault is the product's, not the dancer's.
  static String unmeasured(int cycles, {ProgressMessageFormatter? format}) =>
      _progressMessage(
          cycles == 1
              ? '{count} cycle we could not check (framing or lighting)'
              : '{count} cycles we could not check (framing or lighting)',
          {'count': cycles},
          format);
}
