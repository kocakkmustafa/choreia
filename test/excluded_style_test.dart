import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/library/library_catalog.dart';
import 'package:choreia/app/style_availability.dart';
import 'package:flutter_test/flutter_test.dart';

/// **THE BRANCH NOBODY HAD SEEN.**
///
/// The handover left this open by name: `StyleView.derive`'s `excluded` branch
/// returns `userFacingReason = null`, which would be a style that cannot be
/// opened and gives no reason — the silence A3 forbids. It also recorded the
/// limit honestly: *"refutability derived from the code, not run"*, and
/// `style_availability_test`'s three synthetic cases never touch it.
///
/// Measuring it found the note was RIGHT and INCOMPLETE. The null reason is
/// only half; the other half is that `StyleCard.badge` mapped `excluded` into
/// the same bucket as `comingSoon` (`inPreparation`). So an out-of-scope style
/// would have been LISTED, wearing a "we are preparing this" badge, with no
/// sentence under it — a promise of future work for something nobody is
/// building, and a silent unopenable surface at once.
///
/// Two intents disagreed inside one file and neither was wrong alone:
/// `Availability.excluded`'s own doc says *"Rendered silently"*, the badge said
/// *"in preparation"*. Nothing showed, because the population is zero.
///
/// > ***A BRANCH WITH NO POPULATION IS NOT A BRANCH THAT WORKS —
/// > IT IS A BRANCH NOBODY HAS SEEN.***
///
/// This file gives it a population. Every case below runs on a SYNTHETIC entry,
/// because the real catalogue has none and waiting for one means finding out on
/// a user's screen.
void main() {
  LibraryEntry entry(String id, String? status) => LibraryEntry(
        id: id,
        displayName: id,
        contentStatus: status,
      );

  LibraryCatalog catalogOf(List<LibraryEntry> entries) => LibraryCatalog(
        entries: entries,
        coursesByStyle: const <String, CourseCatalog>{},
      );

  group('an out-of-scope style never reaches a surface', () {
    test('THE CASE ITSELF: an excluded entry produces no card', () {
      final LibraryCatalog c = catalogOf(<LibraryEntry>[
        entry('kept', 'comingSoon'),
        entry('dropped', excludedStatus),
      ]);

      expect(c.cards.map((StyleCard s) => s.entry.id), <String>['kept'],
          reason: 'kapsam dışı bir stil kütüphaneye kart olarak giriyor');
      expect(c.excludedEntries.map((LibraryEntry e) => e.id),
          <String>['dropped']);

      // NOT deleted from the catalogue — dropped from the SURFACE. The
      // declaration is still readable; what is refused is showing it as
      // something the learner might one day open.
      expect(c.entries, hasLength(2));
    });

    test('POSITIVE CONTROL — the filter drops ONLY excluded', () {
      // Without this, a filter that returned an empty list would pass the test
      // above. Every other status this app declares must survive: measured
      // against the real content's own distribution (demoOpen 1 · comingSoon
      // 31 · live 1 · onHold 1), plus the null status a style with no `status`
      // key would carry.
      final LibraryCatalog c = catalogOf(<LibraryEntry>[
        entry('a', 'live'),
        entry('b', 'demoOpen'),
        entry('c', 'comingSoon'),
        entry('d', 'onHold'),
        entry('e', null),
        entry('f', excludedStatus),
      ]);
      expect(c.cards.map((StyleCard s) => s.entry.id),
          <String>['a', 'b', 'c', 'd', 'e']);
    });

    test('and the SPELLING is a single constant, so a typo cannot smuggle one '
        'back in', () {
      // `'Excluded'` is not `excluded`; a style spelled that way falls through
      // `StyleView.derive` to `comingSoon` and IS listed — with a reason, so it
      // is not silent, but it is also not what content meant. The point of the
      // constant is that the filter and the derivation can never disagree
      // about which string they are looking for.
      expect(excludedStatus, 'excluded');
      final LibraryCatalog c =
          catalogOf(<LibraryEntry>[entry('typo', 'Excluded')]);
      expect(c.cards, hasLength(1),
          reason: 'yanlış yazılmış bir statü SESSİZCE elenirse, içerik '
              'yazarının hatası kullanıcıdan gizlenmiş olur');
      expect(c.cards.single.view.availability, Availability.comingSoon);
      expect(c.cards.single.view.userFacingReason, isNotNull,
          reason: 'listelenen her açılamayan kartın bir sebebi olmalı — '
              'yanlış yazım bile sessiz bir yüzey üretmemeli');
    });
  });

  group('every card that IS shown carries a reason when it cannot be opened',
      () {
    test('the rule holds across the whole synthetic lattice', () {
      // The claim A3 actually makes, checked at the CARD level rather than at
      // `StyleView` alone: `style_availability_test` proves the derivation
      // gives a reason, this proves nothing reaches a surface without one.
      final LibraryCatalog c = catalogOf(<LibraryEntry>[
        entry('a', 'live'),
        entry('b', 'demoOpen'),
        entry('c', 'comingSoon'),
        entry('d', 'onHold'),
        entry('e', null),
        entry('f', excludedStatus),
      ]);

      for (final StyleCard card in c.cards) {
        if (card.view.isOpenable) continue;
        expect(card.view.userFacingReason, isNotNull,
            reason: '${card.entry.id} (${card.view.availability}) açılamıyor '
                've sebebi YOK — J-066\'nın yasakladığı sessizlik');
        expect(card.view.userFacingReason, isNotEmpty);
      }

      // POSITIVE CONTROL for the loop: it must have had something to check.
      // A loop over an empty list passes every assertion inside it.
      expect(c.cards.where((StyleCard s) => !s.view.isOpenable), isNotEmpty,
          reason: 'döngü boş küme üzerinde koştu — hiçbir şey ölçülmedi');
    });
  });
}
