import 'package:choreia/app/live/live_session.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/session_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localeTestValue = const Locale('tr');
  });
  tearDown(() => TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .clearLocaleTestValue());

  Future<void> show(WidgetTester tester, RecordOutcome outcome) =>
      tester.pumpWidget(MaterialApp(
        locale: Locale('tr'),
        supportedLocales: <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionResultView(
          lessonName: 'Test',
          outcome: outcome,
          gated: const <GatedCheck>[],
          notMeasuredNote: '',
          sawUnjudgeableFrames: false,
        ),
      ));

  testWidgets('absent session is not presented as a zero score',
      (WidgetTester tester) async {
    await show(tester, const RecordNothingToStore());
    expect(find.textContaining('Bu sıfır tekrarlı bir seans değil'),
        findsOneWidget);
    expect(find.textContaining('kamera hiç başlamadığı'), findsNothing);
    expect(find.textContaining('değerlendirilebilir hareket okunmadı'),
        findsOneWidget);
    expect(find.byKey(SessionResultView.notStoredKey), findsOneWidget);
  });

  testWidgets('failed write is stated without a saved claim',
      (WidgetTester tester) async {
    await show(tester, const RecordFailed('disk full'));
    expect(find.textContaining('seansı kaydedemedik'), findsOneWidget);
    expect(find.byKey(SessionResultView.failedKey), findsOneWidget);
    expect(find.byKey(SessionResultView.storedKey), findsNothing);
  });

  testWidgets('open Bounce result repeats Turkish measurement limits',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const String footReason = 'We are not checking which foot you start on. '
        'The measured reference does not distinguish left and right reliably '
        'for this movement, so calling your starting foot wrong would be a '
        'coin flip presented as a judgement.';
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('tr'),
      supportedLocales: <Locale>[Locale('en'), Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SessionResultView(
        lessonId: 'hh_l1_bounce',
        lessonName: 'The Bounce (puanlanmıyor)',
        outcome: RecordNothingToStore(),
        gated: <GatedCheck>[
          GatedCheck(code: 'WRONG_FOOT', why: footReason),
        ],
        notMeasuredNote: LiveSession.notMeasuredNote,
        sawUnjudgeableFrames: false,
      ),
    ));
    expect(find.textContaining('sağı ve solu güvenilir biçimde ayıramıyor'),
        findsOneWidget);
    expect(find.textContaining('bu adımı çalıştığınızın kanıtı değildir'),
        findsOneWidget);
    expect(find.textContaining('coin flip'), findsNothing);
  });
}
