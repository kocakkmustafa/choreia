import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Turkish device locale shows honest profile copy',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());

    await tester.pumpWidget(const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ProfileView()));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.textContaining('Hesap oluşturma ve üyelik erişimi bağlı değil'),
        findsOneWidget);
    expect(
        find.textContaining('kullanılabilir bir özellik yok'), findsOneWidget);
  });

  for (final language in <String>['en', 'tr']) {
    testWidgets(
        'failed catalogue survives account change and Retry in $language',
        (WidgetTester tester) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(language);
      addTearDown(
          () => tester.binding.platformDispatcher.clearLocaleTestValue());
      final owner = ValueNotifier<String?>(null);
      addTearDown(owner.dispose);

      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ChoreiaShell(
          bundleOverride: () async => throw StateError('catalogue unavailable'),
          flagOverride: MemoryFirstRunFlag(seen: true),
          env: LiveEnvironment(accountUserId: owner),
        ),
      ));
      Future<void> waitForFailure() async {
        for (var i = 0;
            i < 20 &&
                find.byKey(ChoreiaShell.loadFailureKey).evaluate().isEmpty;
            i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.byKey(ChoreiaShell.loadFailureKey), findsOneWidget);
      }

      await waitForFailure();

      if (language == 'tr') {
        expect(find.textContaining('uygulamayı güncelle veya desteğe ulaş'),
            findsOneWidget);
        expect(find.textContaining('Uygulamayı silme'), findsOneWidget);
        expect(find.textContaining('tekrar yükle'), findsNothing);
      } else {
        expect(find.textContaining('update the app or contact support'),
            findsOneWidget);
        expect(find.textContaining('Do not delete the app'), findsOneWidget);
        expect(find.textContaining('reinstall'), findsNothing);
      }
      owner.value = '11111111-1111-4111-8111-111111111111';
      await tester.pump();
      await waitForFailure();
      expect(tester.takeException(), isNull);
      await tester
          .tap(find.text(language == 'tr' ? 'Tekrar dene' : 'Try again'));
      await tester.pump();
      await waitForFailure();
      expect(tester.takeException(), isNull);
    });
  }
}
