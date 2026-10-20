import 'dart:convert';
import 'dart:io';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/localization/language_picker.dart';
import 'package:choreia/app/localization/translation_fallback.dart';
import 'package:choreia/app/ui_language.dart';
import 'package:choreia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_catalog.dart';

void main() {
  test('regional language requests resolve to the fourteen approved variants', () {
    final cases = <Locale, String>{
      Locale('tr', 'TR'): 'tr',
      Locale('en', 'GB'): 'en',
      Locale('es', 'MX'): 'es-419',
      Locale('es', 'ES'): 'es-419',
      Locale('pt', 'PT'): 'pt-BR',
      Locale('de', 'AT'): 'de',
      Locale('fr', 'CA'): 'fr',
      Locale('ja', 'JP'): 'ja',
      Locale('ar', 'EG'): 'ar',
      Locale('zh', 'CN'): 'zh-Hans',
      Locale('zh', 'TW'): 'en',
      Locale('zh', 'HK'): 'en',
      Locale('zh', 'MO'): 'en',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'CN'): 'en',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'TW'): 'zh-Hans',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'SG'): 'zh-Hans',
      Locale('it', 'IT'): 'it',
      Locale('ko', 'KR'): 'ko',
      Locale('id', 'ID'): 'id',
      Locale('pl', 'PL'): 'pl',
      Locale('hi', 'IN'): 'hi',
      Locale('ru'): 'en',
    };
    for (final entry in cases.entries) {
      expect(
          ChoreiaLocaleController.tag(ChoreiaLocaleController.resolve(
              entry.key, ChoreiaLocaleController.supported)),
          entry.value);
    }
    expect(const ChoreiaMessagesDelegate().isSupported(const Locale('ru')),
        isFalse);
  });

  testWidgets('system preferences skip an unsupported first language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ru'), Locale('fr', 'CA')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final controller = ChoreiaLocaleController.memory();
    addTearDown(controller.dispose);
    await tester.pumpWidget(ChoreiaApp(
      localeController: controller,
      localeBundle: DiskBundle(),
      shellBuilder: (_, __) => Builder(builder: (context) => Scaffold(
        body: Text(ChoreiaMessages.of(context).localeTag, key: const Key('ordered.locale')))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('fr'), findsOneWidget);
    await controller.select(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text('ar'), findsOneWidget);
    expect(ChoreiaLocaleController.resolveLocales(const [Locale('ru')], ChoreiaLocaleController.supported), const Locale('en'));
  });

  test('unsupported Chinese script never loads the Simplified asset', () async {
    const delegate = ChoreiaMessagesDelegate();
    for (final locale in const [
      Locale('zh', 'TW'), Locale('zh', 'HK'), Locale('zh', 'MO'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Latn'),
    ]) {
      expect(delegate.isSupported(locale), isFalse);
      expect((await delegate.load(locale)).localeTag, 'en');
      expect(ChoreiaLocaleController.resolveLocales([locale, const Locale('fr')], ChoreiaLocaleController.supported), const Locale('fr'));
    }
  });

  testWidgets('Traditional Chinese falls through to the next supported OS preference', (tester) async {
    tester.platformDispatcher.localesTestValue = const [
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
      Locale('fr', 'CA'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final controller = ChoreiaLocaleController.memory();
    addTearDown(controller.dispose);
    await tester.pumpWidget(ChoreiaApp(
      localeController: controller,
      localeBundle: DiskBundle(),
      shellBuilder: (_, __) => Builder(builder: (context) => Scaffold(
        body: Text(ChoreiaMessages.of(context).localeTag))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('fr'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ChoreiaLocaleController.supported) {
    final tag = ChoreiaLocaleController.tag(locale);
    testWidgets('$tag loads a real bundled course overlay and app locale',
        (tester) async {
      final controller = ChoreiaLocaleController.memory(locale);
      addTearDown(controller.dispose);
      final raw = jsonDecode(File('content/hip_hop_foundations_course.json')
          .readAsStringSync()) as Map<String, dynamic>;
      final title = (raw['title'] as Map).cast<String, String>();
      final index =
          (jsonDecode(File('content/l10n/course.index.json').readAsStringSync())
                  as Map)
              .cast<String, String>();
      final translated =
          (jsonDecode(File('content/l10n/course.$tag.json').readAsStringSync())
                  as Map)
              .cast<String, String>();
      final expected = translated[index[title['en']]]!;
      await tester.pumpWidget(ChoreiaApp(
        localeController: controller,
        localeBundle: DiskBundle(),
        shellBuilder: (_, __) => Builder(
            builder: (context) => Scaffold(
                    body: Column(children: [
                  Text(UiLanguage.courseText(context, title),
                      key: const Key('course.title')),
                  const ChoreiaLanguagePicker(),
                ]))),
      ));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      expect(
          Directionality.of(
              tester.element(find.byKey(const Key('course.title')))),
          tag == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('selection changes an open route without losing its local state',
      (tester) async {
    final controller = ChoreiaLocaleController.memory(const Locale('en'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(ChoreiaApp(
      localeController: controller,
      localeBundle: DiskBundle(),
      shellBuilder: (_, __) => Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const _OpenRoute())),
                  child: const Text('Open test route')))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open test route'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('route.increment')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await controller.select(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('التقدم'), findsOneWidget);
    expect(
        Directionality.of(
            tester.element(find.byKey(const Key('route.increment')))),
        TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('templates reject missing or unused values and format the locale',
      (tester) async {
    late BuildContext context;
    final controller = ChoreiaLocaleController.memory(const Locale('fr'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(ChoreiaApp(
      localeController: controller,
      localeBundle: DiskBundle(),
      shellBuilder: (_, __) => Builder(builder: (value) {
        context = value;
        return const Scaffold();
      }),
    ));
    await tester.pumpAndSettle();
    expect(
        () => UiLanguage.format(context,
            en: '{count} items', tr: '{count} öğe', values: {}),
        throwsArgumentError);
    expect(UiLanguage.number(context, 1234.5), contains(',5'));
    expect(UiLanguage.currency(context, 12.5, 'EUR'), contains('€'));
    expect(UiLanguage.date(context, DateTime(2026, 10, 20)), contains('2026'));
  });

  testWidgets('an unavailable translation is visible in the selected language',
      (tester) async {
    final controller = ChoreiaLocaleController.memory(const Locale('de'));
    addTearDown(controller.dispose);
    await tester.pumpWidget(ChoreiaApp(
        localeController: controller,
        localeBundle: _UnavailableBundle(),
        shellBuilder: (_, __) => Builder(
            builder: (context) => Scaffold(
                body: Text(UiLanguage.text(context,
                    en: 'Progress', tr: 'İlerleme'))))));
    await tester.pumpAndSettle();
    expect(find.text(translationFallbackCopy['de']!), findsOneWidget);
    expect(find.text('Fortschritt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _UnavailableBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('fixture asset unavailable');
}

class _OpenRoute extends StatefulWidget {
  const _OpenRoute();
  @override
  State<_OpenRoute> createState() => _OpenRouteState();
}

class _OpenRouteState extends State<_OpenRoute> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Column(children: [
        Text(UiLanguage.text(context, en: 'Progress', tr: 'İlerleme')),
        Text('$count'),
        TextButton(
            key: const Key('route.increment'),
            onPressed: () => setState(() => count++),
            child: const Text('+')),
      ]));
}
