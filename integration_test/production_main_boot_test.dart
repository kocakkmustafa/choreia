import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:choreia/main.dart' as production;
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('production main guest boot paints choreia app', (tester) async {
    await production.main();
    for (var i = 0; i < 600; i++) {
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
      final intro = find.byKey(FirstRunView.continueKey);
      if (intro.evaluate().isNotEmpty) {
        await tester.ensureVisible(intro);
        await tester.tap(intro);
        await tester.pump();
      }
      if (find.byKey(ChoreiaShell.libraryTabKey).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byType(production.ChoreiaApp), findsOneWidget);
    expect(find.byKey(ChoreiaShell.loadingKey), findsNothing);
    expect(find.byKey(ChoreiaShell.loadFailureKey), findsNothing);
    expect(find.byKey(ChoreiaShell.libraryTabKey), findsOneWidget);
    expect(find.byKey(ChoreiaShell.progressTabKey), findsOneWidget);
    expect(find.byKey(ChoreiaShell.profileTabKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Host runner captures the simulator while this real main UI remains mounted.
    debugPrint('MOTION_MAIN_BOOT_READY_choreia');
    await Future<void>.delayed(const Duration(seconds: 3));
  });
}
