import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _course() =>
    (jsonDecode(File('content/salsa_on1_course.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();

Map<String, dynamic> _lesson(Map<String, dynamic> course, String id) =>
    (course['lessons'] as List).cast<Map<String, dynamic>>().singleWhere(
          (row) => row['id'] == id,
        );

String _teaching(Map<String, dynamic> lesson, String language) =>
    ((lesson['teaching'] as Map)[language] as List).join(' ');

// Reads the displayed bilingual count clauses rather than a parallel fixture.
// This checks authored count/support logic, never a person's actual load.
List<({String count, String side, String action})> _touchCells(
    String teaching, String language) {
  final pattern = language == 'en'
      ? RegExp(r'(1(?:-and)?|2|5(?:-and)?|6): (right|left) (touch|step)')
      : RegExp(r'(1(?:-ve)?|2|5(?:-ve)?|6): (sağ|sol) (dokunuş|adım)');
  return [
    for (final match in pattern.allMatches(teaching))
      (
        count: match.group(1)!.replaceAll('-and', '&').replaceAll('-ve', '&'),
        side: const {'right': 'R', 'left': 'L', 'sağ': 'R', 'sol': 'L'}[
            match.group(2)!]!,
        action: const {
          'touch': 'touch',
          'step': 'step',
          'dokunuş': 'touch',
          'adım': 'step',
        }[match.group(3)!]!,
      ),
  ];
}

String _supportAfter(
    String initial, List<({String count, String side, String action})> actions) {
  var support = initial;
  for (final action in actions) {
    // The written touch cell must leave its touching foot available.
    expect(action.side, isNot(support),
        reason: 'Count ${action.count}: the planned moving foot is not free');
    if (action.action == 'step') support = action.side;
  }
  return support;
}

void main() {
  for (final language in ['tr', 'en']) {
    test('$language displayed two-cell map preserves touches and explicit reset',
        () {
      final row = _lesson(_course(), 'so_32');
      final actions = _touchCells(_teaching(row, language), language);
      expect(actions.map((action) => action.count).toList(),
          ['1', '1&', '2', '5', '5&', '6']);
      expect(actions.map((action) => action.side).toList(),
          ['R', 'R', 'R', 'L', 'L', 'L']);
      expect(actions.map((action) => action.action).toList(),
          ['touch', 'touch', 'step', 'touch', 'touch', 'step']);
      final support = _supportAfter('L', actions);
      expect(support, 'L');
      // The basic starts with L; a right-support reset outside the cells is
      // therefore necessary, not a fictional uninterrupted On1 transition.
      final practice = (row['practice'] as Map)[language] as String;
      expect(practice,
          contains(language == 'en' ? 'right step in place' : 'sağ yerinde adımla'));
      expect(practice,
          contains(language == 'en' ? 'outside the counted cell' : 'sayılan hücrenin dışında'));
      expect(practice,
          contains(language == 'en' ? 'fresh eight' : 'Yeni bir sekiz'));
      final resetSupport = _supportAfter(
          support, [(count: 'outside', side: 'R', action: 'step')]);
      expect(resetSupport, 'R');
      expect('L', isNot(resetSupport));
    });
  }

  for (final language in ['tr', 'en']) {
    test('$language crossover practice frees the other foot before its touches', () {
      final row = _lesson(_course(), 'so_25');
      final practice = (row['practice'] as Map)[language] as String;
      final resetPattern = language == 'en'
          ? RegExp(r'left-right-left|right-left-right')
          : RegExp(r'sol-sağ-sol|sağ-sol-sağ');
      final resetOrders = resetPattern.allMatches(practice)
          .map((match) => match.group(0)!).toList();
      expect(resetOrders, language == 'en'
          ? ['left-right-left', 'right-left-right']
          : ['sol-sağ-sol', 'sağ-sol-sağ']);
      expect(practice, contains(language == 'en'
          ? 'keeping support on the right' : 'desteği sağda tut'));
      expect(practice, contains(language == 'en'
          ? 'keeping support on the left' : 'desteği solda tut'));
      expect(practice, contains(language == 'en'
          ? 'outside the counted On1 phrase' : 'sayılan On1 dizisinin dışında'));
      var support = 'R';
      for (var index = 0; index < resetOrders.length; index++) {
        final steps = resetOrders[index].split('-').map((side) => (
          count: 'outside',
          side: side == 'left' || side == 'sol' ? 'L' : 'R',
          action: 'step',
        )).toList();
        support = _supportAfter(support, steps);
        expect(support, index == 0 ? 'L' : 'R');
      }
    });
  }

  test('undefined accent-matching foot variant remains withheld in both languages',
      () {
    final row = _lesson(_course(), 'so_33');
    expect(_teaching(row, 'en'),
        contains('No new accent-matching foot sequence is specified'));
    expect(_teaching(row, 'tr'), contains('yeni bir ayak dizisi tarif edilmiyor'));
    expect((row['practice'] as Map)['en'],
        contains('No new syncopated foot sequence is requested'));
    expect((row['practice'] as Map)['tr'],
        contains('ayaklarla yeni senkoplu dizi istenmez'));
  });

  for (final language in ['tr', 'en']) {
    test('$language left turn and rhythm return retain the primary step order',
        () {
      final course = _course();
      for (final entry in {'so_22': 1, 'so_35': 2}.entries) {
        final lines = (_lesson(course, entry.key)['teaching'] as Map)[language]
            as List;
        final text = lines[entry.value] as String;
        final pattern = language == 'en'
            ? RegExp(r'(left|right) on (?:the fresh )?([123567])')
            : RegExp(r'([123567]) (sol|sağ)');
        final actions = [
          for (final match in pattern.allMatches(text))
            (
              count: match.group(language == 'en' ? 2 : 1)!,
              side: const {'left': 'L', 'right': 'R', 'sol': 'L', 'sağ': 'R'}[
                  match.group(language == 'en' ? 1 : 2)!]!,
              action: 'step',
            ),
        ];
        expect(actions.map((action) => action.count).toList(),
            ['1', '2', '3', '5', '6', '7']);
        expect(actions.map((action) => action.side).toList(),
            ['L', 'R', 'L', 'R', 'L', 'R']);
        expect(_supportAfter('R', actions), 'R');
      }
    });
  }

  test('right study and quiet/accent alternatives have explicit bounded plans',
      () {
    final course = _course();
    final right = _lesson(course, 'so_19');
    expect(_teaching(right, 'en'), contains('small RIGHT direction change'));
    expect(_teaching(right, 'tr'), contains('küçük bir SAĞ yön değişimi'));
    expect((right['practice'] as Map)['en'], contains('read lesson 22 first'));
    final quiet = _lesson(course, 'so_34');
    final main = ((_teaching(quiet, 'en').split('Main four-eight plan: ').last)
            .split('.').first)
        .split('→');
    expect(main.length, 4);
    expect(main[0].trim(), 'one basic eight');
    expect(main[1], contains('quiet-count'));
    expect(main[2], contains('hand-accent'));
    expect(main[3].trim(), 'one basic eight');
    final practice = (quiet['practice'] as Map)['en'] as String;
    final shorter = RegExp(r'three eights: ([^.]*)')
        .firstMatch(practice)!.group(1)!.split('→');
    expect(shorter.length, 3);
    expect(shorter[1], contains('quiet counting including one hand accent'));
    expect(_teaching(quiet, 'en'), contains('without changing foot support'));
    expect(_teaching(quiet, 'tr'), contains('ayak desteğini bunun için değiştirme'));
    // Independently parse the Turkish plans; the English match is not TR proof.
    final trPractice = (quiet['practice'] as Map)['tr'] as String;
    final trMain = RegExp(r'dört sekiz olarak seç: ([^.]*)')
        .firstMatch(trPractice)!.group(1)!.split('→');
    final trShort = RegExp(r'üç sekizdir: ([^.]*)')
        .firstMatch(trPractice)!.group(1)!.split('→');
    expect(trMain.length, 4);
    expect(trMain.first.trim(), 'temel');
    expect(trMain[1], contains('ayaklar dinlenirken sessiz sayma'));
    expect(trMain[2], contains('aynı ayak desteğiyle tek küçük el vurgusu'));
    expect(trMain.last.trim(), 'temel');
    expect(trShort.length, 3);
    expect(trShort[1], contains('sessiz sayma içinde tek el vurgusu'));
    expect(trPractice, contains('aynı plan, aynı seçilen vurgu sayısı'));

  });

  for (final id in ['so_36', 'so_37', 'so_38']) {
    test('$id listening retest keeps excerpt and cue fixed in TR and EN', () {
      final row = _lesson(_course(), id);
      final en = (row['practice'] as Map)['en'] as String;
      final tr = (row['practice'] as Map)['tr'] as String;
      expect(en, contains('SAME lawfully accessed short excerpt'));
      expect(en, contains('same sound/entry cue'));
      expect(en, contains('same audibility'));
      expect(en, contains('that SAME cue/sound without reading'));
      expect(en, contains('Another track/layer begins a new A'));
      expect(en, contains('leave pulse, musical 1 and phrase entry untested'));
      expect(tr, contains('AYNI kısa bölüm ve aynı sesi/başlangıç işaretini'));
      expect(tr, contains('aynı duyulabilirlikte'));
      expect(tr, contains('metne bakmadan AYNI işareti/sesi'));
      expect(tr, contains('Başka parça/katman seçmek yeni A'));
      expect(tr, contains('pulse, müzikte 1 veya cümle başlangıcını sınanmış sayma'));
    });
  }

  test('retests preserve one location and conditions without a completion gate',
      () {
    final course = _course();
    for (final id in [
      'so_06', 'so_12', 'so_18', 'so_24', 'so_30',
      'so_41', 'so_42', 'so_43', 'so_47', 'so_48',
    ]) {
      final row = _lesson(course, id);
      final en = (row['practice'] as Map)['en'] as String;
      final tr = (row['practice'] as Map)['tr'] as String;
      expect(en, contains('ONE count/transition difference or uncertainty'));
      expect(en, contains('same order, count source/pace'));
      expect(en, contains('changed conditions begin a new A'));
      expect(tr, contains('TEK sayı/geçişte'));
      expect(tr, contains('aynı sıra, sayım kaynağı/tempo'));
      expect(tr, contains('koşul değişirse yeni A başlat'));
      expect(row['assessment'], 'selfCheck');
    }
    expect(course['version'], 1);
    expect((course['lessons'] as List).length, 48);
    expect((course['music'] as Map)['provided'], isFalse);
    expect((course['music'] as Map)['beatEvidence'], 'unavailable');
    for (final row in (course['lessons'] as List).cast<Map<String, dynamic>>()) {
      final brief = row['mediaBrief'] as Map;
      expect(brief['status'], 'planned');
      expect(brief['sequence'], row['teaching']);
      expect(brief['rights'], contains('No asset exists yet'));
    }
  });
}
