import 'dart:convert';

/// App-local written study; no scoring, journal or completion mutation.
class LineDanceCourse {
  LineDanceCourse._(this.copy, this.units);
  final Map<String, Map<String, String>> copy;
  final List<LineDanceUnit> units;
  static const fields = [
    'title',
    'reviewNotice',
    'boundaries',
    'startCompetency',
    'endCompetency',
    'provenance',
    'diagramNotice'
  ];
  static const gates = [
    'scoring',
    'progressWrites',
    'paidAccess',
    'mediaRightsAccepted',
    'modelVerified',
    'physicalInstructionAccepted',
    'completeCurriculumAccepted'
  ];
  factory LineDanceCourse.decode(String source) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    if (raw['schemaVersion'] != 1 ||
        raw['version'] != 2 ||
        raw['id'] != 'line_dance_beginner_written') {
      throw const FormatException('Unsupported written Line Dance course');
    }
    final acceptance = raw['acceptance'] as Map<String, dynamic>;
    if (gates.any((key) => acceptance[key] != false)) {
      throw const FormatException(
          'Written course cannot open acceptance gates');
    }
    final units = (raw['units'] as List<dynamic>)
        .map((u) => LineDanceUnit(u as Map<String, dynamic>))
        .toList(growable: false);
    if (units.length != 9) {
      throw const FormatException('Incomplete written endpoint');
    }
    for (var n = 0; n < units.length; n++) {
      if (units[n].id != 'ld_0${n + 1}' ||
          units[n].prerequisiteIds.join(',') != (n == 0 ? '' : 'ld_0$n')) {
        throw const FormatException('Broken ordered prerequisites');
      }
    }
    final finalTask = raw['finalTaskContract'] as Map<String, dynamic>;
    if (finalTask['beats'] != 24 ||
        finalTask['evidence'] != 'self_observation_only' ||
        finalTask['crossingSubstituteIsPhysicalCrossing'] != false ||
        finalTask['seatedIsPhysical'] != false ||
        finalTask['planChangeRequiresFreshA'] != true ||
        finalTask['extendedBeatsPerWall'] != 32 ||
        finalTask['actualTurnEligible'] != false ||
        finalTask['completePhysicalEndpoint'] != false) {
      throw const FormatException('Unsupported self-observation task');
    }
    return LineDanceCourse._(pairs(raw, fields), units);
  }
  static Map<String, Map<String, String>> pairs(
          Map<String, dynamic> raw, List<String> keys) =>
      {
        for (final key in keys)
          key: {
            for (final lang in ['en', 'tr'])
              lang: text((raw[key] as Map<String, dynamic>)[lang])
          }
      };
  static String text(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Missing course text');
    }
    return value;
  }
}

class LineDanceUnit {
  LineDanceUnit(Map<String, dynamic> raw)
      : id = LineDanceCourse.text(raw['id']),
        prerequisiteIds = (raw['prerequisiteIds'] as List<dynamic>)
            .map(LineDanceCourse.text)
            .toList(growable: false),
        copy = LineDanceCourse.pairs(raw, [
          ...fields,
          if (raw.containsKey('exercise') || raw.containsKey('answer')) ...[
            'exercise',
            'answer'
          ]
        ]);
  List<String> get displayFields => [
        ...fields,
        if (copy.containsKey('exercise')) ...['exercise', 'answer']
      ];
  final String id;
  final List<String> prerequisiteIds;
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
    'diagram'
  ];
}
