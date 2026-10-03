import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motion_account/motion_account.dart';

import 'app/account_bridge.dart';
import 'app/account_recovery_host.dart';
import 'app/history/account_store_lifetime.dart';
import 'app/live/live_environment.dart';
import 'app/shell/choreia_shell.dart';
import 'app/theme.dart';

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
  await launchChoreia();
}

/// A broken account build must show a bounded failure instead of opening an
/// unauthenticated guest shell or ending before the first Flutter frame.
Future<void> launchChoreia({
  String url = const String.fromEnvironment('MOTION_SUPABASE_URL'),
  String publishableKey =
      const String.fromEnvironment('MOTION_SUPABASE_PUBLISHABLE_KEY'),
}) async {
  try {
    final hostController = ChoreiaAccountHostController();
    final MotionAccountRuntime runtime = await MotionAccountRuntime.initialize(
      url: url,
      publishableKey: publishableKey,
      app: MotionApp.choreia,
      emailRedirectTo: 'com.yulalab.choreia://auth/callback',
      onDeletedAccount: (id) => clearLocalHistoryFor(id,
          onNamespaceFenced: hostController.namespaceFenced),
      localAccountIds: localHistoryAccountIds,
    );
    runApp(MotionIdentityGate(
      runtime: runtime,
      child: ChoreiaApp(accountRuntime: runtime,
          accountHostController: hostController),
    ));
  } on Object {
    runApp(const ChoreiaAccountStartupFailure());
  }
}

class ChoreiaAccountStartupFailure extends StatelessWidget {
  const ChoreiaAccountStartupFailure({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Choreia',
        theme: ChoreiaTheme.dark,
        supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ChoreiaAccountFailureView(),
      );
}

/// Only reached when the configured account service cannot start.
class ChoreiaAccountFailureView extends StatelessWidget {
  const ChoreiaAccountFailureView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              Localizations.localeOf(context).languageCode == 'tr'
                  ? 'Choreia hesap hizmeti bu sürümde başlatılamadı. '
                      'Uygulamayı yeniden açmayı dene; sorun sürerse '
                      'güncel sürümü yükle.'
                  : 'Choreia account service could not start in this '
                      'build. Try reopening the app; if the problem '
                      'continues, install an updated version.',
              key: const Key('choreia.accountStartupFailure'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

class ChoreiaApp extends StatefulWidget {
  const ChoreiaApp({super.key, this.accountRuntime, this.accountHostController,
      this.shellBuilder});

  final MotionAccountRuntime? accountRuntime;
  final ChoreiaAccountHostController? accountHostController;
  @visibleForTesting
  final Widget Function(LiveEnvironment environment,
      WidgetBuilder? accountPageBuilder)? shellBuilder;

  @override
  State<ChoreiaApp> createState() => _ChoreiaAppState();
}

class _ChoreiaAppState extends State<ChoreiaApp> {
  MotionAccountRuntime? get accountRuntime => widget.accountRuntime;
  Stream<ChoreiaAuthSessionEvent>? _authSessionChanges;
  late ChoreiaAccountHostController _hostController;

  void _bindRuntimeEvents() {
    // Public Auth stream is retirement-only; canonical phase remains the
    // authority for verified or genuinely signed-out guest admission.
    _authSessionChanges = accountRuntime?.account.authChanges.map((state) =>
        ChoreiaAuthSessionEvent(state.event.name, state.session));
  }

  @override
  void initState() {
    super.initState();
    _hostController = widget.accountHostController ?? ChoreiaAccountHostController();
    _bindRuntimeEvents();
  }

  @override
  void didUpdateWidget(covariant ChoreiaApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountHostController != widget.accountHostController) {
      _hostController = widget.accountHostController ?? ChoreiaAccountHostController();
    }
    if (oldWidget.accountRuntime != accountRuntime) _bindRuntimeEvents();
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
      return widget.shellBuilder?.call(env, accountBuilder) ?? ChoreiaShell(
          env: env,
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
      return MaterialApp(
          key: navigationKey,
          debugShowCheckedModeBanner: false,
          title: 'Choreia',
          theme: ChoreiaTheme.dark,
          supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: recovery ||
                  (accountRuntime != null && _hostController.requiresAccountRoute)
              ? accountPage(context)
              : shell(ownerEpoch),
        );
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
            currentSessionIdentity: () => runtime.account.supabase.auth.currentSession,
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
