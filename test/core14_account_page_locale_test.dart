import 'dart:async';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:choreia/app/theme/theme_preference.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_catalog.dart' show DiskBundle;

void main() {
  testWidgets('actual Choreia account error and cancel dialog use Arabic dark',
      (tester) async {
    await _exerciseAccountRoute(tester,
        locale: const Locale('ar'),
        mode: ThemeMode.dark,
        userId: '00000000-0000-4000-8000-000000000141');
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('actual Choreia account error and cancel dialog use Hindi light',
      (tester) async {
    await _exerciseAccountRoute(tester,
        locale: const Locale('hi'),
        mode: ThemeMode.light,
        userId: '00000000-0000-4000-8000-000000000142');
  }, timeout: const Timeout(Duration(seconds: 30)));
}

Future<void> _exerciseAccountRoute(WidgetTester tester,
    {required Locale locale,
    required ThemeMode mode,
    required String userId}) async {
  final fixtureZone = Zone.current;
  final fixture = _AccountPresentationFixture(userId);
  final locales = ChoreiaLocaleController.memory(locale);
  final themes = ChoreiaThemeController.memory(mode);
  _registerCleanup(tester, fixtureZone, fixture, locales, themes);
  tester.view.physicalSize = const Size(320, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Public proof path only. getUser is implemented by the local fake below.
  await fixture.runtime.refreshIdentity();
  fixture.expectVerified();
  expect(fixture.identityReads, 1);
  expect(fixture.profileReadStarts, 0);
  var generatedBuilderObserved = false;
  await tester.pumpWidget(MediaQuery.fromView(
    view: tester.view,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: ChoreiaApp(
          accountRuntime: fixture.runtime,
          localeController: locales,
          themeController: themes,
          localeBundle: DiskBundle(),
          shellBuilder: (environment, accountPageBuilder) {
            expect(accountPageBuilder, isNotNull,
                reason: 'Use the real builder created by ChoreiaApp');
            generatedBuilderObserved = true;
            return Scaffold(
                body: ProfileView(accountPageBuilder: accountPageBuilder));
          },
        ),
      ),
    ),
  ));
  final accountEntry = find.byKey(ProfileView.accountEntryKey);
  await _waitFor(tester, () => _readyInLocale(tester, accountEntry, locale),
      'The actual app profile must finish loading its locale resources');
  expect(generatedBuilderObserved, isTrue);
  _expectFallbackAndAppearance(tester.element(accountEntry), locale, mode);
  expect(fixture.profileReadStarts, 0);

  await _tap(tester, accountEntry);
  final pageFinder = find.byType(MotionAccountPage);
  final strings = MotionAccountLocalizations(locale);
  final profileError =
      find.text(strings.text(MotionAccountString.profileReadFailed));
  await _waitFor(
      tester,
      () =>
          pageFinder.evaluate().length == 1 &&
          _readyInLocale(tester, profileError, locale),
      'The generated account route must show the real Core profile read error');
  final pageElement = tester.element(pageFinder);
  final page = tester.widget<MotionAccountPage>(pageFinder);
  expect(page.account, isA<OwnerBoundMotionAccountClient>());
  expect(page.account.supabase, same(fixture.client));
  expect(page.paidFeaturesAvailable, isTrue); // sales open
  expect(page.clearLocalData, isNotNull);
  expect(page.initialPasswordRecovery, isFalse);
  expect(find.byType(MotionMembershipPage), findsNothing);
  // Sales are open: the localized membership entry is offered, not opened.
  expect(find.text(strings.text(MotionAccountString.membershipOptions)),
      findsOneWidget);
  expect(fixture.profileReadStarts, 1);
  _expectFallbackAndAppearance(tester.element(profileError), locale, mode);
  _expectUntouchedSaveDisabled(tester, strings);
  final currentTicket = appStoreOwners.currentTicket(userId);
  expect(currentTicket, isNotNull);
  final ticket = currentTicket!;
  expect(ticket.isActive, isTrue);

  final retry = find.widgetWithText(
      TextButton, strings.text(MotionAccountString.retryProfile));
  await _tap(tester, retry);
  await _waitFor(
      tester,
      () =>
          fixture.profileReadStarts == 2 &&
          _readyInLocale(tester, profileError, locale),
      'Profile Retry must start a separate read and report its controlled failure');
  expect(tester.element(pageFinder), same(pageElement));
  _expectUntouchedSaveDisabled(tester, strings);
  _expectFallbackAndAppearance(tester.element(profileError), locale, mode);
  expect(fixture.identityReads, 1,
      reason: 'Profile Retry must not silently become an identity refresh');

  await _tap(
      tester,
      find.widgetWithText(
          TextButton, strings.text(MotionAccountString.deleteMotionAccount)));
  final dialog = find.byType(AlertDialog);
  final explanation = find.descendant(
      of: dialog,
      matching: find.text(strings.text(MotionAccountString.deleteExplanation)));
  await _waitFor(
      tester,
      () =>
          dialog.evaluate().length == 1 &&
          _readyInLocale(tester, explanation, locale),
      'The actual Core confirmation dialog must open in the selected locale');
  expect(explanation, findsOneWidget);
  _expectFallbackAndAppearance(tester.element(explanation), locale, mode);
  final cancel = find.descendant(
      of: dialog,
      matching: find.widgetWithText(
          TextButton, strings.text(MotionAccountString.cancel)));
  await _tap(tester, cancel);
  await _waitFor(tester, () => dialog.evaluate().isEmpty,
      'Cancel must close the dialog without dispatch or local cleanup');
  expect(pageFinder, findsOneWidget);
  expect(tester.element(pageFinder), same(pageElement));
  expect(appStoreOwners.currentTicket(userId), same(ticket));
  expect(ticket.isActive, isTrue);
  expect(fixture.profileReadStarts, 2);
  fixture.expectVerified();
  fixture.expectNoUnexpectedEffects();
  expect(tester.takeException(), isNull);
}

bool _readyInLocale(WidgetTester tester, Finder finder, Locale locale) {
  if (finder.evaluate().length != 1) return false;
  final context = tester.element(finder);
  final messages = ChoreiaMessages.of(context);
  return Localizations.maybeLocaleOf(context) == locale &&
      messages.localeTag == ChoreiaLocaleController.tag(locale) &&
      !messages.translationUnavailable;
}

void _expectFallbackAndAppearance(
    BuildContext context, Locale locale, ThemeMode mode) {
  expect(Localizations.localeOf(context), locale);
  // Choreia's production delegates are deliberately untouched. A copied Core
  // MaterialApp/delegate harness would miss the consumer fallback contract.
  expect(
      Localizations.of<MotionAccountLocalizations>(
          context, MotionAccountLocalizations),
      isNull);
  expect(MotionAccountLocalizations.of(context).locale, locale);
  expect(Directionality.of(context),
      locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
  final actual = Theme.of(context);
  final expected =
      mode == ThemeMode.dark ? ChoreiaTheme.dark : ChoreiaTheme.light;
  expect(actual.brightness, expected.brightness);
  expect(actual.scaffoldBackgroundColor, expected.scaffoldBackgroundColor);
  expect(actual.colorScheme.primary, expected.colorScheme.primary);
}

void _expectUntouchedSaveDisabled(
    WidgetTester tester, MotionAccountLocalizations strings) {
  final save = find.widgetWithText(
      FilledButton, strings.text(MotionAccountString.saveProfile));
  expect(save, findsOneWidget);
  expect(tester.widget<FilledButton>(save).onPressed, isNull,
      reason: 'A failed read is not permission to overwrite an untouched name');
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget,
      reason: 'The real pointer target must be visible and hit-testable');
  await tester.tap(target.hitTestable());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  expect(tester.takeException(), isNull);
}

Future<void> _waitFor(
    WidgetTester tester, bool Function() ready, String witness) async {
  for (var turn = 0; turn < 120 && !ready(); turn++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull, reason: witness);
  }
  expect(ready(), isTrue, reason: witness);
  await tester.pump();
}

void _registerCleanup(
    WidgetTester tester,
    Zone fixtureZone,
    _AccountPresentationFixture fixture,
    ChoreiaLocaleController locales,
    ChoreiaThemeController themes) {
  addTearDown(() async {
    try {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      var drained = false;
      Object? drainError;
      StackTrace? drainStack;
      fixtureZone.run<void>(() {
        unawaited(appStoreOwners.retireOwner(fixture.user.id).then<void>((_) {
          drained = true;
        }, onError: (Object error, StackTrace stack) {
          drainError = error;
          drainStack = stack;
          drained = true;
        }));
      });
      for (var turn = 0; turn < 300 && !drained; turn++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 2)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(drained, isTrue,
          reason: 'The actual fixture owner must drain before the next test');
      final failure = drainError;
      if (failure != null) Error.throwWithStackTrace(failure, drainStack!);
      expect(appStoreOwners.currentTicket(fixture.user.id), isNull);
      fixture.expectNoUnexpectedEffects();
      expect(tester.takeException(), isNull);
    } finally {
      // The app is already unmounted; these objects belong to this fixture.
      fixture.runtime.dispose();
      locales.dispose();
      themes.dispose();
    }
  });
}

class _ExpectedProfileReadFailure implements Exception {
  const _ExpectedProfileReadFailure();
}

class _AccountPresentationFixture {
  _AccountPresentationFixture(String userId) {
    user = User(
      id: userId,
      appMetadata: const {},
      userMetadata: null,
      aud: 'authenticated',
      createdAt: '2026-10-20T00:00:00Z',
      email: 'presentation@example.invalid',
    );
    // Getter reads must retain this exact object, not rebuild equal Sessions.
    session = Session(
        accessToken: 'synthetic presentation token',
        tokenType: 'bearer',
        user: user);
    client = _PresentationSupabase(this);
    runtime = MotionAccountRuntime.forTesting(
      client: client,
      app: MotionApp.choreia,
      localAccountIds: () async => const <String>[],
      onDeletedAccount: (_) async {
        deletionCallbacks++;
        throw StateError('This presentation fixture cannot delete an account');
      },
    );
  }

  late final User user;
  late final Session session;
  late final _PresentationSupabase client;
  late final MotionAccountRuntime runtime;
  int identityReads = 0;
  int profileReadStarts = 0;
  int ageReadStarts = 0;
  int membershipReadStarts = 0;
  int deletionCallbacks = 0;
  final unexpected = <String>[];

  Never reject(String operation) {
    unexpected.add(operation);
    throw StateError('Unexpected fixture client operation: $operation');
  }

  void expectVerified() {
    expect(runtime.isDisposed, isFalse);
    expect(runtime.phase.value, MotionIdentityPhase.verified);
    expect(runtime.userId.value, user.id);
    expect(runtime.isCurrentSessionVerified, isTrue);
    expect(client.auth.currentSession, same(session));
  }

  void expectNoUnexpectedEffects() {
    expect(unexpected, isEmpty,
        reason:
            'Core catches read errors; an unexpected fake call must still fail');
    expect(deletionCallbacks, 0);
    expect(identityReads, 1);
  }
}

class _PresentationSupabase implements SupabaseClient {
  _PresentationSupabase(this.fixture) : _auth = _PresentationAuth(fixture);
  final _AccountPresentationFixture fixture;
  final _PresentationAuth _auth;

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'motion_age_declarations') {
      // Core 5832031 reads the age/consent state when the page opens. Answer
      // with the same controlled read failure; no transport is constructed.
      fixture.ageReadStarts++;
      throw const _ExpectedProfileReadFailure();
    }
    if (table != 'motion_profiles') return fixture.reject('from($table)');
    fixture.profileReadStarts++;
    // The actual Core loadProfile Future observes this controlled read failure.
    // No query builder, HTTP transport or mutation is constructed/dispatched.
    throw const _ExpectedProfileReadFailure();
  }

  @override
  FunctionsClient get functions {
    // Sales are open: the page reads the membership on open. Answer with the
    // same controlled read failure; no transport is constructed.
    fixture.membershipReadStarts++;
    throw const _ExpectedProfileReadFailure();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      fixture.reject('Supabase.${invocation.memberName}');
}

class _PresentationAuth implements GoTrueClient {
  _PresentationAuth(this.fixture);
  final _AccountPresentationFixture fixture;

  @override
  Session? get currentSession => fixture.session;

  @override
  User? get currentUser => fixture.user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream<AuthState>.empty();

  @override
  Future<UserResponse> getUser([String? jwt]) async {
    fixture.identityReads++;
    if (jwt != fixture.session.accessToken) {
      return fixture.reject('getUser with an unexpected captured token');
    }
    return UserResponse.fromJson(fixture.user.toJson());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      fixture.reject('Auth.${invocation.memberName}');
}
