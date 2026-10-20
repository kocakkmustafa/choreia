// Public-contract regressions for AUX03; test definitions are not acceptance.
// Eight independently authored cases plus two root cold-frame cases.
// Public ChoreiaApp/controller API read from frozen dbbabea3fd15f46d38ab7409bdc094504bbafca3.
// No private resource-wrapper API, live account or native-provider execution, or
// translation/native-device acceptance. Fixture strings identify resource sets;
// they are deliberately not production translations.
//
// API notes: TestPlatformDispatcher.localesTestValue invokes onLocaleChanged
// in the installed Flutter test source. Zero-duration pump flushes microtasks.
// The five-second case advances fake time explicitly; no real sleep/runAsync.
// MaterialApp.locale may be null for system mode or a prepared canonical locale;
// assertions use the effective Localizations/messages/direction contract.
import 'dart:async';
import 'dart:convert';

import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/ui_language.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _appKey = Key('resource.regression.app');
const _probeKey = Key('resource.regression.probe');
const _translationKey = Key('resource.regression.translation');
const _openKey = Key('resource.regression.open');
const _fieldKey = Key('resource.regression.field');
const _incrementKey = Key('resource.regression.increment');

void main() {
  testWidgets('new AR completes before old FR and stays authoritative',
      (tester) async {
    await _withHarness(tester, (h) async {
      h.bundle.hold('fr');
      h.bundle.hold('ar');
      await h.select('fr');
      h.bundle.expectPending('fr');
      await h.select('ar');
      h.bundle.expectPending('ar');
      h.bundle.complete('ar');
      await _flush(tester);
      _expectEffective(h, 'ar');
      h.bundle.expectPending('fr');
      h.bundle.complete('fr');
      await _flush(tester);
      _expectEffective(h, 'ar');
    });
  });

  testWidgets('old FR read failure cannot replace the newer EN resources',
      (tester) async {
    await _withHarness(tester, (h) async {
      h.bundle.hold('fr');
      await h.select('fr');
      h.bundle.expectPending('fr');
      await h.select('en');
      _expectEffective(h, 'en');
      h.bundle.fail('fr');
      await _flush(tester);
      _expectEffective(h, 'en');
    });
  });

  testWidgets('old AR five-second timeout cannot replace EN or add its banner',
      (tester) async {
    await _withHarness(tester, (h) async {
      h.bundle.hold('ar');
      await h.select('ar');
      h.bundle.expectPending('ar');
      await h.select('en');
      _expectEffective(h, 'en');
      // Fake time exercises the real delegate timeout, not a timeout stub.
      await tester.pump(const Duration(seconds: 5, milliseconds: 1));
      await _flush(tester);
      _expectEffective(h, 'en');
      h.bundle.expectPending('ar');
      // timeout != cancellation: also drain the still-pending underlying read.
      h.bundle.complete('ar');
      await _flush(tester);
      _expectEffective(h, 'en');
    });
  });

  testWidgets('rapid ordered OS lists cannot override the explicit EN choice',
      (tester) async {
    tester.platformDispatcher.localesTestValue = const [
      Locale('ru'),
      Locale('en'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _withHarness(tester, (h) async {
      expect(h.controller.value, isNull);
      h.bundle.hold('fr');
      h.bundle.hold('ar');
      tester.platformDispatcher.localesTestValue = const [
        Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
        Locale('fr', 'CA'),
      ];
      await _flush(tester);
      h.bundle.expectPending('fr');
      tester.platformDispatcher.localesTestValue = const [
        Locale('ru'),
        Locale('ar', 'EG'),
      ];
      await _flush(tester);
      h.bundle.expectPending('ar');
      await h.select('en');
      _expectEffective(h, 'en');
      h.bundle.complete('ar');
      h.bundle.complete('fr');
      await _flush(tester);
      _expectEffective(h, 'en');
      // Another OS event must respect the already explicit selection too.
      tester.platformDispatcher.localesTestValue = const [Locale('ar')];
      await _flush(tester);
      _expectEffective(h, 'en');
    }, initialLocale: null);
  });

  testWidgets('a replaced bundle wins over the old same-locale response',
      (tester) async {
    await _withHarness(tester, (h) async {
      final oldBundle = h.bundle;
      oldBundle.hold('fr');
      await h.select('fr');
      oldBundle.expectPending('fr');
      final replacement = h.newBundle('replacement');
      h.bundle = replacement;
      await h
          .mount(); // Same ChoreiaApp key/controller, different localeBundle.
      await _flush(tester);
      _expectEffective(h, 'fr');
      expect(replacement.requested('fr'), isTrue);
      oldBundle.complete('fr');
      await _flush(tester);
      _expectEffective(
          h, 'fr'); // Also checks the replacement marker, not tag only.
    });
  });

  testWidgets('controller replacement and retirement invalidate an old read',
      (tester) async {
    await _withHarness(tester, (h) async {
      final oldController = h.controller;
      h.bundle.hold('fr');
      await h.select('fr');
      h.bundle.expectPending('fr');
      h.controller = h.newController(const Locale('en'));
      await h.mount();
      await _flush(tester);
      h.retire(oldController);
      _expectEffective(h, 'en');
      h.bundle.complete('fr');
      await _flush(tester);
      _expectEffective(h, 'en');
    });
  });

  testWidgets('completion after app disposal cannot poison the next app',
      (tester) async {
    await _withHarness(tester, (h) async {
      final oldBundle = h.bundle;
      final oldController = h.controller;
      oldBundle.hold('ar');
      await h.select('ar');
      oldBundle.expectPending('ar');
      await tester.pumpWidget(const SizedBox.shrink());
      await _flush(tester);
      h.retire(oldController);
      oldBundle.complete('ar');
      await _flush(tester);
      expect(tester.takeException(), isNull);
      h.bundle = h.newBundle('next-app');
      h.controller = h.newController(const Locale('en'));
      await h.mount();
      await _flush(tester);
      _expectEffective(h, 'en');
      expect(tester.binding.sendFramesToEngine, isTrue);
    });
  });

  testWidgets('an open Navigator route keeps draft focus counter and State',
      (tester) async {
    await _withHarness(tester, (h) async {
      await tester.tap(find.byKey(_openKey));
      await tester
          .pumpAndSettle(); // No pending asset and field not focused yet.
      final route = tester.state<_RouteProbeState>(find.byType(_RouteProbe));
      final field = tester.widget<TextField>(find.byKey(_fieldKey));
      final originalController = field.controller!;
      final originalFocus = field.focusNode!;
      const draft = 'draft — uncertain 1 & 2';
      await tester.enterText(find.byKey(_fieldKey), draft);
      await tester.tap(find.byKey(_incrementKey));
      originalFocus.requestFocus();
      await tester.pump();
      void expectRoute() {
        expect(
            identical(tester.state<_RouteProbeState>(find.byType(_RouteProbe)),
                route),
            isTrue);
        final currentField = tester.widget<TextField>(find.byKey(_fieldKey));
        expect(identical(currentField.controller, originalController), isTrue);
        expect(identical(currentField.focusNode, originalFocus), isTrue);
        expect(currentField.controller!.text, draft);
        expect(originalFocus.hasFocus, isTrue);
        expect(find.text('counter=1'), findsOneWidget);
        final context = tester.element(find.byKey(_probeKey));
        expect(ModalRoute.of(context)!.isCurrent, isTrue);
        expect(Navigator.of(context).canPop(), isTrue);
      }

      expectRoute();
      h.bundle.hold('fr');
      h.bundle.hold('ar');
      await h.select('fr');
      h.bundle.expectPending('fr');
      expectRoute();
      await h.select('ar');
      h.bundle.expectPending('ar');
      h.bundle.complete('ar');
      await _flush(tester);
      _expectEffective(h, 'ar');
      expectRoute();
      h.bundle.complete('fr');
      await _flush(tester);
      _expectEffective(h, 'ar');
      expectRoute();
    });
  });
  // Root additions: cold start and disposal must balance first-frame ownership.
  testWidgets('initial AR waits for the requested resource before visible text',
      (tester) async {
    tester.binding.resetFirstFrameSent();
    final h = _Harness(tester, const Locale('ar'));
    h.bundle.hold('ar');
    try {
      await h.mount();
      await _flush(tester);
      h.bundle.expectPending('ar');
      expect(find.byKey(_probeKey), findsNothing);
      expect(find.text('Progress'), findsNothing);
      expect(tester.binding.sendFramesToEngine, isFalse);
      h.bundle.complete('ar');
      await _flush(tester);
      _expectEffective(h, 'ar');
      expect(tester.binding.sendFramesToEngine, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      await h.close();
    }
  });

  testWidgets('disposing an initial resource load releases its first frame',
      (tester) async {
    tester.binding.resetFirstFrameSent();
    final h = _Harness(tester, const Locale('ar'));
    h.bundle.hold('ar');
    try {
      await h.mount();
      await _flush(tester);
      h.bundle.expectPending('ar');
      expect(tester.binding.sendFramesToEngine, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await _flush(tester);
      expect(tester.binding.sendFramesToEngine, isTrue);
      // The unmounted loader is still pending; timeout is not cancellation.
      h.bundle.expectPending('ar');
      h.bundle.complete('ar');
      await _flush(tester);
      expect(tester.binding.sendFramesToEngine, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      await h.close();
    }
  });
}

Future<void> _withHarness(
    WidgetTester tester, Future<void> Function(_Harness) body,
    {Locale? initialLocale = const Locale('en')}) async {
  final harness = _Harness(tester, initialLocale);
  try {
    await harness.mount();
    await tester
        .pumpAndSettle(); // All cases start at the completed warm EN state.
    _expectEffective(harness, 'en');
    await body(harness);
    expect(tester.takeException(), isNull);
  } finally {
    await harness.close();
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump();
  }
}

void _expectEffective(_Harness h, String tag) {
  final context = h.tester.element(find.byKey(_probeKey));
  final expected = Locale(tag); // These fixtures request EN, FR and AR only.
  final selected = h.controller.value;
  if (selected != null) expect(selected, expected);
  final configured =
      h.tester.widget<MaterialApp>(find.byType(MaterialApp)).locale;
  if (configured != null) {
    expect(
        ChoreiaLocaleController.resolve(
            configured, ChoreiaLocaleController.supported),
        expected);
  }
  expect(Localizations.localeOf(context), expected);
  expect(UiLanguage.locale(context), expected);
  final messages = ChoreiaMessages.of(context);
  expect(messages.localeTag, tag);
  expect(messages.translationUnavailable, isFalse);
  expect(find.byKey(const Key('locale.translationUnavailable')), findsNothing);
  final direction = tag == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  expect(Directionality.of(context), direction);
  expect(WidgetsLocalizations.of(context).textDirection, direction);
  expect(h.tester.widget<Text>(find.byKey(_translationKey)).data,
      tag == 'en' ? 'Progress' : h.bundle.marker(tag));
}

class _Harness {
  _Harness(this.tester, Locale? initialLocale) {
    controller = newController(initialLocale);
    bundle = newBundle('initial');
  }
  final WidgetTester tester;
  final List<ChoreiaLocaleController> _controllers = [];
  final Set<ChoreiaLocaleController> _retired = {};
  final List<_ControlledBundle> _bundles = [];
  late ChoreiaLocaleController controller;
  late _ControlledBundle bundle;

  ChoreiaLocaleController newController(Locale? locale) {
    final result = ChoreiaLocaleController.memory(locale);
    _controllers.add(result);
    return result;
  }

  _ControlledBundle newBundle(String id) {
    final result = _ControlledBundle(id);
    _bundles.add(result);
    return result;
  }

  void retire(ChoreiaLocaleController value) {
    if (_retired.add(value)) value.dispose();
  }

  Future<void> select(String tag) async {
    await controller.select(Locale(tag), persist: false);
    await _flush(tester);
  }

  Future<void> mount() => tester.pumpWidget(ChoreiaApp(
        key: _appKey,
        localeController: controller,
        localeBundle: bundle,
        shellBuilder: (_, __) => const _Entry(),
      ));

  Future<void> close() async {
    try {
      for (final value in _bundles) {
        value.completeAll();
      }
      await _flush(tester);
    } finally {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
      } finally {
        for (final value in _controllers) {
          retire(value);
        }
      }
    }
  }
}

class _ControlledBundle extends CachingAssetBundle {
  _ControlledBundle(this.id);
  final String id;
  final Map<String, Completer<String>> _gates = {};
  final Set<String> _requested = {};

  String marker(String tag) => 'resource-set:$id:$tag';
  bool requested(String tag) => _requested.contains(tag);

  void hold(String tag) {
    if (_gates.containsKey(tag)) {
      throw StateError('Duplicate fixture gate: $tag');
    }
    _gates[tag] = Completer<String>();
  }

  void expectPending(String tag) {
    expect(requested(tag), isTrue,
        reason: '$id/$tag must actually have started');
    expect(_gates.containsKey(tag), isTrue);
    expect(_gates[tag]!.isCompleted, isFalse);
  }

  void complete(String tag) {
    final gate = _gates[tag];
    if (gate != null && !gate.isCompleted) {
      gate.complete(jsonEncode({'Progress': marker(tag)}));
    }
  }

  void fail(String tag) {
    expectPending(
        tag); // The delegate has attached its real Future.wait listener.
    _gates[tag]!.completeError(
        FlutterError('Controlled old locale read failure: $id/$tag'));
  }

  void completeAll() {
    for (final tag in _gates.keys) {
      complete(tag);
    }
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key == 'content/l10n/course.index.json') {
      return Future<String>.value('{}');
    }
    final match = RegExp(r'^content/l10n/(course|ui|catalog)\.([^/]+)\.json$')
        .firstMatch(key);
    if (match == null) {
      return Future<String>.error(
          FlutterError('Unexpected fixture asset: $key'));
    }
    if (match[1] != 'ui') return Future<String>.value('{}');
    final tag = match[2]!;
    _requested.add(tag);
    return _gates[tag]?.future ??
        Future<String>.value(jsonEncode({'Progress': marker(tag)}));
  }

  @override
  Future<ByteData> load(String key) => Future<ByteData>.error(
      FlutterError('Fixture supports JSON loadString only: $key'));
}

class _LocaleProbe extends StatelessWidget {
  const _LocaleProbe();
  @override
  Widget build(BuildContext context) => Builder(
        key: _probeKey,
        builder: (context) => Text(
          UiLanguage.text(context, en: 'Progress', tr: 'İlerleme'),
          key: _translationKey,
        ),
      );
}

class _Entry extends StatelessWidget {
  const _Entry();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          const _LocaleProbe(),
          TextButton(
            key: _openKey,
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _RouteProbe())),
            child: const Text('Open controlled route'),
          ),
        ]),
      );
}

class _RouteProbe extends StatefulWidget {
  const _RouteProbe();
  @override
  State<_RouteProbe> createState() => _RouteProbeState();
}

class _RouteProbeState extends State<_RouteProbe> {
  final text = TextEditingController();
  final focus = FocusNode();
  int count = 0;
  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Controlled route')),
        body: Column(children: [
          const _LocaleProbe(),
          TextField(key: _fieldKey, controller: text, focusNode: focus),
          Text('counter=$count'),
          TextButton(
            key: _incrementKey,
            onPressed: () => setState(() => count++),
            child: const Text('+'),
          ),
        ]),
      );
}
