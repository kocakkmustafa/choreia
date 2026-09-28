import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'lesson_media_catalog.dart';

/// Inspection seam for a future lesson media surface. No rendering, playback,
/// permission request, or progress-store dependency exists in this widget.
/// The only shipping catalog is empty; a signed acceptance root and a real
/// player will require a separate change before any learner sees media.
class LessonMediaSlot extends StatefulWidget {
  const LessonMediaSlot({
    required this.catalog,
    required this.bundle,
    required this.lessonId,
    required this.sceneId,
    required this.variantStem,
    required this.locale,
    this.durationProbe,
    this.accountUserId,
    @visibleForTesting this.onInspectionChanged,
    super.key,
  });

  final LessonMediaCatalog catalog;
  final AssetBundle bundle;
  final String lessonId, sceneId, variantStem, locale;
  final MediaDurationProbe? durationProbe;
  final ValueListenable<String?>? accountUserId;

  /// Allows a synthetic test to observe inspection without exposing UI.
  final ValueChanged<InspectedLessonMedia?>? onInspectionChanged;

  @override
  State<LessonMediaSlot> createState() => _LessonMediaSlotState();
}

class _LessonMediaSlotState extends State<LessonMediaSlot>
    with WidgetsBindingObserver {
  int _epoch = 0;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.accountUserId?.addListener(_close);
    _inspect();
  }

  @override
  void didUpdateWidget(covariant LessonMediaSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId) {
      oldWidget.accountUserId?.removeListener(_close);
      widget.accountUserId?.addListener(_close);
      _close();
    }
    if (!_closed &&
        (oldWidget.catalog != widget.catalog ||
            oldWidget.bundle != widget.bundle ||
            oldWidget.lessonId != widget.lessonId ||
            oldWidget.sceneId != widget.sceneId ||
            oldWidget.variantStem != widget.variantStem ||
            oldWidget.locale != widget.locale ||
            oldWidget.durationProbe != widget.durationProbe)) {
      _inspect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _close();
  }

  void _close() {
    _epoch++;
    _closed = true;
    widget.onInspectionChanged?.call(null);
  }

  Future<void> _inspect() async {
    if (_closed || widget.catalog.isEmpty) return;
    final epoch = ++_epoch;
    final result = await widget.catalog.inspect(
      bundle: widget.bundle,
      lessonId: widget.lessonId,
      sceneId: widget.sceneId,
      variantStem: widget.variantStem,
      locale: widget.locale,
      durationProbe: widget.durationProbe,
    );
    if (mounted && !_closed && epoch == _epoch) {
      widget.onInspectionChanged?.call(result);
    }
  }

  @override
  void dispose() {
    _epoch++;
    widget.accountUserId?.removeListener(_close);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
