import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

class _UnavailableBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('invalid manifest')));

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      throw FlutterError('Missing $key');
}

void main() {
  final unavailable = _UnavailableBundle();
  final pages = <String, Widget Function(Directory)>{
    'hiphop introduction': (_) => HipHopCoursePage(bundle: unavailable),
    'hiphop skill': (_) =>
        HipHopCoursePage(bundle: unavailable, skillCourse: true),
    'line': (_) => LineDanceCoursePage(bundle: unavailable),
    'latin': (_) => LatinFusionCoursePage(bundle: unavailable),
    'shortform': (_) => ShortFormCoursePage(bundle: unavailable),
    'salsa integrity': (directory) => SalsaCoursePage(
        env: LiveEnvironment(
            bundle: unavailable, historyDirectoryOverride: directory)),
    'salsa progress': (directory) => SalsaCoursePage(
        env: LiveEnvironment(
            bundle: DeviceBundle(declaredReferences()),
            historyDirectoryOverride: directory)),
  };

  for (final language in ['en', 'tr']) {
    for (final size in [const Size(320, 568), const Size(640, 320)]) {
      for (final entry in pages.entries) {
        testWidgets(
            '${entry.key} error remains readable and escapable: $language $size 2x',
            (tester) async {
          final directory = Directory.systemTemp.createTempSync('choreia-error-');
          addTearDown(() => directory.deleteSync(recursive: true));
          // Corrupt progress produces the recoverable read error; preserve it.
          final progress = File('${directory.path}/course-choreia-guest.json')
            ..writeAsStringSync('corrupt');
          final page = entry.value(directory);
          tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          tester.platformDispatcher.localeTestValue = Locale(language);
          addTearDown(tester.platformDispatcher.clearLocaleTestValue);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(
              locale: Locale(language),
              supportedLocales: const [Locale('en'), Locale('tr')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ChoreiaTheme.dark,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!),
              home: Builder(builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(builder: (_) => page)),
                      child: const Text('Open'))))));
          await tester.tap(find.text('Open'));
          for (var i = 0; i < 100; i++) {
            await tester.runAsync(() =>
                Future<void>.delayed(const Duration(milliseconds: 10)));
            await tester.pump(const Duration(milliseconds: 50));
            if (find.text(language == 'tr' ? 'Tekrar dene' : 'Retry').evaluate().isNotEmpty ||
                find.byKey(const Key('salsa.loadError')).evaluate().isNotEmpty) {
              break;
            }
          }
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          final retry = find.text(language == 'tr' ? 'Tekrar dene' : 'Retry');
          if (entry.key == 'salsa integrity') {
            expect(retry, findsNothing);
            // The final preservation instruction must be reachable by scrolling.
            final message = find.byKey(const Key('salsa.loadError'));
            expect(message, findsOneWidget);
            final scrollable = find.byType(Scrollable);
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.last, const Offset(0, -1200));
            }
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.getBottomRight(message).dy,
                lessThanOrEqualTo(size.height));
          } else {
            expect(retry, findsOneWidget);
            await tester.ensureVisible(retry);
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.getCenter(retry).dy, lessThan(size.height));
          }
          expect(progress.readAsStringSync(), 'corrupt');
          await tester.tap(find.byType(BackButton));
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Open'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
