import 'dart:convert';

/// App-local written study. No scoring, progress or physical completion mutation.
class LatinFusionCourse {
  LatinFusionCourse._(
    this.copy,
    this.units,
    this.patterns,
    this.directions,
    this.openTeaching,
  );
  final Map<String, Map<String, String>> copy;
  final List<LatinFusionUnit> units;
  final Map<String, LatinFusionPattern> patterns;
  final Map<String, Map<String, String>> directions;
  final List<Map<String, String>> openTeaching;
  static const fields = [
    'title',
    'reviewNotice',
    'scope',
    'boundaries',
    'startCompetency',
    'endCompetency',
    'salsaSeparation',
    'musicAndObservation',
    'diagramNotice',
    'provenance',
  ];
  static const gates = [
    'writtenProposalIndependentlyAccepted',
    'appIntegrated',
    'softwareQualified',
    'physicalTeachingAccepted',
    'completeCurriculumAccepted',
    'scoring',
    'progressWrites',
    'paidAccess',
    'mediaRightsAccepted',
    'modelVerified',
    'physicalInstructionAccepted',
  ];
  factory LatinFusionCourse.decode(String source) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    require(
      raw['schemaVersion'] == 1 &&
          raw['version'] == 1 &&
          raw['id'] == 'latin_fusion_beginner_written' &&
          raw['catalogStyleId'] == 'latin_fusion_fitness' &&
          raw['status'] == 'written_integration_candidate',
    );
    final acceptance = raw['acceptance'] as Map<String, dynamic>;
    require(gates.every((key) => acceptance[key] == false));
    final units = (raw['units'] as List<dynamic>)
        .map((u) => LatinFusionUnit(u as Map<String, dynamic>))
        .toList();
    require(units.length == 10);
    String unitId(int number) => 'lf_${number.toString().padLeft(2, '0')}';
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
    final patterns = <String, LatinFusionPattern>{};
    for (final row in raw['patterns'] as List<dynamic>) {
      final pattern = LatinFusionPattern(row as Map<String, dynamic>);
      require(!patterns.containsKey(pattern.id));
      patterns[pattern.id] = pattern;
    }
    require(patterns.keys.join(',') == 'M,S,T,C,M-side,P');
    for (final unit in units) {
      require(unit.patternIds.every(patterns.containsKey));
    }
    final task = raw['finalTaskContract'] as Map<String, dynamic>;
    require(
      task['beats'] == 32 &&
          task['startSupport'] == 'R' &&
          task['startFree'] == 'L' &&
          task['endSupport'] == 'R' &&
          task['nextFree'] == 'L' &&
          task['facing'] == 'front' &&
          task['evidence'] == 'self_observation_only' &&
          task['physicalTeachingAccepted'] == false &&
          task['completeCurriculumAccepted'] == false &&
          task['conditionChangeStartsNewFirst'] == true &&
          task['pulseExcludedFrom32'] == true &&
          (task['defaultPatternOrder'] as List).join(',') == 'M,S,T,C' &&
          (task['explicitSubstitutionOrder'] as List).join(',') == 'M,S,T,T',
    );
    final directions = pairs(
      raw['notation']['directions'] as Map<String, dynamic>,
      LatinFusionPattern.directionNames,
    );
    final gaps = (raw['openTeachingComponents'] as List<dynamic>).map((gap) {
      require(gap['physicalAccepted'] == false);
      return pairs(gap as Map<String, dynamic>, ['copy'])['copy']!;
    }).toList();
    require(gaps.length == 3);
    return LatinFusionCourse._(
      pairs(raw, fields),
      units,
      patterns,
      directions,
      gaps,
    );
  }
  static void require(bool condition) {
    if (!condition) {
      throw const FormatException('Unsupported written Latin Fusion contract');
    }
  }

  static String text(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Missing written Latin Fusion text');
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

class LatinFusionUnit {
  LatinFusionUnit(Map<String, dynamic> raw)
    : id = LatinFusionCourse.text(raw['id']),
      prerequisiteIds = (raw['prerequisiteIds'] as List<dynamic>)
          .map(LatinFusionCourse.text)
          .toList(),
      patternIds = (raw['patternIds'] as List<dynamic>)
          .map(LatinFusionCourse.text)
          .toList(),
      copy = LatinFusionCourse.pairs(raw, [
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

class LatinFusionPattern {
  LatinFusionPattern(Map<String, dynamic> raw)
    : id = LatinFusionCourse.text(raw['id']),
      copy = LatinFusionCourse.pairs(raw, ['title', 'originality']),
      rows = (raw['rows'] as List<dynamic>)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList() {
    final pulse = id == 'P';
    var support = pulse ? 'B' : 'R';
    LatinFusionCourse.require(
      rows.length == 8 &&
          raw['startSupport'] == support &&
          raw['startFree'] == (pulse ? null : 'L') &&
          raw['endSupport'] == support &&
          raw['nextFree'] == (pulse ? null : 'L') &&
          raw['physicalTeachingReviewed'] != true,
    );
    const expectedActions = {
      'M': 'W,W,W,W,W,W,W,W',
      'M-side': 'W,W,W,W,W,W,W,W',
      'S': 'W,W,W,H,W,W,W,H',
      'C': 'W,W,W,H,W,W,W,H',
      'T': 'W,T,W,T,W,T,W,T',
      'P':
          'P_bend,P_release,P_bend,P_release,P_bend,P_release,P_bend,P_release',
    };
    LatinFusionCourse.require(
      rows.map((r) => r['action']).join(',') == expectedActions[id],
    );
    const expectedDirections = {
      'M': 'in_place,in_place,in_place,in_place,in_place,in_place,in_place,in_place',
      'S': 'left,in_place,near,in_place,right,in_place,near,in_place',
      'T': 'left,near,right,near,left,near,right,near',
      'C': 'back,in_place,near,in_place,back,in_place,near,in_place',
      'M-side': 'left,in_place,near,in_place,in_place,right,in_place,near',
      'P': 'in_place,in_place,in_place,in_place,in_place,in_place,in_place,in_place',
    };
    LatinFusionCourse.require(
      rows.map((r) => r['direction']).join(',') == expectedDirections[id],
    );
    for (var n = 0; n < rows.length; n++) {
      final row = rows[n];
      final foot = row['foot'];
      final action = row['action'];
      LatinFusionCourse.require(
        row['count'] == n + 1 &&
            row['facing'] == 'front' &&
            directionNames.contains(row['direction']),
      );
      if (pulse) {
        LatinFusionCourse.require(
          foot == 'BOTH' && row['direction'] == 'in_place',
        );
      } else if (action == 'W') {
        LatinFusionCourse.require(
          (foot == 'L' || foot == 'R') && foot != support,
        );
        support = foot as String;
      } else if (action == 'T') {
        LatinFusionCourse.require(
          (foot == 'L' || foot == 'R') && foot != support,
        );
      } else {
        LatinFusionCourse.require(action == 'H' && foot == '—');
      }
      LatinFusionCourse.require(row['supportAfter'] == support);
    }
    LatinFusionCourse.require(support == (pulse ? 'B' : 'R'));
  }
  final String id;
  final Map<String, Map<String, String>> copy;
  final List<Map<String, dynamic>> rows;
  static const directionNames = [
    'front',
    'back',
    'left',
    'right',
    'near',
    'in_place',
  ];
}
