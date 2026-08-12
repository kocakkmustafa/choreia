import 'dart:convert';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Tam paket, `show` listesi DEĞİL — ölçüldü: `isPermanentlyDenied`/
// `isRestricted`/`status` bu pakette UZANTI (extension) üyeleri, ve bir
// `show` listesi uzantıları gizler. Ostinato da API'yi kullandığı dosyada
// tam import ediyor (`camera_session.dart`).
import 'package:permission_handler/permission_handler.dart';

import 'camera_pose_source.dart';
import 'live_session.dart';
import 'live_state.dart';
import 'live_view.dart';
import 'pose_model.dart';

/// Runs one lesson's live path and renders whatever it honestly reports.
///
/// Lifted out of `main.dart` unchanged (2026-08-07) when the navigation shell
/// landed. Before that, this WAS the app: `main.dart` hardcoded one
/// `stepId`/`lessonClass` pair because there was nothing to reach it from. It
/// is now pushed from a lesson card, and the pair it runs comes from content
/// instead of from a literal in the entry point.
///
/// The behaviour is deliberately untouched by that move. The live path is the
/// one chain in this app that is verified end to end (kısım-1+2, `b9e448e`),
/// and a navigation turn is the wrong time to also change what it does.
class LiveLessonPage extends StatefulWidget {
  const LiveLessonPage({
    super.key,
    required this.stepId,
    required this.lessonClass,
    this.styleId,
    this.permanentlyDeniedProbe,
    this.openSettings,
  });

  final String stepId;
  final String lessonClass;

  /// Asks the OS whether camera access is refused for good.
  ///
  /// **A SEAM, and it exists because the answer used to be GUESSED.** Until
  /// C-222 this page inferred "permanent" from a second refusal in a row —
  /// a heuristic wrong in both directions: a policy-restricted device is
  /// permanent on the FIRST refusal, and declining twice on purpose does not
  /// mean the switch was turned off for good.
  ///
  /// Injected rather than called inline for the reason JabLab injects the
  /// same question into its controller: a platform channel cannot answer
  /// under `flutter test`, so a screen that asks one directly cannot be
  /// walked at all. Default is the real query.
  final Future<bool> Function()? permanentlyDeniedProbe;

  /// Opens the OS settings page. Defaults to `permission_handler`'s
  /// `openAppSettings` — the same call Ostinato makes, which is the only
  /// line in the family that actually opens settings (measured; JabLab's
  /// `openSettings` is its own in-app page).
  final VoidCallback? openSettings;

  /// Which style's `steps/` directory holds this step's document.
  ///
  /// Optional so the historical two-style prefix rule still works, but passed
  /// by every caller in the shell: inferring a directory from an id prefix
  /// stops working the moment a third style ships, and a wrong guess here is a
  /// failed asset load rather than a visible mistake.
  final String? styleId;

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

  final CameraPoseSource _camera = CameraPoseSource();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _camera.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final DanceReference reference = DanceReference.fromJson(jsonDecode(
            await rootBundle
                .loadString('content/references/${widget.stepId}.json'))
        as Map<String, dynamic>);
    final Map<String, dynamic> step =
        jsonDecode(await rootBundle.loadString(_stepPath(widget.stepId)))
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
    // The model is copied out of the bundle to a real file first — the
    // plugin opens a filesystem path, not an asset key (see `pose_model.dart`
    // for why that distinction was invisible until it was measured).
    final LiveState? refusal = await _camera.start(
      modelPath: await materialisePoseModel(),
      modelId: PoseModelPin.modelId,
    );
    if (!mounted) return;
    if (refusal != null) {
      // ASK, do not infer. Ostinato's rule, adapted unchanged: `isRestricted`
      // counts as permanent too — a device under parental controls or an MDM
      // policy never shows the dialog at all, and the old second-refusal
      // heuristic could not see that case even in principle.
      bool permanent = false;
      if (refusal is LivePermissionDenied) {
        final Future<bool> Function() probe =
            widget.permanentlyDeniedProbe ?? askOsPermanentlyDenied;
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
      return;
    }

    session.run(_camera.frames()).listen((LiveState s) {
      if (!mounted) return;
      setState(() {
        _state = s;
        if (s is LiveWatching && s.cyclesSeen > 0) _cycles = s.cyclesSeen;
      });
    });
  }

  String _stepPath(String id) {
    final String style = widget.styleId ??
        (id.startsWith('ss_') ? 'salsa_shines' : 'hip_hop_foundations');
    return 'content/styles/$style/steps/$id.json';
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
        onOpenSettings: widget.openSettings ?? openAppSettings,
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
