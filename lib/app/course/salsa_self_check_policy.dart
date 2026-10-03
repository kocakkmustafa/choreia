enum SalsaPracticeOption { standard, adapted, rhythmOnly }

enum SalsaSelfCheckMode { existingSelfCheck, practiceOnly }

/// A typed selection of existing bilingual criterion indices, never new text.
final class SalsaSelfCheckSelection {
  SalsaSelfCheckSelection._(this.mode, Iterable<int> indices)
      : indices = List<int>.unmodifiable(indices);

  factory SalsaSelfCheckSelection.legacy(int count) =>
      SalsaSelfCheckSelection._(SalsaSelfCheckMode.existingSelfCheck,
          List<int>.generate(count, (index) => index));

  factory SalsaSelfCheckSelection.parse(Object? raw, int count) {
    if (raw is! Map<String, dynamic> ||
        raw.length != 2 ||
        !raw.containsKey('mode') ||
        !raw.containsKey('indices')) {
      throw const FormatException('Expected an exact criterion selection.');
    }
    final mode = switch (raw['mode']) {
      'existingSelfCheck' => SalsaSelfCheckMode.existingSelfCheck,
      'practiceOnly' => SalsaSelfCheckMode.practiceOnly,
      _ => throw const FormatException('Unknown criterion selection mode.'),
    };
    final rawIndices = raw['indices'];
    if (rawIndices is! List || rawIndices.any((index) => index is! int)) {
      throw const FormatException('Expected integer criterion indices.');
    }
    final indices = rawIndices.cast<int>();
    if (indices.toSet().length != indices.length ||
        indices.any((index) => index < 0 || index >= count) ||
        (mode == SalsaSelfCheckMode.existingSelfCheck && indices.isEmpty) ||
        (mode == SalsaSelfCheckMode.practiceOnly && indices.isNotEmpty)) {
      throw const FormatException('Invalid criterion indices for this mode.');
    }
    return SalsaSelfCheckSelection._(mode, indices);
  }

  final SalsaSelfCheckMode mode;
  final List<int> indices;
  bool get completionAllowed =>
      mode == SalsaSelfCheckMode.existingSelfCheck && indices.isNotEmpty;
}

final class SalsaSelfCheckPolicy {
  SalsaSelfCheckPolicy._(
      Map<SalsaPracticeOption, SalsaSelfCheckSelection> choices)
      : _choices = Map.unmodifiable(choices);

  factory SalsaSelfCheckPolicy.parse(Object? raw, int count) {
    if (raw is! Map<String, dynamic> ||
        raw.length != SalsaPracticeOption.values.length ||
        !SalsaPracticeOption.values
            .every((option) => raw.containsKey(option.name))) {
      throw const FormatException(
          'Every practice option needs an exact policy.');
    }
    return SalsaSelfCheckPolicy._({
      for (final option in SalsaPracticeOption.values)
        option: SalsaSelfCheckSelection.parse(raw[option.name], count),
    });
  }

  final Map<SalsaPracticeOption, SalsaSelfCheckSelection> _choices;
  SalsaSelfCheckSelection forOption(SalsaPracticeOption option) =>
      _choices[option]!;
}

// This narrow candidate revision covers only the five reviewed source mappings.
// Other lessons remain explicit legacy scope, not applicability approval.
const salsaCriterionRevisionLessons = {
  'so_16',
  'so_19',
  'so_21',
  'so_27',
  'so_39'
};
