import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter/widgets.dart';

import 'lesson_media_catalog.dart';
import '../../history/account_store_lifetime.dart';
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
    this.passwordRecovery,
    this.ownerEpoch,
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
    this.passwordRecovery,
    this.ownerEpoch,
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
    this.passwordRecovery,
    this.ownerEpoch,
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
  final ValueListenable<bool>? passwordRecovery;
  final ValueListenable<int>? ownerEpoch;

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
  int _playbackGeneration = 0;
  bool _closed = false;
  bool _accountRevoked = false;
  bool _recoveryRetired = false;
  final _playbackAdmission = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.accountUserId?.addListener(_onAccount);
    widget.passwordRecovery?.addListener(_onRecovery);
    widget.ownerEpoch?.addListener(_onOwnerEpoch);
    if (widget.passwordRecovery?.value == true) {
      _recoveryRetired = true;
      _close(notify: false);
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      _close(notify: false);
    }
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
    if (oldWidget.ownerEpoch != widget.ownerEpoch) {
      oldWidget.ownerEpoch?.removeListener(_onOwnerEpoch);
      widget.ownerEpoch?.addListener(_onOwnerEpoch);
      _accountRevoked = true;
      _close(notify: false);
    }
    if (oldWidget.passwordRecovery != widget.passwordRecovery) {
      oldWidget.passwordRecovery?.removeListener(_onRecovery);
      widget.passwordRecovery?.addListener(_onRecovery);
      // A replacement cannot inherit an in-flight admission from its predecessor.
      _recoveryRetired = true;
      _close(notify: false);
    }
    if (widget.passwordRecovery?.value == true) _onRecovery();
    if (!_closed &&
        (oldWidget.catalog != widget.catalog ||
            oldWidget.bundle != widget.bundle ||
            oldWidget.lessonId != widget.lessonId ||
            oldWidget.sceneId != widget.sceneId ||
            oldWidget.variantStem != widget.variantStem ||
            oldWidget.locale != widget.locale ||
            oldWidget.durationProbe != widget.durationProbe ||
            oldWidget.onInspectionChanged != widget.onInspectionChanged ||
            oldWidget.testingPlayback != widget.testingPlayback ||
            oldWidget.testingVideoFactory != widget.testingVideoFactory)) {
      _inspect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _close();
    } else if (_closed &&
        !_accountRevoked &&
        !_recoveryRetired &&
        widget.passwordRecovery?.value != true) {
      _closed = false;
      _playbackGeneration++;
      _playbackAdmission.value = true;
      if (mounted) setState(() {});
      _inspect();
    }
  }

  void _onAccount() {
    _accountRevoked = true;
    _close();
  }

  void _onOwnerEpoch() => _onAccount();

  void _onRecovery() {
    if (widget.passwordRecovery?.value != true) return;
    _recoveryRetired = true;
    _close();
  }

  void _deliver(ValueChanged<InspectedLessonMedia?>? observer,
      InspectedLessonMedia? result) {
    try {
      observer?.call(result);
    } catch (_) {
      // Inspection observers cannot escape as unhandled asynchronous errors.
    }
  }

  void _close({bool notify = true}) {
    _epoch++;
    _closed = true;
    // Listeners retire pending native preparation before the next widget frame.
    _playbackAdmission.value = false;
    _deliver(widget.onInspectionChanged, null);
    if (notify && mounted) setState(() {});
  }

  Future<void> _inspect() async {
    // Empty or unbound replacements revoke pending inspections as well.
    final epoch = ++_epoch;
    final onInspectionChanged = widget.onInspectionChanged;
    final sceneId = widget.sceneId;
    final variantStem = widget.variantStem;
    if (_closed ||
        widget.catalog.isEmpty ||
        sceneId == null ||
        variantStem == null) {
      _deliver(onInspectionChanged, null);
      return;
    }
    final result = await widget.catalog.inspect(
      bundle: widget.bundle,
      lessonId: widget.lessonId,
      sceneId: sceneId,
      variantStem: variantStem,
      locale: widget.locale,
      durationProbe: widget.durationProbe,
    );
    if (mounted &&
        !_closed &&
        !_recoveryRetired &&
        widget.passwordRecovery?.value != true &&
        epoch == _epoch) {
      _deliver(onInspectionChanged, result);
    }
  }

  @override
  void dispose() {
    _epoch++;
    _playbackAdmission.value = false;
    widget.accountUserId?.removeListener(_onAccount);
    widget.passwordRecovery?.removeListener(_onRecovery);
    widget.ownerEpoch?.removeListener(_onOwnerEpoch);
    WidgetsBinding.instance.removeObserver(this);
    _playbackAdmission.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixture = widget.testingPlayback;
    final videoFactory = widget.testingVideoFactory;
    if (!kReleaseMode &&
        !_closed &&
        !_recoveryRetired &&
        widget.passwordRecovery?.value != true &&
        fixture != null &&
        videoFactory != null &&
        fixture.lessonId == widget.lessonId &&
        fixture.captionAssetPaths.containsKey(widget.locale)) {
      return LessonMediaPlayback(
        key: ValueKey<String>(
            '${widget.lessonId}\u0000${widget.locale}\u0000${fixture.videoAssetPath}\u0000$_playbackGeneration'),
        fixture: fixture,
        bundle: widget.bundle,
        locale: widget.locale,
        videoFactory: videoFactory,
        admissionOpen: _playbackAdmission,
        ownerTicket: widget.accountUserId == null ? null :
            appStoreOwners.capture(widget.accountUserId!.value),
      );
    }
    return const SizedBox.shrink();
  }
}
