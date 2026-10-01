import 'dart:io';

import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/live/pose_model.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/practice_lab/practice_lab_view.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:choreia/app/today/today_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/round_trip_store.dart';
import 'support/test_catalog.dart';

/// **The navigability measurement.** How many separate screens can a user
/// actually GO to, starting from launch, pressing only controls that are on
/// the screen in front of them?
///
/// Why this is a gate and not a note
/// ---------------------------------
/// The number that set this line's phase — "Choreia 1, a user who opens the
/// app can go nowhere" — was measured once, by hand, at 02:00. A hand-measured
/// number goes stale the moment anyone commits, and nobody can tell that it
/// has. Pinned here, it re-measures on every run and fails loudly when the
/// shape of the app changes without this file changing with it.
///
/// The counting rule (the family's, so five lines stay comparable)
/// --------------------------------------------------------------
/// Two readings, because the orchestrator's first order said "separate screen"
/// without saying whether a curtain inside one page counts, and JabLab's line
/// swung 6↔11 on exactly that ambiguity.
///
/// * **STRICT — separate ROUTE.** A place you GO to and can come back FROM:
///   one `Navigator.push`. Curtains inside a page do not count, however
///   different they look.
/// * **LOOSE — separate PLACE.** Every strict route, plus destinations you
///   switch between without a push (the shell's tabs), because a tab is a
///   place a user returns to even though the route never changes.
///
/// Neither reading counts a screen that exists in `lib/` but has no trigger.
/// **A line's presence is not its cue** — the whole reason this line's
/// `ProgressView` sat fully tested and unreachable for weeks.
void main() {
  late LibraryCatalog library;
  late Set<String> declared;

  // Loaded once, outside `testWidgets`. Anything above ~50 KB read inside a
  // widget test hangs forever: `loadString` hands off to `compute()`, and the
  // fake clock never advances the isolate. The references here are 74-79 KB.
  setUpAll(() async {
    declared = declaredReferences();
    library = await LibraryCatalog.load(DeviceBundle(declared));
  });

  /// A FRESH INSTALL by default — which is the only walk that matches what a
  /// new user experiences. Passing `seen: true` measures the returning user.
  Widget app(NavigatorObserver spy, {bool introSeen = false}) => MaterialApp(
        navigatorObservers: <NavigatorObserver>[spy],
        home: ChoreiaShell(
          bundleOverride: () async => library,
          flagOverride: MemoryFirstRunFlag(seen: introSeen),
          // An EMPTY store, injected for the same reason the bundle and the
          // flag are: this file measures where a user can GO, and the real
          // opener is a platform channel that neither answers nor throws under
          // `flutter test`. Left out, the progress tab renders its "reading
          // your record" wait and the loose count silently loses a
          // destination — which is exactly what this gate caught when the
          // store was first wired in.
          env: LiveEnvironment(storeOpener: () async => RoundTripStore()),
        ),
      );

  /// Dismisses the first-run screen the way a user does: by pressing the
  /// button on it. Never by setting the flag behind the UI — a walk that
  /// skips a screen cannot report on whether that screen has an exit.
  Future<void> passIntro(WidgetTester tester) async {
    expect(find.byType(FirstRunView), findsOneWidget,
        reason: 'taze kurulumda tanıtım ekranı görünmüyor');
    await tester.tap(find.byKey(FirstRunView.continueKey));
    await _settle(tester);
  }

  group('kaç ekrana GİDİLEBİLİR — ölçüm, iddia değil', () {
    testWidgets('KATI okuma: ayrı rota sayısı', (WidgetTester tester) async {
      final _RouteSpy spy = _RouteSpy();
      await tester.pumpWidget(app(spy));
      await _settle(tester);

      // 0 — the first-run screen. A PLACE, not a route: it is drawn inside
      // the shell's own route, so it changes what a new user sees without
      // changing what the strict count measures. Counted in the loose
      // reading below.
      await passIntro(tester);

      // 1 — the shell itself. `MaterialApp.home` is a route the user is
      // standing on, so it counts; it is the floor, not a destination.
      expect(find.byType(LibraryView), findsOneWidget,
          reason: 'açılış ekranı kütüphane olmalı');

      // What a DEVICE could start. Derived from content filtered through the
      // shipping manifest, because a lesson whose reference is on disk but
      // undeclared is not a lesson anyone can open.
      final List<String> startable = <String>[
        for (final StyleCard c in library.cards)
          for (final LessonOffer o in c.offers(library.runnableSteps))
            if (o.canStart) '${c.entry.id}/${o.lesson.id}',
      ];
      expect(startable, <String>['hip_hop_foundations/hh_l1_bounce'],
          reason: 'başlatılabilir ders kümesi değişti: $startable — KATI sayı '
              'buna bağlı, testi güncellemeden ÖNCE koordinatöre söyle');
      final String styleId = startable.single.split('/').first;

      // 2 — the style page. Driven by tapping a card that is actually
      // painted, never by calling the route builder: a route nobody can
      // reach is precisely what this measurement exists to exclude.
      final Finder card = find.byKey(LibraryView.tileKey(styleId));
      await tester.ensureVisible(card);
      await _settle(tester);
      await tester.tap(card);
      await _settle(tester);
      expect(find.byType(StyleDetailView), findsOneWidget,
          reason: 'stil kartı bir yere gitmiyor');

      // 3 — the live lesson. Reached by pressing the button, never by
      // pushing the route directly. Until 2026-08-07 12:0x this walk ended
      // here: the lesson was written, the page was built, the reference was
      // on disk — and `pubspec.yaml` did not ship it, so no device could
      // open it and no button was painted. One manifest line, one ruling.
      final Finder startButton = find.widgetWithText(FilledButton, 'Start');
      await _scrollTo(tester, startButton);
      expect(startButton, findsOneWidget,
          reason: 'başlatılabilir ders var ama Start düğmesi yok — türetim '
              'ile yüzey ayrışmış');
      // Found is not reachable. A lazy `ListView` builds children inside its
      // cacheExtent — BELOW the viewport — so `find` sees a button the user
      // cannot touch and `tap` lands on empty space. The widget-scale form of
      // "a replica existing is not its cue existing".
      await tester.ensureVisible(startButton);
      await _settle(tester);
      await tester.tap(startButton);
      await _settle(tester);

      // KATI = shell + style page + live lesson.
      expect(spy.pushed, hasLength(2),
          reason: 'KATI sayı beklenenden farklı. Ölçülen rotalar: '
              '${spy.pushed}. Bu sayı hattın FAZ SIRASINI belirliyor — '
              'değiştiyse testi güncellemeden ÖNCE koordinatöre söyle.');
      expect(spy.pushed.last, 'live/hh_l1_bounce',
          reason: 'Start basıldı ama canlı ders rotasına gidilmedi');
    });

    testWidgets('YÜRÜYÜŞ EKSİK YÜRÜNMEDİ — aday = varılan ⊎ varılamayan',
        (WidgetTester tester) async {
      // ⚠️ SÖZLEŞME (d) — ve Lissom'un kendi maddesini KÖR yazmasından alınan
      // ders: **bir bölme denetimi, iki tarafı AYNI KAYNAKTAN okuyorsa
      // denetim değil TANIMDIR.** Aday kümesi bu yüzden yürüyüşten DEĞİL,
      // `lib/` KAYNAĞINDAN ada göre üretiliyor (`…View` / `…Page`).
      //
      // Niye gerekli: yürüyüş "kaç yere vardım" sayıyordu ama "kaç yere
      // VARAMADIM" hiç sorulmuyordu — eksik yürünen bir yürüyüş, sessizce
      // daha küçük ve "doğru" görünen bir sayı üretir. *"0 kusur" en kolay
      // sahtelenen sayıdır.*
      // (a) İKİ BAĞIMSIZ TÜRETİM — sözleşme: *desenin kendisi de ölçülür.*
      // Tek kanal, kapsamı YAZANIN ADLANDIRMA ALIŞKANLIĞI kadar bırakır;
      // Gravita'da ölçülen arıza tam buydu (`OnboardingFlow` hiç aday
      // olmuyordu).
      //
      // ⚠️ Ostinato'nun YAPI kanalı (`Scaffold(` kuran sınıf) BURAYA
      // GEÇMİYOR ve bu ÖLÇÜLDÜ: Choreia'da `Scaffold` TEK bir kabukta,
      // hedefler `IndexedStack` gövdesi olarak takılıyor → `LibraryView` ve
      // `ProgressView` `Scaffold` kurmuyor ama gerçek hedefler. Kopyalasaydım
      // ikisini hayalet ilan ederdim. Bu ağacın yapısal imzası MONTAJ NOKTASI:
      // rota oluşturucusu · kabuk sekmesi · ilk-koşu kaplaması.
      final Map<String, String> lib = <String, String>{
        for (final FileSystemEntity e
            in Directory('lib').listSync(recursive: true))
          if (e is File && e.path.endsWith('.dart'))
            e.path: e.readAsStringSync(),
      };
      Set<String> matches(RegExp re, [int group = 1]) => <String>{
            for (final String src in lib.values)
              for (final RegExpMatch m in re.allMatches(src)) m.group(group)!,
          };

      final Set<String> byName = matches(RegExp(
          r'^class ([A-Za-z_]+(?:View|Page)) extends Stat',
          multiLine: true));
      final Set<String> byStructure = <String>{
        ...matches(RegExp(r'builder:\s*\([^)]*\)\s*=>\s*(?:const\s+)?'
            r'([A-Z][A-Za-z_]*)\(')),
        // MaterialApp.home also mounts a real destination without a builder.
        ...matches(
            RegExp(r'home:\s*(?:const\s+)?([A-Z][A-Za-z_]*(?:View|Page))\(')),
        // ⚠️ Kabuk sekmeleri BLOKTAN okunuyor, satır girintisinden DEĞİL.
        // İlk yazımım `^\s{10,}X\(\s*$` deseniydi ve `ProgressView`i
        // görüp `LibraryView`i KAÇIRDI — çünkü birinin argümanları alt
        // satırda, ötekininki aynı satırda. *Bir desenin kapsamı, yazarının
        // BİÇİMLENDİRME alışkanlığı kadardı* — (a)'nın uyarısının boşluk
        // karakteri hâli, ve testin kendisi yakaladı.
        for (final String src in lib.values)
          for (final RegExpMatch blok
              in RegExp(r'IndexedStack\([\s\S]{0,400}?children:\s*<Widget>\['
                      r'([\s\S]*?)\n\s*\],')
                  .allMatches(src))
            ...RegExp(r'\b([A-Z][A-Za-z_]*)\(')
                .allMatches(blok.group(1)!)
                .map((RegExpMatch m) => m.group(1)!),
        ...matches(RegExp(r'_introSeen == false[\s\S]{0,200}?return\s+'
            r'([A-Z][A-Za-z_]*)\(')),
      };
      final Set<String> candidates = byName.union(byStructure);

      expect(candidates.length, greaterThan(3),
          reason: 'kaynak taraması aday bulamadı — denetim vakumda');
      expect(byStructure.difference(byName), isEmpty,
          reason: 'YAPIDA monte edilen bir ekranı AD deseni kaçırıyor — '
              'desenin kapsamı adlandırma alışkanlığının altında kaldı '
              '(Gravita M-F-575 sınıfı)');

      // (e) ELLE KÜME — kaynak DEĞİL, türetimin POZİTİF KONTROLÜ.
      //
      // ⚠️ ŞERH 1: bu küme bir ALT SINIRDIR, **tam envanter DEĞİLDİR**.
      // ⚠️ ŞERH 2: buraya ekleme yapmak envanter güncellemesi DEĞİL,
      //    KONTROLÜN TABANINI yükseltmektir.
      //
      // Gerekçe (JabLab M-F-575): türetim `_XState` elemesiyle her
      // StatefulWidget ekranını yok etmişti ve YAKALAYAN ŞEY ELLE KÜMEYDİ.
      const Set<String> knownFloor = <String>{
        'FirstRunView',
        'LibraryView',
        'ProgressView',
        'StyleDetailView',
        'LiveLessonPage',
        'SalsaCoursePage',
        'SalsaLessonPage',
      };
      expect(candidates.containsAll(knownFloor), isTrue,
          reason: 'türetim, bilinen tabanı KAPSAMIYOR — eksik: '
              '${knownFloor.difference(candidates)}. Elle küme kaynak değil '
              'kontroldür: türetim onu yutuyorsa türetim bozuktur.');

      final Set<String> reached = <String>{};
      void snapshot() {
        for (final String c in candidates) {
          if (find
              .byWidgetPredicate((Widget w) => w.runtimeType.toString() == c)
              .evaluate()
              .isNotEmpty) {
            reached.add(c);
          }
        }
      }

      final _RouteSpy spy = _RouteSpy();
      await tester.pumpWidget(app(spy));
      await _settle(tester);
      snapshot(); // tanıtım
      await passIntro(tester);
      snapshot(); // kütüphane
      await tester.tap(find.byKey(ChoreiaShell.progressTabKey));
      await _settle(tester);
      snapshot(); // ilerleme
      await tester.tap(find.byKey(ChoreiaShell.libraryTabKey));
      await _settle(tester);
      final Finder card =
          find.byKey(LibraryView.tileKey('hip_hop_foundations'));
      await tester.ensureVisible(card);
      await _settle(tester);
      await tester.tap(card);
      await _settle(tester);
      snapshot(); // stil sayfası

      // VARILAMAYANLAR — adıyla ve SEBEBİYLE. Boş bırakılamaz: sebebi
      // olmayan bir dışlama, denetimi tekrar tanıma çevirir.
      const Map<String, String> unreachableInWalk = <String, String>{
        // ⚠️ SEBEP DEĞİŞTİ 2026-08-13 — ve eskisi ARTIK YANLIŞTI, ki bunu
        // yakalayan şey aşağıdaki bayatlık probu oldu. Eski gerekçe *"widget
        // testinde AÇILAMAZ"* diyordu; bugün açılabiliyor. Açılmıyor olmasının
        // sebebi bu YÜRÜYÜŞÜN cihaz varsayılanlarıyla koşması: burada ölçülen
        // şey nereye GİDİLEBİLDİĞİ, ve kamerası+paketi enjekte edilmiş bir
        // kabuk o soruyu cevaplamaz.
        //
        // *Bir dışlamanın gerekçesi, dışlananın kendisi kadar denetlenir* —
        // ve bu satır, gerekçenin kendisinin bayatlayabildiğinin kanıtı.
        'LiveLessonPage': 'bu yürüyüş kabuğu CİHAZ varsayılanlarıyla kuruyor '
            '(gerçek kamera + `rootBundle` + gerçek depo), o yüzden ekran '
            'burada çizilmiyor. ARTIK YÜRÜNEBİLİR: `LiveEnvironment` enjekte '
            'edilerek baştan sona yürünüyor — `first_walk_test.dart`. KATI '
            'sayımda ROTASI ölçülüyor (`spy.pushed`), EKRANI orada.',
        'LiveView': 'yalnız `LiveLessonPage`in gövdesi olarak çizilir; o '
            'açılamadığı için bu da açılamıyor. AYRI testi var '
            '(`live_view_test.dart`, 7 hâlin hepsi) ve `first_walk_test` '
            'içinde gerçek oturumda çiziliyor.',
        'SessionResultView': 'bir oturumu BİTİRMEDEN varılamaz, ve oturum bu '
            'yürüyüşte hiç başlamıyor (yukarıdaki sebep). Tek girişi '
            '`LiveLessonPage._finish`; `first_walk_test.dart` oraya '
            'düğmeyle varıyor.',
      };

      // The profile is a shell destination, so the strict pushed-route walk
      // does not count it. The loose walk below visits it.
      const Set<String> unreachableByDesign = <String>{
        'ProfileView',
        // Only the separate failed-account startup route can mount this view.
        // The normal configured shell walk cannot and must not simulate it.
        'ChoreiaAccountFailureView',
      };
      final String shellSrc = lib.entries
          .firstWhere((MapEntry<String, String> e) =>
              e.key.endsWith('shell/choreia_shell.dart'))
          .value;
      expect(
          shellSrc,
          contains(
              'ProfileView(accountPageBuilder: widget.accountPageBuilder)'),
          reason: 'Profil artık kabukta değilse rota sayımı bayatladı');
      final File looseWalk = File('test/reachability_test.dart');
      final String looseWalkSrc = looseWalk.readAsStringSync();
      expect(looseWalkSrc, contains('profileTabKey'),
          reason: 'Profil gevşek yürüyüşte ziyaret edilmiyor');
      // These classes remain in source for later feature work but are not
      // mounted or advertised as empty destinations in the store shell.
      const Set<String> deferredUnpublished = <String>{
        'TodayView',
        'PracticeLabView',
      };
      for (final String screen in deferredUnpublished) {
        expect(shellSrc, isNot(contains('$screen(')),
            reason: '$screen boşken kullanıcı gezinmesine geri sızdı');
      }
      // The new offline course has a separate real-file persistence walk. This
      // legacy walk intentionally uses device storage/bundle defaults and does
      // not open that teaching path. Keep its independent evidence discoverable.
      const Map<String, String> separatelyWalked = {
        'SalsaCoursePage': 'test/salsa_course_page_test.dart',
        'SalsaLessonPage': 'test/salsa_course_page_test.dart',
      };
      for (final entry in separatelyWalked.entries) {
        final source = File(entry.value).readAsStringSync();
        expect(source, contains(entry.key));
        expect(source, contains('salsa.open'));
        expect(source, contains('salsa.saved'));
      }
      final Set<String> allExcluded = unreachableInWalk.keys
          .toSet()
          .union(unreachableByDesign)
          .union(separatelyWalked.keys.toSet())
          .union(deferredUnpublished);

      // (c) SEBEP DE ÖLÇÜLÜR — sözleşme: *yanlış bir sebep, sebepsizlikten
      // daha kötüdür: denetimi DOĞRULANMIŞ gösterir.* (Ostinato'nun sebebi
      // ölçülünce yanlış çıktı.) Bu iki gerekçe artık HER KOŞUMDA kaynaktan
      // yeniden türetiliyor; iddia olarak durmuyorlar.
      final String livePage = lib.entries
          .firstWhere((MapEntry<String, String> e) =>
              e.key.endsWith('live_lesson_page.dart'))
          .value;
      // ① Sayfa hâlâ CİHAZ varsayılanına düşüyor mu — gerekçenin ilk yarısı.
      expect(livePage.contains('widget.env.bundle ?? rootBundle'), isTrue,
          reason: 'gerekçe BAYAT: `LiveLessonPage` artık `rootBundle`a '
              'düşmüyor olabilir — o hâlde bu yürüyüşte çizilmeme sebebi '
              'değişti');
      expect(livePage.contains('materialisePoseModel()'), isTrue,
          reason: 'gerekçe BAYAT: poz modeli artık yüklenmiyor olabilir');
      expect(livePage.contains('widget.env.source?.call() ?? _CameraSource()'),
          isTrue,
          reason:
              'gerekçe BAYAT: poz kaynağı artık kameraya düşmüyor olabilir');

      // ② Ve gerekçenin İKİNCİ yarısı: "başka bir yerde yürünüyor" iddiası.
      //
      // 🔴 Bu satır olmadan dışlama yarım bir doğrudur. Bir ekranı *"burada
      // değil, şurada yürünüyor"* diye dışlamak, ŞURASI silindiği gün sessizce
      // *"hiçbir yerde yürünmüyor"*a döner — ve gerekçe hâlâ ikna edici
      // görünür. Dışlamanın dayandığı yürüyüşün VARLIĞI da ölçülür.
      final File walk = File('test/first_walk_test.dart');
      expect(walk.existsSync(), isTrue,
          reason: 'gerekçe BAYAT: dışlamanın dayandığı yürüyüş dosyası YOK');
      final String walkSrc = walk.readAsStringSync();
      for (final String screen in unreachableInWalk.keys) {
        expect(walkSrc, contains(screen),
            reason: 'gerekçe BAYAT: `$screen` burada dışlanıyor ve '
                '`first_walk_test.dart` ona hiç değinmiyor — dışlama '
                'dayanaksız kaldı');
      }
      expect(walkSrc, contains('LiveEnvironment('),
          reason: 'gerekçe BAYAT: o yürüyüş artık ortamı enjekte etmiyor, '
              'yani buradaki "cihaz varsayılanı" ayrımı anlamsızlaştı');
      final Iterable<String> liveViewUsers = lib.entries
          .where((MapEntry<String, String> e) =>
              RegExp(r'\bLiveView\(').hasMatch(e.value) &&
              !e.key.endsWith('live_view.dart'))
          .map((MapEntry<String, String> e) => e.key.split('/').last);
      expect(liveViewUsers, <String>['live_lesson_page.dart'],
          reason: 'gerekçe BAYAT: `LiveView` artık yalnız `LiveLessonPage`in '
              'gövdesi değil — başka bir yerden de kuruluyor: $liveViewUsers');
      // Ve YAPI kanalı bunu bağımsız olarak doğruluyor: `LiveView` ADDA var,
      // YAPIDA yok — hiçbir montaj noktasında geçmiyor.
      expect(byName.difference(byStructure),
          <String>{'LiveView', 'TodayView', 'PracticeLabView'},
          reason: 'ad-yalnız ekran kümesi değişti: '
              '${byName.difference(byStructure)}. ADDA ekran görünüp YAPIDA '
              'monte edilmeyen her sınıf, varılamayan kovasında SEBEBİYLE '
              'yer almalı.');

      final Set<String> unreached = candidates.difference(reached);
      expect(unreached, allExcluded,
          reason: 'BÖLME BOZULDU. Varılamayan küme değişti: $unreached. '
              'Yeni bir ekran yürüyüşe girmediyse SEBEBİNİ yaz; girdiyse '
              'listeden çıkar. Eşitlik: aday = varılan ⊎ varılamayan.');
      expect(reached.union(allExcluded), candidates,
          reason: 'aday kümesi ile toplam ayrıştı');
    });

    testWidgets('GEVŞEK okuma: rota + itilmeden geçilen yerler',
        (WidgetTester tester) async {
      final _RouteSpy spy = _RouteSpy();
      await tester.pumpWidget(app(spy));
      await _settle(tester);
      await passIntro(tester);

      // Only the three working destinations are in the store shell.
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.byType(TodayView), findsNothing);
      expect(find.byType(PracticeLabView), findsNothing);
      await tester.tap(find.byKey(ChoreiaShell.progressTabKey));
      await _settle(tester);
      expect(find.byType(ProgressView), findsOneWidget,
          reason: 'ilerleme sekmesi bir yere gitmiyor');

      await tester.tap(find.byKey(ChoreiaShell.profileTabKey));
      await _settle(tester);
      expect(find.byType(ProfileView), findsOneWidget,
          reason: 'Profil sekmesi bir yere gitmiyor');

      await tester.tap(find.byKey(ChoreiaShell.libraryTabKey));
      await _settle(tester);
      expect(find.byType(LibraryView), findsOneWidget,
          reason: 'kütüphane sekmesine geri dönülemiyor');

      final Finder card =
          find.byKey(LibraryView.tileKey('hip_hop_foundations'));
      await tester.ensureVisible(card);
      await _settle(tester);
      await tester.tap(card);
      await _settle(tester);
      expect(find.byType(StyleDetailView), findsOneWidget);

      final Finder startButton = find.widgetWithText(FilledButton, 'Start');
      await _scrollTo(tester, startButton);
      await tester.ensureVisible(startButton);
      await _settle(tester);
      await tester.tap(startButton);
      await _settle(tester);

      // Intro, library, progress and profile are places without a push;
      // style detail and live lesson are pushed routes.
      expect(spy.pushed.length + 4, 6,
          reason: 'GEVŞEK sayı beklenenden farklı. Rotalar: ${spy.pushed}');
    });

    test('diskte olan ≠ uygulamada olan — C-143 isimle çivili', () {
      final Set<String> onDisk = Directory('content/references')
          .listSync()
          .whereType<File>()
          .map((File f) => f.uri.pathSegments.last)
          .where((String n) => n.endsWith('.json') && !n.startsWith('.'))
          .map((String n) => n.replaceAll('.json', ''))
          .where((String n) => n != 'decisions')
          .toSet();

      // The gap is a DECISION, not an accident: `hh_bounce` carries
      // `mirrorConfident: false`, so shipping it may be deliberate. What must
      // not happen is the gap changing without anyone noticing — a reference
      // silently added to the app, or a shipped one silently dropped.
      // 2026-08-07'de `hh_bounce` beyan edildi; artık diskteki her referans
      // uygulamaya giriyor ve kapı bunu İKİ YÖNDE tutuyor — beyansız yeni bir
      // dosya da, diskte olmayan bir beyan da kırmızı.
      //
      // ⚠️ AMA C-143 BİTMİŞ DEĞİL, ve bu satır bir zamanlar öyle diyordu
      // (2026-08-13'te düzeltildi). Kaydın KENDİ durum sütunu:
      // "AÇIK — koordinatör kararı bekliyor". Beyan **mekaniği** kapandı;
      // kaydın sorduğu ÜRÜN HÜKMÜ (`mirrorConfident: false` taşıyan bir
      // referans sevk edilmeli mi) hâlâ koordinatörde.
      //
      // ⇒ ***BİR KUSURUN MEKANİĞİNİ DÜZELTMEK, O KUSURUN SORDUĞU SORUYU
      // CEVAPLAMAZ*** — ve iki şeyi aynı satırda kapalı ilan etmek, cevabı
      // beklenen soruyu görünmez yapar. Bunu `closure_authority` kapısı
      // yakaladı: bu yorumun iddiası bir DEFTER kaydına sızmıştı ve kapı
      // *"kaydın kendi sütunu AÇIK diyor"* diye kırmızı verdi (C-272 ③).
      expect(onDisk.difference(declared), isEmpty,
          reason: 'diskte olup uygulamaya girmeyen referans var — kullanıcı '
              'onu açamaz ve rozet onu vaat ediyor olabilir (C-185)');
      expect(declared.difference(onDisk), isEmpty,
          reason: 'pubspec diskte olmayan bir referansı bildiriyor — '
              'yüklemede gürültüsüzce patlar');
    });

    test(
        'ÜÇÜNCÜ KÜME: pakete giren ama HİÇBİR DERSİN yükleyemeyeceği '
        'referanslar — SAYILIR, yasaklanmaz', () {
      // C-143'ün kapısı iki yönü tutuyor: diskte olan bildirilmiş mi,
      // bildirilen diskte var mı. İkisi de **dosya** hakkında. Kimsenin
      // sormadığı üçüncü soru şu: *bildirilen bir referansı yükleyebilecek
      // bir DERS var mı?*
      //
      // `LiveLessonPage` referansı yalnız `stepId` üzerinden açar; hiçbir
      // dersin `stepId`'si olmayan bir referans, cihaza iner ve orada
      // **hiçbir kod yolunun okuyamayacağı** bayt olarak durur.
      //
      // ⛔ BU BİR YASAK DEĞİL, ve olmaması kasıtlı: C-143 tam da bu
      // dosyaları BİLDİREREK kapandı ("diskte olup uygulamaya girmeyen
      // referans var" kırmızısını temizleyerek). Kapıyı ters çevirmek o
      // hükmü çiğnerdi. Ölçülen şey **küme**: yenisi sessizce eklenemez,
      // ve eklendiği gün bedeli baytıyla görünür.
      final Set<String> namedByALesson = <String>{
        for (final StyleCard c in library.cards)
          for (final LessonInfo l in c.lessons)
            if (l.stepId != null) l.stepId!,
      };
      // POZİTİF KONTROL: türetim boş dönerse aşağıdaki fark HER ŞEYİ
      // "ulaşılamaz" ilan eder ve test kendi vakumunda yeşil görünür.
      expect(namedByALesson, isNotEmpty,
          reason: 'hiçbir ders bir adım adlandırmıyor — türetim bozuk, '
              'ölçüm vakumda');

      final Set<String> shippedUnloadable = declared.difference(namedByALesson);
      final int bytes = shippedUnloadable.fold<int>(
          0,
          (int a, String s) =>
              a + File('content/references/$s.json').lengthSync());

      expect(shippedUnloadable, <String>{'hh_roger_rabbit', 'hh_running_man'},
          reason: 'pakete giren ama hiçbir dersin yükleyemeyeceği referans '
              'kümesi DEĞİŞTİ: $shippedUnloadable ($bytes bayt). Yeni bir '
              'referans bildirildiyse ya onu adlandıran ders eksik, ya da '
              'bildirim erken. Küme küçüldüyse bir ders bağlandı — bu iyi '
              'haber, sayıyı güncelle.');

      // Bedeli ADIYLA: bir sayı, penceresi yazılmadan başka bir sayıyla
      // karşılaştırılamaz — bu yüzden bayt burada, ölçüldüğü yerde duruyor.
      expect(bytes, greaterThan(150 * 1024),
          reason: 'iki referansın toplam boyutu beklenenden küçük — '
              '$bytes bayt. Bu satır bedelin GÖRÜNÜR kalması için var; '
              'küçüldüyse sebebini yaz.');

      // Ve ikisinin de dersi NİYE yok, ölçülerek: `hh_l1_running_man`
      // yazılmış bir DERS ama `step` alanı yok VE adım belgesi de yok, yani
      // eksik olan kablolama değil İÇERİK (A4'ün A′ sınıfı, hasat turu).
      // `hh_roger_rabbit` ise hiçbir derse ait değil — sözlükte bir ad.
      expect(
          File('content/styles/hip_hop_foundations/steps/'
                  'hh_running_man.json')
              .existsSync(),
          isFalse,
          reason: 'adım belgesi YAZILMIŞ — o hâlde eksik olan yalnız '
              '`step` kablolaması ve bu HATTIN kalemi (A4 sınıf B); '
              'gerekçe bayatladı');
    });

    test(
        'demoOpen rozeti CİHAZDA fazla-satıyor — kafesin kaynağı disk, '
        'kullanıcınınki paket', () {
      // `demoOpen` means, in the registry's own words, "the user can OPEN a
      // lesson; none of them score". `validate_content` enforces that lattice
      // in both directions — against the style pack ON DISK.
      //
      // A device does not have the disk. It has whatever `pubspec.yaml`
      // shipped. `hip_hop_foundations` is registered `demoOpen`, its demo-only
      // lesson is fully written, and its reference is NOT declared — so on a
      // phone that lesson cannot open and the badge promises something the
      // build does not contain.
      //
      // This is C-101's shape one layer down: a proxy (disk) standing in for
      // the thing that matters (the bundle). The lattice is not wrong, its
      // SOURCE is — and the gap only shows up if you ask the question from
      // where the user reads it.
      final List<String> openableOnDevice = <String>[
        for (final StyleCard c in library.cards)
          for (final LessonOffer o in c.offers(library.runnableSteps))
            if (o.canStart) c.entry.id,
      ];
      final List<String> claimDemoOpen = <String>[
        for (final LibraryEntry e in library.entries)
          if (e.contentStatus == 'demoOpen') e.id,
      ];

      expect(claimDemoOpen, <String>['hip_hop_foundations'],
          reason: 'demoOpen iddia eden stil kümesi değişti: $claimDemoOpen');
      // KAPANDI 2026-08-07 12:0x. The badge is now true where the user reads
      // it. Kept as a gate rather than deleted: the failure it caught cannot
      // be caught by `validate_content`, which reads the DISK, and this is
      // the only place the question is asked from the bundle's side.
      expect(
          claimDemoOpen.toSet().difference(openableOnDevice.toSet()), isEmpty,
          reason: 'demoOpen iddia eden ama CİHAZDA hiçbir ders açamayan stil '
              'var — rozet build\'in içermediği bir şeyi vaat ediyor. '
              'Kafes diski okur, kullanıcının elinde paket vardır (C-185)');
    });

    test('açılan kapının artık ZEMİNİ VAR — ama koştuğu ölçülmedi (C-186)', () {
      // For six hours this gate asserted the opposite: the lesson was
      // reachable and could not run, because `LiveLessonPage` asked the
      // camera for `assets/pose_landmarker_full.task` — a file that was not
      // declared, not in the repository, not shipped by the plugin, and not
      // even the right SHAPE (the plugin's contract wants an absolute
      // filesystem path, not a bundle key).
      //
      // Three sibling lines had solved this months ago. The fix was their
      // recipe, not an invention: a pinned model fetched and SHA-verified by
      // a script, declared as an asset, and copied out of the bundle to a
      // real file at launch.
      //
      // WHAT THIS STILL DOES NOT CLAIM: that a dancer can dance. The camera
      // has never been opened on a device from this repository (C-146, no
      // touch path), so "the model is present and correctly addressed" is the
      // whole of the assertion. Reaching, running and WORKING are three
      // claims, and this file has now measured two of them.
      expect(File(PoseModelPin.assetPath).existsSync(), isTrue,
          reason: 'model yerinde değil — `tool/fetch_pose_model.sh` koş');
      expect(
          File('pubspec.yaml').readAsStringSync(), contains('assets/models/'),
          reason: 'model beyan edilmemiş, yani cihaza girmez');

      final String live =
          File('lib/app/live/live_lesson_page.dart').readAsStringSync();
      expect(live, contains('materialisePoseModel()'),
          reason: 'canlı sayfa modeli GERÇEK bir dosya yoluna çevirmeden '
              'kameraya veriyor — eklenti asset anahtarını açamaz');
      expect(live, isNot(contains("'assets/pose_landmarker")),
          reason: 'eski gömülü asset yolu geri geldi');
    });

    test('rota adları ölçülebilir kalmalı — isimsiz rota sayılamaz', () {
      // The measurement above reads `RouteSettings.name`. If a future push
      // omits it the spy still counts the route, but nobody can tell WHICH
      // screen appeared in a failure message. Cheap to keep, silently lost
      // otherwise.
      expect(library.cards, isNotEmpty);
    });
  });
}

/// Bounded scroll. `scrollUntilVisible` never returns for the same reason
/// `pumpAndSettle` does not — it settles between steps and this app always has
/// a frame pending. Drags a fixed number of times and stops, so a genuinely
/// unreachable target fails an assertion instead of hanging.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  for (int i = 0; i < 25 && target.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await _settle(tester);
  }
}

/// `pumpAndSettle` never returns here: `ChoreiaBackdrop` runs a `..repeat()`
/// animation for the life of the app, so the tester waits for a frame queue
/// that is never empty. Bounded pumps instead — 500ms clears the one screen
/// transition this app has (400ms, `choreia_page_route.dart`) with margin.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class _RouteSpy extends NavigatorObserver {
  final List<String> pushed = <String>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) {
    // The first push IS the home route; the strict count adds it back as the
    // floor rather than counting it here, so `pushed` means "went somewhere".
    if (previous != null) pushed.add(route.settings.name ?? '(isimsiz)');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previous) =>
      pushed.remove(route.settings.name ?? '(isimsiz)');
}
