import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart' show AssetBundle, VoidCallback;
import 'package:motion_core/motion_core.dart' show SessionStore;

import '../history/session_store_access.dart';
import '../history/account_store_lifetime.dart';
import 'camera_pose_source.dart';

/// Everything a live lesson needs that differs between a real device and a
/// walk-through.
///
/// **One object rather than three fields, and the reason is measured rather
/// than aesthetic.** The lesson is reached through two intermediaries
/// (`LibraryView` → `StyleDetailView`), neither of which has any business
/// knowing what an asset bundle or a session store is. Threading three
/// unrelated parameters through both would put six fields on two widgets that
/// only forward them — and the day a fourth seam appears, the widget that
/// forgets to forward it fails SILENTLY: the lesson quietly falls back to the
/// device default and the walk stops testing what it thinks it tests.
///
/// Bundled, forgetting is a compile error at exactly one place.
///
/// The default is the real thing: `const LiveEnvironment()` means bundle =
/// `rootBundle`, poses = the camera, history = the app's own store. A screen
/// that is handed nothing behaves exactly as it did before this type existed.
class LiveEnvironment {
  const LiveEnvironment({
    this.bundle,
    this.source,
    this.storeOpener,
    this.accountUserId,
    this.passwordRecovery,
    this.ownerEpoch,
    this.storeOwners,
    this.historyDirectoryOverride,
    this.permanentlyDeniedProbe,
    this.cameraPermissionRequest,
    this.openSettings,
  });

  /// Where content is read from. `null` = `rootBundle`.
  ///
  /// A substitute must imitate the device's FAILURE MODE (an asset that
  /// `pubspec.yaml` does not declare must throw), not merely its signature —
  /// `test/reachability_test.dart`'s `DeviceBundle` is the one that does, and
  /// the plain disk-reading fake it replaced produced a Start button no phone
  /// would ever paint.
  final AssetBundle? bundle;

  /// Where poses come from. `null` = the device camera.
  ///
  /// Replay is this project's only accepted verification path for camera work.
  final PoseSource Function()? source;

  /// Where a finished session is written. `null` = the app's real store.
  final SessionStoreOpener? storeOpener;

  /// The host supplies the canonical runtime's verified user id. A null id
  /// admits guest data only when the canonical phase is genuinely signed out.
  final ValueListenable<String?>? accountUserId;

  /// Directly supplied from MotionAccountRuntime.passwordRecovery. A same-UUID
  /// callback must retire a running route even when userId does not notify.
  final ValueListenable<bool>? passwordRecovery;

  /// Host retirement epoch also covers a replacement Auth session whose UUID
  /// is unchanged. It never establishes identity or mirrors recovery state.
  final ValueListenable<int>? ownerEpoch;

  /// Tests can own an isolated store lifetime; production shares the host's.
  final AppStoreOwnerRegistry? storeOwners;

  /// Local filesystem seam for scope tests; production uses app support.
  final Directory? historyDirectoryOverride;

  Future<SessionStore> openStoreFor(String? userId) =>
      storeOpener?.call() ??
      openAppSessionStore(
        accountUserId: userId,
        supportDirectory: historyDirectoryOverride,
        owners: storeOwners,
      );

  /// Asks the OS whether camera access is refused for good. `null` = the real
  /// query (`askOsPermanentlyDenied`).
  ///
  /// Moved here from the page's own parameter list when the walk needed it:
  /// under `flutter test` the platform channel answers nothing, and a screen
  /// that asks one directly cannot be walked at all. It is a device-only
  /// dependency like the other three, and keeping it in a second place was how
  /// a forwarder would come to relay three of four seams and silently drop the
  /// fourth.
  final Future<bool> Function()? permanentlyDeniedProbe;

  /// Starts the OS camera permission request. Null uses permission_handler;
  /// replay tests may inject the dialog's timing without opening a camera.
  final Future<bool> Function()? cameraPermissionRequest;

  /// Opens the OS settings page. `null` = `permission_handler`'s
  /// `openAppSettings`, the same call Ostinato makes.
  final VoidCallback? openSettings;
}
