import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/account_recovery_host.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _initialToken = 'initial-session';

http.Response _json(Object body) => http.Response(jsonEncode(body), 200,
    headers: <String, String>{'content-type': 'application/json'});

/// Public Auth creates the actual Session objects observed by Core's dialog.
/// The real Core deletion client dispatches only to this local MockClient.
/// Every unexpected HTTP endpoint fails; no provider or network is contacted.
final class _HeldAccount extends MotionAccountClient {
  factory _HeldAccount() {
    late final _HeldAccount account;
    final transport = MockClient((request) => account._handle(request));
    final client = SupabaseClient('https://dialog-fixture.example.invalid',
        'public-local-fixture-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: transport);
    account = _HeldAccount._(client, transport);
    return account;
  }

  _HeldAccount._(SupabaseClient client, this.transport)
      : super(supabase: client, app: MotionApp.choreia,
            emailRedirectTo: 'com.yulalab.choreia://auth/callback');
  final MockClient transport;
  final response = Completer<void>();
  final unexpected = <String>[];
  final dispatchedTokens = <String?>[];
  String _nextToken = _initialToken;
  int deleteInvocations = 0;
  int logouts = 0;
  int identityRequests = 0;
  final identitySessions = <Session?>[];
  bool holdResponse = false;
  bool cleanupPending = false;
  bool deletionFinished = false;
  Future<void>? _deletion;

  Map<String, Object> _user() => <String, Object>{
        'id': _alice,
        'aud': 'authenticated',
        'created_at': '2026-10-02T00:00:00Z',
        'app_metadata': <String, Object>{},
      };
  Map<String, Object> _session() => <String, Object>{
        'access_token': _nextToken,
        'refresh_token': 'local-fixture-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': _user(),
      };

  Future<http.Response> _handle(http.Request request) async {
    if (request.method == 'POST' && request.url.path == '/auth/v1/token') {
      final grant = request.url.queryParameters['grant_type'];
      if (grant == 'password' || grant == 'refresh_token') {
        return _json(_session());
      }
    } else if (request.method == 'GET' && request.url.path == '/auth/v1/user') {
      identityRequests++;
      identitySessions.add(supabase.auth.currentSession);
      return _json(_user());
    } else if (request.method == 'GET' &&
        request.url.path == '/rest/v1/motion_profiles') {
      return _json(<Object>[]);
    } else if (request.method == 'GET' &&
        (request.url.path == '/rest/v1/motion_age_declarations' ||
            request.url.path == '/rest/v1/motion_parental_consents')) {
      // Core 5832031 MotionAccountPage reads the age/consent state on open.
      return _json(<Object>[]);
    } else if (request.method == 'POST' &&
        request.url.path == '/functions/v1/motion-delete-account') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['expectedUserId'], _alice);
      expect(body['confirmation'], 'DELETE');
      deleteInvocations++;
      dispatchedTokens.add(request.headers['authorization']);
      if (holdResponse) {
        await response.future;
      }
      return _json(<String, Object>{'deleted': true, 'userId': _alice});
    } else if (request.method == 'POST' &&
        request.url.path == '/auth/v1/logout') {
      logouts++;
      return _json(<String, Object>{});
    }
    final endpoint = '${request.method} ${request.url}';
    unexpected.add(endpoint);
    throw StateError('Unexpected local dialog endpoint: $endpoint');
  }

  Future<void> initialize() async {
    await supabase.auth.setInitialSession(jsonEncode(_session()));
  }

  Future<void> event(AuthChangeEvent event, String token) async {
    final oldSession = supabase.auth.currentSession;
    final observed = authChanges
        .firstWhere((state) => state.event == event)
        .timeout(const Duration(seconds: 2));
    _nextToken = token;
    if (event == AuthChangeEvent.signedIn) {
      await supabase.auth.signInWithPassword(
          email: 'local-dialog@example.invalid', password: 'fake');
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      await supabase.auth.refreshSession();
    } else {
      throw ArgumentError.value(event, 'event');
    }
    await observed;
    expect(supabase.auth.currentSession, isNotNull);
    expect(identical(supabase.auth.currentSession, oldSession), isFalse);
    expect(supabase.auth.currentSession!.accessToken, token);
    expect(currentUser!.id, _alice);
  }

  @override
  Future<void> deleteCommonAccount({
    Future<void> Function(String userId)? afterRemoteDelete,
  }) async {
    // Instrument completion only. Dispatch, receipt parsing, captured UUID and
    // final Session-aware signOut all remain the public Core implementation.
    final deleting = super.deleteCommonAccount(afterRemoteDelete: afterRemoteDelete);
    _deletion = deleting;
    try {
      await deleting;
    } on MotionLocalCleanupPending {
      cleanupPending = true;
      rethrow;
    } finally {
      deletionFinished = true;
    }
  }

  void release() {
    if (!response.isCompleted) {
      response.complete();
    }
  }

  Future<void> disposeFixture() async {
    release();
    if (_deletion != null) {
      try {
        await _deletion!.timeout(const Duration(seconds: 2));
      } catch (_) {
        // A failed assertion must still close the transport and client below.
      }
    }
    try {
      await supabase.dispose().timeout(const Duration(seconds: 2));
    } finally {
      transport.close();
    }
  }
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready,
    String witness) async {
  for (var i = 0; i < 80 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
  expect(ready(), isTrue, reason: witness);
}

Future<void> _openDialog(WidgetTester tester) async {
  final open = find.text('Delete Motion account');
  await tester.ensureVisible(open);
  await tester.tap(open);
  await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isNotEmpty,
      'The actual Core confirmation dialog must open.');
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  late Directory directory;
  late AppStoreOwnerRegistry owners;
  late ValueNotifier<int> pageRevision;
  ValueListenable<int>? ownerEpoch;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('choreia-delete-init-');
    owners = AppStoreOwnerRegistry();
    pageRevision = ValueNotifier<int>(0);
    ownerEpoch = null;
  });
  tearDown(() {
    pageRevision.dispose();
    directory.deleteSync(recursive: true);
  });

  Future<void> clearFixtureFiles(String id, AppStoreOwnerTicket? ticket) =>
      owners.erase(id, () async {
        // Dialog/captured callback scope uses exact synchronous fixture IO.
        // Admitted asynchronous bridge IO drain has its separate store tests.
        final journal = sessionFileFor(directory, id);
        final course = File('${directory.path}/${SalsaProgressStore.fileNameFor(id)}');
        for (final file in [journal, File('${journal.path}.tmp'),
          course, File('${course.path}.tmp')]) {
          if (FileSystemEntity.typeSync(file.path, followLinks: false) ==
              FileSystemEntityType.file) {
            file.deleteSync();
          }
        }
      }, expectedOwner: ticket);

  Future<_HeldAccount> fixture(WidgetTester tester) async {
    final account = (await tester.runAsync(() async => _HeldAccount()))!;
    addTearDown(() async {
      try {
        account.release();
        if (account._deletion != null) {
          await _waitFor(tester, () => account.deletionFinished,
              'An admitted local HTTP deletion must settle before teardown.');
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(account.disposeFixture);
      }
      expect(account.unexpected, isEmpty);
    });
    await tester.runAsync(account.initialize);
    expect(account.currentUser!.id, _alice);
    expect(account.supabase.auth.currentSession, isNotNull);
    return account;
  }

  Future<void> mount(WidgetTester tester, _HeldAccount account) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    final events = account.authChanges.map((state) =>
        ChoreiaAuthSessionEvent(state.event.name, state.session));
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user, passwordRecovery: recovery, owners: owners,
      authSessionChanges: events,
      initialSessionIdentity: account.supabase.auth.currentSession,
      builder: (context, navigationKey, recovering, epoch) {
        ownerEpoch = epoch;
        return MaterialApp(key: navigationKey,
          home: ValueListenableBuilder<int>(valueListenable: pageRevision,
            builder: (context, value, child) => MotionAccountPage(
              account: OwnerBoundMotionAccountClient(account,
                  expectedOwner: owners.currentTicket(_alice), owners: owners),
              paidFeaturesAvailable: false,
              clearLocalData: (id) => clearFixtureFiles(id, null),
            ),
          ),
        );
      },
    ));
    await tester.pump();
    await _openDialog(tester);
  }

  testWidgets('same-UUID replacement rejects an old dialog before the next frame',
      (tester) async {
    final account = await fixture(tester);
    await mount(tester, account);
    final oldTicket = owners.currentTicket(_alice)!;
    await tester.runAsync(() => account.event(AuthChangeEvent.signedIn, 'replacement-session'));
    // Deliver SDK microtasks while retaining the old dialog's frame.
    await tester.idle();
    expect(oldTicket.isActive, isFalse);
    expect(identical(oldTicket, owners.currentTicket(_alice)), isFalse);
    final freshFile = sessionFileFor(directory, _alice)..writeAsStringSync('fresh A data');
    // Public Auth changed; no frame has replaced the mounted old dialog yet.
    await tester.tap(find.text('Delete account'));
    expect(account.deleteInvocations, 0);
    expect(freshFile.readAsStringSync(), 'fresh A data');
    await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isEmpty,
        'The old confirmation dialog must leave the route.');
    expect(account.deleteInvocations, 0);
    expect(freshFile.readAsStringSync(), 'fresh A data');
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('ordinary refresh keeps host ticket but rejects the old dialog Session',
      (tester) async {
    final account = await fixture(tester);
    await mount(tester, account);
    final ticket = owners.currentTicket(_alice)!;
    final epoch = ownerEpoch!.value;
    final openingSession = account.supabase.auth.currentSession;
    final file = sessionFileFor(directory, _alice)..writeAsStringSync('current refresh data');
    await tester.runAsync(() => account.event(AuthChangeEvent.tokenRefreshed, 'refreshed-session'));
    expect(ticket.isActive, isTrue);
    expect(identical(ticket, owners.currentTicket(_alice)), isTrue);
    expect(ownerEpoch!.value, epoch);
    expect(identical(account.supabase.auth.currentSession, openingSession), isFalse);
    await tester.tap(find.text('Delete account'));
    await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isEmpty,
        'The old confirmation dialog must leave the route.');
    expect(account.deleteInvocations, 0);
    expect(file.readAsStringSync(), 'current refresh data');
    expect(ticket.isActive, isTrue);
    // Renew the page wrapper explicitly: a reopened dialog cannot revive the
    // prior wrapper's captured Session. This does not rotate the host lifetime.
    pageRevision.value++;
    await tester.pump();
    expect(ownerEpoch!.value, epoch);
    expect(identical(ticket, owners.currentTicket(_alice)), isTrue);
    await _openDialog(tester);
    await tester.tap(find.text('Delete account'));
    await _waitFor(tester, () => account.deletionFinished, 'Fresh-session dialog deletion completed.');
    expect(account.deleteInvocations, 1);
    expect(account.dispatchedTokens, <String>['Bearer refreshed-session']);
    expect(account.cleanupPending, isFalse);
    expect(file.existsSync(), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('same-token signedIn rejects an old dialog before the next frame',
      (tester) async {
    final account = await fixture(tester);
    await mount(tester, account);
    final oldTicket = owners.currentTicket(_alice)!;
    await tester.runAsync(() => account.event(AuthChangeEvent.signedIn, _initialToken));
    await tester.idle();
    expect(oldTicket.isActive, isFalse);
    expect(identical(oldTicket, owners.currentTicket(_alice)), isFalse);
    final freshFile = sessionFileFor(directory, _alice)..writeAsStringSync('fresh same-token A');
    await tester.tap(find.text('Delete account'));
    expect(account.deleteInvocations, 0);
    expect(freshFile.readAsStringSync(), 'fresh same-token A');
    await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isEmpty,
        'The old confirmation dialog must leave the route.');
    expect(account.deleteInvocations, 0);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final replacementToken in ['replacement-session', _initialToken]) {
    testWidgets('replacement ${replacementToken == _initialToken ? 'same-token' : 'new-token'} after remote dispatch still erases confirmed account-wide A',
        (tester) async {
      final account = await fixture(tester);
      account.holdResponse = true;
      await mount(tester, account);
      final openingSession = account.supabase.auth.currentSession;
      await tester.tap(find.text('Delete account'));
      await _waitFor(tester, () => account.deleteInvocations == 1, 'Real Core delete HTTP entered its held response.');
      expect(account.deletionFinished, isFalse);
      expect(account.dispatchedTokens, <String>['Bearer $_initialToken']);
      await tester.runAsync(() => account.event(AuthChangeEvent.signedIn, replacementToken));
      final replacement = account.supabase.auth.currentSession;
      expect(identical(replacement, openingSession), isFalse);
      final freshFile = sessionFileFor(directory, _alice)..writeAsStringSync('fresh A while old response held');
      account.release();
      await _waitFor(tester, () => account.deletionFinished, 'Held confirmed deletion settled.');
      expect(account.cleanupPending, isFalse);
      expect(freshFile.existsSync(), isFalse);
      expect(owners.isErasing(_alice), isFalse);
      expect(account.logouts, 0);
      expect(identical(account.supabase.auth.currentSession, replacement), isTrue);
      expect(account.supabase.auth.currentSession!.accessToken, replacementToken);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('unchanged Session replacement wrapper keeps the opening callback',
      (tester) async {
    final account = await fixture(tester);
    final ticket = owners.capture(_alice);
    final opening = OwnerBoundMotionAccountClient(account, expectedOwner: ticket, owners: owners);
    final replacement = OwnerBoundMotionAccountClient(account, expectedOwner: ticket, owners: owners);
    final wrapper = ValueNotifier<MotionAccountClient>(opening);
    var openingCalls = 0, replacementCalls = 0;
    addTearDown(wrapper.dispose);
    await tester.pumpWidget(MaterialApp(home: ValueListenableBuilder<MotionAccountClient>(
      valueListenable: wrapper,
      builder: (context, value, child) => MotionAccountPage(account: value,
        paidFeaturesAvailable: false,
        clearLocalData: (id) async {
          if (identical(value, opening)) { openingCalls++; } else { replacementCalls++; }
          await clearFixtureFiles(id, null);
        },
      ),
    )));
    await _openDialog(tester);
    final openingSession = account.supabase.auth.currentSession;
    wrapper.value = replacement;
    await tester.pump();
    expect(identical(account.supabase.auth.currentSession, openingSession), isTrue);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Delete account'));
    await _waitFor(tester, () => account.deletionFinished, 'Opening wrapper dispatch completed.');
    expect(account.deleteInvocations, 1);
    expect(openingCalls, 1);
    expect(replacementCalls, 0);
    expect(account.cleanupPending, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final tokenAba in [false, true]) {
    testWidgets('pending dialog independently rejects ${tokenAba ? 'token ABA' : 'same-token new Session'}',
        (tester) async {
      final account = await fixture(tester);
      final ticket = owners.capture(_alice);
      var cleanupCalls = 0;
      Widget page(MotionAccountClient client) => MaterialApp(home: MotionAccountPage(
        account: client,
        paidFeaturesAvailable: false,
        clearLocalData: (id) async { cleanupCalls++; await clearFixtureFiles(id, null); },
      ));
      await tester.pumpWidget(page(account));
      await _openDialog(tester);
      final opening = account.supabase.auth.currentSession;
      if (tokenAba) {
        await tester.runAsync(() => account.event(AuthChangeEvent.signedIn, 'middle-token'));
      }
      await tester.runAsync(() => account.event(AuthChangeEvent.signedIn, _initialToken));
      final replacement = account.supabase.auth.currentSession;
      expect(identical(opening, replacement), isFalse);
      expect(replacement!.accessToken, opening!.accessToken);
      // No host listener or app wrapper retires/refuses this account: Core's
      // pending-dialog Session guard is independently necessary.
      expect(ticket.isActive, isTrue);
      expect(identical(owners.currentTicket(_alice), ticket), isTrue);
      await tester.tap(find.text('Delete account'));
      await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isEmpty,
          'The rejected Session dialog must close.');
      expect(account.deleteInvocations, 0);
      expect(cleanupCalls, 0);
      expect(identical(account.supabase.auth.currentSession, replacement), isTrue);
      // Renew the app wrapper for the current Session positive control.
      await tester.pumpWidget(page(OwnerBoundMotionAccountClient(account,
          expectedOwner: ticket, owners: owners)));
      await _openDialog(tester);
      await tester.tap(find.text('Delete account'));
      await _waitFor(tester, () => account.deletionFinished, 'Current Session positive dialog dispatch completed.');
      expect(account.deleteInvocations, 1);
      expect(cleanupCalls, 1);
      expect(account.cleanupPending, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('silent same-token recoverSession cannot revive a retained owner wrapper',
      (tester) async {
    final account = await fixture(tester);
    final runtime = MotionAccountRuntime.forTesting(client: account.supabase,
      app: MotionApp.choreia, onDeletedAccount: (id) => clearFixtureFiles(id, null));
    addTearDown(runtime.dispose);
    await tester.runAsync(runtime.refreshIdentity);
    expect(runtime.phase.value, MotionIdentityPhase.verified);
    final ticket = owners.capture(_alice);
    final retained = OwnerBoundMotionAccountClient(account,
        expectedOwner: ticket, owners: owners);
    final opening = account.supabase.auth.currentSession!;
    final events = <AuthChangeEvent>[];
    final subscription = account.authChanges.listen((state) => events.add(state.event));
    addTearDown(subscription.cancel);
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
      events.clear();
      await account.supabase.auth.recoverSession(jsonEncode(opening.toJson()));
      await Future<void>.delayed(Duration.zero);
    });
    final recovered = account.supabase.auth.currentSession!;
    expect(identical(opening, recovered), isFalse);
    expect(recovered.accessToken, opening.accessToken);
    expect(recovered.user.id, opening.user.id);
    expect(events, isEmpty, reason: 'Silent recovery must exercise the path with no host Auth event.');
    expect(runtime.phase.value, MotionIdentityPhase.verified,
        reason: 'Cached canonical phase alone cannot admit a retained wrapper.');
    expect(runtime.userId.value, _alice);
    expect(ticket.isActive, isTrue);
    expect(identical(owners.currentTicket(_alice), ticket), isTrue);
    final file = sessionFileFor(directory, _alice)..writeAsStringSync('fresh recovered A');
    var cleanupCalls = 0;
    Widget page(MotionAccountClient client) => MaterialApp(home: MotionAccountPage(
      account: client, paidFeaturesAvailable: false,
      clearLocalData: (id) async { cleanupCalls++; await clearFixtureFiles(id, null); },
    ));
    // Open AFTER silent recovery. Core's dialog captures the new Session, so
    // only the app wrapper's captured initiating Session can refuse this RPC.
    await tester.pumpWidget(page(retained));
    await _openDialog(tester);
    await tester.tap(find.text('Delete account'));
    await _waitFor(tester,
        () => find.text('Could not complete the request. Check your details and connection, then retry.').evaluate().isNotEmpty,
        'The retained wrapper must settle with a handled refusal.');
    expect(account.deleteInvocations, 0);
    expect(cleanupCalls, 0);
    expect(file.readAsStringSync(), 'fresh recovered A');
    expect(identical(account.supabase.auth.currentSession, recovered), isTrue);
    expect(ticket.isActive, isTrue);
    final requestsBeforeRefresh = account.identityRequests;
    await tester.runAsync(runtime.refreshIdentity);
    expect(account.identityRequests, requestsBeforeRefresh + 1);
    expect(identical(account.identitySessions.last, recovered), isTrue);
    expect(identical(account.supabase.auth.currentSession, recovered), isTrue);
    expect(runtime.phase.value, MotionIdentityPhase.verified);
    // This local GET_USER response has no Session supersession. The public
    // Future<void>/cached phase is not a general verified-Session witness.
    final fresh = OwnerBoundMotionAccountClient(account,
        expectedOwner: owners.currentTicket(_alice), owners: owners);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(page(fresh));
    await _openDialog(tester);
    await tester.tap(find.text('Delete account'));
    await _waitFor(tester, () => account.deletionFinished,
        'The explicit current-Session wrapper local positive must dispatch and settle.');
    expect(account.deleteInvocations, 1);
    expect(cleanupCalls, 1);
    expect(file.existsSync(), isFalse);
    expect(account.cleanupPending, isFalse);
    expect(account.unexpected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final beforeFirstBuild in [true, false]) {
    testWidgets('actual Session dialog outlives removed parent ${beforeFirstBuild ? 'before first build' : 'after opening'}',
        (tester) async {
      final account = await fixture(tester);
      final ticket = owners.capture(_alice);
      final visible = ValueNotifier<bool>(true);
      final locale = ValueNotifier<Locale>(const Locale('en'));
      var cleanupCalls = 0;
      addTearDown(visible.dispose);
      addTearDown(locale.dispose);
      await tester.pumpWidget(ValueListenableBuilder<Locale>(valueListenable: locale,
        builder: (context, value, child) => MaterialApp(locale: value,
          supportedLocales: const [Locale('en'), Locale('tr')],
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          home: ValueListenableBuilder<bool>(valueListenable: visible,
            builder: (context, show, child) => show ? MotionAccountPage(
              account: OwnerBoundMotionAccountClient(account, expectedOwner: ticket, owners: owners),
              paidFeaturesAvailable: false,
              clearLocalData: (_) async { cleanupCalls++; },
            ) : const Scaffold(body: Text('REPLACEMENT_PAGE')),
          ),
        ),
      ));
      await tester.ensureVisible(find.text('Delete Motion account'));
      await tester.tap(find.text('Delete Motion account'));
      if (!beforeFirstBuild) {
        await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isNotEmpty,
            'Dialog first build must be witnessed before parent removal.');
        await tester.pump(const Duration(milliseconds: 350));
      }
      visible.value = false;
      await tester.pump();
      locale.value = const Locale('tr');
      await _waitFor(tester, () => find.text('Motion hesabını sil').evaluate().isNotEmpty,
          'The retained dialog must rebuild in TR after its parent is disposed.');
      expect(find.byType(MotionAccountPage), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Motion hesabını sil'), findsOneWidget);
      expect(ticket.isActive, isTrue, reason: 'Mounted-parent refusal is independent of owner-ticket retirement.');
      expect(tester.takeException(), isNull);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
      await _waitFor(tester, () => find.byType(AlertDialog).evaluate().isEmpty,
          'The retained dialog must close without dispatch from its disposed parent.');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('REPLACEMENT_PAGE'), findsOneWidget);
      expect(account.deleteInvocations, 0);
      expect(cleanupCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
