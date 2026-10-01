import 'package:flutter/material.dart';

import '../shell/not_built_tab_body.dart';
import '../ui_language.dart';

/// The "Bugün" (Today) tab (roadmap §5.1).
///
/// Every noun in the roadmap's description — a daily eight-count, a path in
/// progress, a recovery suggestion, a rhythm goal — names a concept with no
/// data model anywhere in the app yet (measured, DEFTER C-321): there is no
/// stored "path", no daily-target tracker, no recovery-suggestion engine.
/// Building a Today screen that shows any of those would be inventing the
/// numbers it displays. This tab is honest about that instead.
class TodayView extends StatelessWidget {
  const TodayView({super.key});

  static const Key notBuiltKey = Key('shell.today.notBuilt');

  @override
  Widget build(BuildContext context) => notBuiltTabBody(
    context,
    key: notBuiltKey,
    title: UiLanguage.text(context, en: 'Today', tr: 'Bugün'),
    plannedContent: UiLanguage.text(
      context,
      en:
          "A daily eight-count, your path, and practice suggestions "
          'are not available here.',
      tr:
          'Günlük çalışma planı ve pratik önerileri bu bölümde '
          'kullanılamıyor.',
    ),
  );
}
