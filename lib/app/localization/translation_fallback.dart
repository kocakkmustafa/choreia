import 'package:flutter/material.dart';
import 'choreia_messages.dart';

/// This small fallback must stay available even when bundled JSON fails.
const translationFallbackCopy = <String, String>{
  'en':
      'Some text is shown in English because a translation could not be loaded.',
  'tr': 'Çeviri yüklenemediği için bazı metinler İngilizce gösteriliyor.',
  'es-419':
      'Algunos textos se muestran en inglés porque no se pudo cargar una traducción.',
  'pt-BR':
      'Alguns textos aparecem em inglês porque não foi possível carregar uma tradução.',
  'de':
      'Einige Texte erscheinen auf Englisch, weil eine Übersetzung nicht geladen werden konnte.',
  'fr':
      'Certains textes sont affichés en anglais, car une traduction n’a pas pu être chargée.',
  'ja': '翻訳を読み込めなかったため、一部の文章は英語で表示されています。',
  'ar': 'تُعرض بعض النصوص بالإنجليزية لتعذّر تحميل ترجمتها.',
  "it": "Alcuni testi sono mostrati in inglese perché non è stato possibile caricare una traduzione.",
  "ko": "번역을 불러오지 못해 일부 텍스트가 영어로 표시됩니다.",
  "id": "Sebagian teks ditampilkan dalam bahasa Inggris karena terjemahan tidak dapat dimuat.",
  "pl": "Niektóre teksty są wyświetlane po angielsku, ponieważ nie udało się wczytać tłumaczenia.",
  "hi": "अनुवाद लोड नहीं हो सका, इसलिए कुछ लिखित सामग्री अंग्रेज़ी में दिखाई जा रही है।",
  "zh-Hans": "由于无法加载翻译，部分文字以英语显示。",
};

class TranslationFallback extends StatelessWidget {
  const TranslationFallback({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final messages = ChoreiaMessages.of(context);
    if (!messages.translationUnavailable) return child;
    return Column(children: [
      Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
              bottom: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                      translationFallbackCopy[messages.localeTag] ??
                          translationFallbackCopy['en']!,
                      key: const Key('locale.translationUnavailable'))))),
      Expanded(child: child),
    ]);
  }
}
