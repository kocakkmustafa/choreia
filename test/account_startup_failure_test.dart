import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('missing account configuration shows a bounded first frame', (
    WidgetTester tester,
  ) async {
    await launchChoreia(url: '', publishableKey: '');
    await tester.pump();

    expect(find.byType(ChoreiaAccountStartupFailure), findsOneWidget);
    expect(find.byType(ChoreiaApp), findsNothing);
    expect(
        find.byKey(const Key('choreia.accountStartupFailure')), findsOneWidget);
    expect(find.textContaining('Invalid Motion account configuration'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final String language in <String>['en', 'tr']) {
    testWidgets('invalid account configuration stays readable in $language', (
      WidgetTester tester,
    ) async {
      tester.binding.platformDispatcher.localesTestValue = <Locale>[
        Locale(language),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

      await launchChoreia(url: 'invalid', publishableKey: 'test-key');
      await tester.pumpAndSettle();

      expect(find.byType(ChoreiaAccountStartupFailure), findsOneWidget);
      expect(
        find.textContaining(language == 'tr'
            ? 'hesap hizmeti bu sürümde başlatılamadı'
            : 'account service could not start in this build'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      expect(find.byType(ChoreiaApp), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
