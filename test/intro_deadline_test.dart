import 'dart:async';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';
import 'support/test_catalog.dart';

void main() {
  testWidgets(
      'unanswered intro read shows intro and a late answer cannot close it',
      (tester) async {
    final library = await testLibrary();
    final flag = _Flag();
    await tester.pumpWidget(MaterialApp(
        home: ChoreiaShell(
      flagOverride: flag,
      bundleOverride: () async => library,
      env: LiveEnvironment(storeOpener: () async => _EmptyStore()),
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(FirstRunView), findsOneWidget);
    flag.read.complete(true);
    await tester.pump();
    expect(find.byType(FirstRunView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unanswered marker write does not block continuing to the library',
      (tester) async {
    final library = await testLibrary();
    final flag = _Flag()..read.complete(false);
    await tester.pumpWidget(MaterialApp(
        home: ChoreiaShell(
      flagOverride: flag,
      bundleOverride: () async => library,
      env: LiveEnvironment(storeOpener: () async => _EmptyStore()),
    )));
    await tester.pump();
    await tester.tap(find.byKey(FirstRunView.continueKey));
    await tester.pump();
    expect(find.byType(LibraryView), findsOneWidget);
    expect(flag.writes, 1);
    expect(tester.takeException(), isNull);
  });
}

class _Flag implements FirstRunFlag {
  final read = Completer<bool>();
  final write = Completer<void>();
  int writes = 0;
  @override
  Future<bool> hasSeenIntro() => read.future;
  @override
  Future<void> markSeen() {
    writes++;
    return write.future;
  }
}

class _EmptyStore implements SessionStore {
  @override
  Future<List<SessionRecord>> recent({int? limit}) async => [];
  @override
  Future<int> unreadableRecords() async => 0;
  @override
  Future<void> append(SessionRecord record) async {}
  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
}
