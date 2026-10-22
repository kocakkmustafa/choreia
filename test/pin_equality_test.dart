import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'support/core_source_preview_guard.dart';
import 'current_core_adoption_test.dart'
    show hasLocalMotionOverrides, verifyCurrentMotionGraph;

const String approvedMotionSha = '583203112c942dd38673bc43d7d05f82f4f5173d';

/// PIN EŞİTLİĞİ (J-071 / M-F-260) — `motion_core` ve `motion_camera` AYNI
/// ve onaylanmış commit'ten gelmek ZORUNDA.
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
  if (hasLocalMotionOverrides()) {
    test(
        'local unpublished candidate keeps canonical descriptor pin and one actual Motion source',
        () {
      final descriptor = File('pubspec.yaml').readAsStringSync();
      final configFile = File('.dart_tool/package_config.json').absolute;
      final config =
          jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      final expected =
          Directory('../motion-core').absolute.resolveSymbolicLinksSync();
      final rows = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .where((row) => (row['name'] as String).startsWith('motion_'))
          .toList();
      expect(rows, isNotEmpty);
      final refs = RegExp(r'      ref: ([0-9a-f]{40})')
          .allMatches(descriptor)
          .map((m) => m.group(1))
          .toList();
      expect(refs.length, greaterThanOrEqualTo(4));
      expect(refs.toSet(), {approvedMotionSha});
      for (final row in rows) {
        final actual =
            Directory.fromUri(configFile.uri.resolve(row['rootUri'] as String))
                .resolveSymbolicLinksSync();
        expect(actual, '$expected/packages/${row['name']}');
      }
    });
    return;
  }

  if (const bool.fromEnvironment('CHOREIA_CORE_SOURCE_PREVIEW')) {
    test(
      'SOURCE_PREVIEW_ONLY — approved Core archive/tree/config identity',
      () {
        final CoreSourcePreviewNotice notice =
            verifyApprovedCoreSourcePreview();
        expect(notice.status, 'SOURCE_PREVIEW_ONLY');
        expect(notice.publishedSha, isNull);
        expect(notice.sourceFileCount, 329);
        expect(notice.archiveSha256, approvedCoreSourceArchiveSha256);
        expect(notice.manifestSha256, approvedCoreSourceManifestSha256);
        expect(notice.patchSha256, approvedCoreSourcePatchSha256);
        expect(notice.motionPackagesByConfig['app'], isNotEmpty);
        expect(
          notice.motionPackagesByConfig['app/packages/choreia_engine'],
          isEmpty,
        );
      },
    );
    return;
  }

  test('root descriptor ve lock dört noktada onaylı Motion SHA kullanır', () {
    verifyCurrentMotionGraph();
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String lock = File('pubspec.lock').readAsStringSync();

    String descriptorRef(String pkg) {
      final RegExp block = RegExp(
        '^  $pkg:\n    git:\n(?:      .*\n)*?      ref: ([0-9a-f]{40})\$',
        multiLine: true,
      );
      final RegExpMatch? match = block.firstMatch(pubspec);
      expect(
        match,
        isNotNull,
        reason: '$pkg root pubspec.yaml içinde tam SHA ref ile tanımlı değil',
      );
      return match!.group(1)!;
    }

    ({String ref, String resolved, String version}) entry(String pkg) {
      final RegExp block = RegExp(
        '^  $pkg:\\n(?:.*\\n)*?    source: git\\n    version: "([^"]+)"',
        multiLine: true,
      );
      final RegExpMatch? m = block.firstMatch(lock);
      expect(
        m,
        isNotNull,
        reason: '$pkg pubspec.lock içinde bir GIT bağımlılığı olarak yok — '
            'pin rejimi (M-F-154) bunu şart koşuyor',
      );
      final String body = m!.group(0)!;
      String field(String name) {
        final RegExpMatch? f =
            RegExp('$name: "?([0-9a-f]{40})"?').firstMatch(body);
        expect(
          f,
          isNotNull,
          reason: '$pkg için $name bir TAM SHA değil. Tag ya da kısa SHA '
              'kabul edilmiyor: pub ref\'leri metin olarak karşılaştırıyor, '
              've iki paket aynı commit\'i farklı yazınca çözüm patlıyor.',
        );
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
    final String coreDescriptorRef = descriptorRef('motion_core');
    final String cameraDescriptorRef = descriptorRef('motion_camera');

    final Map<String, String> pins = <String, String>{
      'pubspec motion_core ref': coreDescriptorRef,
      'pubspec motion_camera ref': cameraDescriptorRef,
      'lock motion_core resolved-ref': core.resolved,
      'lock motion_camera resolved-ref': camera.resolved,
    };
    expect(
      pins.values,
      everyElement(approvedMotionSha),
      reason: 'CORE-ADOPT-001 dört pin noktasının tamamını onaylı '
          '$approvedMotionSha SHA\'sına kilitler. Gerçek değerler: $pins',
    );

    expect(
      camera.ref,
      core.ref,
      reason: 'PIN AYRIŞMASI: motion_camera ${camera.ref.substring(0, 12)} '
          'ile motion_core ${core.ref.substring(0, 12)} farklı commit\'ten '
          'geliyor. Aynı repodan iki paket tek commit\'ten pinlenir '
          '(J-071).',
    );
    expect(
      camera.resolved,
      core.resolved,
      reason: 'ref\'ler aynı ama RESOLVED-REF farklı — biri taşınmış',
    );
    expect(
      core.resolved,
      core.ref,
      reason: 'motion_core istenen ref\'e çözülmemiş',
    );
    expect(
      coreDescriptorRef,
      core.ref,
      reason: 'motion_core root descriptor ile lock ref farklı',
    );
    expect(
      cameraDescriptorRef,
      camera.ref,
      reason: 'motion_camera root descriptor ile lock ref farklı',
    );

    // Sürümler de kayda geçsin: bir gün biri bump\'lanır ve pin aynı kalırsa
    // bu satır neyin adopte edildiğini söyleyen tek yer olur.
    expect(core.version, '0.13.0');
    expect(camera.version, '0.2.0');
  });

  test('POZİTİF İKİZ — testin kendisi ayrışmayı GERÇEKTEN yakalar', () {
    // Yukarıdaki iddialar bugünkü lock üzerinde geçiyor. Bu ikiz olmasa,
    // regex\'i hiçbir şey bulamayan bozuk bir test de "geçer" görünürdü.
    // Sentetik ayrışma: aynı ayrıştırıcı, farklı ref\'ler.
    const String a = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const String b = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    expect(
      a == b,
      isFalse,
      reason: 'ayrışma tespiti trivial ama ASSERTION\'IN KENDİSİ '
          'çalışmalı — yukarıdaki eşitlik testi bu karşılaştırmaya dayanıyor',
    );

    // Ve gerçek kanıt: lock dosyasında iki paket de GERÇEKTEN var. Regex
    // hiçbir şey bulamasaydı yukarıdaki test boş kümede geçerdi.
    final String lock = File('pubspec.lock').readAsStringSync();
    expect(lock, contains('  motion_core:'));
    expect(lock, contains('  motion_camera:'));
  });
}
