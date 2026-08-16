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
      // F1 audit (H-24): was `{'left_knee': 12.5}` — snake_case, which let a
      // broken camelCase→words transform look correct. `judge.dart` only
      // ever produces camelCase keys; the fixture now matches production.
      const LiveMeasured(
          measurements: <String, double>{'kneeDeltaDeg': 12.5},
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
        'kalıcı ret dalı — CİHAZDAKİ hâl: düğme GERÇEKTEN basılabilir (C-140 kapandı)',
        (WidgetTester tester) async {
      // The production value is READ FROM PRODUCTION, never retyped here.
      // This assertion is the reason the fix and this pin had to land in the
      // same commit: while `onOpenSettings: null` shipped, the pin below
      // asserted the button was DEAD, and leaving that pin in place after the
      // fix would have frozen the defect it was written to expose.
      final String page =
          File('lib/app/live/live_lesson_page.dart').readAsStringSync();
      expect(page, isNot(contains('onOpenSettings: null')),
          reason: 'üretim ölü düğmeye geri döndü (C-140 geri geldi)');
      expect(page, contains('openAppSettings'),
          reason: 'ayarları açan gerçek çağrı kayboldu — düğme yine bir '
              'eylemin ŞEKLİNİ sunar hâle gelmiş olabilir');

      // Rendered with the value production actually passes: a real callback.
      bool opened = false;
      await show(tester, const LivePermissionDenied(),
          permanent: true, openSettings: () => opened = true);

      final FilledButton button =
          tester.widget<FilledButton>(find.byKey(LiveView.actionKey));
      expect(button.onPressed, isNotNull,
          reason: 'kalıcı ret dalının tek kontrolü yine DEVRE DIŞI — '
              'M-F-268 ölü-sonu');

      // Found and enabled is still not "works": press it.
      await tester.tap(find.byKey(LiveView.actionKey));
      await tester.pump();
      expect(opened, isTrue,
          reason: 'düğme basılabilir görünüyor ama basıldığında hiçbir şey '
              'çağırmıyor');

      // The sentence stays: a working button does not remove the need to say
      // where the switch is.
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
            measurements: <String, double>{'kneeDeltaDeg': 12.5},
            gated: gated,
            notMeasuredNote: note));
    expect(find.text(LiveStrings.measuredTitle), findsOneWidget);
    // kural-8 on the surface: a demo-only lesson has no verdict section at
    // all — and cannot, because `LiveMeasured` carries no findings field.
    expect(find.text(LiveStrings.findingsTitle), findsNothing);
  });

  testWidgets(
      'SABOTAJ (H-24) — camelCase ölçüm anahtarı HAM görünmez, kelimelere '
      'ayrılır, tekrar eden birim düşer', (WidgetTester tester) async {
    // GERÇEK anahtarlar `judge.dart`dan (`kneeDeltaDeg` · `identityLegShapeDeg`
    // · `identityWorstJointDeg`) — sentetik/snake_case değil. `hh_l1_bounce`
    // (bugün başlatılabilen TEK ders) `demoOnly`, ve HER zaman bu kartla
    // çiziliyor: burada kırılan şey teorik değil, canlı yüzeyin ta kendisi.
    await show(
        tester,
        const LiveMeasured(measurements: <String, double>{
          'kneeDeltaDeg': 12.5,
          'identityLegShapeDeg': 7.25,
          'identityWorstJointDeg': 3.0,
        }, gated: gated, notMeasuredNote: note));
    // ÖNCE, negatif: hiçbir HAM anahtar ekranda YOK.
    expect(find.textContaining('kneeDeltaDeg'), findsNothing,
        reason: 'ham anahtar sızdı — kullanıcı asla görmemesi gereken bir '
            'iç tanımlayıcı');
    expect(find.textContaining('identityLegShapeDeg'), findsNothing);
    expect(find.textContaining('identityWorstJointDeg'), findsNothing);
    // SONRA, pozitif: doğru kelimelere ayrılmış, ilk harf büyük, tekrar eden
    // "Deg" birimi düşmüş (değer zaten '°' taşıyor — `LiveStrings` deseni).
    expect(find.text('Knee delta'), findsOneWidget);
    expect(find.text('Identity leg shape'), findsOneWidget);
    expect(find.text('Identity worst joint'), findsOneWidget);
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
