import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter/widgets.dart';

import 'lesson_media_catalog.dart';
import 'lesson_media_playback.dart';

/// The shipping route stays empty. A separate test-only playback fixture
/// exercises the future player without treating a staging inspection as a
/// signed publication decision.
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
  })  : testingPlayback = null,
        testingVideoFactory = null;

  /// Shipping lesson seam: it has no scene, variant, candidate, or probe.
  /// The same bundle and account context are kept for a later signed rollout.
  LessonMediaSlot.empty({
    required this.lessonId,
    required this.locale,
    this.accountUserId,
    AssetBundle? bundle,
    super.key,
  })  : catalog = const LessonMediaCatalog.empty(),
        bundle = bundle ?? rootBundle,
        sceneId = null,
        variantStem = null,
        durationProbe = null,
        onInspectionChanged = null,
        testingPlayback = null,
        testingVideoFactory = null;

  /// This path is hidden in release builds and never reads the v3 staging
  /// catalog. A signed acceptance root must provide a new shipping path.
  @visibleForTesting
  LessonMediaSlot.testingPlayback({
    required this.lessonId,
    required this.locale,
    required LessonMediaPlaybackFixture fixture,
    required this.bundle,
    this.accountUserId,
    LessonVideoFactory videoFactory = createAssetLessonVideo,
    super.key,
  })  : catalog = const LessonMediaCatalog.empty(),
        sceneId = null,
        variantStem = null,
        durationProbe = null,
        onInspectionChanged = null,
        testingPlayback = fixture,
        testingVideoFactory = videoFactory;

  final LessonMediaCatalog catalog;
  final AssetBundle bundle;
  final String lessonId, locale;
  final String? sceneId, variantStem;
  final MediaDurationProbe? durationProbe;
  final ValueListenable<String?>? accountUserId;

  /// Allows a synthetic test to observe inspection without exposing UI.
  final ValueChanged<InspectedLessonMedia?>? onInspectionChanged;
  final LessonMediaPlaybackFixture? testingPlayback;
  final LessonVideoFactory? testingVideoFactory;

  @override
  State<LessonMediaSlot> createState() => _LessonMediaSlotState();
}

class _LessonMediaSlotState extends State<LessonMediaSlot>
    with WidgetsBindingObserver {
  int _epoch = 0;
  bool _closed = false;
  bool _accountRevoked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.accountUserId?.addListener(_onAccount);
    _inspect();
  }

  @override
  void didUpdateWidget(covariant LessonMediaSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountUserId != widget.accountUserId) {
      oldWidget.accountUserId?.removeListener(_onAccount);
      widget.accountUserId?.addListener(_onAccount);
      _accountRevoked = true;
      _close(notify: false);
    }
    if (!_closed &&
        (oldWidget.catalog != widget.catalog ||
            oldWidget.bundle != widget.bundle ||
            oldWidget.lessonId != widget.lessonId ||
            oldWidget.sceneId != widget.sceneId ||
            oldWidget.variantStem != widget.variantStem ||
            oldWidget.locale != widget.locale ||
            oldWidget.durationProbe != widget.durationProbe ||
            oldWidget.testingPlayback != widget.testingPlayback ||
            oldWidget.testingVideoFactory != widget.testingVideoFactory)) {
      _inspect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _close();
    } else if (_closed && !_accountRevoked) {
      _closed = false;
      if (mounted) setState(() {});
      _inspect();
    }
  }

  void _onAccount() {
    _accountRevoked = true;
    _close();
  }

  void _close({bool notify = true}) {
    _epoch++;
    _closed = true;
    widget.onInspectionChanged?.call(null);
    if (notify && mounted) setState(() {});
  }

  Future<void> _inspect() async {
    final sceneId = widget.sceneId;
    final variantStem = widget.variantStem;
    if (_closed ||
        widget.catalog.isEmpty ||
        sceneId == null ||
        variantStem == null) {
      return;
    }
    final epoch = ++_epoch;
    final result = await widget.catalog.inspect(
      bundle: widget.bundle,
      lessonId: widget.lessonId,
      sceneId: sceneId,
      variantStem: variantStem,
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
    widget.accountUserId?.removeListener(_onAccount);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixture = widget.testingPlayback;
    final videoFactory = widget.testingVideoFactory;
    if (!kReleaseMode &&
        !_closed &&
        fixture != null &&
        videoFactory != null &&
        fixture.lessonId == widget.lessonId &&
        fixture.captionAssetPaths.containsKey(widget.locale)) {
      return LessonMediaPlayback(
        key: ValueKey<String>(
            '${widget.lessonId}\u0000${widget.locale}\u0000${fixture.videoAssetPath}'),
        fixture: fixture,
        bundle: widget.bundle,
        locale: widget.locale,
        videoFactory: videoFactory,
      );
    }
    return const SizedBox.shrink();
  }
}
