import 'dart:io';

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

  /// [openSettings] defaults to a WORKING callback — which is not what the app
  /// ships. `LiveLessonPage` builds this screen with `onOpenSettings: null`
  /// (C-140: nothing in the dependency set can open the OS settings page), so
  /// until this parameter existed every test in this file handed the screen a
  /// callback no device ever has. The M-F-268 "no dead end" gate below was
  /// therefore measuring a screen the app never builds: green, and blind to
  /// the one branch where the dead end actually lives.
  ///
  /// The default is left as-is deliberately — flipping it would silently
  /// rewrite what the other tests mean. The production value is measured
  /// separately, from the production file, in `kalıcı ret dalı` below.
  Future<void> show(WidgetTester tester, LiveState state,
          {int? cycles,
          bool permanent = false,
          VoidCallback? openSettings = _stubOpenSettings}) =>
      tester.pumpWidget(MaterialApp(
        home: LiveView(
          state: state,
          gated: gated,
          notMeasuredNote: note,
          cyclesRead: cycles,
          permissionPermanentlyDenied: permanent,
          onRetry: () {},
          onOpenSettings: openSettings,
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

    testWidgets(
        'kalıcı ret dalı — CİHAZDAKİ hâl: tek eylem ÖLÜ (C-140 çivilendi)',
        (WidgetTester tester) async {
      // The production value is READ FROM PRODUCTION, never retyped here. The
      // two tests above pass `onOpenSettings: () {}` and so describe a screen
      // no device builds — that is the whole reason this branch's dead end
      // survived a green "NO DEAD END" gate.
      final String page =
          File('lib/app/live/live_lesson_page.dart').readAsStringSync();
      expect(page, contains('onOpenSettings: null'),
          reason: 'üretim artık gerçek bir geri-çağrı geçiriyor olabilir — '
              'aşağıdaki ÖLÜ-DÜĞME çivisi o hâlde kusuru DONDURUR, ikisi '
              'aynı commit’te güncellenmeli');

      await show(tester, const LivePermissionDenied(),
          permanent: true, openSettings: null);

      // ÇİVİLENEN ŞEY BİR KUSUR, BİR TASARIM DEĞİL. A user reaches this branch
      // by denying the camera twice; the only control on it is a button
      // labelled "Open settings" that is greyed out. M-F-268 says the branch
      // must offer an action — this one offers the SHAPE of one.
      final FilledButton button =
          tester.widget<FilledButton>(find.byKey(LiveView.actionKey));
      expect(button.onPressed, isNull,
          reason: 'düğme artık basılabilir — kusur kapandıysa bu çivi ve '
              'C-140 birlikte güncellenmeli, çivi sessizce geçmemeli');

      // What keeps this from being a TOTAL dead end today: the sentence still
      // says where to go, even though the app cannot take the user there.
      expect(find.text(LiveStrings.permanentlyDenied), findsOneWidget);
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

  group('SINGLE CORRECTION (C-136 (b), ruled 2026-08-07)', () {
    ErrorFinding fired(String code) => ErrorFinding(code, Verdict.error);

    Future<void> showJudged(WidgetTester tester, List<ErrorFinding> f) =>
        tester.pumpWidget(MaterialApp(
          home: LiveView(
            state: LiveJudged(
              result: JudgeResult(
                  measurements: const <String, double>{}, findings: f),
              gated: gated,
              notMeasuredNote: note,
            ),
            gated: gated,
            notMeasuredNote: note,
          ),
        ));

    testWidgets('two fired findings render ONE correction, not two',
        (WidgetTester tester) async {
      await showJudged(tester,
          <ErrorFinding>[fired('STEP_TOO_LARGE'), fired('WRONG_FOOT')]);

      // The card used to render a row per finding. It must now show the one
      // the derived order names.
      expect(find.textContaining('STEP_TOO_LARGE'), findsNothing,
          reason: 'the lower-priority finding must not appear as a second '
              'correction — that is the rule this screen was violating');
      expect(find.textContaining('WRONG_FOOT'), findsWidgets);
    });

    testWidgets('the other finding is COUNTED, never silently dropped',
        (WidgetTester tester) async {
      await showJudged(tester,
          <ErrorFinding>[fired('STEP_TOO_LARGE'), fired('WRONG_FOOT')]);
      expect(find.byKey(LiveView.alsoSawKey), findsOneWidget,
          reason: 'showing one correction is the rule; implying it was the '
              'only thing we saw is a stronger claim than the rule makes');
    });

    testWidgets('a single fired finding shows NO "also saw" line',
        (WidgetTester tester) async {
      // The positive twin. Without it, a card that ALWAYS printed the line
      // would pass the test above.
      await showJudged(tester, <ErrorFinding>[fired('WRONG_FOOT')]);
      expect(find.byKey(LiveView.alsoSawKey), findsNothing);
    });

    testWidgets('nothing fired still renders the clean-attempt sentence',
        (WidgetTester tester) async {
      await showJudged(tester, const <ErrorFinding>[]);
      expect(find.text(LiveStrings.nothingWrong), findsOneWidget);
      expect(find.byKey(LiveView.alsoSawKey), findsNothing);
    });

    test('the "also saw" copy INTERPOLATES — no raw variable name ships', () {
      // This exact bug shipped once in this repo (C-130: a user-facing string
      // written with the variable name escaped, so \$unreadable reached the
      // screen) and it recurred while writing THIS line — the plural branch
      // was authored as '\$n other things', which Dart reads as a literal.
      // Asserting the NUMBER, not merely "some text", is what catches it.
      expect(LiveStrings.alsoSaw(2), contains('2'));
      expect(LiveStrings.alsoSaw(2), isNot(contains(r'$n')));
      expect(LiveStrings.alsoSaw(1), isNot(contains(r'$n')));
      expect(LiveStrings.alsoSaw(1), contains('One other thing'));
    });
  });
}

/// The callback the PRODUCTION wiring does not have.
///
/// A top-level function so it can be a `show()` default; named rather than
/// inline so the diff between "what the fake hands the screen" and "what the
/// app hands the screen" (`null`) is a thing you can point at.
void _stubOpenSettings() {}
