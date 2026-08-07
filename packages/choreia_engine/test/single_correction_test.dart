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
      // The judge emits exactly four codes. Two carry verdicts and MUST be
      // ranked; two are structurally noVerdict and must NOT be, because
      // ranking them would imply they could become a correction.
      const Set<String> emitted = <String>{
        'STEP_TOO_LARGE',
        'NO_WEIGHT_TRANSFER',
        'STEP_LATE',
        'WRONG_FOOT',
      };
      const Set<String> structurallyMute = <String>{
        'NO_WEIGHT_TRANSFER',
        'STEP_LATE',
      };

      final Set<String> mustRank = emitted.difference(structurallyMute);
      expect(correctionPriority.toSet(), mustRank,
          reason: 'a new fireable code added to DanceJudge without a rank '
              'would fall to the unranked fallback and quietly lose every '
              'tie-break. Rank it, or prove it is structurally mute.');
    });

    test('no duplicates — a duplicated rank is an ambiguous order', () {
      expect(correctionPriority.toSet(), hasLength(correctionPriority.length));
    });
  });
}
