import 'dart:async';

import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

import 'support/test_catalog.dart';

class _EmptyHistoryStore implements SessionStore {
  @override
  Future<void> append(SessionRecord record) async =>
      throw UnsupportedError('This history fixture is read-only.');

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => <SessionRecord>[];

  @override
  Future<int> unreadableRecords() async => 0;

  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;
}

void main() {
  late LibraryCatalog catalog;
  setUpAll(() async => catalog = await testLibrary());

  Future<void> mountShell(
    WidgetTester tester,
    Future<SessionStore> Function() openStore, {
    ValueNotifier<String?>? owner,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: ChoreiaShell(
        bundleOverride: () async => catalog,
        flagOverride: MemoryFirstRunFlag(seen: true),
        env: LiveEnvironment(storeOpener: openStore, accountUserId: owner),
      ),
    ));
    await tester.pump();
  }

  testWidgets('a late old-account read cannot cancel the current timeout',
      (WidgetTester tester) async {
    final owner =
        ValueNotifier<String?>('11111111-1111-4111-8111-111111111111');
    addTearDown(owner.dispose);
    final oldRead = Completer<SessionStore>();
    final currentRead = Completer<SessionStore>();
    var opens = 0;

    await mountShell(tester, () {
      opens++;
      if (opens == 1) return Future.value(_EmptyHistoryStore());
      if (opens == 2) return oldRead.future;
      return currentRead.future;
    }, owner: owner);
    expect(opens, 1);

    // Progress arrival starts account A's delayed refresh. Switching to B
    // starts its own hung read while that progress tab remains visible.
    await tester.tap(find.byKey(ChoreiaShell.progressTabKey));
    await tester.pump();
    expect(opens, 2);
    owner.value = '22222222-2222-4222-8222-222222222222';
    await tester.pump();
    expect(opens, 3);
    expect(find.byKey(ChoreiaShell.historyLoadingKey), findsOneWidget);

    // A completes after B owns the timer. A must neither publish its empty
    // history nor cancel the deadline that gives B an unavailable state.
    oldRead.complete(_EmptyHistoryStore());
    await tester.pump();
    expect(find.byKey(ChoreiaShell.historyLoadingKey), findsOneWidget);
    await tester.pump(historyReadTimeout + const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(ChoreiaShell.historyLoadingKey), findsNothing);
    expect(find.byType(ProgressView), findsOneWidget);
    expect(
        tester
            .widget<ProgressView>(find.byType(ProgressView))
            .summary
            .integrity
            .fidelity,
        HistoryFidelity.unavailable);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('one hanging history read still reaches its own timeout',
      (WidgetTester tester) async {
    final read = Completer<SessionStore>();
    await mountShell(tester, () => read.future);
    await tester.pump(historyReadTimeout + const Duration(milliseconds: 1));
    await tester.pump();

    final progress = find.byType(ProgressView, skipOffstage: false);
    expect(progress, findsOneWidget);
    expect(tester.widget<ProgressView>(progress).summary.integrity.fidelity,
        HistoryFidelity.unavailable);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing during a read cancels its timer and ignores late work',
      (WidgetTester tester) async {
    final read = Completer<SessionStore>();
    await mountShell(tester, () => read.future);
    await tester.pumpWidget(const SizedBox.shrink());
    read.complete(_EmptyHistoryStore());
    await tester.pump();
    await tester.pump(historyReadTimeout + const Duration(milliseconds: 1));

    expect(find.byType(ChoreiaShell), findsNothing);
    expect(tester.takeException(), isNull);
    // The widget-test binding also rejects a timer left pending at teardown.
  });
}
