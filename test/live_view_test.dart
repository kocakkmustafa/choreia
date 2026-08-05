import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/live_view.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

/// The live screen must render EVERY state, and three family patterns must
/// hold on it (M-F-268): no dead end · permission has two flavours ·
/// "never started" is not zero.
void main() {
  const List<GatedCheck> gated = <GatedCheck>[
    GatedCheck(code: 'STEP_LATE', why: 'We are not checking your timing yet.'),
  ];
  const String note = 'We do not check that this is the right step.';

  Future<void> show(WidgetTester tester, LiveState state,
          {int? cycles, bool permanent = false}) =>
      tester.pumpWidget(MaterialApp(
        home: LiveView(
          state: state,
          gated: gated,
          notMeasuredNote: note,
          cyclesRead: cycles,
          permissionPermanentlyDenied: permanent,
          onRetry: () {},
          onOpenSettings: () {},
        ),
      ));

  testWidgets('every state renders without throwing, and none is blank',
      (WidgetTester tester) async {
    final List<LiveState> all = <LiveState>[
      const LiveIdle(),
      const LivePermissionDenied(),
      const LiveCameraUnavailable(CameraFailure.modelLoadFailed, 'detail'),
      const LiveNoPerson(<QualityIssue>{QualityIssue.outOfFrame}),
      const LiveWatching(cyclesSeen: 0),
      const LiveMeasured(
          measurements: <String, double>{'left_knee': 12.5},
          gated: gated,
          notMeasuredNote: note),
      LiveJudged(
          result: const JudgeResult(
              measurements: <String, double>{}, findings: <ErrorFinding>[]),
          gated: gated,
          notMeasuredNote: note),
    ];
    // Seven states — the same seven `LiveState` declares. If an eighth is
    // added, `LiveView`'s switch stops compiling before this test even runs.
    expect(all, hasLength(7));

    for (final LiveState s in all) {
      await show(tester, s);
      expect(tester.takeException(), isNull, reason: '$s threw');
      expect(find.byKey(LiveView.bodyKey), findsOneWidget);
      // A screen with nothing on it makes a claim nobody wrote.
      expect(find.byType(Text), findsWidgets, reason: '$s rendered blank');
    }
  });

  testWidgets('gated checks and the identity limit are on EVERY screen',
      (WidgetTester tester) async {
    for (final LiveState s in <LiveState>[
      const LiveIdle(),
      const LivePermissionDenied(),
      const LiveCameraUnavailable(CameraFailure.noSuchCamera, null),
      const LiveNoPerson(<QualityIssue>{QualityIssue.lowTrackingConfidence}),
    ]) {
      await show(tester, s);
      // Even when things went wrong: a check we cannot make is exactly what a
      // learner would otherwise assume passed.
      expect(find.byKey(LiveView.gatedKey), findsOneWidget, reason: '$s');
      expect(find.text(gated.first.why), findsOneWidget, reason: '$s');
      expect(find.byKey(LiveView.notMeasuredKey), findsOneWidget, reason: '$s');
    }
  });

  group('M-F-268 patterns', () {
    testWidgets('NO DEAD END — a camera failure still offers an action',
        (WidgetTester tester) async {
      await show(tester,
          const LiveCameraUnavailable(CameraFailure.modelLoadFailed, null));
      expect(find.byKey(LiveView.actionKey), findsOneWidget);
      expect(find.text(LiveStrings.tryAgain), findsOneWidget);
    });

    testWidgets('PERMISSION has two flavours, and they differ',
        (WidgetTester tester) async {
      await show(tester, const LivePermissionDenied());
      expect(find.text(LiveStrings.tryAgain), findsOneWidget);
      expect(find.text(LiveStrings.openSettings), findsNothing);

      await show(tester, const LivePermissionDenied(), permanent: true);
      // A "try again" that cannot possibly work is worse than no button.
      expect(find.text(LiveStrings.tryAgain), findsNothing);
      expect(find.text(LiveStrings.openSettings), findsOneWidget);
    });

    testWidgets('"never started" is NOT zero', (WidgetTester tester) async {
      await show(tester, const LiveWatching(cyclesSeen: 0));
      expect(find.text(LiveStrings.cycles(null)), findsOneWidget);
      // The negative that gives it meaning: no bare zero anywhere.
      expect(find.text('0 read so far'), findsNothing);

      // POSITIVE TWIN — a real count DOES render as a number, otherwise the
      // assertion above would pass on a screen that never shows counts.
      await show(tester, const LiveWatching(cyclesSeen: 3));
      expect(find.text('3 read so far'), findsOneWidget);
    });
  });

  testWidgets('a demoOnly reading shows measurements and NO verdict',
      (WidgetTester tester) async {
    await show(
        tester,
        const LiveMeasured(
            measurements: <String, double>{'left_knee': 12.5},
            gated: gated,
            notMeasuredNote: note));
    expect(find.text(LiveStrings.measuredTitle), findsOneWidget);
    // kural-8 on the surface: a demo-only lesson has no verdict section at
    // all — and cannot, because `LiveMeasured` carries no findings field.
    expect(find.text(LiveStrings.findingsTitle), findsNothing);
  });
}
