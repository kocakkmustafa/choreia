import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:choreia/main.dart';
import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/account_recovery_host.dart';
import 'package:choreia/app/course/practice_comparison_page.dart';
import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/history/session_store_access.dart';
import 'package:choreia/app/library/library_view.dart';
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
    // Core 5832031 MotionAccountPage reads the age/consent state on open.
    if ((request.url.path == '/rest/v1/motion_age_declarations' ||
            request.url.path == '/rest/v1/motion_parental_consents') &&
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
 for (final mode in ['preserve', 'owner-in-flight', 'recovery-in-flight']) {
  testWidgets('production root worksheet $mode', (tester) async {
    final temp = Directory.systemTemp.createTempSync('choreia-worksheet-root-');
    final controller = ChoreiaAccountHostController();
    final account = _AccountFixture(controller);
    addTearDown(() async {
      debugPrint('root.route unmount-all begin');
      await tester.pumpWidget(const SizedBox.shrink());
      debugPrint('root.route unmount-all complete');
      await tester.pump();
      await _closeFixture(tester, account);
      await drainOwners(tester, appStoreOwners, [_alice, _bob]);
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
      final history = await ioStage('journal.open', () => openAppSessionStore(accountUserId: _alice, supportDirectory: temp, owners: seedOwners));
      await ioStage('journal.append-and-IO-close', () => history.append(SessionRecord(lessonId: 'hh_l1_bounce', lessonClass: 'demoOnly',
          completedAt: DateTime.utc(2026, 10, 5), workedSeconds: 12,
          unitsCompleted: 1, plannedUnits: 2, unitLabel: 'cycles')));
      final progress = await ioStage('course.open', () => SalsaProgressStore.open(accountUserId: _alice, supportDirectory: temp, owners: seedOwners));
      await ioStage('course.record-and-IO-close', () => progress.record(course, course.lessons.first, SalsaEvidence.viewed));
      await ioStage('course.record-and-IO-close', () => progress.record(course, course.lessons.first, SalsaEvidence.practised,
          option: SalsaPracticeOption.rhythmOnly));
      await ioStage('seed.registry-retire', () => seedOwners.retireOwner(_alice));
    });
    final journal = sessionFileFor(temp, _alice);
    final progressFile = File('${temp.path}/${SalsaProgressStore.fileNameFor(_alice)}');
    final journalBefore = journal.readAsBytesSync();
    final progressBefore = progressFile.readAsBytesSync();
    debugPrint('root: seeded records; mount production app');
    await tester.pumpWidget(MotionIdentityGate(runtime: account.runtime, child: ChoreiaApp(
      accountRuntime: account.runtime, accountHostController: controller,
      shellBuilder: (env, accountBuilder) => ChoreiaShell(
        bundleOverride: () async => library!, flagOverride: MemoryFirstRunFlag(seen: true),
        accountPageBuilder: accountBuilder,
        env: LiveEnvironment(bundle: DeviceBundle(declaredReferences()),
          historyDirectoryOverride: temp, accountUserId: env.accountUserId,
          passwordRecovery: env.passwordRecovery, ownerEpoch: env.ownerEpoch,
          source: () => throw StateError('Worksheet must not open camera'))),
    )));
    debugPrint('root.route production mount complete');
    await advance(tester);
    expect(account.runtime.isCurrentSessionVerified, isTrue);
    final oldTicket = appStoreOwners.currentTicket(_alice)!;
    await reach(tester, find.byKey(LibraryView.tileKey('hip_hop_foundations')));
    await routeStage('library-to-Hip-Hop', () => tester.tap(find.byKey(LibraryView.tileKey('hip_hop_foundations'))));
    await advance(tester);
    final link = find.byKey(const Key('style.practiceComparison'));
    await reach(tester, link);
    await routeStage('style-to-worksheet', () => tester.tap(link));
    // Route is deliberately still transitioning when the owner is retired.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PracticeComparisonPage), findsOneWidget);
    if (mode != 'preserve') {
      if (mode == 'owner-in-flight') {
        await tester.runAsync(() => ioStage('identity.Bob-sign-in', () => account.signIn(_bob)));
      } else {
        await tester.runAsync(() => ioStage('identity.recovery-callback', () => account.client.auth.getSessionFromUrl(Uri.parse(
            'com.yulalab.choreia://auth/callback#access_token=local-recovery-token'
            '&refresh_token=local-fixture-refresh&expires_in=3600&token_type=bearer&type=recovery'))));
      }
      await advance(tester);
      expect(oldTicket.isActive, isFalse);
      expect(find.byType(PracticeComparisonPage, skipOffstage: false), findsNothing);
      expect(account.runtime.userId.value, mode == 'owner-in-flight' ? _bob : _alice);
      if (mode == 'recovery-in-flight') {
        expect(account.runtime.passwordRecovery.value, isTrue);
        expect(find.byType(MotionAccountPage), findsOneWidget);
      }
    } else {
      await advance(tester);
      for (var i = 0; i < 7; i++) {
        final field = find.byKey(Key('practiceComparison.note.$i'));
        await reach(tester, field);
        await tester.enterText(field, 'uncertain note $i');
      }
      await routeStage('Back', tester.pageBack);
      await advance(tester);
      await reach(tester, link);
      await routeStage('style-to-worksheet', () => tester.tap(link));
      await advance(tester);
      for (var i = 0; i < 7; i++) {
        final field = find.byKey(Key('practiceComparison.note.$i'));
        await reach(tester, field);
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      }
      expect(oldTicket.isActive, isTrue);
      await routeStage('Back', tester.pageBack);
      await advance(tester);
      await routeStage('Back', tester.pageBack);
      await advance(tester);
      await routeStage('actual-progress-tab', () => tester.tap(find.byKey(ChoreiaShell.progressTabKey)));
      await advance(tester);
    }
    expect(journal.readAsBytesSync(), orderedEquals(journalBefore));
    expect(progressFile.readAsBytesSync(), orderedEquals(progressBefore));
    // Reopen/parse actual production persistence; equal bytes alone are insufficient.
    await tester.runAsync(() async {
      final readOwners = AppStoreOwnerRegistry();
      final history = await ioStage('journal.open', () => openAppSessionStore(accountUserId: _alice, supportDirectory: temp, owners: readOwners));
      expect((await ioStage('journal.recent-and-IO-close', history.recent)).single.workedSeconds, 12);
      final progress = await ioStage('course.open', () => SalsaProgressStore.open(accountUserId: _alice, supportDirectory: temp, owners: readOwners));
      final events = (await ioStage('course.read-and-IO-close', progress.read)).events;
      expect(events.map((e) => e.kind), [SalsaEvidence.viewed, SalsaEvidence.practised]);
      expect(events.last.option, SalsaPracticeOption.rhythmOnly);
    });
    expect(account.deletes, 0);
    expect(account.logouts, 0);
    expect(account.unexpected, isEmpty);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 45)));
 }
}
