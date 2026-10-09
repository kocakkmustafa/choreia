import 'package:choreia/app/course/support_hold_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const currentKey = Key('supportHold.current');
const playKey = Key('supportHold.play');

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

Future<void> tapKey(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await reach(tester, target);
  await tester.tap(target);
  await tester.pump();
}

Future<String> current(WidgetTester tester) async {
  await reach(tester, find.byKey(currentKey));
  return tester.widget<Text>(find.byKey(currentKey)).data!;
}

void main() {
  for (final lang in ['en', 'tr']) {
    testWidgets('$lang actual UI shows both holds and extra-transfer consequence', (tester) async {
      tester.binding.platformDispatcher.localeTestValue = Locale(lang);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      await tester.pumpWidget(const MaterialApp(home: SupportHoldDemo()));
      expect(find.text(lang == 'tr' ? 'Destek ve durak şeması' : 'Support and hold diagram'), findsOneWidget);
      final state = lang == 'tr' ? 'destek durumu' : 'support state';
      final hold = lang == 'tr' ? 'aynı destek / durak' : 'same support / hold';
      await tapKey(tester, const Key('supportHold.count.3'));
      expect(await current(tester), '3/8 — A — $state');
      await tapKey(tester, const Key('supportHold.count.4'));
      expect(await current(tester), '4/8 — A — $hold');
      await tapKey(tester, const Key('supportHold.count.7'));
      expect(await current(tester), '7/8 — B — $state');
      await tapKey(tester, const Key('supportHold.count.8'));
      expect(await current(tester), '8/8 — B — $hold');
      await tapKey(tester, const Key('supportHold.count.5'));
      expect(await current(tester), '5/8 — B — $state');
      await tapKey(tester, const Key('supportHold.compare'));
      expect(await current(tester), '5/8 — A — $state');
      await tapKey(tester, const Key('supportHold.count.4'));
      expect(await current(tester), '4/8 — B — $state');
      await tapKey(tester, const Key('supportHold.count.8'));
      expect(await current(tester), '8/8 — B — $state');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('eight-second one-shot ends without looping and explicit replay resets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportHoldDemo()));
    await tapKey(tester, playKey);
    await tester.pump(const Duration(seconds: 7));
    expect(await current(tester), startsWith('8/8'));
    await tester.pump(const Duration(seconds: 1));
    final end = await current(tester);
    await tester.pump(const Duration(seconds: 16));
    expect(await current(tester), end);
    expect(tester.binding.transientCallbackCount, 0);
    await tapKey(tester, playKey);
    expect(await current(tester), startsWith('1/8'));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(await current(tester), startsWith('2/8'));
    await tapKey(tester, const Key('supportHold.pause'));
    final paused = await current(tester);
    await tester.pump(const Duration(seconds: 4));
    expect(await current(tester), paused);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('background pause and resume do not restart; playing dispose cancels ticker', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportHoldDemo()));
    await tapKey(tester, playKey);
    await tester.pump(const Duration(milliseconds: 3100));
    final beforePause = await current(tester);
    expect(beforePause, startsWith('4/8'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 3));
    expect(await current(tester), beforePause);
    expect(tester.binding.transientCallbackCount, 0);
    await tapKey(tester, playKey);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(await current(tester), startsWith('2/8'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 9));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  for (final initial in [true, false]) {
    testWidgets('reduced motion initial=$initial stops clock and never auto-resumes', (tester) async {
      final reduced = ValueNotifier(initial);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: reduced,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: value), child: child!),
        ), home: const SupportHoldDemo()));
      if (!initial) {
        await tapKey(tester, playKey);
        await tester.pump(const Duration(milliseconds: 2100));
        expect(await current(tester), startsWith('3/8'));
        reduced.value = true;
        await tester.pump();
      }
      await reach(tester, find.byKey(playKey));
      expect(tester.widget<TextButton>(find.byKey(playKey)).onPressed, isNull);
      final stopped = await current(tester);
      await tester.pump(const Duration(seconds: 9));
      expect(await current(tester), stopped);
      expect(tester.binding.transientCallbackCount, 0);
      // Manual inspection stays available with reduced motion enabled.
      await tapKey(tester, const Key('supportHold.count.8'));
      expect(await current(tester), startsWith('8/8'));
      reduced.value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      expect(await current(tester), startsWith('8/8'));
      await tapKey(tester, playKey);
      expect(await current(tester), startsWith('1/8'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final lang in ['tr', 'en']) {
    testWidgets('$lang 320x640 double text remains scrollable and operable', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.binding.platformDispatcher.localeTestValue = Locale(lang);
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final semantics = tester.ensureSemantics();
      try {
      await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!), home: const SupportHoldDemo()));
      for (final n in [3, 4, 7, 8]) {
        await tapKey(tester, Key('supportHold.count.$n'));
        expect(await current(tester), startsWith('$n/8'));
        expect(tester.takeException(), isNull);
      }
      await reach(tester, find.byKey(playKey));
      expect(find.bySemanticsLabel(RegExp(lang == 'tr' ? 'Bir kez göster' : 'Show once')), findsOneWidget);
      await tapKey(tester, playKey);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(await current(tester), startsWith('2/8'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
