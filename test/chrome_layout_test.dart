import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/live_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// Does content START where it should?
///
/// Every other layout test in this suite asks whether content FITS. None of
/// them could have caught what this file exists for: 96pt of dead space between
/// the AppBar and the first element of the style page, found by looking at a
/// screenshot (C-154). An overflow assertion is satisfied by a page that begins
/// a third of the way down the screen.
///
/// The cause is a double count that is easy to reintroduce, which is why it is
/// pinned rather than just fixed: `extendBodyBehindAppBar: true` makes Scaffold
/// hand the body a top inset that ALREADY INCLUDES the AppBar, `SafeArea`
/// consumes all of it, and a top padding sized "to clear the AppBar" then adds
/// that height a second time.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryCatalog lib;
  setUpAll(() async => lib = await testLibrary());

  /// A real notch inset. With `top: 0` the double count is invisible — the bug
  /// only appears once there is a status-bar inset to count twice, so a test
  /// that skipped this would have passed against the broken code.
  const FakeViewPadding notch = FakeViewPadding(top: 47);

  Future<double> gapBelowAppBar(
      WidgetTester tester, Widget home, Finder firstContent) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = notch;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: ChoreiaTheme.dark, home: home));
    await tester.pump();
    return tester.getRect(firstContent).top -
        tester.getRect(find.byType(AppBar)).bottom;
  }

  testWidgets('the style page starts one margin below its AppBar',
      (WidgetTester tester) async {
    final double gap = await gapBelowAppBar(
      tester,
      StyleDetailView(card: lib.cardFor('vogue')!),
      find.byType(StatusPill).first,
    );
    expect(gap, 24,
        reason: 'measured 96 before the fix — the AppBar height counted twice. '
            'A value near 100 means the double count is back; a negative value '
            'means content is hiding under the AppBar.');
  });

  testWidgets('the live page starts flush with its AppBar, margin inside',
      (WidgetTester tester) async {
    final double gap = await gapBelowAppBar(
      tester,
      const LiveView(
        state: LiveIdle(),
        gated: <GatedCheck>[],
        notMeasuredNote: 'note',
      ),
      find.byKey(LiveView.bodyKey),
    );
    // The scroll view itself butts against the AppBar and carries its margin
    // as internal padding — so 0 here is correct and 100 is the old bug.
    expect(gap, 0,
        reason: 'the ListView box should begin at the AppBar bottom; its own '
            'padding provides the margin');
  });

  testWidgets('no screen hides content UNDER the AppBar',
      (WidgetTester tester) async {
    // The opposite failure, and the one a smaller padding would cause. Checked
    // across several styles because the first element differs by content.
    for (final String id in <String>['vogue', 'salsa_shines', 'hula']) {
      final double gap = await gapBelowAppBar(
        tester,
        StyleDetailView(card: lib.cardFor(id)!),
        find.byType(StatusPill).first,
      );
      expect(gap, greaterThanOrEqualTo(0),
          reason: '$id renders its first element behind the AppBar');
    }
  });
}
