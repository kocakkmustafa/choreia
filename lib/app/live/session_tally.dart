import 'package:motion_core/motion_core.dart';

import '../recorded_summary.dart';
import 'live_state.dart';

/// What one live lesson actually produced, accumulated from the states the
/// session emitted.
///
/// Pure on purpose — no Flutter, no clock of its own, no storage. The page
/// feeds it states and a timestamp; this class decides what may be CLAIMED
/// about them, and `SessionRecord` is the only thing it hands back. Keeping
/// the decision here rather than in `setState` is what lets the rules below be
/// tested without a camera, a device or a widget tree.
final class SessionTally {
  SessionTally({required this.lessonId, required this.lessonClass});

  final String lessonId;

  /// The class AT WRITE TIME (`scored` / `demoOnly`) — the core stores it
  /// rather than deriving it later, so a lesson promoted tomorrow does not
  /// retroactively turn today's practice into a graded session.
  final String lessonClass;

  int _cycles = 0;
  int _framesUnseen = 0;
  Duration? _firstFrameAt;
  Duration? _lastFrameAt;

  /// Full repetitions the engine READ and judged.
  int get cyclesRead => _cycles;

  /// Whether the camera ever delivered a frame at all. A session that never
  /// got past permission or a model fault produced NOTHING, and a record of
  /// nothing is not a record of practice.
  bool get sawCamera => _firstFrameAt != null;

  /// Whether any frame arrived that could not be judged (framing, light,
  /// tracking). Not a COUNT of lost cycles — see [unmeasuredUnits].
  bool get sawUnjudgeableFrames => _framesUnseen > 0;

  /// Feed one state, stamped with elapsed time since the page opened.
  ///
  /// [elapsed] is passed IN rather than read from a clock here: a tally that
  /// calls `DateTime.now()` cannot be replayed, and replay is the only
  /// verification path this project accepts for camera work.
  void observe(LiveState state, Duration elapsed) {
    switch (state) {
      // States that mean the camera is delivering frames. The clock runs
      // across ALL of them, including `LiveNoPerson`: we cannot tell standing
      // still from dancing in poor light, and stopping the clock on frames we
      // failed to judge would report LESS practice than happened — the "you
      // did less" lie this family already paid for once (M-F-228).
      case LiveNoPerson():
        _framesUnseen++;
        _stamp(elapsed);
      case LiveWatching():
        _stamp(elapsed);
      case LiveJudged():
      case LiveMeasured():
        _cycles++;
        _stamp(elapsed);
      // Nothing arrived from the camera in these: no clock, no cycles.
      case LiveIdle():
      case LivePermissionDenied():
      case LiveCameraUnavailable():
        break;
    }
  }

  void _stamp(Duration at) {
    _firstFrameAt ??= at;
    _lastFrameAt = at;
  }

  /// Seconds the camera was delivering frames. Zero until it did.
  int get workedSeconds => _firstFrameAt == null
      ? 0
      : (_lastFrameAt! - _firstFrameAt!).inSeconds;

  /// Units the learner attempted that could not be judged.
  ///
  /// **0 AS A DECLARATION, not as a default** — the same distinction the core
  /// draws for `unreadableRecords()`. This pipeline CANNOT produce a non-zero
  /// value even in principle: a cycle only comes into existence after the
  /// confidence gate accepts its frames, so work lost to bad light never
  /// becomes a countable unit. The fact is not dropped — [sawUnjudgeableFrames]
  /// carries it, and the result surface states the limit in words.
  ///
  /// Writing a number derived from rejected FRAMES would be an invented unit:
  /// frames are not cycles, and the ratio between them is the very thing the
  /// period estimator could not establish.
  int get unmeasuredUnits => 0;

  /// Build the record for a session the learner ENDED THEMSELVES.
  ///
  /// [endedAt] is the wall-clock stamp stored on the record; [workedSeconds]
  /// comes from the elapsed stamps above, so a session is not lengthened by
  /// the time between the last frame and the tap on Finish.
  SessionRecord toRecord({required DateTime endedAt}) => SessionRecord(
        lessonId: lessonId,
        lessonClass: lessonClass,
        completedAt: endedAt,
        workedSeconds: workedSeconds,
        unitsCompleted: _cycles,
        plannedUnits: noDeclaredTarget,
        unitLabel: choreiaUnitLabel,
        unmeasuredUnits: unmeasuredUnits,
      );
}

/// What Choreia writes into [SessionRecord.plannedUnits] because **no lesson
/// in this app declares a target**.
///
/// Measured, not assumed: `hh_bounce.json` declares `beats: 1`,
/// `cycleUnit.dipsPerCycle: 1` and `style.json` declares `minutes: 8`. Not one
/// of them says how many repetitions a lesson IS, and deriving a count from
/// minutes needs a tempo — the exact quantity `beatsStatus: PENDING` says this
/// app does not have.
///
/// Every other value would put a false sentence on a screen that already
/// exists, and both directions were checked before this one was chosen:
///
///   · `plannedUnits = attemptedUnits` renders "6 of 6 cycles" — a target hit,
///     for a target nobody set. The strongest possible over-claim, dressed as
///     arithmetic.
///   · any invented constant renders "6 of 8 cycles" and blames the learner
///     for falling short of a number this app made up.
///
/// So the record says the target is absent, and the SURFACE is what must not
/// turn that absence into a claim — `ProgressStrings.cycles` renders a bare
/// fact when this is 0, and never "of 0".
///
/// ⚠️ This is a floor, not a decision to keep forever. The day content
/// declares a per-lesson cycle target, this constant is the one place that
/// changes.
const int noDeclaredTarget = 0;
