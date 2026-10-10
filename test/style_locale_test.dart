import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/library/library_view.dart';
import 'package:choreia/app/library/style_content_copy.dart';
import 'package:choreia/app/library/style_detail_view.dart';
import 'package:choreia/app/library/style_status_copy.dart';
import 'package:choreia/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryCatalog library;
  setUpAll(() async => library = await testLibrary());

  Future<void> showTurkish(WidgetTester tester, String id) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: StyleDetailView(
        card: library.cardFor(id)!,
        runnableSteps: declaredReferences(),
      ),
    ));
    await tester.pump();
  }

  Future<void> bringIntoView(WidgetTester tester, Finder target) async {
    // ChoreiaBackdrop animates continuously, so bounded drags avoid settle.
    for (int i = 0; i < 25 && target.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pump();
    }
  }

  testWidgets('open Hip-Hop status, lesson access and tempo use Turkish chrome',
      (WidgetTester tester) async {
    await showTurkish(tester, 'hip_hop_foundations');

    expect(find.text('KAMERA REFERANSLARI'), findsOneWidget);
    expect(find.text('Hip-Hop Temelleri'), findsWidgets);
    expect(find.textContaining('kamera çalışması ve puanlama kapalı'), findsOneWidget);
    expect(find.textContaining('Hip-hop dansının temelindeki parti dansı'),
        findsOneWidget);
    expect(find.textContaining('Siyah Amerikalı gençler'), findsOneWidget);
    expect(find.textContaining("Hip-hop's foundational party dances"),
        findsNothing);
    await bringIntoView(
      tester,
      find.text('Bu stil yaklaşık 85–105 BPM temposunda dans edilir.'),
    );
    expect(find.text('Bu stil yaklaşık 85–105 BPM temposunda dans edilir.'),
        findsOneWidget);
    await bringIntoView(tester, find.text('Dersler'));
    expect(find.text('Dersler'), findsOneWidget);
    final unavailable = find.byKey(StyleDetailView.sessionUnavailableKey('hh_l1_bounce'));
    await bringIntoView(tester, unavailable);
    expect(unavailable, findsOneWidget);
    expect(find.text('REFERANS · SEANS KAPALI'), findsOneWidget);
    expect(find.textContaining('Bu sürümde kamera pratiği kullanılamıyor'), findsOneWidget);
    expect(find.text('Kamera pratiğini başlat'), findsNothing);
    expect(find.text('The Bounce (puanlanmıyor)'), findsOneWidget);
    expect(find.textContaining('Bu adımı yapan üç eğitmeni ölçtük'),
        findsOneWidget);
    expect(find.text('OPEN · NOT SCORED'), findsNothing);
    expect(find.textContaining('The bounce (not graded)'), findsNothing);
  });

  testWidgets('open Hip-Hop detail renders reviewed TR limits and drill copy',
      (WidgetTester tester) async {
    await showTurkish(tester, 'hip_hop_foundations');

    expect(find.textContaining('kombinasyonları kendimiz düzenlemeliyiz'),
        findsOneWidget);
    await bringIntoView(tester, find.textContaining('dizlerden gelen düzenli'));
    expect(find.textContaining('dizlerden gelen düzenli'), findsOneWidget);
    await bringIntoView(tester, find.text('Yarım hızda Bounce'));
    expect(find.text('Yarım hızda Bounce'), findsOneWidget);
    await bringIntoView(
        tester, find.textContaining('kamera gürültümüzden daha küçük'));
    expect(
        find.textContaining('kamera gürültümüzden daha küçük'), findsOneWidget);
  });

  testWidgets('Salsa release gate and disputed tempo are explained in Turkish',
      (WidgetTester tester) async {
    await showTurkish(tester, 'salsa_shines');

    expect(find.text('KAMERA KAPALI'), findsOneWidget);
    expect(
        find.textContaining('müzik vuruşu henüz doğrulanmadı'), findsOneWidget);
    await bringIntoView(
        tester, find.text('Bu stilin temposu henüz doğrulanmadı.'));
    expect(find.text('Bu stilin temposu henüz doğrulanmadı.'), findsOneWidget);
    expect(find.text('Kamera pratiğini başlat'), findsNothing);
    expect(find.textContaining('DISPUTED'), findsNothing);
  });

  testWidgets('Hula hold decision is translated while attribution is retained',
      (WidgetTester tester) async {
    await showTurkish(tester, 'hula');

    expect(find.text('DURAKLATILDI'), findsOneWidget);
    expect(find.textContaining('bir hālau içinde kumu hula'), findsOneWidget);
    expect(
        find.textContaining('Hula uygulayıcılarıyla ortaklık'), findsOneWidget);
    expect(find.text('BU DANSIN KÖKENİ'), findsOneWidget);
    expect(find.textContaining('Hula is a Native Hawaiian practice'),
        findsOneWidget);
  });

  testWidgets('catalogue tiles share the translated release and hold reasons',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr');
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: ChoreiaTheme.dark,
      home: Scaffold(body: LibraryView(library: library)),
    ));
    await tester.pump();

    expect(find.text('Hip-Hop Temelleri'), findsOneWidget);

    await bringIntoView(
        tester, find.byKey(LibraryView.tileKey('salsa_shines')));
    expect(
      find.descendant(
        of: find.byKey(LibraryView.tileKey('salsa_shines')),
        matching: find.textContaining('müzik vuruşu henüz doğrulanmadı'),
      ),
      findsOneWidget,
    );
    await bringIntoView(tester, find.byKey(LibraryView.tileKey('hula')));
    expect(
      find.descendant(
        of: find.byKey(LibraryView.tileKey('hula')),
        matching: find.textContaining('Hula uygulayıcılarıyla ortaklık'),
      ),
      findsOneWidget,
    );
  });

  test('changed authored hold reason falls back to source text', () {
    final StyleCard current = library.cardFor('hula')!;
    final LibraryEntry changed = LibraryEntry(
      id: current.entry.id,
      displayName: current.entry.displayName,
      contentStatus: current.entry.contentStatus,
      onHoldReason: 'Changed source decision requiring a new translation.',
    );
    final StyleCard card = StyleCard(entry: changed, view: current.view);
    expect(StyleStatusCopy.reason(card, turkish: true), changed.onHoldReason);
    expect(StyleStatusCopy.reason(current, turkish: true),
        contains('Hula uygulayıcılarıyla ortaklık'));
  });

  test('open-style translations require matching source ids and English text',
      () {
    final StyleCard current = library.cardFor('hip_hop_foundations')!;
    final LessonInfo bounce = current.lessons
        .firstWhere((LessonInfo lesson) => lesson.id == 'hh_l1_bounce');
    expect(StyleContentCopy.styleName(current.entry, turkish: true),
        'Hip-Hop Temelleri');
    expect(StyleContentCopy.originAttribution(current.entry, turkish: true),
        contains('bu topluluklara aittir'));
    expect(StyleContentCopy.originAttribution(current.entry, turkish: false),
        current.entry.originAttribution);
    expect(StyleContentCopy.lessonName(bounce, turkish: true),
        'The Bounce (puanlanmıyor)');
    expect(StyleContentCopy.lessonReason(bounce, bounce.reason, turkish: true),
        contains('ölçüm belirsizliğimizi'));

    final LibraryEntry changed = LibraryEntry(
      id: current.entry.id,
      displayName: 'Revised source name',
      contentStatus: current.entry.contentStatus,
      description: 'Revised source description',
      originAttribution: 'Revised source origin requiring cultural review.',
    );
    expect(StyleContentCopy.styleName(changed, turkish: true),
        'Revised source name');
    expect(StyleContentCopy.styleDescription(changed, turkish: true),
        'Revised source description');
    expect(StyleContentCopy.originAttribution(changed, turkish: true),
        changed.originAttribution);
    expect(
        StyleContentCopy.lessonReason(
          bounce,
          'Revised measurement reason',
          turkish: true,
        ),
        'Revised measurement reason');
    expect(StyleContentCopy.styleName(current.entry, turkish: false),
        current.entry.displayName);
  });

  test('all open Hip-Hop short content has reviewed Turkish source matches',
      () {
    final StyleCard card = library.cardFor('hip_hop_foundations')!;
    final List<LessonInfo> lessons = card.lessons;
    expect(lessons, hasLength(7));
    for (final LessonInfo lesson in lessons) {
      expect(StyleContentCopy.lessonName(lesson, turkish: true),
          isNot(lesson.displayName),
          reason: '${lesson.id} name');
      expect(lesson.reason, isNotNull, reason: '${lesson.id} reason source');
      expect(
        StyleContentCopy.lessonReason(lesson, lesson.reason, turkish: true),
        isNot(lesson.reason),
        reason: '${lesson.id} reason',
      );
      if (lesson.whyPermanent != null) {
        expect(StyleContentCopy.lessonWhyPermanent(lesson, turkish: true),
            isNot(lesson.whyPermanent),
            reason: '${lesson.id} permanence');
      }
    }
    expect(
        lessons.where((LessonInfo l) => l.whyPermanent != null), hasLength(4));

    final String boundary = card.prose!.reproductionBoundary!;
    expect(
      StyleContentCopy.reproductionBoundary(card.entry.id, boundary,
          turkish: true),
      contains('kombinasyonları kendimiz düzenlemeliyiz'),
    );
    expect(card.entry.stepGlossary, hasLength(4));
    for (final GlossaryEntry entry in card.entry.stepGlossary) {
      expect(
        StyleContentCopy.glossaryGloss(card.entry.id, entry, turkish: true),
        isNot(entry.gloss),
        reason: '${entry.name} glossary',
      );
    }
    expect(card.prose!.notMeasured, hasLength(5));
    for (final String source in card.prose!.notMeasured) {
      expect(
        StyleContentCopy.honestyNotMeasured(card.entry.id, source,
            turkish: true),
        isNot(source),
        reason: 'measurement limit: $source',
      );
    }
    expect(
      StyleContentCopy.honestyNotMeasured(
          card.entry.id, card.prose!.notMeasured[2],
          turkish: true),
      allOf(contains('%83'), contains('%9–28'), contains('puanlamıyoruz')),
    );
    expect(StyleContentCopy.lessonName(lessons[2], turkish: false),
        lessons[2].displayName);
  });

  test('a changed glossary or measurement statement stays in source language',
      () {
    const GlossaryEntry changed = GlossaryEntry(
      name: 'Bounce',
      gloss: 'Updated author wording awaiting review.',
    );
    expect(
      StyleContentCopy.glossaryGloss('hip_hop_foundations', changed,
          turkish: true),
      changed.gloss,
    );
    const String source = 'Updated measurement finding awaiting review.';
    expect(
      StyleContentCopy.honestyNotMeasured('hip_hop_foundations', source,
          turkish: true),
      source,
    );
  });

  test('Rock definition and reference state agree with the visible limit', () {
    final StyleCard card = library.cardFor('hip_hop_foundations')!;
    final LessonInfo rock = card.lessons.firstWhere(
      (LessonInfo lesson) => lesson.id == 'hh_l1_rock',
    );
    expect(rock.kind, LessonKind.locked);
    expect(rock.reason, contains('no teachers have been measured'));

    final String source = card.prose!.notMeasured.last;
    expect(source, contains('Rock has an authored step definition'));
    expect(source, contains('no teacher has been measured'));
    expect(source, contains('its lesson stays locked'));
    expect(source, contains('Groove is taught as feel and musicality'));
    final String turkish = StyleContentCopy.honestyNotMeasured(
      card.entry.id,
      source,
      turkish: true,
    );
    expect(turkish, contains('Rock adımının tanımı hazır'));
    expect(turkish, contains('hiçbir eğitmen ölçülmedi'));
    expect(turkish, contains('dersi kilitli'));
    expect(turkish, contains('Groove, his ve müzikalite'));
    expect(
      StyleContentCopy.honestyNotMeasured(
        card.entry.id,
        source,
        turkish: false,
      ),
      source,
    );
  });
}
