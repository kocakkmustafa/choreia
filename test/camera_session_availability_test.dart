import 'dart:async';
import 'dart:io';

import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:motion_account/motion_account.dart';
import 'package:motion_core/motion_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/round_trip_store.dart';
import 'support/test_catalog.dart';

class _CountingSource implements PoseSource {
  int starts = 0;
  @override
  Future<LiveState?> begin() async {
    starts++;
    return null;
  }

  @override
  Stream<PoseFrame> frames() => const Stream<PoseFrame>.empty();
  @override
  Future<void> stop() async {}
}

void main() {
  late LibraryCatalog library;
  setUpAll(() async =>
      library = await LibraryCatalog.load(DeviceBundle(declaredReferences())));
  const lessonId = 'hh_l1_bounce';
  final startKey = StyleDetailView.lessonStartKey(lessonId);
  final unavailableKey = StyleDetailView.sessionUnavailableKey(lessonId);

  void phone(WidgetTester tester, String language) {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localeTestValue = Locale(language);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump();
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  for (final language in ['en', 'tr']) {
    for (final available in [false, true]) {
      for (final reference in [false, true]) {
        testWidgets(
            '$language: session $available, reference $reference remain independent',
            (tester) async {
          phone(tester, language);
          var checks = 0, permissions = 0, factories = 0;
          final source = _CountingSource();
          await tester.pumpWidget(MaterialApp(
              home: StyleDetailView(
            card: library.cardFor('hip_hop_foundations')!,
            runnableSteps: reference ? const {'hh_bounce'} : const {},
            cameraSessionsAvailable: available,
            beforeStart: (_) async {
              checks++;
              return true;
            },
            env: LiveEnvironment(
                bundle: DeviceBundle(declaredReferences()),
                storeOpener: () async => RoundTripStore(),
                cameraPermissionRequest: () async {
                  permissions++;
                  return true;
                },
                source: () {
                  factories++;
                  return source;
                }),
          )));
          await reveal(tester, find.byKey(StyleDetailView.lessonKey(lessonId)));
          final card = find.byKey(StyleDetailView.lessonKey(lessonId));
          if (available && reference) {
            expect(find.byKey(startKey), findsOneWidget);
            expect(
                find.descendant(
                    of: card,
                    matching: find.text(language == 'tr'
                        ? 'CANLI PRATİK · PUAN YOK'
                        : 'LIVE PRACTICE · NO SCORING')),
                findsOneWidget);
            expect(
                find.descendant(
                    of: card,
                    matching: find.textContaining(language == 'tr'
                        ? 'cihazında kamera izni ister'
                        : 'requests camera permission on your device')),
                findsOneWidget);
            expect(find.textContaining('unavailable in this release'),
                findsNothing);
          } else {
            expect(find.byKey(startKey), findsNothing);
            if (reference) {
              expect(find.byKey(unavailableKey), findsOneWidget);
              expect(
                  find.descendant(
                      of: card,
                      matching: find.textContaining(language == 'tr'
                          ? 'Bu sürümde kamera pratiği kullanılamıyor'
                          : 'Camera practice is unavailable in this release')),
                  findsOneWidget);
            } else {
              expect(find.byKey(unavailableKey), findsNothing);
              expect(
                  find.descendant(
                      of: card,
                      matching: find.textContaining(language == 'tr'
                          ? 'Bu dersin hareket referansı hazırlanmadı'
                          : 'movement reference behind this lesson')),
                  findsOneWidget);
            }
          }
          expect(
              find.descendant(
                  of: card, matching: find.textContaining('PREVIEW')),
              findsNothing);
          expect(checks, 0);
          expect(permissions, 0);
          expect(factories, 0);
          expect(source.starts, 0);
          expect(find.byType(LiveLessonPage), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final access in [(false, false), (true, false), (true, true)]) {
      final (permitted, permissionGranted) = access;
      testWidgets(
          '$language: future capability retains access and permission ordering (access=$permitted, permission=$permissionGranted)',
          (tester) async {
        phone(tester, language);
        var checks = 0, permissions = 0;
        final grant = Completer<bool>();
        final source = _CountingSource();
        await tester.pumpWidget(MaterialApp(
            home: StyleDetailView(
          card: library.cardFor('hip_hop_foundations')!,
          runnableSteps: const {'hh_bounce'},
          cameraSessionsAvailable: true,
          beforeStart: (_) async {
            checks++;
            return permitted;
          },
          env: LiveEnvironment(
              bundle: DeviceBundle(declaredReferences()),
              source: () => source,
              storeOpener: () async => RoundTripStore(),
              permanentlyDeniedProbe: () async => false,
              cameraPermissionRequest: () {
                permissions++;
                return grant.future;
              }),
        )));
        await reveal(tester, find.byKey(startKey));
        await tester.tap(find.byKey(startKey));
        for (var i = 0;
            i < 20 && (permitted ? permissions == 0 : checks == 0);
            i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(milliseconds: 500));
        expect(checks, 1);
        expect(source.starts, 0);
        if (permitted) {
          expect(find.byType(LiveLessonPage), findsOneWidget);
          expect(permissions, 1);
          grant.complete(permissionGranted);
          for (var i = 0; i < 20 && source.starts == 0; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(source.starts, permissionGranted ? 1 : 0);
        } else {
          expect(find.byType(LiveLessonPage), findsNothing);
          expect(permissions, 0);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final language in ['en', 'tr']) {
    for (final available in [false, true]) {
      testWidgets(
          '$language: fresh intro, library and configured profile agree ($available)',
          (tester) async {
        phone(tester, language);
        var permissions = 0;
        await tester.pumpWidget(MaterialApp(
            home: ChoreiaShell(
          cameraSessionsAvailable: available,
          bundleOverride: () async => library,
          flagOverride: MemoryFirstRunFlag(),
          accountPageBuilder: (_) =>
              const Scaffold(body: Text('local account fixture')),
          env: LiveEnvironment(
              storeOpener: () async => RoundTripStore(),
              cameraPermissionRequest: () async {
                permissions++;
                return true;
              }),
        )));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
            tester
                .widget<FirstRunView>(find.byType(FirstRunView))
                .cameraSessionsAvailable,
            available);
        await reveal(tester, find.byKey(FirstRunView.cameraKey));
        final cameraText = tester
            .widgetList<Text>(find.descendant(
                of: find.byKey(FirstRunView.cameraKey),
                matching: find.byType(Text)))
            .map((text) => text.data ?? '')
            .join(' ');
        expect(
            cameraText,
            contains(available
                ? (language == 'tr'
                    ? 'cihaz izni ve erişim kontrolü'
                    : 'device permission and access checks')
                : (language == 'tr'
                    ? 'canlı kamera pratiği ve abonelik satışı kapalıdır'
                    : 'Live camera practice and subscription sales are closed')));
        if (available) {
          expect(
              cameraText,
              contains(language == 'tr'
                  ? 'Abonelik satışı kapalı kalır'
                  : 'Subscription sales remain closed'));
          expect(
              cameraText,
              isNot(contains(language == 'tr'
                  ? 'canlı kamera pratiği ve abonelik satışı kapalıdır'
                  : 'Live camera practice and subscription sales are closed')));
        }
        await reveal(tester, find.byKey(FirstRunView.stateKey));
        final stateText = tester
            .widgetList<Text>(find.descendant(
                of: find.byKey(FirstRunView.stateKey),
                matching: find.byType(Text)))
            .map((text) => text.data ?? '')
            .join(' ');
        expect(
            stateText,
            contains(language == 'tr'
                ? 'kamera seansı referans notları'
                : 'camera-session reference notes'));
        expect(stateText, isNot(contains('with lesson previews')));
        expect(stateText, isNot(contains('ders ön izlemesi var')));
        expect(
            stateText,
            contains(available
                ? (language == 'tr'
                    ? 'cihaz izni ve erişim kontrolü'
                    : 'device permission and access checks')
                : (language == 'tr'
                    ? 'oynatılabilir bir önizleme değildir'
                    : 'not a playable preview')));
        await tester.tap(find.byKey(FirstRunView.continueKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
            tester
                .widget<LibraryView>(find.byType(LibraryView))
                .cameraSessionsAvailable,
            available);
        await tester.tap(find.byKey(ChoreiaShell.profileTabKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
            tester
                .widget<ProfileView>(find.byType(ProfileView))
                .cameraSessionsAvailable,
            available);
        expect(
            find.textContaining(available
                ? (language == 'tr'
                    ? 'cihaz izni ve erişim kontrolü'
                    : 'device permission and access checks')
                : (language == 'tr'
                    ? 'canlı kamera pratiği ve abonelik satışı kapalıdır'
                    : 'Live camera practice and subscription sales are closed')),
            findsOneWidget);
        expect(find.byKey(ProfileView.accountEntryKey), findsOneWidget);
        expect(find.byKey(ProfileView.licensesEntryKey), findsOneWidget);
        expect(permissions, 0);
        expect(find.byType(LiveLessonPage), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
      testWidgets(
          '$language: profile fallback describes the same session state ($available)',
          (tester) async {
        phone(tester, language);
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: ProfileView(
          cameraSessionsAvailable: available,
        ))));
        final text = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data ?? '')
            .join(' ');
        expect(
            text,
            contains(available
                ? (language == 'tr'
                    ? 'cihaz izni ve erişim kontrolü'
                    : 'device permission and access checks')
                : (language == 'tr'
                    ? 'canlı kamera pratiği ve abonelik satışı kapalıdır'
                    : 'Live camera practice and subscription sales are closed')));
        expect(find.byKey(ProfileView.licensesEntryKey), findsOneWidget);
        expect(find.byKey(ProfileView.accountEntryKey), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final user in <String?>[null, 'local-active-member']) {
    testWidgets(
        'closed production policy cannot be overridden by account/access callback ($user)',
        (tester) async {
      var checks = 0, permissions = 0, factories = 0;
      final identity = ValueNotifier<String?>(user);
      addTearDown(identity.dispose);
      expect(motionPaidFeaturesAvailable, isFalse);
      await tester.pumpWidget(MaterialApp(
          home: StyleDetailView(
        card: library.cardFor('hip_hop_foundations')!,
        runnableSteps: const {'hh_bounce'},
        cameraSessionsAvailable: motionPaidFeaturesAvailable,
        beforeStart: (_) async {
          checks++;
          return true;
        },
        env: LiveEnvironment(
            accountUserId: identity,
            cameraPermissionRequest: () async {
              permissions++;
              return true;
            },
            source: () {
              factories++;
              return _CountingSource();
            }),
      )));
      await reveal(tester, find.byKey(unavailableKey));
      expect(find.byKey(startKey), findsNothing);
      expect(find.byType(LiveLessonPage), findsNothing);
      expect(checks, 0);
      expect(permissions, 0);
      expect(factories, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'configured production app binds session UI to pinned false policy without provider calls',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('choreia_release_host_');
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(paths, (_) async => dir.path);
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(paths, null);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    var requests = 0;
    final client = (await tester.runAsync(() async => SupabaseClient(
            'https://release-fixture.example.invalid',
            'public-local-fixture-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
            httpClient: MockClient((_) async {
          requests++;
          throw StateError('Provider calls forbidden');
        }))))!;
    final runtime = MotionAccountRuntime.forTesting(
        client: client, app: MotionApp.choreia, onDeletedAccount: (_) async {});
    await runtime.refreshIdentity();
    await tester.pumpWidget(MotionIdentityGate(
        runtime: runtime, child: ChoreiaApp(accountRuntime: runtime)));
    await tester.pump();
    expect(find.byType(ChoreiaShell), findsOneWidget);
    expect(
        tester
            .widget<ChoreiaShell>(find.byType(ChoreiaShell))
            .cameraSessionsAvailable,
        isFalse);
    expect(requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    runtime.dispose();
    await tester.runAsync(client.dispose);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'closed shell forwards status through catalogue and keeps written course entry',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ChoreiaShell(
      bundleOverride: () async => library,
      flagOverride: MemoryFirstRunFlag(seen: true),
      env: LiveEnvironment(storeOpener: () async => RoundTripStore()),
    )));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final view = tester.widget<LibraryView>(find.byType(LibraryView));
    expect(view.cameraSessionsAvailable, isFalse);
    expect(find.textContaining('Camera practice and scoring are unavailable'),
        findsWidgets);
    expect(find.textContaining('Start camera practice'), findsNothing);
    await reveal(tester, find.byKey(const Key('salsa.open')));
    await tester.tap(find.byKey(const Key('salsa.open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SalsaCoursePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
