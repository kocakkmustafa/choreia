import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SignedOutAccount implements MotionAccountClient {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authChanges => const Stream<AuthState>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('host profile opens Core sign-in and registration screens',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProfileView(
          accountPageBuilder: (_) => MotionAccountPage(
            account: _SignedOutAccount(),
            clearLocalData: clearLocalHistoryFor,
          ),
        ),
      ),
    ));
    expect(
        find.textContaining(
            'Explore five solo dance paths without an account or camera'),
        findsOneWidget);
    expect(
        find.textContaining('subscription sales are closed'), findsOneWidget);
    await tester.tap(find.byKey(ProfileView.accountEntryKey));
    await tester.pumpAndSettle();
    expect(find.byType(MotionAccountPage), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
  });

  for (final locale in ['en', 'tr']) {
    testWidgets(
        'profile keeps account reachable on a narrow large-text screen in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.localeTestValue = Locale(locale);
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
              body: ProfileView(
            accountPageBuilder: (_) =>
                const Scaffold(body: Text('Account route')),
          ))));
      expect(
          find.textContaining(locale == 'tr'
              ? 'Beş solo dans yolunu hesap veya kamera olmadan'
              : 'Explore five solo dance paths without an account or camera'),
          findsOneWidget);
      expect(
          find.textContaining(locale == 'tr'
              ? 'canlı kamera pratiği ve abonelik satışı kapalıdır'
              : 'Live camera practice and subscription sales are closed'),
          findsOneWidget);
      expect(find.textContaining('requires a Motion account'), findsNothing);
      expect(find.textContaining('üyeliği gerekir'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(ProfileView.accountEntryKey));
      await tester.tap(find.byKey(ProfileView.accountEntryKey));
      await tester.pumpAndSettle();
      expect(find.text('Account route'), findsOneWidget);
    });
  }
}
