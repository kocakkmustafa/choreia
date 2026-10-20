import 'dart:io';
import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/recorded_summary.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';
import 'package:motion_core/motion_core.dart';

/// These tests measure the HONESTY STRUCTURE of the progress surface, not its
/// appearance — there is no device in this session, so nothing here claims
/// anything about how it looks.
///
/// The load-bearing choice: every section assertion is SCOPED to a section key
/// via `find.descendant`. An unscoped `find.text` would pass even if Recorded
/// and Evaluated were merged into one list, which is precisely the defect
/// §3.9 exists to prevent — so an unscoped test would be a test that cannot
/// fail for the reason it was written.
void main() {
  // Content shaped like the real files, trimmed to what the derivation reads.
  final Map<String, dynamic> salsaStyle = <String, dynamic>{
    'id': 'salsa_shines',
    'shipGates': <Map<String, dynamic>>[
      {
        'gate': 'bpmResolved',
        'blocked': true,
        'why': 'bpmRange unresolved (two passes ~2x apart)',
        'unblockedBy': 'one live tap on a known track',
      },
      {'gate': 'referencesBuilt', 'blocked': false, 'why': 'done'},
    ],
    'levels': <Map<String, dynamic>>[
      {
        'level': 1,
        'lessons': <Map<String, dynamic>>[
          {
            'id': 'ss_l1_footwork',
            'displayName': {'en': 'Shine footwork'},
            'step': 'ss_shine_footwork',
            'scored': true,
            'minutes': 10,
          },
          {
            'id': 'ss_l1_basic',
            'displayName': {'en': 'The basic'},
            'step': 'ss_basic',
            'scored': false,
            'demoOnly': true,
            'demoOnlyClass': 'structural-circular',
            'demoOnlyReason': {'en': 'the plateau is below what we can measure'},
            'promotionPath': {'unblockedBy': 'a source with visible holds'},
            'minutes': 8,
          },
          {
            'id': 'ss_l1_locked_example',
            'displayName': {'en': 'Not written yet'},
            'scored': false,
            'lockedReason': {'en': 'no teachers measured for it yet'},
            'minutes': 6,
          },
        ],
      },
    ],
  };

  final Map<String, Map<String, dynamic>> steps = <String, Map<String, dynamic>>{
    'ss_shine_footwork': <String, dynamic>{
      // Key is `errors`, matching the real step documents.
      'errors': <Map<String, dynamic>>[
        {
          'code': 'NO_WEIGHT_TRANSFER',
          'status': 'blocked',
          'blockedBy': 'threshold(1.0deg) < noiseFloor(6.0deg)',
        },
        {'code': 'WRONG_FOOT', 'status': 'live (M-F-117)'},
        {
          'code': 'STEP_LATE',
          'status': 'blocked',
          'blockedBy': 'beatsStatus:PENDING — no beat grid to be late against',
        },
      ],
    },
    'ss_basic': <String, dynamic>{'errors': <Map<String, dynamic>>[]},
  };

  final CourseCatalog catalog =
      CourseCatalog.fromStyles(<Map<String, dynamic>>[salsaStyle], steps: steps);

  SessionRecord rec({
    required String lesson,
    String klass = ChoreiaLessonClass.scored,
    int worked = 600,
    int cycles = 8,
    int planned = 8,
    DateTime? at,
  }) =>
      SessionRecord(
        lessonId: lesson,
        lessonClass: klass,
        completedAt: at ?? DateTime.utc(2026, 7, 30, 12),
        workedSeconds: worked,
        unitsCompleted: cycles,
        plannedUnits: planned,
        unitLabel: choreiaUnitLabel,
      );

  ProgressSummary summaryOf(List<SessionRecord> history) =>
      ProgressSummary.build(
        history: history,
        catalog: catalog,
        totals: const RecordedSummary(
          sessions: 0,
          targetedSessions: 0,
          completed: 0,
          workedSeconds: 0,
          scoredSessions: 0,
          demoOnlySessions: 0,
          unmeasuredUnits: 0,
        ),
      );

  group('CourseCatalog — blocked gates are DERIVED, never prose', () {
    test('all three scopes are picked up, and only the blocked ones', () {
      final Set<String> ids =
          catalog.blockedGates.map((BlockedGate g) => g.id).toSet();
      expect(ids, contains('bpmResolved'));           // style scope
      expect(ids, contains('NO_WEIGHT_TRANSFER'));    // errorCode scope
      expect(ids, contains('STEP_LATE'));             // errorCode scope
      expect(ids, contains('ss_l1_basic'));           // lesson scope
      expect(ids, contains('ss_l1_locked_example'));  // lesson scope

      expect(ids, isNot(contains('referencesBuilt')),
          reason: 'a PASSED gate must not be listed as blocked — '
              'over-claiming a limit is still a false statement');
      expect(ids, isNot(contains('WRONG_FOOT')),
          reason: 'a live error code is not a blocked gate');
      expect(ids, isNot(contains('ss_l1_footwork')),
          reason: 'a scored lesson is not a blocked gate');
    });

    test('the three lesson kinds stay distinct — locked is NOT weak demoOnly',
        () {
      expect(catalog.lessonById('ss_l1_footwork')!.kind, LessonKind.scored);
      expect(catalog.lessonById('ss_l1_basic')!.kind, LessonKind.demoOnly);
      expect(catalog.lessonById('ss_l1_locked_example')!.kind,
          LessonKind.locked);
    });

    test('every ungraded lesson carries a reason', () {
      for (final LessonInfo l in catalog.lessons.where((l) => !l.isScored)) {
        expect(l.reason, isNotNull, reason: '${l.id} has no stated reason');
        expect(l.reason, isNotEmpty);
      }
    });

    test('a step shared by two lessons emits its gate ONCE', () {
      final Iterable<BlockedGate> nwt =
          catalog.blockedGates.where((g) => g.id == 'NO_WEIGHT_TRANSFER');
      expect(nwt, hasLength(1));
    });
  });

  group('ProgressSummary — the two sections cannot merge', () {
    test('there is no combined list on the type at all', () {
      final ProgressSummary s = summaryOf(<SessionRecord>[]);
      // Structural, not stylistic: a surface literally cannot render one list,
      // because no field offers one.
      expect(s.recorded, isEmpty);
      expect(s.evaluated, isEmpty);
    });

    test('Evaluated is empty AND says why — a blank would blame the user', () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
      ]);
      expect(s.evaluated, isEmpty);
      expect(s.evaluatedUnavailableReason, isNotNull);
      expect(s.evaluatedUnavailableReason, contains('camera'));
    });

    test('a demoOnly session appears in Recorded with its completion counted',
        () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_basic', klass: ChoreiaLessonClass.demoOnly),
      ]);
      final RecordedRow row = s.recorded.single;
      expect(row.isDemoOnly, isTrue);
      expect(row.completedSessions, 1,
          reason: 'completion is a MEASUREMENT; withholding it would make the '
              'lesson second class — the thing K10 prevents');
    });

    test('a lesson practised across a promotion reports the CAUTIOUS class',
        () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_basic', klass: ChoreiaLessonClass.demoOnly,
            at: DateTime.utc(2026, 1, 1)),
        rec(lesson: 'ss_l1_basic', klass: ChoreiaLessonClass.scored,
            at: DateTime.utc(2026, 7, 1)),
      ]);
      expect(s.recorded.single.lessonClass, ChoreiaLessonClass.demoOnly,
          reason: 'calling the whole history scored would over-claim exactly '
              'the sessions danced before the promotion');
    });

    test('display names come from content, unknown ids fall back to the id', () {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
        rec(lesson: 'a_lesson_no_longer_in_content'),
      ]);
      final Map<String, String> names = <String, String>{
        for (final RecordedRow r in s.recorded) r.lessonId: r.displayName,
      };
      expect(names['ss_l1_footwork'], 'Shine footwork');
      expect(names['a_lesson_no_longer_in_content'],
          'a_lesson_no_longer_in_content',
          reason: 'a removed lesson must still render its history — dropping '
              'the row would delete the record');
    });

    test('unit-bearing strings: no bare numbers reach a surface', () {
      expect(ProgressStrings.duration(600), '10 min practised');
      expect(ProgressStrings.duration(3661), '1h 1m practised');
      expect(ProgressStrings.duration(7200), '2h practised');
      expect(ProgressStrings.cycles(3, 8), '3 of 8 cycles');
      expect(ProgressStrings.sessionsCompleted(1, 2, anyTarget: true),
          '1 of 2 sessions finished');
    });

    test('NO DECLARED TARGET — the ratio disappears, the fact stays', () {
      // Choreia lessons declare no cycle target (`noDeclaredTarget`), so every
      // record this app writes today arrives here with `planned == 0`. Both
      // halves are pinned because both were wrong in an obvious way before:
      // "3 of 0 cycles" is a broken sentence, and storing the attempt as the
      // target would have rendered "3 of 3" — a target hit, for a target
      // nobody set.
      expect(ProgressStrings.cycles(3, 0), '3 cycles read');
      expect(ProgressStrings.cycles(1, 0), '1 cycle read');
      expect(ProgressStrings.cycles(0, 0), '0 cycles read');

      // `SessionRecord.isComplete` is `attempted >= planned`, so with no
      // target EVERY record reads as complete. Printing "1 of 1 sessions
      // finished" would report the arithmetic of an absent plan as an
      // achievement.
      expect(ProgressStrings.sessionsCompleted(2, 2, anyTarget: false),
          '2 sessions');
      expect(ProgressStrings.sessionsCompleted(1, 1, anyTarget: false),
          '1 session');

      // POSITIVE CONTROL — the no-target branch must not swallow the real one.
      // Without this, deleting the ratio entirely would still pass.
      expect(ProgressStrings.cycles(3, 8), contains(' of '));
      expect(ProgressStrings.sessionsCompleted(1, 2, anyTarget: true),
          contains('finished'));
    });
  });

  group('ProgressView — WHICH SECTION each string lands in', () {
    Future<void> pump(WidgetTester tester, ProgressSummary s) =>
        tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: ProgressView(summary: s, catalog: catalog),
        ));

    Finder inSection(Key section, String text) => find.descendant(
        of: find.byKey(section), matching: find.text(text));

    testWidgets('the reason for an empty Evaluated sits INSIDE Evaluated, '
        'not in Recorded', (WidgetTester tester) async {
      final ProgressSummary s = summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
      ]);
      await pump(tester, s);
      final String reason = s.evaluatedUnavailableReason!;
      expect(inSection(ProgressView.evaluatedSectionKey, reason), findsOneWidget);
      expect(inSection(ProgressView.recordedSectionKey, reason), findsNothing);
    });

    testWidgets('practice facts land in Recorded and NOWHERE in Evaluated',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork', worked: 600, cycles: 8, planned: 8),
      ]));
      expect(inSection(ProgressView.recordedSectionKey, '10 min practised'),
          findsOneWidget);
      expect(inSection(ProgressView.evaluatedSectionKey, '10 min practised'),
          findsNothing,
          reason: 'a measurement rendered under Evaluated would read as a grade');
    });

    testWidgets('a demoOnly row shows the completion mark AND the no-band dash',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_basic', klass: ChoreiaLessonClass.demoOnly),
      ]));
      final Finder row = find.byKey(const Key('progress.recorded.ss_l1_basic'));
      expect(
          find.descendant(
              of: row,
              matching: find.textContaining('Taught, not graded')),
          findsOneWidget);
      expect(
          find.descendant(
              of: row, matching: find.text(ProgressStrings.noBand)),
          findsOneWidget,
          reason: 'a blank would look like a missing value; the dash says the '
              'judgement is ABSENT, not zero');
      expect(
          find.descendant(
              of: row,
              matching: find.textContaining('below what we can measure')),
          findsOneWidget,
          reason: 'the reason travels with the row (K10: not dropped, marked '
              'with a reason in the language the user reads)');
    });

    testWidgets('a scored lesson row carries NO band and NO demo mark',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        rec(lesson: 'ss_l1_footwork'),
      ]));
      final Finder row =
          find.byKey(const Key('progress.recorded.ss_l1_footwork'));
      expect(
          find.descendant(
              of: row, matching: find.textContaining('Taught, not graded')),
          findsNothing);
      expect(
          find.descendant(
              of: row, matching: find.text(ProgressStrings.noBand)),
          findsNothing,
          reason: 'the dash is the demo-only marker; on a scored lesson it '
              'would claim a judgement was withheld');
    });

    testWidgets('unmeasured cycles are NAMED on the row they happened in',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[
        SessionRecord(
          lessonId: 'ss_l1_footwork',
          lessonClass: ChoreiaLessonClass.scored,
          completedAt: DateTime.utc(2026, 7, 30, 12),
          workedSeconds: 600,
          unitsCompleted: 7,
          plannedUnits: 8,
          unitLabel: choreiaUnitLabel,
          unmeasuredUnits: 1,
          unmeasuredReason: 'framing',
        ),
      ]));
      final Finder row =
          find.byKey(const Key('progress.recorded.ss_l1_footwork'));
      expect(
          find.descendant(
              of: row, matching: find.textContaining('could not check')),
          findsOneWidget,
          reason: 'without this line the row reads "7 of 8 cycles" for a '
              'session where the learner danced 8 — the product failure is '
              'reported as the dancer doing less');
    });

    testWidgets('a row with NOTHING unmeasured says nothing about it',
        (WidgetTester tester) async {
      // The positive twin's negative half: an always-present notice would be
      // noise, and a surface that always warns is a surface nobody reads.
      await pump(tester, summaryOf(<SessionRecord>[rec(lesson: 'ss_l1_footwork')]));
      expect(
          find.descendant(
              of: find.byKey(const Key('progress.recorded.ss_l1_footwork')),
              matching: find.textContaining('could not check')),
          findsNothing);
    });

    testWidgets('every blocked gate is NAMED on screen, with its reason',
        (WidgetTester tester) async {
      // ⚠️ ÖLÇÜT DEĞİŞTİ, İDDİA DEĞİŞMEDİ (C-279). Bu test eskiden `g.id`yi
      // ekranda ARIYORDU — yani *"adlandırılmış olsun"* iddiasını *"ham
      // kimliğiyle görünsün"* diye ölçüyordu, ve o ölçüt kusuru YERİNDE
      // ÇİVİLİYORDU: bir ders için doğru ad içerikte zaten yazılı.
      // (C-275'in çelişkisiyle aynı şekil: bir kontrol, koruduğu sanılan
      // kusurun devam etmesini şart koşabilir.)
      await pump(tester, summaryOf(<SessionRecord>[]));
      for (final BlockedGate g in catalog.blockedGates) {
        final String shown = g.scope == GateScope.lesson
            ? (catalog.lessonById(g.id)?.displayName ?? g.id)
            : g.id;
        expect(
            find.descendant(
                of: find.byKey(ProgressView.blockedSectionKey),
                matching: find.textContaining(shown)),
            findsOneWidget,
            reason: '${g.id} is blocked but not on the screen — silence is a '
                'lie (J-066)');
      }
    });

    testWidgets('BİR DERS KENDİ ADIYLA ANILIR, ham kimliğiyle DEĞİL (C-279)',
        (WidgetTester tester) async {
      // Bu bölüm uygulamanın en gururlu yüzeyi ("What we cannot check") ve
      // kullanıcıya `hh_l1_bounce` diye hitap ediyordu. C-268 ⑥ ile aynı
      // sınıf, bir yüzey ötede: BİR SINIFI BİR YÜZEYDE KAPATMAK, KOMŞU
      // YÜZEYDE KAPATMIŞ OLMAZ.
      await pump(tester, summaryOf(<SessionRecord>[]));

      final Iterable<BlockedGate> lessonGates = catalog.blockedGates
          .where((BlockedGate g) => g.scope == GateScope.lesson);

      // POZİTİF KONTROL ① — ölçülecek popülasyon var mı. Boş bir küme
      // üzerinde aşağıdaki döngü hiç koşmaz ve test kendi vakumunda yeşil
      // görünür (C-270'in sıfır-payda dersi).
      expect(lessonGates, isNotEmpty,
          reason: 'ders kapsamlı bloklu kapı YOK — bu testin ölçtüğü şey '
              'kalmamış, iddiası yeniden okunmalı');

      int renamed = 0;
      for (final BlockedGate g in lessonGates) {
        final String? name = catalog.lessonById(g.id)?.displayName;
        if (name == null || name == g.id) continue;
        renamed++;
        expect(
            find.descendant(
                of: find.byKey(ProgressView.blockedSectionKey),
                matching: find.textContaining(name)),
            findsOneWidget,
            reason: '"$name" içerikte kullanıcı için yazılmış ad, ve ekranda '
                'yok — yerine ${g.id} yazılıyorsa dürüstlük bölümü kullanıcıya '
                'iç kimlikle hitap ediyor demektir');
        expect(
            find.descendant(
                of: find.byKey(ProgressView.blockedSectionKey),
                matching: find.text(g.id)),
            findsNothing,
            reason: '${g.id} ham kimliği hâlâ bir başlık olarak çiziliyor');
      }

      // POZİTİF KONTROL ② — adların gerçekten FARKLI olduğu bir vaka bulundu
      // mu. Her ders adı kimliğine eşit olsaydı yukarıdaki `continue` her
      // turda çalışır ve test hiçbir şey ölçmeden geçerdi.
      expect(renamed, greaterThan(0),
          reason: 'hiçbir dersin adı kimliğinden farklı değil — bu testin '
              'ayırt edebileceği bir şey yok, vakumda yeşil');
    });

    test('VE KABUK KATALOĞU GERÇEKTEN GEÇİRİYOR — yoksa düzeltme üretimde '
        'sessizce NO-OP (C-279)', () {
      // NİYE VAR: yukarıdaki widget testleri `ProgressView`e kataloğu ELDEN
      // veriyor. `catalog` alanı nullable; kabuk onu geçirmeyi bırakırsa her
      // test yeşil kalır ve ekran ham kimliklere geri döner — düzeltmenin
      // yük taşımadığı, yalnız testte taşıdığı hâl.
      //
      // ⚠️ SINIRI YAZILI: bu bir METİN taraması, çalışan bir dikiş kanıtı
      // değil. Yorumlar sıyrılıyor (bu depo bir kapının yorumu kod sayması
      // yüzünden bir kırmızı ödedi), ama ölçtüğü şey "kaynakta bu satır var",
      // "bu değer çalışma anında null değil" DEĞİL. Daha güçlü kanıt A1
      // yürüyüşünün kendisi.
      final String shell = File('lib/app/shell/choreia_shell.dart')
          .readAsStringSync()
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');

      // POZİTİF KONTROL — okuma boş değil; boş bir okuma her iddiayı
      // vakumda doğru yapar.
      expect(shell.length, greaterThan(2000),
          reason: 'kabuk kaynağı okunamadı — aşağıdaki iddia vakumda');

      expect(shell, contains('ProgressView('),
          reason: 'kabuk artık ProgressView çizmiyor — bu testin konusu '
              'değişti');
      expect(shell, contains('catalog: library.allCourses'),
          reason: 'kabuk ProgressView\'e kataloğu GEÇİRMİYOR ⇒ '
              '`_gateLabel` her satırda ham kimliğe düşer ve "What we cannot '
              'check" bölümü kullanıcıya hh_l1_bounce diye hitap eder — '
              'testler yeşil kalarak');
    });

    testWidgets('the no-retroactive-credit statement is present',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[]));
      expect(find.byKey(ProgressView.retroactiveNoteKey), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(ProgressView.blockedSectionKey),
              matching: find.byKey(ProgressView.retroactiveNoteKey)),
          findsOneWidget,
          reason: 'it answers the question the blocked list provokes, so it '
              'belongs beside that list');
    });

    testWidgets('OKUNAMAYAN GEÇMİŞ, BOŞ GEÇMİŞ DEĞİLDİR (C-280)',
        (WidgetTester tester) async {
      // 🔴 EKRANDA BULUNDU. Yürüyüş sırasında depo açılamadı ve aynı ekran
      // şunları YAN YANA söyledi:
      //   "We could not open your practice history."   (not — doğru)
      //   "…there is simply nothing here."             (bölüm — YALAN)
      // Okunamayan bir geçmiş ile boş bir geçmiş AYNI boş listeyi üretir ve
      // ZIT şeyler demektir; ikincisini birincisinden iddia etmek, bu dosyanın
      // her yerde kaçındığı "sen hiçbir şey yapmadın" cümlesidir — BİZİM
      // arızamızdan üretilmiş, KULLANICI hakkında bir iddia (J-066).
      final ProgressSummary s = ProgressSummary.build(
        history: const <SessionRecord>[],
        catalog: catalog,
        integrity: HistoryIntegrity.unavailable,
      );
      await pump(tester, s);

      expect(
          inSection(ProgressView.recordedSectionKey,
              ProgressStrings.unknownHistory),
          findsOneWidget,
          reason: 'depo AÇILAMADI ve bölüm bunu söylemiyor');
      expect(
          inSection(
              ProgressView.recordedSectionKey, ProgressStrings.emptyHistory),
          findsNothing,
          reason: 'okunamayan geçmiş "there is simply nothing here" diye '
              'raporlanıyor — arızamızdan kullanıcı hakkında iddia üretiliyor');

      // VE SESSİZ DE KALMIYOR (A3): boş bir bölüm, altında hangi cümle olursa
      // olsun "hiçbir şey yok" diye okunur — davet ettiği tahmin tam olarak
      // engellenmek isteneni.
      expect(find.byKey(ProgressView.emptyReasonKey), findsOneWidget);
    });

    testWidgets('ve BOŞ geçmiş hâlâ boş diyebiliyor — payda kontrolü (C-280)',
        (WidgetTester tester) async {
      // NEGATİF KONTROL: yukarıdaki düzeltme her boşluğu "bilinmiyor"a
      // çevirseydi, temiz okunmuş ve gerçekten boş bir geçmiş de kaybolurdu.
      await pump(tester, summaryOf(<SessionRecord>[]));
      expect(
          inSection(
              ProgressView.recordedSectionKey, ProgressStrings.emptyHistory),
          findsOneWidget,
          reason: 'temiz okunan boş geçmiş artık boş diyemiyor — düzeltme '
              'fazla kapsadı');
      expect(
          inSection(ProgressView.recordedSectionKey,
              ProgressStrings.unknownHistory),
          findsNothing);
    });

    testWidgets('empty history says so without hiding anything',
        (WidgetTester tester) async {
      await pump(tester, summaryOf(<SessionRecord>[]));
      expect(
          inSection(
              ProgressView.recordedSectionKey, ProgressStrings.emptyHistory),
          findsOneWidget);
      // The blocked list is NOT conditional on having history: a new user must
      // see the limits before investing time, not after.
      expect(
          find.descendant(
              of: find.byKey(ProgressView.blockedSectionKey),
              matching: find.textContaining('bpmResolved')),
          findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // The REAL content, not a fixture. This is the group that earns its keep:
  // C-111 was found by a Dart test that read the real artifact rather than a
  // hand-built one, and content drift is the same class of defect — a fixture
  // agrees with whatever I believed when I wrote it.
  // ─────────────────────────────────────────────────────────────────────────
  group('real content (asset bundle)', () {
    // WHY A DISK-BACKED BUNDLE AND NOT `rootBundle`
    //
    // `rootBundle.loadString` never completes under `flutter test` in this
    // setup — probed all three ways (plain `test`, `testWidgets`, and
    // `testWidgets` + `runAsync`) and every one hung with the tester process at
    // 0% CPU, which is what separates a deadlock from a slow machine. Rather
    // than skip the real-content check, the bundle is backed by the repository
    // files: `CourseCatalog.load` runs in full, including its tolerance for an
    // unwritten step document.
    //
    // The honest limit: this exercises the LOADER and the DERIVATION against
    // real content, not Flutter's own asset plumbing. Whether the declared
    // asset paths resolve on a device is a separate claim, and this test does
    // not make it.
    Future<CourseCatalog> loadReal(WidgetTester tester) async =>
        CourseCatalog.load(DiskBundle());

    testWidgets('loads, and every ungraded lesson names a reason',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      expect(real.lessons, isNotEmpty);

      for (final LessonInfo l in real.lessons.where((l) => !l.isScored)) {
        expect(l.reason, isNotNull,
            reason: '${l.id} is ungraded with NO stated reason — the silence '
                'K10 forbids');
        expect(l.reason!.trim(), isNotEmpty, reason: '${l.id} reason is blank');
      }
    });

    testWidgets('the blocked gates Choreia actually has today are all named',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      final Set<String> ids =
          real.blockedGates.map((BlockedGate g) => g.id).toSet();

      // These three are the measured limits recorded in the plan and UI-BRIEF
      // §3.9. If one stops being blocked, this test SHOULD fail — that is the
      // moment the surface's text must change too, and a stale limit is the
      // failure mode a hand-written list has.
      expect(ids, contains('bpmResolved'),
          reason: 'BPM is DISPUTED; if this gate cleared, the beat grid landed '
              'and §3.9 needs rewriting');
      expect(ids, contains('NO_WEIGHT_TRANSFER'));
      expect(ids, contains('STEP_LATE'));
    });

    // THIS TEST CHANGED BECAUSE THE WORLD DID, AND THAT IS THE DESIGN.
    //
    // It used to pin `hh_rock` as the unwritten step, and it BROKE the moment
    // that document was authored (2026-08-04) — which is what a nail test is
    // for: content moved and the suite refused to keep asserting yesterday's
    // state. The property it protects is unchanged, so it is re-aimed rather
    // than deleted.
    //
    // It no longer depends on the catalogue HAPPENING to be incomplete. That
    // dependency was the original's weakness: the day every step is authored,
    // `unreadableSteps` goes empty and an assertion that loops over it stops
    // asserting anything while still passing — the unbreakable-claim trap this
    // repo keeps paying for. So the missing document is MANUFACTURED here, and
    // the case stays real forever.
    testWidgets('an unreadable step is reported as unknown, never as clean',
        (WidgetTester tester) async {
      const String hidden = 'content/styles/hip_hop_foundations/steps/'
          'hh_bounce.json';
      final CourseCatalog crippled =
          await CourseCatalog.load(_BundleMissing(hidden));

      expect(crippled.unreadableSteps, contains('hh_bounce'),
          reason: 'a step whose document will not load must be RECORDED as '
              'unreadable, not quietly skipped');
      expect(crippled.blockedGates.map((BlockedGate g) => g.id),
          contains('hh_bounce'),
          reason: 'an unreadable step must appear as something we cannot '
              'check, otherwise the screen implies it needs no checks');

      // POSITIVE TWIN: the same load with nothing hidden must NOT report that
      // step as unreadable. Without this, a loader that marked everything
      // unreadable would pass the assertions above.
      final CourseCatalog real = await loadReal(tester);
      expect(real.unreadableSteps, isNot(contains('hh_bounce')));
    });

    testWidgets('a scored lesson exists and is NOT listed as blocked',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      final List<LessonInfo> scored = real.scoredLessons.toList();
      expect(scored, hasLength(1),
          reason: 'exactly one scored lesson today (ss_l1_footwork). If this '
              'changes, the honesty copy that says so must change with it');
      final Set<String> gateIds =
          real.blockedGates.map((BlockedGate g) => g.id).toSet();
      for (final LessonInfo l in scored) {
        expect(gateIds, isNot(contains(l.id)));
      }
    });

    testWidgets('the surface renders against real content without throwing',
        (WidgetTester tester) async {
      final CourseCatalog real = await loadReal(tester);
      final ProgressSummary s = ProgressSummary.build(
        history: <SessionRecord>[
          rec(lesson: 'ss_l1_footwork'),
          rec(lesson: 'ss_l1_basic', klass: ChoreiaLessonClass.demoOnly),
        ],
        catalog: real,
        totals: const RecordedSummary(sessions: 2, targetedSessions: 0,
            completed: 0, workedSeconds: 1200, scoredSessions: 1,
            demoOnlySessions: 1, unmeasuredUnits: 0),
      );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ProgressView(summary: s, catalog: real),
      ));
      expect(tester.takeException(), isNull);
      // The real demo-only reason must reach the row, not a placeholder.
      expect(
          find.descendant(
              of: find.byKey(const Key('progress.recorded.ss_l1_basic')),
              matching: find.textContaining('Taught, not graded — ')),
          findsOneWidget);
    });
  });

  group('the integrity sentence is ON SCREEN, not just in the type (C-172)',
      () {
    // Sabotage 2026-08-07: deleting the `integrityNote` block from
    // `ProgressView` left all 180 tests green. The C-163 fix — the sentence
    // that stops a reader believing their practice was recorded and lost —
    // could have been removed and every gate would have agreed.
    //
    // A gate that accepts the DELETION of the sentence it protects guards a
    // SILENCE, not an honesty.

    ProgressSummary summaryWith(HistoryIntegrity integrity) =>
        ProgressSummary.build(
          history: const <SessionRecord>[],
          catalog: const CourseCatalog(
              lessons: <LessonInfo>[], blockedGates: <BlockedGate>[]),
          integrity: integrity,
        );

    testWidgets('a build that records nothing SAYS so',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
          home: ProgressView(summary: summaryWith(HistoryIntegrity.notRecorded))));
      await tester.pump();

      expect(find.byKey(ProgressView.integrityNoteKey), findsOneWidget,
          reason: 'nothing is being written and the screen does not say so — '
              'the absence is silent again');
      expect(find.textContaining('does not save'), findsOneWidget);
      expect(find.textContaining('nothing in this source'), findsOneWidget,
          reason: 'the absence claim must stay scoped to this source');
    });

    testWidgets('a healthy history says NOTHING extra',
        (WidgetTester tester) async {
      // The positive twin. Without it, a view that printed the note
      // unconditionally would pass the test above.
      await tester.pumpWidget(MaterialApp(
          home: ProgressView(
              summary: summaryWith(
                  HistoryIntegrity.opened(unreadable: 0, readable: 0)))));
      await tester.pump();
      expect(find.byKey(ProgressView.integrityNoteKey), findsNothing);
    });
  });
}

/// Serves the repository's real content files through the [AssetBundle] API, so
/// the production loader is the thing under test.

/// A bundle that fails for ONE named asset, the way a missing step document
/// fails. Used to keep the unreadable-step case real even after every step in
/// the catalogue has been authored.
class _BundleMissing extends DiskBundle {
  _BundleMissing(this.missing);

  final String missing;

  @override
  Future<ByteData> load(String key) async {
    if (key == missing) throw FlutterError('asset not found: $key');
    return super.load(key);
  }
}
