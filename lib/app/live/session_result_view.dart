import 'package:flutter/material.dart';
import 'package:motion_core/motion_core.dart';

import '../theme.dart';
import '../ui_language.dart';
import 'live_lesson_copy.dart';
import 'live_state.dart';

/// What happened to the record when the learner ended the session.
///
/// Sealed for the same reason [LiveState] is: the result screen must handle
/// every case, and the case it would forget is the one where the write failed
/// — a screen that prints the session's numbers while nothing reached the disk
/// is the *talkative absence* class this repo already measured once
/// (`publication_inventory_test`): the mechanism is missing AND a surface
/// describes it anyway.
sealed class RecordOutcome {
  const RecordOutcome();
}

/// Stored. [record] is the line that was appended, not a copy of the intent.
final class RecordWritten extends RecordOutcome {
  const RecordWritten(this.record);

  final SessionRecord record;
}

/// Nothing was written because the camera delivered no assessable pose. The
/// learner may have moved, but the app has no measurement to record.
///
/// A DIFFERENT case from a measured session of zero cycles. Writing a
/// 0-cycle, 0-second row would put an unsupported measurement in history.
final class RecordNothingToStore extends RecordOutcome {
  const RecordNothingToStore();
}

/// The session happened and the store refused it.
///
/// Carries [detail] so the failure is reportable. Named on screen rather than
/// swallowed: the learner just danced, and silently losing it while the screen
/// congratulates them is worse than saying the storage failed.
final class RecordFailed extends RecordOutcome {
  const RecordFailed(this.detail);

  final String detail;
}

/// The end of one live lesson: what was measured, what was stored, and what
/// was NOT checked.
///
/// **This screen is what makes the app's first full flow finishable.** Until
/// it existed the live path had no terminal at all — the only way out of a
/// lesson was the back arrow, which discarded everything, and the progress tab
/// said in as many words that this app "does not save" anything. The three
/// sections below are the three claims the flow now makes, in the order a
/// learner cares about them: what you did · whether we kept it · what we did
/// not look at.
class SessionResultView extends StatelessWidget {
  const SessionResultView({
    super.key,
    required this.lessonName,
    required this.outcome,
    required this.gated,
    required this.notMeasuredNote,
    this.lessonId,
    required this.sawUnjudgeableFrames,
    this.onDone,
  });

  final String lessonName;
  final RecordOutcome outcome;

  /// Checks this lesson could not make. Repeated here rather than assumed
  /// remembered from the live screen: a summary that lists only findings
  /// implies the rest was checked and passed.
  final List<GatedCheck> gated;
  final String notMeasuredNote;
  final String? lessonId;

  /// Whether any frame arrived that could not be judged. NOT a count — see
  /// `SessionTally.unmeasuredUnits` for why a number here would be invented.
  final bool sawUnjudgeableFrames;

  final VoidCallback? onDone;

  static const Key bodyKey = Key('result.body');
  static const Key storedKey = Key('result.stored');
  static const Key notStoredKey = Key('result.notStored');
  static const Key failedKey = Key('result.failed');
  static const Key gatedKey = Key('result.gated');
  static const Key doneKey = Key('result.done');
  static const Key partialKey = Key('result.partial');

  @override
  Widget build(BuildContext context) {
    final bool tr = UiLanguage.isTurkish(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(tr ? 'Seans' : ResultStrings.title)),
      body: ChoreiaBackdrop(
        child: SafeArea(
          child: ListView(
            key: bodyKey,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: <Widget>[
              Text(lessonName,
                  style: ChoreiaType.of(context).display(size: 24)),
              const SizedBox(height: 16),
              _outcomeCard(context, tr),
              const SizedBox(height: 16),
              _gatedSection(context, tr),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  LiveLessonCopy.identityLimit(lessonId, notMeasuredNote,
                      turkish: tr),
                  textAlign: TextAlign.center,
                  style: ChoreiaType.of(context).label(
                      size: 10.5, color: ChoreiaPalette.of(context).text(0.4)),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: doneKey,
                onPressed: onDone ?? () => Navigator.of(context).pop(),
                child: Text(tr ? 'Derslere dön' : ResultStrings.done),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outcomeCard(BuildContext context, bool tr) => switch (outcome) {
        RecordWritten(:final SessionRecord record) =>
          _storedCard(context, record, tr),
        RecordNothingToStore() => _AttentionPanel(
            key: notStoredKey,
            icon: Icons.videocam_off_outlined,
            tone: ChoreiaPalette.of(context).amber,
            body: tr
                ? 'Bu seans için kayıt oluşmadı: kameradan değerlendirilebilir hareket okunmadı. Bu sıfır tekrarlı bir seans değil; ölçüm olmadığı için geçmişinize eklenmedi.'
                : ResultStrings.nothingToStore,
          ),
        RecordFailed(:final String detail) => _AttentionPanel(
            key: failedKey,
            icon: Icons.error_outline,
            tone: ChoreiaPalette.of(context).roseDeep,
            body: tr
                ? 'Çalıştınız ama seansı kaydedemedik. Sorun bizim kayıt işlemimizde; önceki çalışmalarınız etkilenmedi.'
                : ResultStrings.storeFailed,
            detail: detail,
          ),
      };

  Widget _storedCard(BuildContext context, SessionRecord record, bool tr) =>
      GlassPanel(
        key: storedKey,
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
                tr
                    ? 'Çalışma geçmişinize kaydedildi'
                    : ResultStrings.storedTitle,
                style: ChoreiaType.of(context).body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: ChoreiaPalette.of(context).bright)),
            const SizedBox(height: 12),
            // FACTS ONLY, and no ratio: this lesson declares no cycle target,
            // so "6 of 6" would report a target that was never set. Same rule
            // as `ProgressStrings.cycles`, applied at the moment the number is
            // first shown rather than only where it is summarised later.
            Text(
                tr
                    ? '${record.unitsCompleted} tam tekrar okundu'
                    : ResultStrings.cycles(record.unitsCompleted),
                style: ChoreiaType.of(context).label(
                    size: 12.5,
                    color: ChoreiaPalette.of(context).text(0.72),
                    letterSpacingEm: 0)),
            const SizedBox(height: 4),
            Text(
                tr
                    ? _workedTr(record.workedSeconds)
                    : ResultStrings.worked(record.workedSeconds),
                style: ChoreiaType.of(context).label(
                    size: 12.5,
                    color: ChoreiaPalette.of(context).text(0.72),
                    letterSpacingEm: 0)),
            const SizedBox(height: 12),
            Text(
                tr
                    ? 'Bu seans bu telefona kaydedildi ve İlerleme bölümünde görünür. Hiçbir şey yüklenmedi ve video saklanmadı; yalnızca bu sayılar kaydedildi.'
                    : ResultStrings.storedNote,
                style: ChoreiaType.of(context).body(
                    size: 12, color: ChoreiaPalette.of(context).text(0.6))),
            // The one thing the counts above cannot say. Shown only when it
            // happened, and worded as a limit of ours rather than a shortfall
            // of theirs.
            if (sawUnjudgeableFrames) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                  tr
                      ? 'Çalışmanızın bir kısmını okuyamadık; kadrajdan çıkmış veya ışık yetersiz kalmış olabilir. Bu tekrarlar yukarıdaki sayıya dahil değil ve kaç tane olduklarını söyleyemiyoruz.'
                      : ResultStrings.partial,
                  key: partialKey,
                  style: ChoreiaType.of(context).body(
                      size: 12, color: ChoreiaPalette.of(context).amberDeep)),
            ],
          ],
        ),
      );

  /// The same always-on section the live screen carries, for the same reason:
  /// a check the app cannot make is exactly the thing a learner would
  /// otherwise assume passed.
  Widget _gatedSection(BuildContext context, bool tr) => GlassPanel(
        key: gatedKey,
        tint: ChoreiaPalette.of(context).amber,
        borderColor: ChoreiaPalette.of(context).amber.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(tr ? 'Kontrol etmediklerimiz' : ResultStrings.gatedTitle,
                style: ChoreiaType.of(context).label(
                    size: 9.5,
                    color: ChoreiaPalette.of(context).amberDeep,
                    letterSpacingEm: 0.12)),
            for (final GatedCheck g in gated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    LiveLessonCopy.gatedReason(lessonId, g.code, g.why,
                        turkish: tr),
                    style: ChoreiaType.of(context).body(
                        size: 12, color: ChoreiaPalette.of(context).text(0.7))),
              ),
          ],
        ),
      );

  String _workedTr(int seconds) {
    final int minutes = seconds ~/ 60;
    return minutes < 1
        ? 'Bir dakikadan az kamera süresi'
        : '$minutes dakika kamera süresi';
  }
}

/// Every user-facing string of the result surface, in one place — same seam as
/// `LiveStrings` and `ProgressStrings`.
abstract final class ResultStrings {
  ResultStrings._();

  static const String title = 'Session';

  static const String storedTitle = 'Kept in your practice record';

  static String cycles(int n) =>
      n == 1 ? '1 full repetition read' : '$n full repetitions read';

  static String worked(int seconds) {
    final int m = seconds ~/ 60;
    if (m < 1) return 'Under a minute of camera time';
    return m == 1 ? '1 minute of camera time' : '$m minutes of camera time';
  }

  /// Says WHERE it went, because a learner has no other way to find out that
  /// the Progress tab is now a place with something in it.
  static const String storedNote =
      'This session is saved on this phone and shows up under Progress. '
      'Nothing was uploaded and no video was kept — only these counts.';

  /// The limit that the counts above cannot express.
  ///
  /// Deliberately not a number: a repetition only becomes countable after the
  /// confidence gate accepts its frames, so work lost to light or framing is
  /// never counted at all. Saying "3 cycles unmeasured" would be inventing the
  /// very quantity we failed to measure.
  static const String partial =
      'Some of what you danced went unread — you moved out of frame, or the '
      'light was too low for us to follow. Those repetitions are not in the '
      'count above, and we cannot say how many there were.';

  static const String nothingToStore =
      'Nothing was recorded for this session: no assessable movement was read '
      'from the camera. This is not a session of zero repetitions; without a '
      'measurement, it was not added to your history.';

  static const String storeFailed =
      'You practised, and we could not save it. The session happened; what '
      'failed is the writing, on our side. Your earlier practice is not '
      'affected.';

  static const String gatedTitle = 'What we were NOT checking';

  static const String done = 'Back to lessons';
}

/// Local twin of the live screen's attention card — one ring, one sentence,
/// optional detail. Duplicated rather than shared because the live one is
/// private to its file and lifting it into a shared widget is a design move,
/// not a measurement one.
class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({
    super.key,
    required this.icon,
    required this.tone,
    required this.body,
    this.detail,
  });

  final IconData icon;
  final Color tone;
  final String body;
  final String? detail;

  @override
  Widget build(BuildContext context) => GlassPanel(
        radius: 22,
        tint: tone,
        borderColor: tone.withValues(alpha: 0.28),
        child: Column(
          children: <Widget>[
            StatusRing(icon: icon, tone: tone, breathing: false),
            const SizedBox(height: 16),
            Text(body,
                textAlign: TextAlign.center,
                style: ChoreiaType.of(context).body(
                    size: 14, color: ChoreiaPalette.of(context).text(0.85))),
            if (detail != null && detail!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(detail!,
                  textAlign: TextAlign.center,
                  style: ChoreiaType.of(context).label(
                      size: 11, color: ChoreiaPalette.of(context).text(0.4))),
            ],
          ],
        ),
      );
}
