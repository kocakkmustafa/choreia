import 'dart:io';

import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
/// The reference files `pubspec.yaml` actually ships, parsed from the manifest
/// rather than from the directory listing.
///
/// `content/references/` is declared FILE BY FILE (the directory also holds
/// build-time bookkeeping that must not ship), so "on disk" and "in the app"
/// are different sets — and only the second one exists on a device.
Set<String> declaredReferences() => File('pubspec.yaml')
    .readAsLinesSync()
    .map((String l) => l.trim())
    .where((String l) => l.startsWith('- content/references/'))
    .map((String l) => l.substring('- content/references/'.length)
        .replaceAll('.json', ''))
    .toSet();

/// A bundle that fails for an undeclared reference the way a real device does.
///
/// WHY THIS EXISTS: `DiskBundle` reads the filesystem, so it happily returns a
/// file `pubspec.yaml` never ships. Measuring reachability through it produced
/// a Start button the device would never paint — and the walk then crashed in
/// `LiveLessonPage`, which loads from `rootBundle` and got the real answer.
/// A fake must imitate the FAILURE MODE, not just the signature (C-115); this
/// one was imitating the wrong machine entirely.
class DeviceBundle extends DiskBundle {
  DeviceBundle(this.declared);

  final Set<String> declared;

  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('content/references/')) {
      final String step =
          key.substring('content/references/'.length).replaceAll('.json', '');
      if (!declared.contains(step)) {
        throw FlutterError('asset not declared in pubspec.yaml: $key');
      }
    }
    return super.load(key);
  }
}

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

    testWidgets('GEVŞEK okuma: rota + itilmeden geçilen yerler',
        (WidgetTester tester) async {
      final _RouteSpy spy = _RouteSpy();
      await tester.pumpWidget(app(spy));
      await _settle(tester);
      await passIntro(tester);

      // The shell's two destinations. Switched by `IndexedStack`, so the route
      // never changes — invisible to the strict count, and yet a user plainly
      // experiences "going to my progress".
      await tester.tap(find.byKey(ChoreiaShell.progressTabKey));
      await _settle(tester);
      expect(find.byType(ProgressView), findsOneWidget,
          reason: 'ilerleme sekmesi bir yere gitmiyor');

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

      // GEVŞEK = 5: tanıtım · kütüphane · ilerleme · stil sayfası · canlı ders.
      // Üçü rota (spy), ikisi (tanıtım, ilerleme sekmesi) itilmeden geçilen
      // yer — ve bir kullanıcı ikisini de "bir yere gittim" diye yaşıyor.
      expect(spy.pushed.length + 3, 5,
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
      // C-143 kapandı 2026-08-07: hh_bounce beyan edildi. Artık diskteki
      // her referans uygulamaya giriyor, ve kapı bunu İKİ YÖNDE tutuyor —
      // beyansız yeni bir dosya da, diskte olmayan bir beyan da kırmızı.
      expect(onDisk.difference(declared), isEmpty,
          reason: 'diskte olup uygulamaya girmeyen referans var — kullanıcı '
              'onu açamaz ve rozet onu vaat ediyor olabilir (C-185)');
      expect(declared.difference(onDisk), isEmpty,
          reason: 'pubspec diskte olmayan bir referansı bildiriyor — '
              'yüklemede gürültüsüzce patlar');
    });

    test('demoOpen rozeti CİHAZDA fazla-satıyor — kafesin kaynağı disk, '
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
      expect(claimDemoOpen.toSet().difference(openableOnDevice.toSet()),
          isEmpty,
          reason: 'demoOpen iddia eden ama CİHAZDA hiçbir ders açamayan stil '
              'var — rozet build\'in içermediği bir şeyi vaat ediyor. '
              'Kafes diski okur, kullanıcının elinde paket vardır (C-185)');
    });

    test('AÇILAN KAPI BOŞLUĞA AÇILIYOR — poz modeli hiçbir yerde yok (C-186)',
        () {
      // The lesson is now reachable. It cannot RUN.
      //
      // `LiveLessonPage` starts the camera with
      // `modelPath: 'assets/pose_landmarker_full.task'`. That file:
      //   * is not declared in `pubspec.yaml`
      //   * does not exist in the repository
      //   * is not shipped by `motion_camera` (the plugin deliberately
      //     bundles no model — "apps pin their own and ship it as an asset")
      // and the argument is not even the right SHAPE: the plugin's contract
      // says `modelPath` is an ABSOLUTE FILESYSTEM PATH, not a bundle key.
      // `path_provider` is a declared dependency and is never imported in
      // `lib/`, which is the shape of a provisioning step that was planned
      // and never written.
      //
      // Why this is pinned here and not merely noted: reaching a screen and
      // the screen WORKING are different claims, and the reachability
      // measurement above only makes the first. Without this the walk would
      // read as "the core loop is live" — the exact overclaim this file was
      // built to prevent, one layer further in.
      const String declaredModel = 'assets/pose_landmarker_full.task';
      final String source = File('lib/app/live/live_lesson_page.dart')
          .readAsStringSync();
      expect(source, contains(declaredModel),
          reason: 'model yolu değişti — bu kapının konusu artık başka bir '
              'dosya, metni güncelle');

      final bool onDisk = File(declaredModel).existsSync();
      final bool declaredInPubspec =
          File('pubspec.yaml').readAsStringSync().contains(declaredModel);

      // Pinned as the CONTRADICTION, like C-185: it flips to red when fixed
      // and says so, rather than passing quietly forever.
      expect(onDisk || declaredInPubspec, isFalse,
          reason: 'poz modeli artık geliyor — bu İYİ HABER. Ders ilk kez '
              'gerçekten çalışabilir; bu kapıyı ve KATI ölçümün "ulaşmak ≠ '
              'çalışmak" notunu güncelle.');
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
