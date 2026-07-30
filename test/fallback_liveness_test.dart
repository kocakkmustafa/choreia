import 'dart:convert';
import 'dart:io';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// FALLBACK LIVENESS (M-F-184/1) — "triggering is MEASURED, existence is not
/// ASSUMED."
///
/// The rule: a fallback class EXISTING does not mean unrecognised input lands
/// in it. Until its triggering is measured the fallback is decorative — and a
/// decorative fallback reads, in the product doc, as "we honestly flag what is
/// out of scope".
///
/// Choreia's fallbacks are the `noVerdict` paths: `WRONG_FOOT` when the side
/// margin sits inside the noise floor, plus the two calibration-blocked codes.
/// Out-of-vocabulary REAL input (recipe step 2): **hip-hop cycles judged
/// against the salsa shine reference** — a different style and a different
/// step, from real footage. Synthetic input would not do: you build synthetic
/// input to land where you want it.
///
/// The two ways a fallback can be dead, which must be told apart:
///   * **A — misclassification:** input is completed into the nearest MODELLED
///     class. Signature: fallback 0, modelled counts high. Damage: WRONG
///     feedback that looks right on screen.
///   * **B — invisibility:** input never reaches the judgement path at all.
///     Signature: everything ~0. Damage: SILENT absence.
///
/// JabLab's addendum, applied below: **before calling a rate "low", measure the
/// CONTROL condition.** In-vocabulary shine cycles are that control — without
/// them, "hip-hop produced 1 verdict" is a number with nothing to mean against.
void main() {
  final Directory repo = Directory.current;

  Map<String, dynamic> readJson(String path) =>
      (jsonDecode(File('${repo.path}/$path').readAsStringSync()) as Map)
          .cast<String, dynamic>();

  Cycle toCycle(Map<String, dynamic> raw) => <String, List<double>>{
        for (final MapEntry<String, dynamic> e in raw.entries)
          e.key: (e.value as List)
              .map((Object? v) => v == null ? double.nan : (v as num).toDouble())
              .toList(growable: false),
      };

  late DanceReference reference;
  late Map<String, Cycle> outOfVocabulary;
  late Map<String, Cycle> control;
  late int momentA;
  late int momentB;

  setUpAll(() {
    reference = DanceReference.load(
        File('${repo.path}/content/references/ss_shine_footwork.json'));
    final Map<String, dynamic> step = readJson(
        'content/styles/salsa_shines/steps/ss_shine_footwork.json');
    final Map<String, int> bins = <String, int>{
      for (final Object? p in (step['phases'] as List))
        (p as Map)['id'] as String:
            ((p['enter'] as Map)['phaseBin'] as num).toInt(),
    };
    momentA = bins['settle_a']!;
    momentB = bins['settle_b']!;

    final Map<String, dynamic> oov =
        readJson('test/fixtures/replay_out_of_vocabulary.json');
    outOfVocabulary = <String, Cycle>{
      for (final MapEntry<String, dynamic> e
          in (oov['cycles'] as Map).cast<String, dynamic>().entries)
        e.key: toCycle(
            ((e.value as Map)['cycle'] as Map).cast<String, dynamic>()),
    };

    control = <String, Cycle>{
      'SHGkSbJm2Iw': toCycle((readJson('test/fixtures/replay_ss_shine_cycle.json')
              ['cycle'] as Map)
          .cast<String, dynamic>()),
      'jjP8bKWCg9U': toCycle(
          (readJson('test/fixtures/replay_ss_shine_cycle_sided.json')['cycle']
                  as Map)
              .cast<String, dynamic>()),
    };
  });

  /// The recipe's three counters, for one cycle.
  ({int fallback, int modelled, int errors}) count(Cycle c) {
    final JudgeResult r = DanceJudge(reference: reference)
        .judge(c, momentA: momentA, momentB: momentB);
    int fallback = 0;
    int modelled = 0;
    int errors = 0;
    for (final ErrorFinding f in r.findings) {
      switch (f.verdict) {
        case Verdict.noVerdict:
          fallback++;
        case Verdict.ok:
          modelled++;
        case Verdict.error:
          modelled++;
          errors++;
      }
    }
    return (fallback: fallback, modelled: modelled, errors: errors);
  }

  test('STEP 3 — the three counters, read together and against a control', () {
    final StringBuffer log = StringBuffer('\nfallback liveness counters\n');
    for (final MapEntry<String, Cycle> e in control.entries) {
      final c = count(e.value);
      log.writeln('  CONTROL  ${e.key}: fallback=${c.fallback} '
          'modelled=${c.modelled} errors=${c.errors}');
    }
    for (final MapEntry<String, Cycle> e in outOfVocabulary.entries) {
      final c = count(e.value);
      log.writeln('  OUT-OF-V ${e.key}: fallback=${c.fallback} '
          'modelled=${c.modelled} errors=${c.errors}');
    }
    // Printed, not asserted: the raw counters are the evidence a human reads
    // when the diagnosis is disputed. The assertions live below.
    printOnFailure(log.toString());

    // The control MUST produce modelled verdicts — otherwise the pipeline is
    // dead for everything and the out-of-vocabulary reading means nothing.
    // This is JabLab's addendum: no rate is "low" without its baseline.
    for (final MapEntry<String, Cycle> e in control.entries) {
      expect(count(e.value).modelled, greaterThan(0),
          reason: '${e.key} is IN vocabulary; if it yields no modelled verdict '
              'the judge is dead and every other number here is meaningless');
    }
  });

  test('STEP 4 — the fallback is ALIVE but does NOT discriminate: a different '
      'dance produces zero errors (MEASURED GAP, canary)', () {
    // My first version of this test asserted `errors > 0 || fallback > 0` and
    // PASSED — on a coincidence. The fallback fires for in-vocabulary cycles
    // too, so that condition was true for everyone and measured nothing. The
    // recipe warns about exactly this: the two expectations must be read
    // TOGETHER, or the first one hides mechanism A.
    //
    // What the counters actually say (control | out-of-vocabulary):
    //   fallback 3,2 | 3,3     modelled 1,2 | 1,1     errors 0,0 | 0,0
    // The signatures are IDENTICAL. The fallback is not decorative — it does
    // fire on real material — but it does not separate a salsa shine from a
    // hip-hop Running Man.
    //
    // Root cause: there is NO STEP-IDENTITY CHECK. Every code asks HOW the step
    // was done; none asks WHETHER this is the step. `STEP_TOO_LARGE` returns
    // `ok` for a Running Man because its thigh excursion (16.9 deg) is under
    // the 20 deg cap — true, and useless as identity.
    //
    // This test asserts TODAY'S MEASURED TRUTH, deliberately. It is a canary:
    // when an identity gate lands, this fails and whoever added it must come
    // back and rewrite the honesty copy that depends on the gap. Asserting the
    // wish instead would have left a red test nobody could act on, and
    // asserting nothing would have let the gap go unrecorded.
    for (final MapEntry<String, Cycle> e in outOfVocabulary.entries) {
      final c = count(e.value);

      // Mechanism B is ruled out: the input DOES reach the judgement path.
      expect(c.fallback + c.modelled, greaterThan(0),
          reason: '${e.key} produced NO findings at all — that would be '
              'mechanism B (invisibility), a different and worse defect');

      expect(c.errors, 0,
          reason: 'MEASURED GAP — if ${e.key} now produces an error, a '
              'step-identity check has landed. Good: update this test, and '
              'update the notMeasured entry in salsa_shines/style.json that '
              'currently states we cannot tell.');
    }
  });

  test('the noVerdict fallback is reachable on REAL material, not just '
      'synthetic', () {
    // The recipe is explicit that synthetic input alone does not count. These
    // are real recorded cycles; at least one of them must exercise the
    // noVerdict path, otherwise "we say when we cannot judge" is a claim with
    // no measurement behind it.
    final int reachedFallback = <Cycle>[
      ...outOfVocabulary.values,
      ...control.values,
    ].where((Cycle c) => count(c).fallback > 0).length;
    expect(reachedFallback, greaterThan(0),
        reason: 'no real cycle ever produced a noVerdict — the fallback is '
            'decorative and the honesty copy resting on it is unearned');
  });
}
