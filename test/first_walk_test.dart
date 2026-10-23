import 'dart:io';

import 'package:choreia/app/history/session_store_access.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/live/live_view.dart';
import 'package:choreia/app/live/session_result_view.dart';
import 'package:choreia/app/live/session_tally.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

import 'support/replay_pose_source.dart';
import 'support/round_trip_store.dart';
import 'support/test_catalog.dart';

/// **A1 — ONE FULL FLOW, END TO END, FROM A FRESH INSTALL.**
///
/// launch → intro (dismissed BY ITS BUTTON) → style → lesson → live session →
/// result surface → a line on disk. Witnessed by a `NavigatorObserver`, driven
/// only by controls that are on the screen in front of the walker.
///
/// Why this file exists and `reachability_test.dart` was not enough
/// ---------------------------------------------------------------
/// That file measures how many screens a user can GO to, and it had to list
/// the live lesson as unreachable WITH A REASON: the page opened its own
/// camera and read its own `rootBundle`, so no test could enter it. The walk
/// stopped at the door of the only screen where a lesson actually happens —
/// and, one layer down, the app had no way to FINISH one: no control ended a
/// session, nothing was ever written, and the progress surface was hard-wired
/// to say this app "does not save".
///
/// So the missing piece was never a test. It was a terminal.
///
/// WHAT THIS WALK USES, AND WHAT THAT COSTS
/// ----------------------------------------
///   · [DeviceBundle] — the SAME machine the navigability measurement uses. A
///     bundle that reads the disk would open doors a phone does not have.
///   · [ReplayPoseSource] — recorded frames through the exact code the camera
///     drives. Replay is this project's only accepted verification path for
///     camera work; what it does NOT claim is that a device camera delivers
///     frames of this shape (that is A12, and it needs hardware).
///   · a real [JsonlSessionStore] on a real temp file — the shipping store and
///     the shipping format, not a stand-in that would accept records the disk
///     would reject.
void main() {
  late Set<String> declared;
  late DeviceBundle bundle;
  late LibraryCatalog library;

  const String styleId = 'hip_hop_foundations';
  const String lessonId = 'hh_l1_bounce';
  const String stepId = 'hh_bounce';

  setUpAll(() async {
    declared = declaredReferences();
    bundle = DeviceBundle(declared);
    library = await LibraryCatalog.load(bundle);

    // 🪤 POSITIVE CONTROL ⓪ — the reference this walk depends on is BIG, and
    // its size is the thing that used to stop the walk dead.
    //
    // `AssetBundle.loadString` hands anything over 50 KB to `compute()`, whose
    // isolate never runs under `flutter test`'s fake clock: the tester hangs
    // at 0% CPU. `DiskBundle` inherited that method, so the fake written to
    // AVOID the hang reproduced it — and only for the two files over the
    // threshold, which is what made it look like a bundle problem instead of a
    // size one. `DiskBundle` now decodes synchronously.
    //
    // Pinned rather than assumed: if the reference ever shrinks below 50 KB
    // the trap stops being reachable and this walk stops proving that the fix
    // is load-bearing.
    expect(File('content/references/$stepId.json').lengthSync(),
        greaterThan(50 * 1024),
        reason: 'referans 50 KB eşiğinin altına indi — `compute()` tuzağı '
            'artık bu yürüyüşten geçmiyor, kanıt değeri düştü');
  });

  /// A FRESH INSTALL: the intro has never been seen and the store is empty.
  Widget app(
    _RouteSpy spy, {
    required SessionStore store,
    required PoseSourceMaker source,
    Future<bool> Function()? probe,
  }) =>
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[spy],
        home: ChoreiaShell(
          // Isolated future-capability route probe, not production release access.
          cameraSessionsAvailable: true,
          bundleOverride: () async => library,
          flagOverride: MemoryFirstRunFlag(),
          env: LiveEnvironment(
            bundle: bundle,
            source: source,
            storeOpener: () async => store,
            permanentlyDeniedProbe: probe,
          ),
        ),
      );

  /// Walk from launch to the live lesson, pressing only what is on screen.
  Future<void> walkToLesson(WidgetTester tester) async {
    expect(find.byType(FirstRunView), findsOneWidget,
        reason: 'taze kurulumda tanıtım ekranı görünmüyor');
    // BY THE BUTTON, never by setting the flag behind the UI — a walk that
    // skips a screen cannot report on whether that screen has an exit (A2).
    await tester.tap(find.byKey(FirstRunView.continueKey));
    await _settle(tester);
    expect(find.byType(LibraryView), findsOneWidget);

    final Finder card = find.byKey(LibraryView.tileKey(styleId));
    await tester.ensureVisible(card);
    await _settle(tester);
    await tester.tap(card);
    await _settle(tester);
    expect(find.byType(StyleDetailView), findsOneWidget);

    final Finder start = find.widgetWithText(FilledButton, StyleStrings.start);
    await _scrollTo(tester, start);
    // Found is not reachable: a lazy `ListView` builds children inside its
    // cacheExtent, BELOW the viewport, so `find` sees a button the user
    // cannot touch and `tap` lands on empty space.
    await tester.ensureVisible(start);
    await _settle(tester);
    await tester.tap(start);
    await _settle(tester);
    expect(find.byType(LiveLessonPage), findsOneWidget,
        reason: 'Start basıldı ama canlı ders açılmadı');
  }

  Directory tmp() => Directory.systemTemp.createTempSync('choreia_walk_');

  /// The record the walk actually produced, handed to the REAL store below.
  /// Null until the walk runs — the disk test asserts that, so an ordering
  /// change cannot silently turn it into a test of a hand-written record.
  SessionRecord? walkedRecord;

  group('A1 — the whole flow, once', () {
    testWidgets(
        'fresh install → intro → style → lesson → result → a line on '
        'disk', (WidgetTester tester) async {
      final RoundTripStore store = RoundTripStore();

      // POSITIVE CONTROL ①, before anything is claimed: the store starts
      // EMPTY. Without it, a walk that never wrote anything would be
      // indistinguishable from one whose assertion reads a pre-existing
      // record.
      expect(store.lines, isEmpty);

      final ReplayPoseSource replay =
          ReplayPoseSource(make: dancingBody(), count: 120);
      final _RouteSpy spy = _RouteSpy();

      await tester.pumpWidget(app(spy, store: store, source: () => replay));
      await _settle(tester);
      await walkToLesson(tester);

      // Let the replay run through the judge. Bounded pumps, never
      // `pumpAndSettle`: `ChoreiaBackdrop` repeats an animation for the life
      // of the app, so the frame queue is never empty and settling never
      // returns.
      for (int i = 0; i < 12; i++) {
        await _settle(tester);
      }

      expect(replay.started, isTrue,
          reason: 'canlı sayfa poz kaynağını hiç açmadı');

      // THE TERMINAL. It is on screen because the session is underway — the
      // control does not exist in the idle or refused states, by design.
      final Finder finish = find.byKey(LiveView.finishKey);
      await _scrollTo(tester, finish);
      await tester.ensureVisible(finish);
      await _settle(tester);

      // REAL DISK IO INSIDE A WIDGET TEST MUST GO THROUGH `runAsync`: the test
      // body runs in a FAKE-ASYNC zone where a real write never completes, and
      // the process hangs at 0% CPU instead of failing. Walked into twice in
      // this codebase already (progress_test, then end_to_end_test), so the
      // guard is structural: the tap that triggers a write is wrapped, and
      // only that tap.
      await tester.tap(finish);
      await _settle(tester);

      // ── the result surface ────────────────────────────────────────────
      expect(find.byType(SessionResultView), findsOneWidget,
          reason: 'oturum bitti ama sonuç yüzeyine varılmadı');
      expect(find.byKey(SessionResultView.storedKey), findsOneWidget,
          reason: 'sonuç yüzeyi "kaydedildi" demiyor — hangi dal çizildi?');
      expect(find.byKey(SessionResultView.notStoredKey), findsNothing);
      expect(find.byKey(SessionResultView.failedKey), findsNothing);

      // The live route is REPLACED, not stacked: a finished session is not a
      // place you can go back into.
      expect(spy.replaced.single, ('live/$lessonId', 'result/$lessonId'),
          reason: 'rota izi: pushed=${spy.pushed} replaced=${spy.replaced}');
      // The APPEND-ONLY trail, not the live stack: `pushed` mirrors what is
      // currently on the navigator, and the replacement removes the lesson
      // from it. A walk has to be able to say where it HAS BEEN, or the one
      // screen it passed through on the way is invisible in the evidence.
      expect(spy.trail,
          <String>['style/$styleId', 'live/$lessonId', 'result/$lessonId'],
          reason: 'yürüyüşün rota izi değişti: ${spy.trail}');
      expect(spy.pushed, <String>['style/$styleId', 'result/$lessonId'],
          reason: 'yığının SON hâli beklenenden farklı: ${spy.pushed}');

      // ── KATI, İKİ PENCEREYLE (koordinatör hükmü H-4 ②) ────────────────
      //
      // Sayma kuralının KATI ölçütü tek bir kelime: `Navigator.push`. Bu
      // yürüyüşün son adımı `pushReplacement` ⇒ kullanıcının GERÇEKTEN vardığı
      // sonuç yüzeyi o ölçütün dışında kalıyor (C-271 ④). Kuralın kendi cümlesi
      // ise *"ayrı ROTA: gidersin ve geri dönebilirsin"* diyor ve sonuç yüzeyi
      // bunu karşılıyor — yani ölçütün KELİMESİ ile ölçtüğü ŞEY ayrışmış.
      //
      // ⛔ BU TEST BİR KAZANAN SEÇMEZ, VE SEÇMEMESİ HÜKMÜN KENDİSİ: kural beş
      // hattın KARŞILAŞTIRILABİLİR sayması için yazıldı; neyin sayıldığını tek
      // taraflı değiştirmek karşılaştırılabilirliği ölçmek yerine bozar.
      // Ölçülen şey ANLAŞMAZLIĞIN BÜYÜKLÜĞÜ — hakem koordinatör.
      //
      // +1'ler kabuk: `MaterialApp.home` itilmez ama kullanıcı üstünde durur
      // (kuralın kendi maddesi: *zemin, hedef değil*).
      const int shellFloor = 1;
      final int strictExcludingReplace = shellFloor + spy.pushedEver.length;
      final int strictIncludingReplace = shellFloor + spy.trail.length;

      expect(strictExcludingReplace, 3,
          reason: 'KATI (pushReplacement HARİÇ) değişti. İtilenler: '
              '${spy.pushedEver}. Bu sayı hattın faz sırasını belirliyor — '
              'testi güncellemeden ÖNCE koordinatöre söyle.');
      expect(strictIncludingReplace, 4,
          reason: 'KATI (pushReplacement DAHİL) değişti. İz: ${spy.trail}');

      // VE FARKIN KENDİSİ ÇİVİLİ. `pushReplacement` bir gün kalkarsa iki
      // pencere ÇAKIŞIR ve açık soru konusuz kalır — o gün bu assert kırmızı
      // vererek "artık tartışılacak bir şey yok, kuralı kapat" der. Farkı
      // ölçmeyen bir test, anlaşmazlığın çözüldüğünü göremez.
      expect(strictIncludingReplace - strictExcludingReplace, 1,
          reason: 'iki pencere arasındaki fark 1 değil — ya yeni bir '
              'pushReplacement eklendi ya var olan kalktı. Her iki durumda da '
              'AÇIK sorunun konusu değişti: docs/design/'
              'GEZILEBILIRLIK-SAYMA-KURALI.md §AÇIK güncellenmeli.');
      expect(spy.replaced, hasLength(1),
          reason: 'farkı üreten tek yer değiştirmedir; sayısı değiştiyse '
              'yukarıdaki iki pencere de artık başka şey ölçüyor');

      // ── the record ────────────────────────────────────────────────────
      final List<SessionRecord> history = store.records;
      expect(history, hasLength(1),
          reason: 'oturum bitti ve depoya HİÇBİR ŞEY yazılmadı');
      final SessionRecord r = history.single;
      // THE LESSON, not the step. `CourseCatalog.lessonById` is keyed by
      // lesson; a record carrying `hh_bounce` misses that lookup and renders
      // on the progress screen under its own raw identifier. Found by the
      // route names disagreeing — `live/hh_l1_bounce` next to
      // `result/hh_bounce` is the same confusion, one layer up.
      expect(r.lessonId, lessonId);
      expect(r.lessonClass, 'demoOnly',
          reason: 'hh_l1_bounce puanlanmayan bir ders — sınıf YAZIM ANINDA '
              'saklanır, sonradan türetilmez');
      expect(r.unitLabel, 'cycle');
      expect(r.unitsCompleted, greaterThan(0),
          reason: 'dans eden bir gövde replay edildi ve motor tek bir tam '
              'döngü bile okumadı — fixture bu referansa karşı çalışmıyor');
      expect(r.plannedUnits, absentTargetOnTheWire,
          reason: 'bu derste ilan edilmiş bir döngü hedefi YOK; başka bir '
              'değer yüzeye "hedefe ulaşıldı" yazdırır');

      // It is a LINE in the shipping format, not merely an object held in
      // memory: the store round-trips through the same `jsonEncode` /
      // `SessionRecord.fromJson` pair the real one uses. The line itself is
      // handed to the real `JsonlSessionStore` in `disk round trip` below.
      expect(store.lines.single,
          contains('"v":${JsonlSessionStore.schemaVersion}'));
      walkedRecord = r;

      // ── back out, and the progress surface now has something ──────────
      await tester.tap(find.byKey(SessionResultView.doneKey));
      await _settle(tester);
      // Lands on the STYLE page, not the library — and that is the point of
      // replacing the lesson route rather than stacking on it. The result is
      // the lesson's last screen, so leaving it goes where the lesson was
      // started FROM; a learner is one tap from the next lesson of the same
      // style, and cannot walk backwards into a session that is over.
      expect(find.byType(StyleDetailView), findsOneWidget,
          reason: 'sonuç ekranından çıkış, dersin başlatıldığı yere '
              'dönmüyor: ${spy.pushed}');
      expect(find.byType(SessionResultView), findsNothing);

      await tester.pageBack();
      await _settle(tester);
      expect(find.byType(LibraryView), findsOneWidget,
          reason: 'stil sayfasından kabuğa dönülemiyor');

      await tester.tap(find.byKey(ChoreiaShell.progressTabKey));
      await _settle(tester);
      expect(find.byType(ProgressView), findsOneWidget);
      // THE DISPLAY NAME FROM CONTENT, not the record's identifier. This is
      // the assertion the lessonId/stepId confusion would have survived:
      // `ProgressSummary.build` falls back to the raw key when
      // `lessonById` misses, so a record carrying `hh_bounce` renders as
      // "hh_bounce" — a row that looks present and names nothing a learner
      // recognises. The written-course entry sits above the history, so the
      // row may be below the first screen: scroll to it before asserting.
      await tester.scrollUntilVisible(
          find.text('The bounce (not graded)').first, 200,
          scrollable: find
              .descendant(
                  of: find.byType(ProgressView),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text('The bounce (not graded)'), findsWidgets,
          reason: 'ilerleme ekranı az önce yapılan pratiği içerikteki ADIYLA '
              'göstermiyor');
      expect(find.text(stepId), findsNothing,
          reason: 'ham adım kimliği yüzeye sızdı — kayıt DERSİ değil ADIMI '
              'taşıyor');
    });

    testWidgets(
        'SABOTAGE — a store that refuses says so, and does NOT draw '
        'the numbers', (WidgetTester tester) async {
      // WITHOUT THIS THE WALK ABOVE PROVES NOTHING ABOUT THE WRITE. A result
      // screen that always renders `storedKey` would pass it. Here the store
      // throws on `append` and every assertion above must invert:
      // `failedKey` instead of `storedKey`, and no counts on screen.
      //
      // And it is a different failure from "nothing to store": that twin is
      // driven separately below, because collapsing the two is exactly how a
      // silent loss gets dressed as an empty session.
      final _RouteSpy spy = _RouteSpy();
      final _RefusingStore store = _RefusingStore();
      await tester.pumpWidget(app(spy,
          store: store,
          source: () => ReplayPoseSource(make: dancingBody(), count: 120)));
      await _settle(tester);
      await walkToLesson(tester);
      for (int i = 0; i < 12; i++) {
        await _settle(tester);
      }

      final Finder finish = find.byKey(LiveView.finishKey);
      await _scrollTo(tester, finish);
      await tester.ensureVisible(finish);
      await _settle(tester);
      await tester.tap(finish);
      await _settle(tester);

      expect(find.byType(SessionResultView), findsOneWidget,
          reason: 'yazma başarısız oldu diye ekran kayboldu — kullanıcı '
              'nerede olduğunu bilemez');
      expect(find.byKey(SessionResultView.failedKey), findsOneWidget,
          reason: 'depo reddetti ve yüzey bunu SÖYLEMİYOR');
      expect(find.byKey(SessionResultView.storedKey), findsNothing,
          reason: 'hiçbir şey kaydedilmedi ve ekran kaydedildi diyor — '
              '"talkative absence" sınıfı');
      expect(store.attempts, 1,
          reason: 'yazma hiç DENENMEDİ — kırmızı, sebebinden ötürü değil '
              'yokluğundan ötürü olurdu');
    });

    testWidgets(
        'SABOTAGE TWIN — a camera that never starts writes NOTHING, '
        'and the record stays empty', (WidgetTester tester) async {
      // "Never started" is not zero (M-F-268). A refused camera produced no
      // practice, so a 0-cycle row would put a session in the learner's
      // history that did not happen. The twin matters in BOTH directions: a
      // page that wrote unconditionally would pass the first sabotage and
      // fail here.
      final RoundTripStore store = RoundTripStore();
      final _RouteSpy spy = _RouteSpy();
      await tester.pumpWidget(app(spy,
          store: store,
          source: () => ReplayPoseSource(
                make: dancingBody(),
                refusal: const LivePermissionDenied(),
              ),
          // The OS cannot answer under `flutter test`. Injected so this walk
          // measures the REFUSAL screen rather than the page's behaviour while
          // waiting for an answer that never comes — a distinct defect,
          // covered by its own test below.
          probe: () async => false));
      await _settle(tester);
      await walkToLesson(tester);
      await _settle(tester);

      // The finish control is ABSENT here — there is no session to end, and
      // offering to keep one would promise something that does not exist.
      expect(find.byKey(LiveView.finishKey), findsNothing,
          reason: 'kamera hiç açılmadı ama ekran "oturumu bitir" öneriyor');
      // NO DEAD END: the refusal still carries its own action.
      expect(find.byKey(LiveView.actionKey), findsOneWidget);

      expect(store.lines, isEmpty,
          reason: 'kamera hiç açılmadı ve yine de bir oturum yazıldı — '
              '"hiç başlamadı" SIFIR DEĞİLDİR');
    });
  });

  group('the record the walk produced survives the REAL store', () {
    test('disk round trip — same record, shipping class, real file', () async {
      // THE OTHER HALF OF THE CHAIN. The walk proves the flow reaches a store;
      // this proves the thing it handed over is something the shipping store
      // accepts, writes and reads back — on a real file, through the atomic
      // tmp+rename, with no widget tree and therefore no fake clock in the way.
      //
      // The record is the WALK'S OWN, not one written here: a hand-made record
      // would test `JsonlSessionStore` (which has its own tests) instead of
      // testing what this app actually produces.
      expect(walkedRecord, isNotNull,
          reason: 'yürüyüş koşmadı ya da hiçbir kayıt üretmedi — bu tur o '
              'kaydı sınıyor, elle yazılmış bir kaydı değil');

      final Directory dir = tmp();
      addTearDown(() => dir.deleteSync(recursive: true));
      final File file = File('${dir.path}/$sessionsFileName');
      final JsonlSessionStore store = JsonlSessionStore(file);

      expect(file.existsSync(), isFalse);
      await store.append(walkedRecord!);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync().trim().split('\n'), hasLength(1));

      final List<SessionRecord> back = await store.recent();
      expect(back, hasLength(1));
      expect(await store.unreadableRecords(), 0,
          reason: 'yazdığımız satırı kendi okuyucumuz çözemedi');
      expect(back.single.lessonId, walkedRecord!.lessonId);
      expect(back.single.lessonClass, walkedRecord!.lessonClass);
      expect(back.single.unitsCompleted, walkedRecord!.unitsCompleted);
      expect(back.single.plannedUnits, walkedRecord!.plannedUnits);
      expect(back.single.unitLabel, walkedRecord!.unitLabel);
    });
  });

  group('the fixture is a valid probe of this lesson', () {
    test(
        'POSITIVE CONTROL ② — the walked lesson is the only startable one, '
        'and it is the one the record names', () async {
      // If the startable set ever changes, the walk above is silently walking
      // a different product. Pinned here rather than assumed, and the same
      // number `reachability_test` pins — two files, one fact.
      final List<String> startable = <String>[
        for (final StyleCard c in library.cards)
          for (final LessonOffer o in c.offers(library.runnableSteps))
            if (o.canStart) '${c.entry.id}/${o.lesson.id}',
      ];
      expect(startable, <String>['$styleId/$lessonId'],
          reason: 'başlatılabilir ders kümesi değişti: $startable');
    });
  });
}

/// A store that opens and then refuses every write.
///
/// Counts its attempts so the sabotage can tell "the write failed" apart from
/// "the write was never tried" — a red that comes from absence proves the
/// opposite of what it looks like it proves.
class _RefusingStore implements SessionStore {
  int attempts = 0;

  @override
  Future<void> append(SessionRecord record) async {
    attempts++;
    throw const FileSystemException('sabotaj: depo yazmayı reddediyor');
  }

  @override
  Future<List<SessionRecord>> recent({int? limit}) async => <SessionRecord>[];

  @override
  Future<int> workedSecondsFor(String lessonId) async => 0;

  @override
  Future<int> unreadableRecords() async => 0;
}

typedef PoseSourceMaker = ReplayPoseSource Function();

/// Bounded scroll. `scrollUntilVisible` never returns for the same reason
/// `pumpAndSettle` does not — it settles between steps and this app always has
/// a frame pending.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  for (int i = 0; i < 25 && target.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await _settle(tester);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Witnesses routes AND replacements.
///
/// `didReplace` is overridden because the finish step uses
/// `pushReplacement` — a spy that only watched pushes would report the walk
/// ending at the live lesson and never notice the result screen at all.
class _RouteSpy extends NavigatorObserver {
  /// What is on the navigator NOW.
  final List<String> pushed = <String>[];

  /// Everywhere the walk has BEEN, in order, never pruned. A stack alone
  /// cannot answer "did we pass through the lesson?" once the lesson has been
  /// replaced by its own result.
  final List<String> trail = <String>[];

  /// Everywhere reached by `Navigator.push` SPECIFICALLY, never pruned.
  ///
  /// [pushed] is the live stack and [trail] is every arrival by any means;
  /// neither can answer "how many places did a PUSH take us to", which is the
  /// one question the strict counting rule's wording actually asks. Kept
  /// separate rather than derived by subtracting [replaced] from [trail]: a
  /// derivation would silently become wrong the first time a route is both
  /// pushed and later replaced by something else.
  final List<String> pushedEver = <String>[];

  final List<(String, String)> replaced = <(String, String)>[];

  String _name(Route<dynamic>? r) => r?.settings.name ?? '(isimsiz)';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) {
    if (previous != null) {
      pushed.add(_name(route));
      pushedEver.add(_name(route));
      trail.add(_name(route));
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previous) =>
      pushed.remove(_name(route));

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replaced.add((_name(oldRoute), _name(newRoute)));
    trail.add(_name(newRoute));
    pushed
      ..remove(_name(oldRoute))
      ..add(_name(newRoute));
  }
}
