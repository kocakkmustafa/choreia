import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/live/pose_model.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pose model pin, and the provenance this repo does NOT record.
void main() {
  group('pin', () {
    test('sürüm segmenti latest OLAMAZ', () {
      // Measured by the family (M-L-01): `/float16/latest/` and `/float16/1/`
      // are different files at IDENTICAL size for the `full` variant. A size
      // check passes, the joint angles shift, and every score drifts for a
      // reason no screen can explain. The word is banned rather than trusted.
      expect(PoseModelPin.versionSegment, '1');
      expect(PoseModelPin.assetPath, isNot(contains('latest')));
      expect(PoseModelPin.modelId, isNot(contains('latest')));
    });

    test('fetch betiği ile Dart pini AYNI hash ve AYNI yolu söylüyor', () {
      // Two declarations of one fact drift. The script is what puts the file
      // in place; the constant is what the app believes about it.
      final String sh = File('tool/fetch_pose_model.sh').readAsStringSync();
      expect(sh, contains(PoseModelPin.sha256),
          reason: 'betiğin doğruladığı hash ile PoseModelPin.sha256 ayrıştı');
      // The script COMPOSES its destination from shell variables, so the
      // literal path never appears in it. Comparing the literal would have
      // been a gate that could only fail — the first version did, and its
      // failure was about my regex, not about the code. Resolve the
      // composition instead.
      final String variant =
          RegExp(r'VARIANT="([^"]+)"').firstMatch(sh)!.group(1)!;
      final String dest = RegExp(r'DEST="([^"]+)"')
          .firstMatch(sh)!
          .group(1)!
          .replaceAll(r'${VARIANT}', variant);
      expect(dest, PoseModelPin.assetPath,
          reason: 'betiğin YAZDIĞI yol ile uygulamanın OKUDUĞU yol ayrıştı: '
              'betik $dest, uygulama ${PoseModelPin.assetPath}');
      expect(RegExp(r'VERSION="([^"]+)"').firstMatch(sh)!.group(1),
          PoseModelPin.versionSegment,
          reason: 'betiğin indirdiği sürüm ile pinlenen sürüm ayrıştı');
      // Scoped to the URL, NOT the file. The whole-file version fired on the
      // script's own comment WARNING against `latest` — a scan that reads
      // prose as code, which is the third time tonight. A gate's scope is
      // part of the gate.
      final String url = RegExp(r'^URL=.*$', multiLine: true)
          .firstMatch(sh)!
          .group(0)!;
      expect(url, isNot(contains('latest')),
          reason: 'betiğin indirme URL\'i latest gösteriyor: $url');
      expect(url, contains(r'${VERSION}'),
          reason: 'URL sürümü gömüyor — pin değiştiğinde indirme değişmez');
    });

    test('pubspec modeli BEYAN ediyor', () {
      // The asset is declared as a DIRECTORY on purpose: the file is not in
      // git, so a file-by-file entry would break the build on a fresh clone
      // before anyone ran the fetch script.
      expect(File('pubspec.yaml').readAsStringSync(),
          contains('assets/models/'));
    });

    test('dosya YERİNDEYSE hash zorunlu; yoksa İSİMLE atlanır', () {
      // Skipping is stated, never silent: a fresh clone has no `.task` and a
      // test that quietly passed there would be indistinguishable from one
      // that verified a good file.
      final File f = File(PoseModelPin.assetPath);
      if (!f.existsSync()) {
        markTestSkipped(
            '${PoseModelPin.assetPath} yok — `tool/fetch_pose_model.sh` '
            'koşulmamış. Hash DOĞRULANMADI.');
        return;
      }
      expect(sha256.convert(f.readAsBytesSync()).toString(),
          PoseModelPin.sha256,
          reason: 'modelin hash\'i pine uymuyor — referans artefaktları bu '
              'modelle üretilmediyse her puan sessizce kayar');
    });
  });

  group('🔴🔴 ÖLÇÜLDÜ: hasat MODELİ ile uygulamanın modeli UYUŞMUYOR (C-196)',
      () {
    test('harvest.py hangi varyantı çağırıyor', () {
      // The extractor's own default is `heavy`, and this repo's harvest passes
      // `heavy` explicitly. Every reference artefact in `content/references/`
      // was produced by that pipeline.
      final String harvest = File('tools/harvest.py').readAsStringSync();
      final RegExpMatch? m =
          RegExp(r'"--variant",\s*"(\w+)"').firstMatch(harvest);
      expect(m, isNotNull,
          reason: 'harvest.py artık --variant geçmiyor — hangi modelle hasat '
              'edildiği yeniden bilinmez oldu');
      expect(m!.group(1), 'heavy',
          reason: 'hasat varyantı değişti. Referanslar YENİDEN üretilmediyse '
              'eski artefaktlar hâlâ eski modelin sayılarını taşıyor');
    });

    test('UYUŞMAZLIK çivili: hasat heavy, uygulama full', () {
      // Measured 2026-08-07: JabLab and Ostinato harvest with `full` AND ship
      // `full` — consistent. Choreia harvests with `heavy` and, since the pose
      // pipeline landed an hour before this test, ships `full`. I copied a
      // sibling line's pin along with its recipe, and the pin was the one part
      // that had to match MY OWN references, not theirs.
      //
      // Why this is pinned rather than fixed here: both repairs are real
      // decisions, not cleanups. Shipping `heavy` keeps every measured number
      // in the artefacts meaningful but triples the model (9.4 -> 30.6 MB) on
      // a product whose whole subject is fast movement. Re-harvesting with
      // `full` keeps the app light and invalidates every tolerance, every
      // disagreement figure and the entire honesty block — a measurement
      // round, not an edit. That is a scope call.
      //
      // Why no user is harmed TODAY: the single openable lesson is
      // `demoOnly`, issues no score, and says in its own words that a number
      // here would mostly measure our uncertainty. An unverified pairing
      // cannot mislead through a number that is never shown. The day anything
      // scores, this stops being a record and becomes a blocker.
      expect(PoseModelPin.modelId, 'pose_landmarker_full/float16/1');
      expect(File('tools/harvest.py').readAsStringSync(),
          contains('"--variant", "heavy"'),
          reason: 'UYUŞMAZLIK KAPANMIŞ OLABİLİR — bu iyi haber. İki taraf da '
              'aynı varyantı söylüyorsa bu kaydı sil ve yerine GERÇEK '
              'eşitlik kapısını koy.');
    });
  });

  group('🔴 ÖLÇÜLDÜ: referanslar hangi modelle üretildiğini SÖYLEMİYOR', () {
    test('hiçbir referans model kimliği taşımıyor — ve bu kapatılamayan bir '
        'kapı', () {
      // The live judge compares a dancer against these artefacts. Which pose
      // model produced them decides what the numbers in them MEAN — and the
      // family has already measured that two bundles of the same variant give
      // different angles at the same file size.
      //
      // JabLab's `model_pin_test` enforces `modelId == fixtures.modelVersion`.
      // That gate CANNOT be built here, because the field does not exist:
      // Choreia's references record `corePin` and nothing about the model,
      // and neither `harvest.py` nor `build_reference.py` stamps one.
      //
      // So this test asserts the GAP, not the guarantee. It is not a check
      // that passes — it is a record that fails the day the gap closes, at
      // which point the real equality gate replaces it.
      final List<String> withProvenance = <String>[];
      for (final File f in Directory('content/references')
          .listSync()
          .whereType<File>()
          .where((File f) =>
              f.path.endsWith('.json') && !f.path.contains('decisions'))) {
        final Map<String, dynamic> ref =
            (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>();
        if (ref.keys.any((String k) => k.toLowerCase().contains('model'))) {
          withProvenance.add(f.uri.pathSegments.last);
        }
      }

      expect(withProvenance, isEmpty,
          reason: 'BİR REFERANS ARTIK MODEL KİMLİĞİ TAŞIYOR ($withProvenance) '
              '— bu iyi haber. Bu kaydı sil ve yerine GERÇEK kapıyı koy: '
              'PoseModelPin.modelId ile artefaktın alanı BİREBİR eşit olmalı '
              '(JabLab model_pin_test deseni).');

      // The vacuum guard: if the loop reads nothing, the emptiness above is
      // meaningless.
      expect(
          Directory('content/references')
              .listSync()
              .whereType<File>()
              .where((File f) => f.path.endsWith('.json'))
              .length,
          greaterThan(1),
          reason: 'hiç referans okunmadı — bu test hiçbir şey ölçmüyor');
    });
  });
}
