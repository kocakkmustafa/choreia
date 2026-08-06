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
