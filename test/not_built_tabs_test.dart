/// The three shell tabs added without a real screen behind them yet
/// (CHO-P1-001, 2026-08-19: Today, Practice Lab, Profile — DEFTER C-321 has
/// the full accounting of why each is genuinely unbuilt, not just unwired).
///
/// `reachability_test.dart` already proves each tab is a real PLACE a user
/// can tap to (the LOOSE walk). This file proves something different: that
/// what's THERE once you arrive follows the same M-F-186 discipline
/// `library_view_test.dart` already pins for unbuilt styles — named,
/// explained, never silent and never dressed up as more than it is.
library;

import 'package:choreia/app/practice_lab/practice_lab_view.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:choreia/app/today/today_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Language a "not built yet" screen must never use — the same class
/// `library_view_test.dart`'s own promise-language check guards against,
/// checked here independently rather than importing that test's list, so
/// the two do not silently drift into checking the same thing by reference.
const List<String> _promiseWords = <String>[
  'coming soon',
  'yakında',
  'soon',
  'launching',
];

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: child)),
      );

  group('not-built tabs say so, and only that', () {
    testWidgets('Today names what it will show and that none of it exists',
        (WidgetTester tester) async {
      await pump(tester, const TodayView());
      expect(find.byKey(TodayView.notBuiltKey), findsOneWidget);
      expect(find.textContaining('Nothing is built here yet'), findsOneWidget,
          reason: 'the one sentence that keeps this tab from reading as a '
              'silent or a fake-full screen');
      final String text = tester
          .widgetList<Text>(find.descendant(
              of: find.byKey(TodayView.notBuiltKey), matching: find.byType(Text)))
          .map((Text t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      for (final String word in _promiseWords) {
        expect(text.contains(word), isFalse,
            reason: '"$word" reads as a promise of when, not a statement of '
                'what is true now (M-F-186)');
      }
    });

    testWidgets('Practice Lab names the tools and that none exist yet',
        (WidgetTester tester) async {
      await pump(tester, const PracticeLabView());
      expect(find.byKey(PracticeLabView.notBuiltKey), findsOneWidget);
      expect(find.textContaining('Nothing is built here yet'), findsOneWidget);
    });

    testWidgets('Profile names what it will show and that most of it does '
        'not exist yet', (WidgetTester tester) async {
      await pump(tester, const ProfileView());
      expect(find.byKey(ProfileView.notBuiltKey), findsOneWidget);
      expect(find.textContaining('Nothing is built here yet'), findsOneWidget);
    });
  });
}
