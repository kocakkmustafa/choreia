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
      'attributionSources': 'OUR bookkeeping, not a badge. The provenance '
          'block\'s own surfaceRule forbids the screen from claiming '
          'verification, so a source list that reached the surface would turn '
          'a record into a guarantee nobody made. Dead on purpose, and this '
          'entry is the declaration that it is (C-198)',
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

  group('ORPHAN KEYS in style/step documents (C-167)', () {
    // The gate above covers `library.json` only — my own scope note in
    // KAPI-ENVANTERI said so. That left 4 parsers and 12 files unmeasured, and
    // an unread key is where refuted claims survive (J-129): `errors[].severity`
    // sat there carrying the very severity ladder C-136 declared not to exist,
    // and `whyPermanent` carried 11 lessons' worth of learner copy nobody saw.

    Set<String> readsOf(String variable) {
      final String src = File('lib/app/course_catalog.dart').readAsStringSync() +
          File('lib/app/library/library_catalog.dart').readAsStringSync();
      return RegExp("\\b$variable\\['(\\w+)'\\]")
          .allMatches(src)
          .map((RegExpMatch m) => m.group(1)!)
          .toSet();
    }

    /// Keys of a nested MAP (not a list), e.g. `honesty` / `copyright`.
    Set<String> keysInMap(String glob, String key) {
      final Set<String> out = <String>{};
      for (final FileSystemEntity e
          in Directory('content/styles').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.json')) continue;
        if (glob == 'style' && !e.path.endsWith('style.json')) continue;
        final Map<String, dynamic> doc =
            (jsonDecode(e.readAsStringSync()) as Map).cast<String, dynamic>();
        final Object? node = doc[key];
        if (node is Map) out.addAll(node.keys.cast<String>());
      }
      return out;
    }

    Set<String> keysAt(String glob, List<String> path) {
      final Set<String> out = <String>{};
      final Directory dir = Directory('content/styles');
      for (final FileSystemEntity e in dir.listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.json')) continue;
        if (glob == 'style' && !e.path.endsWith('style.json')) continue;
        if (glob == 'step' && !e.path.contains('/steps/')) continue;
        final Map<String, dynamic> doc =
            (jsonDecode(e.readAsStringSync()) as Map).cast<String, dynamic>();
        for (final Map<String, dynamic> node in _walk(doc, path)) {
          out.addAll(node.keys);
        }
      }
      return out;
    }

    /// Keys deliberately not parsed, each with the reason. Engine config,
    /// authoring provenance and harvest bookkeeping are OURS; rendering them
    /// would leak internal state to a dancer.
    const Map<String, String> ours = <String, String>{
      'schemaVersion': 'format version',
      'id': 'the key itself', 'name': 'read via displayName',
      'style': 'back-reference', 'level': 'read on the level node',
      'status': 'lesson kind is derived from scored/demoOnly; see the '
          'consistency check below',
      'note': 'authoring notes', 'evidence': 'provenance',
      'countSystem': 'engine selector', 'scoring': 'engine selector',
      'bpmRange': 'engine input', 'bpmNote': 'authoring note',
      'bpmStatus': 'authoring state', 'bpmCandidates': 'research record',
      'errorTaxonomy': 'authoring inventory',
      'stepInventory': 'authoring inventory',
      'shipGatesNote': 'authoring note',
      'unlockRule': 'DECLARED, NOT IMPLEMENTED — see C-164; nothing may render '
          'it until progression exists',
      'unlockRuleNote': 'authoring note',
      '_whyUnlocked': 'authoring note', 'blockedBy': 'authoring note',
      'demoOnlyClassBasis': 'authoring basis for demoOnlyClass',
      'k10Note': 'authoring note', 'drillFor': 'authoring link',
      'scoredWhat': 'per-lesson honesty — style-level honesty covers it today',
      'notScoredWhat': 'same',
      r'$comment': 'authoring note', 'measuredNote': 'authoring note',
      'basis': 'clearance reasoning; the user-facing half is boundary',
      'beats': 'engine input', 'beatsStatus': 'engine state',
      'countLabels': 'engine input', 'countLabelsNote': 'authoring note',
      'phases': 'engine input', 'scoredMoments': 'engine input',
      'analysisWindow': 'engine input', 'cycleUnit': 'engine input',
      'measurability': 'authoring tier record', 'reference': 'build record',
      'sourceDerivation': 'build record', 'advisorReview': 'review record',
      'omittedFromStyleTaxonomy': 'authoring note',
      'harvestProbe3_reevaluation': 'harvest record',
      'harvestProbe4_footLevel': 'harvest record',
      'detect': 'engine rule', 'measurement': 'engine rule',
      'severity': 'READ BY A TEST, not by the app — it is the derivation basis '
          'for correctionPriority (C-167); the engine ranks codes, content '
          'declares the rungs',
      'relatedDrill': 'authoring link', 'drillNote': 'authoring note',
      'calibrationNote': 'authoring note', 'kural7Note': 'authoring note',
      'firstAttemptFailed': 'authoring record',
      'calibration': 'the DESCRIBED-not-yet-CALIBRATED hold (C-200). Read by '
          '`validate_content`, never by the app: it governs which judgement '
          'fields may be null while a step waits for its reference, and a '
          'dancer must never see authoring state',
      'severityStatus': 'why this error carries no severity yet — the same '
          'hold, per error. Surfacing it would show a blank where a judgement '
          'belongs and invite the reader to supply one',
    };

    test('every orphan key is either read or recorded as ours', () {
      final Map<String, Set<String>> scopes = <String, Set<String>>{
        // `StyleProse.fromJson` reads through `json[...]`, so the style
        // top-level has TWO parsers and both must count. Missing the second
        // one reported `honesty`/`copyright` as orphaned when they are the
        // most-read keys in the file.
        'style.json top': keysAt('style', const <String>[])
            .difference(readsOf('style'))
            .difference(readsOf('json')),
        'honesty{}':
            keysInMap('style', 'honesty').difference(readsOf('honesty')),
        'copyright{}':
            keysInMap('style', 'copyright').difference(readsOf('copyright')),
        'levels[]': keysAt('style', const <String>['levels'])
            .difference(readsOf('level')),
        'lessons[]': keysAt('style', const <String>['levels', 'lessons'])
            .difference(readsOf('l')),
        'steps top': keysAt('step', const <String>[]).difference(readsOf('step')),
        'errors[]':
            keysAt('step', const <String>['errors']).difference(readsOf('code')),
      };

      expect(scopes.values.every((Set<String> s) => true), isTrue);
      expect(keysAt('style', const <String>[]), isNotEmpty,
          reason: 'the walker found nothing — every check below is vacuous');

      final Map<String, List<String>> unexplained = <String, List<String>>{
        for (final MapEntry<String, Set<String>> e in scopes.entries)
          if (e.value.difference(ours.keys.toSet()).isNotEmpty)
            e.key: e.value.difference(ours.keys.toSet()).toList()..sort(),
      };

      expect(unexplained, isEmpty,
          reason: 'content sets these and nothing reads them, and no reason is '
              'recorded: $unexplained. An unread key is where a refuted claim '
              'survives — `errors[].severity` carried the severity ladder '
              'C-136 said did not exist.');
    });

    test('the ours-list describes reality, not a memory', () {
      final Set<String> everywhere = <String>{
        ...keysAt('style', const <String>[]),
        ...keysAt('style', const <String>['levels']),
        ...keysAt('style', const <String>['levels', 'lessons']),
        ...keysAt('step', const <String>[]),
        ...keysAt('step', const <String>['errors']),
        ...keysInMap('style', 'honesty'),
        ...keysInMap('style', 'copyright'),
      };
      final Set<String> stale = ours.keys.toSet().difference(everywhere);
      expect(stale, isEmpty,
          reason: '$stale is exempted but no document sets it any more');
    });

    test('a dropped key never CONTRADICTS what the app derives', () {
      // `lessons[].status` is not parsed — kind comes from scored/demoOnly.
      // They agree today and nothing checked that they must.
      for (final FileSystemEntity e
          in Directory('content/styles').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('style.json')) continue;
        final Map<String, dynamic> doc =
            (jsonDecode(e.readAsStringSync()) as Map).cast<String, dynamic>();
        for (final Object? lv in (doc['levels'] as List? ?? const [])) {
          for (final Object? rl in ((lv! as Map)['lessons'] as List? ?? const [])) {
            final Map<String, dynamic> l = (rl! as Map).cast<String, dynamic>();
            if (l['status'] != 'locked') continue;
            expect(l['scored'], isNot(true),
                reason: '${l['id']} declares status:locked and scored:true — '
                    'the dropped key contradicts the derivation');
            expect(l['demoOnly'], isNot(true),
                reason: '${l['id']} declares status:locked and demoOnly:true');
          }
        }
      }
    });
  });
}

/// Walks `path` (a chain of list-valued keys) and returns the maps found.
List<Map<String, dynamic>> _walk(Map<String, dynamic> doc, List<String> path) {
  if (path.isEmpty) return <Map<String, dynamic>>[doc];
  List<Map<String, dynamic>> level = <Map<String, dynamic>>[doc];
  for (final String key in path) {
    final List<Map<String, dynamic>> next = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> node in level) {
      for (final Object? child in (node[key] as List? ?? const [])) {
        next.add((child! as Map).cast<String, dynamic>());
      }
    }
    level = next;
  }
  return level;
}
