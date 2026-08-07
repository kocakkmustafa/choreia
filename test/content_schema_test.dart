import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Does the app READ what content WRITES, and write what it reads?
///
/// The open debt this closes was stated as "verify the style page's
/// attribution/glossary fields actually exist in content". Measuring that they
/// are POPULATED (C-151) is only half of it. The other half is the pair of
/// silent failures either side:
///
///   · a DEAD READ  — the parser pulls a key nothing in content ever sets, so
///     the surface renders a permanent blank and no test notices, because
///     "absent" is a legal state everywhere in this app;
///   · a DEAD WRITE — content carries a key no surface reads, so writing it
///     feels like progress and changes nothing a dancer sees. R12 named this
///     class in this repo already ("yazılmış ama OKUNMAMIŞ alan"), and C-130
///     found a real one.
///
/// Both are invisible to every other test here, and both get more likely as 32
/// styles' worth of content is written.
void main() {
  Map<String, dynamic> library() =>
      (jsonDecode(File('content/library.json').readAsStringSync()) as Map)
          .cast<String, dynamic>();

  /// Every key any style entry actually sets.
  Set<String> keysInContent() {
    final Set<String> out = <String>{};
    for (final Object? s in (library()['styles'] as List)) {
      out.addAll((s as Map).keys.cast<String>());
    }
    return out;
  }

  /// Every key `LibraryEntry.fromJson` pulls out, read from the parser itself
  /// rather than restated here (C-153): a hand-copied list of "keys we parse"
  /// stops matching the parser the first time someone edits it.
  Set<String> keysParsed() {
    final String src =
        File('lib/app/library/library_catalog.dart').readAsStringSync();
    final int start = src.indexOf('factory LibraryEntry.fromJson');
    expect(start, greaterThan(-1),
        reason: 'the parser was renamed — this scan is now measuring nothing');
    final int end = src.indexOf('\n  final String id;', start);
    final String body = src.substring(start, end > start ? end : src.length);
    return RegExp(r"json\['(\w+)'\]")
        .allMatches(body)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();
  }

  test('the two scans find something before they are compared', () {
    expect(keysInContent().length, greaterThan(5));
    expect(keysParsed().length, greaterThan(5));
  });

  test('NO DEAD READ: every key the parser pulls is set by some style', () {
    final Set<String> orphaned = keysParsed().difference(keysInContent());
    expect(orphaned, isEmpty,
        reason: 'the parser reads $orphaned, which no style in content sets. '
            'Either content lost a field or the parser is looking for a name '
            'nobody writes — and the surface renders a permanent blank either '
            'way, because absence is a legal state on every one of these.');
  });

  test('NO DEAD WRITE: every key content sets is read by the app', () {
    // Keys deliberately NOT read by any surface, each with its reason. These
    // are content-side bookkeeping, and rendering them would leak authoring
    // state to a dancer.
    const Map<String, String> notForTheSurface = <String, String>{
      'status': 'read as `contentStatus`, via a different name',
      'name': 'read as `displayName`, via a different name',
      'wave': 'ROLLOUT ORDER — parsed but deliberately never rendered; showing '
          'it would turn a build sequence into a queue promise',
      'note': 'authoring notes, in Turkish, addressed to us',
      'statusNote': 'same — a correction log, not copy',
      'contentOnDisk': 'redundant with whether style.json loads; the loader is '
          'the truth',
      'demoOnly': 'a PLAN note about a style not yet built ("these moves will '
          'not be scored"), not a lesson state — library.json says so itself',
      'scoring': 'engine selector, not user-facing',
      'countSystem': 'engine selector, not user-facing',
      'legalFlag': 'clearance triage for us; the user-facing half is the '
          'attribution box and the reproduction boundary',
      'policyBucket': 'store-policy triage',
      'cautionClass': 'internal severity tag; the user-facing half is the '
          'safety copy',
      'isFamilyPage': 'implied to the reader by subDances being present',
      'trendPack': 'curation grouping',
      'seasonal': 'curation grouping',
      'id': 'the key itself',
    };

    final Set<String> unread =
        keysInContent().difference(keysParsed()).difference(
            notForTheSurface.keys.toSet());

    expect(unread, isEmpty,
        reason: 'content sets $unread and nothing reads it. Writing it feels '
            'like progress and changes nothing a dancer sees — the "written '
            'but never READ field" class (R12). Either render it, or record '
            'here why it is ours and not theirs.');
  });

  test('the not-for-surface list describes reality, not a memory', () {
    // Same discipline as `knownUnshipped` (C-153): an exemption that outlives
    // the thing it exempts is folklore.
    const Set<String> listed = <String>{
      'status', 'name', 'wave', 'note', 'statusNote', 'contentOnDisk',
      'demoOnly', 'scoring', 'countSystem', 'legalFlag', 'policyBucket',
      'cautionClass', 'isFamilyPage', 'trendPack', 'seasonal', 'id',
    };
    final Set<String> stale = listed.difference(keysInContent());
    expect(stale, isEmpty,
        reason: '$stale is exempted from the dead-write check but no style '
            'sets it any more — remove the entry rather than carrying a '
            'ruling about nothing');
  });
}
