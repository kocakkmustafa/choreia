import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/live/live_lesson_copy.dart';
import 'package:choreia/app/live/live_session.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/live_view.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';

void main() {
  Future<void> show(WidgetTester tester, LiveState state,
      {bool permanent = false}) async {
    await tester.pumpWidget(MaterialApp(
      home: LiveView(
        state: state,
        gated: const <GatedCheck>[],
        notMeasuredNote: '',
        permissionPermanentlyDenied: permanent,
        onRetry: () {},
        onOpenSettings: () {},
      ),
    ));
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localeTestValue = const Locale('tr');
  });
  tearDown(() => TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .clearLocaleTestValue());

  testWidgets('permanent denial points to settings, transient denial retries',
      (WidgetTester tester) async {
    await show(tester, const LivePermissionDenied(), permanent: true);
    expect(find.text('Ayarları aç'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsNothing);

    await show(tester, const LivePermissionDenied());
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Ayarları aç'), findsNothing);
  });

  testWidgets('camera failure and absent count are stated in Turkish',
      (WidgetTester tester) async {
    await show(tester,
        const LiveCameraUnavailable(CameraFailure.modelLoadFailed, null));
    expect(find.textContaining('Sorun telefonunuzda değil'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);

    await show(tester, const LiveWatching(cyclesSeen: 0));
    expect(find.text('Henüz tam tekrar okunmadı'), findsOneWidget);
  });

  test('open Bounce live limits use its measured reference and exact source',
      () {
    final DanceReference reference = DanceReference.fromJson(
        jsonDecode(File('content/references/hh_bounce.json').readAsStringSync())
            as Map<String, dynamic>);
    final Map<String, dynamic> step = jsonDecode(
        File('content/styles/hip_hop_foundations/steps/hh_bounce.json')
            .readAsStringSync()) as Map<String, dynamic>;
    expect(reference.mirrorConfident, isFalse);
    final LiveSession session = LiveSession(
      reference: reference,
      stepConfig: step,
      lessonClass: 'demo-only',
      judge: DanceJudge(reference: reference),
    );
    final GatedCheck foot = session
        .gatedChecks()
        .firstWhere((GatedCheck check) => check.code == 'WRONG_FOOT');
    expect(
      LiveLessonCopy.gatedReason('hh_l1_bounce', foot.code, foot.why,
          turkish: true),
      contains('sağı ve solu güvenilir biçimde ayıramıyor'),
    );
    expect(
      LiveLessonCopy.identityLimit('hh_l1_bounce', LiveSession.notMeasuredNote,
          turkish: true),
      contains('bu adımı çalıştığınızın kanıtı değildir'),
    );
    expect(
      LiveLessonCopy.gatedReason('hh_l1_bounce', foot.code, '${foot.why} New.',
          turkish: true),
      '${foot.why} New.',
    );
    expect(
      LiveLessonCopy.identityLimit(
          'another_lesson', LiveSession.notMeasuredNote,
          turkish: true),
      LiveSession.notMeasuredNote,
    );
    expect(
      LiveLessonCopy.measurementLabel(
          'hh_l1_bounce', 'kneeDeltaDeg', 'Revised knee label',
          turkish: true),
      'Revised knee label',
    );
  });

  testWidgets('open Bounce live reading shows Turkish limits without a grade',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const String footReason = 'We are not checking which foot you start on. '
        'The measured reference does not distinguish left and right reliably '
        'for this movement, so calling your starting foot wrong would be a '
        'coin flip presented as a judgement.';
    await tester.pumpWidget(MaterialApp(
      home: LiveView(
        lessonId: 'hh_l1_bounce',
        state: const LiveMeasured(
          measurements: <String, double>{'kneeDeltaDeg': 12.5},
          gated: <GatedCheck>[
            GatedCheck(code: 'WRONG_FOOT', why: footReason),
          ],
          notMeasuredNote: LiveSession.notMeasuredNote,
        ),
        gated: const <GatedCheck>[
          GatedCheck(code: 'WRONG_FOOT', why: footReason),
        ],
        notMeasuredNote: LiveSession.notMeasuredNote,
      ),
    ));
    expect(find.text('Diz açısı değişimi'), findsOneWidget);
    expect(find.textContaining('sağı ve solu güvenilir biçimde ayıramıyor'),
        findsOneWidget);
    expect(find.textContaining('bu adımı çalıştığınızın kanıtı değildir'),
        findsOneWidget);
    expect(find.textContaining('coin flip'), findsNothing);
    expect(find.textContaining('wrong step'), findsNothing);
    expect(find.textContaining('puan'), findsNothing);
  });
}
