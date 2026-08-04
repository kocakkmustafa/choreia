import 'package:flutter/widgets.dart';

import 'course_catalog.dart';
import 'progress_summary.dart';

/// The progress surface's **STRUCTURE**, deliberately without visual design.
///
/// What this widget is for
/// -----------------------
/// The honesty rules of §3.9 are not styling choices — they are constraints on
/// what may appear next to what: Recorded and Evaluated may never merge, a
/// demo-only lesson gets a completion mark and never a band, blocked checks are
/// named on screen, and practice time is never converted into retroactive
/// credit. Those constraints have to exist in TESTED CODE before a visual pass,
/// so the design session INHERITS them instead of having to rediscover them.
/// JabLab's precedent: structure-level widget tests caught a real honesty
/// defect (three lessons could not pass their own gate).
///
/// What this widget is NOT
/// ----------------------
/// It is not the finished screen. Colour, type, spacing, iconography and
/// layout belong to the claude.ai/design pass (founder-manual). **Design changes
/// the styling and INHERITS the structure — it does not invent it.** There is
/// also no visual verification behind this file: this session has no device,
/// emulator or camera, so what is proven here is the STRUCTURE, by test, and
/// nothing about how it looks.
///
/// Every section carries a [Key] so a test can assert WHICH SECTION a given
/// string appears in. A test that only asserts "the text exists somewhere" would
/// pass even if the two sections were merged — the exact failure the type split
/// in [ProgressSummary] exists to prevent.
class ProgressView extends StatelessWidget {
  const ProgressView({required this.summary, this.catalog, super.key});

  static const Key recordedSectionKey = Key('progress.recorded');
  static const Key evaluatedSectionKey = Key('progress.evaluated');
  static const Key blockedSectionKey = Key('progress.blocked');
  static const Key retroactiveNoteKey = Key('progress.retroactiveNote');

  final ProgressSummary summary;

  /// Only used to name WHY a lesson is ungraded on its own row. Optional: the
  /// row must still render honestly without it.
  final CourseCatalog? catalog;

  /// The history-integrity sentence, when there is one to say.
  static const Key integrityNoteKey = Key('progress.integrityNote');

  @override
  Widget build(BuildContext context) {
    final String? integrityNote = summary.integrity.note;
    return ListView(
      children: <Widget>[
        // INTEGRITY FIRST, above the numbers it qualifies.
        //
        // Placed here rather than in a footnote because a caveat that arrives
        // after the totals has already let them be read as complete. When the
        // history could not be read at all there are no totals below this line
        // to qualify — `ProgressSummary.totals` is null in that state, so the
        // sentence stands alone rather than captioning a screen of zeros.
        if (integrityNote != null)
          Padding(
            key: integrityNoteKey,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(integrityNote),
          ),
        _section(
          key: recordedSectionKey,
          title: ProgressStrings.recordedSection,
          subtitle: ProgressStrings.recordedSubtitle,
          children: summary.recorded.isEmpty
              ? <Widget>[const Text(ProgressStrings.emptyHistory)]
              : summary.recorded.map(_recordedRow).toList(growable: false),
        ),
        _section(
          key: evaluatedSectionKey,
          title: ProgressStrings.evaluatedSection,
          subtitle: ProgressStrings.evaluatedSubtitle,
          children: summary.evaluated.isEmpty
              // The reason goes INSIDE this section: a blank Evaluated section
              // reads as a statement about the user ("you earned nothing"),
              // when the true statement is about the product.
              ? <Widget>[Text(summary.evaluatedUnavailableReason ?? '')]
              : summary.evaluated
                  .map((EvaluatedRow r) =>
                      Text('${r.displayName}: ${r.band}'))
                  .toList(growable: false),
        ),
        _section(
          key: blockedSectionKey,
          title: ProgressStrings.blockedSection,
          subtitle: ProgressStrings.blockedSubtitle,
          children: <Widget>[
            for (final BlockedGate g in summary.blockedGates)
              Text('${g.id}: ${g.why}'
                  '${g.unblockedBy == null ? '' : ' Opens when: ${g.unblockedBy}'}'),
            // Sits in the blocked section on purpose: it is the answer to the
            // question this section provokes ("so what happens to my work when
            // these open?").
            const Padding(
              padding: EdgeInsets.zero,
              child: Text(
                ProgressSummary.retroactiveCreditNote,
                key: retroactiveNoteKey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _recordedRow(RecordedRow row) {
    final LessonInfo? info = catalog?.lessonById(row.lessonId);
    return Column(
      key: Key('progress.recorded.${row.lessonId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(row.displayName),
        // Units live in the strings, so no caller can emit a bare number.
        Text(ProgressStrings.duration(row.workedSeconds)),
        Text(ProgressStrings.cycles(row.cyclesCompleted, row.plannedCycles)),
        Text(ProgressStrings.sessionsCompleted(
            row.completedSessions, row.sessions)),
        // Unmeasured work is named on the row it happened in — an aggregate
        // elsewhere would tell the user something went unchecked without
        // saying where.
        if (row.unmeasuredCycles > 0)
          Text(ProgressStrings.unmeasured(row.unmeasuredCycles)),
        // A demo-only lesson EARNS the completion mark and shows `—` where a
        // band would be. Both halves matter: the mark because completion is a
        // measurement, the dash because a blank would look like a missing value
        // rather than an absent judgement.
        if (row.isDemoOnly) ...<Widget>[
          Text(ProgressStrings.demoOnlyMark(info?.reason)),
          const Text(ProgressStrings.noBand),
        ],
      ],
    );
  }

  Widget _section({
    required Key key,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[Text(title), Text(subtitle), ...children],
    );
  }
}
