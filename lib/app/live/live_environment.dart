import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart' show AssetBundle, VoidCallback;
import 'package:motion_core/motion_core.dart' show SessionStore;

import '../history/session_store_access.dart';
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

  /// Host account adapter publishes the current Supabase user id here.
  /// `null` means guest. No Core account dependency is needed until its pin
  /// exists; the host later maps `authChanges` to this listenable.
  final ValueListenable<String?>? accountUserId;

  /// Local filesystem seam for scope tests; production uses app support.
  final Directory? historyDirectoryOverride;

  Future<SessionStore> openStoreFor(String? userId) =>
      storeOpener?.call() ??
      openAppSessionStore(
        accountUserId: userId,
        supportDirectory: historyDirectoryOverride,
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
