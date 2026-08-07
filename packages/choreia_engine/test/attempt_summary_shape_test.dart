import 'dart:io';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:test/test.dart';

/// C-136 MEASUREMENT: what does an attempt summary actually contain?
///
/// The single-correction rule ("score + ONE correction, the most important
/// error") was blocked on an assumption: that reducing "show all" to "show one"
/// needs a derived severity ladder like JabLab's six-rung one, and that
/// inventing one for Choreia would be threshold-invention. This file measures
/// the size of the problem instead of assuming it.
void main() {
  final Directory repo = _findRepoRoot();
  final DanceReference shine = DanceReference.load(
      File('${repo.path}/content/references/ss_shine_footwork.json'));
  final DanceReference runningMan = DanceReference.load(
      File('${repo.path}/content/references/hh_running_man.json'));

  /// One judged attempt against the reference's own consensus pose — the
  /// cleanest possible learner, so every finding present here is present in
  /// EVERY attempt regardless of how well it was danced.
  /// Phase bins the step config declares as its two settle moments — the same
  /// pair `judge_test.dart` uses against these artifacts.
  const int momentA = 1;
  const int momentB = 29;

  JudgeResult judgeSelf(DanceReference ref) => DanceJudge(reference: ref)
      .judge(ref.angles, momentA: momentA, momentB: momentB);

  group('how many rows the summary renders', () {
    test('the one scored lesson emits exactly 4 findings, every attempt', () {
      final JudgeResult r = judgeSelf(shine);
      expect(r.findings.map((ErrorFinding f) => f.code).toList(),
          <String>['STEP_TOO_LARGE', 'NO_WEIGHT_TRANSFER', 'STEP_LATE',
              'WRONG_FOOT'],
          reason: 'live_view renders one row per finding, unconditionally');
    });

    test('HALF of them can NEVER carry a verdict', () {
      final JudgeResult r = judgeSelf(shine);
      final List<String> permanentlyMute = r.findings
          .where((ErrorFinding f) => f.verdict == Verdict.noVerdict)
          .map((ErrorFinding f) => f.code)
          .toList();

      expect(permanentlyMute, <String>['NO_WEIGHT_TRANSFER', 'STEP_LATE'],
          reason: 'both are noVerdict by CONSTRUCTION, not by this attempt: '
              'NO_WEIGHT_TRANSFER is calibration-blocked (threshold below the '
              'noise floor) and STEP_LATE has no beat grid. Neither can turn '
              'into a correction no matter how the learner dances.');
    });

    test('THE NUMBER THAT MATTERS: at most 2 findings can ever fire', () {
      // Every code that carries a real verdict, i.e. could ever be "the one
      // correction". This is the whole candidate set the single-correction
      // rule would have to choose between.
      final List<String> canFire = judgeSelf(shine)
          .findings
          .where((ErrorFinding f) => f.verdict != Verdict.noVerdict)
          .map((ErrorFinding f) => f.code)
          .toList();

      expect(canFire, <String>['STEP_TOO_LARGE', 'WRONG_FOOT'],
          reason: 'so the ordering problem is NOT an n-way severity ladder. It '
              'is ONE binary tie-break: when both of these fire at once, which '
              'is the single correction?');
    });

    test('a mirror-uncertain reference drops to 3 findings and ONE that fires',
        () {
      // hip-hop's references carry mirrorConfident:false, so WRONG_FOOT is
      // never FORMED (kural-7). There, single-correction is not a choice at
      // all — there is only one candidate.
      final JudgeResult r = judgeSelf(runningMan);
      expect(runningMan.mirrorConfident, isFalse);
      expect(r.findings.map((ErrorFinding f) => f.code), isNot(contains('WRONG_FOOT')));
      expect(
          r.findings
              .where((ErrorFinding f) => f.verdict != Verdict.noVerdict)
              .map((ErrorFinding f) => f.code),
          <String>['STEP_TOO_LARGE']);
    });
  });

  group('can the two be told apart WITHOUT inventing a threshold', () {
    test('content already ranks them: the unlock gate names WRONG_FOOT only',
        () {
      // salsa_shines level 1 unlockRule:
      //   "3 consecutive attempts ... with shapeScore >= 0.75 and zero
      //    WRONG_FOOT"
      // STEP_TOO_LARGE is NOT in it, and the rule's own note explains which
      // codes were deliberately excluded and why. So content has already made
      // a severity statement about exactly this pair — WRONG_FOOT blocks
      // progression, STEP_TOO_LARGE does not.
      final String styleDoc = File(
              '${repo.path}/content/styles/salsa_shines/style.json')
          .readAsStringSync();
      expect(styleDoc, contains('zero WRONG_FOOT'));

      final int unlockAt = styleDoc.indexOf('zero WRONG_FOOT');
      final String unlockBlock = styleDoc.substring(
          unlockAt, (unlockAt + 900).clamp(0, styleDoc.length));
      expect(unlockBlock, isNot(contains('STEP_TOO_LARGE')),
          reason: 'if STEP_TOO_LARGE ever enters the unlock rule, the derived '
              'ordering below loses its basis and must be re-derived');
    });
  });
}

Directory _findRepoRoot() {
  Directory d = Directory.current;
  while (!File('${d.path}/pubspec.yaml').existsSync() ||
      !Directory('${d.path}/content').existsSync()) {
    final Directory up = d.parent;
    if (up.path == d.path) throw StateError('repo root not found');
    d = up;
  }
  return d;
}
