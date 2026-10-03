import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/course/salsa_course_repository.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_content/motion_content.dart';

import 'support/salsa_criterion_fixture.dart';
import 'support/test_catalog.dart';

/// In-memory version-two fixture; it never edits the shipped course or pins.
final class _VersionTwoBundle extends DeviceBundle {
  _VersionTwoBundle() : super(declaredReferences()) {
    _course =
        Uint8List.fromList(utf8.encode(jsonEncode(criterionCourseJson())));
    final manifest =
        jsonDecode(File(salsaIntegrityManifestPath).readAsStringSync())
            as Map<String, dynamic>;
    final asset = (manifest['assets'] as List).single as Map<String, dynamic>;
    asset['byteLength'] = _course.length;
    asset['sha256'] = computeSha256Hex(_course);
    manifest['contentVersion'] = '2.0.0';
    manifest['catalogDigest'] = computeCatalogDigest(manifest);
    _manifest = Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
  }
  late final Uint8List _course, _manifest;
  @override
  Future<ByteData> load(String key) {
    if (key == salsaCourseAssetPath) {
      return Future.value(ByteData.sublistView(_course));
    }
    if (key == salsaIntegrityManifestPath) {
      return Future.value(ByteData.sublistView(_manifest));
    }
    return super.load(key);
  }
}

void main() {
  late Directory temp;
  late ValueNotifier<String?> owner;
  late SalsaProgressStore store;
  late SalsaCourse course;
  setUp(() async {
    temp = Directory.systemTemp.createTempSync('criterion-ui-');
    owner = ValueNotifier(null);
    store = await SalsaProgressStore.open(supportDirectory: temp);
    course = criterionCourse();
  });
  tearDown(() {
    owner.dispose();
    temp.deleteSync(recursive: true);
  });

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<SalsaProgress> readSettled(WidgetTester tester) async {
    SalsaProgress? result;
    Object? failure;
    StackTrace? failureStack;
    var settled = false;
    // A read may queue behind the lesson's viewed/practice write in FakeAsync.
    // Observe that future in the same zone and pump it between real IO delays.
    unawaited(store.read().then<void>((value) {
      result = value;
      settled = true;
    }, onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      settled = true;
    }));
    for (var i = 0; i < 80 && !settled; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(settled, isTrue, reason: 'The journal queue read must settle.');
    if (failure != null) {
      Error.throwWithStackTrace(failure!, failureStack!);
    }
    return result!;
  }

  Future<void> pump(WidgetTester tester, String id, {bool tr = false}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = const Size(600, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = LiveEnvironment(
        bundle: DeviceBundle(declaredReferences()),
        accountUserId: owner,
        historyDirectoryOverride: temp,
        source: () =>
            throw StateError('Written practice must not start camera'));
    await tester.pumpWidget(MaterialApp(
        theme: ChoreiaTheme.dark,
        home: SalsaLessonPage(
            course: course,
            lesson: course.lesson(id),
            store: store,
            env: env,
            initialTurkish: tr)));
    await drain(tester);
    await readSettled(tester);
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 400));
    // Join actual viewed/practice IO before dispatching the next enabled action.
    await readSettled(tester);
    await tester.pump();
    final widget = tester.widget(finder);
    if (widget is FilledButton) {
      expect(widget.onPressed, isNotNull, reason: 'Requested action $key must be enabled before dispatch; save error=${find.byKey(const Key("salsa.saveError")).evaluate().isNotEmpty}');
    }
    await tester.tap(finder);
    await drain(tester);
    if (widget is CheckboxListTile) {
      expect(tester.widget<CheckboxListTile>(finder).value, !widget.value!,
          reason: 'Each dispatched self-check must toggle its actual selected value.');
    }
    if (key == const Key('salsa.complete')) {
      final progress = await readSettled(tester);
      expect(progress.lessonIds(course, SalsaEvidence.selfReportedComplete), isNotEmpty);
      await tester.pump();
    }
    if (key == const Key('salsa.savePractice')) {
      final progress = await readSettled(tester);
      expect(progress.lessonIds(course, SalsaEvidence.practised), isNotEmpty,
          reason: 'Enabled practice action must persist before checking completion.');
    }
  }

  for (final tr in [false, true]) {
    testWidgets(
        'spoken so16 has no physical checks or empty-list completion $tr',
        (tester) async {
      await pump(tester, 'so_16', tr: tr);
      await tap(tester, const Key('salsa.option.rhythmOnly'));
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byKey(const Key('salsa.practiceOnly')), findsOneWidget);
      await tap(tester, const Key('salsa.savePractice'));
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('salsa.complete')))
              .onPressed,
          isNull);
      expect(find.byKey(const Key('salsa.next')), findsNothing);
      expect(find.text(tr ? 'Kursa dön' : 'Back to course'), findsOneWidget);
      final saved = await readSettled(tester);
      expect(saved.lessonIds(course, SalsaEvidence.practised), {'so_16'});
      expect(
          saved.lessonIds(course, SalsaEvidence.selfReportedComplete), isEmpty);
      owner.value = '11111111-1111-4111-8111-111111111111';
      await tester.pump();
      expect(find.byKey(const Key('salsa.accountChanged')), findsOneWidget);
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('salsa.savePractice')))
              .onPressed,
          isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'standard rhythm adapted switches reset selected checks and practice',
      (tester) async {
    await pump(tester, 'so_16');
    await tap(tester, const Key('salsa.preparation.acknowledge'));
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    await tap(tester, const Key('salsa.savePractice'));
    for (var i = 0; i < 3; i++) {
      await tap(tester, Key('salsa.check.$i'));
    }
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('salsa.complete')))
            .onPressed,
        isNotNull);
    await tap(tester, const Key('salsa.option.rhythmOnly'));
    expect(find.byType(CheckboxListTile), findsNothing);
    await tap(tester, const Key('salsa.option.adapted'));
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    for (final tile
        in tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))) {
      expect(tile.value, isFalse);
    }
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('salsa.complete')))
            .onPressed,
        isNull);
    await tap(tester, const Key('salsa.savePractice'));
    for (var i = 0; i < 3; i++) {
      await tap(tester, Key('salsa.check.$i'));
    }
    await tap(tester, const Key('salsa.complete'));
    expect(find.byKey(const Key('salsa.next')), findsOneWidget);
    await tap(tester, const Key('salsa.next'));
    expect(
        find.byKey(const ValueKey('salsa.lessonBody.so_17')), findsOneWidget);
    expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('salsa.option.standard')))
            .selected,
        isTrue);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('salsa.complete')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final id in ['so_01', 'so_20']) {
    testWidgets('$id spoken conceptual or untried checks remain usable',
        (tester) async {
      await pump(tester, id);
      await tap(tester, const Key('salsa.option.rhythmOnly'));
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(find.byKey(const Key('salsa.practiceOnly')), findsNothing);
      await tap(tester, const Key('salsa.savePractice'));
      for (var i = 0; i < 3; i++) {
        await tap(tester, Key('salsa.check.$i'));
      }
      await tap(tester, const Key('salsa.complete'));
      final progress = await readSettled(tester);
      expect(progress.lessonIds(course, SalsaEvidence.selfReportedComplete),
          {id});
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('language toggle keeps selected indices and practice-only state',
      (tester) async {
    await pump(tester, 'so_16');
    await tap(tester, const Key('salsa.preparation.acknowledge'));
    await tap(tester, const Key('salsa.check.0'));
    await tester.tap(find.text('Türkçe'));
    await tester.pump();
    expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('salsa.check.0')))
            .value,
        isTrue);
    expect(find.text(course.lesson('so_16').selfCheck.tr[0]), findsOneWidget);
    await tap(tester, const Key('salsa.option.rhythmOnly'));
    await tester.tap(find.text('English'));
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(
        find.text(
            'This spoken option saves practice only. Physical self-checks remain untried and do not count as completion.'),
        findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('salsa.complete')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final retirement in ['background', 'account', 'dispose']) {
    testWidgets('pending completion cannot reopen progress after $retirement',
        (tester) async {
      await pump(tester, 'so_16');
      await tap(tester, const Key('salsa.preparation.acknowledge'));
      await tap(tester, const Key('salsa.savePractice'));
      for (var i = 0; i < 3; i++) {
        await tap(tester, Key('salsa.check.$i'));
      }
      // Do not drain real IO: the authorized old-owner write is still pending.
      final complete = find.byKey(const Key('salsa.complete'));
      await tester.ensureVisible(complete);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(complete);
      await tester.pump();
      expect(tester.widget<FilledButton>(complete).onPressed, isNull);
      expect(find.byKey(const Key('salsa.saved')), findsNothing);
      if (retirement == 'background') {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      } else if (retirement == 'account') {
        owner.value = '11111111-1111-4111-8111-111111111111';
      } else {
        await tester.pumpWidget(const SizedBox());
      }
      await drain(tester);
      // The journal may finish its begun write; its stale UI result is refused.
      final saved = await readSettled(tester);
      await tester.pump();
      expect(saved.lessonIds(course, SalsaEvidence.selfReportedComplete),
          {'so_16'});
      expect(find.byKey(const Key('salsa.saved')), findsNothing);
      expect(find.byKey(const Key('salsa.next')), findsNothing);
      if (retirement == 'background') {
        expect(find.byKey(const Key('salsa.preparation.required')),
            findsOneWidget);
      }
      if (retirement == 'account') {
        expect(find.byKey(const Key('salsa.accountChanged')), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'version two overview discloses retained old records and resets current totals',
      (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    final old = SalsaCourse.fromJson(
        jsonDecode(File(salsaCourseAssetPath).readAsStringSync())
            as Map<String, dynamic>);
    final now = DateTime(2026, 10, 2, 12);
    await tester.runAsync(() async {
      for (final kind in SalsaEvidence.values) {
        await store.record(old, old.lesson('so_01'), kind, at: now);
      }
    });
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: ChoreiaTheme.dark,
        home: SalsaCoursePage(
            env: LiveEnvironment(
                bundle: _VersionTwoBundle(),
                accountUserId: owner,
                historyDirectoryOverride: temp),
            nowForWeeklyPractice: () => now)));
    await drain(tester);
    expect(find.text('0 / 48 self-reported complete'), findsOneWidget);
    expect(find.text('0 opened · 0 practised lessons'), findsOneWidget);
    expect(find.text('Saved attempts: 0 · Lessons with attempts: 0'),
        findsNWidgets(4));
    await tester.scrollUntilVisible(find.text('Practice history'), 600,
        scrollable: find.byType(Scrollable).first, maxScrolls: 100);
    await tester.tap(find.text('Practice history'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
        find.text(
            '3 records from other content versions are retained and excluded from this version’s totals.'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 10);
    expect(
        find.text(
            '3 records from other content versions are retained and excluded from this version’s totals.'),
        findsOneWidget);
    expect(find.text('No practice saved for this version.'), findsOneWidget);
    final retained = await readSettled(tester);
    expect(retained.events, hasLength(3));
    expect(retained.forCourse(course), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
