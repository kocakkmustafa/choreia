import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:flutter/material.dart';
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
    expect(find.textContaining('Browse dance styles without an account'),
        findsOneWidget);
    expect(find.textContaining('requires a Motion account'), findsOneWidget);
    await tester.tap(find.byKey(ProfileView.accountEntryKey));
    await tester.pumpAndSettle();
    expect(find.byType(MotionAccountPage), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsWidgets);
  });
}
