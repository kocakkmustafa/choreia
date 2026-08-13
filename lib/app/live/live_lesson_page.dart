import 'dart:async';
import 'dart:convert';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_core/motion_core.dart';
// Tam paket, `show` listesi DEĞİL — ölçüldü: `isPermanentlyDenied`/
// `isRestricted`/`status` bu pakette UZANTI (extension) üyeleri, ve bir
// `show` listesi uzantıları gizler. Ostinato da API'yi kullandığı dosyada
// tam import ediyor (`camera_session.dart`).
import 'package:permission_handler/permission_handler.dart';

import '../history/session_store_access.dart';
import '../shell/choreia_page_route.dart';
import 'camera_pose_source.dart';
import 'live_environment.dart';
import 'live_session.dart';
import 'live_state.dart';
import 'live_view.dart';
import 'pose_model.dart';
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

class _LiveLessonPageState extends State<LiveLessonPage> {
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

  late final PoseSource _source =
      widget.env.source?.call() ?? _CameraSource();

  AssetBundle get _bundle => widget.env.bundle ?? rootBundle;

  StreamSubscription<LiveState>? _run;

  /// Guards the one irreversible action on this screen. A second tap while the
  /// write is in flight would append the same practice twice.
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _run?.cancel();
    _source.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final DanceReference reference = DanceReference.fromJson(jsonDecode(
            await _bundle.loadString('content/references/${widget.stepId}.json'))
        as Map<String, dynamic>);
    final Map<String, dynamic> step =
        jsonDecode(await _bundle.loadString(_stepPath(widget.stepId)))
            as Map<String, dynamic>;

    final LiveSession session = LiveSession(
      reference: reference,
      stepConfig: step,
      lessonClass: widget.lessonClass,
      judge: DanceJudge(reference: reference),
    );
    if (!mounted) return;
    setState(() => _gated = session.gatedChecks());

    // NO DEAD END (M-F-268): a refusal becomes a STATE, not an exception that
    // leaves the screen empty with nothing to do.
    final LiveState? refusal = await _source.begin();
    if (!mounted) return;
    if (refusal != null) {
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
      if (!mounted) return;
      setState(() {
        _permanentlyDenied = permanent;
        _state = refusal;
      });
      _tally.observe(refusal, _clock.elapsed);
      return;
    }

    await _run?.cancel();
    _run = session.run(_source.frames()).listen((LiveState s) {
      // The tally is fed BEFORE the mounted check: a state the session
      // produced is a fact about the practice whether or not the widget is
      // still on screen, and dropping the last few would shorten the record.
      _tally.observe(s, _clock.elapsed);
      if (!mounted) return;
      setState(() {
        _state = s;
        if (s is LiveWatching && s.cyclesSeen > 0) _cycles = s.cyclesSeen;
        if (s is LiveJudged || s is LiveMeasured) _cycles = _tally.cyclesRead;
      });
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
    if (_finishing) return;
    setState(() => _finishing = true);

    // NOT AWAITED, and the difference is measurable rather than stylistic.
    //
    // `CameraPoseSource.stop()` is deliberately non-`async` so it publishes
    // its shutdown latch SYNCHRONOUSLY — the next lesson's `start()` waits on
    // that latch, so nothing here needs to. Awaiting the frame subscription is
    // worse than unnecessary: the stream lives in the caller's async zone, and
    // a `cancel()` awaited from a zone that is not advancing that one never
    // returns. Measured: the walk hung at exactly this line, after the tap and
    // before the write, and looked like a missing result screen.
    //
    // Nothing is lost by not waiting — the tally already holds every state the
    // session produced, and it is fed before the mounted check for that reason.
    unawaited(_run?.cancel());
    _run = null;
    unawaited(_source.stop());
    _clock.stop();

    final RecordOutcome outcome = await _writeRecord();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      ChoreiaPageRoute<void>(
        settings: RouteSettings(name: 'result/${widget.lessonId}'),
        builder: (_) => SessionResultView(
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
    if (!_tally.sawCamera) return const RecordNothingToStore();
    final SessionRecord record = _tally.toRecord(endedAt: DateTime.now());
    try {
      final SessionStoreOpener open = widget.env.storeOpener ?? openAppSessionStore;
      await (await open()).append(record);
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
        state: _state,
        gated: _gated,
        notMeasuredNote: LiveSession.notMeasuredNote,
        cyclesRead: _cycles,
        permissionPermanentlyDenied: _permanentlyDenied,
        onRetry: _start,
        // C-140 KAPANDI (koordinatör hükmü (A), C-222). Buraya `null`
        // geçiliyordu ve ekranın tek kontrolü DEVRE DIŞI bir düğmeydi —
        // M-F-268'in yasakladığı ölü-sonun kendisi. Artık gerçek bir çağrı.
        onOpenSettings: widget.env.openSettings ?? openAppSettings,
        onFinish: _finishing ? null : _finish,
      );
}

/// The shipping source: the device camera, plus the pose model it needs.
///
/// **Materialising the model belongs HERE, not in the page.** The plugin opens
/// a filesystem path, not an asset key (see `pose_model.dart` for why that
/// distinction was invisible until it was measured) — and a replay source has
/// no model to place. Keeping the step inside the camera implementation is
/// what makes [PoseSource] substitutable at all.
class _CameraSource implements PoseSource {
  final CameraPoseSource _camera = CameraPoseSource();

  @override
  Future<LiveState?> begin() async => _camera.start(
        modelPath: await materialisePoseModel(),
        modelId: PoseModelPin.modelId,
      );

  @override
  Stream<PoseFrame> frames() => _camera.frames();

  @override
  Future<void> stop() => _camera.stop();
}

/// Asks the OS whether camera access is refused for good.
///
/// **Ostinato's rule, adapted UNCHANGED** (`camera_session.dart`
/// `permissionState`): `isRestricted` counts as permanent too. A device under
/// parental controls or an MDM policy never shows the dialog at all, so the
/// old "second refusal reads as permanent" heuristic could not see that case
/// even in principle.
///
/// Choreia asks `.status` rather than `request()` because the camera plugin
/// has already done the asking by the time we get a refusal — re-requesting
/// here would pop a second dialog for a question the OS just answered.
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
