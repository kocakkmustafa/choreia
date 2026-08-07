import 'dart:convert';
import 'dart:io';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:test/test.dart';

/// THE THIRD RUNNER'S PIN, AND THE CONTRACT IT SHARES WITH THIS ONE.
///
/// This repository has three test runners — the app suite, this engine suite,
/// and 19 Python gates under `tools/`. They do not share a pin:
///
///   · `tools/validate_content.py` and `prepare_take.py` read the joint
///     vocabulary out of **`motion_core-v0.5.0`** (by `git show` against the
///     core repo), and every reference artifact records `corePin:
///     motion_core-v0.5.0`;
///   · the app and this engine run on **motion_core 0.11.0**.
///
/// That divergence is legitimate — an artifact is built once and read later —
/// but until now NOTHING compared the two. `end_to_end_test` asserted only that
/// `provenance['corePin']` was non-null: the pin was written and never read,
/// the exact class R12 named in this repo (C-175).
///
/// WHY IT MATTERS, AND WHY IT WOULD HAVE BEEN SILENT
/// -------------------------------------------------
/// `cycleDistance` skips a joint the other side does not have:
///
///     final List<double>? other = b[j];
///     if (other == null) continue;
///
/// So if the core renamed a joint between 0.5.0 and 0.11.0, this engine would
/// look for a key no artifact carries, skip it, and go on **measuring fewer
/// joints with no error at all** — a weaker judgement wearing the same number.
/// The pins may drift; the VOCABULARY may not.
void main() {
  final Directory repo = _findRepoRoot();

  List<File> references() => Directory('${repo.path}/content/references')
      .listSync()
      .whereType<File>()
      .where((File f) =>
          f.path.endsWith('.json') &&
          !f.path.endsWith('decisions.json') &&
          !f.path.contains('.keyset-baseline'))
      .toList();

  test('there are artifacts to check', () {
    expect(references(), isNotEmpty,
        reason: 'no reference found — every assertion below would be vacuous');
  });

  test('EVERY joint this engine names exists in EVERY shipped reference', () {
    // The union of what the engine reaches for by name. If the core's
    // vocabulary moved under us, these are the names that would silently miss.
    final Set<String> engineNames = <String>{
      ...orientationJoints,
      ...legJoints,
    };
    expect(engineNames, isNotEmpty);

    for (final File f in references()) {
      final Map<String, dynamic> doc =
          (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>();
      final Set<String> artifact =
          ((doc['scoring'] as Map).cast<String, dynamic>()).keys.toSet();

      final Set<String> missing = engineNames.difference(artifact);
      expect(missing, isEmpty,
          reason: '${f.uri.pathSegments.last} does not carry $missing. '
              'cycleDistance would SKIP those joints silently and keep '
              'reporting a number — a weaker judgement that looks identical.');
    }
  });

  test('the artifact pin is RECORDED and matches across artifacts', () {
    // Not "equal to the app's pin" — they are legitimately different. What
    // must hold is that every artifact was built by the SAME core, or two
    // references disagree about the geometry they encode.
    final Set<String> pins = <String>{};
    for (final File f in references()) {
      final Map<String, dynamic> doc =
          (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>();
      final Object? pin = doc['corePin'];
      expect(pin, isNotNull,
          reason: '${f.uri.pathSegments.last} records no corePin — its '
              'geometry cannot be traced to a core version');
      pins.add('$pin');
    }
    expect(pins, hasLength(1),
        reason: 'references were built by DIFFERENT cores: $pins. Two '
            'artifacts encoding different geometry are compared by the same '
            'judge.');
  });

  test('the Python side and the artifacts agree on which core built them', () {
    // The third runner declares its pin in source. If someone bumps the tool
    // without rebuilding artifacts (or vice versa), this is where it shows.
    final String tool =
        File('${repo.path}/tools/validate_content.py').readAsStringSync();
    final RegExpMatch? m =
        RegExp(r'CORE_PIN\s*=\s*"([^"]+)"').firstMatch(tool);
    expect(m, isNotNull,
        reason: 'the Python gate no longer declares CORE_PIN — this check is '
            'measuring nothing');

    final Map<String, dynamic> any = (jsonDecode(
            references().first.readAsStringSync()) as Map)
        .cast<String, dynamic>();
    expect(any['corePin'], m!.group(1),
        reason: 'the Python pipeline is pinned to ${m.group(1)} but the '
            'artifacts on disk were built by ${any['corePin']}. One of them '
            'moved without the other.');
  });
}

Directory _findRepoRoot() {
  Directory d = Directory.current;
  while (!File('${d.path}/pubspec.yaml').existsSync() ||
      !Directory('${d.path}/content').existsSync()) {
    final Directory up = d.parent;
    if (up.path == d.path) throw StateError('repo root not found');
    d = up;
  }
  return d;
}
