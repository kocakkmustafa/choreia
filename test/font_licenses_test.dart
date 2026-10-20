import 'dart:io';

import 'package:choreia/app/font_licenses.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notices = <String, String>{
    'Instrument Serif': 'assets/fonts/OFL-InstrumentSerif.txt',
    'IBM Plex Mono': 'assets/fonts/OFL-IBMPlexMono.txt',
    'Manrope': 'assets/fonts/OFL-Manrope.txt',
  };
  setUpAll(() async {
    for (final path in notices.values) {
      await rootBundle.loadString(path);
    }
  });
  setUp(() {
    LicenseRegistry.reset();
    registerBundledFontLicenses();
  });
  tearDown(LicenseRegistry.reset);

  test('all three complete notices resolve from the declared asset bundle',
      () async {
    final entries = await LicenseRegistry.licenses.toList();
    expect(entries.length, notices.length);
    for (final entry in entries.cast<LicenseEntryWithLineBreaks>()) {
      final family = entry.packages.single;
      final original = File(notices[family]!).readAsBytesSync();
      expect(entry.text, File(notices[family]!).readAsStringSync());
      expect(
          sha256.convert(original).toString(),
          switch (family) {
            'Instrument Serif' =>
              '129ed7618959716959f2941fdd5b49e0ad6e6c1d78726761786a00253d865521',
            'IBM Plex Mono' =>
              '7e6b2818edbd8f6a01ae80641cc8f16a51080d08fb4e532be3a0b6f74adb07da',
            'Manrope' =>
              'e01b637272e0cbdfb240184dd98ea5cc671556d9894dae2668d92ab2c906787c',
            _ => throw StateError('Unexpected bundled font'),
          });
      expect(entry.text, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(entry.text, contains('TERMINATION'));
      expect(entry.text, contains('DISCLAIMER'));
    }
  });

  for (final language in <String>['en', 'tr']) {
    for (final configured in <bool>[false, true]) {
      testWidgets(
          'Profile exposes font notices in $language (account entry $configured)',
          (tester) async {
        tester.binding.platformDispatcher.localeTestValue = Locale(language);
        addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
            locale: Locale(language),
            supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: ProfileView(
          accountPageBuilder: configured ? (_) => const SizedBox() : null,
        )));
        expect(find.text(language == 'tr' ? 'Lisanslar' : 'Licenses'),
            findsOneWidget);
        await tester.runAsync(() async {
          final registered = await LicenseRegistry.licenses.toList();
          expect(registered.length, notices.length);
          await tester.tap(find.byKey(ProfileView.licensesEntryKey));
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            if (notices.keys
                .every((family) => find.text(family).evaluate().isNotEmpty)) {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        expect(find.byType(LicensePage), findsOneWidget);

        for (final family in notices.keys) {
          expect(find.text(family), findsOneWidget);
        }
        await tester.runAsync(() async {
          await tester.tap(find.text('IBM Plex Mono'));
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            if (find
                .textContaining('Reserved Font Name "Plex"')
                .evaluate()
                .isNotEmpty) {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        expect(
            find.textContaining('Reserved Font Name "Plex"'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
