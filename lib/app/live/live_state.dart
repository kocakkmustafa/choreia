import 'package:choreia_engine/choreia_engine.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

/// A check this lesson CANNOT make today, named for the learner.
///
/// Carried beside every live reading rather than dropped. A screen that shows
/// three findings and stays silent about the fourth check implies the fourth
/// passed — the silence J-066 forbids, and the same reasoning as the progress
/// surface's blocked-gates section.
final class GatedCheck {
  const GatedCheck({required this.code, required this.why});

  final String code;

  /// User language. Never the raw `blockedBy` string: `beatsStatus:PENDING`
  /// tells a dancer nothing (kalem-4's rule, C-117).
  final String why;
}

/// What the live camera path can be at any moment.
///
/// Sealed so a surface must handle every case: an unhandled state would
/// otherwise render as a blank screen, and a blank screen makes a claim.
sealed class LiveState {
  const LiveState();
}

/// Nothing started yet.
final class LiveIdle extends LiveState {
  const LiveIdle();
}

/// Capture was released after leaving the foreground or changing its owner.
final class LiveInterrupted extends LiveState {
  const LiveInterrupted({this.accountChanged = false});

  /// An account change permanently retires this route's capture lease.
  final bool accountChanged;
}

enum ObservationBlocker { unsupported, incompatible, clockDiscontinuity }

/// No assessment is available; this is neither a zero nor a completed cycle.
final class LiveObservationUnavailable extends LiveState {
  const LiveObservationUnavailable(this.reason);
  final ObservationBlocker reason;
}

/// The user has not granted camera permission (or revoked it).
///
/// Its OWN state rather than a flavour of "unavailable": this is the one
/// failure the user can fix, and it routes to a different screen.
final class LivePermissionDenied extends LiveState {
  const LivePermissionDenied();
}

/// The camera could not be opened, for a reason that is not permission.
///
/// Carries the typed [failure] so the surface can say WHICH refusal it was
/// — "something went wrong" is the message that makes a bug unreportable.
final class LiveCameraUnavailable extends LiveState {
  const LiveCameraUnavailable(this.failure, this.detail);

  final CameraFailure failure;
  final String? detail;
}

/// The camera is running but no judgeable person is in frame.
///
/// NOT an error and NOT scored as zero: "we cannot see you" and "you did it
/// badly" are different sentences, and collapsing them is the confident-lie
/// class this project keeps measuring.
final class LiveNoPerson extends LiveState {
  const LiveNoPerson(this.issues);

  final Set<QualityIssue> issues;
}

/// Tracking a person, but no full cycle has been observed yet.
final class LiveWatching extends LiveState {
  const LiveWatching({required this.cyclesSeen});

  final int cyclesSeen;
}

/// A demoOnly lesson's live reading: MEASUREMENTS, and no judgement.
///
/// This type has NO band and NO findings field, so a demo-only lesson cannot
/// leak a score through the live path even by mistake — the same move as
/// `ProgressSummary` having no merged-rows field and `DanceJudge` never
/// FORMING a side-dependent verdict under kural-7. The guard is the type, not
/// a runtime check somebody has to remember.
final class LiveMeasured extends LiveState {
  const LiveMeasured({
    required this.measurements,
    required this.gated,
    required this.notMeasuredNote,
  });

  final Map<String, double> measurements;
  final List<GatedCheck> gated;

  /// The MEASURED limit of what this reading can claim, in user language.
  /// Carries the step-identity honesty forward to the live surface: nothing
  /// here checks that you are dancing THIS step.
  final String notMeasuredNote;
}

/// A scored lesson's live reading.
final class LiveJudged extends LiveState {
  const LiveJudged({
    required this.result,
    required this.gated,
    required this.notMeasuredNote,
  });

  final JudgeResult result;
  final List<GatedCheck> gated;
  final String notMeasuredNote;
}
