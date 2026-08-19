/// ANDROID RELEASE İMZASI — sessiz debug-imzası kapatıldı (jablab J-215
/// deseni), CHO-P0-002'de gravita/lissom emsaliyle `allowDebugSigning`
/// bilerek-opt-in bayrağına genişletildi.
///
/// ## Neden bu dosya var, ve neden POZİTİF-VARLIK + SABOTAJ (metin-regex DEĞİL)
///
/// İlk sürüm (motion-core, `a3eab87`) tek bir negatif regex kullanıyordu:
/// "signingConfig = signingConfigs.getByName(\"debug\")" satırı YOK mu. CHO-
/// P0-002 CI'da/yerelde GERÇEK bir `flutter build appbundle --release`
/// koşumu istiyor — ve CI'da gerçek keystore yok ve olmamalı. Yani artık
/// BİLEREK bir debug-imza yolu VAR (`allowDebugSigning`); o satır artık
/// dosyada duruyor ve bu doğru. Negatif regex bu geçişte anlamını kaybetti.
///
/// Panzehir gravita/lissom'un `release_signing_test.dart`ından: kaynağın
/// KRİTİK PARÇALARININ (seçim mantığı + gürültülü durdurucu + opt-in bayrağı)
/// hâlâ orada olduğunu pozitif olarak doğrula, VE bir sabotaj ikiziyle
/// durdurucuyu KALDIRIP testin gerçekten kırmızı yandığını kanıtla — aksi
/// hâlde "kapı var" testi durdurucu sessizce silinse bile yeşil kalabilirdi.
///
/// ⚠️ NE ÖLÇMÜYOR: Gradle'ın GERÇEKTEN durduğunu/uyardığını — o, gerçek bir
/// `./gradlew`/`flutter build` koşumuyla ayrı doğrulanır (bu oturumda
/// `docs/evidence/production-line/CHO-P0-002/` altında). Bu dosya yalnız
/// KAYNAK METNİNİN kritik parçaları taşıdığını nöbetler.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _gradlePath = 'android/app/build.gradle.kts';

void main() {
  test('imza seçim mantığı, opt-in bayrağı VE gürültülü durdurucu kaynakta',
      () {
    final String src = File(_gradlePath).readAsStringSync();
    final Map<String, String> mustContain = <String, String>{
      'gerçek keystore kontrolü': 'hasKeystore',
      'bilerek debug-imza opt-in bayrağı': 'allowDebugSigning',
      'sessiz debug düşüşü yok (else dalı null)': 'else -> null',
      'ayrı durdurucu blok': 'gradle.taskGraph.whenReady',
      'sessiz düşüşü durduran gürültülü hata': 'throw GradleException(',
      'bayrakla geçildiğinde durdurmak yerine uyarma': 'logger.warn(',
      'yalnız RELEASE görevlerine daraltma': 'contains("Release")',
    };
    final List<String> missing = <String>[
      for (final MapEntry<String, String> e in mustContain.entries)
        if (!src.contains(e.value)) '${e.key}: «${e.value}» bulunamadı',
    ];
    expect(missing, isEmpty,
        reason: 'RELEASE İMZASI GUARD\'I ZAYIFLADI:\n${missing.join("\n")}\n\n'
            'Bu, release artefaktın debug anahtarıyla SESSİZCE üretilip '
            'Play tarafından reddedilmesi riskini geri getirir.');
  });

  test('SABOTAJ — durdurucu tamamen kaldırılsa nöbet gerçekten ateşliyor mu',
      () {
    final String real = File(_gradlePath).readAsStringSync();
    // `if (!hasKeystore) { gradle.taskGraph.whenReady { ... } }` bloğunun
    // TAMAMINI (dosyanın sonuna kadar) düş — Gradle söz diziminde en son
    // bildirim olduğu için bu geçerli bir sabotajdır.
    final int idx = real.indexOf('if (!hasKeystore) {');
    expect(idx, greaterThan(0),
        reason: 'Sabotaj kurulamadı — gerçek dosyada durdurucu blok YOK, bu '
            'ikiz hiçbir şey ölçmez.');
    final String sabotaged = real.substring(0, idx);
    expect(sabotaged.length, lessThan(real.length),
        reason: 'Sabotaj uygulanamadıysa bu ikiz hiçbir şey ölçmez.');
    expect(sabotaged.contains('throw GradleException('), isFalse,
        reason: 'Saptayıcı sentetik eksiği göremiyorsa gerçeğini de '
            'göremez.');
    // `allowDebugSigning` val'ı `android {}` bloğundan ÖNCE bildirilir —
    // truncate noktasının üstünde kalır, kasıtlı olarak. Sabotaj yalnız
    // DURDURUCUYU (whenReady + throw + warn) düşürür, bayrağın seçim
    // mantığındaki varlığını değil; ①'deki pozitif test bunu zaten ayrıca
    // doğruluyor.
  });

  test('⛔ SIR DEPOYA GİREMEZ — key.properties ve keystore git-dışı', () {
    final String ignore = File('android/.gitignore').readAsStringSync();
    for (final String pat in <String>['key.properties', '*.keystore', '*.jks']) {
      expect(ignore, contains(pat),
          reason: '$pat .gitignore\'da değil — imza sırrı depoya sızabilir');
    }
    expect(File('android/key.properties').existsSync(), isFalse,
        reason: 'key.properties çalışma ağacında VAR — içeriği sır, bu '
            'testin kendisi onu okumaz ama varlığı beklenmiyor');
  });
}
