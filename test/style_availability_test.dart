import 'package:choreia/app/course_catalog.dart';
import 'package:choreia/app/style_availability.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two axes in, one answer out — and the answer is never stored.
///
/// The load-bearing case is `live` + a closed release gate. That combination is
/// REAL today (`salsa_shines`: a scored lesson exists, BPM is disputed), and it
/// is the one a naive surface gets wrong by reading the lattice alone.
void main() {
  BlockedGate styleGate(String id) => BlockedGate(
        scope: GateScope.style,
        id: id,
        why: 'technical text a user should never see: beatsStatus:PENDING',
        unblockedBy: 'tools/beat_annotate.py live tap',
      );

  const BlockedGate lessonGate = BlockedGate(
    scope: GateScope.lesson,
    id: 'ss_l1_basic',
    why: 'the plateau is below what we can measure',
  );

  const BlockedGate codeGate = BlockedGate(
    scope: GateScope.errorCode,
    id: 'NO_WEIGHT_TRANSFER',
    why: 'threshold below noise floor',
  );

  StyleView view(String? status, List<BlockedGate> gates) => StyleView.derive(
      styleId: 's', contentStatus: status, blockedGates: gates);

  group('the two axes stay independent', () {
    test('THE CASE THAT MATTERS: live + closed release gate is NOT openable',
        () {
      final StyleView v = view('live', <BlockedGate>[styleGate('bpmResolved')]);
      expect(v.availability, Availability.gatedByRelease);
      expect(v.isOpenable, isFalse,
          reason: 'promising a gated style is the mirror image of the '
              'coming-soon ban — the content is real, the door is not open');
      // Both axes survive the derivation: neither is overwritten by the other.
      expect(v.contentStatus, 'live',
          reason: 'content reality must not be rewritten to fit release '
              'reality — that is the C-101 proxy defect coming back');
      expect(v.releaseBlockers, hasLength(1));
    });

    test('live with no release gate IS openable', () {
      expect(view('live', const <BlockedGate>[]).isOpenable, isTrue);
    });

    test('demoOpen with no release gate is openable — teaching counts', () {
      expect(view('demoOpen', const <BlockedGate>[]).isOpenable, isTrue);
    });

    test('comingSoon stays comingSoon, gate or no gate', () {
      expect(view('comingSoon', const <BlockedGate>[]).availability,
          Availability.comingSoon);
      expect(
          view('comingSoon', <BlockedGate>[styleGate('bpmResolved')])
              .availability,
          Availability.gatedByRelease,
          reason: 'a closed gate is the more specific truth, and it is the one '
              'with a way out worth naming');
    });

    test('LESSON and ERROR-CODE gates do NOT gate the style', () {
      // Only style-scope gates are release gates. A demo-only lesson or a
      // blocked check is a fact ABOUT content, already reflected in the
      // lattice; counting it twice would close a style that is genuinely open.
      final StyleView v =
          view('demoOpen', const <BlockedGate>[lessonGate, codeGate]);
      expect(v.availability, Availability.openable);
      expect(v.releaseBlockers, isEmpty);
    });

    test('onHold and excluded are not overridden by gates', () {
      expect(view('onHold', <BlockedGate>[styleGate('x')]).availability,
          Availability.onHold);
      expect(view('excluded', <BlockedGate>[styleGate('x')]).availability,
          Availability.excluded);
    });
  });

  group('what the user is told', () {
    test('an unopenable style always carries a reason', () {
      for (final StyleView v in <StyleView>[
        view('live', <BlockedGate>[styleGate('bpmResolved')]),
        view('comingSoon', const <BlockedGate>[]),
        view('onHold', const <BlockedGate>[]),
      ]) {
        expect(v.userFacingReason, isNotNull,
            reason: '${v.availability} with no reason is the silence J-066 '
                'forbids');
        expect(v.userFacingReason, isNotEmpty);
      }
    });

    test('an openable style says nothing extra', () {
      expect(view('live', const <BlockedGate>[]).userFacingReason, isNull);
    });

    test('an UNKNOWN gate falls back to plain words, never raw technical text',
        () {
      final BlockedGate unknown = styleGate('someGateAddedTomorrow');
      final StyleView v = view('live', <BlockedGate>[unknown]);
      expect(v.userFacingReason, AvailabilityStrings.genericGate);
      expect(v.userFacingReason, isNot(contains('beatsStatus')),
          reason: 'the raw blockedBy string tells a dancer nothing; leaking it '
              'is how jargon reaches a surface');
      expect(v.userFacingReason, isNot(contains(unknown.why)));
    });

    test('the known BPM gate is explained in dance terms', () {
      final String? text =
          view('live', <BlockedGate>[styleGate('bpmResolved')]).userFacingReason;
      expect(text, contains('beat'));
      expect(text, isNot(contains('BPM')),
          reason: 'the user-facing sentence names what we are unsure of, not '
              'the field name');
      expect(text, isNot(contains('bpmResolved')));
    });
  });

  group('derivation is not storage', () {
    test('the same inputs recompute the same answer, and changing ONE axis '
        'changes the answer without touching the other', () {
      const String status = 'live';
      final StyleView gated =
          view(status, <BlockedGate>[styleGate('bpmResolved')]);
      final StyleView open = view(status, const <BlockedGate>[]);

      // Content axis identical, release axis differs → different answer.
      expect(gated.contentStatus, open.contentStatus);
      expect(gated.isOpenable, isFalse);
      expect(open.isOpenable, isTrue,
          reason: 'opening a gate must flip every surface at once, which only '
              'works while nobody has cached the answer');
    });
  });
}
