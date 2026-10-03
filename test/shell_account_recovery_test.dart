import 'dart:async';

import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

import 'support/round_trip_store.dart';
import 'support/test_catalog.dart';

void main() {
  late LibraryCatalog catalog;
  setUpAll(() async => catalog = await testLibrary());
  Widget shell(
          ValueNotifier<bool> recovery, Future<SessionStore> Function() open) =>
      MaterialApp(
          home: ChoreiaShell(
              bundleOverride: () async => catalog,
              flagOverride: MemoryFirstRunFlag(seen: true),
              env: LiveEnvironment(
                  passwordRecovery: recovery, storeOpener: open)));

  testWidgets('recovery invalidates pending history and cancels its deadline',
      (tester) async {
    final recovery = ValueNotifier<bool>(false);
    final opening = Completer<SessionStore>();
    var opens = 0;
    addTearDown(recovery.dispose);
    await tester.pumpWidget(shell(recovery, () {
      opens++;
      return opening.future;
    }));
    await tester.pump();
    expect(opens, 1);
    recovery.value = true;
    recovery.value = false;
    opening.complete(RoundTripStore());
    await tester.pump();
    await tester.pump(historyReadTimeout + const Duration(milliseconds: 1));
    expect(find.byType(ProgressView, skipOffstage: false), findsNothing);
    expect(opens, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an initially recovering shell does not open history',
      (tester) async {
    final recovery = ValueNotifier<bool>(true);
    var opens = 0;
    addTearDown(recovery.dispose);
    await tester.pumpWidget(shell(recovery, () async {
      opens++;
      return RoundTripStore();
    }));
    await tester.pump();
    expect(opens, 0);
    recovery.value = false;
    await tester.pump();
    expect(opens, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
