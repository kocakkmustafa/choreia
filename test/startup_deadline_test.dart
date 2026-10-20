import 'dart:async';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';

void main() {
  testWidgets('unresolved account startup paints a frame then fails closed',
      (tester) async {
    final pending = Completer<MotionAccountRuntime>();
    final launch = launchChoreia(
        initialize: () => pending.future,
        startupTimeout: const Duration(seconds: 20));
    await tester.pump();
    expect(
        find.byKey(const Key('choreia.accountStartupWaiting')), findsOneWidget);
    expect(find.byType(ChoreiaApp), findsNothing);

    await tester.pump(const Duration(seconds: 20));
    await launch;
    await tester.pump();
    expect(
        find.byKey(const Key('choreia.accountStartupFailure')), findsOneWidget);
    expect(find.byType(ChoreiaApp), findsNothing);

    pending.completeError(StateError('late initialization failure'));
    await tester.pump();
    expect(
        find.byKey(const Key('choreia.accountStartupFailure')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
