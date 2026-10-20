// Exercises only the real Core terminal-error blocker with no live client.
// Pending/Retry, successful admission, native AT and admitted child State are separate.
import 'dart:async';

import 'package:choreia/app/account_identity_appearance.dart';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/theme.dart';
import 'package:choreia/app/theme/theme_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_account/motion_account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _adapterKey = ValueKey<String>('test.identity.appearance');

void main() {
  testWidgets(
      'real closed Core blocker uses explicit app Arabic and dark theme',
      (tester) async {
    final fixture = _ClosedFixture();
    final locales = _TrackedLocales(const Locale('ar'));
    final themes = _TrackedThemes(ThemeMode.dark);
    _tearDownFixture(tester, fixture, [locales], [themes]);
    _narrowView(tester);

    await tester.pumpWidget(_adapter(fixture, locales, themes));
    await tester.pumpAndSettle();

    _expectClosedBlocker(tester, fixture,
        locale: const Locale('ar'), brightness: Brightness.dark);
    expect(locales.liveListeners, 1);
    expect(themes.liveListeners, 1);
  });

  testWidgets(
      'live locale and theme keep the same closed gate runtime and child',
      (tester) async {
    final fixture = _ClosedFixture();
    final locales = _TrackedLocales(const Locale('tr'));
    final themes = _TrackedThemes(ThemeMode.light);
    _tearDownFixture(tester, fixture, [locales], [themes]);
    _narrowView(tester);

    await tester.pumpWidget(_adapter(fixture, locales, themes));
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('tr'), brightness: Brightness.light);
    final gateElement = tester.element(find.byType(MotionIdentityGate));

    await locales.select(const Locale('ar'), persist: false);
    await themes.select(ThemeMode.dark);
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('ar'), brightness: Brightness.dark);
    expect(tester.element(find.byType(MotionIdentityGate)), same(gateElement));

    await locales.select(const Locale('ja'), persist: false);
    await themes.select(ThemeMode.light);
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('ja'), brightness: Brightness.light);
    expect(tester.element(find.byType(MotionIdentityGate)), same(gateElement));
    expect(locales.liveListeners, 1);
    expect(themes.liveListeners, 1);
  });

  testWidgets('raw System follows the full ordered OS list and skips Hant',
      (tester) async {
    final fixture = _ClosedFixture();
    final locales = _TrackedLocales(null);
    final themes = _TrackedThemes(ThemeMode.system);
    _tearDownFixture(tester, fixture, [locales], [themes]);
    _narrowView(tester);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    tester.platformDispatcher.localesTestValue = const [
      Locale('xx'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      Locale('fr'),
    ];

    await tester.pumpWidget(_adapter(fixture, locales, themes));
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('fr'), brightness: Brightness.light);
    final gateElement = tester.element(find.byType(MotionIdentityGate));
    expect(locales.value, isNull);

    tester.platformDispatcher.localesTestValue = const [
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      Locale('ar'),
    ];
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('ar'), brightness: Brightness.dark);
    expect(locales.value, isNull);
    expect(themes.value, ThemeMode.system);
    expect(tester.element(find.byType(MotionIdentityGate)), same(gateElement));

    await locales.select(const Locale('hi'), persist: false);
    await tester.pumpAndSettle();
    tester.platformDispatcher.localesTestValue = const [
      Locale('de'),
      Locale('ar'),
    ];
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('hi'), brightness: Brightness.dark);
    expect(locales.value, const Locale('hi'));

    await locales.select(null, persist: false);
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('de'), brightness: Brightness.dark);
    expect(locales.value, isNull);

    tester.platformDispatcher.localesTestValue = const [
      Locale('xx'),
      Locale('zh', 'TW'),
    ];
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('en'), brightness: Brightness.dark);
    expect(locales.value, isNull);
    expect(tester.element(find.byType(MotionIdentityGate)), same(gateElement));
  });

  testWidgets(
      'controller replacement detaches old listeners and unmount detaches new',
      (tester) async {
    final fixture = _ClosedFixture();
    final oldLocales = _TrackedLocales(const Locale('tr'));
    final oldThemes = _TrackedThemes(ThemeMode.light);
    final newLocales = _TrackedLocales(const Locale('ar'));
    final newThemes = _TrackedThemes(ThemeMode.dark);
    _tearDownFixture(
        tester, fixture, [oldLocales, newLocales], [oldThemes, newThemes]);
    _narrowView(tester);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(_adapter(fixture, oldLocales, oldThemes));
    await tester.pumpAndSettle();
    final gateElement = tester.element(find.byType(MotionIdentityGate));
    expect(oldLocales.liveListeners, 1);
    expect(oldThemes.liveListeners, 1);

    await tester.pumpWidget(_adapter(fixture, newLocales, newThemes));
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('ar'), brightness: Brightness.dark);
    expect(tester.element(find.byType(MotionIdentityGate)), same(gateElement));
    expect(oldLocales.liveListeners, 0);
    expect(oldThemes.liveListeners, 0);
    expect(newLocales.liveListeners, 1);
    expect(newThemes.liveListeners, 1);
    expect(oldLocales.disposeCalls, 0);
    expect(oldThemes.disposeCalls, 0);

    await oldLocales.select(const Locale('ja'), persist: false);
    await oldThemes.select(ThemeMode.light);
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('ar'), brightness: Brightness.dark);

    await newLocales.select(const Locale('fr'), persist: false);
    await newThemes.select(ThemeMode.light);
    await tester.pumpAndSettle();
    _expectClosedBlocker(tester, fixture,
        locale: const Locale('fr'), brightness: Brightness.light);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(find.byType(MotionIdentityGate), findsNothing);
    expect(newLocales.liveListeners, 0);
    expect(newThemes.liveListeners, 0);
    expect(newLocales.disposeCalls, 0);
    expect(newThemes.disposeCalls, 0);

    // Exercise stale sources after unmount; listener counts above are the
    // detach evidence, not merely absence of a mounted-setState exception.
    await oldLocales.select(null, persist: false);
    await newLocales.select(null, persist: false);
    await newThemes.select(ThemeMode.dark);
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    await tester.pump();
    expect(tester.takeException(), isNull);
    fixture.expectNoEffects();
  });
}

Widget _adapter(_ClosedFixture fixture, ChoreiaLocaleController locales,
        ChoreiaThemeController themes) =>
    ChoreiaIdentityAppearance(
      key: _adapterKey,
      runtime: fixture.runtime,
      locales: locales,
      themes: themes,
      child: fixture.child,
    );

void _narrowView(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _tearDownFixture(WidgetTester tester, _ClosedFixture fixture,
    List<_TrackedLocales> locales, List<_TrackedThemes> themes) {
  addTearDown(() async {
    // Unmount before disposing externally owned presentation controllers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    for (final controller in locales) {
      expect(controller.liveListeners, 0);
      expect(controller.disposeCalls, 0);
      controller.dispose();
    }
    for (final controller in themes) {
      expect(controller.liveListeners, 0);
      expect(controller.disposeCalls, 0);
      controller.dispose();
    }
    fixture.runtime.dispose(); // Core's public disposal is idempotent.
    fixture.expectNoEffects();
    expect(tester.takeException(), isNull);
  });
}

void _expectClosedBlocker(WidgetTester tester, _ClosedFixture fixture,
    {required Locale locale, required Brightness brightness}) {
  final gateFinder = find.byType(MotionIdentityGate);
  expect(gateFinder, findsOneWidget);
  final gate = tester.widget<MotionIdentityGate>(gateFinder);
  expect(gate.runtime, same(fixture.runtime));
  expect(gate.child, same(fixture.child));
  expect(gate.key, isNull);
  expect(gate.locale, locale);
  expect(gate.theme!.brightness, Brightness.light);
  expect(gate.darkTheme!.brightness, Brightness.dark);

  final expected = MotionAccountLocalizations(locale)
      .text(MotionAccountString.accountVerificationFailed);
  final message = find.text(expected);
  expect(message, findsOneWidget);
  final context = tester.element(message);
  expect(Localizations.localeOf(context), locale);
  expect(MotionAccountLocalizations.of(context).locale, locale);
  expect(Directionality.of(context),
      locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr);
  final theme = Theme.of(context);
  final appTheme =
      brightness == Brightness.dark ? ChoreiaTheme.dark : ChoreiaTheme.light;
  expect(theme.brightness, brightness);
  expect(theme.scaffoldBackgroundColor, appTheme.scaffoldBackgroundColor);
  expect(theme.colorScheme.primary, appTheme.colorScheme.primary);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text('SHOULD_NEVER_BUILD'), findsNothing);
  expect(tester.takeException(), isNull);
  fixture.expectNoEffects();
}

class _TrackedLocales extends ChoreiaLocaleController {
  _TrackedLocales(Locale? locale) : super.memory(locale);
  int additions = 0;
  int removals = 0;
  int disposeCalls = 0;
  int get liveListeners => additions - removals;

  @override
  void addListener(VoidCallback listener) {
    additions++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removals++;
    super.removeListener(listener);
  }

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

class _TrackedThemes extends ChoreiaThemeController {
  _TrackedThemes(ThemeMode mode) : super.memory(mode);
  int additions = 0;
  int removals = 0;
  int disposeCalls = 0;
  int get liveListeners => additions - removals;

  @override
  void addListener(VoidCallback listener) {
    additions++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removals++;
    super.removeListener(listener);
  }

  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

class _ClosedFixture {
  _ClosedFixture() {
    runtime = MotionAccountRuntime.forTesting(
      client: _NoNetworkSupabase(this),
      app: MotionApp.choreia,
      onDeletedAccount: (_) async {
        deletionCallbacks++;
        throw StateError('A presentation test cannot delete an account');
      },
      // Empty local IDs mean reconciliation has no receipt/provider work.
      localAccountIds: () async => const <String>[],
    );
    runtime.dispose();
    child = _BlockedChild(this);
  }

  late final MotionAccountRuntime runtime;
  late final Widget child;
  int unexpectedClientCalls = 0;
  int deletionCallbacks = 0;
  int childBuilds = 0;

  Never reject(Invocation invocation) {
    unexpectedClientCalls++;
    throw StateError(
        'Unexpected Supabase operation: ' + invocation.memberName.toString());
  }

  void expectNoEffects() {
    expect(runtime.isDisposed, isTrue);
    expect(unexpectedClientCalls, 0);
    expect(deletionCallbacks, 0);
    expect(childBuilds, 0,
        reason: 'This terminal error fixture never admits or mounts its child');
  }
}

class _BlockedChild extends StatelessWidget {
  const _BlockedChild(this.fixture);
  final _ClosedFixture fixture;

  @override
  Widget build(BuildContext context) {
    fixture.childBuilds++;
    return const Text('SHOULD_NEVER_BUILD');
  }
}

class _NoNetworkSupabase implements SupabaseClient {
  _NoNetworkSupabase(this.fixture) : _auth = _NoNetworkAuth(fixture);
  final _ClosedFixture fixture;
  final _NoNetworkAuth _auth;

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => fixture.reject(invocation);
}

class _NoNetworkAuth implements GoTrueClient {
  _NoNetworkAuth(this.fixture);
  final _ClosedFixture fixture;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream<AuthState>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => fixture.reject(invocation);
}
