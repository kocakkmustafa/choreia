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
  SessionTally({
    required this.lessonId,
    required this.lessonClass,
    this.cycleTarget,
  });

  final String lessonId;

  /// The lesson's declared cycle target, or null when it declares none.
  ///
  /// **Read from CONTENT, per lesson — it used to be an app-wide constant**
  /// whose own doc asserted a fact about the catalogue ("no lesson in this app
  /// declares a target"). That is a content claim living in code, and content
  /// claims in code go stale the day content moves without anything going red.
  /// Now the absent case is `null` because the lesson said nothing, not because
  /// the app believes something about every lesson (C-273, H-4 ③).
  final int? cycleTarget;

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
      case LiveInterrupted():
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
  int get workedSeconds =>
      _firstFrameAt == null ? 0 : (_lastFrameAt! - _firstFrameAt!).inSeconds;

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
        plannedUnits: cycleTarget ?? absentTargetOnTheWire,
        unitLabel: choreiaUnitLabel,
        unmeasuredUnits: unmeasuredUnits,
      );
}

/// How an ABSENT target crosses the wire — an ENCODING, not a product opinion.
///
/// The family's [SessionRecord.plannedUnits] is a non-nullable `int` (promoted
/// schema, five apps, pinned), so "no target" needs a value. Zero is that
/// value, and this is the only place in Choreia that knows it: above this line
/// absence is `int?`, and a reader who never sees this constant cannot mistake
/// it for a target of nothing.
///
/// **What this is NOT any more:** until C-273 the same zero was a constant
/// called `noDeclaredTarget`, documented as "what Choreia writes because no
/// lesson in this app declares a target" — a claim about the CATALOGUE, made
/// in code, that nothing would have falsified on the day a lesson declared one.
/// The claim now lives where it can be checked: `cycleTarget` in
/// `content/SCHEMA.md`, gated by `validate_content.py`.
///
/// Both wrong alternatives were checked before zero was chosen, and they are
/// worth keeping written down because they are what a plausible refactor would
/// reach for:
///
///   · `plannedUnits = attemptedUnits` renders "6 of 6 cycles" — a target hit,
///     for a target nobody set. The strongest possible over-claim, dressed as
///     arithmetic.
///   · any invented constant renders "6 of 8 cycles" and blames the learner
///     for falling short of a number this app made up. (This is now
///     structurally hard rather than merely discouraged: content may only
///     declare a target WITH a measured `cycleTargetBasis`.)
///
/// Surfaces must never render this as a denominator: `ProgressStrings.cycles`
/// and `RecordedSummary.anyTarget` both read `<= 0` / `> 0` as absence, so
/// "of 0" cannot reach a screen.
const int absentTargetOnTheWire = 0;
