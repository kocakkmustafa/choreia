import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Does the app SHIP the content it references?
///
/// Why this test exists as its own file
/// ------------------------------------
/// Every other content test in this suite runs through `DiskBundle`, which
/// serves any file present in the repository. A real `rootBundle` serves only
/// what `pubspec.yaml` declares. That difference is invisible to the rest of
/// the suite and it is exactly where a real defect was found on 2026-08-07:
/// `content/references/hh_bounce.json` exists, is 74 KB of measured reference
/// data, and **is not declared**, so no device can read it.
///
/// `pubspec.yaml` says why references are listed file by file rather than as a
/// directory (build-time bookkeeping in the same folder must not ship) and
/// closes with "adding a reference means adding a line here — and a forgotten
/// line fails loudly at load, which is the failure direction to prefer". It
/// does fail loudly — at RUNTIME, on a device, inside a lesson. This file moves
/// that failure to the suite, where it costs nothing.
///
/// Parsed with regular expressions rather than a YAML package: adding a
/// dependency to read six lines of a file this project already owns would be
/// the heavier choice, and the shape being matched (a flat list of asset paths)
/// is fixed by pubspec's own schema.
void main() {
  /// Asset paths declared under `flutter: assets:`.
  Set<String> declaredAssets() {
    final List<String> lines = File('pubspec.yaml').readAsLinesSync();
    final Set<String> out = <String>{};
    bool inAssets = false;
    for (final String line in lines) {
      if (RegExp(r'^\s{2}assets:\s*$').hasMatch(line)) {
        inAssets = true;
        continue;
      }
      if (inAssets) {
        final RegExpMatch? m = RegExp(r'^\s{4}-\s+(\S+)\s*$').firstMatch(line);
        if (m != null) {
          out.add(m.group(1)!);
          continue;
        }
        // A non-comment, non-blank line that is not a list item ends the block.
        if (line.trim().isNotEmpty && !line.trim().startsWith('#')) break;
      }
    }
    return out;
  }

  /// True when a real bundle would serve [path].
  ///
  /// A directory entry in `pubspec.yaml` is **not recursive** — `content/`
  /// includes the files directly inside `content/` and nothing in
  /// `content/references/`. Getting this wrong is not a small error: a
  /// `startsWith` prefix check makes `content/` swallow every path in the tree,
  /// and this test then passes while measuring nothing. It did exactly that on
  /// its first run (family lesson 4 — a too-broad check makes an absence claim
  /// vacuum-true), which is why the parent directory is compared exactly.
  bool isBundled(String path, Set<String> declared) {
    if (declared.contains(path)) return true;
    final int slash = path.lastIndexOf('/');
    if (slash < 0) return false;
    return declared.contains(path.substring(0, slash + 1));
  }

  test('the asset block parses and is not silently empty', () {
    final Set<String> declared = declaredAssets();
    expect(declared, isNotEmpty,
        reason: 'if this parser stops finding the asset block, every '
            'assertion below becomes vacuously true — the "structural removal '
            'makes absence claims vacuum-true" trap (family lesson 4)');
    expect(declared, contains('content/'));

    // The parser must see the file-by-file reference lines too. If the regex
    // ever stops matching them, `missing` below fills with false positives —
    // the opposite failure, and just as misleading.
    expect(declared, contains('content/references/ss_shine_footwork.json'));
  });

  test('a directory declaration is treated as non-recursive', () {
    // Guards the check itself. `content/` is declared; `content/references/`
    // is not. If this ever reports true, the test above has stopped measuring.
    expect(isBundled('content/library.json', <String>{'content/'}), isTrue);
    expect(isBundled('content/references/x.json', <String>{'content/'}), isFalse,
        reason: 'Flutter does not recurse into subdirectories for a directory '
            'asset entry, and a prefix check that pretends otherwise silently '
            'disables this whole file');
  });

  /// References that exist, are reachable from a lesson, and are deliberately
  /// NOT declared — each with the reason it is withheld.
  ///
  /// An allowlist rather than a red suite, because a permanently-failing test
  /// trains people to stop reading it. The entry is not an excuse: it names the
  /// class of the limit (family lesson 5 — write the limit's CLASS, not just
  /// its existence), and the test below proves each listed file really exists,
  /// so this list cannot quietly rot into a lie once the gap is closed.
  const Map<String, String> knownUnshipped = <String, String>{
    'content/references/hh_bounce.json':
        'Built and measured (3 sources, none thin) but carries '
            'mirrorConfident:false, where the one shipped reference '
            '(ss_shine_footwork) carries true. Whether a reference that cannot '
            'resolve left from right may ship for a DEMO-ONLY lesson — which '
            'issues measurements and never a side-dependent verdict — is a '
            'product ruling, not a build fix. Raised to the coordinator '
            '2026-08-07; withheld until it is answered, because shipping a '
            'reference that failed a gate is worse than shipping none. NOTE: '
            "library.json's own note claims this step has NO reference, which "
            'is measurably wrong — the file is 74 KB on disk.',
  };

  test('the known-unshipped list describes reality, not a memory', () {
    for (final String path in knownUnshipped.keys) {
      expect(File(path).existsSync(), isTrue,
          reason: '$path is listed as deliberately withheld, but it does not '
              'exist — the list has outlived the thing it describes');
    }
  });

  test('every withheld entry is still REACHABLE FROM A LESSON', () {
    // The claim the allowlist makes is not merely "this file exists". It is
    // "this file exists, a lesson points at it, and we are choosing not to
    // ship it". The middle clause was unverified until C-153: if
    // `hh_l1_bounce` lost its `step` field tomorrow, the entry would become
    // dead weight describing a chain that no longer runs, and every test here
    // would stay green — the exemption-list failure JabLab measured, where a
    // list keeps asserting something no code path produces.
    final Set<String> reachable = <String>{};
    for (final FileSystemEntity dir in Directory('content/styles').listSync()) {
      final File styleFile = File('${dir.path}/style.json');
      if (!styleFile.existsSync()) continue;
      final Map<String, dynamic> style =
          (jsonDecode(styleFile.readAsStringSync()) as Map)
              .cast<String, dynamic>();
      for (final Object? rawLevel in (style['levels'] as List? ?? const [])) {
        for (final Object? rawLesson
            in ((rawLevel as Map)['lessons'] as List? ?? const [])) {
          final Object? stepId = (rawLesson as Map)['step'];
          if (stepId is String) {
            reachable.add('content/references/$stepId.json');
          }
        }
      }
    }

    expect(reachable, isNotEmpty,
        reason: 'no lesson names a step at all — this gate would then pass '
            'vacuously for any allowlist entry');

    for (final String path in knownUnshipped.keys) {
      expect(reachable, contains(path),
          reason: 'no lesson points at $path any more, so withholding it is '
              'no longer a decision about anything. Remove the entry — a live '
              'ruling that has become folklore is worse than no entry.');
    }
  });

  test('every reference a lesson can reach is actually shipped', () {
    final Set<String> declared = declaredAssets();
    final List<String> missing = <String>[];
    final List<String> checked = <String>[];

    for (final FileSystemEntity dir
        in Directory('content/styles').listSync()) {
      final File styleFile = File('${dir.path}/style.json');
      if (!styleFile.existsSync()) continue;
      final Map<String, dynamic> style =
          (jsonDecode(styleFile.readAsStringSync()) as Map)
              .cast<String, dynamic>();

      for (final Object? rawLevel in (style['levels'] as List? ?? const [])) {
        for (final Object? rawLesson
            in ((rawLevel as Map)['lessons'] as List? ?? const [])) {
          final Object? stepId = (rawLesson as Map)['step'];
          if (stepId is! String) continue;

          final String ref = 'content/references/$stepId.json';
          // Only references that EXIST are candidates. A step with no
          // reference at all is a content state the app already renders
          // honestly (`LessonBlock.referenceMissing`); this test is about the
          // narrower, nastier case where the work was done and not shipped.
          if (!File(ref).existsSync()) continue;
          checked.add(ref);
          if (!isBundled(ref, declared) && !knownUnshipped.containsKey(ref)) {
            missing.add(ref);
          }
        }
      }
    }

    expect(checked, isNotEmpty,
        reason: 'no lesson-reachable reference was examined at all — this '
            'test would pass without measuring anything');

    expect(missing, isEmpty,
        reason: 'These reference documents exist and are reachable from a '
            'lesson, but pubspec.yaml does not declare them, so no device can '
            'load them. The measurement work is done and does not ship: '
            '$missing');
  });

  test('a withheld reference stays withheld until someone rules on it', () {
    // The other direction: if a listed file gets declared, this list is stale
    // and the ruling has been made without updating the record of WHY.
    final Set<String> declared = declaredAssets();
    for (final String path in knownUnshipped.keys) {
      expect(isBundled(path, declared), isFalse,
          reason: '$path is now shipped, so remove it from knownUnshipped — '
              'leaving it there turns a live decision into stale folklore');
    }
  });
}
