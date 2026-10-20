import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'localization/choreia_locale.dart';
import 'localization/choreia_messages.dart';

/// Respects the app selection, then the resolved system locale.
abstract final class UiLanguage {
  static String choose(
    String languageCode, {
    required String en,
    required String tr,
  }) =>
      languageCode.toLowerCase() == 'tr' ? tr : en;

  static String text(
    BuildContext context, {
    required String en,
    required String tr,
  }) {
    if (isTurkish(context)) {
      return tr == en ? ChoreiaMessages.of(context).translate(en) : tr;
    }
    return ChoreiaMessages.of(context).translate(en);
  }

  static bool isTurkish(BuildContext context) =>
      locale(context).languageCode == 'tr';

  static Locale locale(BuildContext context) =>
      Localizations.maybeLocaleOf(context) ??
      ChoreiaLocaleController.resolve(
          View.of(context).platformDispatcher.locale, const []);

  static String tag(BuildContext context) =>
      ChoreiaLocaleController.tag(locale(context));

  static String courseText(BuildContext context, Map<String, String> pair) =>
      text(context, en: pair['en']!, tr: pair['tr']!);

  /// Keeps the existing isolated reader's TR/EN override while the real app
  /// consistently inherits its selected locale on all routes.
  static String pair(BuildContext context,
          {required bool turkish, required String en, required String tr}) =>
      ChoreiaLocaleScope.maybeOf(context) == null
          ? (turkish ? tr : en)
          : text(context, en: en, tr: tr);

  /// Translate the template before inserting values. Catalogue validation
  /// enforces identical placeholder names across locales.
  static String format(BuildContext context,
      {required String en,
      required String tr,
      required Map<String, Object> values}) {
    var result = text(context, en: en, tr: tr);
    final placeholders = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}')
        .allMatches(en)
        .map((match) => match[1]!)
        .toSet();
    if (placeholders.length != values.length ||
        !placeholders.every(values.containsKey)) {
      throw ArgumentError(
          'Message values must match the template placeholders.');
    }
    for (final entry in values.entries) {
      final value = entry.value;
      final display = value is num ? number(context, value) : value.toString();
      result = result.replaceAll('{${entry.key}}', display);
    }
    return result;
  }

  static String number(BuildContext context, num value) =>
      NumberFormat.decimalPattern(tag(context).replaceAll('-', '_'))
          .format(value);

  static String date(BuildContext context, DateTime value) =>
      DateFormat.yMMMd(tag(context).replaceAll('-', '_')).format(value);

  static String currency(
          BuildContext context, num value, String currencyCode) =>
      NumberFormat.simpleCurrency(
              locale: tag(context).replaceAll('-', '_'), name: currencyCode)
          .format(value);
}
