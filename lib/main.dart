import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motion_account/motion_account.dart';

import 'app/account_bridge.dart';
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
  final MotionAccountRuntime runtime = await MotionAccountRuntime.initialize(
    url: const String.fromEnvironment('MOTION_SUPABASE_URL'),
    publishableKey:
        const String.fromEnvironment('MOTION_SUPABASE_PUBLISHABLE_KEY'),
    app: MotionApp.choreia,
    emailRedirectTo: 'com.yulalab.choreia://auth/callback',
    onDeletedAccount: clearLocalHistoryFor,
    localAccountIds: localHistoryAccountIds,
  );
  runApp(MotionIdentityGate(
    runtime: runtime,
    child: ChoreiaApp(accountRuntime: runtime),
  ));
}

class ChoreiaApp extends StatelessWidget {
  const ChoreiaApp({super.key, this.accountRuntime});

  final MotionAccountRuntime? accountRuntime;

  @override
  Widget build(BuildContext context) {
    Widget accountPage(BuildContext _) => MotionAccountPage(
          account: accountRuntime!.account,
          onRetryIdentity: accountRuntime!.refreshIdentity,
          initialPasswordRecovery: accountRuntime!.isPasswordRecovery,
          clearLocalData: clearLocalHistoryFor,
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Choreia',
      theme: ChoreiaTheme.dark,
      supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ChoreiaShell(
        env: accountRuntime == null
            ? const LiveEnvironment()
            : LiveEnvironment(accountUserId: accountRuntime!.userId),
        accountPageBuilder: accountRuntime == null ? null : accountPage,
        beforeLessonStart: accountRuntime == null
            ? null
            : (lessonContext) => requireMotionPaidAccess(
                  lessonContext,
                  account: accountRuntime!.account,
                  accountPageBuilder: accountPage,
                ),
      ),
    );
  }
}
