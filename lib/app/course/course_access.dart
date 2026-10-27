import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:motion_account/motion_account.dart'
    show MotionTeenPurchasePolicy, motionSubscriptionSalesAvailable;

/// Subscription sales are open in the first release (owner decision,
/// 23 Oct 2026) while live camera practice and scoring stay closed
/// (`motionCameraCoachingAvailable`). Choreia follows Core's sales flag.
const bool choreiaSubscriptionSalesOpen = motionSubscriptionSalesAvailable;

/// Owner decision (27 Oct 2026, K-2: all five Motion apps): a 13–17 account
/// still waiting for parental consent sees the subscription offers, and the
/// purchase itself is left to the store's family controls (Ask to Buy /
/// Google Play parental approval). Core R4 keeps `parentalConsentRequired` as
/// its default, so every Core purchase entry point in `main.dart` passes this.
/// Account features stay closed until consent; under-13 accounts cannot buy.
const MotionTeenPurchasePolicy choreiaTeenPurchasePolicy =
    MotionTeenPurchasePolicy.storeFamilyControls;

/// Which written lessons are free and how a paid one is unlocked.
///
/// Owner decision (23 Oct 2026, Motion paywall "A"): the first module or
/// roughly the first third of every course is free; the remaining lessons
/// and their practice open with a Choreia or Motion+ membership. Progress
/// records stay readable whether or not a lesson is unlocked.
abstract class CourseAccess {
  const CourseAccess();

  /// Free lessons per course, in course order. Salsa counts whole modules
  /// (3 of 8 modules = 18 of 48 lessons, the module boundary nearest a third);
  /// the flat courses round a third up.
  static const Map<String, int> freeLessons = <String, int>{
    'salsa_shines': 18,
    'hip_hop_foundations': 3,
    'line_dance': 4,
    'latin_fusion_fitness': 4,
    'tiktok_format': 4,
  };

  /// [position] is the 1-based place of the lesson in its course.
  static bool isFree(String styleId, int position) =>
      position <= (freeLessons[styleId] ?? 0);

  /// False only where a membership check guards paid lessons.
  bool get allOpen;

  /// True once a membership has been confirmed for the current owner.
  ValueListenable<bool> get unlocked;

  /// Asks for a membership (sign-in, purchase or restore as needed).
  Future<bool> unlock(BuildContext context);

  bool canOpen(String styleId, int position) =>
      allOpen || unlocked.value || isFree(styleId, position);
}

/// Every lesson open — tests and the isolated readers.
class OpenCourseAccess extends CourseAccess {
  const OpenCourseAccess();

  static final ValueListenable<bool> _always = ValueNotifier<bool>(true);

  @override
  bool get allOpen => true;

  @override
  ValueListenable<bool> get unlocked => _always;

  @override
  Future<bool> unlock(BuildContext context) async => true;
}

/// Paid lessons ask [gate] (Core `requireMotionPaidAccess`) once per owner;
/// a change of [ownerEpoch] (sign-out, another account) locks them again.
class SubscriptionCourseAccess extends CourseAccess {
  SubscriptionCourseAccess({
    required Future<bool> Function(BuildContext context) gate,
    ValueListenable<int>? ownerEpoch,
  })  : _gate = gate,
        _ownerEpoch = ownerEpoch {
    _ownerEpoch?.addListener(_relock);
  }

  final Future<bool> Function(BuildContext context) _gate;
  final ValueListenable<int>? _ownerEpoch;
  final ValueNotifier<bool> _unlocked = ValueNotifier<bool>(false);

  @override
  bool get allOpen => false;

  @override
  ValueListenable<bool> get unlocked => _unlocked;

  void _relock() => _unlocked.value = false;

  @override
  Future<bool> unlock(BuildContext context) async {
    if (_unlocked.value) return true;
    final int? epoch = _ownerEpoch?.value;
    final bool granted = await _gate(context);
    if (granted && epoch == _ownerEpoch?.value) _unlocked.value = true;
    return _unlocked.value;
  }

  void dispose() {
    _ownerEpoch?.removeListener(_relock);
    _unlocked.dispose();
  }
}
