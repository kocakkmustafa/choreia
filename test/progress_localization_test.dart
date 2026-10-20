import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/localization/progress_messages.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = CourseCatalog(lessons: [], blockedGates: []);

Set<String> _placeholders(String text) => RegExp(r'\{(\w+)\}')
    .allMatches(text)
    .map((match) => match.group(1)!)
    .toSet();

Widget _screen(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: ChoreiaLocaleController.supported,
      localizationsDelegates: const [
        _ProgressMessagesDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            disableAnimations: true, textScaler: TextScaler.linear(2)),
        child: child!,
      ),
      home: ProgressView(
        summary: ProgressSummary.build(history: [], catalog: _catalog),
      ),
    );

void main() {
  test('Progress has the same complete key set in all eight locales', () {
    final expected = ChoreiaLocaleController.names.keys.toSet();
    expect(progressMessages.keys.toSet(), expected);
    final english = progressMessages['en']!;
    expect(english, hasLength(35));
    for (final locale in expected) {
      final messages = progressMessages[locale]!;
      expect(messages.keys.toSet(), english.keys.toSet(), reason: locale);
      for (final key in english.keys) {
        expect(messages[key]!.trim(), isNotEmpty, reason: '$locale: $key');
        expect(_placeholders(messages[key]!), _placeholders(key),
            reason: '$locale: $key');
        if (locale != 'en' && key != '—') {
          expect(messages[key], isNot(key),
              reason: '$locale must contain a translation rather than English');
        }
      }
    }
  });

  for (final locale in ChoreiaLocaleController.supported) {
    final tag = ChoreiaLocaleController.tag(locale);
    final messages = progressMessages[tag]!;

    test('$tag formatter receives templates and exact values in every branch',
        () {
      final used = <String>{};
      String translate(String template, Map<String, Object> values) {
        expect(messages.containsKey(template), isTrue,
            reason: '$tag: missing template $template');
        expect(values.keys.toSet(), _placeholders(template),
            reason: 'No unused value or missing placeholder: $tag: $template');
        used.add(template);
        var result = messages[template]!;
        for (final value in values.entries) {
          result = result.replaceAll('{${value.key}}', value.value.toString());
        }
        expect(_placeholders(result), isEmpty,
            reason: '$tag: unresolved placeholder');
        return result;
      }

      for (final count in [0, 1, 2, 3, 11, 100]) {
        ProgressStrings.historyPartial(count, format: translate);
        ProgressStrings.historyNoneReadable(count, format: translate);
        ProgressStrings.cycles(count, 0, format: translate);
        ProgressStrings.cycles(count, 120, format: translate);
        ProgressStrings.sessionsCompleted(0, count,
            anyTarget: false, format: translate);
        ProgressStrings.sessionsCompleted(0, count,
            anyTarget: true, format: translate);
        ProgressStrings.unmeasured(count, format: translate);
      }
      for (final seconds in [0, 59, 60, 3600, 3661]) {
        ProgressStrings.duration(seconds, format: translate);
      }
      for (final fidelity in HistoryFidelity.values) {
        ProgressSummary.retroactiveCreditNote(fidelity, format: translate);
      }
      for (final integrity in [
        HistoryIntegrity.notRecorded,
        HistoryIntegrity.unavailable,
        HistoryIntegrity.opened(unreadable: 1, readable: 0),
        HistoryIntegrity.opened(unreadable: 2, readable: 1),
      ]) {
        integrity.noteFor(format: translate);
      }
      ProgressStrings.demoOnlyMark(null, format: translate);
      ProgressStrings.demoOnlyMark('example', format: translate);
      expect(used, hasLength(21));
    });

    testWidgets('$tag narrow, large-text Progress uses the selected locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_screen(locale));
      await tester.pumpAndSettle();
      expect(find.text(messages['Progress']!), findsOneWidget);
      expect(
          find.text(messages[ProgressStrings.historyScope]!), findsOneWidget);
      expect(
          Directionality.of(
              tester.element(find.byKey(ProgressView.historyScopeKey))),
          tag == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
          find.byKey(ProgressView.emptyReasonKey), 250,
          scrollable: find.byType(Scrollable).first);
      expect(
          find.text(messages[ProgressStrings.emptyHistory]!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing display locale rebuilds Progress copy and direction',
      (tester) async {
    await tester.pumpWidget(_screen(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsOneWidget);

    await tester.pumpWidget(_screen(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text(progressMessages['ar']!['Progress']!), findsOneWidget);
    expect(find.text('Progress'), findsNothing);
    expect(
        Directionality.of(
            tester.element(find.byKey(ProgressView.historyScopeKey))),
        TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}

/// Injects the shipped Progress catalog into the production localization
/// lookup. This component test does not claim asset-loader or device coverage.
class _ProgressMessagesDelegate extends LocalizationsDelegate<ChoreiaMessages> {
  const _ProgressMessagesDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ChoreiaMessages> load(Locale locale) =>
      SynchronousFuture(ChoreiaMessages(
          ui: progressMessages[ChoreiaLocaleController.tag(locale)]!));

  @override
  bool shouldReload(_ProgressMessagesDelegate old) => false;
}
