import 'dart:convert';
import 'dart:io';

/// A built dance reference, read from `content/references/<step>.json`.
///
/// Deliberately a READER, not a builder: references are produced by the Python
/// harvest pipeline (`tools/build_reference.py`) and the artifact is the
/// contract between the two halves. Re-implementing the builder in Dart would
/// create a second source of truth for tolerances — the defect M-F-03 settled
/// by declaring one canonical pipeline per concern.
final class DanceReference {
  const DanceReference({
    required this.step,
    required this.phaseBins,
    required this.takeCount,
    required this.mirrorConfident,
    required this.status,
    required this.angles,
    required this.toleranceDeg,
    required this.scoredPhases,
  });

  /// Throws [FormatException] on a version/shape it does not understand rather
  /// than reading partial data. A reference that loads "mostly" would score
  /// against a half-built tolerance band, which is worse than not scoring.
  factory DanceReference.fromJson(Map<String, dynamic> j) {
    final Object? built = j['built'];
    if (built != true) {
      throw const FormatException(
          'reference has built != true — an unbuilt artifact carries no '
          'tolerances and must not reach a scorer');
    }
    final Map<String, dynamic> ref =
        (j['reference'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> tol =
        (j['toleranceDeg'] as Map).cast<String, dynamic>();
    final Map<String, dynamic> scoring =
        (j['scoring'] as Map? ?? const <String, dynamic>{})
            .cast<String, dynamic>();

    List<double> nums(Object? v) => (v as List)
        .map((Object? e) => (e as num).toDouble())
        .toList(growable: false);

    final Map<String, List<bool>> scored = <String, List<bool>>{};
    for (final MapEntry<String, dynamic> e in scoring.entries) {
      final Object? phases =
          (e.value as Map).cast<String, dynamic>()['scoredPhases'];
      if (phases is List) {
        scored[e.key] =
            phases.map((Object? b) => b == true).toList(growable: false);
      }
    }

    return DanceReference(
      step: j['step'] as String,
      phaseBins: (j['phaseBins'] as num).toInt(),
      takeCount: (j['takeCount'] as num).toInt(),
      // Absent is read as FALSE, not as "probably fine": kural-7 says a
      // side-dependent verdict needs this to be explicitly true.
      mirrorConfident: j['mirrorConfident'] == true,
      status: j['status'] as String?,
      angles: <String, List<double>>{
        for (final MapEntry<String, dynamic> e in ref.entries)
          e.key: nums(e.value),
      },
      toleranceDeg: <String, List<double>>{
        for (final MapEntry<String, dynamic> e in tol.entries)
          e.key: nums(e.value),
      },
      scoredPhases: scored,
    );
  }

  static DanceReference load(File file) => DanceReference.fromJson(
      (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>());

  final String step;
  final int phaseBins;
  final int takeCount;

  /// Whether the build could tell a mirrored take from a straight one. When
  /// false NO side-dependent judgement may be formed (kural-7, M-F-117) —
  /// enforced in [DanceJudge], not merely documented.
  final bool mirrorConfident;

  /// `provisional` while evidence is thin. Carried so a surface can say so.
  final String? status;

  final Map<String, List<double>> angles;
  final Map<String, List<double>> toleranceDeg;

  /// Per joint, which phase bins the instructors agreed tightly enough for a
  /// verdict. A bin marked false is MEASURED but never JUDGED.
  final Map<String, List<bool>> scoredPhases;

  Iterable<String> get joints => angles.keys;

  bool isScoredAt(String joint, int bin) {
    final List<bool>? mask = scoredPhases[joint];
    if (mask == null || bin < 0 || bin >= mask.length) return false;
    return mask[bin];
  }
}
