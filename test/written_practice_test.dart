import 'dart:async';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/course/written_unit_practice.dart';
import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart' show SessionStoreRetiredException;

import 'support/test_catalog.dart';

void main() {
  const alice = '11111111-1111-4111-8111-111111111111';
  const bob = '22222222-2222-4222-8222-222222222222';
  late Directory dir;
  late AppStoreOwnerRegistry owners;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('choreia-written-study-');
    owners = AppStoreOwnerRegistry();
  });
  tearDown(() => dir.deleteSync(recursive: true));
  Future<SalsaProgressStore> open([String? user]) => SalsaProgressStore.open(
      accountUserId: user,
      supportDirectory: dir,
      owners: owners,
      writtenStudy: true);

  test('all five written course identities survive close/reopen and repeat',
      () async {
    final store = await open();
    for (final entry in writtenStudyCourses.entries) {
      await store.recordWrittenStudy(
          courseId: entry.key,
          version: entry.value.version,
          lessonId: '${entry.value.prefix}01');
    }
    await store.recordWrittenStudy(
        courseId: 'line_dance_beginner_written', version: 2, lessonId: 'ld_01');
    final reloaded = await (await open()).read();
    expect(reloaded.events, hasLength(6));
    expect(reloaded.events.every((e) => e.kind == SalsaEvidence.practised),
        isTrue);
    expect(reloaded.events.where((e) => e.lessonId == 'ld_01'), hasLength(2));
    expect(File('${store.file.path}.tmp').existsSync(), isFalse);
    expect(
        File('${dir.path}/${SalsaProgressStore.fileNameFor(null)}')
            .existsSync(),
        isFalse,
        reason:
            'Existing Salsa file is untouched, including for an older-app rollback.');
  });
  test('parallel writers preserve every separate study attempt', () async {
    final handles = await Future.wait(List.generate(8, (_) => open(alice)));
    await Future.wait(handles.map((s) => s.recordWrittenStudy(
        courseId: 'line_dance_beginner_written',
        version: 2,
        lessonId: 'ld_01')));
    expect((await (await open(alice)).read()).events, hasLength(8));
  });
  test('guest and two account journals never merge', () async {
    await (await open(alice)).recordWrittenStudy(
        courseId: 'hip_hop_foundations_beginner',
        version: 1,
        lessonId: 'hhf_01');
    expect((await (await open()).read()).events, isEmpty);
    expect((await (await open(bob)).read()).events, isEmpty);
    expect((await (await open(alice)).read()).events, hasLength(1));
  });
  test('unknown unit, wrong version and wrong journal cannot record study',
      () async {
    final store = await open();
    await expectLater(
        store.recordWrittenStudy(
            courseId: 'line_dance_beginner_written',
            version: 2,
            lessonId: 'ld_99'),
        throwsArgumentError);
    await expectLater(
        store.recordWrittenStudy(
            courseId: 'line_dance_beginner_written',
            version: 1,
            lessonId: 'ld_01'),
        throwsArgumentError);
    final salsa =
        await SalsaProgressStore.open(supportDirectory: dir, owners: owners);
    await expectLater(
        salsa.recordWrittenStudy(
            courseId: 'line_dance_beginner_written',
            version: 2,
            lessonId: 'ld_01'),
        throwsArgumentError);
    expect(dir.listSync(), isEmpty);
  });
  test('unreadable study data is preserved, never reset by a save', () async {
    final store = await open();
    store.file.writeAsStringSync('{broken');
    await expectLater(store.read(), throwsFormatException);
    await expectLater(
        store.recordWrittenStudy(
            courseId: 'line_dance_beginner_written',
            version: 2,
            lessonId: 'ld_01'),
        throwsFormatException);
    expect(store.file.readAsStringSync(), '{broken');
  });
  test(
      'confirmed namespace deletion covers study; old handle cannot resurrect it',
      () async {
    final store = await open(alice);
    await store.recordWrittenStudy(
        courseId: 'line_dance_beginner_written', version: 2, lessonId: 'ld_01');
    expect(
        await localHistoryAccountIds(supportDirectory: dir), contains(alice));
    await clearLocalHistoryFor(alice, supportDirectory: dir, owners: owners);
    expect(store.file.existsSync(), isFalse);
    await expectLater(
        store.recordWrittenStudy(
            courseId: 'line_dance_beginner_written',
            version: 2,
            lessonId: 'ld_01'),
        throwsA(isA<SessionStoreRetiredException>()));
  });
  test('a late directory opener retains its retired owner ticket', () async {
    final gate = Completer<Directory>();
    final pending = SalsaProgressStore.open(
        accountUserId: alice,
        writtenStudy: true,
        owners: owners,
        directoryResolver: () => gate.future);
    final rejection =
        expectLater(pending, throwsA(isA<SessionStoreRetiredException>()));
    await owners.retireOwner(alice);
    gate.complete(dir);
    await rejection;
    expect(dir.listSync(), isEmpty);
  });

  Future<void> ioPump(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
      'explicit study action persists and account change retires the old panel',
      (tester) async {
    final account = ValueNotifier<String?>(alice);
    final env = LiveEnvironment(
        accountUserId: account,
        storeOwners: owners,
        historyDirectoryOverride: dir);
    Widget panel() => MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: WrittenUnitPractice(
          courseId: 'line_dance_beginner_written',
          version: 2,
          unitId: 'ld_01',
          bundle: DiskBundle(),
          env: env,
        ))));
    await tester.pumpWidget(panel());
    await ioPump(tester);
    expect(find.text('Your study entries: 0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('written.record.ld_01')));
    await ioPump(tester);
    expect(find.text('Your study entries: 1'), findsOneWidget);
    expect(
        (await tester.runAsync(
            () async => (await (await open(alice)).read()).events.length)),
        1);
    account.value = bob;
    await tester.pump();
    expect(find.text('Your study entries: 1'), findsNothing);
    expect(find.textContaining('Reopen the lesson'), findsOneWidget);
    expect(
        (await tester.runAsync(
            () async => (await (await open(bob)).read()).events.length)),
        0);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
  });

  testWidgets(
      'background cannot admit a study action; resume reloads; recovery retires',
      (tester) async {
    final recovery = ValueNotifier(false);
    final env = LiveEnvironment(
        passwordRecovery: recovery,
        storeOwners: owners,
        historyDirectoryOverride: dir);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WrittenUnitPractice(
                courseId: 'line_dance_beginner_written',
                version: 2,
                unitId: 'ld_01',
                bundle: DiskBundle(),
                env: env))));
    await ioPump(tester);
    final oldAction = tester
        .widget<OutlinedButton>(find.byKey(const Key('written.record.ld_01')))
        .onPressed!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(
        tester
            .widget<OutlinedButton>(
                find.byKey(const Key('written.record.ld_01')))
            .onPressed,
        isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() async {
      oldAction();
    });
    expect(dir.listSync(), isEmpty,
        reason: 'Even a callback retained before background cannot admit IO.');
    await tester.runAsync(() async => (await open()).recordWrittenStudy(
        courseId: 'line_dance_beginner_written',
        version: 2,
        lessonId: 'ld_01'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await ioPump(tester);
    expect(find.text('Your study entries: 1'), findsOneWidget);
    recovery.value = true;
    await tester.pump();
    expect(find.byKey(const Key('written.record.ld_01')), findsNothing);
    expect(find.textContaining('Reopen the lesson'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    recovery.dispose();
  });

  for (final entry in writtenStudyCourses.entries) {
    testWidgets(
        '${entry.key} exposes an owner-bound study panel and empty media seam',
        (tester) async {
      final env =
          LiveEnvironment(storeOwners: owners, historyDirectoryOverride: dir);
      final bundle = DiskBundle();
      final Widget page = switch (entry.key) {
        'hip_hop_foundations_beginner' =>
          HipHopCoursePage(bundle: bundle, env: env),
        'hip_hop_foundations_skill_course' =>
          HipHopCoursePage(skillCourse: true, bundle: bundle, env: env),
        'line_dance_beginner_written' =>
          LineDanceCoursePage(bundle: bundle, env: env),
        'latin_fusion_beginner_written' =>
          LatinFusionCoursePage(bundle: bundle, env: env),
        _ => ShortFormCoursePage(bundle: bundle, env: env),
      };
      await tester.pumpWidget(MaterialApp(home: page));
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final id = '${entry.value.prefix}01';
      final tile = find.byKey(ValueKey(id));
      await tester.scrollUntilVisible(tile, 400);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await ioPump(tester);
      expect(find.byKey(Key('written.record.$id')), findsOneWidget);
      final slot =
          tester.widget<LessonMediaSlot>(find.byType(LessonMediaSlot).first);
      expect(slot.lessonId, id);
      expect(slot.catalog.isEmpty, isTrue);
      expect(slot.testingPlayback, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
