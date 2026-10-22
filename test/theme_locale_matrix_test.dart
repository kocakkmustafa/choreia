import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:choreia/app/course/hip_hop_course_page.dart';
import 'package:choreia/app/course/latin_fusion_course_page.dart';
import 'package:choreia/app/course/line_dance_course_page.dart';
import 'package:choreia/app/course/line_dance_direction_diagram.dart';
import 'package:choreia/app/course/practice_comparison_page.dart';
import 'package:choreia/app/course/salsa_course_page.dart';
import 'package:choreia/app/course/short_form_course_page.dart';
import 'package:choreia/app/course/support_hold_demo.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/live/live_lesson_page.dart';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:choreia/app/localization/choreia_messages.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/progress_summary.dart';
import 'package:choreia/app/progress_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:choreia/app/study_review.dart';
import 'package:choreia/app/study_review_content.dart';
import 'package:choreia/app/theme/theme_picker.dart';
import 'package:choreia/app/theme/theme_preference.dart';
import 'package:choreia/main.dart';
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart' show SessionRecord;

import 'support/round_trip_store.dart';
import 'support/test_catalog.dart';
import 'theme_preference_test.dart' show MemoryAppearanceStore;

/// Sayım: 1 kapsam kontrolü + 56 matris + 6 hata + 6 rota = 69 test.
/// Matris: 14 dil × açık/koyu × 1x/2x, her zaman 320×760 mantıksal piksel.
/// Her matris aynı altı gerçek yüzeyi ziyaret eder: katalog, boş ilerleme,
/// profil, Line Dance detayı, yazılı okuyucu/yön haritası ve geçici A/B formu.
/// Formu yeniden açmak yedinci bağımsız yüzey diye sayılmaz.
///
/// Ek rota taraması EN/AR/HI × iki tema, 2x: tüm katalog detayları, beş ana
/// yazılı kurs + ayrı Hip-Hop girişi, beş A/B formu, recall hub/tüm recall
/// sayfaları, bir gerçek Salsa dersi, sembolik destek demosu ve lisans sayfası.
/// İçerik varyantlarının tamamı (ör. 48 Salsa dersi), her lisans paketinin
/// alt sayfası, Core hesap rotaları ve kapalı kamera/satış rotaları bu sayımda
/// yoktur. Bu bir tüm-ürün/native/anadil/eğitmen kabulü değildir.
///
/// DiskBundle gerçek içeriği okur; cihazın asset paketlemesini kanıtlamaz.
/// Exact kaynak çalıştırma makbuzu ayrı raporlanır; tanımlar kabul sonucu değildir.
const _viewport = Size(320, 760);
const _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];
const _scales = <double>[1, 2];
const _sweepLocales = <Locale>[Locale('en'), Locale('ar'), Locale('hi')];
const _writtenTypes = <String, Type>{
  'hip_hop_foundations': HipHopCoursePage,
  'salsa_shines': SalsaCoursePage,
  'line_dance': LineDanceCoursePage,
  'latin_fusion_fitness': LatinFusionCoursePage,
  'tiktok_format': ShortFormCoursePage,
};

Finder get _verticalScroll => find.byElementPredicate((element) {
      final widget = element.widget;
      return widget is Scrollable &&
          widget.axisDirection == AxisDirection.down &&
          ModalRoute.of(element)?.isCurrent == true;
    });

Finder _note(int index) => find.byKey(Key('practiceComparison.note.$index'));

// Diagnostic only: real elapsed time and bounded output, no weaker assertions.
bool _routeTracing = false;
Stopwatch? _routeClock;
int _routeTraceLines = 0;
void _routeTrace(String stage) {
  if (!_routeTracing || _routeTraceLines >= 300) return;
  _routeTraceLines++;
  debugPrintSynchronously(
      '[CHOREIA-ROUTE ${_routeClock!.elapsedMilliseconds}ms] $stage');
}

void _clean(WidgetTester tester, String checkpoint) {
  expect(tester.takeException(), isNull, reason: checkpoint);
  expect(find.byType(LiveLessonPage), findsNothing, reason: checkpoint);
  expect(find.byKey(const Key('locale.translationUnavailable')), findsNothing,
      reason: '$checkpoint: gerçek bundle sessiz EN fallback göstermemeli');
}

Future<void> _advance(WidgetTester tester) async {
  // Bounded: dekorun sonlanmasını bekleyen pumpAndSettle kullanılmaz.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

Future<void> _waitFor(WidgetTester tester, Finder finder,
    {Locale? locale}) async {
  for (var frame = 0; frame < 120; frame++) {
    if (finder.evaluate().isNotEmpty &&
        (locale == null ||
            ChoreiaMessages.of(tester.element(finder.first)).localeTag ==
                ChoreiaLocaleController.tag(locale))) {
      await _advance(tester);
      _clean(tester, 'hazır: $finder');
      return;
    }
    // Yalnız yerel Salsa dosya IO'sunun gerçek event loop'una fırsat verir.
    // Ağ, SDK, platform izin veya production servis çağrısı yoktur.
    final traceFrame = frame % 30 == 0 || frame == 119;
    if (traceFrame) _routeTrace('wait.$frame yield.before $finder');
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    if (traceFrame) _routeTrace('wait.$frame yield.after $finder');
    await tester.pump(const Duration(milliseconds: 50));
    if (traceFrame) _routeTrace('wait.$frame pump.after $finder');
    _clean(tester, 'bekleme $frame: $finder');
  }
  fail('120 sonlu pompa içinde yüzey hazır olmadı: $finder');
}

Future<void> _reach(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    expect(_verticalScroll, findsWidgets, reason: '$target için scroll yok');
    tester.state<ScrollableState>(_verticalScroll.first).position.jumpTo(0);
    await tester.pump();
    for (var step = 0; step < 240 && target.evaluate().isEmpty; step++) {
      final position =
          tester.state<ScrollableState>(_verticalScroll.first).position;
      if (position.pixels >= position.maxScrollExtent) break;
      position.jumpTo((position.pixels + 360)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble());
      await tester.pump();
      _clean(tester, 'arama $step: $target');
    }
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .35);
  await _advance(tester);
  _clean(tester, 'erişim: $target');
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reach(tester, target);
  expect(target.hitTestable(), findsOneWidget,
      reason: 'Görünür ama basılamayan hedef: $target');
  await tester.tap(target);
  await _advance(tester);
  _clean(tester, 'dokunma: $target');
}

Future<void> _back(WidgetTester tester) async {
  final back = find.byType(BackButton).last;
  expect(back.hitTestable(), findsOneWidget);
  await tester.tap(back);
  await _advance(tester);
  _clean(tester, 'geri');
}

Future<void> _scan(WidgetTester tester, String name) async {
  if (_verticalScroll.evaluate().isEmpty) {
    _clean(tester, name);
    return;
  }
  var position = tester.state<ScrollableState>(_verticalScroll.first).position;
  position.jumpTo(0);
  await tester.pump();
  for (var step = 0; step < 240; step++) {
    _clean(tester, '$name, kaydırma $step');
    position = tester.state<ScrollableState>(_verticalScroll.first).position;
    if (position.pixels >= position.maxScrollExtent - .5) return;
    position.jumpTo((position.pixels + 360)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble());
    await tester.pump();
  }
  fail('$name: 240 adımda sona erişilemedi; kapsam sessizce daraltılmadı');
}

void _surface(WidgetTester tester, Finder finder, _Host host,
    {ThemeMode? mode, Locale? locale}) {
  expect(finder, findsOneWidget);
  final context = tester.element(finder);
  final selected = locale ?? host.locale;
  final tag = ChoreiaLocaleController.tag(selected);
  expect(ChoreiaMessages.of(context).localeTag, tag);
  expect(ChoreiaLocaleController.tag(Localizations.localeOf(context)), tag);
  expect(Directionality.of(context),
      tag == 'ar' ? TextDirection.rtl : TextDirection.ltr);
  expect(
      Theme.of(context).brightness,
      (mode ?? host.mode) == ThemeMode.light
          ? Brightness.light
          : Brightness.dark);
  expect(MediaQuery.textScalerOf(context).scale(10), host.scale * 10);
  expect(MediaQuery.disableAnimationsOf(context), isTrue);
  _clean(tester, '$tag/${(mode ?? host.mode).name}/${host.scale}: $finder');
}

void _scriptRun(WidgetTester tester, Finder scope, Locale locale) {
  final script = switch (locale.languageCode) {
    'ar' => RegExp(r'[\u0600-\u06FF]'),
    'hi' => RegExp(r'[\u0900-\u097F]'),
    'ja' => RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]'),
    'ko' => RegExp(r'[\uAC00-\uD7AF]'),
    'zh' => RegExp(r'[\u4E00-\u9FFF]'),
    _ => RegExp(r'[A-Za-z\u00C0-\u024F]'),
  };
  final rich = find.descendant(
      of: scope,
      matching: find.byWidgetPredicate((widget) =>
          widget is RichText && script.hasMatch(widget.text.toPlainText())));
  expect(rich, findsWidgets,
      reason: '${locale.toLanguageTag()} gerçek yüzeyde hedef yazı yok');
  final paragraph = tester.renderObject<RenderParagraph>(rich.first);
  final value = paragraph.text.toPlainText();
  // A partial matra/conjunct glyph selection can legitimately have no boxes.
  // Select the complete word containing the target script, including joiners.
  final span = RegExp(r'[\p{L}\p{M}\p{N}\u200C\u200D]+', unicode: true)
      .allMatches(value)
      .firstWhere((match) => script.hasMatch(match.group(0)!));
  final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: span.start, extentOffset: span.end));
  expect(boxes, isNotEmpty);
  expect(
      boxes.any((box) => box.right > box.left && box.bottom > box.top), isTrue);
  // Metin ve layout kutusu gözlenir; tofu/glyph estetiği veya anadil kabulü değil.
}

Future<void> _openStyle(WidgetTester tester, String id) async {
  final tile = find.byKey(LibraryView.tileKey(id));
  await _reach(tester, tile);
  // 2x'te kart viewport'tan uzun olabilir. Ortası yerine gerçek başlık tıklanır.
  await _tap(
      tester, find.descendant(of: tile, matching: find.byType(Text)).first);
  await _waitFor(tester, find.byType(StyleDetailView));
  expect(
      tester
          .widget<StyleDetailView>(find.byType(StyleDetailView))
          .card
          .entry
          .id,
      id);
}

class _CourseFaultBundle extends DiskBundle {
  bool failCourse = true;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (failCourse && key == 'content/line_dance_beginner_course.json') {
      return Future<String>.error(StateError('Yerel kurs okuma arızası'));
    }
    return super.loadString(key, cache: cache);
  }
}

class _UnreadableHistory extends RoundTripStore {
  @override
  Future<List<SessionRecord>> recent({int? limit}) async =>
      throw StateError('Yerel geçmiş okuma arızası');
}

class _Host {
  _Host(this.locale, this.mode, this.scale, this.library,
      {required this.locales,
      required this.themes,
      required this.store,
      required this.bundle,
      required this.introSeen,
      required this.failCatalog,
      this.directory}) {
    env = LiveEnvironment(
      bundle: bundle,
      storeOwners: owners,
      historyDirectoryOverride: directory,
      storeOpener: () async => store,
      source: () {
        cameraCalls++;
        throw StateError('Bu matris kamera açamaz');
      },
      cameraPermissionRequest: () async {
        cameraCalls++;
        throw StateError('Bu matris izin isteyemez');
      },
    );
  }

  final Locale locale;
  final ThemeMode mode;
  final double scale;
  final LibraryCatalog library;
  final ChoreiaLocaleController locales;
  final ChoreiaThemeController themes;
  final RoundTripStore store;
  final DiskBundle bundle;
  final bool introSeen;
  bool failCatalog;
  final Directory? directory;
  final owners = AppStoreOwnerRegistry();
  late final LiveEnvironment env;
  var cameraCalls = 0;

  Widget app(WidgetTester tester) => MediaQuery.fromView(
        view: tester.view,
        child: Builder(
            builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true),
                  child: ChoreiaApp(
                    localeController: locales,
                    themeController: themes,
                    localeBundle: bundle,
                    shellBuilder: (_, __) => ChoreiaShell(
                      env: env,
                      // Üretim kapısı false kalır; Core/Auth test rotası verilmez.
                      cameraSessionsAvailable: false,
                      flagOverride: MemoryFirstRunFlag(seen: introSeen),
                      bundleOverride: () async {
                        if (failCatalog) {
                          throw StateError('Yerel katalog okuma arızası');
                        }
                        return library;
                      },
                    ),
                  ),
                )),
      );
}

Future<_Host> _mount(WidgetTester tester, LibraryCatalog library, Locale locale,
    ThemeMode mode, double scale,
    {bool failThemeSave = false,
    bool failPreferencesRead = false,
    bool failHistory = false,
    bool failCatalog = false,
    bool introSeen = true,
    bool localCourseFiles = false,
    DiskBundle? bundle}) async {
  // The registered teardown is not automatically run in this test's fake zone.
  final fixtureZone = Zone.current;
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.platformBrightnessTestValue =
      mode == ThemeMode.light ? Brightness.light : Brightness.dark;
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final preferences = MemoryAppearanceStore()..failWrite = failThemeSave;
  final themes = ChoreiaThemeController.persisted(store: preferences);
  final locales = failPreferencesRead
      ? ChoreiaLocaleController.persisted(
          preferenceFile: () async => throw StateError('Tercih okunamadı'))
      : ChoreiaLocaleController.memory(locale);
  final host = _Host(locale, mode, scale, library,
      locales: locales,
      themes: themes,
      store: failHistory ? _UnreadableHistory() : RoundTripStore(),
      bundle: bundle ?? DiskBundle(),
      introSeen: introSeen,
      failCatalog: failCatalog,
      directory: localCourseFiles
          ? Directory.systemTemp.createTempSync('choreia-theme-matrix-')
          : null);
  addTearDown(() async {
    _routeTrace('teardown.begin');
    await tester.pumpWidget(const SizedBox.shrink());
    _routeTrace('teardown.unmounted');
    await tester.pump();
    _routeTrace('teardown.pumped; drain.before');
    var drained = false;
    Object? drainError;
    StackTrace? drainStack;
    // Owner operations were registered in the fake test zone. Observe their
    // real Future there while separately allowing real IO and fake callbacks.
    fixtureZone.run<void>(() {
      _routeTrace('teardown.drain.fixture.begin');
      unawaited(host.owners.retireOwner(null).then<void>((_) {
        drained = true;
      }, onError: (Object error, StackTrace stack) {
        drainError = error;
        drainStack = stack;
        drained = true;
      }));
    });
    for (var turn = 0; turn < 300 && !drained; turn++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 2)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(drained, isTrue,
        reason:
            'Owner drain must finish before deleting the fixture directory');
    final failure = drainError;
    if (failure != null) Error.throwWithStackTrace(failure, drainStack!);
    _routeTrace('teardown.drain.returned');
    host.directory?.deleteSync(recursive: true);
    _routeTrace('teardown.directory.deleted');
    locales.dispose();
    themes.dispose();
    expect(host.cameraCalls, 0);
    expect(host.store.lines, isEmpty,
        reason: 'Yazılı/UI gezintisi kamera oturumu üretmemeli');
    _routeTrace('teardown.end');
    _routeTracing = false;
  });
  if (failPreferencesRead) {
    preferences.contents = 'invalid preference';
    await themes.restore();
    await locales.restore();
    expect(themes.readFailed, isTrue);
    expect(locales.readFailed, isTrue);
  } else {
    await themes.select(mode);
    expect(themes.saveFailed, failThemeSave);
  }
  await tester.pumpWidget(host.app(tester));
  await _advance(tester);
  return host;
}

Future<void> _formRoundTrip(WidgetTester tester, _Host host) async {
  await _tap(tester, find.byKey(const Key('style.practiceComparison')));
  await _waitFor(tester, find.byType(PracticeComparisonPage));
  _surface(tester, find.byType(PracticeComparisonPage), host);
  final state = tester.state(find.byType(PracticeComparisonPage));
  await _reach(tester, _note(6));
  final text = 'draft ${host.locale.toLanguageTag()} — A/B uncertain';
  await tester.enterText(_note(6), text);
  final controller = tester.widget<TextField>(_note(6)).controller!;
  final editable =
      find.descendant(of: _note(6), matching: find.byType(EditableText));
  final focus = tester.widget<EditableText>(editable).focusNode;
  tester.view.viewInsets = const FakeViewPadding(bottom: 240);
  await tester.pump();
  await _reach(tester, _note(6));
  expect(tester.getRect(_note(6)).bottom, lessThanOrEqualTo(520.5));
  expect(focus.hasFocus, isTrue);
  final otherMode =
      host.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  await host.themes.select(otherMode);
  await _advance(tester);
  _surface(tester, find.byType(PracticeComparisonPage), host, mode: otherMode);
  expect(identical(state, tester.state(find.byType(PracticeComparisonPage))),
      isTrue);
  expect(identical(controller, tester.widget<TextField>(_note(6)).controller),
      isTrue);
  expect(controller.text, text);
  expect(focus.hasFocus, isTrue);
  // Aynı Navigator rotasında gerçek delegate yeniden yüklenir.
  final otherLocale = host.locale.languageCode == 'ar'
      ? const Locale('hi')
      : const Locale('ar');
  await host.locales.select(otherLocale);
  await _waitFor(tester, find.byType(PracticeComparisonPage),
      locale: otherLocale);
  _surface(tester, find.byType(PracticeComparisonPage), host,
      mode: otherMode, locale: otherLocale);
  expect(identical(state, tester.state(find.byType(PracticeComparisonPage))),
      isTrue);
  expect(controller.text, text);
  expect(focus.hasFocus, isTrue);
  await host.locales.select(host.locale);
  await host.themes.select(host.mode);
  await _waitFor(tester, find.byType(PracticeComparisonPage),
      locale: host.locale);
  tester.view.resetViewInsets();
  FocusManager.instance.primaryFocus?.unfocus();
  await _back(tester);
  await _tap(tester, find.byKey(const Key('style.practiceComparison')));
  await _reach(tester, _note(6));
  expect(tester.widget<TextField>(_note(6)).controller!.text, isEmpty,
      reason:
          'Tema/dil değişimi taslağı korur; sayfadan çıkış geçici notu siler');
  await _back(tester);
}

void main() {
  late LibraryCatalog library;
  setUpAll(() async => library = await testLibrary());

  test('matris on dört onaylı dili ve beş yazılı yolu gerçekten kapsar', () {
    expect(
        ChoreiaLocaleController.supported
            .map(ChoreiaLocaleController.tag)
            .toSet(),
        <String>{
          'tr',
          'en',
          'es-419',
          'pt-BR',
          'de',
          'fr',
          'ja',
          'ar',
          'it',
          'ko',
          'id',
          'pl',
          'hi',
          'zh-Hans'
        });
    expect(_writtenTypes.keys.toSet(), PracticeComparisonPage.supportedStyles);
  });

  // Written-course cards once printed the camera notice through a TR/EN-only
  // helper, leaking English into the other twelve catalogues.
  for (final locale in ChoreiaLocaleController.supported) {
    final tag = ChoreiaLocaleController.tag(locale);
    if (tag == 'en' || tag == 'tr') continue;
    testWidgets('yazılı kurs kartı kamera notu $tag', (tester) async {
      final english = LibraryStrings.sessionNotice(false);
      final localized =
          (jsonDecode(File('content/l10n/ui.$tag.json').readAsStringSync())
              as Map<String, dynamic>)[english] as String;
      expect(localized, isNot(english));
      await _mount(tester, library, locale, ThemeMode.light, 1);
      await _waitFor(tester, find.byType(LibraryView));
      final tile = find.byKey(LibraryView.tileKey('hip_hop_foundations'));
      await _reach(tester, tile);
      expect(find.descendant(of: tile, matching: find.text(localized)),
          findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text(english)),
          findsNothing);
    });
  }

  for (final locale in ChoreiaLocaleController.supported) {
    for (final mode in _modes) {
      for (final scale in _scales) {
        final tag = ChoreiaLocaleController.tag(locale);
        testWidgets('matris $tag ${mode.name} ${scale}x 320px', (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final host = await _mount(tester, library, locale, mode, scale,
                failThemeSave: true);
            await _waitFor(tester, find.byType(LibraryView));
            _surface(tester, find.byType(LibraryView), host);
            await _scan(tester, 'katalog $tag');
            await _tap(tester, find.byKey(ChoreiaShell.progressTabKey));
            await _waitFor(tester, find.byType(ProgressView));
            _surface(tester, find.byType(ProgressView), host);
            await _reach(tester, find.byKey(ProgressView.emptyReasonKey));
            expect(
                tester
                    .widget<ProgressView>(find.byType(ProgressView))
                    .summary
                    .integrity
                    .fidelity,
                HistoryFidelity.ok);
            await _scan(tester, 'boş ilerleme $tag');
            await _tap(tester, find.byKey(ChoreiaShell.profileTabKey));
            _surface(tester, find.byType(ProfileView), host);
            await _reach(tester, find.byType(ChoreiaThemePicker));
            _scriptRun(tester, find.byType(ChoreiaThemePicker), locale);
            final selected = find.byKey(Key('theme.choice.${mode.name}'));
            await _reach(tester, selected);
            expect(
                tester
                    .getSemantics(selected)
                    .getSemanticsData()
                    .flagsCollection
                    .isSelected,
                Tristate.isTrue);
            expect(tester.getSize(selected).height, greaterThanOrEqualTo(48));
            expect(host.themes.saveFailed, isTrue);
            expect(
                find.descendant(
                    of: find.byType(ChoreiaThemePicker),
                    matching: find.byWidgetPredicate((w) =>
                        w is Semantics && w.properties.liveRegion == true)),
                findsOneWidget);
            final language = find.byKey(const Key('profile.language'));
            expect(
                tester.widget<PopupMenuButton<String>>(language).initialValue,
                tag);
            await _tap(tester, language);
            expect(find.byWidgetPredicate((w) => w is PopupMenuItem<String>),
                findsNWidgets(15));
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await _advance(tester);
            await _scan(tester, 'profil ve tercih hata mesajı $tag');
            await _tap(tester, find.byKey(ChoreiaShell.libraryTabKey));
            await _openStyle(tester, 'line_dance');
            _surface(tester, find.byType(StyleDetailView), host);
            await _scan(tester, 'gerçek Line Dance detayı $tag');
            await _tap(
                tester, find.byKey(WrittenCourseLink.startKey('line_dance')));
            await _waitFor(tester, find.byType(LineDanceCoursePage));
            await _reach(tester, find.byType(LineDanceDirectionDiagram));
            _surface(tester, find.byType(LineDanceCoursePage), host);
            final diagram = tester
                .getSemantics(find.byType(LineDanceDirectionDiagram))
                .getSemanticsData();
            expect(diagram.flagsCollection.isImage, isTrue);
            expect(diagram.label.trim(), isNotEmpty);
            await _scan(tester, 'yazılı Line Dance okuyucu $tag');
            await _back(tester);
            await _formRoundTrip(tester, host);
            await _back(tester);
            expect(find.byType(LibraryView), findsOneWidget);
            expect(host.cameraCalls, 0);
            _clean(tester, 'matris sonu $tag');
          } finally {
            semantics.dispose();
          }
        }, timeout: const Timeout(Duration(minutes: 2)));
      }
    }
  }

  for (final locale in _sweepLocales) {
    for (final mode in _modes) {
      final tag = ChoreiaLocaleController.tag(locale);
      testWidgets('hata ve kurtarma $tag ${mode.name} 2x 320px',
          (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final bundle = _CourseFaultBundle();
          final host = await _mount(tester, library, locale, mode, 2,
              failPreferencesRead: true,
              failHistory: true,
              failCatalog: true,
              bundle: bundle);
          await _waitFor(tester, find.byKey(ChoreiaShell.loadFailureKey));
          _surface(tester, find.byKey(ChoreiaShell.loadFailureKey), host);
          await _scan(tester, 'katalog okuma hatası');
          host.failCatalog = false;
          await _tap(
              tester,
              find.descendant(
                  of: find.byKey(ChoreiaShell.loadFailureKey),
                  matching: find.byType(FilledButton)));
          await _waitFor(tester, find.byType(LibraryView));
          await _tap(tester, find.byKey(ChoreiaShell.progressTabKey));
          await _waitFor(tester, find.byType(ProgressView));
          final summary =
              tester.widget<ProgressView>(find.byType(ProgressView)).summary;
          expect(summary.integrity.fidelity, HistoryFidelity.unavailable);
          expect(summary.totals, isNull,
              reason: 'Okunamayan kayıt sıfır toplam değildir');
          await _reach(tester, find.byKey(ProgressView.integrityNoteKey));
          await _scan(tester, 'okunamayan geçmiş');
          await _tap(tester, find.byKey(ChoreiaShell.profileTabKey));
          _surface(tester, find.byType(ProfileView), host);
          expect(host.locales.readFailed, isTrue);
          expect(host.themes.readFailed, isTrue);
          await _scan(tester, 'dil ve tema okuma hataları');
          expect(
              find.descendant(
                  of: find.byType(ProfileView),
                  matching: find.byWidgetPredicate((w) =>
                      w is Semantics && w.properties.liveRegion == true)),
              findsNWidgets(2));
          await _tap(tester, find.byKey(ChoreiaShell.libraryTabKey));
          await _tap(
              tester, find.byKey(WrittenCourseLink.startKey('line_dance')));
          await _waitFor(
              tester,
              find.descendant(
                  of: find.byType(LineDanceCoursePage),
                  matching: find.byType(TextButton)));
          final retry = find.descendant(
              of: find.byType(LineDanceCoursePage),
              matching: find.byType(TextButton));
          _surface(tester, find.byType(LineDanceCoursePage), host);
          expect(retry, findsOneWidget);
          bundle.failCourse = false;
          await _tap(tester, retry);
          await _reach(tester, find.byType(LineDanceDirectionDiagram));
          await _scan(tester, 'yeniden okunmuş kurs');
          await _back(tester);
        } finally {
          semantics.dispose();
        }
      }, timeout: const Timeout(Duration(minutes: 2)));

      testWidgets('public rota aileleri $tag ${mode.name} 2x 320px',
          (tester) async {
        _routeTracing = true;
        _routeTraceLines = 0;
        _routeClock = Stopwatch()..start();
        _routeTrace('body.begin $tag ${mode.name}');
        final host = await _mount(tester, library, locale, mode, 2,
            introSeen: false, localCourseFiles: true);
        _routeTrace('body.mount.end');
        await _waitFor(tester, find.byType(FirstRunView));
        _surface(tester, find.byType(FirstRunView), host);
        await _scan(tester, 'ilk açılış');
        await _tap(tester, find.byKey(FirstRunView.continueKey));
        await _waitFor(tester, find.byType(LibraryView));
        final styles = <String>{};
        final courses = <String>{};
        final forms = <String>{};
        for (final card in library.cards) {
          final id = card.entry.id;
          _routeTrace('style.$id.begin');
          await _openStyle(tester, id);
          _surface(tester, find.byType(StyleDetailView), host);
          await _scan(tester, 'detay $id');
          styles.add(id);
          if (_writtenTypes.containsKey(id)) {
            await _tap(
                tester, find.byKey(const Key('style.practiceComparison')));
            await _waitFor(tester, find.byType(PracticeComparisonPage));
            _surface(tester, find.byType(PracticeComparisonPage), host);
            await _scan(tester, 'form $id');
            forms.add(id);
            await _back(tester);
            await _tap(tester, find.byKey(WrittenCourseLink.startKey(id)));
            final page = find.byType(_writtenTypes[id]!);
            await _waitFor(tester, page);
            if (id == 'salsa_shines') {
              _routeTrace('salsa.overview.before');
              await _waitFor(tester, find.byKey(const Key('salsa.overview')));
              _routeTrace('salsa.overview.after');
              await _tap(tester, find.byKey(const Key('salsa.lesson.so_04')));
              _routeTrace('salsa.lesson.before');
              await _waitFor(
                  tester, find.byKey(const ValueKey('salsa.lessonBody.so_04')));
              _routeTrace('salsa.lesson.after');
              _surface(tester,
                  find.byKey(const ValueKey('salsa.lessonBody.so_04')), host);
              await _scan(tester, 'Salsa so_04');
              await _back(tester);
            } else {
              await _waitFor(tester,
                  find.descendant(of: page, matching: find.byType(ListView)));
            }
            _surface(tester, page, host);
            await _scan(tester, 'kurs $id');
            courses.add(id);
            await _back(tester);
            if (id == 'hip_hop_foundations') {
              await _tap(
                  tester, find.byKey(const Key('style.hipHopWrittenPath')));
              await _waitFor(tester, find.byType(HipHopCoursePage));
              await _waitFor(
                  tester,
                  find.descendant(
                      of: find.byType(HipHopCoursePage),
                      matching: find.byType(ListView)));
              expect(
                  tester
                      .widget<HipHopCoursePage>(find.byType(HipHopCoursePage))
                      .skillCourse,
                  isFalse);
              await _scan(tester, 'ayrı Hip-Hop giriş okuyucusu');
              courses.add('hip_hop_introduction');
              await _back(tester);
            }
          }
          await _back(tester);
          _routeTrace('style.$id.end');
        }
        _routeTrace('all.styles.end');
        expect(styles, library.cards.map((card) => card.entry.id).toSet());
        expect(courses, {..._writtenTypes.keys, 'hip_hop_introduction'});
        expect(forms, PracticeComparisonPage.supportedStyles);
        await _tap(tester, find.byKey(const Key('study-review-entry')));
        await _waitFor(tester, find.byType(StudyReviewPage));
        _surface(tester, find.byType(StudyReviewPage), host);
        final recalled = <String>{};
        for (final area in studyAreas) {
          for (final lesson in area.lessons) {
            _routeTrace('recall.${lesson.id}.begin');
            await _tap(tester, find.byKey(Key('study-lesson-${lesson.id}')));
            await _waitFor(tester, find.byType(RecallLessonPage));
            _surface(tester, find.byType(RecallLessonPage), host);
            await _scan(tester, 'yazılı recall ${lesson.id}');
            await _tap(tester, find.byKey(const Key('study-reference-toggle')));
            await _reach(tester, find.byKey(const Key('study-reference')));
            recalled.add(lesson.id);
            await _back(tester);
            _routeTrace('recall.${lesson.id}.end');
          }
        }
        expect(recalled, {
          for (final area in studyAreas)
            for (final lesson in area.lessons) lesson.id
        });
        _routeTrace('all.recall.end; support.before');
        await _tap(tester, find.byKey(const Key('study-related-salsa')));
        await _waitFor(tester, find.byType(SupportHoldDemo));
        _surface(tester, find.byType(SupportHoldDemo), host);
        await _scan(tester, 'sembolik destek demosu');
        // Otomatik sayacı başlatmadan manuel sayaç; sonsuz timer yok.
        await _tap(tester, find.byKey(const Key('supportHold.count.4')));
        await _back(tester);
        await _back(tester);
        await _tap(tester, find.byKey(ChoreiaShell.progressTabKey));
        await _waitFor(tester, find.byType(ProgressView));
        await _scan(tester, 'ilerleme');
        await _tap(tester, find.byKey(ChoreiaShell.profileTabKey));
        await _scan(tester, 'profil');
        _routeTrace('license.before');
        await _tap(tester, find.byKey(ProfileView.licensesEntryKey));
        await _waitFor(tester, find.byType(LicensePage));
        _surface(tester, find.byType(LicensePage), host);
        await _back(tester);
        expect(find.byType(ProfileView), findsOneWidget);
        expect(host.cameraCalls, 0);
        _clean(tester, 'rota taraması sonu');
        _routeTrace('body.end');
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
  }
}
