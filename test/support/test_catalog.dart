import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset bundle backed by the repository files.
///
/// WHY NOT `rootBundle`: `rootBundle.loadString` never completes under
/// `flutter test` in this setup — probed three ways (plain `test`,
/// `testWidgets`, `testWidgets` + `runAsync`) and every one hung with the
/// tester process at 0% CPU, which is what separates a deadlock from a slow
/// machine. Rather than skip real-content checks, the bundle reads the files
/// directly so `CourseCatalog.load` runs in full.
///
/// The honest limit, unchanged: this exercises the LOADER and the DERIVATION
/// against real content, NOT Flutter's asset plumbing. Whether the declared
/// asset paths resolve on a device is a separate claim these tests do not make.
///
/// Lives here rather than being copied per test file: two copies of a fake
/// drift apart and the second one starts agreeing with whatever its author
/// believed (M-F-03).
class DiskBundle extends CachingAssetBundle {
  /// 🪤 DECODED HERE, NOT BY `compute()`.
  ///
  /// `AssetBundle.loadString` hands anything over 50 KB to `compute()`, which
  /// spawns an isolate — and an isolate never runs under `flutter test`'s fake
  /// clock, so the tester hangs at 0% CPU. That is the documented reason
  /// `rootBundle` is unusable here; inheriting `loadString` unchanged
  /// reproduced the same hang through a fake that was supposed to avoid it,
  /// and it did so ONLY for the two files big enough to cross the threshold
  /// (the references, 74–79 KB) — every smaller asset worked, which is exactly
  /// what made it look like a bundle problem rather than a size one.
  ///
  /// Caching the result is NOT the fix and was tried first: a cache hit still
  /// has to be a hit on a future the fake zone can complete, and pre-warming
  /// from `setUpAll` did not change the symptom.
  ///
  /// A fake must imitate the FAILURE MODE, not the implementation (C-115) —
  /// and "the decode blocks" is an implementation detail of the real bundle,
  /// not a failure a device exhibits.
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode((await load(key)).buffer.asUint8List());

  @override
  Future<ByteData> load(String key) async {
    final File file = File(key);
    if (!file.existsSync()) {
      // The same shape of failure the real bundle raises for a missing asset —
      // the branch `CourseCatalog.load` must survive for a step whose document
      // is not written yet. A fake must imitate the FAILURE MODE, not just the
      // signature (C-115): throwing `Exception` here would let a handler that
      // catches the wrong type pass in test and crash on device.
      throw FlutterError('asset not found: $key');
    }
    return ByteData.view(file.readAsBytesSync().buffer);
  }
}

/// The real catalog, loaded from the repository's own content.
Future<CourseCatalog> testCatalog() => CourseCatalog.load(DiskBundle());

/// The real library — all 34 declared styles plus the two authored on disk.
Future<LibraryCatalog> testLibrary() => LibraryCatalog.load(DiskBundle());

/// The reference files `pubspec.yaml` actually ships, parsed from the manifest
/// rather than from the directory listing.
///
/// `content/references/` is declared FILE BY FILE (the directory also holds
/// build-time bookkeeping that must not ship), so "on disk" and "in the app"
/// are different sets — and only the second one exists on a device.
Set<String> declaredReferences() => File('pubspec.yaml')
    .readAsLinesSync()
    .map((String l) => l.trim())
    .where((String l) => l.startsWith('- content/references/'))
    .map((String l) => l.substring('- content/references/'.length)
        .replaceAll('.json', ''))
    .toSet();

/// A bundle that fails for an undeclared reference the way a real device does.
///
/// WHY THIS EXISTS: [DiskBundle] reads the filesystem, so it happily returns a
/// file `pubspec.yaml` never ships. Measuring reachability through it produced
/// a Start button the device would never paint — and the walk then crashed in
/// `LiveLessonPage`, which loads from `rootBundle` and got the real answer.
/// A fake must imitate the FAILURE MODE, not just the signature (C-115); this
/// one was imitating the wrong machine entirely.
///
/// Lives here rather than in one test file because the first-walk test needs
/// the SAME machine the navigability measurement uses: a walk driven through a
/// more forgiving bundle would open doors a phone does not have.
class DeviceBundle extends DiskBundle {
  DeviceBundle(this.declared);

  final Set<String> declared;

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('content/references/')) {
      final String step =
          key.substring('content/references/'.length).replaceAll('.json', '');
      if (!declared.contains(step)) {
        throw FlutterError('asset not declared in pubspec.yaml: $key');
      }
    }
    return super.load(key);
  }
}
