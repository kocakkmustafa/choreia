import 'dart:async';
import 'dart:convert';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_core/motion_core.dart';
import 'package:motion_camera/motion_camera.dart'
    show CameraException, CameraFailure;
// Tam paket, `show` listesi DEĞİL — ölçüldü: `isPermanentlyDenied`/
// `isRestricted`/`status` bu pakette UZANTI (extension) üyeleri, ve bir
// `show` listesi uzantıları gizler. Ostinato da API'yi kullandığı dosyada
// tam import ediyor (`camera_session.dart`).
import 'package:permission_handler/permission_handler.dart';

import '../shell/choreia_page_route.dart';
import '../history/account_store_lifetime.dart';
import 'camera_pose_source.dart';
import 'live_environment.dart';
import 'live_session.dart';
import 'dance_runtime.dart';
import 'live_state.dart';
import 'live_view.dart';
import 'session_result_view.dart';
import 'session_tally.dart';

/// Runs one lesson's live path, renders whatever it honestly reports, and —
/// since 2026-08-13 — lets the learner END it, which is what turns this screen
/// from a place you fall into a place you come back FROM.
///
/// Lifted out of `main.dart` unchanged (2026-08-07) when the navigation shell
/// landed. Before that, this WAS the app: `main.dart` hardcoded one
/// `stepId`/`lessonClass` pair because there was nothing to reach it from. It
/// is now pushed from a lesson card, and the pair it runs comes from content
/// instead of from a literal in the entry point.
///
/// WHAT CHANGED, and why it is not a redesign
/// ------------------------------------------
/// The live path had **no terminal**. There was no control that ended a
/// lesson, so nothing was ever written, so `ProgressView` was hard-wired to
/// say this app "does not save" anything — and the whole first flow
/// (launch → style → lesson → result → record) was structurally impossible,
/// not merely unbuilt. What is added: a FINISH control, a record built from
/// what the session actually produced, and [env] — the three device-only
/// dependencies (content bundle · pose source · session store) gathered behind
/// one substitutable object. The first two are what made this screen
/// unopenable in any test, so the navigability gate had to list it as
/// unreachable WITH A REASON rather than walk it.
///
/// The behaviour of the judge, the session and the surface is untouched.
class LiveLessonPage extends StatefulWidget {
  const LiveLessonPage({
    super.key,
    required this.stepId,
    required this.lessonId,
    required this.lessonClass,
    this.cycleTarget,
    this.styleId,
    this.lessonName,
    this.env = const LiveEnvironment(),
  });

  /// The MOVEMENT this lesson teaches — names the reference and step document.
  final String stepId;

  /// The LESSON, which is what a session is a session OF.
  ///
  /// **Not the same string, and conflating them corrupts the history.**
  /// `SessionRecord.lessonId` is joined against `CourseCatalog.lessonById`, and
  /// that map is keyed by lesson (`hh_l1_bounce`), not by step (`hh_bounce`) —
  /// a record carrying the step id renders on the progress screen under its
  /// own raw identifier, because the lookup misses and the fallback is the key
  /// itself. It looks like a naming quirk and it is a lost row.
  ///
  /// Found by a route name: the lesson is pushed as `live/<lessonId>` and the
  /// result was being pushed as `result/<stepId>`, which is what made the two
  /// vocabularies visible in one line of output.
  final String lessonId;

  final String lessonClass;

  /// The lesson's declared cycle target, straight from `LessonInfo`.
  ///
  /// Passed rather than looked up here: this page already receives the lesson
  /// it is running, and a second lookup against the catalogue is a second place
  /// the answer could differ from the one the library screen showed.
  final int? cycleTarget;

  /// What the result screen calls this lesson. Falls back to the step id
  /// rather than to a blank: an unnamed heading is worse than a technical one.
  final String? lessonName;

  /// Which style's `steps/` directory holds this step's document.
  ///
  /// Optional so the historical two-style prefix rule still works, but passed
  /// by every caller in the shell: inferring a directory from an id prefix
  /// stops working the moment a third style ships, and a wrong guess here is a
  /// failed asset load rather than a visible mistake.
  final String? styleId;

  /// Every device-only dependency, in one substitutable object: content
  /// bundle, pose source, session store, permission probe, settings opener.
  /// Defaults to the real ones.
  ///
  /// **A SEAM, and the permission probe is here because the answer used to be
  /// GUESSED.** Until C-222 this page inferred "permanent" from a second
  /// refusal in a row — a heuristic wrong in both directions: a
  /// policy-restricted device is permanent on the FIRST refusal, and declining
  /// twice on purpose does not mean the switch was turned off for good.
  final LiveEnvironment env;

  @override
  State<LiveLessonPage> createState() => _LiveLessonPageState();
}

class _LiveLessonPageState extends State<LiveLessonPage>
    with WidgetsBindingObserver {
  LiveState _state = const LiveIdle();
  List<GatedCheck> _gated = const <GatedCheck>[];
  int? _cycles;

  /// Answered by the OS, not inferred from how many times we were refused
  /// (C-222). Still defaults to `false`, so an unanswerable probe offers
  /// "try again" rather than a settings trip the user may not need.
  bool _permanentlyDenied = false;

  late final SessionTally _tally = SessionTally(
    lessonId: widget.lessonId,
    lessonClass: widget.lessonClass,
    cycleTarget: widget.cycleTarget,
  );

  /// Real elapsed time, started when the page opens. Read only through
  /// [SessionTally.observe], which decides which states the clock applies to —
  /// the page measures, the tally rules.
  final Stopwatch _clock = Stopwatch()..start();

  late final PoseSource _source;
  AppStoreOwnerTicket? _resourceOwner;

  Future<void> _closeOwnedResource() {
    _revokeOwner();
    return _retireSource();
  }

  // Keep this lesson's journal owner fixed even if sign-in changes while the
  // camera is open. A new account must never inherit the guest attempt.
  late final String? _recordOwnerUserId;
  bool _ownerRevoked = false;
  bool get _ownerMatches =>
      widget.env.accountUserId?.value == _recordOwnerUserId;
  bool _captureAllowed(int epoch) =>
      mounted &&
      _foreground &&
      !_ownerRevoked &&
      !_cameraCloseFailed &&
      !_finishing &&
      _ownerMatches &&
      epoch == _lifecycleEpoch;

  AssetBundle get _bundle => widget.env.bundle ?? rootBundle;

  StreamSubscription<LiveState>? _run;
  Timer? _noPoseTimer;

  /// Guards the one irreversible action on this screen. A second tap while the
  /// write is in flight would append the same practice twice.
  bool _finishing = false;
  bool _foreground = true;
  bool _starting = false;
  bool _requestingPermission = false;
  bool _sourceOpen = false;
  bool _sourceLeaseActive = false;
  bool _cameraCloseFailed = false;
  Future<void>? _sourceRetirement;
  int _lifecycleEpoch = 0;
  Completer<void>? _resumeSignal;

  @override
  void initState() {
    super.initState();
    _recordOwnerUserId = widget.env.accountUserId?.value;
    _source = widget.env.source?.call() ?? DeviceCameraPoseSource();
    _resourceOwner =
        (widget.env.storeOwners ?? appStoreOwners).capture(_recordOwnerUserId);
    _resourceOwner!.registerResource(_closeOwnedResource);
    WidgetsBinding.instance.addObserver(this);
    widget.env.accountUserId?.addListener(_revokeOwner);
    widget.env.passwordRecovery?.addListener(_onRecoveryChanged);
    widget.env.ownerEpoch?.addListener(_revokeOwner);
    _onRecoveryChanged();
    _start();
  }

  @override
  void didUpdateWidget(covariant LiveLessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.env == widget.env) return;
    if (oldWidget.env.accountUserId != widget.env.accountUserId) {
      oldWidget.env.accountUserId?.removeListener(_revokeOwner);
      widget.env.accountUserId?.addListener(_revokeOwner);
    }
    if (oldWidget.env.passwordRecovery != widget.env.passwordRecovery) {
      oldWidget.env.passwordRecovery?.removeListener(_onRecoveryChanged);
      widget.env.passwordRecovery?.addListener(_onRecoveryChanged);
      _onRecoveryChanged();
    }
    if (oldWidget.env.ownerEpoch != widget.env.ownerEpoch) {
      oldWidget.env.ownerEpoch?.removeListener(_revokeOwner);
      widget.env.ownerEpoch?.addListener(_revokeOwner);
      _revokeOwner();
    }
    // This source and journal owner were acquired for the original route.
    // Replacing its dependencies cannot silently rebind a running attempt.
    if (oldWidget.env.accountUserId != widget.env.accountUserId ||
        oldWidget.env.bundle != widget.env.bundle ||
        oldWidget.env.source != widget.env.source ||
        oldWidget.env.storeOpener != widget.env.storeOpener ||
        oldWidget.env.storeOwners != widget.env.storeOwners ||
        oldWidget.env.historyDirectoryOverride !=
            widget.env.historyDirectoryOverride ||
        oldWidget.env.cameraPermissionRequest !=
            widget.env.cameraPermissionRequest ||
        oldWidget.env.permanentlyDeniedProbe !=
            widget.env.permanentlyDeniedProbe ||
        oldWidget.env.openSettings != widget.env.openSettings) {
      _revokeOwner();
    }
  }

  void _onRecoveryChanged() {
    if (widget.env.passwordRecovery?.value == true) _revokeOwner();
  }

  void _revokeOwner() {
    if (_ownerRevoked) return;
    _ownerRevoked = true;
    _lifecycleEpoch++;
    _clock.stop();
    _noPoseTimer?.cancel();
    _noPoseTimer = null;
    _resumeSignal?.complete();
    _resumeSignal = null;
    unawaited(_run?.cancel());
    _run = null;
    _retireSource();
    if (mounted) {
      setState(() => _state = const LiveInterrupted(accountChanged: true));
    }
  }

  Future<void> _retireSource() {
    _sourceOpen = false;
    if (!_sourceLeaseActive) return _sourceRetirement ?? Future<void>.value();
    _sourceLeaseActive = false;
    // stop also cancels acquisition; waiting for begin to settle can strand
    // an opening camera after the route has lost its owner or foreground.
    final retirement = Future<void>.sync(_source.stop);
    _sourceRetirement = retirement;
    // Observe errors for background/owner/dispose callers too. Finish awaits
    // this same per-attempt Future, and must not write before confirmed close.
    unawaited(
        retirement.then<void>((_) {}, onError: (Object error, StackTrace _) {
      _cameraCloseFailed = true;
      _lifecycleEpoch++;
      _clock.stop();
      _noPoseTimer?.cancel();
      _noPoseTimer = null;
      if (mounted && !_ownerRevoked) {
        final failure = error is CameraException
            ? error.failure
            : CameraFailure.closeUncertain;
        setState(() {
          _finishing = false;
          _state = LiveCameraUnavailable(failure, null);
        });
      }
    }));
    return retirement;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ownerRevoked) return;
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _resumeSignal?.complete();
      _resumeSignal = null;
      if (mounted) setState(() {});
      return;
    }
    if (!_foreground) return;
    _foreground = false;
    if (_requestingPermission && !_sourceOpen) return;
    _lifecycleEpoch++;
    _clock.stop();
    _noPoseTimer?.cancel();
    _noPoseTimer = null;
    unawaited(_run?.cancel());
    _run = null;
    _retireSource();
    if (mounted) setState(() => _state = const LiveInterrupted());
  }

  @override
  void dispose() {
    widget.env.accountUserId?.removeListener(_revokeOwner);
    widget.env.passwordRecovery?.removeListener(_onRecoveryChanged);
    widget.env.ownerEpoch?.removeListener(_revokeOwner);
    _lifecycleEpoch++;
    WidgetsBinding.instance.removeObserver(this);
    _resumeSignal?.complete();
    _resumeSignal = null;
    _noPoseTimer?.cancel();
    _run?.cancel();
    final retirement = _retireSource();
    unawaited(retirement.then<void>((_) {
      _resourceOwner?.unregisterResource(_closeOwnedResource);
    }, onError: (Object _, StackTrace __) {}));
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting || _sourceOpen || !_captureAllowed(_lifecycleEpoch)) return;
    _starting = true;
    final int epoch = _lifecycleEpoch;
    _clock.start();
    setState(() => _state = const LiveIdle());
    try {
      final binding = await DanceRuntimeManifest.loadBinding(
          bundle: _bundle,
          stepId: widget.stepId,
          stepPath: _stepPath(widget.stepId));
      if (!_captureAllowed(epoch)) return;
      if (!binding.diagnosticAngles) {
        setState(() => _state = LiveObservationUnavailable(
            binding.status == DanceCapabilityStatus.unsupported
                ? ObservationBlocker.unsupported
                : ObservationBlocker.incompatible));
        return;
      }
      final DanceReference reference = DanceReference.fromJson(jsonDecode(
              await _bundle
                  .loadString('content/references/${widget.stepId}.json'))
          as Map<String, dynamic>);
      final Map<String, dynamic> step =
          jsonDecode(await _bundle.loadString(_stepPath(widget.stepId)))
              as Map<String, dynamic>;

      final LiveSession session = LiveSession(
        provider: binding,
        reference: reference,
        stepConfig: step,
        lessonClass: widget.lessonClass,
        judge: DanceJudge(reference: reference),
      );
      if (!_captureAllowed(epoch)) return;
      setState(() => _gated = session.gatedChecks());

      // The native plugin never requests camera access. Only the real device
      // source needs this OS dialog; replay sources remain device-free.
      LiveState? refusal;
      if (widget.env.source == null ||
          widget.env.cameraPermissionRequest != null) {
        _requestingPermission = true;
        try {
          final bool granted =
              await (widget.env.cameraPermissionRequest?.call() ??
                  _requestCameraPermission());
          if (!granted) refusal = const LivePermissionDenied();
        } on Object {
          refusal = const LivePermissionDenied();
        } finally {
          if (mounted && !_ownerRevoked && !_foreground) {
            final Completer<void> resume = Completer<void>();
            _resumeSignal = resume;
            await resume.future;
          }
          _requestingPermission = false;
        }
        if (!_captureAllowed(epoch)) {
          _clock.stop();
          if (mounted && !_ownerRevoked) {
            setState(() => _state = const LiveInterrupted());
          }
          return;
        }
      }

      // NO DEAD END (M-F-268): a refusal becomes a STATE, not an exception that
      // leaves the screen empty with nothing to do.
      if (refusal == null) {
        _sourceLeaseActive = true;
        _sourceRetirement = null;
        refusal = await _source.begin();
      }
      if (!_captureAllowed(epoch)) {
        _retireSource();
        return;
      }
      if (refusal != null) {
        _retireSource();
        // ASK, do not infer. Ostinato's rule, adapted unchanged: `isRestricted`
        // counts as permanent too — a device under parental controls or an MDM
        // policy never shows the dialog at all, and the old second-refusal
        // heuristic could not see that case even in principle.
        bool permanent = false;
        if (refusal is LivePermissionDenied) {
          final Future<bool> Function() probe =
              widget.env.permanentlyDeniedProbe ?? askOsPermanentlyDenied;
          try {
            permanent = await probe();
          } on Object {
            // An unanswerable probe is not a permanent denial. Failing the
            // other way would strand a user on a settings screen they never
            // needed — the direction of this default is chosen, not accidental.
            permanent = false;
          }
        }
        if (!_captureAllowed(epoch)) return;
        final LiveState rejected = refusal;
        setState(() {
          if (rejected is LiveCameraUnavailable &&
              (rejected.failure == CameraFailure.closeUncertain ||
                  rejected.failure == CameraFailure.ownedProtocolUnavailable)) {
            _cameraCloseFailed = true;
          }
          _permanentlyDenied = permanent;
          _state = rejected;
        });
        _tally.observe(refusal, _clock.elapsed);
        return;
      }

      _sourceOpen = true;

      await _run?.cancel();
      if (!_captureAllowed(epoch)) return;
      _armNoPoseTimer(epoch);
      final Stream<PoseFrame> observedFrames = _source.frames().map(
        (PoseFrame frame) {
          _armNoPoseTimer(epoch);
          return frame;
        },
      );
      _run = session.run(observedFrames).listen((LiveState s) {
        // A frame delivered after backgrounding is not part of this practice.
        // Owner and route lifetime also bound which frames may reach tally.
        if (!_captureAllowed(epoch)) return;
        _tally.observe(s, _clock.elapsed);
        if (!mounted) return;
        setState(() {
          _state = s;
          if (s is LiveWatching && s.cyclesSeen > 0) _cycles = s.cyclesSeen;
          if (s is LiveJudged || s is LiveMeasured) _cycles = _tally.cyclesRead;
        });
      });
    } finally {
      _starting = false;
      if (mounted) setState(() {});
    }
  }

  Future<bool> _requestCameraPermission() async =>
      (await Permission.camera.request()).isGranted;

  void _armNoPoseTimer(int epoch) {
    if (!_captureAllowed(epoch)) return;
    _noPoseTimer?.cancel();
    _noPoseTimer = Timer(const Duration(seconds: 5), () {
      if (!_captureAllowed(epoch)) return;
      setState(() =>
          _state = const LiveNoPerson(<QualityIssue>{QualityIssue.outOfFrame}));
    });
  }

  String _stepPath(String id) {
    final String style = widget.styleId ??
        (id.startsWith('ss_') ? 'salsa_shines' : 'hip_hop_foundations');
    return 'content/styles/$style/steps/$id.json';
  }

  /// End the session, write it, and go to the result.
  ///
  /// The order matters and is not interchangeable: the camera is stopped
  /// first (so the next lesson can open one), the record is built from the
  /// tally as it stands, and only THEN does the screen change. A result
  /// surface drawn before the write would have to guess its own outcome.
  Future<void> _finish() async {
    if (_finishing || _ownerRevoked || _cameraCloseFailed || !_ownerMatches) {
      return;
    }
    setState(() => _finishing = true);
    _lifecycleEpoch++;

    // Retire capture synchronously. Subscription cancellation is not awaited;
    // the owned camera close acknowledgement is awaited before persistence.
    unawaited(_run?.cancel());
    _run = null;
    _noPoseTimer?.cancel();
    _noPoseTimer = null;
    final retirement = _retireSource();
    _clock.stop();

    try {
      await retirement;
    } on Object {
      // _retireSource observes and renders the typed terminal refusal. An
      // uncertain close cannot become a saved attempt or a result route.
      return;
    }
    if (!mounted || _ownerRevoked || _cameraCloseFailed || !_ownerMatches) {
      return;
    }

    final RecordOutcome outcome = await _writeRecord();
    if (!mounted || _ownerRevoked || !_ownerMatches) return;

    Navigator.of(context).pushReplacement(
      ChoreiaPageRoute<void>(
        settings: RouteSettings(name: 'result/${widget.lessonId}'),
        builder: (_) => SessionResultView(
          lessonId: widget.lessonId,
          lessonName: widget.lessonName ?? widget.lessonId,
          outcome: outcome,
          gated: _gated,
          notMeasuredNote: LiveSession.notMeasuredNote,
          sawUnjudgeableFrames: _tally.sawUnjudgeableFrames,
        ),
      ),
    );
  }

  /// "Never started" is not zero (M-F-268), one layer down: a session where
  /// the camera never delivered a frame produced no practice, and writing a
  /// 0-cycle row would put something in the learner's history that did not
  /// happen.
  Future<RecordOutcome> _writeRecord() async {
    if (!_tally.sawCamera || _ownerRevoked || !_ownerMatches) {
      return const RecordNothingToStore();
    }
    final SessionRecord record = _tally.toRecord(endedAt: DateTime.now());
    try {
      final store = await widget.env.openStoreFor(_recordOwnerUserId);
      if (!mounted || _ownerRevoked || !_ownerMatches) {
        return const RecordNothingToStore();
      }
      await store.append(record);
      return RecordWritten(record);
    } on Object catch (e) {
      // NOT swallowed. The first-run flag may fail quietly because losing it
      // costs the user one extra intro screen; losing a session they just
      // danced is a different size of loss, and the screen says so.
      return RecordFailed('$e');
    }
  }

  @override
  Widget build(BuildContext context) => LiveView(
        lessonId: widget.lessonId,
        state: _state,
        gated: _gated,
        notMeasuredNote: LiveSession.notMeasuredNote,
        cyclesRead: _cycles,
        permissionPermanentlyDenied: _permanentlyDenied,
        onRetry: _ownerRevoked || _cameraCloseFailed
            ? () => Navigator.of(context).maybePop()
            : _starting || !_foreground || _finishing
                ? null
                : _start,
        // C-140 KAPANDI (koordinatör hükmü (A), C-222). Buraya `null`
        // geçiliyordu ve ekranın tek kontrolü DEVRE DIŞI bir düğmeydi —
        // M-F-268'in yasakladığı ölü-sonun kendisi. Artık gerçek bir çağrı.
        onOpenSettings: widget.env.openSettings ?? openAppSettings,
        onFinish: _finishing || _cameraCloseFailed ? null : _finish,
      );
}

/// Asks the OS whether camera access is refused for good.
///
/// **Ostinato's rule, adapted UNCHANGED** (`camera_session.dart`
/// `permissionState`): `isRestricted` counts as permanent too. A device under
/// parental controls or an MDM policy never shows the dialog at all, so the
/// old "second refusal reads as permanent" heuristic could not see that case
/// even in principle.
///
/// Choreia asks `.status` here because `LiveLessonPage._start` already requested
/// permission. A second request after refusal would repeat the OS prompt.
///
/// **TOP-LEVEL, not a private method on the State, and that is the point.**
/// While this lived inside `_LiveLessonPageState` the only way to exercise it
/// was to build the whole page — so the branch shipped unexercised, and a
/// test could only reach it by injecting `permanentlyDeniedProbe`, which
/// REPLACES this function and therefore proves nothing about the rule inside
/// it. Lissom measured that exact class the same morning (L-283: "kodda
/// vardı, hiç koşulmamıştı"). Reachable from a test, the platform channel can
/// be stubbed and the real chain — channel → plugin → this rule — driven end
/// to end.
Future<bool> askOsPermanentlyDenied() async {
  final PermissionStatus perm = await Permission.camera.status;
  return perm.isPermanentlyDenied || perm.isRestricted;
}
