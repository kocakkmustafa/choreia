import 'dart:io';

import 'package:choreia/app/live/live_view.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart' show CameraFailure;
import 'package:motion_core/motion_core.dart' show SessionRecord;

import 'support/test_catalog.dart';

/// **A sentence may not assert a context its code path does not carry.**
///
/// JabLab found this class in a line pool: `"Round one. Go."` was a correct
/// sentence, picked round-robin, so round TWO announced round one. The line
/// was fine; the path that played it carried no round number.
///
/// Choreia has no line pool — measured, not assumed: no `Random`, no modulo
/// index, no rotation anywhere in `lib/`. The class still landed here twice,
/// through `switch` arms instead of pools, and both were live in the shipping
/// build:
///
///   1. The progress screen's retroactive-credit note said "practice time
///      ALREADY RECORDED stays a record of practice" while the build records
///      nothing at all.
///   2. The live screen blamed a camera conflict on "another part of the app"
///      in an app with exactly one camera surface.
///
/// Both hid in a SUBORDINATE clause — the part of the sentence that is not
/// its point. That is the cheapest place for a false claim to live, because
/// nobody re-reads it.
void main() {
  group('kaydedilen bir şey yokken kayıt VARSAYILMAZ (C-191)', () {
    test('notRecorded metni "already recorded" ÖNVARSAYIMINI taşımaz', () {
      final String note = ProgressSummary.retroactiveCreditNote(
          HistoryFidelity.notRecorded);
      expect(note.toLowerCase(), isNot(contains('already recorded')));
      expect(note.toLowerCase(), contains('saves nothing'),
          reason: 'yokluk YERİNE geçen bir cümle değil, yokluğu SÖYLEYEN bir '
              'cümle olmalı');
    });

    test('bir depo VARKEN aynı cümle geri geliyor — bu bir kayıp değil', () {
      // The negative twin. Deleting the promise everywhere would also make the
      // first assertion pass, and would quietly drop a real guarantee: when a
      // store exists, "time already recorded stays a record" is TRUE and is
      // the thing a dancer needs to hear before a gate opens.
      for (final HistoryFidelity f in <HistoryFidelity>[
        HistoryFidelity.ok,
        HistoryFidelity.partial,
        HistoryFidelity.unavailable,
      ]) {
        expect(ProgressSummary.retroactiveCreditNote(f).toLowerCase(),
            contains('already recorded'),
            reason: '$f durumunda geri-dönük puan sözü DÜŞTÜ — kapı, '
                'ihlali silerek değil vaadi silerek geçilmiş olur');
      }
    });

    testWidgets('EKRANDA: hiçbir şey kaydedilmiyorken "already recorded" '
        'yazmıyor', (WidgetTester tester) async {
      // Asserted at the SURFACE, not only at the string. The defect was not
      // that the sentence existed — it was that this state rendered it.
      final ProgressSummary summary = ProgressSummary.build(
        history: const <SessionRecord>[],
        catalog: await testCatalog(),
        integrity: HistoryIntegrity.notRecorded,
      );
      await tester.pumpWidget(MaterialApp(
        home: ProgressView(summary: summary, catalog: await testCatalog()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('already recorded'), findsNothing,
          reason: 'kaydedilen hiçbir şey yokken ekran "zaten kaydedilmiş '
              'pratik" diyor — kullanıcı pratiğinin tutulduğunu okur');
      expect(find.byKey(ProgressView.retroactiveNoteKey), findsOneWidget,
          reason: 'not tamamen kayboldu — geri-dönük puan sözü her durumda '
              'verilmeli, yalnız DOĞRU kelimelerle');
    });
  });

  group('uygulamanın olmayan bir parçası suçlanamaz (C-192)', () {
    test('MEASURED: kamerayı kaç yüzey açıyor', () {
      // The claim under test is about the app's own shape, so it is measured
      // from the app rather than remembered. If a second camera surface is
      // ever added, "another part of the app" becomes a legitimate sentence
      // and this gate should be revisited deliberately — which is why it
      // fails on the COUNT rather than silently allowing the wording.
      final int surfaces = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .map((File f) => 'CameraPoseSource()'.allMatches(f.readAsStringSync()).length)
          .fold(0, (int a, int b) => a + b);

      expect(surfaces, 1,
          reason: 'kamera yüzeyi sayısı değişti ($surfaces). Aşağıdaki kapı '
              '"uygulamanın başka bir parçası" ifadesini yasaklıyor ÇÜNKÜ '
              'öyle bir parça yok — varsa yasak kalkmalı, sessizce değil');
    });

    test('kamera arıza metinleri var olmayan bir fail suçlamıyor', () {
      final List<String> messages = <String>[
        for (final CameraFailure f in CameraFailure.values)
          LiveStrings.cameraProblem(f),
      ];
      expect(messages, isNotEmpty, reason: 'hiçbir metin okunmadı');

      for (final String m in messages) {
        expect(m.toLowerCase(), isNot(contains('another part of the app')),
            reason: 'tek kamera yüzeyi varken "uygulamanın başka bir parçası" '
                'diye bir parça yok — yolun taşımadığı bir bağlam');
      }
    });

    test('alreadyRunning kullanıcıya YAPACAK BİR ŞEY bırakıyor', () {
      // A blamed stranger ends the screen: nothing to try, nobody to be. The
      // honest suspect is our own previous session, and that one has an
      // action attached to it.
      final String m =
          LiveStrings.cameraProblem(CameraFailure.alreadyRunning).toLowerCase();
      expect(m, contains('again'),
          reason: 'çıkışsız arıza metni — M-F-268 ölü-son yasağı');
      expect(m, contains('last lesson'),
          reason: 'gerçek şüpheli isimlendirilmeli: bu uygulamanın açtığı tek '
              'şey önceki ders');
    });
  });

  group('havuz taraması — mekanizma yoksa da kapı durur', () {
    test('lib/ içinde döngüsel ya da rastgele replik seçimi YOK', () {
      // The reverse twin of JabLab's gate: their defect needs a pool to
      // exist. Choreia has none today, and the value of that fact is that it
      // can CHANGE without anyone noticing. If a pool appears, this fails and
      // the round-robin context rule has to be applied deliberately.
      final List<String> offenders = <String>[];
      for (final File f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))) {
        final String src = f.readAsStringSync();
        if (src.contains('Random(') ||
            RegExp(r'\.shuffle\(').hasMatch(src) ||
            RegExp(r'%\s*\w*(cues|lines|pool|phrases)').hasMatch(src)) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'replik havuzu / rastgele seçim belirdi: $offenders. '
              'JabLab kuralı devreye giriyor — döngüsel seçilen bir replik, '
              'seçim yolunun TAŞIMADIĞI bağlamı ("ilk", "yine", sıra sayısı) '
              'iddia edemez');
    });
  });
}
