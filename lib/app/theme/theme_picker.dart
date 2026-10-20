import 'dart:async';
import 'package:flutter/material.dart';
import '../ui_language.dart';
import 'theme_preference.dart';

class ChoreiaThemePicker extends StatelessWidget {
  const ChoreiaThemePicker({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = ChoreiaThemeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    String text(String en, String tr) => UiLanguage.text(context, en: en, tr: tr);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text('Appearance', 'Görünüm'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final mode in ThemeMode.values)
            ChoiceChip(
              key: Key('theme.choice.${mode.name}'),
              label: Text(switch (mode) {
                ThemeMode.system => text('System theme', 'Sistem teması'),
                ThemeMode.light => text('Light theme', 'Açık tema'),
                ThemeMode.dark => text('Dark theme', 'Koyu tema'),
              }),
              selected: controller.value == mode,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => unawaited(controller.select(mode)),
            ),
        ]),
        if (controller.saveFailed || controller.readFailed)
          Semantics(liveRegion: true, child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(controller.saveFailed
              ? text('This theme applies for this session. The device preference could not be saved.', 'Bu tema bu oturumda geçerli. Cihaz tercihi kaydedilemedi.')
              : text('Your saved theme could not be read. System theme is used until you choose another option.', 'Kayıtlı temanız okunamadı. Başka bir seçenek belirleyene kadar sistem teması kullanılır.'),
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          )),
      ]),
    );
  }
}
