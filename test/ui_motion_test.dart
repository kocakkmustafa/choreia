import 'package:choreia/app/shell/choreia_page_route.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget contracts only. OS settings, battery use and physical devices need
/// separate acceptance; these tests control the host MediaQuery preference.
void main() {
  const backdropKey = Key('motion.backdrop');
  const destinationKey = Key('motion.destination');

  Widget preferenceHost(ValueNotifier<bool> reduceMotion, Widget home) =>
      MaterialApp(
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          child: child,
          builder: (context, value, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: value),
            child: child!,
          ),
        ),
        home: home,
      );

  List<double> decorationPose(WidgetTester tester) {
    final transform = tester.widget<Transform>(find.descendant(
      of: find.byType(SlowBreath),
      matching: find.byType(Transform),
    ));
    final spin = tester.widget<RotationTransition>(find.descendant(
      of: find.byType(SlowSpin),
      matching: find.byType(RotationTransition),
    ));
    final blobs = tester.widgetList<Align>(find.descendant(
      of: find.byKey(backdropKey),
      matching: find.byType(Align),
    ));
    return <double>[
      ...transform.transform.storage,
      spin.turns.value,
      for (final blob in blobs) ...<double>[
        (blob.alignment as Alignment).x,
        (blob.alignment as Alignment).y,
      ],
    ];
  }

  testWidgets('decoration stays still, resumes, and stops after a live change',
      (tester) async {
    final reduceMotion = ValueNotifier(true);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(preferenceHost(
      reduceMotion,
      const Scaffold(
        body: ChoreiaBackdrop(
          key: backdropKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SlowBreath(child: SizedBox(width: 20, height: 20)),
              SlowSpin(child: SizedBox(width: 20, height: 20)),
            ],
          ),
        ),
      ),
    ));
    final still = decorationPose(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(decorationPose(tester), still);
    expect(tester.binding.transientCallbackCount, 0);

    reduceMotion.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(decorationPose(tester), isNot(equals(still)));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    reduceMotion.value = true;
    await tester.pump();
    final stopped = decorationPose(tester);
    expect(stopped, still);
    await tester.pump(const Duration(seconds: 2));
    expect(decorationPose(tester), stopped);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  Widget routeHome() => Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              ChoreiaPageRoute<void>(
                builder: (_) => const Scaffold(
                  key: destinationKey,
                  body: Text('Destination'),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      );

  Finder routeSlides() => find.ancestor(
        of: find.byKey(destinationKey),
        matching: find.byType(SlideTransition),
      );

  Finder routeFades() => find.ancestor(
        of: find.byKey(destinationKey),
        matching: find.byType(FadeTransition),
      );

  testWidgets('a live preference change removes push and pop motion',
      (tester) async {
    final reduceMotion = ValueNotifier(false);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(preferenceHost(reduceMotion, routeHome()));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(routeSlides(), findsOneWidget);
    expect(routeFades(), findsOneWidget);

    reduceMotion.value = true;
    await tester.pump();
    expect(routeSlides(), findsNothing);
    expect(routeFades(), findsNothing);
    await tester.pump(ChoreiaMotion.screenTransition);

    reduceMotion.value = false;
    await tester.pump();
    Navigator.of(tester.element(find.byKey(destinationKey))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(routeSlides(), findsOneWidget);
    reduceMotion.value = true;
    await tester.pump();
    expect(routeSlides(), findsNothing);
    expect(routeFades(), findsNothing);
    await tester.pump(ChoreiaMotion.screenTransition);
    expect(find.text('Open').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a route opened with Reduce Motion has no fade or slide',
      (tester) async {
    final reduceMotion = ValueNotifier(true);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(preferenceHost(reduceMotion, routeHome()));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(routeSlides(), findsNothing);
    expect(routeFades(), findsNothing);
    await tester.pump(ChoreiaMotion.screenTransition);
    expect(tester.takeException(), isNull);
  });
}
