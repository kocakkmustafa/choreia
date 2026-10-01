import 'judge.dart';
import 'reference.dart';

/// Evidence required before diagnostic rules become learner judgments.
///
/// The repository has derived regression cycles, including cycles from the
/// reference's own sources, but no accepted independent calibration report.
/// Removing a content release gate or provisional flag cannot supply that
/// missing evidence. Promotion requires an independently reviewed evaluation
/// tied to model, reference and rule hashes; this version has no such receipt.
final class DanceAssessmentGate {
  DanceAssessmentGate.forReference(this.reference)
      : blockers = List<String>.unmodifiable(<String>[
          'accepted_independent_evaluation_missing',
          if (reference.status == 'provisional' || reference.isProvisional)
            'reference_provisional',
          if (!reference.mirrorConfident) 'reference_orientation_unresolved',
        ]);

  final DanceReference reference;
  final List<String> blockers;

  bool get allowsScoring => blockers.isEmpty;

  /// Completeness is checked before diagnostic means can ignore missing data.
  /// An absent or non-finite joint is unobserved, never a zero-angle success.
  List<String> cycleIssues(Cycle cycle) {
    final List<String> issues = <String>[];
    if (reference.phaseBins < 2) issues.add('invalid_phase_count');
    for (final String joint in legJoints) {
      final List<double>? values = cycle[joint];
      final List<double>? expected = reference.angles[joint];
      if (expected == null ||
          expected.length != reference.phaseBins ||
          expected.any((double x) => !x.isFinite)) {
        issues.add('invalid_reference:$joint');
      }
      if (values == null) {
        issues.add('missing_joint:$joint');
      } else if (values.length != reference.phaseBins) {
        issues.add('incomplete_cycle:$joint');
      } else if (values.any((double x) => !x.isFinite)) {
        issues.add('non_finite_joint:$joint');
      }
    }
    // Extra/styling joints still enter the candidate's whole-body distance.
    for (final MapEntry<String, List<double>> joint in cycle.entries) {
      if (legJoints.contains(joint.key)) continue;
      if (joint.value.length != reference.phaseBins ||
          joint.value.any((double x) => !x.isFinite)) {
        issues.add('invalid_joint:${joint.key}');
      }
    }
    return List<String>.unmodifiable(issues);
  }
}
