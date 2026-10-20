import 'package:choreia/app/account_recovery_host.dart';
import 'package:choreia/app/course/practice_comparison_page.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

// Queued test source. No runtime pass or physical acceptance is claimed.
const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

Finder note(int index) => find.byKey(Key('practiceComparison.note.$index'));

Future<void> reach(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  if (target.evaluate().isEmpty) {
    // Reset before scanning: the requested lazy child may be ABOVE the viewport.
    position.jumpTo(0);
    await tester.pump();
  }
  for (var i = 0; i < 200 && target.evaluate().isEmpty; i++) {
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo((position.pixels + 150).clamp(0.0, position.maxScrollExtent).toDouble());
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
}

Future<void> enter(WidgetTester tester, int index, String text) async {
  await reach(tester, note(index));
  await tester.enterText(note(index), text);
  await tester.pump();
}

String value(WidgetTester tester, int index) =>
    tester.widget<TextField>(note(index)).controller!.text;

Widget root() => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          key: const Key('openWorksheet'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const PracticeComparisonPage(
                  styleId: 'hip_hop_foundations'))),
          child: const Text('Open worksheet'),
        ),
      ),
    );

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('openWorksheet')));
  await tester.pumpAndSettle();
}

void main() {
  for (final lang in ['en', 'tr']) {
    testWidgets('$lang A/B notes retain uncertainty and never award success',
        (tester) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(lang);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ChoreiaTheme.dark, home: root()));
      await open(tester);
      final semantics = tester.ensureSemantics();
      try {
      final boundary = tester.widget<Text>(
          find.byKey(const Key('practiceComparison.boundary'))).data!;
      expect(boundary, contains(lang == 'tr' ? 'değerlendirme değildir' : 'not an assessment'));
      expect(boundary, contains(lang == 'tr' ? 'kaybolur' : 'lost when closed'));
      await enter(tester, 0, 'step-touch count 4; touch versus transfer');
      await enter(tester, 1, 'reading only; R; front; no physical trial');
      await enter(tester, 2, 'silent; external beat not tested');
      await enter(tester, 3, 'A: uncertain at 4');
      await enter(tester, 4, 'one cue: say touch without claiming transfer');
      await enter(tester, 5, 'B: still uncertain at 4');
      expect(value(tester, 5), 'B: still uncertain at 4');
      await enter(tester, 6, 'ask for separate qualified feedback');
      final expectedLabels = lang == 'tr' ? <String>[
        'Çalışma ve belirli sayı/geçiş',
        'Koşul: mod, uyarlama, taraf, yön ve hareket aralığı',
        'Ses koşulu: dış kaynak veya yalnız yazılı/sessiz çalışma',
        'A: Nerede ne gözledim? Emin değilsem bunu yaz',
        'Tek düzeltme: B için seçeceğim ipucu',
        'B: Aynı noktada ne gözledim? Emin değilsem bunu yaz',
        'Sonraki adım: tekrar, ara veya eğitmenden geri bildirim',
      ] : <String>[
        'Study and specific count/transition',
        'Condition: mode, adaptation, side, facing and range',
        'Sound condition: external source or written/silent study only',
        'A: What did I observe, and where? Say if uncertain',
        'One correction: my chosen cue for B',
        'B: What did I observe at that same point? Say if uncertain',
        'Next step: revisit, rest or ask an instructor for feedback',
      ];
      final observedLabels = <String>[];
      for (var i = 0; i < 7; i++) {
        await reach(tester, note(i));
        final wrapper = find.ancestor(of: note(i), matching: find.byWidgetPredicate((w) =>
            w is Semantics && w.properties.label == expectedLabels[i]));
        expect(wrapper, findsOneWidget);
        observedLabels.add(tester.widget<Semantics>(wrapper).properties.label!);
        expect(find.bySemanticsLabel(RegExp('^${RegExp.escape(expectedLabels[i])}')),
            findsOneWidget);
      }
      expect(observedLabels, orderedEquals(expectedLabels));
      expect(observedLabels.toSet(), hasLength(7));
      // Reading/typing all fields must not remove or replace the boundary.
      await reach(tester, find.byKey(const Key('practiceComparison.boundary')));
      expect(tester.widget<Text>(find.byKey(const Key('practiceComparison.boundary'))).data, boundary);
      expect(find.textContaining(lang == 'tr' ? 'B yeni başlangıçtır' : 'B is a new baseline'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('Back cancels page-local notes; reopening begins empty', (tester) async {
    await tester.pumpWidget(MaterialApp(home: root()));
    await open(tester);
    for (var i = 0; i < 7; i++) {
      await enter(tester, i, 'cancelled private note $i');
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(PracticeComparisonPage), findsNothing);
    await open(tester);
    for (var i = 0; i < 7; i++) {
      await reach(tester, note(i));
      expect(value(tester, i), isEmpty);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Repeated input and locale changes keep notes until page closes', (tester) async {
    final selectedLocale = ValueNotifier<Locale>(const Locale('en'));
    addTearDown(selectedLocale.dispose);
    await tester.pumpWidget(ValueListenableBuilder<Locale>(
      valueListenable: selectedLocale,
      builder: (_, locale, __) => MaterialApp(
        locale: locale,
        supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: root(),
      ),
    ));
    await open(tester);
    for (var i = 0; i < 12; i++) {
      await enter(tester, 3, 'A revision $i; uncertain');
    }
    selectedLocale.value = const Locale('tr');
    await tester.pump();
    expect(value(tester, 3), 'A revision 11; uncertain');
    await enter(tester, 5, 'B has changed tempo; new baseline');
    expect(value(tester, 5), 'B has changed tempo; new baseline');
    await reach(tester, find.textContaining('B yeni başlangıçtır'));
    expect(find.textContaining('B yeni başlangıçtır'), findsOneWidget);
    await reach(tester, find.text('Çalışma ve belirli sayı/geçiş'));
    expect(find.text('Çalışma ve belirli sayı/geçiş'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pause/resume keeps the open worksheet, unmount clears it', (tester) async {
    await tester.pumpWidget(MaterialApp(home: root()));
    await open(tester);
    await enter(tester, 3, 'reading note while page remains open');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(value(tester, 3), 'reading note while page remains open');
    // App/root destruction is different from temporarily covering a live page.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(home: root()));
    await open(tester);
    await reach(tester, note(3));
    expect(value(tester, 3), isEmpty);
  });

  for (final reset in ['owner-change', 'logout', 'same-owner-recovery']) {
    testWidgets('actual account host $reset disposes nested worksheet notes', (tester) async {
      final user = ValueNotifier<String?>(_alice);
      final recovery = ValueNotifier<bool>(false);
      final owners = AppStoreOwnerRegistry();
      addTearDown(user.dispose);
      addTearDown(recovery.dispose);
      await tester.pumpWidget(ChoreiaAccountHost(
        accountUserId: user,
        passwordRecovery: recovery,
        owners: owners,
        builder: (context, key, recovering, epoch) => MaterialApp(
          key: key,
          home: recovering ? const Scaffold(body: Text('Recovery')) : root(),
        ),
      ));
      final oldTicket = owners.capture(_alice);
      await open(tester);
      await enter(tester, 3, 'old-owner-note');
      if (reset == 'same-owner-recovery') {
        recovery.value = true;
      } else {
        user.value = reset == 'logout' ? null : _bob;
      }
      await tester.pumpAndSettle();
      expect(oldTicket.isActive, isFalse);
      expect(find.byType(PracticeComparisonPage), findsNothing);
      if (reset == 'same-owner-recovery') {
        recovery.value = false;
        await tester.pumpAndSettle();
      }
      await open(tester);
      await reach(tester, note(3));
      expect(value(tester, 3), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final lang in ['tr', 'en']) {
   for (final id in PracticeComparisonPage.supportedStyles) {
    testWidgets('actual $lang $id style route and Back retain catalogue status', (tester) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(lang);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final library = await tester.runAsync(testLibrary);
      final card = library!.cardFor(id)!;
      final status = card.entry.contentStatus;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ChoreiaTheme.dark,
          home: StyleDetailView(card: card)));
      final link = find.byKey(const Key('style.practiceComparison'));
      await reach(tester, link);
      await tester.tap(link);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PracticeComparisonPage), findsOneWidget);
      expect(tester.widget<PracticeComparisonPage>(find.byType(PracticeComparisonPage)).styleId, id);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(StyleDetailView), findsOneWidget);
      expect(card.entry.contentStatus, status);
      expect(tester.takeException(), isNull);
    });
  }
  }

  testWidgets('small viewport, double text and keyboard retain last field and semantics', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ), home: root()));
    await open(tester);
    await reach(tester, note(6));
    await tester.tap(note(6));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await enter(tester, 6, 'uncertain; instructor feedback required');
    expect(value(tester, 6), 'uncertain; instructor feedback required');
    expect(tester.getRect(note(6)).bottom, lessThanOrEqualTo(700));
    expect(find.bySemanticsLabel(RegExp('Next step: revisit')), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('every unselected catalogue style has no worksheet path', (tester) async {
    final library = await tester.runAsync(testLibrary);
    for (final card in library!.cards.where((c) =>
        !PracticeComparisonPage.supportedStyles.contains(c.entry.id))) {
      await tester.pumpWidget(MaterialApp(home: StyleDetailView(card: card)));
      await tester.pump();
      expect(find.byKey(const Key('style.practiceComparison')), findsNothing,
          reason: card.entry.id);
      expect(tester.takeException(), isNull);
    }
  });
}
