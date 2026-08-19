/// `resolveScoredMomentBin` — the scored-moment→phase-bin resolver
/// (`lib/app/live/live_session.dart`).
///
/// ## Why this file exists
///
/// `test/end_to_end_test.dart` and `test/fallback_liveness_test.dart` both
/// derive their own `momentA`/`momentB` correctly (`phases[].id` →
/// `phases[].enter.phaseBin`, reading real content) and feed them straight to
/// `DanceJudge.judge()` — neither test ever calls the LIVE app's own
/// resolution path. `LiveSession._moment()` had zero coverage, and its own
/// logic (looking for `phaseBin` directly on a `scoredMoments` entry — a key
/// the content schema never puts there) always missed and silently fell
/// through to an arbitrary default. This file closes that gap: it asserts
/// the SAME correct resolution the other two tests already trust, but
/// through the function the live app actually calls.
///
/// Real content, not invented fixtures — same discipline as the sibling
/// tests: `ss_shine_footwork.json`'s bins (1, 29) and `hh_bounce.json`'s
/// phase-less "bottom" moment are read from the files that ship.
library;

import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/live/live_session.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readStep(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();

void main() {
  group('resolveScoredMomentBin — ss_shine_footwork (fixed-bin phases)', () {
    late Map<String, dynamic> step;

    setUpAll(() {
      step = _readStep(
          'content/styles/salsa_shines/steps/ss_shine_footwork.json');
    });

    test('MEASURED: settle_a resolves to phaseBin 1, not the arbitrary '
        'default (0)', () {
      // Both happen to be small integers here — the point of this test is
      // that they are DIFFERENT numbers, so a regression back to the
      // default cannot pass by coincidence.
      expect(resolveScoredMomentBin(step, 64, 'a'), 1,
          reason: "content/styles/salsa_shines/steps/ss_shine_footwork.json "
              "phases[].id=='settle_a' declares enter.phaseBin: 1 — the "
              "resolver must find THAT, not fall through to the id=='a' "
              "default of 0");
    });

    test('MEASURED: settle_b resolves to phaseBin 29, not the arbitrary '
        'default (half of 64 = 32)', () {
      expect(resolveScoredMomentBin(step, 64, 'b'), 29,
          reason: "phases[].id=='settle_b' declares enter.phaseBin: 29 — "
              "the old code's fallback (phaseBins ~/ 2 == 32) is a "
              "DIFFERENT, wrong bin, not a rounding of the right one");
    });

    test('SABOTAGE — remove the phaseBin from settle_a, resolver falls to '
        'the documented default rather than inventing a number', () {
      final Map<String, dynamic> sabotaged =
          jsonDecode(jsonEncode(step)) as Map<String, dynamic>;
      final List<Object?> phases = sabotaged['phases'] as List<Object?>;
      final Map<String, dynamic> settleA =
          (phases.firstWhere((p) => (p as Map)['id'] == 'settle_a') as Map)
              .cast<String, dynamic>();
      (settleA['enter'] as Map).remove('phaseBin');

      expect(resolveScoredMomentBin(sabotaged, 64, 'a'), 0,
          reason: 'with no phaseBin to find, the resolver must fall to the '
              'named default (0), not throw and not silently reuse the '
              'pre-sabotage value from a stale read');
    });
  });

  group('resolveScoredMomentBin — hh_bounce (live-FSM phases, no phaseBin)', () {
    late Map<String, dynamic> step;

    setUpAll(() {
      step = _readStep(
          'content/styles/hip_hop_foundations/steps/hh_bounce.json');
    });

    test("MEASURED: hh_bounce's phases are metric/op gates with no "
        'phaseBin field at all', () {
      final List<Object?> phases = step['phases'] as List<Object?>;
      final Map<String, dynamic> bottom =
          (phases.firstWhere((p) => (p as Map)['id'] == 'bottom') as Map)
              .cast<String, dynamic>();
      expect((bottom['enter'] as Map).containsKey('phaseBin'), isFalse,
          reason: 'this assertion is the reason the OTHER test in this '
              'group is allowed to expect the arbitrary default — if this '
              'ever becomes true, hh_bounce has a real bin to resolve to '
              'and the test below should change to expect it');
    });

    test('the resolver still returns the SAME arbitrary default it always '
        'has for this style — this fix does not change bounce behaviour, '
        'it only corrects styles that DO have a resolvable bin', () {
      expect(resolveScoredMomentBin(step, 32, 'a'), 0);
      expect(resolveScoredMomentBin(step, 32, 'b'), 16);
    });
  });
}
