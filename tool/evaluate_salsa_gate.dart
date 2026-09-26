import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:choreia_engine/choreia_engine.dart';
import 'package:crypto/crypto.dart';

/// Offline regression evidence, not a training or accuracy report.
/// Run from the app root: dart run tool/evaluate_salsa_gate.dart
void main() {
  try {
    final Map<String, Object?> report = evaluateSalsaGate(Directory.current);
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
    exitCode = report['assessmentReady'] == true ? 0 : 2;
  } on Object catch (error) {
    stderr.writeln('Salsa evaluation failed: $error');
    exitCode = 1;
  }
}

Map<String, Object?> evaluateSalsaGate(Directory repo) {
  const String referencePath = 'content/references/ss_shine_footwork.json';
  const String sidedPath = 'test/fixtures/replay_ss_shine_cycle_sided.json';
  const String ambiguousPath = 'test/fixtures/replay_ss_shine_cycle.json';
  const String outsidePath = 'test/fixtures/replay_out_of_vocabulary.json';
  const String stepPath =
      'content/styles/salsa_shines/steps/ss_shine_footwork.json';
  const String pinPath = 'lib/app/live/pose_model.dart';
  final Map<String, String> hashes = <String, String>{};

  String read(String path) {
    final List<int> bytes = File('${repo.path}/$path').readAsBytesSync();
    hashes[path] = sha256.convert(bytes).toString();
    return utf8.decode(bytes);
  }

  Map<String, dynamic> document(String path) =>
      (jsonDecode(read(path)) as Map).cast<String, dynamic>();
  Cycle cycle(Object? raw) =>
      (raw as Map).map((Object? key, Object? value) => MapEntry(key as String,
          (value as List).map((Object? x) => (x as num).toDouble()).toList()));

  final DanceReference reference =
      DanceReference.fromJson(document(referencePath));
  final DanceAssessmentGate gate = DanceAssessmentGate.forReference(reference);
  final DanceJudge judge = DanceJudge(reference: reference);
  final Map<String, dynamic> step = document(stepPath);
  final Map<String, int> bins = <String, int>{
    for (final Map<String, dynamic> phase
        in (step['phases'] as List).cast<Map<String, dynamic>>())
      if (phase['enter'] is Map && (phase['enter'] as Map)['phaseBin'] is num)
        phase['id'] as String:
            ((phase['enter'] as Map)['phaseBin'] as num).toInt(),
  };
  int moment(String id) {
    final Map<String, dynamic> entry = (step['scoredMoments'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((Map<String, dynamic> value) => value['label'] == id);
    return bins[entry['phase']] ??
        (throw const FormatException('Missing declared phase bin'));
  }

  final int momentA = moment('a');
  final int momentB = moment('b');
  final Map<String, dynamic> sided = document(sidedPath);
  final Map<String, dynamic> ambiguous = document(ambiguousPath);
  final Map<String, dynamic> outside = document(outsidePath);
  final Cycle source = cycle(sided['cycle']);
  final Cycle frozen = <String, List<double>>{
    for (final MapEntry<String, List<double>> entry in source.entries)
      entry.key: List<double>.filled(reference.phaseBins, entry.value.first),
  };
  final Cycle sway = <String, List<double>>{
    for (final MapEntry<String, List<double>> entry in frozen.entries)
      entry.key: List<double>.generate(
          reference.phaseBins,
          (int i) =>
              entry.value[i] +
              (orientationJoints.contains(entry.key)
                  ? 2 * math.sin(2 * math.pi * i / reference.phaseBins)
                  : 0)),
  };

  final List<Map<String, Object?>> cases = <Map<String, Object?>>[];
  void inspect(String id, Cycle input, String provenance) {
    final List<String> issues = gate.cycleIssues(input);
    final JudgeResult? diagnostic = issues.isEmpty
        ? judge.judge(input, momentA: momentA, momentB: momentB)
        : null;
    cases.add(<String, Object?>{
      'id': id,
      'provenance': provenance,
      'inputIssues': issues,
      'diagnosticMeasurements': diagnostic?.measurements,
      'diagnosticFindings': diagnostic?.findings
          .map((ErrorFinding finding) => <String, Object?>{
                'code': finding.code,
                'verdict': finding.verdict.name,
              })
          .toList(),
      'learnerVerdictsAllowed': gate.allowsScoring && issues.isEmpty,
      'assessmentStatus': 'unavailable',
    });
  }

  inspect(
      'reference_self', reference.angles, 'reference consensus, not holdout');
  inspect('source_sided', source, 'existing source-derived regression fixture');
  inspect('source_ambiguous', cycle(ambiguous['cycle']),
      'existing source-derived regression fixture');
  inspect('wrong_foot', mirrorCycle(source), 'controlled anatomical mirror');
  inspect('display_mirror_normalized', mirrorCycle(mirrorCycle(source)),
      'controlled display mirror and inverse; not a new participant');
  inspect('frozen', frozen, 'synthetic stationary distractor');
  inspect(
      'small_sway', sway, 'synthetic 2 degree sway; not labeled human data');
  for (final MapEntry<String, dynamic> entry
      in (outside['cycles'] as Map).cast<String, dynamic>().entries) {
    inspect('different_step_${entry.key}', cycle((entry.value as Map)['cycle']),
        'existing out-of-vocabulary derived regression fixture');
  }
  inspect(
      'occluded_left_knee',
      <String, List<double>>{
        for (final MapEntry<String, List<double>> entry in source.entries)
          if (entry.key != 'left_knee') entry.key: entry.value,
      },
      'synthetic missing required joint');
  inspect(
      'partial_cycle',
      <String, List<double>>{
        for (final MapEntry<String, List<double>> entry in source.entries)
          entry.key: entry.value.sublist(0, entry.value.length - 1),
      },
      'synthetic truncation');
  inspect(
      'non_finite_knee',
      <String, List<double>>{
        ...source,
        'left_knee': List<double>.filled(reference.phaseBins, double.nan),
      },
      'synthetic invalid coordinate');

  final String pin = read(pinPath);
  String pinValue(String name) =>
      RegExp("$name\\s*=\\s*'([^']+)'").firstMatch(pin)!.group(1)!;
  // The evaluated implementation is part of the receipt, not only its inputs.
  for (final String path in <String>[
    'packages/choreia_engine/lib/src/judge.dart',
    'packages/choreia_engine/lib/src/assessment_gate.dart',
    'tool/evaluate_salsa_gate.dart',
  ]) {
    read(path);
  }
  return <String, Object?>{
    'schemaVersion': 1,
    'course': 'salsa_on1_solo',
    'assessmentReady': gate.allowsScoring,
    'blockers': gate.blockers,
    'assessmentAccuracy': null,
    'independentHoldoutParticipants': 0,
    'independentHoldoutClips': 0,
    'physicalDevicesEvaluated': 0,
    'trainingPerformed': false,
    'downloadsPerformed': false,
    'sourceMediaTrainingRights': 'not established; no source media used',
    'poseModelDeclaredId': pinValue('modelId'),
    'poseModelDeclaredSha256': pinValue('sha256'),
    'poseModelBinaryEvaluated': false,
    'beatTimingAssessed': false,
    'countConvention': <String, Object?>{
      'musicalPulses': 8,
      'primaryStepCounts': <int>[1, 2, 3, 5, 6, 7],
      'steplessCountsAreNotBodyFreezes': true,
      'fixtureBeatLabels': null,
      'phaseBinsAreNotBeatLabels': true,
      'diagnosticMomentBins': <int>[momentA, momentB],
    },
    'fixtureProvenance': <Object?>[
      sided['provenance'],
      ambiguous['provenance']
    ],
    'filesSha256': hashes,
    'cases': cases,
    'limitations': <String>[
      'Source-derived fixtures and synthetic transforms are regression only.',
      'Angle replay does not test camera pixels, tracking confidence or clocks.',
      'No numerical dance accuracy, mastery, safety or medical verdict is valid.',
      'Clearing BPM/provisional content flags cannot authorize scoring.',
    ],
  };
}
