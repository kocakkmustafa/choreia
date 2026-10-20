import 'dart:async';

import 'package:flutter/foundation.dart'
    show ValueListenable, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motion_account/motion_account.dart';

import 'app/account_bridge.dart';
import 'app/account_recovery_host.dart';
import 'app/history/account_store_lifetime.dart';
import 'app/font_licenses.dart';
import 'app/live/live_environment.dart';
import 'app/shell/choreia_shell.dart';
import 'app/theme.dart';
import 'app/theme/theme_preference.dart';
import 'app/ui_language.dart';
import 'app/support_action.dart';
import 'app/localization/choreia_locale.dart';
import 'app/localization/choreia_messages.dart';
import 'app/localization/translation_fallback.dart';

/// Choreia's entry point.
///
/// Until 2026-08-07 this file WAS the app: it opened one hardcoded lesson's
/// live path and nothing else, with its own comment explaining why — "building
/// [a navigation shell] around an unverified chain would be decorating
/// something that does not work." The chain was verified in `b9e448e`, so the
/// shell exists now and this file is back to what an entry point should be: a
/// theme and a first screen.
///
/// CHO-P0-002: `GoogleFonts.config.allowRuntimeFetching` kapatır — üç aile
/// artık `assets/fonts/` altında bundle (`pubspec.yaml`, `tool/
/// fetch_fonts.sh`, lissom L-348/LIS-P0-002 ile aynı desen). Kapatılmadan
/// önce ölçüldü: baseline'ın kendi §1'i "google_fonts runtime bağımlılığı"nı
/// GERÇEK bir ağ davranışı olarak listeliyordu, icat edilmiş bir kusur
/// değil.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  registerBundledFontLicenses();
  final localeController = ChoreiaLocaleController.persisted();
  final themes = ChoreiaThemeController.persisted();
  await Future.wait([localeController.restore(), themes.restore()]);
  await launchChoreia(localeController: localeController, themeController: themes);
}

/// A broken account build must show a bounded failure instead of opening an
/// unauthenticated guest shell or ending before the first Flutter frame.
Future<void> launchChoreia({
  String url = const String.fromEnvironment('MOTION_SUPABASE_URL'),
  String publishableKey =
      const String.fromEnvironment('MOTION_SUPABASE_PUBLISHABLE_KEY'),
  ChoreiaLocaleController? localeController,
  ChoreiaThemeController? themeController,
  Duration startupTimeout = const Duration(seconds: 20),
  Future<MotionAccountRuntime> Function()? initialize,
}) async {
  final locales = localeController ?? ChoreiaLocaleController.memory();
  final themes = themeController ?? ChoreiaThemeController.memory();
  var abandoned = false;
  runApp(
      ChoreiaAccountStartupFailure(localeController: locales, themeController: themes, waiting: true));
  try {
    final hostController = ChoreiaAccountHostController();
    final pending = initialize?.call() ??
        MotionAccountRuntime.initialize(
          url: url,
          publishableKey: publishableKey,
          app: MotionApp.choreia,
          emailRedirectTo: 'com.yulalab.choreia://auth/callback',
          onDeletedAccount: (id) => clearLocalHistoryFor(id,
              onNamespaceFenced: hostController.namespaceFenced),
          localAccountIds: localHistoryAccountIds,
        );
    // A late initializer must never replace the terminal failure or admit an
    // unverified guest. Dispose only this abandoned attempt's runtime.
    unawaited(pending.then<void>((runtime) {
      if (abandoned) runtime.dispose();
    }, onError: (Object _, StackTrace __) {}));
    final MotionAccountRuntime runtime = await pending.timeout(startupTimeout);
    runApp(MotionIdentityGate(
      runtime: runtime,
      child: ChoreiaApp(
          accountRuntime: runtime,
          accountHostController: hostController,
          localeController: locales, themeController: themes),
    ));
  } on Object {
    abandoned = true;
    runApp(ChoreiaAccountStartupFailure(localeController: locales, themeController: themes));
  }
}

class ChoreiaAccountStartupFailure extends StatefulWidget {
  const ChoreiaAccountStartupFailure({this.localeController, this.themeController, this.waiting = false, super.key});
  final ChoreiaLocaleController? localeController;
  final ChoreiaThemeController? themeController;
  final bool waiting;
  @override
  State<ChoreiaAccountStartupFailure> createState() => _ChoreiaAccountStartupFailureState();
}
class _ChoreiaAccountStartupFailureState extends State<ChoreiaAccountStartupFailure> {
  late ChoreiaLocaleController locales;
  late ChoreiaThemeController themes;
  @override
  void initState() {
    super.initState();
    locales = widget.localeController ?? ChoreiaLocaleController.memory();
    themes = widget.themeController ?? ChoreiaThemeController.memory();
  }
  @override
  void didUpdateWidget(covariant ChoreiaAccountStartupFailure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeController != widget.localeController) {
      if (oldWidget.localeController == null) locales.dispose();
      locales = widget.localeController ?? ChoreiaLocaleController.memory();
    }
    if (oldWidget.themeController != widget.themeController) {
      if (oldWidget.themeController == null) themes.dispose();
      themes = widget.themeController ?? ChoreiaThemeController.memory();
    }
  }
  @override
  void dispose() {
    if (widget.localeController == null) locales.dispose();
    if (widget.themeController == null) themes.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => ChoreiaThemeScope(controller: themes,
    child: ChoreiaLocaleScope(controller: locales, child: AnimatedBuilder(
      animation: Listenable.merge([locales, themes]),
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false, title: 'Choreia',
        theme: ChoreiaTheme.light, darkTheme: ChoreiaTheme.dark, themeMode: themes.value,
        themeAnimationDuration: Duration.zero,
        locale: locales.value, supportedLocales: ChoreiaLocaleController.supported,
        localeResolutionCallback: ChoreiaLocaleController.resolve,
                    localeListResolutionCallback: ChoreiaLocaleController.resolveLocales,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(value: ChoreiaTheme.overlayFor(Theme.of(context).brightness), child: TranslationFallback(child: child!)),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ChoreiaMessagesDelegate(), GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
        ],
        home: widget.waiting ? const Scaffold(body: SafeArea(child: Center(child: _AccountStartupWaiting()))) : const ChoreiaAccountFailureView(),
      ),
    )),
  );
}

class _AccountStartupWaiting extends StatelessWidget {
  const _AccountStartupWaiting();
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
          UiLanguage.text(context,
              en: 'Checking account access…',
              tr: 'Hesap erişimi kontrol ediliyor…'),
          key: const Key('choreia.accountStartupWaiting')));
}

/// Only reached when the configured account service cannot start.
class ChoreiaAccountFailureView extends StatelessWidget {
  const ChoreiaAccountFailureView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Center(
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                UiLanguage.text(context,
                    tr: 'Choreia hesap hizmeti bu sürümde başlatılamadı. '
                        'Uygulamayı yeniden açmayı dene; sorun sürerse '
                        'güncel sürümü yükle.',
                    en: 'Choreia account service could not start in this '
                        'build. Try reopening the app; if the problem '
                        'continues, install an updated version.'),
                key: const Key('choreia.accountStartupFailure'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const SupportAction(surface: SupportSurface.startup),
            ]),
          )),
        )),
      );
}

class ChoreiaApp extends StatefulWidget {
  const ChoreiaApp(
      {super.key,
      this.accountRuntime,
      this.accountHostController,
      this.shellBuilder,
      this.localeController,
      this.themeController,
      this.localeBundle});

  final MotionAccountRuntime? accountRuntime;
  final ChoreiaAccountHostController? accountHostController;
  final ChoreiaLocaleController? localeController;
  final ChoreiaThemeController? themeController;
  @visibleForTesting
  final AssetBundle? localeBundle;
  @visibleForTesting
  final Widget Function(
          LiveEnvironment environment, WidgetBuilder? accountPageBuilder)?
      shellBuilder;

  @override
  State<ChoreiaApp> createState() => _ChoreiaAppState();
}

class _ChoreiaAppState extends State<ChoreiaApp> {
  MotionAccountRuntime? get accountRuntime => widget.accountRuntime;
  Stream<ChoreiaAuthSessionEvent>? _authSessionChanges;
  late ChoreiaAccountHostController _hostController;
  late ChoreiaLocaleController _locales;
  late ChoreiaThemeController _themes;

  void _bindRuntimeEvents() {
    // Public Auth stream is retirement-only; canonical phase remains the
    // authority for verified or genuinely signed-out guest admission.
    _authSessionChanges = accountRuntime?.account.authChanges.map(
        (state) => ChoreiaAuthSessionEvent(state.event.name, state.session));
  }

  @override
  void initState() {
    super.initState();
    _hostController =
        widget.accountHostController ?? ChoreiaAccountHostController();
    _locales = widget.localeController ?? ChoreiaLocaleController.memory();
    _themes = widget.themeController ?? ChoreiaThemeController.memory();
    _bindRuntimeEvents();
  }

  @override
  void didUpdateWidget(covariant ChoreiaApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountHostController != widget.accountHostController) {
      _hostController =
          widget.accountHostController ?? ChoreiaAccountHostController();
    }
    if (oldWidget.accountRuntime != accountRuntime) _bindRuntimeEvents();
    if (oldWidget.themeController != widget.themeController) {
      if (oldWidget.themeController == null) _themes.dispose();
      _themes = widget.themeController ?? ChoreiaThemeController.memory();
    }
    if (oldWidget.localeController != widget.localeController) {
      if (oldWidget.localeController == null) _locales.dispose();
      _locales = widget.localeController ?? ChoreiaLocaleController.memory();
    }
  }

  @override
  void dispose() {
    if (widget.localeController == null) _locales.dispose();
    if (widget.themeController == null) _themes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget accountPage(BuildContext _) {
      final runtime = accountRuntime!;
      // Capture the route ticket only for before-RPC initiation. Once Core
      // verifies a server UUID echo, page and permanent callbacks both erase
      // that UUID's entire data namespace across all its storage epochs.
      final userId = runtime.userId.value;
      final ticket =
          userId == null ? null : appStoreOwners.currentTicket(userId);
      return MotionAccountPage(
        account: OwnerBoundMotionAccountClient(runtime.account,
            expectedOwner: ticket),
        onRetryIdentity: runtime.refreshIdentity,
        initialPasswordRecovery: runtime.passwordRecovery.value,
        clearLocalData: (id) => clearLocalHistoryFor(id,
            onNamespaceFenced: _hostController.namespaceFenced),
      );
    }

    Widget shell(ValueListenable<int>? ownerEpoch) {
      final env = accountRuntime == null
          ? const LiveEnvironment()
          : LiveEnvironment(
              accountUserId: accountRuntime!.userId,
              passwordRecovery: accountRuntime!.passwordRecovery,
              ownerEpoch: ownerEpoch,
            );
      final WidgetBuilder? accountBuilder =
          accountRuntime == null ? null : accountPage;
      return widget.shellBuilder?.call(env, accountBuilder) ??
          ChoreiaShell(
            env: env,
            // Match the current beforeStart release policy without enabling it.
            cameraSessionsAvailable: motionPaidFeaturesAvailable,
            accountPageBuilder: accountBuilder,
            beforeLessonStart: accountRuntime == null
                ? null
                : (lessonContext) => requireMotionPaidAccess(
                      lessonContext,
                      account: accountRuntime!.account,
                      accountPageBuilder: accountPage,
                    ),
          );
    }

    Widget app(BuildContext context, Key? navigationKey, bool recovery,
        ValueListenable<int>? ownerEpoch) {
      return ChoreiaThemeScope(controller: _themes, child: ChoreiaLocaleScope(
          controller: _locales,
          child: AnimatedBuilder(
              animation: Listenable.merge([_locales, _themes]),
              builder: (_, __) => MaterialApp(
                    key: navigationKey,
                    debugShowCheckedModeBanner: false,
                    title: 'Choreia',
                    theme: ChoreiaTheme.light,
                    darkTheme: ChoreiaTheme.dark,
                    themeMode: _themes.value,
                    themeAnimationDuration: Duration.zero,
                    locale: _locales.value,
                    supportedLocales: ChoreiaLocaleController.supported,
                    localeResolutionCallback: ChoreiaLocaleController.resolve,
                    localeListResolutionCallback: ChoreiaLocaleController.resolveLocales,
                    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(value: ChoreiaTheme.overlayFor(Theme.of(context).brightness), child: TranslationFallback(child: child!)),
                    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                      ChoreiaMessagesDelegate(bundle: widget.localeBundle),
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: recovery ||
                            (accountRuntime != null &&
                                _hostController.requiresAccountRoute)
                        ? accountPage(context)
                        : shell(ownerEpoch),
                  ))));
    }

    final runtime = accountRuntime;
    return runtime == null
        ? app(context, null, false, null)
        : ChoreiaAccountHost(
            accountUserId: runtime.userId,
            passwordRecovery: runtime.passwordRecovery,
            controller: _hostController,
            authSessionChanges: _authSessionChanges,
            initialSessionIdentity:
                runtime.account.supabase.auth.currentSession,
            currentSessionIdentity: () =>
                runtime.account.supabase.auth.currentSession,
            identityChanges: runtime.phase,
            verificationChanges: runtime.identityVerification,
            canAdmitOwner: () =>
                (runtime.phase.value == MotionIdentityPhase.verified &&
                    runtime.isCurrentSessionVerified &&
                    runtime.userId.value != null &&
                    runtime.account.currentUser?.id == runtime.userId.value) ||
                (!runtime.isDisposed &&
                    runtime.phase.value == MotionIdentityPhase.signedOut &&
                    runtime.account.supabase.auth.currentSession == null &&
                    runtime.userId.value == null &&
                    runtime.account.currentUser == null),
            builder: app,
          );
  }
}
