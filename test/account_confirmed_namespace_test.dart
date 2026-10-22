import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/account_recovery_host.dart';
import 'package:choreia/app/course/media/lesson_media_playback.dart';
import 'package:choreia/app/course/media/lesson_media_slot.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:motion_account/motion_account.dart';
import 'package:motion_core/motion_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_catalog.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _pathProvider = MethodChannel('plugins.flutter.io/path_provider');

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
    _runtime?.dispose();
    await client.dispose();
    transport.close();
  }
}

final class _Camera implements PoseSource {
  final framesController = StreamController<PoseFrame>.broadcast();
  int starts = 0, stops = 0;
  Completer<void>? stopAck;
  @override
  Future<LiveState?> begin() async {
    starts++;
    return null;
  }

  @override
  Stream<PoseFrame> frames() => framesController.stream;
  @override
  Future<void> stop() async {
    stops++;
    await stopAck?.future;
  }
}

final class _CaptionBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
      Uint8List.fromList(utf8.encode(
          'WEBVTT - Motion locale=en\n\n00:00:00.000 --> 00:00:00.500\nWritten demonstration.\n')));
}

final class _Video implements LessonVideoHandle {
  int plays = 0, pauses = 0, closes = 0;
  Completer<void>? closeAck;
  @override
  final ValueNotifier<LessonVideoFrame> frame =
      ValueNotifier<LessonVideoFrame>(const LessonVideoFrame());
  @override
  Future<void> initialize() async {
    frame.value = const LessonVideoFrame(initialized: true);
  }

  @override
  Future<void> silence() async {}
  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> close() async {
    closes++;
    await closeAck?.future;
    frame.dispose();
  }

  @override
  Widget buildVideo() => const SizedBox(key: Key('namespace.video'));
}

enum _Transition { refresh, sameUuidSignIn, bobSignIn, guestSignOut }

void main() {
  for (final transition in _Transition.values) {
    testWidgets('real Core held deletion + ${transition.name} scopes camera and data',
        (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final directory = Directory.systemTemp.createTempSync('choreia-confirmed-');
      final controller = ChoreiaAccountHostController();
      final account = (await tester.runAsync(() async => _AccountFixture(controller)))!;
      final cameras = <_Camera>[];
      final cameraFactories = <AppStoreOwnerTicket, PoseSource Function()>{};
      final bundle = DeviceBundle(declaredReferences());
      ValueListenable<int>? epoch;
      Future<void>? deleting;
      Object? observedError;
      var locationRequests = 0;
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_pathProvider, (call) async {
        if (call.method != 'getApplicationSupportDirectory') {
          throw StateError('Unexpected path-provider method.');
        }
        locationRequests++;
        if (transition == _Transition.refresh || transition == _Transition.sameUuidSignIn) {
          // Actual main callback notified resources before asking for a path.
          expect(controller.requiresAccountRoute, isTrue);
          expect(cameras.where((camera) => camera.starts > 0).last.stops, 1);
        }
        return directory.path;
      });
      addTearDown(() async {
        for (final camera in cameras) {
          if (camera.stopAck?.isCompleted == false) camera.stopAck!.complete();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        var streamsClosed = false;
        unawaited(Future.wait<void>([
          for (final camera in cameras) camera.framesController.close(),
        ]).then<void>((_) => streamsClosed = true));
        for (var i = 0; i < 80 && !streamsClosed; i++) {
          await tester.pump(const Duration(milliseconds: 25));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        }
        expect(streamsClosed, isTrue, reason: 'All actual frame subscriptions must drain before teardown.');
        debugPrint('namespace fixture: frame teardown drained');
        await tester.runAsync(() async {
          account.acknowledge();
          if (deleting != null) {
            try { await deleting!.timeout(const Duration(seconds: 2)); } catch (_) {}
          }
          await account.close().timeout(const Duration(seconds: 2));
        });
        var ownersDrained = false;
        Object? ownersError;
        unawaited(Future.wait<void>([
          for (final id in <String?>[_alice, _bob, null]) appStoreOwners.retireOwner(id),
        ]).then<void>((_) => ownersDrained = true,
            onError: (Object error, StackTrace _) {
              ownersError = error;
              ownersDrained = true;
            }));
        for (var i = 0; i < 80 && !ownersDrained; i++) {
          await tester.pump(const Duration(milliseconds: 25));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        }
        expect(ownersDrained, isTrue, reason: 'Each source owner must drain in its live test zone before the next fixture.');
        expect(ownersError, isNull);
        expect(appStoreOwners.retirementBarrier, isNull);
        messenger.setMockMethodCallHandler(_pathProvider, null);
        directory.deleteSync(recursive: true);
      });
      final previousDrain = appStoreOwners.retirementBarrier;
      if (previousDrain != null) {
        await tester.runAsync(() => previousDrain.timeout(const Duration(seconds: 2)));
      }
      await tester.runAsync(account.initialize);
      final aliceJournal = sessionFileFor(directory, _alice)..writeAsStringSync('A old');
      final aliceTmp = File('${aliceJournal.path}.tmp')..writeAsStringSync('A tmp');
      final course = File('${directory.path}/${SalsaProgressStore.fileNameFor(_alice)}')
        ..writeAsStringSync('A course');
      final courseTmp = File('${course.path}.tmp')..writeAsStringSync('A course tmp');
      final guest = sessionFileFor(directory, null)..writeAsStringSync('guest');
      final bob = sessionFileFor(directory, _bob)..writeAsStringSync('B');
      final protected = <File, String>{guest: 'guest', bob: 'B'};
      for (final id in <String?>[null, _bob]) {
        final label = id == null ? 'guest' : 'B';
        final journal = sessionFileFor(directory, id);
        final progress = File('${directory.path}/${SalsaProgressStore.fileNameFor(id)}');
        protected[File('${journal.path}.tmp')] = '$label journal tmp';
        protected[progress] = '$label course';
        protected[File('${progress.path}.tmp')] = '$label course tmp';
      }
      for (final entry in protected.entries) {
        entry.key.writeAsStringSync(entry.value);
      }
      await tester.pumpWidget(MotionIdentityGate(runtime: account.runtime, child: ChoreiaApp(
        accountRuntime: account.runtime,
        accountHostController: controller,
        shellBuilder: (environment, accountBuilder) {
          epoch = environment.ownerEpoch;
          final ticket = appStoreOwners.currentTicket(environment.accountUserId?.value)!;
          final sourceFactory = cameraFactories.putIfAbsent(ticket, () {
            final camera = _Camera();
            cameras.add(camera);
            return () => camera;
          });
          return Scaffold(body: Stack(children: <Widget>[
            LiveLessonPage(stepId: 'hh_bounce', lessonId: 'hh_l1_bounce',
                lessonClass: 'demoOnly', styleId: 'hip_hop_foundations',
                env: LiveEnvironment(bundle: bundle, source: sourceFactory,
                    accountUserId: environment.accountUserId,
                    passwordRecovery: environment.passwordRecovery,
                    ownerEpoch: environment.ownerEpoch)),
            Positioned(right: 0, top: 0, child: Builder(builder: (context) =>
                TextButton(onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: accountBuilder!)),
                    child: const Text('Open source account')))),
          ]));
        },
      )));
      for (var i = 0; i < 80 && cameras.where((camera) => camera.starts > 0).isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 25));
      }
      expect(cameras.where((camera) => camera.starts > 0), hasLength(1),
          reason: 'Actual verified owner must admit its first source before a transition.');
      final activeCamera = cameras.first;
      if (transition == _Transition.refresh) {
        activeCamera.stopAck = (await tester.runAsync(() async => Completer<void>()))!;
      }
      final initialEpoch = epoch!.value;
      await tester.tap(find.text('Open source account'));
      for (var i = 0; i < 40 && find.byType(MotionAccountPage).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(MotionAccountPage), findsOneWidget,
          reason: 'Current admitted owner account route must open before deletion.');
      final page = tester.widget<MotionAccountPage>(find.byType(MotionAccountPage));
      await tester.runAsync(() async {
        deleting = page.account.deleteCommonAccount(afterRemoteDelete: (id) async {
          try { await page.clearLocalData!(id); }
          catch (error, stack) {
            account.cleanupError = error;
            Error.throwWithStackTrace(error, stack);
          }
        });
        unawaited(deleting!.catchError((Object error) { observedError = error; }));
        await account.entered.future.timeout(const Duration(seconds: 2));
        switch (transition) {
          case _Transition.refresh: await account.refresh(); break;
          case _Transition.sameUuidSignIn: await account.signIn(_alice); break;
          case _Transition.bobSignIn: await account.signIn(_bob); break;
          case _Transition.guestSignOut:
            await account.client.auth.signOut(scope: SignOutScope.local);
            break;
        }
      });
      debugPrint('namespace fixture: transition completed');
      expect(account.deletes, 1);
      expect(cameras.first.stops, transition == _Transition.refresh ? 0 : 1);
      expect(epoch!.value, transition == _Transition.refresh ? initialEpoch : greaterThan(initialEpoch));
      await tester.pump(const Duration(milliseconds: 350));
      if (transition != _Transition.refresh) {
        for (var i = 0; i < 80 && cameras.where((camera) => camera.starts > 0).length < 2; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(cameras.where((camera) => camera.starts > 0), hasLength(2));
        expect(cameras.where((camera) => camera.starts > 0).last.starts, 1);
      }
      debugPrint('namespace fixture: successor admission observed');
      final beforeReceiptEpoch = epoch!.value;
      final beforeReceiptLogouts = account.logouts;
      if (transition == _Transition.sameUuidSignIn) {
        aliceJournal.writeAsStringSync('fresh A in E+1 is the same namespace');
      }
      if (transition == _Transition.refresh) {
        var settled = false;
        unawaited(deleting!.whenComplete(() => settled = true).catchError((Object _) {}));
        account.acknowledge();
        for (var i = 0; i < 40 && (!appStoreOwners.isErasing(_alice) || activeCamera.stops == 0); i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          await tester.pump(const Duration(milliseconds: 25));
        }
        expect(activeCamera.stops, 1);
        expect(settled, isFalse, reason: 'Confirmed deletion must await actual source close ACK.');
        expect(aliceJournal.existsSync(), isTrue);
        expect(appStoreOwners.isErasing(_alice), isTrue,
            reason: 'The exact namespace stays quarantined even if Core replaced its host shell.');
        expect(() => appStoreOwners.capture(_alice),
            throwsA(isA<SessionStoreRetiredException>()));
        expect(cameras.where((camera) => camera.starts > 0), hasLength(1),
            reason: 'No successor capture before the old source closes.');
        activeCamera.stopAck!.complete();
      }
      account.acknowledge();
      var deletionSettled = false;
      Object? deletionError;
      unawaited(deleting!.then<void>((_) => deletionSettled = true,
          onError: (Object error, StackTrace _) {
            deletionError = error;
            deletionSettled = true;
          }));
      for (var i = 0; i < 120 && !deletionSettled; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 25));
      }
      debugPrint('namespace fixture: receipt drain observed');
      expect(deletionSettled, isTrue, reason: 'Deletion ACK and resource/data drains must settle.');
      expect(deletionError, isNull);

      expect(account.cleanupError, isNull, reason: 'Report the exact local cleanup failure before the Core wrapper.');
      expect(observedError, isNull);
      expect(account.unexpected, isEmpty);
      expect(locationRequests, 1);
      expect(aliceJournal.existsSync(), isFalse);
      expect(aliceTmp.existsSync(), isFalse);
      expect(course.existsSync(), isFalse);
      expect(courseTmp.existsSync(), isFalse);
      expect(guest.readAsStringSync(), 'guest');
      expect(bob.readAsStringSync(), 'B');
      for (final entry in protected.entries) {
        expect(entry.key.readAsStringSync(), entry.value);
      }
      expect(account.logouts, beforeReceiptLogouts,
          reason: 'The host data/resource fence never signs out current Auth.');
      expect(account.runtime.passwordRecovery.value, isFalse);
      if (transition == _Transition.refresh || transition == _Transition.sameUuidSignIn) {
        expect(epoch!.value, greaterThan(beforeReceiptEpoch));
        expect(cameras.where((camera) => camera.starts > 0).last.stops, 1);
        expect(controller.requiresAccountRoute, isTrue);
        expect(account.client.auth.currentSession?.accessToken, 'local-fixture-token-2');
        expect(account.runtime.phase.value, MotionIdentityPhase.verified);
      } else {
        expect(epoch!.value, beforeReceiptEpoch);
        expect(cameras.last.stops, 0);
        expect(controller.requiresAccountRoute, isFalse);
        expect(account.client.auth.currentUser?.id,
            transition == _Transition.bobSignIn ? _bob : isNull);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      if (controller.requiresAccountRoute) {
        expect(find.byType(LiveLessonPage), findsNothing);
        expect(find.byType(MotionAccountPage), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('real main refresh receipt retires video admission before a stale play action',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final directory = Directory.systemTemp.createTempSync('choreia-confirmed-video-');
    final controller = ChoreiaAccountHostController();
    final account = (await tester.runAsync(() async => _AccountFixture(controller)))!;
    final video = _Video()
      ..closeAck = (await tester.runAsync(() async => Completer<void>()))!;
    final captionBundle = _CaptionBundle();
    LessonVideoHandle videoFactory(String assetPath, String captionText) => video;
    Future<void>? deleting;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_pathProvider, (call) async {
      if (call.method != 'getApplicationSupportDirectory') throw StateError('Unexpected path method.');
      expect(controller.requiresAccountRoute, isTrue);
      expect(video.pauses, 1);
      return directory.path;
    });
    addTearDown(() async {
      if (video.closeAck?.isCompleted == false) video.closeAck!.complete();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        account.acknowledge();
        if (deleting != null) { try { await deleting!.timeout(const Duration(seconds: 2)); } catch (_) {} }
        await account.close();
        await appStoreOwners.retireOwner(_alice);
      });
      messenger.setMockMethodCallHandler(_pathProvider, null);
      directory.deleteSync(recursive: true);
    });
    await tester.runAsync(account.initialize);
    await tester.pumpWidget(MotionIdentityGate(runtime: account.runtime, child: ChoreiaApp(
      accountRuntime: account.runtime, accountHostController: controller,
      shellBuilder: (environment, accountBuilder) => Scaffold(body: Column(children: <Widget>[
        LessonMediaSlot.testingPlayback(lessonId: 'so_01', locale: 'en',
            fixture: const LessonMediaPlaybackFixture(lessonId: 'so_01',
                videoAssetPath: 'local-only.mp4',
                captionAssetPaths: <String, String>{'en': 'local-only.en.vtt'}),
            bundle: captionBundle, accountUserId: environment.accountUserId,
            passwordRecovery: environment.passwordRecovery,
            ownerEpoch: environment.ownerEpoch, videoFactory: videoFactory),
        Builder(builder: (context) => TextButton(onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: accountBuilder!)),
            child: const Text('Open source account'))),
      ])),
    )));
    final toggle = find.byKey(const Key('choreia.mediaPlaybackToggle'));
    bool playbackReady() => toggle.evaluate().isNotEmpty &&
        tester.widget<TextButton>(toggle).onPressed != null;
    for (var i = 0; i < 80 && !playbackReady(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(playbackReady(), isTrue,
        reason: 'Actual verified owner must admit the fixture video before retaining its action.');
    final stalePlay = tester.widget<TextButton>(
        find.byKey(const Key('choreia.mediaPlaybackToggle'))).onPressed!;
    await tester.ensureVisible(find.text('Open source account'));
    await tester.tap(find.text('Open source account'));
    for (var i = 0; i < 40 && find.byType(MotionAccountPage).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(find.byType(MotionAccountPage), findsOneWidget);
    final page = tester.widget<MotionAccountPage>(find.byType(MotionAccountPage));
    await tester.runAsync(() async {
      deleting = page.account.deleteCommonAccount(afterRemoteDelete: (id) async {
          try { await page.clearLocalData!(id); }
          catch (error, stack) {
            account.cleanupError = error;
            Error.throwWithStackTrace(error, stack);
          }
        });
      unawaited(deleting!.catchError((Object _) {}));
      await account.entered.future.timeout(const Duration(seconds: 2));
      await account.refresh();
    });
    expect(video.pauses, 0);
    account.acknowledge();
    var receiptSettled = false;
    Object? receiptError;
    unawaited(deleting!.then<void>((_) => receiptSettled = true,
        onError: (Object error, StackTrace _) {
          receiptError = error;
          receiptSettled = true;
        }));
    for (var i = 0; i < 40 && video.closes == 0; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(video.pauses, 1);
    expect(video.closes, 1);
    expect(receiptSettled, isFalse, reason: 'Video close ACK is part of confirmed account cleanup.');
    expect(appStoreOwners.isErasing(_alice), isTrue);
    expect(() => appStoreOwners.capture(_alice), throwsA(isA<SessionStoreRetiredException>()));
    stalePlay();
    expect(video.plays, 0);
    video.closeAck!.complete();
    for (var i = 0; i < 120 && !receiptSettled; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(receiptSettled, isTrue);
    expect(account.cleanupError, isNull);
    expect(receiptError, isNull);
    stalePlay(); // Retained old callback must remain closed after receipt drainage.
    expect(video.plays, 0);
    expect(account.unexpected, isEmpty);
    expect(account.logouts, 0);
    expect(account.client.auth.currentSession?.accessToken, 'local-fixture-token-2');
    for (var i = 0; i < 12; i++) { await tester.pump(); }
    expect(video.pauses, 1);
    expect(video.closes, 1);
    expect(find.byType(LessonMediaPlayback), findsNothing);
    expect(find.byType(MotionAccountPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
