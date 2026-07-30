import 'dart:convert';
import 'dart:io';

/// One named reason a reference is still provisional.
///
/// The family rule this implements: a flag carries its own basis (M-F-166).
/// `mirror-ambiguity`, `source-count-below-target` and `thin-evidence` are
/// separate weaknesses with separate cures, and a consumer that wants to know
/// "can I trust the SIDE call" must be able to ask about mirroring alone
/// without being told about cycle counts.
final class StatusBasis {
  const StatusBasis({
    required this.basis,
    required this.why,
    required this.resolvedBy,
  });

  factory StatusBasis.fromJson(Map<String, dynamic> j) => StatusBasis(
        basis: j['basis'] as String,
        why: j['why'] as String? ?? '',
        resolvedBy: j['resolvedBy'] as String? ?? '',
      );

  /// Machine-readable id: mirror-ambiguity | source-count-below-target |
  /// thin-evidence.
  final String basis;

  /// What was measured, in the builder's words.
  final String why;

  /// What would lift THIS basis — not the others.
  final String resolvedBy;
}

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
    required this.statusBases,
    required this.angles,
    required this.toleranceDeg,
    required this.scoredPhases,
    required this.excludedIdentityAmbiguous,
    required this.namedVariants,
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
      statusBases: <StatusBasis>[
        for (final Object? b in (j['statusBases'] as List? ?? const <Object?>[]))
          StatusBasis.fromJson((b as Map).cast<String, dynamic>()),
      ],
      angles: <String, List<double>>{
        for (final MapEntry<String, dynamic> e in ref.entries)
          e.key: nums(e.value),
      },
      toleranceDeg: <String, List<double>>{
        for (final MapEntry<String, dynamic> e in tol.entries)
          e.key: nums(e.value),
      },
      scoredPhases: scored,
      excludedIdentityAmbiguous: <Map<String, dynamic>>[
        for (final Object? e
            in (j['excludedIdentityAmbiguous'] as List? ?? const <Object?>[]))
          (e as Map).cast<String, dynamic>(),
      ],
      namedVariants: <String, String>{
        for (final Object? s in (j['sources'] as List? ?? const <Object?>[]))
          if ((s as Map).cast<String, dynamic>()['namedVariant'] != null)
            s.cast<String, dynamic>()['videoId'] as String:
                s.cast<String, dynamic>()['namedVariant'] as String,
      },
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

  /// `provisional` while any weakness remains, else null.
  ///
  /// Never read this alone: it says THAT the reference is provisional, not
  /// WHICH weakness makes it so. A flag without its bases makes solving one
  /// look like solving all of them (C-111 was exactly that defect — status
  /// derived from mirror ambiguity alone, so resolving mirroring silently
  /// cleared a still-provisional reference). Use [statusBases].
  final String? status;

  /// The named weaknesses behind [status] — each one independently resolvable.
  final List<StatusBasis> statusBases;

  bool get isProvisional => statusBases.isNotEmpty;

  bool hasBasis(String basis) =>
      statusBases.any((StatusBasis b) => b.basis == basis);

  final Map<String, List<double>> angles;
  final Map<String, List<double>> toleranceDeg;

  /// Per joint, which phase bins the instructors agreed tightly enough for a
  /// verdict. A bin marked false is MEASURED but never JUDGED.
  final Map<String, List<bool>> scoredPhases;

  /// Sources set aside because it could not be established that they show THIS
  /// step — named, with an independent reason. Excluding an inconvenient source
  /// is the failure M-F-47 exists to prevent, so the record travels with the
  /// artifact and a surface can show it.
  final List<Map<String, dynamic>> excludedIdentityAmbiguous;

  /// videoId -> the named variation that source demonstrates, where one is
  /// known. The step stays ONE step; the name is kept at source level (no
  /// dropping, no splitting — tagging).
  final Map<String, String> namedVariants;

  String? namedVariantOf(String videoId) => namedVariants[videoId];

  Iterable<String> get joints => angles.keys;

  bool isScoredAt(String joint, int bin) {
    final List<bool>? mask = scoredPhases[joint];
    if (mask == null || bin < 0 || bin >= mask.length) return false;
    return mask[bin];
  }
}
