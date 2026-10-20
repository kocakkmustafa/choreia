import 'package:flutter/material.dart';

import 'course_catalog.dart';
import 'localization/progress_messages.dart';
import 'progress_summary.dart';
import 'theme.dart';
import 'ui_language.dart';

/// The progress surface.
///
/// What this widget is for
/// -----------------------
/// The honesty rules of §3.9 are not styling choices — they are constraints on
/// what may appear next to what: Recorded and Evaluated may never merge, a
/// demo-only lesson gets a completion mark and never a band, blocked checks are
/// named on screen, and practice time is never converted into retroactive
/// credit. Those constraints exist in TESTED CODE, and the design pass below
/// INHERITS them rather than rediscovering them. JabLab's precedent:
/// structure-level widget tests caught a real honesty defect (three lessons
/// could not pass their own gate).
///
/// Every section carries a [Key] so a test can assert WHICH SECTION a given
/// string appears in. A test that only asserts "the text exists somewhere" would
/// pass even if the two sections were merged — the exact failure the type split
/// in [ProgressSummary] exists to prevent.
///
/// DESIGN PASS (2026-08-06, `docs/design/`): the mockup's "Progress" screen
/// shows Recorded/Assessed as two TABS — only one mounted at a time. That
/// would still satisfy every existing assertion below (an unmounted section's
/// text is simply absent, which is what "findsNothing" already checks for),
/// but it is not the SAME claim the tests were written to make: several of
/// them assert that one section's text is present WHILE another section's
/// same text is absent, in a single pump, which only means what it was
/// written to mean if both sections are actually in the tree together. Kept
/// as three always-mounted, strongly separated sections instead — visual
/// language borrowed from the design (large serif section titles, a hairline
/// rule, generous spacing), tab AFFORDANCE dropped. Named here rather than
/// silently decided, per the giydirme brief's own rule on structural
/// conflicts.
class ProgressView extends StatelessWidget {
  const ProgressView(
      {required this.summary, this.catalog, this.courseEntry, super.key});

  static const Key recordedSectionKey = Key('progress.recorded');
  static const Key evaluatedSectionKey = Key('progress.evaluated');
  static const Key blockedSectionKey = Key('progress.blocked');
  static const Key retroactiveNoteKey = Key('progress.retroactiveNote');
  static const Key historyScopeKey = Key('progress.historyScope');

  final ProgressSummary summary;

  /// Optional entry to the independently recorded teaching course.
  final Widget? courseEntry;

  /// Only used to name WHY a lesson is ungraded on its own row. Optional: the
  /// row must still render honestly without it.
  final CourseCatalog? catalog;

  /// The history-integrity sentence, when there is one to say.
  static const Key integrityNoteKey = Key('progress.integrityNote');

  /// The one line the Recorded section shows when it has no rows — and
  /// WHICH line it is is the claim (C-280).
  static const Key emptyReasonKey = Key('progress.emptyReason');

  String _text(BuildContext context, String english) => UiLanguage.text(context,
      en: english, tr: progressMessages['tr']?[english] ?? english);

  String _format(
          BuildContext context, String template, Map<String, Object> values) =>
      UiLanguage.format(context,
          en: template,
          tr: progressMessages['tr']?[template] ?? template,
          values: values);

  @override
  Widget build(BuildContext context) {
    String message(String template, Map<String, Object> values) =>
        _format(context, template, values);
    final String? integrityNote = summary.integrity.noteFor(format: message);
    return ChoreiaBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: <Widget>[
            Text(_text(context, 'Your practice'),
                style: ChoreiaType.of(context).label(
                    size: 10, color: ChoreiaPalette.of(context).text(0.42))),
            const SizedBox(height: 8),
            Text(_text(context, 'Progress'),
                style: ChoreiaType.of(context).display(size: 33)),
            const SizedBox(height: 18),

            if (courseEntry != null) ...[
              courseEntry!,
              const SizedBox(height: 24),
            ],

            Text(_text(context, ProgressStrings.historyScope),
                key: historyScopeKey,
                style: ChoreiaType.of(context).body(
                    size: 12.5, color: ChoreiaPalette.of(context).text(0.65))),
            const SizedBox(height: 16),

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
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassPanel(
                  tint: ChoreiaPalette.of(context).amber,
                  borderColor: ChoreiaPalette.of(context).amber.withValues(alpha: 0.24),
                  child: Text(integrityNote,
                      style: ChoreiaType.of(context).body(
                          size: 12.5, color: ChoreiaPalette.of(context).text(0.8))),
                ),
              ),

            _section(context: context,
              sectionKey: recordedSectionKey,
              title: _text(context, ProgressStrings.recordedSection),
              subtitle: _text(context, ProgressStrings.recordedSubtitle),
              accent: ChoreiaPalette.of(context).rose,
              children: summary.recorded.isEmpty
                  ? <Widget>[
                      // WHY it is empty decides what may be SAID about it.
                      // An unreadable history and an empty one produce the
                      // same empty list and mean opposite things (C-280).
                      Text(
                          _text(
                              context,
                              summary.integrity.canClaimEmpty
                                  ? ProgressStrings.emptyHistory
                                  : ProgressStrings.unknownHistory),
                          key: emptyReasonKey,
                          style: ChoreiaType.of(context).body(
                              size: 13, color: ChoreiaPalette.of(context).text(0.6)))
                    ]
                  : summary.recorded
                      .map((row) => _recordedRow(context, row))
                      .toList(growable: false),
            ),
            const SizedBox(height: 28),

            _section(context: context,
              sectionKey: evaluatedSectionKey,
              title: _text(context, ProgressStrings.evaluatedSection),
              subtitle: _text(context, ProgressStrings.evaluatedSubtitle),
              accent: ChoreiaPalette.of(context).rose,
              children: summary.evaluated.isEmpty
                  // The reason goes INSIDE this section: a blank Evaluated section
                  // reads as a statement about the user ("you earned nothing"),
                  // when the true statement is about the product.
                  ? <Widget>[
                      Text(
                          _text(context,
                              summary.evaluatedUnavailableReason ?? ''),
                          style: ChoreiaType.of(context).body(
                              size: 13, color: ChoreiaPalette.of(context).text(0.6)))
                    ]
                  : summary.evaluated
                      .map((row) => _evaluatedRow(context, row))
                      .toList(growable: false),
            ),
            const SizedBox(height: 28),

            _section(context: context,
              sectionKey: blockedSectionKey,
              title: _text(context, ProgressStrings.blockedSection),
              subtitle: _text(context, ProgressStrings.blockedSubtitle),
              accent: ChoreiaPalette.of(context).amber,
              children: <Widget>[
                for (final BlockedGate g in summary.blockedGates)
                  _blockedRow(context, g),
                // Sits in the blocked section on purpose: it is the answer to the
                // question this section provokes ("so what happens to my work when
                // these open?").
                Padding(
                  key: retroactiveNoteKey,
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      ProgressSummary.retroactiveCreditNote(
                          summary.integrity.fidelity,
                          format: message),
                      style: ChoreiaType.of(context).body(
                          size: 11.5, color: ChoreiaPalette.of(context).text(0.48))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordedRow(BuildContext context, RecordedRow row) {
    String message(String template, Map<String, Object> values) =>
        _format(context, template, values);
    final LessonInfo? info = catalog?.lessonById(row.lessonId);
    final Color tone =
        row.isDemoOnly ? ChoreiaPalette.of(context).amber : ChoreiaPalette.of(context).rose;
    return Padding(
      key: Key('progress.recorded.${row.lessonId}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        radius: 16,
        tint: tone,
        borderColor: ChoreiaPalette.of(context).hairline(0.11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: tone),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_text(context, row.displayName),
                      style: ChoreiaType.of(context).body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: ChoreiaPalette.of(context).bright)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Units live in the strings, so no caller can emit a bare number.
            Text(ProgressStrings.duration(row.workedSeconds, format: message),
                style: ChoreiaType.of(context).label(
                    size: 10.5, color: ChoreiaPalette.of(context).text(0.5))),
            Text(
                ProgressStrings.cycles(
                    row.cyclesCompleted,
                    // A mixed history must not compare all read cycles with
                    // a plan that only some sessions declared.
                    row.targetedSessions == row.sessions
                        ? row.plannedCycles
                        : 0,
                    format: message),
                style: ChoreiaType.of(context).label(
                    size: 10.5, color: ChoreiaPalette.of(context).text(0.5))),
            Text(
                ProgressStrings.sessionsCompleted(0, row.sessions,
                    anyTarget: false, format: message),
                style: ChoreiaType.of(context).label(
                    size: 10.5, color: ChoreiaPalette.of(context).text(0.5))),
            if (row.targetedSessions > 0)
              Text(
                  ProgressStrings.sessionsCompleted(
                      row.completedSessions, row.targetedSessions,
                      anyTarget: true, format: message),
                  style: ChoreiaType.of(context).label(
                      size: 10.5, color: ChoreiaPalette.of(context).text(0.5))),
            // Unmeasured work is named on the row it happened in — an aggregate
            // elsewhere would tell the user something went unchecked without
            // saying where.
            if (row.unmeasuredCycles > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    ProgressStrings.unmeasured(row.unmeasuredCycles,
                        format: message),
                    style: ChoreiaType.of(context).body(
                        size: 11.5, color: ChoreiaPalette.of(context).amberDeep)),
              ),
            // A demo-only lesson EARNS the completion mark and shows `—` where a
            // band would be. Both halves matter: the mark because completion is a
            // measurement, the dash because a blank would look like a missing value
            // rather than an absent judgement.
            if (row.isDemoOnly) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // The reason is content-authored prose (K10) with no length
                  // guarantee — real content already runs longer than the
                  // synthetic test fixture. Expanded so it WRAPS instead of
                  // pushing the fixed-width dash off the right edge.
                  Expanded(
                    child: Text(
                        ProgressStrings.demoOnlyMark(
                            info?.reason == null
                                ? null
                                : _text(context, info!.reason!),
                            format: message),
                        style: ChoreiaType.of(context).body(
                            size: 11.5, color: ChoreiaPalette.of(context).text(0.62))),
                  ),
                  const SizedBox(width: 10),
                  Text(ProgressStrings.noBand,
                      style: ChoreiaType.of(context).display(
                          size: 15, color: ChoreiaPalette.of(context).text(0.5))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _evaluatedRow(BuildContext context, EvaluatedRow row) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassPanel(
          radius: 16,
          tint: ChoreiaPalette.of(context).rose,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(_text(context, row.displayName),
                    style: ChoreiaType.of(context).body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: ChoreiaPalette.of(context).bright)),
              ),
              const SizedBox(width: 10),
              Text(_text(context, row.band),
                  style: ChoreiaType.of(context).display(
                      size: 17, color: ChoreiaPalette.of(context).roseBright)),
            ],
          ),
        ),
      );

  /// What to CALL a blocked gate on screen.
  ///
  /// 🔴 **FOUND BY WALKING (C-279).** This section is the app's proudest
  /// surface — *"What we cannot check"*, named with the reason — and it was
  /// addressing the learner in internal identifiers: `hh_l1_bounce`,
  /// `ss_weight_shift`, `hh_bounce_wall`. Every one of those lessons already
  /// has a name written FOR THE USER in content (*"The bounce (not graded)"*),
  /// and the screen was throwing it away.
  ///
  /// **The same class as `C-268 ⑥`, one surface over.** There the RECORD
  /// carried a step id where a lesson id belonged and rendered under its raw
  /// key; the fix was applied to the history path and this path kept the
  /// defect. ⇒ ***BİR SINIFI BİR YÜZEYDE KAPATMAK, KOMŞU YÜZEYDE KAPATMIŞ
  /// OLMAZ*** — and the two are far enough apart that no test noticed.
  ///
  /// **Scope is deliberate: LESSONS ONLY.** A lesson's display name is not
  /// invented here — content already wrote it for a reader. `GateScope.style`
  /// (`bpmResolved`) and `GateScope.errorCode` (`STEP_LATE`,
  /// `NO_WEIGHT_TRANSFER`) have no user-facing name anywhere, and making one up
  /// would be authoring copy rather than using it. They stay as they are, and
  /// the question of what a learner should call them is raised rather than
  /// answered.
  String _gateLabel(BlockedGate g) => switch (g.scope) {
        GateScope.lesson => catalog?.lessonById(g.id)?.displayName ?? g.id,
        GateScope.style || GateScope.errorCode => g.id,
      };

  Widget _blockedRow(BuildContext context, BlockedGate g) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassPanel(
          radius: 14,
          tint: ChoreiaPalette.of(context).amber,
          borderColor: ChoreiaPalette.of(context).amber.withValues(alpha: 0.2),
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_text(context, _gateLabel(g)),
                  style: ChoreiaType.of(context).label(
                      size: 9.5,
                      color: ChoreiaPalette.of(context).amberDeep,
                      letterSpacingEm: 0.1)),
              const SizedBox(height: 6),
              Text(_text(context, g.why),
                  style: ChoreiaType.of(context).body(
                      size: 12.5, color: ChoreiaPalette.of(context).text(0.78))),
              if (g.unblockedBy != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      _format(context, 'Opens when: {condition}',
                          {'condition': _text(context, g.unblockedBy!)}),
                      style: ChoreiaType.of(context).body(
                          size: 11.5, color: ChoreiaPalette.of(context).text(0.5))),
                ),
            ],
          ),
        ),
      );

  Widget _section({required BuildContext context,
    required Key sectionKey,
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> children,
  }) {
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(width: 3, height: 16, color: accent),
            const SizedBox(width: 8),
            // Expanded even though today's three titles are short fixed
            // strings: at large system text-scaling (accessibility) the
            // same Row-without-Flexible overflow this section's demo-only
            // row just failed on would reappear here first.
            Expanded(child: Text(title, style: ChoreiaType.of(context).display(size: 20))),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Text(subtitle,
              style:
                  ChoreiaType.of(context).body(size: 12, color: ChoreiaPalette.of(context).text(0.55))),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
