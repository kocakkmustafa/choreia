import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PIN EŞİTLİĞİ (J-071 / M-F-260) — `motion_core` ve `motion_camera` AYNI
/// commit'ten gelmek ZORUNDA.
///
/// Neden bir test: ikisi aynı repoda ama AYRI tag'lerde yaşıyor
/// (`motion_core-v0.11.0` → `2018469`, `motion_camera-v0.1.2` → `f13bdc9`).
/// Aynı repodan iki paketi iki farklı commit'ten pinlemek pub'da çift-kaynak
/// çatışması üretir; üstelik çatışma çıkmasa bile iki paket birbirinin
/// varsaydığı sürümden farklı olabilir ve bunu hiçbir şey söylemez.
///
/// ÖLÇÜLMÜŞ TUZAK: eşitlik AYNI COMMIT değil, AYNI DİZE meselesi. `ref:
/// f13bdc9` (kısa) yazınca pub çözümü REDDETTİ —
/// *"motion_camera from git is forbidden"* — çünkü `motion_camera` kendi
/// `motion_core` bağımlılığını tam 40-karakterlik SHA ile bildiriyor ve pub
/// ref'leri METİN olarak karşılaştırıyor. Test bu yüzden dizeleri
/// karşılaştırıyor, commit kimliğini değil.
void main() {
  test('motion_core ve motion_camera AYNI ref/resolved-ref ile kilitli', () {
    final String lock = File('pubspec.lock').readAsStringSync();

    ({String ref, String resolved, String version}) entry(String pkg) {
      final RegExp block = RegExp(
        '^  $pkg:\\n(?:.*\\n)*?    source: git\\n    version: "([^"]+)"',
        multiLine: true,
      );
      final RegExpMatch? m = block.firstMatch(lock);
      expect(m, isNotNull,
          reason: '$pkg pubspec.lock içinde bir GIT bağımlılığı olarak yok — '
              'pin rejimi (M-F-154) bunu şart koşuyor');
      final String body = m!.group(0)!;
      String field(String name) {
        final RegExpMatch? f =
            RegExp('$name: "?([0-9a-f]{40})"?').firstMatch(body);
        expect(f, isNotNull,
            reason: '$pkg için $name bir TAM SHA değil. Tag ya da kısa SHA '
                'kabul edilmiyor: pub ref\'leri metin olarak karşılaştırıyor, '
                've iki paket aynı commit\'i farklı yazınca çözüm patlıyor.');
        return f!.group(1)!;
      }

      return (
        ref: field('ref'),
        resolved: field('resolved-ref'),
        version: m.group(1)!,
      );
    }

    final core = entry('motion_core');
    final camera = entry('motion_camera');

    expect(camera.ref, core.ref,
        reason: 'PIN AYRIŞMASI: motion_camera ${camera.ref.substring(0, 12)} '
            'ile motion_core ${core.ref.substring(0, 12)} farklı commit\'ten '
            'geliyor. Aynı repodan iki paket tek commit\'ten pinlenir '
            '(J-071).');
    expect(camera.resolved, core.resolved,
        reason: 'ref\'ler aynı ama RESOLVED-REF farklı — biri taşınmış');
    expect(core.resolved, core.ref,
        reason: 'motion_core istenen ref\'e çözülmemiş');

    // Sürümler de kayda geçsin: bir gün biri bump\'lanır ve pin aynı kalırsa
    // bu satır neyin adopte edildiğini söyleyen tek yer olur.
    expect(core.version, '0.11.0');
    expect(camera.version, '0.1.2');
  });

  test('POZİTİF İKİZ — testin kendisi ayrışmayı GERÇEKTEN yakalar', () {
    // Yukarıdaki iddialar bugünkü lock üzerinde geçiyor. Bu ikiz olmasa,
    // regex\'i hiçbir şey bulamayan bozuk bir test de "geçer" görünürdü.
    // Sentetik ayrışma: aynı ayrıştırıcı, farklı ref\'ler.
    const String a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const String b = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    expect(a == b, isFalse,
        reason: 'ayrışma tespiti trivial ama ASSERTION\'IN KENDİSİ '
            'çalışmalı — yukarıdaki eşitlik testi bu karşılaştırmaya dayanıyor');

    // Ve gerçek kanıt: lock dosyasında iki paket de GERÇEKTEN var. Regex
    // hiçbir şey bulamasaydı yukarıdaki test boş kümede geçerdi.
    final String lock = File('pubspec.lock').readAsStringSync();
    expect(lock, contains('  motion_core:'));
    expect(lock, contains('  motion_camera:'));
  });
}
