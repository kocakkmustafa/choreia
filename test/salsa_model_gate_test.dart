import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/live/live_session.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/evaluate_salsa_gate.dart' as evaluator;
import 'support/replay_pose_source.dart';

void main() {
  late Map<String, Object?> report;
  late DanceReference reference;
  late Map<String, dynamic> step;

  setUpAll(() {
    report = evaluator.evaluateSalsaGate(Directory.current);
    reference =
        DanceReference.load(File('content/references/ss_shine_footwork.json'));
    step = (jsonDecode(
            File('content/styles/salsa_shines/steps/ss_shine_footwork.json')
                .readAsStringSync()) as Map)
        .cast<String, dynamic>();
  });

  Map<String, Object?> result(String id) =>
      (report['cases']! as List<Map<String, Object?>>)
          .firstWhere((Map<String, Object?> value) => value['id'] == id);

  String verdict(String id, String code) =>
      (result(id)['diagnosticFindings']! as List<Map<String, Object?>>)
          .firstWhere((Map<String, Object?> value) =>
              value['code'] == code)['verdict']! as String;

  test('controlled wrong foot changes the actual diagnostic, not approval', () {
    expect(verdict('source_sided', 'WRONG_FOOT'), 'ok');
    expect(verdict('wrong_foot', 'WRONG_FOOT'), 'error');
    expect(verdict('display_mirror_normalized', 'WRONG_FOOT'), 'ok');
    expect(result('display_mirror_normalized')['diagnosticMeasurements'],
        result('source_sided')['diagnosticMeasurements']);
    for (final Map<String, Object?> value
        in report['cases']! as List<Map<String, Object?>>) {
      expect(value['learnerVerdictsAllowed'], isFalse,
          reason:
              '${value['id']} is regression evidence, not accepted holdout');
    }
  });

  test('missing or corrupt observations never enter diagnostic averaging', () {
    for (final String id in <String>[
      'occluded_left_knee',
      'partial_cycle',
      'non_finite_knee',
    ]) {
      expect(result(id)['inputIssues'], isNotEmpty);
      expect(result(id)['diagnosticMeasurements'], isNull);
      expect(result(id)['diagnosticFindings'], isNull);
    }
    expect(result('source_sided')['inputIssues'], isEmpty);
    expect(result('source_sided')['diagnosticMeasurements'], isNotEmpty);
  });

  test('reproduces known wrong-step silence without reporting success', () {
    final List<Map<String, Object?>> wrongSteps =
        (report['cases']! as List<Map<String, Object?>>)
            .where((Map<String, Object?> value) =>
                (value['id']! as String).startsWith('different_step_'))
            .toList();
    expect(wrongSteps, isNotEmpty);
    for (final Map<String, Object?> value in wrongSteps) {
      final List<Map<String, Object?>> findings =
          value['diagnosticFindings']! as List<Map<String, Object?>>;
      expect(
          findings.where((Map<String, Object?> f) => f['verdict'] == 'error'),
          isEmpty,
          reason: 'Known false-negative baseline changed; review it.');
      expect(value['assessmentStatus'], 'unavailable');
    }
    expect(result('small_sway')['diagnosticMeasurements'], isNotEmpty);
    expect(result('small_sway')['learnerVerdictsAllowed'], isFalse);
  });

  test('report discloses provenance and remains deterministic', () {
    expect(report['independentHoldoutParticipants'], 0);
    expect(report['assessmentAccuracy'], isNull);
    expect(report['beatTimingAssessed'], isFalse);
    expect(report['poseModelBinaryEvaluated'], isFalse);
    expect(report['trainingPerformed'], isFalse);
    expect(report['downloadsPerformed'], isFalse);
    final Map<String, String> hashes =
        report['filesSha256']! as Map<String, String>;
    expect(hashes.keys, contains('packages/choreia_engine/lib/src/judge.dart'));
    expect(
        hashes.values
            .every((String h) => RegExp(r'^[a-f0-9]{64}$').hasMatch(h)),
        isTrue);
    expect(jsonEncode(evaluator.evaluateSalsaGate(Directory.current)),
        jsonEncode(report));
  });

  test('removing provisional and beat flags cannot create evidence', () async {
    final Map<String, dynamic> json = (jsonDecode(
            File('content/references/ss_shine_footwork.json')
                .readAsStringSync()) as Map)
        .cast<String, dynamic>();
    json.remove('status');
    json['statusBases'] = <Object?>[];
    final DanceReference edited = DanceReference.fromJson(json);
    expect(edited.isProvisional, isFalse);
    final DanceAssessmentGate gate = DanceAssessmentGate.forReference(edited);
    expect(gate.blockers, isNot(contains('reference_provisional')));
    expect(gate.blockers, contains('accepted_independent_evaluation_missing'));
    final LiveSession session = LiveSession(
      reference: edited,
      stepConfig: <String, dynamic>{...step, 'errors': <Object?>[]},
      lessonClass: 'scored',
      judge: DanceJudge(reference: edited),
    );
    expect(session.isScored, isFalse);
    expect(session.gatedChecks().map((GatedCheck g) => g.code),
        contains('ASSESSMENT_UNVALIDATED'));
    final List<LiveState> states =
        await session.run(framesFrom(dancingBody(), 180)).toList();
    expect(states.whereType<LiveJudged>(), isEmpty);
    expect(states.whereType<LiveNoPerson>(), isEmpty);
    expect(states.whereType<LiveWatching>(), isNotEmpty);
    expect(states.whereType<LiveMeasured>(), isNotEmpty,
        reason: 'The regression must actually reach the cycle reader.');
  });

  test('occluded live frames yield no measurements or success', () async {
    final LiveSession session = LiveSession(
      reference: reference,
      stepConfig: step,
      lessonClass: 'scored',
      judge: DanceJudge(reference: reference),
    );
    final List<LiveState> states =
        await session.run(framesFrom(blankBody(), 90)).toList();
    expect(states.whereType<LiveNoPerson>(), hasLength(90));
    expect(states.whereType<LiveJudged>(), isEmpty);
    expect(states.whereType<LiveMeasured>(), isEmpty);
  });
}
