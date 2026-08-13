import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/course_catalog.dart';
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
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
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
    test('THE FINDING, INVERTED 2026-08-13: the app writes now, so it may no '
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
      final bool anythingWrites =
          RegExp(r'\.append\(').hasMatch(appCode());
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

    test('THE TWIN: a surface must not call ABSENT a mechanism that is '
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
      // That is legal today ONLY because no surface mentions unlocking. This
      // is precisely the shape JabLab found (a progression gate described to
      // the user with no producer anywhere), caught here before it is spoken
      // rather than after.
      final String styleDoc =
          lib('content/styles/salsa_shines/style.json');
      expect(styleDoc, contains('unlockRule'),
          reason: 'if content stops declaring it, this guard is measuring '
              'nothing');

      final String code = appCode();
      expect(code, isNot(matches(RegExp(r"'[^'\n]*\bunlock", caseSensitive: false))),
          reason: 'a user-facing string mentions unlocking, and nothing '
              'implements it — the talkative-absence class');
      expect(code, isNot(contains("json['unlockRule']")),
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
          for (final Object? l in ((s as Map)['cameraLimits'] as List? ?? const []))
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
          expect(line, matches(RegExp(r'we do not have|cannot measure|without a beat grid')),
              reason: '${s['id']} names a beat grid without saying we have '
                  'none: "$line"');
        }
      }
    });
  });
}
