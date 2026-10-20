import 'dart:async';
import 'package:flutter/material.dart';

import '../ui_language.dart';
import 'choreia_locale.dart';

class ChoreiaLanguagePicker extends StatelessWidget {
  const ChoreiaLanguagePicker({this.compact = false, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = ChoreiaLocaleScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final selected = controller.value;
    final name = selected == null
        ? UiLanguage.text(context, en: 'System language', tr: 'Sistem dili')
        : ChoreiaLocaleController.names[ChoreiaLocaleController.tag(selected)]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PopupMenuButton<String>(
        key: const Key('profile.language'),
        tooltip: UiLanguage.text(context, en: 'Language', tr: 'Dil'),
        initialValue:
            selected == null ? 'system' : ChoreiaLocaleController.tag(selected),
        onSelected: (tag) => unawaited(controller.select(tag == 'system'
            ? null
            : ChoreiaLocaleController.supported.firstWhere(
                (locale) => ChoreiaLocaleController.tag(locale) == tag))),
        itemBuilder: (_) => [
          PopupMenuItem(
              value: 'system',
              child: Text(UiLanguage.text(context,
                  en: 'System language', tr: 'Sistem dili'))),
          for (final entry in ChoreiaLocaleController.names.entries)
            PopupMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        child: compact
            ? const SizedBox(width: 48, height: 48, child: Icon(Icons.language))
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          '${UiLanguage.text(context, en: 'Language', tr: 'Dil')}: $name'))
                ])),
      ),
      if (controller.readFailed && !compact)
        Semantics(
            liveRegion: true,
            child: Text(UiLanguage.text(context,
                en: 'Your saved language could not be read. System language is used until you choose another option.',
                tr: 'Kayıtlı diliniz okunamadı. Başka bir seçenek belirleyene kadar sistem dili kullanılır.'))),
      if (controller.persistenceFailed && !compact)
        Text(UiLanguage.text(context,
            en: 'This language works for this session. The device preference could not be saved.',
            tr: 'Dil bu oturumda geçerli. Cihaz tercihi kaydedilemedi.')),
    ]);
  }
}
