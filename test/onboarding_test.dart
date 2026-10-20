import 'dart:io';

import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/onboarding/first_run_flag.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:choreia/app/shell/choreia_shell.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

/// The first-run screen: does it tell the truth, and can you get past it?
void main() {
  late LibraryCatalog library;

  setUpAll(() async => library = await testLibrary());

  Future<void> pump(WidgetTester tester, FirstRunFlag flag,
      {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ChoreiaShell(
        bundleOverride: () async => library,
        flagOverride: flag,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('bir kez görünür, ve çıkışı GÖRÜNÜR', () {
    testWidgets('taze kurulumda tanıtım gelir, katalog gelmez',
        (WidgetTester tester) async {
      await pump(tester, MemoryFirstRunFlag());
      expect(find.byType(FirstRunView), findsOneWidget);
      expect(find.byType(LibraryView), findsNothing,
          reason: 'tanıtım kataloğun ÜSTÜNE binmemeli — arkada duran bir '
              'ekran, kullanıcının hangisine baktığını belirsizleştirir');
    });

    testWidgets('dönen kullanıcı tanıtımı HİÇ görmez — tek kare bile',
        (WidgetTester tester) async {
      // THE CATALOGUE MUST RESOLVE FIRST, or this test proves nothing.
      //
      // Written the obvious way — both futures pending — it passed against a
      // deliberately broken shell (`_introSeen = false` from the start),
      // because the catalogue was still loading and the loading screen hid
      // the flash. A gate that cannot fail is not a gate, and this one had to
      // be sabotaged to find that out.
      //
      // So: catalogue ready immediately, flag deliberately slow. Now the only
      // thing the shell can be waiting on is the flag, and an implementation
      // that guesses "not seen" while waiting paints the intro on frame 0.
      final SlowFlag flag = SlowFlag(seen: true);
      await tester.pumpWidget(MaterialApp(
        home: ChoreiaShell(
          bundleOverride: () => SynchronousFuture<LibraryCatalog>(library),
          flagOverride: flag,
        ),
      ));

      for (int i = 0; i < 6; i++) {
        expect(find.byType(FirstRunView), findsNothing,
            reason: 'kare $i: tanıtım dönen kullanıcıya çakıyor');
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LibraryView), findsOneWidget);
    });

    testWidgets('çıkış düğmesi KAYDIRMADAN görünür (375x812)',
        (WidgetTester tester) async {
      await pump(tester, MemoryFirstRunFlag());
      final Finder button = find.byKey(FirstRunView.continueKey);
      expect(button, findsOneWidget);

      // Not "exists" — VISIBLE without scrolling. The first measurement of
      // this screen found the button below the fold at 375x812, which made
      // the only exit from a user's first screen something they had to
      // discover. `find` cannot tell those apart; geometry can.
      final Rect rect = tester.getRect(button);
      final Size screen =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.bottom, lessThanOrEqualTo(screen.height),
          reason: 'çıkış düğmesi ekranın altında kalıyor — açılış ekranının '
              'tek çıkışı keşfedilmeyi gerektiriyor');
      expect(rect.top, greaterThanOrEqualTo(0));
    });

    testWidgets('devam edilince bir daha gelmez ve bayrak GERÇEKTEN yazılır',
        (WidgetTester tester) async {
      final MemoryFirstRunFlag flag = MemoryFirstRunFlag();
      await pump(tester, flag);
      await tester.tap(find.byKey(FirstRunView.continueKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LibraryView), findsOneWidget);
      expect(flag.seen, isTrue,
          reason: 'ekran kapandı ama işaret yazılmadı — kullanıcı her '
              'açılışta aynı tanıtımı görür');
    });
  });

  group('söylediği şey DOĞRU', () {
    for (final language in ['en', 'tr']) {
      testWidgets('current course and closed camera intro in $language',
          (tester) async {
        tester.platformDispatcher.localeTestValue = Locale(language);
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);
        await pump(tester, MemoryFirstRunFlag(), locale: Locale(language));
        expect(
            find.textContaining(language == 'tr'
                ? 'Beş solo dans yolunu'
                : 'Explore five solo dance paths'),
            findsOneWidget);
        expect(
            find.textContaining(language == 'tr'
                ? 'Hesap veya kamera gerekmez'
                : 'No account or camera is required'),
            findsOneWidget);
        expect(
            find.textContaining(language == 'tr'
                ? 'Çalışma kaydın bu cihazda kalır'
                : 'study record stays on this device'),
            findsOneWidget);
        final gate = find.textContaining(language == 'tr'
            ? 'canlı kamera pratiği ve abonelik satışı kapalıdır'
            : 'Live camera practice and subscription sales are closed');
        for (var i = 0; i < 12 && gate.evaluate().isEmpty; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -160));
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(gate, findsOneWidget);
        expect(find.textContaining('watches your dancing to give you feedback'),
            findsNothing);
        expect(find.byKey(FirstRunView.continueKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
    test('kamera cümlesi iOS izin metniyle BİREBİR aynı', () {
      // Two copies of a privacy promise drift, and the one that drifts is the
      // one nobody re-reads. The OS shows its string at the moment of consent;
      // this screen shows its own beforehand. They must be one sentence.
      final String plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains(IntroStrings.camera),
          reason: 'tanıtımdaki kamera cümlesi ile Info.plist '
              'NSCameraUsageDescription AYRIŞTI. İkisi aynı vaat; biri '
              'değiştiyse diğeri de değişmeli');
    });

    testWidgets('envanter cümlesi SAYILIYOR, yazılmıyor',
        (WidgetTester tester) async {
      await pump(tester, MemoryFirstRunFlag());
      final LibraryTally tally = LibraryTally.from(library.cards);

      // Below the fold on a 375x812 screen, and a lazy `ListView` does not
      // BUILD what it has not laid out — so the finder must walk there, not
      // just look. (`scrollUntilVisible` never returns: the backdrop animates
      // forever, so it never settles.)
      final Finder sentence = find.text(IntroStrings.today(tally));
      for (int i = 0; i < 15 && sentence.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -220));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // The claim is derived from the same catalogue the library screen
      // counts, so the intro can never quote an inventory the app no longer
      // has. Asserted against the CATALOGUE, not against a literal string —
      // a literal would have to be edited in two places and would rot in one.
      expect(sentence, findsOneWidget);
      expect(IntroStrings.today(tally), contains('${tally.total}'));
    });

    test('ritim/zamanlama YOKLUĞU açıkça söyleniyor', () {
      // The family's hardest line: there is no rhythm or timing score and it
      // may never be implied. Onboarding is where an unstated absence becomes
      // an assumed presence, so the absence is stated.
      final String limits = IntroStrings.limits.toLowerCase();
      expect(limits, contains('no rhythm or timing score'));
      expect(IntroStrings.music.toLowerCase(), contains('not'),
          reason: 'müzik paneli "adımlar sayılır, parçaya zamanlanmaz" '
              'ayrımını taşımalı');
    });

    test('tezahürat yok, uydurma vaat yok', () {
      final String all = <String>[
        IntroStrings.what,
        IntroStrings.camera,
        IntroStrings.music,
        IntroStrings.limits,
        IntroStrings.today(LibraryTally.from(library.cards)),
        IntroStrings.continueLabel,
      ].join(' ').toLowerCase();

      // Written to the PATTERN, not to today's copy: these are the shapes the
      // family forbids, so a rewrite that reintroduces one fails even if the
      // exact wording is new.
      const List<String> banned = <String>[
        "let's go",
        'awesome',
        'amazing',
        'unlock',
        'level up',
        'streak',
        'crush it',
        'get started in seconds',
        'personalised plan',
        'ai coach',
        'perfect your',
        'master ',
      ];
      for (final String word in banned) {
        expect(all, isNot(contains(word)),
            reason: 'açılış metninde yasak kalıp: "$word"');
      }

      // A promise of scoring would be the costliest lie here: one lesson can
      // open and NONE of them score.
      expect(all, isNot(contains('score your')),
          reason: 'hiçbir ders skorlamıyorken skorlama vaadi');
    });
  });
}

/// A flag whose answer arrives a few frames late — the real shape of a disk
/// read, and the only way the "no flash" claim above can actually fail.
class SlowFlag implements FirstRunFlag {
  SlowFlag({required this.seen});

  final bool seen;
  bool wrote = false;

  @override
  Future<bool> hasSeenIntro() =>
      Future<bool>.delayed(const Duration(milliseconds: 120), () => seen);

  @override
  Future<void> markSeen() async => wrote = true;
}
