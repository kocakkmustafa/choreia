import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course/media/choreia_source_projection_adapter.dart';
import 'package:choreia/app/course/media/choreia_source_projection_pin.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

final class _PendingRead {
  final gate = Completer<void>();
  bool finished = false;
}

/// Exact packaged bytes, with positive read/completion witnesses. No native
/// player, network, billing, or camera fake is used for a source observation.
final class _SourceBundle extends DeviceBundle {
  _SourceBundle({this.heldPath, this.changedPath, this.missingPath})
      : super(declaredReferences()) {
    addTearDown(() {
      for (final read in pending) {
        if (!read.gate.isCompleted) read.gate.complete();
      }
    });
  }

  final String? heldPath, changedPath, missingPath;
  final reads = <String>[];
  final pending = <_PendingRead>[];
  int mediaReads = 0;
  int get projectionReads => reads
      .where((path) => path == ChoreiaSourceProjectionPin.projectionPath)
      .length;

  @override
  Future<ByteData> load(String key) async {
    reads.add(key);
    if (key.startsWith('content/media/')) {
      mediaReads++;
      throw FlutterError('Source identity cannot read release media.');
    }
    if (key == missingPath) throw FlutterError('Missing source fixture.');
    final data = await super.load(key);
    if (key == heldPath) {
      final read = _PendingRead();
      pending.add(read);
      await read.gate.future;
      read.finished = true;
    }
    if (key == changedPath) {
      final bytes = Uint8List.fromList(Uint8List.sublistView(data));
      bytes[0] ^= 1;
      return ByteData.sublistView(bytes);
    }
    return data;
  }

  void release(int index) => pending[index].gate.complete();
}

void _expectNoAuthority(ChoreiaSourceProjectionResult result) {
  expect(result.mediaAvailable, isFalse);
  expect(result.releaseEligible, isFalse);
  expect(result.paidAccess, isFalse);
  expect(result.progressEffect, 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('public Core decoder reads real raw v1 source pins as NO_MEDIA',
      () async {
    final bundle = _SourceBundle();
    final result = await ChoreiaSourceProjectionAdapter.load(bundle: bundle);
    expect(result, isA<ChoreiaSourceVerifiedNoMedia>());
    final verified = result as ChoreiaSourceVerifiedNoMedia;
    expect(verified.source.appId, ChoreiaSourceProjectionPin.appId);
    expect(verified.source.variants, hasLength(872));
    expect(verified.source.held, isEmpty);
    expect(bundle.projectionReads, 1);
    expect(bundle.mediaReads, 0);
    _expectNoAuthority(result);
  });

  for (final path in <String>[
    ChoreiaSourceProjectionPin.coursePath,
    ChoreiaSourceProjectionPin.slicePath,
    ChoreiaSourceProjectionPin.projectionPath,
  ]) {
    test('changed packaged $path is typed unavailable NO_MEDIA', () async {
      final bundle = _SourceBundle(changedPath: path);
      final result = await ChoreiaSourceProjectionAdapter.load(bundle: bundle);
      expect(result, isA<ChoreiaSourceUnavailableNoMedia>());
      expect(bundle.mediaReads, 0);
      _expectNoAuthority(result);
    });
    test('missing packaged $path is typed unavailable NO_MEDIA', () async {
      final result = await ChoreiaSourceProjectionAdapter.load(
          bundle: _SourceBundle(missingPath: path));
      expect(result, isA<ChoreiaSourceUnavailableNoMedia>());
      _expectNoAuthority(result);
    });
  }

  group('shipping route projection lifetime', () {
    const alice = '11111111-1111-4111-8111-111111111111';
    const bob = '22222222-2222-4222-8222-222222222222';
    late Directory temp;
    late ValueNotifier<String?> owner;
    late ValueNotifier<bool> recovery;
    late ValueNotifier<int> ownerEpoch;
    late SalsaCourse course;
    late AppStoreOwnerRegistry storeOwners;
    SalsaProgressStore? store;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('choreia-source-adoption-');
      owner = ValueNotifier<String?>(alice);
      recovery = ValueNotifier<bool>(false);
      ownerEpoch = ValueNotifier<int>(0);
      course = SalsaCourse.fromJson(jsonDecode(
              File(ChoreiaSourceProjectionPin.coursePath).readAsStringSync())
          as Map<String, dynamic>);
      storeOwners = AppStoreOwnerRegistry();
      store = null;
    });

    tearDown(() {
      owner.dispose();
      recovery.dispose();
      ownerEpoch.dispose();
      temp.deleteSync(recursive: true);
    });

    LiveEnvironment environment(AssetBundle bundle,
            {ValueNotifier<String?>? account,
            ValueNotifier<bool>? recoverySignal,
            ValueNotifier<int>? epochSignal}) =>
        LiveEnvironment(
          bundle: bundle,
          accountUserId: account ?? owner,
          passwordRecovery: recoverySignal ?? recovery,
          ownerEpoch: epochSignal ?? ownerEpoch,
          historyDirectoryOverride: temp,
          storeOwners: storeOwners,
          source: () => throw StateError('Teaching cannot request a camera.'),
        );

    Future<void> waitFor(WidgetTester tester, bool Function() condition) async {
      for (var i = 0; i < 80 && !condition(); i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(condition(), isTrue, reason: 'The positive witness must settle.');
    }

    Future<void> mount(WidgetTester tester, Widget home) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.binding.platformDispatcher.localesTestValue = const [Locale('en')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester
          .pumpWidget(MaterialApp(theme: ChoreiaTheme.dark, home: home));
      await tester.pump();
    }

    Future<void> lesson(WidgetTester tester, LiveEnvironment env,
        ChoreiaSourceProjectionObserver? observer) async {
      store ??= await tester.runAsync(() => SalsaProgressStore.open(
          accountUserId: alice, supportDirectory: temp, owners: storeOwners));
      await mount(
          tester,
          SalsaLessonPage(
            key: const Key('stable.lesson'),
            course: course,
            lesson: course.lessons.first,
            store: store!,
            env: env,
            initialTurkish: false,
            onSourceProjectionReadback: observer,
          ));
    }

    Future<void> replaceLesson(WidgetTester tester, LiveEnvironment env,
        ChoreiaSourceProjectionObserver? observer) async {
      await tester.pumpWidget(MaterialApp(
          theme: ChoreiaTheme.dark,
          home: SalsaLessonPage(
            key: const Key('stable.lesson'),
            course: course,
            lesson: course.lessons.first,
            store: store!,
            env: env,
            initialTurkish: false,
            onSourceProjectionReadback: observer,
          )));
      await tester.pump();
    }

    ChoreiaSourceProjectionResult readback(WidgetTester tester) {
      final dynamic state = tester.state(find.byType(SalsaLessonPage));
      return state.sourceProjectionReadback as ChoreiaSourceProjectionResult;
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      if (store != null) {
        // A read queued behind a write admitted in FakeAsync must be pumped
        // in that same zone. Awaiting it inside runAsync would strand the write.
        var settled = false;
        Object? readError;
        unawaited(store!.read().then<void>((_) {
          settled = true;
        }, onError: (Object error, StackTrace _) {
          readError = error;
          settled = true;
        }));
        await waitFor(tester, () => settled);
        expect(readError, isNull,
            reason: 'The owner journal queue must drain.');
      }
      expect(tester.takeException(), isNull);
    }

    testWidgets('Entry to Course to Lesson reads projection exactly once',
        (tester) async {
      final bundle = _SourceBundle();
      final seen = <ChoreiaSourceProjectionResult>[];
      await mount(
          tester,
          Scaffold(
              body: SalsaCourseEntry(
                  env: environment(bundle),
                  onSourceProjectionReadback: seen.add)));
      await tester.tap(find.byKey(const Key('salsa.open')));
      await waitFor(tester,
          () => find.byKey(const Key('salsa.continue')).evaluate().isNotEmpty);
      expect(bundle.projectionReads, 0);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.tap(find.byKey(const Key('salsa.continue')));
      await waitFor(tester, () => seen.isNotEmpty);
      // The callback may complete during the route's offstage entrance. Wait
      // for the actual visible teaching route as a separate positive witness.
      await tester.pump(const Duration(milliseconds: 450));
      await waitFor(
          tester, () => find.byType(SalsaLessonPage).evaluate().isNotEmpty);
      expect(find.byType(SalsaLessonPage), findsOneWidget);
      expect(seen, hasLength(1));
      expect(seen.single, isA<ChoreiaSourceVerifiedNoMedia>());
      expect(bundle.projectionReads, 1);
      _expectNoAuthority(seen.single);

      final slotFinder = find.byKey(const ValueKey('salsa.mediaSlot.so_01'));
      final slot = tester.widget<LessonMediaSlot>(slotFinder);
      expect(slot.catalog.isEmpty, isTrue);
      expect(slot.sceneId, isNull);
      expect(slot.variantStem, isNull);
      expect(tester.getSize(slotFinder).height, 0);
      expect(bundle.mediaReads, 0);
      final file =
          File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}');
      await waitFor(tester, file.existsSync);
      final before = file.readAsBytesSync();
      final raw = jsonDecode(utf8.decode(before)) as Map<String, dynamic>;
      expect((raw['events'] as List<dynamic>).map((dynamic row) => row['kind']),
          [SalsaEvidence.viewed.name]);
      await tester.tap(find.text('Türkçe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(bundle.projectionReads, 1);
      expect(seen, hasLength(1));
      expect(file.readAsBytesSync(), before);
      expect(bundle.mediaReads, 0);
      await unmount(tester);
    });

    testWidgets('Next lesson refuses the previous internal lesson epoch',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, environment(bundle), seen.add);
      await waitFor(tester, () => bundle.pending.length == 1);

      Future<void> tap(Key key) async {
        final finder = find.byKey(key);
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(finder, 300,
              scrollable: find.byType(Scrollable).first);
        } else {
          await tester.ensureVisible(finder);
        }
        await tester.pump(const Duration(milliseconds: 400));
        await waitFor(tester, () {
          final action = tester.widget(finder);
          if (action is FilledButton) return action.onPressed != null;
          if (action is TextButton) return action.onPressed != null;
          if (action is CheckboxListTile) return action.onChanged != null;
          return true;
        });
        await tester.tap(finder);
        await tester.pump();
      }

      await tap(const Key('salsa.savePractice'));
      await waitFor(
          tester,
          () => find
              .text('Practice saved · save another attempt')
              .evaluate()
              .isNotEmpty);
      final checks = course.lessons.first
          .selfChecksFor(SalsaPracticeOption.standard)
          .indices;
      for (var i = 0; i < checks.length; i++) {
        await tap(Key('salsa.check.$i'));
      }
      await tap(const Key('salsa.complete'));
      await waitFor(tester,
          () => find.byKey(const Key('salsa.saved')).evaluate().isNotEmpty);
      await tap(const Key('salsa.next'));
      await waitFor(tester, () => bundle.pending.length == 2);
      expect(
          find.byKey(const ValueKey('salsa.lessonBody.so_02')), findsOneWidget);
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      bundle.release(1);
      await waitFor(tester, () => seen.length == 1);
      expect(seen.single, isA<ChoreiaSourceVerifiedNoMedia>());
      _expectNoAuthority(seen.single);
      await unmount(tester);
    });

    testWidgets('initial lesson recovery admits no source or viewed write',
        (tester) async {
      final bundle = _SourceBundle();
      final seen = <ChoreiaSourceProjectionResult>[];
      recovery.value = true;
      await lesson(tester, environment(bundle), seen.add);
      await tester.pump();
      expect(bundle.reads, isEmpty);
      expect(seen, isEmpty);
      expect(temp.listSync(), isEmpty);
      expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
      recovery.value = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(bundle.reads, isEmpty);
      expect(temp.listSync(), isEmpty);
      await unmount(tester);
    });

    testWidgets('owner A to B to A retires a pending source observation',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, environment(bundle), seen.add);
      await waitFor(tester, () => bundle.pending.length == 1);
      owner.value = bob;
      owner.value = alice;
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
      expect(bundle.projectionReads, 1);
      await unmount(tester);
    });

    testWidgets('bundle replacement refuses old bytes before new completion',
        (tester) async {
      final oldBundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final newBundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      final observer = seen.add;
      await lesson(tester, environment(oldBundle), observer);
      await waitFor(tester, () => oldBundle.pending.length == 1);
      await replaceLesson(tester, environment(newBundle), observer);
      await waitFor(tester, () => newBundle.pending.length == 1);
      oldBundle.release(0);
      await waitFor(tester, () => oldBundle.pending[0].finished);
      expect(seen, isEmpty);
      newBundle.release(0);
      await waitFor(tester, () => seen.length == 1);
      expect(seen.single, isA<ChoreiaSourceVerifiedNoMedia>());
      expect(oldBundle.projectionReads, 1);
      expect(newBundle.projectionReads, 1);
      await unmount(tester);
    });

    testWidgets('observer replacement cannot receive a predecessor result',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final env = environment(bundle);
      final oldSeen = <ChoreiaSourceProjectionResult>[];
      final newSeen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, env, oldSeen.add);
      await waitFor(tester, () => bundle.pending.length == 1);
      await replaceLesson(tester, env, newSeen.add);
      await waitFor(tester, () => bundle.pending.length == 2);
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(oldSeen, isEmpty);
      expect(newSeen, isEmpty);
      bundle.release(1);
      await waitFor(tester, () => newSeen.length == 1);
      expect(oldSeen, isEmpty);
      expect(newSeen.single, isA<ChoreiaSourceVerifiedNoMedia>());
      await unmount(tester);
    });

    testWidgets('owner listenable replacement with the same id retires lease',
        (tester) async {
      final replacement = ValueNotifier<String?>(alice);
      addTearDown(replacement.dispose);
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      final observer = seen.add;
      await lesson(tester, environment(bundle), observer);
      await waitFor(tester, () => bundle.pending.length == 1);
      await replaceLesson(
          tester, environment(bundle, account: replacement), observer);
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
      expect(bundle.projectionReads, 1);
      await unmount(tester);
      replacement.value = bob;
      owner.value = bob;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('background and resume refuses old completion in new epoch',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, environment(bundle), seen.add);
      await waitFor(tester, () => bundle.pending.length == 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await waitFor(tester, () => bundle.pending.length == 2);
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      bundle.release(1);
      await waitFor(tester, () => seen.length == 1);
      expect(seen.single, isA<ChoreiaSourceVerifiedNoMedia>());
      await unmount(tester);
    });

    testWidgets('dispose drains delayed bytes without delivering source',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, environment(bundle), seen.add);
      await waitFor(tester, () => bundle.pending.length == 1);
      await unmount(tester);
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      owner.value = bob;
      recovery.value = true;
      await tester.pump();
      expect(seen, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'recovery true then false synchronously retires lesson lifetime',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, environment(bundle), seen.add);
      await waitFor(tester, () => bundle.pending.length == 1);
      final file =
          File('${temp.path}/${SalsaProgressStore.fileNameFor(alice)}');
      await waitFor(tester, file.existsSync);
      final before = file.readAsBytesSync();
      recovery.value = true;
      // No pump: the old callback must lose admission in the same stack.
      recovery.value = false;
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(bundle.projectionReads, 1);
      expect(file.readAsBytesSync(), before);
      await unmount(tester);
    });

    testWidgets('recovery replacement detaches old signal and captures new one',
        (tester) async {
      final replacement = ValueNotifier<bool>(false);
      addTearDown(replacement.dispose);
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      final observer = seen.add;
      await lesson(tester, environment(bundle), observer);
      await waitFor(tester, () => bundle.pending.length == 1);
      await replaceLesson(
          tester, environment(bundle, recoverySignal: replacement), observer);
      await waitFor(tester, () => bundle.pending.length == 2);
      recovery.value = true;
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      bundle.release(1);
      await waitFor(tester, () => seen.length == 1);
      expect(readback(tester), isA<ChoreiaSourceVerifiedNoMedia>());
      replacement.value = true;
      expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
      await unmount(tester);
    });

    for (final asynchronous in <bool>[false, true]) {
      testWidgets(
          '${asynchronous ? 'async' : 'sync'} observer throw is typed NO_MEDIA',
          (tester) async {
        final bundle = _SourceBundle();
        var calls = 0;
        FutureOr<void> observer(ChoreiaSourceProjectionResult result) {
          calls++;
          _expectNoAuthority(result);
          if (asynchronous) {
            return Future<void>.error(StateError('observer failed'));
          }
          throw StateError('observer failed');
        }

        await lesson(tester, environment(bundle), observer);
        await waitFor(tester, () => calls == 1);
        await tester.pump();
        expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
        expect(calls, 1);
        expect(bundle.projectionReads, 1);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }

    testWidgets('old async observer error cannot poison a replacement result',
        (tester) async {
      final bundle = _SourceBundle();
      final env = environment(bundle);
      final gate = Completer<void>();
      var oldCalls = 0;
      Future<void> oldObserver(ChoreiaSourceProjectionResult _) {
        oldCalls++;
        return gate.future;
      }

      final newSeen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, env, oldObserver);
      await waitFor(tester, () => oldCalls == 1);
      await replaceLesson(tester, env, newSeen.add);
      await waitFor(tester, () => newSeen.length == 1);
      gate.completeError(StateError('retired observer failed'));
      await tester.pump();
      expect(readback(tester), isA<ChoreiaSourceVerifiedNoMedia>());
      expect(newSeen, hasLength(1));
      expect(oldCalls, 1);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('Entry refuses recovery admission before another frame',
        (tester) async {
      final bundle = _SourceBundle();
      await mount(
          tester, Scaffold(body: SalsaCourseEntry(env: environment(bundle))));
      final action = tester
          .widget<FilledButton>(find.byKey(const Key('salsa.open')))
          .onPressed!;
      recovery.value = true;
      action();
      await tester.pump();
      expect(find.byType(SalsaCoursePage), findsNothing);
      expect(bundle.reads, isEmpty);
      await unmount(tester);
    });

    testWidgets('same UUID owner epoch retires pending lesson before a frame',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      await lesson(tester, environment(bundle), seen.add);
      await waitFor(tester, () => bundle.pending.length == 1);
      ownerEpoch.value++;
      expect(owner.value, alice);
      expect(readback(tester), isA<ChoreiaSourceUnavailableNoMedia>());
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(bundle.projectionReads, 1);
      await unmount(tester);
      ownerEpoch.value++;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('epoch notifier replacement retires even the same epoch value',
        (tester) async {
      final replacement = ValueNotifier<int>(0);
      addTearDown(replacement.dispose);
      final bundle =
          _SourceBundle(heldPath: ChoreiaSourceProjectionPin.projectionPath);
      final seen = <ChoreiaSourceProjectionResult>[];
      final observer = seen.add;
      await lesson(tester, environment(bundle), observer);
      await waitFor(tester, () => bundle.pending.length == 1);
      await replaceLesson(
          tester, environment(bundle, epochSignal: replacement), observer);
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(seen, isEmpty);
      expect(bundle.projectionReads, 1);
      await unmount(tester);
      replacement.value++;
      ownerEpoch.value++;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Entry stale action refuses a same UUID session epoch',
        (tester) async {
      final bundle = _SourceBundle();
      await mount(
          tester, Scaffold(body: SalsaCourseEntry(env: environment(bundle))));
      final action = tester
          .widget<FilledButton>(find.byKey(const Key('salsa.open')))
          .onPressed!;
      ownerEpoch.value++;
      action();
      await tester.pump();
      expect(owner.value, alice);
      expect(find.byType(SalsaCoursePage), findsNothing);
      expect(bundle.reads, isEmpty);
      await unmount(tester);
    });

    testWidgets(
        'Course same UUID epoch retires a delayed load before IO admission',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: 'content/motion_content/manifest.json');
      await mount(tester, SalsaCoursePage(env: environment(bundle)));
      await waitFor(tester, () => bundle.pending.length == 1);
      ownerEpoch.value++;
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(find.byKey(const Key('salsa.ownerEpochRetired')), findsOneWidget);
      expect(find.byKey(const Key('salsa.continue')), findsNothing);
      expect(temp.listSync(), isEmpty);
      await unmount(tester);
    });

    testWidgets('Course recovery retires delayed load before store admission',
        (tester) async {
      final bundle =
          _SourceBundle(heldPath: 'content/motion_content/manifest.json');
      await mount(tester, SalsaCoursePage(env: environment(bundle)));
      await waitFor(tester, () => bundle.pending.length == 1);
      recovery.value = true;
      recovery.value = false;
      bundle.release(0);
      await waitFor(tester, () => bundle.pending[0].finished);
      expect(find.byKey(const Key('salsa.recoveryRetired')), findsOneWidget);
      expect(find.byKey(const Key('salsa.continue')), findsNothing);
      expect(bundle.projectionReads, 0);
      expect(temp.listSync(), isEmpty);
      await unmount(tester);
    });
  });
}
