import 'dart:convert';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camera_pose_source.dart';
import 'live_session.dart';
import 'live_state.dart';
import 'live_view.dart';

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
  });

  final String stepId;
  final String lessonClass;

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

  /// A second refusal reads as permanent. Getting this wrong in the other
  /// direction is the worse failure: a "try again" button that can never
  /// work (M-F-268).
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
    final LiveState? refusal = await _camera.start(
      modelPath: 'assets/pose_landmarker_full.task',
      modelId: 'pose_landmarker_full',
    );
    if (!mounted) return;
    if (refusal != null) {
      setState(() {
        if (refusal is LivePermissionDenied && _state is LivePermissionDenied) {
          _permanentlyDenied = true;
        }
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
        // KNOWN DEFECT, carried forward deliberately (C-140, DEFTER
        // 2026-08-07): there is no way to open the OS settings page from this
        // app — neither `motion_camera` nor any current dependency exposes
        // one — so the permanently-denied branch's button has nothing to call.
        // It was `() {}` (an enabled button that silently does nothing) before
        // this file existed; passing null at least disables it rather than
        // faking an action.
        //
        // NOT fixed here because the fix is a dependency decision
        // (`permission_handler`) and this turn's brief is explicit that the
        // live screen is preserved, not renegotiated. Named, not silently
        // inherited.
        onOpenSettings: null,
      );
}
