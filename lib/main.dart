import 'dart:convert';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/live/camera_pose_source.dart';
import 'app/live/live_session.dart';
import 'app/live/live_state.dart';
import 'app/live/live_view.dart';

/// Choreia's entry point.
///
/// Deliberately thin: it opens the ONE scored lesson's live path so the camera
/// chain can be exercised end to end. No navigation shell yet — building one
/// around an unverified chain would be decorating something that does not work.
void main() => runApp(const ChoreiaApp());

class ChoreiaApp extends StatelessWidget {
  const ChoreiaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Choreia',
        theme: ThemeData(useMaterial3: true),
        home: const LiveLessonPage(
          stepId: 'ss_shine_footwork',
          lessonClass: 'scored',
        ),
      );
}

/// Runs one lesson's live path and renders whatever it honestly reports.
class LiveLessonPage extends StatefulWidget {
  const LiveLessonPage({
    super.key,
    required this.stepId,
    required this.lessonClass,
  });

  final String stepId;
  final String lessonClass;

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
            await rootBundle.loadString(
                'content/references/${widget.stepId}.json'))
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

  static String _stepPath(String id) => id.startsWith('ss_')
      ? 'content/styles/salsa_shines/steps/$id.json'
      : 'content/styles/hip_hop_foundations/steps/$id.json';

  @override
  Widget build(BuildContext context) => LiveView(
        state: _state,
        gated: _gated,
        notMeasuredNote: LiveSession.notMeasuredNote,
        cyclesRead: _cycles,
        permissionPermanentlyDenied: _permanentlyDenied,
        onRetry: _start,
        onOpenSettings: () {},
      );
}
