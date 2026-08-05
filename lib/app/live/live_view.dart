import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import 'live_state.dart';

/// Every user-facing string of the live surface, in one place (same seam as
/// `ProgressStrings`).
abstract final class LiveStrings {
  static const String title = 'Live practice';

  static const String idle = 'Getting the camera ready.';

  static const String permanentlyDenied =
      'Camera access is turned off for Choreia. We cannot ask again from '
      'here — it has to be switched back on in your phone settings.';
  static const String deniedOnce =
      'We need the camera to watch your steps. Nothing is recorded and '
      'nothing leaves your phone — we only read where your joints are.';
  static const String openSettings = 'Open settings';
  static const String tryAgain = 'Try again';

  static const String noPerson =
      'We cannot see you well enough to check anything right now.';
  static String noPersonWhy(QualityIssue issue) => switch (issue) {
        QualityIssue.lowTrackingConfidence =>
          'Try more light, or a plainer background.',
        QualityIssue.outOfFrame =>
          'Some of you is outside the frame — try stepping back.',
        QualityIssue.torsoUnreliable =>
          'We cannot make out your upper body, so there is nothing to '
              'measure from.',
      };

  static const String watching = 'Watching. Keep going — we read a full '
      'repetition at a time.';

  /// "Nothing yet" is NOT zero. A bare 0 next to "repetitions" reads as a
  /// score of nothing; the absence of a count is a different fact.
  static String cycles(int? n) =>
      n == null ? 'No full repetition read yet' : '$n read so far';

  static const String gatedTitle = 'What we are NOT checking';
  static const String measuredTitle = 'What we measured';
  static const String findingsTitle = 'What we noticed';
  static const String nothingWrong =
      'Nothing we check came out wrong this time.';

  static String cameraProblem(CameraFailure f) => switch (f) {
        CameraFailure.modelLoadFailed =>
          'The movement model would not load, so we cannot watch you. This '
              'one is on us, not your phone.',
        CameraFailure.noSuchCamera =>
          'We could not find a front camera on this device.',
        CameraFailure.alreadyRunning =>
          'The camera is already in use by another part of the app.',
        CameraFailure.notRunning => 'The camera session is not running.',
        CameraFailure.permissionDenied =>
          // Never reached: permission has its own state. Handled so the
          // switch stays exhaustive rather than defaulting.
          'Camera access is off.',
      };
}

/// The live lesson screen.
///
/// [LiveState] is `sealed`, so the compiler REQUIRES every case below. That is
/// the point: an unhandled state renders as a blank screen, and a blank screen
/// makes a claim about the user's dancing that nobody wrote.
///
/// THREE PATTERNS CARRIED IN FROM THE FAMILY (M-F-268):
///   · NO DEAD END — a camera failure never leaves the screen unopenable; it
///     flows INTO the session as a typed state with something to do next.
///   · PERMISSION HAS TWO FLAVOURS — a permanent denial offers settings, not
///     a "try again" button that cannot work.
///   · "NEVER STARTED" ≠ ZERO — the repetition counter is `int?`, and a null
///     renders as words, never as a bare 0.
class LiveView extends StatelessWidget {
  const LiveView({
    super.key,
    required this.state,
    required this.gated,
    required this.notMeasuredNote,
    this.cyclesRead,
    this.permissionPermanentlyDenied = false,
    this.onRetry,
    this.onOpenSettings,
  });

  final LiveState state;

  /// Shown in EVERY state, including failures: a check we cannot make is not
  /// something the learner should discover only when things go well.
  final List<GatedCheck> gated;
  final String notMeasuredNote;

  /// Null until a full repetition has been read. Not zero (M-F-268).
  final int? cyclesRead;

  final bool permissionPermanentlyDenied;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;

  static const Key bodyKey = Key('live.body');
  static const Key gatedKey = Key('live.gated');
  static const Key notMeasuredKey = Key('live.notMeasured');
  static const Key actionKey = Key('live.action');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(LiveStrings.title)),
      body: ListView(
        key: bodyKey,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ..._forState(),
          const SizedBox(height: 24),
          _gatedSection(),
          const SizedBox(height: 16),
          Text(notMeasuredNote, key: notMeasuredKey),
        ],
      ),
    );
  }

  /// The compiler enforces exhaustiveness here — adding an eighth state
  /// breaks the build rather than silently rendering nothing.
  List<Widget> _forState() => switch (state) {
        LiveIdle() => <Widget>[const Text(LiveStrings.idle)],
        LivePermissionDenied() => <Widget>[
            Text(permissionPermanentlyDenied
                ? LiveStrings.permanentlyDenied
                : LiveStrings.deniedOnce),
            const SizedBox(height: 12),
            // A "try again" that cannot possibly work is worse than no button.
            if (permissionPermanentlyDenied)
              FilledButton(
                key: actionKey,
                onPressed: onOpenSettings,
                child: const Text(LiveStrings.openSettings),
              )
            else
              FilledButton(
                key: actionKey,
                onPressed: onRetry,
                child: const Text(LiveStrings.tryAgain),
              ),
          ],
        LiveCameraUnavailable(:final CameraFailure failure, :final String? detail) =>
          <Widget>[
            Text(LiveStrings.cameraProblem(failure)),
            if (detail != null && detail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(detail, style: const TextStyle(fontSize: 12)),
              ),
            const SizedBox(height: 12),
            // NO DEAD END: there is always something to do next.
            FilledButton(
              key: actionKey,
              onPressed: onRetry,
              child: const Text(LiveStrings.tryAgain),
            ),
          ],
        LiveNoPerson(:final Set<QualityIssue> issues) => <Widget>[
            const Text(LiveStrings.noPerson),
            for (final QualityIssue i in issues)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(LiveStrings.noPersonWhy(i)),
              ),
            const SizedBox(height: 8),
            Text(LiveStrings.cycles(cyclesRead)),
          ],
        LiveWatching(:final int cyclesSeen) => <Widget>[
            const Text(LiveStrings.watching),
            const SizedBox(height: 8),
            Text(LiveStrings.cycles(cyclesSeen == 0 ? null : cyclesSeen)),
          ],
        // DEMO-ONLY: measurements only. This branch has no band to render
        // because `LiveMeasured` has no band FIELD — the guarantee is the
        // type, not this code remembering.
        LiveMeasured(:final Map<String, double> measurements) => <Widget>[
            const Text(LiveStrings.measuredTitle,
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final MapEntry<String, double> m in measurements.entries)
              Text('${m.key}: ${m.value.toStringAsFixed(1)}°'),
            const SizedBox(height: 8),
            Text(LiveStrings.cycles(cyclesRead)),
          ],
        LiveJudged(:final JudgeResult result) => <Widget>[
            const Text(LiveStrings.findingsTitle,
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (result.findings.isEmpty)
              const Text(LiveStrings.nothingWrong)
            else
              for (final ErrorFinding f in result.findings)
                Text('${f.code}${f.why == null ? '' : ' — ${f.why}'}'),
            const SizedBox(height: 8),
            Text(LiveStrings.cycles(cyclesRead)),
          ],
      };

  /// Gated checks, ALWAYS on screen.
  ///
  /// Not folded away behind a tap: a check the app cannot make is exactly the
  /// thing a learner would otherwise assume passed (kalem-4, C-117).
  Widget _gatedSection() => Column(
        key: gatedKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(LiveStrings.gatedTitle,
              style: TextStyle(fontWeight: FontWeight.bold)),
          for (final GatedCheck g in gated)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(g.why),
            ),
        ],
      );
}
