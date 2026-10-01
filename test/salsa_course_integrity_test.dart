import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_course_repository.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_content/motion_content.dart';

import 'support/test_catalog.dart';

final class _AssetOverlayBundle extends DiskBundle {
  _AssetOverlayBundle({
    this.courseBytes,
    this.missingManifest = false,
    this.missingCourse = false,
    this.timeoutManifest = false,
    this.ioManifest = false,
  });

  final Uint8List? courseBytes;
  final bool missingManifest;
  final bool missingCourse;
  final bool timeoutManifest;
  final bool ioManifest;
  final List<String> requestedPaths = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedPaths.add(key);
    if (key == salsaIntegrityManifestPath && timeoutManifest) {
      throw TimeoutException('asset read timed out');
    }
    if (key == salsaIntegrityManifestPath && ioManifest) {
      throw const ContentException(ContentError(code: ContentErrorCode.io));
    }
    if ((key == salsaIntegrityManifestPath && missingManifest) ||
        (key == salsaCourseAssetPath && missingCourse)) {
      throw FlutterError('asset unavailable: $key');
    }
    if (key == salsaCourseAssetPath && courseBytes != null) {
      final Uint8List bytes = courseBytes!;
      return Future<ByteData>.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }
    return super.load(key);
  }
}

Future<ContentException> _rejection(_AssetOverlayBundle bundle) async {
  try {
    await SalsaCourseRepository.load(bundle);
  } on ContentException catch (error) {
    return error;
  }
  throw StateError('Expected the Salsa integrity gate to reject the bundle');
}

Uint8List _sameLengthTamper() {
  final Uint8List original = File(salsaCourseAssetPath).readAsBytesSync();
  final Uint8List changed = Uint8List.fromList(original);
  changed[changed.length - 1] = original.last == 10 ? 32 : 10;
  expect(changed.length, original.length);
  expect(() => jsonDecode(utf8.decode(changed)), returnsNormally);
  return changed;
}

Future<void> _pumpFailedCourse(
    WidgetTester tester, _AssetOverlayBundle bundle) async {
  tester.binding.platformDispatcher.localesTestValue = const <Locale>[
    Locale('en'),
  ];
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
  final Directory directory =
      Directory.systemTemp.createTempSync('choreia-integrity-');
  addTearDown(() => directory.deleteSync(recursive: true));
  await tester.pumpWidget(MaterialApp(
    home: SalsaCoursePage(
      env: LiveEnvironment(
        bundle: bundle,
        historyDirectoryOverride: directory,
      ),
    ),
  ));

  for (var i = 0;
      i < 40 && find.byKey(const Key('salsa.loadError')).evaluate().isEmpty;
      i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byKey(const Key('salsa.loadError')), findsOneWidget);
  expect(find.byKey(const Key('salsa.completedCount')), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real manifest verifies the 48-lesson course before parsing', () async {
    final _AssetOverlayBundle bundle = _AssetOverlayBundle();
    final course = await SalsaCourseRepository.load(bundle);

    expect(course.modules, hasLength(8));
    expect(course.lessons, hasLength(48));
    expect(bundle.requestedPaths.first, salsaIntegrityManifestPath);
    expect(
      bundle.requestedPaths.where((path) => path == salsaCourseAssetPath),
      hasLength(2),
    );
  });

  test('Flutter bundle actually includes the generated manifest', () async {
    final course = await SalsaCourseRepository.load(rootBundle);
    expect(course.lessons, hasLength(48));
  });

  test('same-length parseable tamper is blocked as a hash mismatch', () async {
    final _AssetOverlayBundle bundle =
        _AssetOverlayBundle(courseBytes: _sameLengthTamper());
    final ContentException error = await _rejection(bundle);

    expect(error.error.code, ContentErrorCode.hashMismatch);
    expect(bundle.requestedPaths, contains(salsaCourseAssetPath));
  });

  test('missing manifest blocks before reading course', () async {
    final _AssetOverlayBundle bundle =
        _AssetOverlayBundle(missingManifest: true);
    final ContentException error = await _rejection(bundle);

    expect(error.error.code, ContentErrorCode.missingAsset);
    expect(bundle.requestedPaths, <String>[salsaIntegrityManifestPath]);
  });

  test('missing course is reported as an unreadable asset', () async {
    final _AssetOverlayBundle bundle = _AssetOverlayBundle(missingCourse: true);
    final ContentException error = await _rejection(bundle);

    expect(error.error.code, ContentErrorCode.missingAsset);
    expect(bundle.requestedPaths, contains(salsaCourseAssetPath));
  });

  testWidgets('course entry blocks a modified package without retry or totals',
      (WidgetTester tester) async {
    await _pumpFailedCourse(
        tester, _AssetOverlayBundle(courseBytes: _sameLengthTamper()));
    expect(find.text('Retry'), findsNothing);
  });

  for (final missingManifest in <bool>[true, false]) {
    testWidgets(
        'missing ${missingManifest ? 'manifest' : 'course'} is a non-retryable installation failure in EN and TR',
        (WidgetTester tester) async {
      await _pumpFailedCourse(
          tester,
          _AssetOverlayBundle(
            missingManifest: missingManifest,
            missingCourse: !missingManifest,
          ));
      expect(find.textContaining('Update the app or contact support'),
          findsOneWidget);
      expect(find.textContaining('Do not delete the app'), findsOneWidget);
      expect(find.textContaining('reinstall'), findsNothing);
      expect(find.text('Retry'), findsNothing);

      await tester.tap(find.text('Türkçe'));
      await tester.pump();
      expect(find.textContaining('Uygulamayı güncelle'), findsOneWidget);
      expect(find.textContaining('Uygulamayı silme'), findsOneWidget);
      expect(find.textContaining('yeniden yükle'), findsNothing);
      expect(find.text('Tekrar dene'), findsNothing);
      expect(find.byKey(const Key('salsa.completedCount')), findsNothing);
    });
  }

  for (final timeout in <bool>[true, false]) {
    testWidgets(
        '${timeout ? 'timeout' : 'IO'} remains retryable without invented totals',
        (WidgetTester tester) async {
      await _pumpFailedCourse(
          tester,
          _AssetOverlayBundle(
            timeoutManifest: timeout,
            ioManifest: !timeout,
          ));
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Update the app'), findsNothing);
    });
  }
}
