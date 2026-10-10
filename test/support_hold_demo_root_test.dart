import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:choreia/main.dart';
import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/account_recovery_host.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/support_hold_demo.dart';
import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/history/session_store_access.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:motion_account/motion_account.dart';
import 'package:motion_core/motion_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/test_catalog.dart';
const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
Map<String, Object> _user(String id) => <String, Object>{
      'id': id,
      'aud': 'authenticated',
      'created_at': '2026-10-02T00:00:00Z',
      'app_metadata': <String, Object>{},
    };

http.Response _json(Object? data) => http.Response(jsonEncode(data), 200,
    headers: <String, String>{'content-type': 'application/json'});

/// Runs the public runtime and real Core deletion client against local HTTP
/// responses. Unexpected endpoints fail; nothing reaches a provider/network.
final class _AccountFixture {
  _AccountFixture(this.controller) {
    transport = MockClient(_handle);
    client = SupabaseClient('https://account-fixture.example.invalid',
        'public-local-fixture-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: transport);
  }
  final ChoreiaAccountHostController controller;
  late final MockClient transport;
  late final SupabaseClient client;
  MotionAccountRuntime? _runtime;
  MotionAccountRuntime get runtime => _runtime!;
  final entered = Completer<void>();
  final receipt = Completer<http.Response>();
  Object? cleanupError;
  String closeStage = 'not started';
  String currentId = _alice;
  String nextToken = 'local-fixture-token-1';
  int deletes = 0, logouts = 0;
  final unexpected = <String>[];

  Map<String, Object> session() => <String, Object>{
        'access_token': nextToken,
        'refresh_token': 'local-fixture-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': _user(currentId),
      };

  Future<http.Response> _handle(http.Request request) async {
    if (request.url.path == '/auth/v1/user' && request.method == 'GET') {
      return _json(_user(currentId));
    }
    if (request.url.path == '/auth/v1/token' && request.method == 'POST') {
      final grant = request.url.queryParameters['grant_type'];
      if (grant != 'refresh_token' && grant != 'password') {
        throw StateError('Unexpected local auth grant.');
      }
      return _json(session());
    }
    if (request.url.path == '/functions/v1/motion-delete-account' &&
        request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['expectedUserId'], _alice);
      expect(body['confirmation'], 'DELETE');
      deletes++;
      entered.complete();
      return receipt.future;
    }
    if (request.url.path == '/auth/v1/logout' && request.method == 'POST') {
      logouts++;
      return _json(<String, Object>{});
    }
    if (request.url.path == '/rest/v1/motion_profiles' &&
        request.method == 'GET') {
      return _json(<Object>[]);
    }
    final endpoint = '${request.method} ${request.url.path}';
    unexpected.add(endpoint);
    throw StateError('Unexpected local fixture endpoint: $endpoint');
  }

  Future<void> initialize() async {
    debugPrint('root: initialize begin');
    await client.auth.setInitialSession(jsonEncode(session()));
    _runtime = MotionAccountRuntime.forTesting(
      client: client,
      app: MotionApp.choreia,
      onDeletedAccount: (id) async {
        try {
          await clearLocalHistoryFor(id, onNamespaceFenced: controller.namespaceFenced);
        } catch (error) {
          cleanupError = error;
          rethrow;
        }
      },
    );
    // Drain the public SDK replay before requesting the final current proof.
    await Future<void>.delayed(Duration.zero);
    await runtime.refreshIdentity();
    expect(runtime.isCurrentSessionVerified, isTrue);
    expect(runtime.phase.value, MotionIdentityPhase.verified);
    debugPrint('root: initialize complete');
  }

  Future<void> refresh() async {
    nextToken = 'local-fixture-token-2';
    await client.auth.refreshSession();
    await runtime.refreshIdentity();
  }

  Future<void> signIn(String id) async {
    currentId = id;
    nextToken = 'local-fixture-token-2';
    await client.auth.signInWithPassword(
        email: 'local-fixture@example.invalid', password: 'fake');
    await runtime.refreshIdentity();
  }

  void acknowledge() {
    if (!receipt.isCompleted) {
      receipt.complete(_json(<String, Object>{'deleted': true, 'userId': _alice}));
    }
  }

  Future<void> close() async {
    acknowledge();
    closeStage = 'Core runtime.dispose';
    debugPrint('root.dispose $closeStage begin');
    _runtime?.dispose();
    debugPrint('root.dispose $closeStage complete');
    closeStage = 'local auth SDK/client.dispose';
    debugPrint('root.dispose $closeStage begin');
    await client.dispose();
    debugPrint('root.dispose $closeStage complete');
    closeStage = 'MockClient transport.close';
    debugPrint('root.dispose $closeStage begin');
    transport.close();
    debugPrint('root.dispose $closeStage complete');
    closeStage = 'complete';
  }
}


// Local transport fixture above follows the existing namespace integration test.
// Real ChoreiaApp -> account host -> MaterialApp -> ChoreiaShell -> library routes.
// IO stages are called INSIDE the existing runAsync callbacks: real timers,
// real futures, and a timeout that throws instead of inventing a completion.
Future<T> ioStage<T>(String label, Future<T> Function() operation) async {
  final wall = Stopwatch()..start();
  debugPrint('root.io $label begin');
  try {
    final result = await operation().timeout(const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('root.io $label exceeded 8 real seconds'));
    debugPrint('root.io $label complete ${wall.elapsedMilliseconds}ms');
    return result;
  } catch (error) {
    debugPrint('root.io $label failed ${error.runtimeType} ${wall.elapsedMilliseconds}ms');
    rethrow;
  }
}

// Keep route operations in their original fake-time test zone. Post-entry
// pumps/scans stay finite; the outer 45s test deadline bounds a framework stall.
Future<T> routeStage<T>(String label, Future<T> Function() operation) async {
  debugPrint('root.route $label begin');
  try {
    final result = await operation();
    debugPrint('root.route $label complete');
    return result;
  } catch (error) {
    debugPrint('root.route $label failed ${error.runtimeType}');
    rethrow;
  }
}

Future<void> advance(WidgetTester tester, [int frames = 20]) async {
  debugPrint('root: advance begin $frames');
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  debugPrint('root: advance complete');
}
Future<void> reach(WidgetTester tester, Finder target) async {
  debugPrint('root.route reach begin ${target.toString()}');
  // During the 400ms transition the previous route is still laid out.
  // Scroll only the actual Navigator's current route, not that previous page.
  final scrollable = find.byElementPredicate((element) =>
      element.widget is Scrollable && ModalRoute.of(element)?.isCurrent == true).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  if (target.evaluate().isEmpty) {
    // Reset before scanning: the requested lazy child may be ABOVE the viewport.
    position.jumpTo(0);
    await tester.pump();
  }
  for (var i = 0; i < 200 && target.evaluate().isEmpty; i++) {
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo((position.pixels + 150).clamp(0.0, position.maxScrollExtent).toDouble());
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  debugPrint('root.route reach complete ${target.toString()}');
}
Future<void> tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await reach(tester, finder);
  await routeStage('key:${key.toString()}', () => tester.tap(finder));
  await tester.pump();
}
Future<void> loaded(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80; i++) {
    await advance(tester, 1);
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
Future<void> drainOwners(WidgetTester tester, AppStoreOwnerRegistry owners,
    Iterable<String?> ids) async {
  debugPrint('root: owner drain begin');
  var drained = false;
  Object? failure;
  final pending = <String>{};
  Future<void> retire(String? id) async {
    final name = id == null ? 'fixture guest' : id == _alice ? 'fixture Alice' : 'fixture Bob';
    pending.add(name);
    debugPrint('root.retire $name begin');
    try {
      await owners.retireOwner(id);
      pending.remove(name);
      debugPrint('root.retire $name complete');
    } catch (error) {
      debugPrint('root.retire $name failed ${error.runtimeType}');
      rethrow;
    }
  }
  unawaited(Future.wait<void>([
    for (final id in ids) retire(id),
  ]).then<void>((_) => drained = true, onError: (Object error, StackTrace _) {
    failure = error;
    drained = true;
  }));
  for (var i = 0; i < 80 && !drained; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
  expect(drained, isTrue, reason: 'Real owner operations must drain in their originating test zone; pending: $pending.');
  expect(failure, isNull);
  expect(owners.retirementBarrier, isNull);
  debugPrint('root: owner drain complete');
}

Future<void> _closeFixture(WidgetTester tester, _AccountFixture account) async {
  debugPrint('root: fixture close begin');
  var closed = false;
  Object? failure;
  unawaited(account.close().then<void>((_) => closed = true,
      onError: (Object error, StackTrace _) {
        failure = error;
        closed = true;
      }));
  for (var i = 0; i < 80 && !closed; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
  expect(closed, isTrue, reason: 'Local auth streams must close with their originating test zone pumped; last stage: ${account.closeStage}.');
  expect(failure, isNull);
  debugPrint('root: fixture close complete');
}

void main() {
  for (final mode in ['back-en', 'back-tr', 'owner-transition', 'owner-playing',
      'recovery-transition', 'recovery-playing', 'logout-playing']) {
    testWidgets('real Salsa so_04 demo route $mode', (tester) async {
      // Device EN for both Back cases: TR must originate from lesson toggle.
      tester.binding.platformDispatcher.localeTestValue = const Locale('en');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final temp = Directory.systemTemp.createTempSync('choreia-demo-root-');
      final controller = ChoreiaAccountHostController();
      final account = _AccountFixture(controller);
      addTearDown(() async {
        debugPrint('root.route unmount-all begin');
      await tester.pumpWidget(const SizedBox.shrink());
      debugPrint('root.route unmount-all complete');
        await tester.pump();
        await _closeFixture(tester, account);
        await drainOwners(tester, appStoreOwners, [_alice, _bob, null]);
        temp.deleteSync(recursive: true);
      });
      await tester.runAsync(() => ioStage('identity.initialize', account.initialize));
      final library = await tester.runAsync(() => ioStage('catalog.disk-load', testLibrary));
      final course = SalsaCourse.fromJson(jsonDecode(
          File('content/salsa_on1_course.json').readAsStringSync()) as Map<String, dynamic>);
      await tester.runAsync(() async {
      // Isolated setup registry creates a cold-start fixture on disk. It is
      // never passed to ChoreiaApp/Shell and never resumes the global owner.
      final seedOwners = AppStoreOwnerRegistry();
        final store = await ioStage('journal.open', () => openAppSessionStore(accountUserId: _alice, supportDirectory: temp, owners: seedOwners));
        await ioStage('journal.append-and-IO-close', () => store.append(SessionRecord(lessonId: 'hh_l1_bounce', lessonClass: 'demoOnly',
            completedAt: DateTime.utc(2026, 10, 5), workedSeconds: 12,
            unitsCompleted: 1, plannedUnits: 2, unitLabel: 'cycles')));
        final progress = await ioStage('course.open', () => SalsaProgressStore.open(accountUserId: _alice, supportDirectory: temp, owners: seedOwners));
        await ioStage('course.record-and-IO-close', () => progress.record(course, course.lessons.first, SalsaEvidence.practised,
            option: SalsaPracticeOption.rhythmOnly));
      await ioStage('seed.registry-retire', () => seedOwners.retireOwner(_alice));
      });
      debugPrint('root: seeded records; mount production app');
    await tester.pumpWidget(MotionIdentityGate(runtime: account.runtime, child: ChoreiaApp(
        accountRuntime: account.runtime, accountHostController: controller,
        shellBuilder: (env, accountBuilder) => ChoreiaShell(
          bundleOverride: () async => library!, flagOverride: MemoryFirstRunFlag(seen: true),
          accountPageBuilder: accountBuilder,
          env: LiveEnvironment(bundle: DeviceBundle(declaredReferences()),
            historyDirectoryOverride: temp, accountUserId: env.accountUserId,
            passwordRecovery: env.passwordRecovery, ownerEpoch: env.ownerEpoch,
            source: () => throw StateError('Symbolic demo must not open camera'))),
      )));
      debugPrint('root.route production mount complete');
      await loaded(tester, find.byKey(const Key('salsa.open')));
      await tapKey(tester, const Key('salsa.open'));
      await loaded(tester, find.byKey(const Key('salsa.overview')));
      await tapKey(tester, const Key('salsa.lesson.so_04'));
      await loaded(tester, find.byKey(const ValueKey('salsa.lessonBody.so_04')));
      await advance(tester);
      // The lesson's legitimate viewed write must settle before demo baseline.
      final eventsBefore = await tester.runAsync(() async {
        final store = await ioStage('course.open', () => SalsaProgressStore.open(accountUserId: _alice, supportDirectory: temp));
        return (await ioStage('course.read-and-IO-close', store.read)).events.map((e) => e.toJson()).toList();
      });
      expect(eventsBefore!.where((e) => e['lessonId'] == 'so_04' && e['kind'] == 'viewed'), hasLength(1));
      final journal = sessionFileFor(temp, _alice);
      final courseFile = File('${temp.path}/${SalsaProgressStore.fileNameFor(_alice)}');
      final journalBefore = journal.readAsBytesSync();
      final courseBefore = courseFile.readAsBytesSync();
      if (mode == 'back-tr') {
        await tester.tap(find.text('Türkçe'));
        await tester.pump();
      }
      final entry = find.byKey(const Key('salsa.supportHoldDemo'));
      await reach(tester, entry);
      final staleEntry = tester.widget<TextButton>(entry).onPressed!;
      final oldTicket = appStoreOwners.currentTicket(_alice)!;
      await routeStage('so_04-to-demo', () => tester.tap(entry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final demo = find.byType(SupportHoldDemo);
      expect(demo, findsOneWidget);
      final route = ModalRoute.of(tester.element(demo))!;
      expect(route.settings.name, 'course/salsa-on1/support-hold');
      expect(route.animation!.status, AnimationStatus.forward);
      expect(route.animation!.value, lessThan(1));
      final oldDemoState = tester.state<State<SupportHoldDemo>>(demo);
      if (mode.startsWith('back')) {
        await advance(tester);
        expect(find.text(mode == 'back-tr' ? 'Destek ve durak şeması' : 'Support and hold diagram'), findsOneWidget);
        final explanation = find.textContaining(mode == 'back-tr'
            ? 'Açıklama: normal örnekte' : 'Explanation: normally');
        await reach(tester, explanation);
        expect(explanation, findsOneWidget);
        await tapKey(tester, const Key('supportHold.count.4'));
        await reach(tester, find.byKey(const Key('supportHold.current')));
        expect(tester.widget<Text>(find.byKey(const Key('supportHold.current'))).data,
            mode == 'back-tr' ? '4/8 — A — aynı destek / durak' : '4/8 — A — same support / hold');
        await routeStage('Back', tester.pageBack);
        await advance(tester);
        expect(oldDemoState.mounted, isFalse);
        expect(find.byKey(const ValueKey('salsa.lessonBody.so_04')), findsOneWidget);
        expect(find.text(mode == 'back-tr' ? 'English' : 'Türkçe'), findsOneWidget);
        expect(oldTicket.isActive, isTrue);
        expect(courseFile.readAsBytesSync(), orderedEquals(courseBefore));
        await tapKey(tester, const Key('salsa.supportHoldDemo'));
        await advance(tester);
        await reach(tester, find.byKey(const Key('supportHold.current')));
        expect(tester.widget<Text>(find.byKey(const Key('supportHold.current'))).data, startsWith('1/8'));
        await routeStage('Back', tester.pageBack);
        await advance(tester);
      } else {
        if (mode.endsWith('playing')) {
          await advance(tester);
          await tapKey(tester, const Key('supportHold.play'));
          await tester.pump(const Duration(milliseconds: 2100));
          await reach(tester, find.byKey(const Key('supportHold.current')));
          expect(tester.widget<Text>(find.byKey(const Key('supportHold.current'))).data, startsWith('3/8'));
        }
        if (mode.startsWith('owner')) {
          await tester.runAsync(() => ioStage('identity.Bob-sign-in', () => account.signIn(_bob)));
        } else if (mode.startsWith('recovery')) {
          await tester.runAsync(() => ioStage('identity.recovery-callback', () => account.client.auth.getSessionFromUrl(Uri.parse(
              'com.yulalab.choreia://auth/callback#access_token=local-recovery-token'
              '&refresh_token=local-fixture-refresh&expires_in=3600&token_type=bearer&type=recovery'))));
        } else {
          await tester.runAsync(() => ioStage('identity.deliberate-logout', account.client.auth.signOut));
        }
        await advance(tester);
        expect(oldTicket.isActive, isFalse);
        expect(oldDemoState.mounted, isFalse);
        expect(find.byType(SupportHoldDemo, skipOffstage: false), findsNothing);
        expect(find.byType(SalsaLessonPage, skipOffstage: false), findsNothing);
        expect(account.runtime.userId.value,
            mode.startsWith('owner') ? _bob : mode.startsWith('recovery') ? _alice : null);
        if (mode.startsWith('recovery')) {
          expect(account.runtime.passwordRecovery.value, isTrue);
          expect(find.byType(MotionAccountPage), findsOneWidget);
        }
        // A retained callback must not recreate a route after its owner retired.
        staleEntry();
        await tester.pump(const Duration(seconds: 9));
        expect(find.byType(SupportHoldDemo, skipOffstage: false), findsNothing);
        expect(oldDemoState.mounted, isFalse);
      }
      expect(journal.readAsBytesSync(), orderedEquals(journalBefore));
      expect(courseFile.readAsBytesSync(), orderedEquals(courseBefore));
      await tester.runAsync(() async {
        final readOwners = AppStoreOwnerRegistry();
        final store = await ioStage('course.open', () => SalsaProgressStore.open(accountUserId: _alice,
            supportDirectory: temp, owners: readOwners));
        expect((await ioStage('course.read-and-IO-close', store.read)).events.map((e) => e.toJson()).toList(), eventsBefore);
      });
      expect(account.deletes, 0);
      expect(account.logouts, mode == 'logout-playing' ? 1 : 0);
      expect(account.unexpected, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  final placementCourse = SalsaCourse.fromJson(jsonDecode(
      File('content/salsa_on1_course.json').readAsStringSync()) as Map<String, dynamic>);
  for (final lesson in placementCourse.lessons) {
    testWidgets('actual lesson placement exists only for so_04: ${lesson.id}', (tester) async {
    final temp = Directory.systemTemp.createTempSync('choreia-demo-placement-');
    final owners = AppStoreOwnerRegistry();
    addTearDown(() async {
      debugPrint('root.route unmount-all begin');
      await tester.pumpWidget(const SizedBox.shrink());
      debugPrint('root.route unmount-all complete');
      await tester.pump();
      await drainOwners(tester, owners, [_alice]);
      temp.deleteSync(recursive: true);
    });
    final course = placementCourse;
    final store = await tester.runAsync(() => SalsaProgressStore.open(
        accountUserId: _alice, supportDirectory: temp, owners: owners));
    final user = ValueNotifier<String?>(_alice);
    addTearDown(user.dispose);
    final env = LiveEnvironment(bundle: DeviceBundle(declaredReferences()),
        historyDirectoryOverride: temp, accountUserId: user, storeOwners: owners,
        source: () => throw StateError('Placement must not start camera'));
      await tester.pumpWidget(MaterialApp(home: SalsaLessonPage(
        key: ValueKey(lesson.id), course: course, lesson: lesson, store: store!,
        env: env, initialTurkish: false)));
      await advance(tester);
      final entry = find.byKey(const Key('salsa.supportHoldDemo'));
      if (lesson.id == 'so_04') {
        await reach(tester, entry);
        expect(entry, findsOneWidget);
        expect(tester.widget<TextButton>(entry).onPressed, isNotNull);
      } else {
        // Traverse the full real lesson ListView: lazy children cannot hide a link.
        // During the 400ms transition the previous route is still laid out.
  // Scroll only the actual Navigator's current route, not that previous page.
  final scrollable = find.byElementPredicate((element) =>
      element.widget is Scrollable && ModalRoute.of(element)?.isCurrent == true).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        for (var frame = 0; frame < 200; frame++) {
          expect(entry, findsNothing, reason: lesson.id);
          if (position.pixels >= position.maxScrollExtent) break;
          position.jumpTo((position.pixels + 200).clamp(0.0, position.maxScrollExtent).toDouble());
          await tester.pump();
        }
        expect(position.pixels, position.maxScrollExtent);
        expect(entry, findsNothing, reason: lesson.id);
      }
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(seconds: 45)));
  }

  for (final retirement in ['owner', 'recovery', 'epoch']) {
    testWidgets('retained real lesson callback rejects mounted $retirement retirement', (tester) async {
      final temp = Directory.systemTemp.createTempSync('choreia-demo-guard-');
      final owners = AppStoreOwnerRegistry();
      final user = ValueNotifier<String?>(_alice);
      final recovery = ValueNotifier(false);
      final epoch = ValueNotifier(0);
      addTearDown(() async {
        debugPrint('root.route unmount-all begin');
      await tester.pumpWidget(const SizedBox.shrink());
      debugPrint('root.route unmount-all complete');
        await tester.pump();
        await drainOwners(tester, owners, [_alice]);
        user.dispose(); recovery.dispose(); epoch.dispose();
        temp.deleteSync(recursive: true);
      });
      final course = SalsaCourse.fromJson(jsonDecode(
          File('content/salsa_on1_course.json').readAsStringSync()) as Map<String, dynamic>);
      final store = await tester.runAsync(() => SalsaProgressStore.open(
          accountUserId: _alice, supportDirectory: temp, owners: owners));
      await tester.pumpWidget(MaterialApp(home: SalsaLessonPage(
        course: course, lesson: course.lesson('so_04'), store: store!, initialTurkish: false,
        env: LiveEnvironment(bundle: DeviceBundle(declaredReferences()),
          historyDirectoryOverride: temp, accountUserId: user, passwordRecovery: recovery,
          ownerEpoch: epoch, storeOwners: owners,
          source: () => throw StateError('Guard test must not open camera')))));
      await advance(tester);
      final entry = find.byKey(const Key('salsa.supportHoldDemo'));
      await reach(tester, entry);
      final callback = tester.widget<TextButton>(entry).onPressed!;
      final before = store.file.readAsBytesSync();
      if (retirement == 'owner') { user.value = _bob; }
      else if (retirement == 'recovery') { recovery.value = true; }
      else { epoch.value++; }
      await tester.pump();
      expect(find.byType(SalsaLessonPage), findsOneWidget,
          reason: 'Exercise the production admission guard while lesson remains mounted.');
      callback();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SupportHoldDemo), findsNothing);
      expect(store.file.readAsBytesSync(), orderedEquals(before));
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(seconds: 45)));
  }

}
