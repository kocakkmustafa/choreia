import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'choreia_locale.dart';
import 'progress_messages.dart';
import 'base_ui_messages.dart';
import 'base_catalog_messages.dart';

/// Overlays never change verified curriculum bytes, criterion IDs or versions.
class ChoreiaMessages {
  const ChoreiaMessages(
      {this.courseIndex = const {},
      this.course = const {},
      this.ui = const {},
      this.catalog = const {},
      this.localeTag = 'en',
      this.translationUnavailable = false});

  final Map<String, String> courseIndex;
  final Map<String, String> course;
  final Map<String, String> ui;
  final Map<String, String> catalog;
  final bool translationUnavailable;
  final String localeTag;

  String translate(String english) =>
      ui[english] ??
      progressMessages[localeTag]?[english] ??
      catalog[english] ??
      course[courseIndex[english]] ??
      english;

  static ChoreiaMessages of(BuildContext context) =>
      Localizations.of<ChoreiaMessages>(context, ChoreiaMessages) ??
      const ChoreiaMessages();
}

class ChoreiaMessagesDelegate extends LocalizationsDelegate<ChoreiaMessages> {
  const ChoreiaMessagesDelegate({this.bundle});
  final AssetBundle? bundle;
  @override
  bool isSupported(Locale locale) =>
      ChoreiaLocaleController.supported.any((supported) =>
          supported.languageCode == locale.languageCode.toLowerCase());

  @override
  Future<ChoreiaMessages> load(Locale locale) {
    final tag = ChoreiaLocaleController.tag(locale);
    if (tag == 'en' || tag == 'tr') {
      return SynchronousFuture(ChoreiaMessages(
          localeTag: tag,
          ui: baseUiMessages[tag] ?? const {},
          catalog: tag == 'tr' ? baseCatalogTurkish : const {}));
    }
    return _load(tag);
  }

  Future<ChoreiaMessages> _load(String tag) async {
    try {
      final assets = bundle ?? rootBundle;
      final results = await Future.wait([
        assets.loadString('content/l10n/course.index.json'),
        assets.loadString('content/l10n/course.$tag.json'),
        assets.loadString('content/l10n/ui.$tag.json'),
        assets.loadString('content/l10n/catalog.$tag.json'),
      ]).timeout(const Duration(seconds: 5));
      Map<String, String> decode(String text) =>
          (jsonDecode(text) as Map).cast<String, String>();
      return ChoreiaMessages(
          localeTag: tag,
          courseIndex: decode(results[0]),
          course: decode(results[1]),
          ui: decode(results[2]),
          catalog: decode(results[3]));
    } on Object {
      return ChoreiaMessages(localeTag: tag, translationUnavailable: true);
    }
  }

  @override
  bool shouldReload(ChoreiaMessagesDelegate old) => bundle != old.bundle;
}
