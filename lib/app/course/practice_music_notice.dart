import '../ui_language.dart';
import 'package:flutter/material.dart';

/// Shared listening and sharing boundary, including the lesson language toggle.
class PracticeMusicNotice extends StatelessWidget {
  const PracticeMusicNotice({required this.turkish, super.key});

  final bool turkish;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiLanguage.pair(context, turkish: turkish, en: 'Music, timing and sharing', tr: 'Müzik, zamanlama ve paylaşım'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              UiLanguage.pair(context, turkish: turkish, en: "These courses supply no music or audible metronome. Follow your separate player's terms. Listening access does not grant rights to copy, distribute or synchronize music with a video; check music, recording and choreography rights before sharing. A count or metronome alone does not verify a song's beat 1, phrasing or musicality.", tr: 'Bu kurslar müzik veya sesli metronom sağlamaz. Ayrı oynatıcının koşullarına uy. Dinleme erişimi müziği kopyalama, dağıtma veya videoyla eşleme hakkı vermez; paylaşmadan önce beste, ses kaydı ve koreografi haklarını kontrol et. Sayı veya metronom tek başına parçanın 1 vuruşunu, cümle yapısını veya müzikaliteyi doğrulamaz.'),
            ),
          ],
        ),
      );
}
