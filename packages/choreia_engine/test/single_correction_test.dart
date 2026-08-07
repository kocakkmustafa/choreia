import 'dart:io';

import 'package:choreia_engine/choreia_engine.dart';
import 'package:test/test.dart';

/// C-136 (a)+(b): the single-correction rule and the order behind it.
void main() {
  ErrorFinding fired(String code) => ErrorFinding(code, Verdict.error);
  ErrorFinding ok(String code) => ErrorFinding(code, Verdict.ok);
  ErrorFinding mute(String code) =>
      ErrorFinding(code, Verdict.noVerdict, why: 'blocked');

  JudgeResult r(List<ErrorFinding> f) =>
      JudgeResult(measurements: const <String, double>{}, findings: f);

  group('one correction, chosen by a derived order', () {
    test('when both fire, WRONG_FOOT wins', () {
      final JudgeResult res =
          r(<ErrorFinding>[fired('STEP_TOO_LARGE'), fired('WRONG_FOOT')]);
      expect(res.correction!.code, 'WRONG_FOOT',
          reason: "content's own unlock rule gates progression on zero "
              'WRONG_FOOT and says nothing about STEP_TOO_LARGE');
      expect(res.otherFiredCount, 1);
    });

    test('list order does not decide it', () {
      // Same pair, opposite order in the findings list. If this passes only in
      // one direction, the "priority" is really just whichever the judge
      // happened to append first.
      expect(
          r(<ErrorFinding>[fired('WRONG_FOOT'), fired('STEP_TOO_LARGE')])
              .correction!
              .code,
          'WRONG_FOOT');
    });

    test('a lone fired finding is the correction whatever it is', () {
      expect(r(<ErrorFinding>[fired('STEP_TOO_LARGE')]).correction!.code,
          'STEP_TOO_LARGE');
      expect(r(<ErrorFinding>[fired('STEP_TOO_LARGE')]).otherFiredCount, 0);
    });

    test('nothing fired means NO correction — not a quiet first finding', () {
      final JudgeResult res = r(<ErrorFinding>[
        ok('STEP_TOO_LARGE'),
        ok('WRONG_FOOT'),
        mute('STEP_LATE'),
      ]);
      expect(res.correction, isNull);
      expect(res.otherFiredCount, 0);
    });

    test('a blocked check is never promoted into a correction', () {
      // The whole point of noVerdict: "we could not check this" must not be
      // rendered as "you did this wrong" just because nothing else fired.
      expect(r(<ErrorFinding>[mute('STEP_LATE'), mute('NO_WEIGHT_TRANSFER')])
              .correction,
          isNull);
    });

    test('an UNRANKED code ranks last, it does not silently outrank', () {
      final JudgeResult res =
          r(<ErrorFinding>[fired('SOME_NEW_CODE'), fired('WRONG_FOOT')]);
      expect(res.correction!.code, 'WRONG_FOOT',
          reason: 'an unranked code must not beat the one content says blocks '
              'progression — see the companion gate below, which fails loudly '
              'rather than relying on this fallback');
    });
  });

  group('the order cannot rot silently', () {
    test('every code the judge can emit is ranked or deliberately mute', () {
      // DERIVED FROM A REAL JUDGE RUN, NOT LISTED (C-153).
      //
      // This assertion previously compared `correctionPriority` against two
      // hand-written sets of "codes the judge emits" and "codes that are
      // structurally mute". That is the exemption-list failure JabLab measured:
      // if DanceJudge gained a fifth code, the literals would not move, the
      // difference would be computed from a fiction, and this test would stay
      // green while the new code fell to the unranked fallback and lost every
      // tie-break. Asking the judge removes the fiction.
      final DanceReference shine = DanceReference.load(
          File('${_findRepoRoot().path}/content/references/'
              'ss_shine_footwork.json'));
      final JudgeResult run = DanceJudge(reference: shine)
          .judge(shine.angles, momentA: 1, momentB: 29);

      expect(run.findings, isNotEmpty,
          reason: 'an empty run makes every set below vacuously equal — the '
              'gate would pass by measuring nothing (family lesson 4)');

      final Set<String> canCarryAVerdict = run.findings
          .where((ErrorFinding f) => f.verdict != Verdict.noVerdict)
          .map((ErrorFinding f) => f.code)
          .toSet();

      expect(correctionPriority.toSet(), canCarryAVerdict,
          reason: 'a new fireable code added to DanceJudge without a rank '
              'would fall to the unranked fallback and quietly lose every '
              'tie-break. Rank it, or prove it is structurally mute.');
    });

    test('a mute code is never ranked', () {
      // The other direction, and it is not symmetric: ranking a structurally
      // mute code would imply it could become a correction, which is exactly
      // the claim `noVerdict` exists to refuse.
      final DanceReference shine = DanceReference.load(
          File('${_findRepoRoot().path}/content/references/'
              'ss_shine_footwork.json'));
      final Set<String> mute = DanceJudge(reference: shine)
          .judge(shine.angles, momentA: 1, momentB: 29)
          .findings
          .where((ErrorFinding f) => f.verdict == Verdict.noVerdict)
          .map((ErrorFinding f) => f.code)
          .toSet();

      expect(mute, isNotEmpty);
      for (final String code in mute) {
        expect(correctionPriority, isNot(contains(code)),
            reason: '$code cannot carry a verdict, so ranking it says it '
                'could be the one correction');
      }
    });

    test('no duplicates — a duplicated rank is an ambiguous order', () {
      expect(correctionPriority.toSet(), hasLength(correctionPriority.length));
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
