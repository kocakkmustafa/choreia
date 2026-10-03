import 'dart:async';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/account_recovery_host.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

final class _ObservedRecovery extends ValueNotifier<bool> {
  _ObservedRecovery(super.value);
  bool get listening => hasListeners;
}

void main() {
  Widget host(ValueNotifier<String?> user, ValueNotifier<bool> recovery,
          AppStoreOwnerRegistry owners) =>
      ChoreiaAccountHost(
        accountUserId: user,
        passwordRecovery: recovery,
        owners: owners,
        builder: (context, navigationKey, recovering, ownerEpoch) =>
            MaterialApp(
          key: navigationKey,
          home: Scaffold(
              body: Builder(
                  builder: (context) => Column(children: [
                        Text(recovering ? 'Account recovery' : 'Fresh shell'),
                        TextButton(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const Scaffold(
                                        body: Text('Pending live route')))),
                            child: const Text('Live')),
                      ]))),
        ),
      );

  testWidgets('queued old session event cannot retire the live successor owner', (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final owners = AppStoreOwnerRegistry();
    final events = StreamController<ChoreiaAuthSessionEvent>.broadcast(sync: true);
    final actual = Object();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    addTearDown(events.close);
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user, passwordRecovery: recovery, owners: owners,
      initialSessionIdentity: actual, currentSessionIdentity: () => actual,
      authSessionChanges: events.stream,
      builder: (context, key, recovery, epoch) => MaterialApp(key: key, home: const Text('live')),
    ));
    final ticket = owners.capture(_alice);
    events.add(ChoreiaAuthSessionEvent('signedIn', Object()));
    await tester.pump();
    expect(ticket.isActive, isTrue);
    expect(identical(owners.capture(_alice), ticket), isTrue);
  });

  testWidgets('readmission waits for acknowledged old owner IO drain', (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    await tester.pumpWidget(host(user, recovery, owners));
    final old = owners.capture(_alice);
    final release = Completer<void>();
    final write = old.run(() => release.future);
    final rejected = expectLater(write, throwsA(isA<Exception>()));
    recovery.value = true;
    recovery.value = false;
    await tester.pump();
    expect(old.isActive, isFalse);
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    release.complete();
    await rejected;
    await tester.pumpAndSettle();
    expect(owners.capture(_alice).isActive, isTrue);
    expect(identical(owners.capture(_alice), old), isFalse);
  });


  testWidgets('cold host inherits pending camera ACK before fresh owner admission', (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    final old = owners.capture(_alice);
    final ack = Completer<void>();
    old.registerResource(() => ack.future);
    final retiring = owners.retireOwner(_alice);
    await tester.pumpWidget(host(user, recovery, owners));
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    ack.complete();
    await retiring;
    await tester.pumpAndSettle();
    expect(owners.capture(_alice).isActive, isTrue);
    expect(identical(owners.capture(_alice), old), isFalse);
  });

  testWidgets('cold host inherits failed camera close quarantine', (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    owners.capture(_alice).registerResource(
        () => Future<void>.error(StateError('close-uncertain')));
    await expectLater(owners.retireOwner(_alice), throwsStateError);
    await tester.pumpWidget(host(user, recovery, owners));
    await tester.pumpAndSettle();
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-UUID recovery retires immediately and resets nested routes',
      (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = _ObservedRecovery(false);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    await tester.pumpWidget(host(user, recovery, owners));
    final oldTicket = owners.capture(_alice);
    await tester.tap(find.text('Live'));
    await tester.pumpAndSettle();
    expect(find.text('Pending live route'), findsOneWidget);
    recovery.value = true;
    // Retirement happens during notification, before the next Flutter frame.
    expect(oldTicket.isActive, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Account recovery'), findsOneWidget);
    expect(find.text('Pending live route'), findsNothing);
    expect(find.byType(Navigator), findsOneWidget);
    recovery.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Fresh shell'), findsOneWidget);
    expect(identical(owners.capture(_alice), oldTicket), isFalse);
  });

  testWidgets('initial recovery uses one account root without owner admission',
      (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = _ObservedRecovery(true);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    await tester.pumpWidget(host(user, recovery, owners));
    expect(find.text('Account recovery'), findsOneWidget);
    expect(find.text('Fresh shell'), findsNothing);
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
  });

  testWidgets('replacement detaches recovery listener and B keeps its lifetime',
      (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final oldSignal = _ObservedRecovery(false);
    final nextSignal = _ObservedRecovery(false);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(oldSignal.dispose);
    addTearDown(nextSignal.dispose);
    await tester.pumpWidget(host(user, oldSignal, owners));
    await tester.pumpWidget(host(user, nextSignal, owners));
    expect(oldSignal.listening, isFalse);
    expect(nextSignal.listening, isTrue);
    user.value = _bob;
    final bob = owners.capture(_bob);
    oldSignal.value = true;
    await tester.pump();
    expect(bob.isActive, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(nextSignal.listening, isFalse);
    expect(bob.isActive, isFalse);
  });

  testWidgets(
      'verifying and unavailable close admission until canonical phase permits it',
      (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    // This fixture drives only the host resource seam. MotionIdentityGate
    // remains the product's UI identity authority.
    final phase = ValueNotifier<int>(0);
    final owners = AppStoreOwnerRegistry();
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    addTearDown(phase.dispose);
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user,
      passwordRecovery: recovery,
      owners: owners,
      identityChanges: phase,
      canAdmitOwner: () => phase.value == 0,
      builder: (context, key, recovery, ownerEpoch) => MaterialApp(
          key: key, home: const Scaffold(body: Text('Canonical gate child'))),
    ));
    final old = owners.capture(_alice);
    phase.value = 1; // verifying
    expect(old.isActive, isFalse);
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    phase.value = 2; // unavailable
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    phase.value = 0; // canonical verified
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    await tester.pumpAndSettle();
    expect(identical(owners.capture(_alice), old), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'ordinary token refresh keeps route resources but replacement retires before frame',
      (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final events =
        StreamController<ChoreiaAuthSessionEvent>.broadcast(sync: true);
    final owners = AppStoreOwnerRegistry();
    var retired = 0;
    ValueListenable<int>? epoch;
    void observeEpoch() => retired++;
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    addTearDown(events.close);
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user,
      passwordRecovery: recovery,
      owners: owners,
      authSessionChanges: events.stream,
      initialSessionIdentity: 'initial',
      builder: (context, key, recovery, ownerEpoch) {
        epoch ??= ownerEpoch;
        return MaterialApp(key: key, home: const Scaffold());
      },
    ));
    epoch!.addListener(observeEpoch);
    final ticket = owners.capture(_alice);
    events.add(const ChoreiaAuthSessionEvent('tokenRefreshed', 'refreshed'));
    expect(retired, 0);
    expect(ticket.isActive, isTrue);
    events.add(const ChoreiaAuthSessionEvent('signedIn', 'replacement'));
    expect(retired, 1);
    expect(ticket.isActive, isFalse);
    epoch!.removeListener(observeEpoch);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('same Session replay stays active but a fresh Session retires resources',
      (tester) async {
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final events = StreamController<ChoreiaAuthSessionEvent>.broadcast(sync: true);
    final owners = AppStoreOwnerRegistry();
    final initialSession = Object();
    final refreshedSession = Object();
    final firstLogin = Object();
    final secondLogin = Object();
    ValueListenable<int>? epoch;
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    addTearDown(events.close);
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user, passwordRecovery: recovery, owners: owners,
      authSessionChanges: events.stream, initialSessionIdentity: initialSession,
      builder: (context, key, recovering, ownerEpoch) {
        epoch = ownerEpoch;
        return MaterialApp(key: key, home: const Scaffold());
      },
    ));
    final first = owners.capture(_alice);
    final initial = epoch!.value;
    events.add(ChoreiaAuthSessionEvent('tokenRefreshed', refreshedSession));
    expect(epoch!.value, initial);
    expect(first.isActive, isTrue);
    events.add(ChoreiaAuthSessionEvent('signedIn', refreshedSession));
    expect(epoch!.value, initial);
    expect(first.isActive, isTrue);
    expect(identical(owners.currentTicket(_alice), first), isTrue);
    events.add(ChoreiaAuthSessionEvent('signedIn', firstLogin));
    expect(epoch!.value, initial + 1);
    expect(first.isActive, isFalse);
    expect(() => owners.capture(_alice), throwsA(isA<Exception>()));
    await tester.pumpAndSettle();
    final successor = owners.capture(_alice);
    events.add(ChoreiaAuthSessionEvent('signedIn', firstLogin));
    expect(epoch!.value, initial + 1);
    expect(successor.isActive, isTrue);
    expect(identical(owners.currentTicket(_alice), successor), isTrue);
    events.add(ChoreiaAuthSessionEvent('signedIn', secondLogin));
    expect(epoch!.value, initial + 2);
    expect(successor.isActive, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settled same-registry notice cannot retire a fresh A lifetime',
      (tester) async {
    final directory = Directory.systemTemp.createTempSync('choreia-fence-replay-');
    final owners = AppStoreOwnerRegistry();
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final events = StreamController<ChoreiaAuthSessionEvent>.broadcast(sync: true);
    final controller = ChoreiaAccountHostController();
    ValueListenable<int>? epoch;
    ChoreiaNamespaceFence? notice;
    addTearDown(() => directory.deleteSync(recursive: true));
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    addTearDown(events.close);
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user, passwordRecovery: recovery,
      owners: owners, controller: controller, authSessionChanges: events.stream,
      builder: (context, key, recovering, ownerEpoch) {
        epoch = ownerEpoch;
        return MaterialApp(key: key, home: const Scaffold());
      },
    ));
    final old = owners.capture(_alice);
    final initial = epoch!.value;
    await tester.runAsync(() => clearLocalHistoryFor(_alice,
        owners: owners, supportDirectory: directory,
        onNamespaceFenced: (fence) {
          notice = fence;
          expect(identical(fence.owners, owners), isTrue);
          expect(fence.isActive, isTrue);
          expect(controller.namespaceFenced(fence), isTrue);
        }));
    expect(old.isActive, isFalse);
    expect(epoch!.value, initial + 1);
    expect(controller.requiresAccountRoute, isTrue);
    expect(notice!.isActive, isFalse);

    // A fresh signedIn after the erase settles resumes this exact registry.
    // Replaying the prior notice must be rejected by its inactive-fence guard,
    // independent of registry/UUID mismatch or an already-retired route latch.
    events.add(const ChoreiaAuthSessionEvent('signedIn', 'fresh-session'));
    await tester.pumpAndSettle();
    final fresh = owners.capture(_alice);
    final resumedEpoch = epoch!.value;
    expect(fresh.isActive, isTrue);
    expect(controller.requiresAccountRoute, isFalse);
    expect(controller.namespaceFenced(notice!), isFalse);
    expect(epoch!.value, resumedEpoch);
    expect(fresh.isActive, isTrue);
    expect(identical(owners.currentTicket(_alice), fresh), isTrue);
    expect(controller.requiresAccountRoute, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('foreign registry namespace notice cannot retire host',
      (tester) async {
    final directory = Directory.systemTemp.createTempSync('choreia-fence-scope-');
    final owners = AppStoreOwnerRegistry();
    final foreign = AppStoreOwnerRegistry();
    final user = ValueNotifier<String?>(_alice);
    final recovery = ValueNotifier<bool>(false);
    final controller = ChoreiaAccountHostController();
    ValueListenable<int>? epoch;
    ChoreiaNamespaceFence? notice;
    addTearDown(() => directory.deleteSync(recursive: true));
    addTearDown(user.dispose);
    addTearDown(recovery.dispose);
    await tester.pumpWidget(ChoreiaAccountHost(
      accountUserId: user, passwordRecovery: recovery,
      owners: owners, controller: controller,
      builder: (context, key, recovering, ownerEpoch) {
        epoch = ownerEpoch;
        return MaterialApp(key: key, home: const Scaffold());
      },
    ));
    final ticket = owners.capture(_alice);
    final initial = epoch!.value;
    await tester.runAsync(() => clearLocalHistoryFor(_alice,
        owners: foreign, supportDirectory: directory,
        onNamespaceFenced: (fence) {
          notice = fence;
          expect(controller.namespaceFenced(fence), isFalse);
        }));
    expect(ticket.isActive, isTrue);
    expect(epoch!.value, initial);
    expect(controller.requiresAccountRoute, isFalse);
    expect(notice!.isActive, isFalse);
    expect(controller.namespaceFenced(notice!), isFalse);
    expect(epoch!.value, initial);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller.namespaceFenced(notice!), isFalse);
  });
}
