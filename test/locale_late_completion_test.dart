// Desired-contract regression probe; definition alone is not runtime acceptance.
// Read against app fc2232f78822bb934745ab9e0242f6515590d49f and installed
// Flutter 6a19cca56475dbfba1478ee68d7bd0c2ef891da1.
// These are desired-contract assertions, not assertions that accept the bug.
// Controlled local assets only; no native provider, account or network.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/ui_language.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final lateTag in const ['fr', 'ar']) {
    testWidgets('late $lateTag resources cannot replace the latest EN selection',
        (tester) async {
      final controller = ChoreiaLocaleController.memory(const Locale('en'));
      final bundle = _DelayedLocaleBundle(lateTag);
      try {
        await tester.pumpWidget(ChoreiaApp(
          localeController: controller,
          localeBundle: bundle,
          shellBuilder: (_, __) => const _Probe(),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('probe.increment')));
        await tester.pump();
        final originalState = tester.state<_ProbeState>(find.byType(_Probe));
        _expectLatestEnglish(tester, controller, originalState);

        // Begin a real ChoreiaMessagesDelegate load and prove it is pending.
        await controller.select(Locale(lateTag), persist: false);
        await _flush(tester);
        expect(bundle.pendingAssetWasRequested, isTrue);
        expect(bundle.hasCompleted, isFalse);
        expect(controller.value, Locale(lateTag));
        // Localizations intentionally keeps the old resources while loading.
        expect(ChoreiaMessages.of(tester.element(find.byType(_Probe))).localeTag,
            'en');

        // The second selection is applied before the old asset is released.
        await controller.select(const Locale('en'), persist: false);
        await _flush(tester);
        _expectLatestEnglish(tester, controller, originalState);
        expect(bundle.hasCompleted, isFalse);

        // The first request now finishes out of order. It must not win.
        bundle.complete();
        await _flush(tester);
        _expectLatestEnglish(tester, controller, originalState);
        expect(tester.takeException(), isNull);
      } finally {
        // Release even after an assertion fails, draining the real delegate's
        // timeout and framework first-frame deferral before disposing fixtures.
        bundle.complete();
        await _flush(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        controller.dispose();
      }
    });
  }
}

Future<void> _flush(WidgetTester tester) async {
  // No fake five-second advance and no pumpAndSettle while the asset is held.
  // Zero-duration frames flush Future.wait + delegate/framework continuations.
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump();
  }
}

void _expectLatestEnglish(WidgetTester tester,
    ChoreiaLocaleController controller, _ProbeState originalState) {
  final context = tester.element(find.byType(_Probe));
  expect(controller.value, const Locale('en'));
  expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'));
  expect(Localizations.localeOf(context), const Locale('en'));
  expect(UiLanguage.locale(context), const Locale('en'));
  expect(ChoreiaMessages.of(context).localeTag, 'en');
  expect(Directionality.of(context), TextDirection.ltr);
  expect(WidgetsLocalizations.of(context).textDirection, TextDirection.ltr);
  expect(tester.widget<Text>(find.byKey(const Key('probe.translation'))).data,
      'Progress');
  expect(identical(tester.state<_ProbeState>(find.byType(_Probe)), originalState),
      isTrue);
  expect(find.text('counter=1'), findsOneWidget);
}

class _DelayedLocaleBundle extends CachingAssetBundle {
  _DelayedLocaleBundle(this.tag);
  final String tag;
  final Completer<String> _gate = Completer<String>();
  bool pendingAssetWasRequested = false;
  bool get hasCompleted => _gate.isCompleted;

  void complete() {
    if (!_gate.isCompleted) {
      _gate.complete(jsonEncode({'Progress': 'diagnostic-$tag'}));
    }
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key == 'content/l10n/ui.$tag.json') {
      pendingAssetWasRequested = true;
      return _gate.future;
    }
    if (key == 'content/l10n/course.index.json' ||
        key == 'content/l10n/course.$tag.json' ||
        key == 'content/l10n/catalog.$tag.json') {
      return Future<String>.value('{}');
    }
    return Future<String>.error(FlutterError('Unexpected fixture asset: $key'));
  }

  @override
  Future<ByteData> load(String key) => Future<ByteData>.error(
      FlutterError('Only JSON loadString is supported by this fixture: $key'));
}

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Text(UiLanguage.text(context, en: 'Progress', tr: 'İlerleme'),
              key: const Key('probe.translation')),
          Text('counter=$count'),
          TextButton(
            key: const Key('probe.increment'),
            onPressed: () => setState(() => count++),
            child: const Text('+'),
          ),
        ]),
      );
}
