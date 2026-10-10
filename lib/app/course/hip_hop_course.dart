import 'dart:convert';

/// Written study only. It deliberately has no scoring or progress mutation API.
class HipHopCourse {
  HipHopCourse._(this.copy, this.units, this.skillCourse);

  final bool skillCourse;
  List<String> get displayFields => [...fields, if (skillCourse) 'provenance'];

  final Map<String, Map<String, String>> copy;
  final List<HipHopUnit> units;

  static const fields = <String>[
    'title',
    'reviewNotice',
    'boundaries',
    'startCompetency',
    'endCompetency',
  ];

  factory HipHopCourse.decode(String source, {bool skillCourse = false}) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    if (raw['schemaVersion'] != 1 ||
        raw['version'] != 1 ||
        raw['id'] !=
            (skillCourse
                ? 'hip_hop_foundations_skill_course'
                : 'hip_hop_foundations_beginner')) {
      throw const FormatException('Unsupported written course');
    }
    final acceptance = raw['acceptance'] as Map<String, dynamic>;
    if (acceptance['scoring'] != false ||
        acceptance['progressWrites'] != false) {
      throw const FormatException('Written course cannot award progress');
    }
    if (skillCourse) {
      for (final field in [
        'releaseEligible',
        'physicalInstructionAccepted',
        'mediaRightsAccepted',
        'completeCurriculumAccepted'
      ]) {
        if (acceptance[field] != false) {
          throw const FormatException(
              'Unreviewed course cannot release instruction');
        }
      }
    }
    final units = (raw['units'] as List<dynamic>)
        .map((value) => HipHopUnit.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
    if (units.isEmpty ||
        units.map((u) => u.id).toSet().length != units.length) {
      throw const FormatException('Empty or duplicate curriculum');
    }
    for (var index = 0; index < units.length; index++) {
      final expected = index == 0 ? <String>[] : [units[index - 1].id];
      final actual = units[index].prerequisiteIds;
      if (actual.length != expected.length ||
          (expected.isNotEmpty && actual.single != expected.single)) {
        throw const FormatException('Broken curriculum prerequisites');
      }
    }
    if (skillCourse &&
        (units.length != 8 ||
            units.first.id != 'hhs_01' ||
            units.last.id != 'hhs_08')) {
      throw const FormatException('Incomplete skill course endpoint');
    }
    return HipHopCourse._(
        _copy(raw, [...fields, if (skillCourse) 'provenance']),
        units,
        skillCourse);
  }

  static Map<String, Map<String, String>> _copy(
    Map<String, dynamic> raw,
    List<String> fields,
  ) {
    return <String, Map<String, String>>{
      for (final field in fields) field: _pair(raw[field]),
    };
  }

  static Map<String, String> _pair(dynamic value) {
    final pair = value as Map<String, dynamic>;
    return <String, String>{
      for (final lang in <String>['en', 'tr']) lang: _nonempty(pair[lang]),
    };
  }

  static String _nonempty(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Missing bilingual curriculum text');
    }
    return value;
  }
}

class HipHopUnit {
  HipHopUnit.fromJson(Map<String, dynamic> raw)
      : id = HipHopCourse._nonempty(raw['id']),
        prerequisiteIds = (raw['prerequisiteIds'] as List<dynamic>)
            .map(HipHopCourse._nonempty)
            .toList(growable: false),
        copy = HipHopCourse._copy(raw, fields);

  final String id;
  final List<String> prerequisiteIds;
  final Map<String, Map<String, String>> copy;
  static const fields = <String>[
    'title',
    'prerequisite',
    'outcome',
    'instruction',
    'practice',
    'mistakes',
    'adaptation',
    'check',
  ];
}
