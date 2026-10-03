import 'dart:async';

import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

void main() {
  test('eager native close cannot admit a successor before its ACK', () async {
    final owners = AppStoreOwnerRegistry();
    final ticket = owners.capture(_alice);
    final ack = Completer<void>();
    var closeCalls = 0;
    ticket.registerResource(() {
      closeCalls++;
      // A native hook may synchronously re-enter admission before returning.
      expect(() => owners.capture(_bob),
          throwsA(isA<SessionStoreRetiredException>()));
      return ack.future;
    });
    final closing = owners.retireOwner(_alice);
    expect(closeCalls, 1);
    expect(ticket.isActive, isFalse);
    expect(owners.retirementBarrier, isNotNull);
    owners.resumeOwner(_bob);
    expect(() => owners.capture(_bob),
        throwsA(isA<SessionStoreRetiredException>()));
    ack.complete();
    await closing;
    owners.resumeOwner(_bob);
    expect(owners.capture(_bob).isActive, isTrue);
  });

  test('acknowledged ticket pruning cannot close an old resource twice', () async {
    final owners = AppStoreOwnerRegistry();
    final old = owners.capture(_alice);
    var closeCalls = 0;
    old.registerResource(() async { closeCalls++; });
    await owners.retireOwner(_alice);
    await owners.retireOwner(_alice);
    owners.resumeOwner(_alice);
    final fresh = owners.capture(_alice);
    expect(identical(old, fresh), isFalse);
    expect(closeCalls, 1);
    await owners.retireOwner(_alice);
    expect(closeCalls, 1);
  });

  test('failed native ACK remains quarantined through repeat retirement', () async {
    final owners = AppStoreOwnerRegistry();
    var closeCalls = 0;
    owners.capture(_alice).registerResource(() {
      closeCalls++;
      throw StateError('close-uncertain');
    });
    await expectLater(owners.retireOwner(_alice), throwsStateError);
    await expectLater(owners.retireOwner(_alice), throwsStateError);
    owners.resumeOwner(_alice);
    owners.resumeOwner(_bob);
    for (final user in [_alice, _bob]) {
      expect(() => owners.capture(user),
          throwsA(isA<SessionStoreRetiredException>()));
    }
    expect(closeCalls, 1);
  });
}
