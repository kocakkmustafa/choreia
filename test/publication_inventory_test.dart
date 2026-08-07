import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/progress_summary.dart';
import 'package:flutter_test/flutter_test.dart';

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
    test('THE FINDING: history is reported as UNWRITTEN, not as unreadable',
        () {
      // EVIDENCE: nothing in `lib/` ever writes a session. `SessionStore` is
      // only ever READ (`store.recent()` in progress_summary and
      // recorded_summary); no call site constructs one or appends to it, and
      // the shell hands `ProgressSummary.build` an empty history by hand.
      final String src = appSource();
      final bool anythingWrites = RegExp(
              r'\.append\(|\.write\(|SessionStore\s*\(|JsonlSessionStore\s*\(')
          .hasMatch(src);
      expect(anythingWrites, isFalse,
          reason: 'a session store now exists — re-check whether '
              '`notRecorded` is still the honest state, because it stops '
              'being true the moment anything is written');

      // So the surface must say ABSENT, not FAILED. "We could not open your
      // practice history … until we can read it" describes a store that
      // exists and failed, and a reader takes it to mean their practice was
      // recorded and is out of reach.
      expect(src, contains('HistoryIntegrity.notRecorded'),
          reason: 'the shell must report the absent state, not the failure '
              'state');

      // Scoped to the SHELL, not the whole app: `ProgressSummary.from` uses
      // `unavailable` correctly, for a real store that refuses to open. The
      // first version of this assertion banned it everywhere and would have
      // forced a correct branch to be deleted — an over-broad test turning a
      // right answer red (C-160).
      expect(lib('lib/app/shell/choreia_shell.dart'),
          isNot(contains('HistoryIntegrity.unavailable')),
          reason: 'the shell has no store at all, so "failed to open" is the '
              'wrong sentence there');

      final String? said = HistoryIntegrity.notRecorded.note;
      expect(said, isNotNull);
      expect(said, contains('does not save'),
          reason: 'the sentence must name the absence outright');
      expect(said, contains('nothing of'),
          reason: 'and must remove the alarm the old wording created — a '
              'reader of "we could not open your history" believes something '
              'of theirs is lost');
      expect(said, isNot(contains('could not open')));
      expect(HistoryIntegrity.notRecorded.showsTotals, isFalse,
          reason: 'no numbers may be shown for a record that was never kept');
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
