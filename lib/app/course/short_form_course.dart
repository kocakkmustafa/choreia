import 'dart:convert';

/// App-local written study. No scoring, progress or physical completion mutation.
class ShortFormCourse {
  ShortFormCourse._(
    this.copy,
    this.units,
    this.patterns,
    this.directions,
    this.openTeaching,
    this.gestures,
  );
  final Map<String, Map<String, String>> copy;
  final List<ShortFormUnit> units;
  final Map<String, ShortFormPattern> patterns;
  final Map<String, Map<String, String>> directions;
  final List<Map<String, String>> openTeaching;
  final Map<String, Map<String, String>> gestures;
  static const fields = ["title", "reviewNotice", "scope", "boundaries", "startCompetency", "endCompetency", "catalogBoundary", "soundAndObservation", "diagramNotice", "provenance"];
  static const gates = ["writtenProposalIndependentlyAccepted", "appIntegrated", "softwareQualified", "physicalTeachingAccepted", "completeCurriculumAccepted", "scoring", "progressWrites", "paidAccess", "mediaRightsAccepted", "modelVerified"];
  factory ShortFormCourse.decode(String source) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    require(
      raw['schemaVersion'] == 1 &&
          raw['version'] == 1 &&
          raw['id'] == 'original_short_form_beginner_written' &&
          raw['catalogStyleId'] == 'tiktok_format' &&
          raw['status'] == 'written_integration_candidate',
    );
    final acceptance = raw['acceptance'] as Map<String, dynamic>;
    require(gates.every((key) => acceptance[key] == false));
    final units = (raw['units'] as List<dynamic>)
        .map((u) => ShortFormUnit(u as Map<String, dynamic>))
        .toList();
    require(units.length == 10);
    String unitId(int number) => 'sf_${number.toString().padLeft(2, '0')}';
    for (var n = 0; n < units.length; n++) {
      require(
        units[n].id == unitId(n + 1) &&
            units[n].prerequisiteIds.join(',') == (n == 0 ? '' : unitId(n)),
      );
    }
    require(
      units[1].copy.containsKey('exercise') &&
          units[1].copy.containsKey('answer'),
    );
    final patterns = <String, ShortFormPattern>{};
    for (final row in raw['patterns'] as List<dynamic>) {
      final pattern = ShortFormPattern(row as Map<String, dynamic>);
      require(!patterns.containsKey(pattern.id));
      patterns[pattern.id] = pattern;
    }
    require(patterns.keys.join(',') == 'A,A-var,B');
    for (final unit in units) {
      require(unit.patternIds.every(patterns.containsKey));
    }
    final task = raw['finalTaskContract'] as Map<String, dynamic>;
    require(task['beats'] == 16 &&
      task['learnerAuthored'] == true &&
      task['merelyRenamingWorkedExampleEligible'] == false &&
      task['motifCounts'] == 4 &&
      task['requiresOneExplainedVariation'] == true &&
      task['requiresContrastingSecondBlock'] == true &&
      task['startSupport'] == "R" &&
      task['startFree'] == "L" &&
      task['endSupport'] == "R" &&
      task['nextFree'] == "L" &&
      task['facing'] == "front" &&
      task['evidence'] == "self_observation_only" &&
      task['cameraRequired'] == false &&
      task['uploadRequired'] == false &&
      task['accountRequired'] == false &&
      task['conditionChangeStartsNewFirst'] == true &&
      task['physicalTeachingAccepted'] == false &&
      task['completeCurriculumAccepted'] == false &&
      jsonEncode(units[1].copy['exercise']) == "{\"en\":\"Start support R, L free, FRONT. 1: L takes a small weighted forward step. 2: no new step. 3: R touches near without weight. 4: R takes a small weighted step to your right. Write W/T/H, support after each row and next available foot. Does 3 add a transfer?\",\"tr\":\"Sağ destek/sol boş, ÖN başla. 1: sol küçük ağırlıklı ön adım. 2: yeni adım yok. 3: sağ ağırlıksız yakına dokunur. 4: sağ kendi sağına küçük ağırlıklı adım. W/T/H, her satır sonrası destek ve sonraki hazır ayağı yaz. 3 aktarım ekler mi?\"}" &&
      jsonEncode(units[1].copy['answer']) == "{\"en\":\"Actions W/H/T/W; support L/L/L/R; next L. Count 3 adds no transfer. If it takes weight, R is not free for 4; revisit 2–3 without inventing a new step.\",\"tr\":\"Eylemler W/H/T/W; destek sol/sol/sol/sağ; sonraki sol. 3 aktarım eklemez. Ağırlık alırsa 4 için sağ boş değildir; yeni adım uydurmadan 2–3e dön.\"}");
    final sources = raw['sources'] as List<dynamic>;
    require(sources.length == 7);
    require(sources[0]['id'] == "choreography_education" && sources[0]['url'] == "https://www.aqa.org.uk/subjects/dance/gcse/dance-8236/specification/subject-content/choreography" && sources[0]['mediaCopied'] == false && sources[0]['endorsement'] == false);
    require(sources[1]['id'] == "rehearsal_education" && sources[1]['url'] == "https://www.aqa.org.uk/subjects/dance/gcse/dance-8236/specification/subject-content/performance" && sources[1]['mediaCopied'] == false && sources[1]['endorsement'] == false);
    require(sources[2]['id'] == "touch_primary" && sources[2]['url'] == "https://howcast.com/videos/497833-how-to-do-touch-steps-line-dancing/" && sources[2]['mediaCopied'] == false && sources[2]['endorsement'] == false);
    require(sources[3]['id'] == "hold_primary" && sources[3]['url'] == "https://www.mathiasellmann.de/en/salsa/movement-lexicon/pause-hold.html" && sources[3]['mediaCopied'] == false && sources[3]['endorsement'] == false);
    require(sources[4]['id'] == "safe_dance_primary" && sources[4]['url'] == "https://ausdance.org.au/articles/details/warm-up-and-cool-down-rules-for-safe-dance" && sources[4]['mediaCopied'] == false && sources[4]['endorsement'] == false);
    require((raw['units'][0]['sourceIds'] as List).join(',') == "choreography_education,safe_dance_primary" && units[0].patternIds.join(',') == "");
    require((raw['units'][1]['sourceIds'] as List).join(',') == "touch_primary,hold_primary" && units[1].patternIds.join(',') == "A");
    require((raw['units'][2]['sourceIds'] as List).join(',') == "choreography_education,touch_primary" && units[2].patternIds.join(',') == "A");
    require((raw['units'][3]['sourceIds'] as List).join(',') == "choreography_education,hold_primary" && units[3].patternIds.join(',') == "A,A-var,B");
    require((raw['units'][4]['sourceIds'] as List).join(',') == "rehearsal_education,hold_primary,safe_dance_primary" && units[4].patternIds.join(',') == "A,B");
    require((raw['units'][5]['sourceIds'] as List).join(',') == "choreography_education,touch_primary,hold_primary" && units[5].patternIds.join(',') == "");
    require((raw['units'][6]['sourceIds'] as List).join(',') == "rehearsal_education,safe_dance_primary" && units[6].patternIds.join(',') == "");
    require(sources[5]['id'] == "ticking_primary" && sources[5]['url'] == "http://www.howcast.com/videos/499518-How-to-Do-the-Ticking-Dance-Move-HipHop-Howto" && sources[5]['mediaCopied'] == false && sources[5]['endorsement'] == false);
    require(sources[6]['id'] == "body_roll_primary" && sources[6]['url'] == "http://www.howcast.com/videos/505195-How-to-Do-Body-Rolls-HipHop-Dancing" && sources[6]['mediaCopied'] == false && sources[6]['endorsement'] == false);
    require((raw['units'][7]['sourceIds'] as List).join(',') == "ticking_primary,hold_primary,safe_dance_primary" && units[7].patternIds.join(',') == "A");
    require((raw['units'][8]['sourceIds'] as List).join(',') == "ticking_primary,choreography_education,safe_dance_primary" && units[8].patternIds.join(',') == "B");
    require((raw['units'][9]['sourceIds'] as List).join(',') == "body_roll_primary,rehearsal_education,safe_dance_primary" && units[9].patternIds.join(',') == "");
    require(units.where((u) => u.copy.containsKey('answer')).length == 1);
    final gestures = pairs(raw['gestureLegend'] as Map<String, dynamic>, ShortFormPattern.gestureNames);
    final directions = pairs(
      raw['notation']['directions'] as Map<String, dynamic>,
      ShortFormPattern.directionNames,
    );
    require(raw['openTeachingComponents'][0]['id'] == "body_roll" && raw['openTeachingComponents'][0]['status'] == "written_bounded_unit_physical_review_open");
    require(raw['openTeachingComponents'][1]['id'] == "sharp_hit" && raw['openTeachingComponents'][1]['status'] == "written_bounded_unit_physical_review_open");
    require(raw['openTeachingComponents'][2]['id'] == "arm_run_coordination" && raw['openTeachingComponents'][2]['status'] == "written_bounded_unit_physical_review_open");
    require(raw['openTeachingComponents'][3]['id'] == "media_and_cultural_context" && raw['openTeachingComponents'][3]['status'] == "rights_and_context_open");
    final gaps = (raw['openTeachingComponents'] as List<dynamic>).map((gap) {
      require(gap['status'] == 'written_bounded_unit_physical_review_open' || gap['status'] == 'rights_and_context_open');
      return pairs(gap as Map<String, dynamic>, ['copy'])['copy']!;
    }).toList();
    require(gaps.length == 4);
    return ShortFormCourse._(
      pairs(raw, fields),
      units,
      patterns,
      directions,
      gaps,
      gestures,
    );
  }
  static void require(bool condition) {
    if (!condition) {
      throw const FormatException('Unsupported written original short-form contract');
    }
  }

  static String text(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Missing written original short-form text');
    }
    return value;
  }

  static Map<String, Map<String, String>> pairs(
    Map<String, dynamic> raw,
    List<String> keys,
  ) => {
    for (final key in keys)
      key: {
        for (final lang in ['en', 'tr'])
          lang: text((raw[key] as Map<String, dynamic>)[lang]),
      },
  };
}

class ShortFormUnit {
  ShortFormUnit(Map<String, dynamic> raw)
    : id = ShortFormCourse.text(raw['id']),
      prerequisiteIds = (raw['prerequisiteIds'] as List<dynamic>)
          .map(ShortFormCourse.text)
          .toList(),
      patternIds = (raw['patternIds'] as List<dynamic>)
          .map(ShortFormCourse.text)
          .toList(),
      copy = ShortFormCourse.pairs(raw, [
        ...fields,
        if (raw.containsKey('exercise') || raw.containsKey('answer')) ...[
          'exercise',
          'answer',
        ],
      ]);
  final String id;
  final List<String> prerequisiteIds;
  final List<String> patternIds;
  final Map<String, Map<String, String>> copy;
  static const fields = [
    'title',
    'prerequisite',
    'outcome',
    'instruction',
    'practice',
    'mistakes',
    'adaptation',
    'check',
  ];
  List<String> get displayFields => [
    ...fields,
    if (copy.containsKey('exercise')) ...['exercise', 'answer'],
  ];
}

class ShortFormPattern {
  ShortFormPattern(Map<String, dynamic> raw)
    : id = ShortFormCourse.text(raw['id']),
      copy = ShortFormCourse.pairs(raw, ['title', 'originality']),
      rows = (raw['rows'] as List<dynamic>)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList() {
    const expectedRows = {"A": "[{\"count\":1,\"foot\":\"L\",\"action\":\"W\",\"direction\":\"left\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"right_reach_low\"},{\"count\":2,\"foot\":\"R\",\"action\":\"T\",\"direction\":\"near\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":3,\"foot\":\"—\",\"action\":\"H\",\"direction\":\"in_place\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":4,\"foot\":\"R\",\"action\":\"W\",\"direction\":\"near\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":5,\"foot\":\"L\",\"action\":\"T\",\"direction\":\"near\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":6,\"foot\":\"—\",\"action\":\"H\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":7,\"foot\":\"L\",\"action\":\"W\",\"direction\":\"in_place\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":8,\"foot\":\"R\",\"action\":\"W\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"}]", "A-var": "[{\"count\":1,\"foot\":\"L\",\"action\":\"W\",\"direction\":\"left\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"right_reach_start_low\"},{\"count\":2,\"foot\":\"R\",\"action\":\"T\",\"direction\":\"near\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"right_reach_arrive_low\"},{\"count\":3,\"foot\":\"—\",\"action\":\"H\",\"direction\":\"in_place\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"return_low\"},{\"count\":4,\"foot\":\"R\",\"action\":\"W\",\"direction\":\"near\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":5,\"foot\":\"L\",\"action\":\"T\",\"direction\":\"near\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":6,\"foot\":\"—\",\"action\":\"H\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":7,\"foot\":\"L\",\"action\":\"W\",\"direction\":\"in_place\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":8,\"foot\":\"R\",\"action\":\"W\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"}]", "B": "[{\"count\":1,\"foot\":\"—\",\"action\":\"H\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":2,\"foot\":\"L\",\"action\":\"W\",\"direction\":\"front\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":3,\"foot\":\"R\",\"action\":\"W\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":4,\"foot\":\"L\",\"action\":\"W\",\"direction\":\"near\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":5,\"foot\":\"R\",\"action\":\"T\",\"direction\":\"near\",\"supportAfter\":\"L\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":6,\"foot\":\"R\",\"action\":\"W\",\"direction\":\"right\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"right_reach_low\"},{\"count\":7,\"foot\":\"L\",\"action\":\"T\",\"direction\":\"near\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"},{\"count\":8,\"foot\":\"—\",\"action\":\"H\",\"direction\":\"in_place\",\"supportAfter\":\"R\",\"facing\":\"front\",\"optionalGesture\":\"rest\"}]"};
    ShortFormCourse.require(
      raw['original'] == true && raw['physicalTeachingAccepted'] == false &&
      raw['startSupport'] == 'R' && raw['startFree'] == 'L' &&
      raw['endSupport'] == 'R' && raw['nextFree'] == 'L' &&
      rows.length == 8 && jsonEncode(rows) == expectedRows[id],
    );
    var support = 'R';
    for (var n = 0; n < rows.length; n++) {
      final row = rows[n];
      final foot = row['foot'];
      final action = row['action'];
      ShortFormCourse.require(row['count'] == n + 1 && row['facing'] == 'front' &&
        directionNames.contains(row['direction']) && gestureNames.contains(row['optionalGesture']));
      if (action == 'W') {
        ShortFormCourse.require((foot == 'L' || foot == 'R') && foot != support);
        support = foot as String;
      } else if (action == 'T') {
        ShortFormCourse.require((foot == 'L' || foot == 'R') && foot != support);
      } else {
        ShortFormCourse.require(action == 'H' && foot == '—');
      }
      ShortFormCourse.require(row['supportAfter'] == support);
    }
    ShortFormCourse.require(support == 'R');
  }
  final String id;
  final Map<String, Map<String, String>> copy;
  final List<Map<String, dynamic>> rows;
  static const directionNames = ["left", "right", "front", "near", "in_place"];
  static const gestureNames = ["rest", "right_reach_low", "right_reach_start_low", "right_reach_arrive_low", "return_low"];
}
