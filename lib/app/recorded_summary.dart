import 'package:motion_core/motion_core.dart';

/// Choreia's names for the classes it writes into [SessionRecord.lessonClass].
///
/// The core keeps that field an OPEN vocabulary on purpose (M-F-193): apps own
/// their words, and only the shared value `'scored'` reads as scored anywhere.
/// These constants exist so the strings are written in one place rather than
/// sprinkled as literals — a typo'd `'demoonly'` would not throw, it would
/// quietly become a class nobody counts.
abstract final class ChoreiaLessonClass {
  /// Graded. The one value the core itself recognises ([SessionRecord.isScoredClass]).
  static const String scored = 'scored';

  /// Taught, deliberately never graded, with a stated reason (K10).
  static const String demoOnly = 'demoOnly';

  static const Set<String> all = <String>{scored, demoOnly};
}

/// The unit a Choreia session counts in.
///
/// Dance has no time-box; a lesson is built on a repeating CYCLE, which is
/// already this repo's unit of measurement (`cyclesInSegment`,
/// `evidenceThickness.cyclesPerTake`). Recorded PER RECORD by the core, so a
/// future step measured in seconds can sit beside this one on one screen.
const String choreiaUnitLabel = 'cycle';

/// FACTS about recorded sessions. No judgement whatsoever.
///
/// Stayed in Choreia when the store was promoted to the core, and deliberately:
/// the SPLIT BY CLASS is this product's honesty rule, not the family's. "You
/// completed 6 lessons" would hide that five of them are never graded, so the
/// progress surface shows both counts in separate sections and never merges
/// them. Another app may have no such split.
///
/// Not one field here says "good" or "bad" — everything is measurable without a
/// camera, which is why the K8 calibration lock does not close it: K8 withholds
/// the SCORE, not the fact (M-F-04).
final class RecordedSummary {
  const RecordedSummary({
    required this.sessions,
    required this.targetedSessions,
    required this.completed,
    required this.workedSeconds,
    required this.scoredSessions,
    required this.demoOnlySessions,
    required this.unmeasuredUnits,
  });

  final int sessions;

  /// Records that DECLARED a cycle target (`plannedUnits > 0`).
  ///
  /// **The denominator, and it exists because the numerator was about to go
  /// silently wrong.** `SessionRecord.isComplete` is `attempted >= planned`, so
  /// a record with no target is complete by arithmetic — every Choreia record
  /// ever written, since no lesson could declare a target until `cycleTarget`
  /// landed in the content schema. That made [completed] a harmless
  /// always-everything, and nothing rendered it.
  ///
  /// The day ONE lesson declares a target, a bare `where(isComplete).length`
  /// stops being harmless and becomes MIXED: target-less records still count as
  /// finished, target-having ones only when the learner reached the number, and
  /// the sum answers no question anyone asked. `RecordedRow` already carried
  /// this guard (`ProgressStrings.sessionsCompleted(anyTarget:)`); the totals
  /// did not. Added on the turn that added the capability — a latent defect and
  /// the feature that activates it belong in one commit.
  final int targetedSessions;

  /// Sessions that reached their declared target — counted ONLY over
  /// [targetedSessions]. Zero, and meaningless, when [anyTarget] is false.
  final int completed;
  final int workedSeconds;

  /// How much of the history could carry a judgement at all.
  final int scoredSessions;

  /// Taught-but-never-graded sessions. These EARN a completion mark and never
  /// a band — withholding the mark too would make the lesson second class,
  /// precisely what K10 exists to prevent.
  final int demoOnlySessions;

  /// Cycles the learner attempted that could not be judged (framing, light,
  /// tracking). Surfaced rather than dropped: silence would let the screen
  /// claim 3 cycles when the user danced 4.
  final int unmeasuredUnits;

  /// Whether "finished" is a fact this history holds at all.
  ///
  /// False means no record declared a target, and then [completed] and
  /// [stoppedEarly] are not small numbers — they are not numbers ABOUT
  /// anything, and a surface must show [sessions] instead.
  bool get anyTarget => targetedSessions > 0;

  /// Sessions that declared a target and did not reach it.
  ///
  /// Measured against [targetedSessions], never [sessions]: subtracting a
  /// target-scoped count from an all-records count would report every
  /// target-less session as "stopped early" — an accusation manufactured out
  /// of an absent plan.
  int get stoppedEarly => targetedSessions - completed;

  /// Human-readable duration. Seconds are NOT shown: at practice-session scale
  /// second precision carries no information, only an impression of precision.
  String get workedLabel {
    final int m = workedSeconds ~/ 60;
    if (m < 60) return '$m min';
    final int h = m ~/ 60;
    final int rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  static Future<RecordedSummary> from(SessionStore store) async =>
      RecordedSummary.fromRecords(await store.recent());

  /// Derives totals from the same reading that supplies the visible rows.
  /// Opening a store again here can mix a later append into the totals while
  /// the screen still renders rows from the earlier reading.
  factory RecordedSummary.fromRecords(Iterable<SessionRecord> records) {
    int worked = 0;
    int targeted = 0;
    int done = 0;
    int scored = 0;
    int demo = 0;
    int unmeasured = 0;
    int sessions = 0;
    for (final SessionRecord r in records) {
      sessions++;
      worked += r.workedSeconds;
      // `> 0`, not `!= 0`: a negative target is an upstream bug, and the safe
      // reading of a bug is the one that claims least — an unreadable plan is
      // an absent plan, not a plan the learner beat. Same rule as
      // `ProgressStrings.cycles`, so the totals and the row cannot disagree
      // about whether a target exists.
      if (r.plannedUnits > 0) {
        targeted++;
        if (r.isComplete) done++;
      }
      unmeasured += r.unmeasuredUnits;
      // Counted through the CORE's least-privilege read, not a local string
      // compare: an unknown or misspelled class must never land in `scored`,
      // and there is exactly one place that decision should live.
      if (r.isScoredClass) {
        scored++;
      } else {
        demo++;
      }
    }
    return RecordedSummary(
      sessions: sessions,
      targetedSessions: targeted,
      completed: done,
      workedSeconds: worked,
      scoredSessions: scored,
      demoOnlySessions: demo,
      unmeasuredUnits: unmeasured,
    );
  }
}
