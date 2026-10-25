import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/localization/progress_messages.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

/// Which surface MISINFORMS someone who opens the app today?
///
/// The question is deliberately asked from the user's side, not ours. JabLab's
/// note on why that matters: *"if I had asked 'what is missing', the list would
/// have filled with to-dos and the finding would never have surfaced — because
/// that item was not missing, it was EXTRA. A 'missing' lens cannot see
/// surplus."*
///
/// The class it names is the inverse of the one this family usually hunts.
/// Normally: a claim exists and its producer does not. Here: the producer does
/// not exist AND A SURFACE DESCRIBES IT ANYWAY. The absence is not silent, it
/// is TALKATIVE — and a talkative absence is worse than a quiet one, because it
/// invents reassurance.
///
/// EVERY CHECK BELOW CARRIES ITS EVIDENCE. A row without "how do I know" is an
/// opinion, and the finding this file exists for was found in exactly that
/// column.
void main() {
  String lib(String path) => File(path).readAsStringSync();

  /// Source of every Dart file under `lib/`, concatenated.
  String appSource() {
    final StringBuffer b = StringBuffer();
    for (final FileSystemEntity f
        in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) b.write(f.readAsStringSync());
    }
    return b.toString();
  }

  /// One file, with comments stripped — the single-file twin of [appCode].
  ///
  /// 🔴 THE MISSING HALF, AND IT COST A RED. The whole-app scan has stripped
  /// comments since its first version (a doc comment discussing a rule is not
  /// the app saying it), but the per-file reads went through raw source — so
  /// the moment a comment EXPLAINED why `HistoryIntegrity.notRecorded` no
  /// longer applies, the assertion that it no longer appears went red on the
  /// explanation itself.
  ///
  /// The family knows this class in its dangerous direction: *a text-scanning
  /// gate counts comments as code*, so a `// GuardName` comment passes a gate
  /// whose guard has been ripped out, silently. This is the same defect with
  /// the sign flipped — loud instead of silent, and therefore cheap. Fixing it
  /// where the READER lives closes both directions at once.
  String code(String path) => lib(path)
      .split('\n')
      .where((String l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  /// The same, with comments stripped.
  ///
  /// Needed because the string scans below look for what the app SAYS, and a
  /// doc comment discussing a rule is not the app saying it. The first version
  /// of this file matched the apostrophe in "content's own unlock rule" inside
  /// a comment and reported a user-facing string that does not exist — a false
  /// positive in a file whose entire job is separating real claims from
  /// imagined ones.
  String appCode() => appSource()
      .split('\n')
      .where((String l) => !l.trimLeft().startsWith('//'))
      .join('\n');

  test('the scan reads the app before it judges it', () {
    expect(appSource().length, greaterThan(20000),
        reason: 'an empty read makes every claim below vacuously true');
  });

  group('a surface must not describe a mechanism that is absent', () {
    test(
        'THE FINDING, INVERTED 2026-08-13: the app writes now, so it may no '
        'longer say it does not', () {
      // 🔔 THIS ASSERTION FIRED, AND THAT WAS ITS JOB.
      //
      // Its previous form asserted that NOTHING in `lib/` writes a session,
      // with the reason written as a trigger rather than a rule: *"a session
      // store now exists — re-check whether `notRecorded` is still the honest
      // state, because it stops being true the moment anything is written"*.
      // The moment arrived. A gate that fires on its own product's progress is
      // the enemy of that product only if it is SILENCED; this one named the
      // condition under which it should be turned around, so it is turned
      // around rather than deleted.
      //
      // The claim it now defends is the mirror of the old one: the write
      // exists, therefore the *"we do not save"* sentence must be gone from
      // the surface. The talkative-absence class has a talkative-PRESENCE
      // twin — a surface that keeps apologising for a mechanism that has
      // since been built teaches the learner to ignore it.
      final bool anythingWrites = RegExp(r'\.append\(').hasMatch(appCode());
      expect(anythingWrites, isTrue,
          reason: 'hiçbir şey oturum yazmıyor — o hâlde ilerleme yüzeyi '
              '`notRecorded` demeliydi; bu testin ESKİ hâline dönülmeli');

      // WHERE the write is, not merely THAT one exists. A `.append(` anywhere
      // in `lib/` would satisfy the line above; the claim is about the live
      // lesson specifically, because that is the only place a session ends.
      expect(code('lib/app/live/live_lesson_page.dart'), contains('.append('),
          reason: 'yazma canlı dersten çıktı — oturumu bitiren başka bir yer '
              'mi var, yoksa yazma kayboldu mu?');

      // And the surface must have STOPPED saying the opposite. Scoped to the
      // shell for the same reason the old assertion was: `notRecorded` is a
      // legitimate state of the type, it is simply no longer this app's.
      expect(code('lib/app/shell/choreia_shell.dart'),
          isNot(contains('HistoryIntegrity.notRecorded')),
          reason: 'kabuk hâlâ "bu uygulama kaydetmiyor" diyor, oysa az önceki '
              'ders diske yazıldı — eski hâliyle DOĞRU olan cümle artık '
              'yanlış');

      // POSITIVE CONTROL — the sentence itself still exists and still says
      // what it says. Without this the assertion above would also pass if
      // `HistoryIntegrity.notRecorded` were deleted outright, which is a
      // different change with different consequences (the type would lose the
      // ability to describe an app that genuinely keeps nothing).
      final String? said = HistoryIntegrity.notRecorded.note;
      expect(said, isNotNull);
      expect(said, contains('does not save'));
      expect(HistoryIntegrity.notRecorded.showsTotals, isFalse,
          reason: 'no numbers may be shown for a record that was never kept');

      // The shell now needs the FAILURE state instead: a store that will not
      // open is a thing that can happen the moment there is a store at all.
      expect(code('lib/app/shell/choreia_shell.dart'),
          contains('HistoryIntegrity.unavailable'),
          reason: 'artık bir depo var, ve açılmama ihtimali onunla birlikte '
              'geldi — kabuk bu dalı çizmiyorsa boş geçmişle ayırt edilemez');
      expect(appCode(), contains('ProgressSummary.from'),
          reason: 'ilerleme özeti hâlâ elle kuruluyor — depodan okunmuyorsa '
              'yazılanın yüzeye çıktığı iddia edilemez');
    });

    test('VE İDDİA, TÜM lib/ İÇİNDE — bir iddia bir SEMBOL DEĞİLDİR (C-275)',
        () {
      // 🔴 NİYE VAR: yukarıdaki assert 2026-08-13'te kuruldu ve aynı yalanı
      // ÜÇ EKRAN ÖTEDE kaçırdı. Onboarding'in son kartı, uygulamayı ilk açan
      // herkese *"Nothing you do is saved anywhere in this version."* diyordu
      // — depo `C-268`'de kuruldu, `C-269` simülatörde yazdığını ölçtü.
      //
      // Kapı niye görmedi: **SEMBOL** arıyordu (`HistoryIntegrity.notRecorded`)
      // ve yalnız **BİR dosyada** (kabuk). Onboarding aynı iddiayı düz metinle,
      // sembolsüz kuruyordu.
      //
      // ⇒ ***BİR İDDİA BİR SEMBOL DEĞİLDİR*** — ve bir kapının kapsamı, avladığı
      // kusurun kapsamı kadar geniş olmak zorundadır. Bu yüzden tarama tüm
      // `lib/` üzerinde, ve dizgeler üzerinde.
      //
      // ⚠️ DİZGELER DAR SEÇİLDİ, ve bu bir ayar değil bir ŞART: gizlilik kartı
      // *"nothing is recorded or uploaded"* diyor ve o cümle VİDEO hakkında,
      // DOĞRU, ve kalmalı. Geniş bir desen ("nothing is recorded") o doğru
      // cümleyi kırmızıya boyardı ⇒ kapı, koruduğu ürünün dürüst cümlesini
      // cezalandırırdı. Desenler **oturum saklamayı** inkâr eden kalıplara
      // bağlı.
      const List<String> deniesSaving = <String>[
        'saved anywhere',
        'does not save',
        'do not save',
        'is saved anywhere',
        'nothing is saved',
      ];

      // ── ÖNCE İKİ KAPININ ÇELİŞKİSİ, ve nasıl çözüldüğü ────────────────
      //
      // Yukarıdaki C-269 assert'inin POZİTİF KONTROLÜ, `historyNotRecorded`ın
      // *'does not save'* demeye DEVAM ETMESİNİ şart koşuyor; buradaki tarama
      // ise o cümleyi yasaklıyor. Gerekçesi sağlamdı: *tip, hiçbir şey
      // saklamayan bir uygulamayı tarif edebilmeyi kaybetmemeli.* Kusur o
      // gerekçede değil, YERİNDE: yetenek **TİPE** aittir, ama kontrol onu
      // Choreia'nın **kullanıcı metnine** çivilemişti — ve bu, yalanı yerinde
      // dondurdu.
      //
      // ⇒ Çözüm cümleyi yasaklamak DEĞİL, cümlenin **ulaşılamaz** olduğunu
      // ölçmek. `HistoryFidelity.notRecorded` bir durum eşlemesidir: o duruma
      // varılırsa cümle DOĞRUDUR. Yalan, onboarding'in aynı şeyi **koşulsuz**
      // söylemesiydi. Korunacak şey bu yüzden ulaşılamazlığın kendisi.
      final String progress = code('lib/app/progress_summary.dart');
      final String shell = code('lib/app/shell/choreia_shell.dart');
      final RegExp builds = RegExp(r'HistoryIntegrity\.notRecorded');

      // POZİTİF KONTROL — ARAÇ BULABİLİYOR MU. Sıfır iki şeyden gelebilir:
      // temiz bir ağaçtan, ya da hiçbir şeye uymayan bir desenden. İkisi
      // ekranda AYNI görünür, ve ayırt edilmezse bu assert kendi vakumunda
      // sonsuza kadar yeşil kalır.
      expect(builds.hasMatch('final x = HistoryIntegrity.notRecorded;'), isTrue,
          reason: 'desen, yakalamak için yazıldığı dizgeyi bile bulamıyor');

      expect(builds.allMatches(appCode()).length, 0,
          reason: 'Choreia içinde HİÇBİR YER `HistoryIntegrity.notRecorded` '
              'durumunu kurmamalı (bildirimi sınıfın içinde, o yüzden nitelikli '
              'kullanım = dışarıdan inşa). Bir yer kuruyorsa "bu uygulama '
              'kaydetmiyor" cümlesi kullanıcıya ULAŞABİLİR hâle gelmiştir, ve '
              'o cümle C-268 depoyu kurduğundan beri YANLIŞ.');
      expect(shell, isNot(contains('HistoryIntegrity.notRecorded')),
          reason: 'kabuk o durumu yeniden kuruyor');

      // ŞİMDİ TARAMA — ve dışlanan tek şey bir DOSYA değil, adı konmuş TEK
      // SABİTİN kendi bildirimi. Dosya bazlı dışlama, bu turun avladığı
      // kusurun ta kendisi olurdu (kapsamı kusurdan dar bir kapı).
      //
      // 🪤 VE DIŞLAMA KAYNAK METNİ ÜZERİNDE, ÇALIŞMA-ZAMANI DEĞERİ ÜZERİNDE
      // DEĞİL. İlk yazımım `replaceAll(ProgressStrings.historyNotRecorded, …)`
      // idi — sabit kaynakta ÜÇ BİTİŞİK LİTERAL olarak yazılı, birleşmiş dizge
      // kaynakta hiç GEÇMİYOR ⇒ `replaceAll` sessizce hiçbir şey yapmadı.
      const String marker = '<durum-eslemesi/ulasilamaz>';
      // The same unreachable state now also has a localization dictionary
      // entry. Exempt only that exact key/value entry in its named dictionary;
      // other dictionary messages and every user-facing call remain scanned.
      final String dictionary =
          code('lib/app/localization/progress_messages.dart');
      final stateEntry = RegExp(
          '${RegExp.escape(jsonEncode(ProgressStrings.historyNotRecorded))}'
          r'\s*:\s*"(?:\\.|[^"\\])*",');
      expect(stateEntry.allMatches(dictionary).length, progressMessages.length,
          reason: 'each locale must retain exactly one mapping of this state');
      final String maskedDictionary = dictionary.replaceAll(stateEntry, marker);
      expect(maskedDictionary, isNot(contains('does not save')),
          reason: 'no other dictionary message may deny saving');
      final String allCode = appCode();
      expect(allCode.split(dictionary), hasLength(2),
          reason: 'the named dictionary must be present exactly once');
      final String app = allCode
          .replaceFirst(dictionary, maskedDictionary)
          .replaceAll(
              RegExp(r'static const String historyNotRecorded =[\s\S]*?;'),
              marker);
      final String unconditional =
          'Text(${jsonEncode(ProgressStrings.historyNotRecorded)});';
      expect(stateEntry.hasMatch(unconditional), isFalse,
          reason: 'a real surface must not receive the dictionary exemption');
      expect(deniesSaving.any(unconditional.contains), isTrue,
          reason: 'the same text on a real surface must still be detected');

      // POZİTİF KONTROL ⓪ — VE SIRASI KONTROLÜN PARÇASI. Bunu ilk yazışımda
      // döngüden SONRA koymuştum; döngü önce düştü, kontrol hiç koşmadı ve
      // hata mesajı sebebi göstermedi. ⇒ ***KORUDUĞU İDDİADAN SONRA GELEN BİR
      // POZİTİF KONTROL ATEŞLEYEMEZ.***
      expect(app, contains(marker),
          reason: 'dışlanacak bildirim kaynakta bulunamadı — desen boşa koştu, '
              'yani aşağıdaki tarama dışladığını sandığı şeyi dışlamıyor');
      expect(app, isNot(contains('nothing of yours has been lost')),
          reason: 'bildirim kısmen çıkarıldı: gövdesi taramada kaldı ⇒ dışlama '
              'sınırı `;`de değil, yanlış yerde bitiyor');

      for (final String phrase in deniesSaving) {
        expect(app, isNot(contains(phrase)),
            reason: 'lib/ içinde bir yüzey KOŞULSUZ olarak "$phrase" diyor — '
                'oysa canlı ders diske YAZIYOR (yukarıdaki assert bunu '
                'ölçüyor). Mekanizma var, yüzey yok diyor: talkative-PRESENCE.');
      }

      expect(progress, contains('does not save'),
          reason: 'durum cümlesi kayboldu — o hâlde yukarıdaki dışlama artık '
              'var olmayan bir şeyi koruyor ve kaldırılmalı');

      // POZİTİF KONTROL ①: TARAYICI BULABİLİYOR MU. Desenlerin hiçbiri
      // eşleşmiyorsa bunun sebebi "yüzey temiz" olabilir — ya da tarama
      // BOŞLUKTA koşuyor olabilir. Sentetik bir metne karşı ölçülüyor.
      const String synthetic =
          'One style is open today. Nothing you do is saved anywhere.';
      expect(deniesSaving.any(synthetic.contains), isTrue,
          reason: 'desen kümesi, kaçırdığı CÜMLENİN TA KENDİSİNİ bile '
              'yakalayamıyor — kapı vakumda yeşil');

      // POZİTİF KONTROL ②: GİZLİLİK CÜMLESİ ELENMİYOR MU. Kapının en olası
      // arızası fazla-yakalamak; o cümle DOĞRU ve kalmalı.
      const String privacyTruth =
          'Video never leaves your phone — we only read the positions of your '
          'joints, and no video is recorded or uploaded.';
      expect(deniesSaving.any(privacyTruth.contains), isFalse,
          reason: 'desen, video hakkındaki DOĞRU cümleyi de yakalıyor — bir '
              'kapı, koruduğu ürünün dürüst cümlesini cezalandıramaz');

      // VE CÜMLENİN ÖZNESİ ADLANDIRILMIŞ OLMALI (C-277). Çıplak *"nothing is
      // recorded"*, aynı ekranın son kartındaki *"kept on this phone"* ile
      // birlikte okunduğunda ekranı KENDİ İÇİNDE çelişkili yapıyordu:
      // `recorded` bir cümlede video, okuyucunun kulağında saklama.
      // Her iki cümle de tek başına doğruydu ve her test yeşildi.
      // ⇒ TUTARLILIK KÜMENİN ÖZELLİĞİDİR, ÜYELERİN DEĞİL.
      final String onboarding = code('lib/app/onboarding/first_run_view.dart');
      expect(onboarding, isNot(contains('nothing is recorded')),
          reason: 'gizlilik cümlesi öznesini kaybetti: çıplak "nothing is '
              'recorded", aynı ekranın "kept on this phone" cümlesiyle '
              'çelişik okunur');
      expect(onboarding, contains('no video is recorded'),
          reason: 'gizlilik iddiası yüzeyden kayboldu — kamera kartı artık '
              'videonun saklanmadığını SÖYLEMİYOR');

      // POZİTİF KONTROL: kontrol, yakalamak için yazıldığı çıplak biçimi
      // gerçekten ayırt ediyor mu — yoksa iki assert de aynı şeye bakıyordur.
      const String bare = 'and nothing is recorded or uploaded.';
      const String named = 'and no video is recorded or uploaded.';
      expect(bare.contains('nothing is recorded'), isTrue);
      expect(named.contains('nothing is recorded'), isFalse);

      // VE YERİNE GEÇEN CÜMLE GERÇEĞİ SÖYLÜYOR MU. Yalnız silmek, A3'ün
      // yasakladığı sessiz yüzeyi bırakırdı: kullanıcı pratiğine ne olduğunu
      // hâlâ bilmezdi.
      expect(code('lib/app/onboarding/first_run_view.dart'),
          contains('kept on this phone'),
          reason: 'yanlış cümle kaldırıldı ama yerine DOĞRUSU konmadı — '
              'kullanıcı pratiğine ne olduğunu öğrenemiyor');
    });

    test(
        'THE TWIN: a surface must not call ABSENT a mechanism that is '
        'PRESENT — the Evaluated reason', () {
      // FOUND BY WALKING THE BUILT APP, not by reading the code. On the
      // simulator the Progress tab still read "Grading needs the camera check,
      // and that is not wired up in this build" — and the camera check IS
      // wired: `LiveLessonPage` opens the camera, `LiveSession` reads cycles
      // and `DanceJudge` produces findings on screen.
      //
      // The sentence was TRUE when it was written. Nothing about it looked
      // wrong afterwards, because a claim about an absence does not break when
      // the absence ends — it just quietly starts lying. That is the whole
      // reason this check exists at the STRING, not at the mechanism.
      final String reason = ProgressSummary.build(
        history: const <SessionRecord>[],
        catalog: CourseCatalog.fromStyles(const <Map<String, dynamic>>[]),
      ).evaluatedUnavailableReason!;

      // EVIDENCE that the mechanism is present, re-derived every run rather
      // than asserted once: the live page drives a judge over camera frames.
      final String live = code('lib/app/live/live_lesson_page.dart');
      expect(live, contains('DanceJudge('),
          reason: 'canlı yol artık yargılamıyor olabilir — o hâlde cümlenin '
              '"kamera kontrolü bağlı değil" demesi yeniden DOĞRU olur ve bu '
              'kapı ters çevrilmeli');
      expect(live, contains('_source.begin()'));

      expect(reason, isNot(contains('not wired up')),
          reason: 'kamera kontrolü BAĞLI ve yüzey bağlı değil diyor — mevcut '
              'bir mekanizmayı yok ilan etmek, yok olanı var ilan etmenin '
              'ikizidir');
      // And it must still say what IS missing, or the fix would be to delete
      // the sentence — which leaves an empty section explaining nothing (A3).
      expect(reason, contains('not kept'),
          reason: 'eksik olan şey ADLANDIRILMIYOR: saklanan kayıtta hüküm '
              'alanı YOK, eksik olan bu');
      expect(reason, contains('zero'),
          reason: 'sıfır göstermeme gerekçesi düştü — "0" bir sonuç gibi '
              'okunur ve bu cümlenin ilk işi buydu');
    });

    test('the unlock rule content declares is not SPOKEN to anyone', () {
      // EVIDENCE: `salsa_shines` level 1 carries an `unlockRule`, and no code
      // implements progression — the only references are doc comments citing
      // it as the derivation basis for `correctionPriority`.
      //
      // That is legal today ONLY because no surface mentions progression
      // unlocking. This
      // is precisely the shape JabLab found (a progression gate described to
      // the user with no producer anywhere), caught here before it is spoken
      // rather than after.
      final String styleDoc = lib('content/styles/salsa_shines/style.json');
      expect(styleDoc, contains('unlockRule'),
          reason: 'if content stops declaring it, this guard is measuring '
              'nothing');

      // The one unlock that IS implemented: a paid lesson opens with a
      // membership (sales open, 23 Oct 2026). Its words live only in
      // PaidLessonLock, and only while that lock calls the real producer.
      const String lockPath = 'lib/app/course/paid_lesson_lock.dart';
      final String lock = code(lockPath);
      expect(lock, contains('await access.unlock(context)'),
          reason: 'the membership button must drive CourseAccess.unlock');
      expect(code('lib/app/course/course_access.dart'),
          contains('Future<bool> unlock(BuildContext context)'));
      expect(lock, isNot(contains('unlockRule')));

      final String rest = appCode().replaceFirst(lock, '');
      expect(rest.length, lessThan(appCode().length),
          reason: 'the exempted lock must be found in the whole-app scan');
      expect(rest,
          isNot(matches(RegExp(r"'[^'\n]*\bunlock", caseSensitive: false))),
          reason: 'a user-facing string mentions unlocking, and nothing '
              'implements it — the talkative-absence class');
      expect(appCode(), isNot(contains("json['unlockRule']")),
          reason: 'nothing parses it, so nothing can render it by accident');
    });

    test('no camera limit describes a check we would run', () {
      // EVIDENCE: the limits list is 62 lines written for 31 styles with no
      // lessons at all. A line that names a mechanism ("once the beat grid
      // lands…") would describe a pipeline that does not exist for ANY of
      // them.
      final List<Object?> styles =
          (jsonDecode(lib('content/library.json')) as Map)['styles'] as List;
      final RegExp mechanism = RegExp(
          r'\bwill be\b|\bonce we\b|\bwhen we\b|\bunlock|\bthen we\b',
          caseSensitive: false);
      final List<String> offenders = <String>[
        for (final Object? s in styles)
          for (final Object? l
              in ((s as Map)['cameraLimits'] as List? ?? const []))
            if (mechanism.hasMatch(l! as String)) '${s['id']}: $l',
      ];
      expect(offenders, isEmpty, reason: '$offenders');
    });

    test('a beat grid is only ever named as ABSENT', () {
      // EVIDENCE: `beatsStatus` is DISPUTED in content and no beat grid is
      // computed anywhere. Five limits mention one; each must say we lack it.
      final List<Object?> styles =
          (jsonDecode(lib('content/library.json')) as Map)['styles'] as List;
      for (final Object? s in styles) {
        for (final Object? l
            in ((s as Map)['cameraLimits'] as List? ?? const [])) {
          final String line = l! as String;
          if (!line.toLowerCase().contains('beat grid')) continue;
          expect(
              line,
              matches(
                  RegExp(r'we do not have|cannot measure|without a beat grid')),
              reason: '${s['id']} names a beat grid without saying we have '
                  'none: "$line"');
        }
      }
    });
  });
}
