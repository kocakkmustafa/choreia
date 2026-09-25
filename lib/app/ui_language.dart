import 'package:flutter/widgets.dart';

/// Small, dependency-free bridge for the app's own launch copy.
///
/// The device language selects Turkish or English. A full Flutter material
/// localization can be wired after the accepted Core pin/lock is reconciled;
/// this file deliberately does not change dependency resolution.
abstract final class UiLanguage {
  static String choose(
    String languageCode, {
    required String en,
    required String tr,
  }) => languageCode.toLowerCase() == 'tr' ? tr : en;

  static String text(
    BuildContext context, {
    required String en,
    required String tr,
  }) => choose(
    View.of(context).platformDispatcher.locale.languageCode,
    en: en,
    tr: tr,
  );

  static bool isTurkish(BuildContext context) =>
      View.of(context).platformDispatcher.locale.languageCode.toLowerCase() ==
      'tr';
}
