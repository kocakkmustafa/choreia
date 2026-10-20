import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui_language.dart';

enum SupportSurface { startup, catalog, profile, salsa }

/// User-controlled support handoff. Only fixed app/surface/locale metadata is
/// copied; this widget never reads identity, journals, camera frames or logs.
class SupportAction extends StatelessWidget {
  const SupportAction({required this.surface, super.key});
  final SupportSurface surface;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SelectableText('support@yulalab.com'),
          TextButton.icon(
            key: const Key('support.copy'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.copy),
            label: Text(UiLanguage.text(context,
                en: 'Copy support details', tr: 'Destek bilgilerini kopyala')),
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(
                    text:
                        'support@yulalab.com\nApp: Choreia\nSurface: ${surface.name}\nLocale: ${UiLanguage.tag(context)}'));
              } on Object {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(UiLanguage.text(context,
                        en: 'Could not copy. You can select the support address above.',
                        tr: 'Kopyalanamadı. Yukarıdaki destek adresini seçebilirsin.'))));
                return;
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(UiLanguage.text(context,
                      en: 'Support details copied.',
                      tr: 'Destek bilgileri kopyalandı.'))));
            },
          ),
        ],
      );
}
