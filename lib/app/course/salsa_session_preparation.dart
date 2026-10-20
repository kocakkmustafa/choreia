import 'package:flutter/material.dart';
import '../ui_language.dart';

import '../theme.dart';

/// Deliberately RAM-only: a saved lesson is not evidence of today's preparation.
class SalsaPreparationSession {
  SalsaPreparationSession({DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  DateTime? _acknowledgedOn;

  bool get acknowledged {
    final previous = _acknowledgedOn;
    final today = _now();
    return previous != null &&
        previous.year == today.year &&
        previous.month == today.month &&
        previous.day == today.day;
  }

  set acknowledged(bool value) => _acknowledgedOn = value ? _now() : null;
  void reset() => _acknowledgedOn = null;
}

class SalsaSessionPreparation extends StatelessWidget {
  const SalsaSessionPreparation({
    required this.turkish,
    required this.onPrepared,
    required this.onSpokenOnly,
    required this.onStop,
    super.key,
  });

  final bool turkish;
  final VoidCallback? onPrepared, onSpokenOnly;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    String t(String en, String tr) =>
        UiLanguage.pair(context, turkish: turkish, en: en, tr: tr);
    final steps = [
      t('Clear space; check that shoes and floor neither catch nor slip.',
          'Alanı boşalt; ayakkabı ve zeminin ne takıldığını ne kaydığını kontrol et.'),
      t('Start with easy walking in place and relaxed arms. Gradually increase the pace within comfort.',
          'Yerinde rahat yürüyüş ve gevşek kollarla başla. Tempoyu rahat sınırında kademeli artır.'),
      t('Gently move ankles, knees, hips and shoulders through a comfortable range. Avoid forcing or holding a deep stretch.',
          'Ayak bileği, diz, kalça ve omuzlarını rahat hareket aralığında yavaşça hareket ettir. Zorlama veya derin esnemede bekleme.'),
      t('Use small, slow weight transfers and familiar basic steps. Before turning, rehearse small step-around changes of direction; lift and replace each foot without twisting on a planted foot.',
          'Küçük, yavaş ağırlık aktarımları ve bildiğin temel adımları kullan. Dönüşten önce küçük adımlarla yön değiştirmeyi prova et; yere basılı ayağı burmadan her ayağı kaldırıp yeniden yerleştir.'),
    ];
    return GlassPanel(
      key: const Key('salsa.preparation'),
      tint: ChoreiaPalette.of(context).amber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('Prepare for this session', 'Bu oturuma hazırlan'),
            style: ChoreiaType.of(context).display(size: 25)),
        const SizedBox(height: 12),
        for (final (index, step) in steps.indexed)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('${index + 1}. $step', style: ChoreiaType.of(context).body())),
        Text(
            t('Take the time you need; reading this card is not warming up. Stop for pain, dizziness or feeling unwell. You may read or count aloud without dancing.',
                'Gereken zamanı ayır; kartı okumak ısınmak değildir. Ağrı, baş dönmesi veya kötü hissetmede dur. Dans etmeden okuyabilir veya sesli sayabilirsin.'),
            style: ChoreiaType.of(context).body()),
        const SizedBox(height: 12),
        FilledButton.tonal(
            key: const Key('salsa.preparation.acknowledge'),
            onPressed: onPrepared,
            child: Text(t('I have prepared for this session',
                'Bu oturum için hazırlığımı yaptım'))),
        Text(
            t('Your report only; the app has not checked readiness or medical suitability.',
                'Yalnız senin beyanın; uygulama hazır oluşunu veya sağlık açısından uygunluğu kontrol etmez.'),
            style: ChoreiaType.of(context).body()),
        TextButton(
            key: const Key('salsa.preparation.spokenOnly'),
            onPressed: onSpokenOnly,
            child:
                Text(t('Read / count aloud only', 'Yalnız oku / sesli say'))),
        TextButton(
            key: const Key('salsa.preparation.stop'),
            onPressed: onStop,
            child: Text(t('Stop · back to course', 'Dur · kursa dön'))),
        ExpansionTile(
            title: Text(t('Preparation source', 'Hazırlık kaynağı')),
            children: [
              Text(
                  t('IADMS · The Importance of a Good Warm-Up (2025). Salsa examples are original course drills.',
                      'IADMS · The Importance of a Good Warm-Up (2025). Salsa örnekleri özgün kurs alıştırmalarıdır.'),
                  style: ChoreiaType.of(context).body()),
            ]),
      ]),
    );
  }
}
