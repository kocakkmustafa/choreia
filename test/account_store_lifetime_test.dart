import 'dart:async';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:choreia/app/history/session_store_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

SessionRecord _record(String lesson) => SessionRecord(
      lessonId: lesson,
      completedAt: DateTime.utc(2026, 10, 2),
      workedSeconds: 30,
      unitsCompleted: 1,
      plannedUnits: 1,
      unitLabel: 'cycle',
      lessonClass: 'demoOnly',
    );

/// Hold a real store inside dispatched filesystem IO, rather than holding an
/// unrelated fake callback that bypasses Core's write lease.
final class _HeldExistsFile implements File {
  _HeldExistsFile(this.inner, this.entered, this.release);
  final File inner;
  final Completer<void> entered;
  final Completer<void> release;
  @override
  String get path => inner.path;
  @override
  File get absolute => inner.absolute;
  @override
  Future<bool> exists() async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return inner.exists();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
      'Unexpected File operation: ${invocation.memberName}');
}

void main() {
  late Directory directory;
  late AppStoreOwnerRegistry owners;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('choreia-owner-drain-');
    owners = AppStoreOwnerRegistry();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test('all opened JSONL handles share one synchronously retired owner lease',
      () async {
    final first = (await openAppSessionStore(
        accountUserId: _alice,
        supportDirectory: directory,
        owners: owners)) as JsonlSessionStore;
    final second = await openAppSessionStore(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    expect(
        identical(first.writeLease, (second as JsonlSessionStore).writeLease),
        isTrue);
    final file = sessionFileFor(directory, _alice)
      ..writeAsStringSync('preserved on retirement');
    final retirement = owners.retireOwner(_alice);
    expect(first.writeLease.isActive, isFalse);
    await expectLater(second.append(_record('late')),
        throwsA(isA<SessionStoreRetiredException>()));
    await retirement;
    expect(file.readAsStringSync(), 'preserved on retirement');
  });

  test('delayed directory opener retains its pre-await owner ticket', () async {
    final location = Completer<Directory>();
    final opening = openAppSessionStore(
        accountUserId: _alice,
        owners: owners,
        directoryResolver: () => location.future);
    final rejected =
        expectLater(opening, throwsA(isA<SessionStoreRetiredException>()));
    sessionFileFor(directory, _alice).writeAsStringSync('old owner namespace');
    await clearLocalHistoryFor(_alice,
        supportDirectory: directory, owners: owners);
    final fresh = await openAppSessionStore(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    await fresh.append(_record('fresh'));
    location.complete(directory);
    await rejected;
    expect((await fresh.recent()).single.lessonId, 'fresh');
  });

  test('exact deletion waits for admitted IO and blocks fresh same-owner opens',
      () async {
    final target = sessionFileFor(directory, _alice);
    await target.writeAsString('old');
    await File('${target.path}.tmp').writeAsString('old tmp');
    await sessionFileFor(directory, null).writeAsString('guest');
    await sessionFileFor(directory, _bob).writeAsString('bob');
    final entered = Completer<void>();
    final release = Completer<void>();
    final first = await openAppSessionStore(
        accountUserId: _alice,
        supportDirectory: directory,
        owners: owners,
        fileFactory: (file) => _HeldExistsFile(file, entered, release));
    final writing = first.append(_record('must not return after erase'));
    final rejected =
        expectLater(writing, throwsA(isA<SessionStoreRetiredException>()));
    await entered.future;
    var erased = false;
    final erasing = clearLocalHistoryFor(_alice,
            supportDirectory: directory, owners: owners)
        .then((_) => erased = true);
    expect(owners.isErasing(_alice), isTrue);
    await expectLater(
        openAppSessionStore(
            accountUserId: _alice, supportDirectory: directory, owners: owners),
        throwsA(isA<SessionStoreRetiredException>()));
    await Future<void>.delayed(Duration.zero);
    expect(erased, isFalse);
    expect(await target.readAsString(), 'old');
    release.complete();
    await rejected;
    await erasing;
    expect(await target.exists(), isFalse);
    expect(await File('${target.path}.tmp').exists(), isFalse);
    expect(await sessionFileFor(directory, null).readAsString(), 'guest');
    expect(await sessionFileFor(directory, _bob).readAsString(), 'bob');
    final fresh = await openAppSessionStore(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    await fresh.append(_record('fresh after barrier'));
    expect((await fresh.recent()).single.lessonId, 'fresh after barrier');
  });

  test('explicit stale guarded local clear preserves a fresh same UUID owner',
      () async {
    final ticket = owners.capture(_alice);
    await owners.retireOwner(_alice);
    owners.resumeOwner(_alice);
    final fresh = await openAppSessionStore(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    await fresh.append(_record('fresh A'));
    await expectLater(
        clearLocalHistoryFor(_alice,
            supportDirectory: directory, owners: owners, expectedOwner: ticket),
        throwsA(isA<StaleAccountDeletionException>()));
    expect((await fresh.recent()).single.lessonId, 'fresh A');
    expect(owners.isErasing(_alice), isFalse);
  });

  test('typed namespace fence is published before path lookup and data IO',
      () async {
    final ticket = owners.capture(_alice);
    final location = Completer<Directory>();
    var notified = false;
    var located = false;
    ChoreiaNamespaceFence? notice;
    final erasing = clearLocalHistoryFor(_alice, owners: owners,
        onNamespaceFenced: (fence) {
          notified = true;
          notice = fence;
          expect(identical(fence.owners, owners), isTrue);
          expect(fence.userId, _alice);
          expect(fence.isActive, isTrue);
          expect(ticket.isActive, isFalse);
          expect(located, isFalse);
        }, directoryResolver: () {
          located = true;
          expect(notified, isTrue);
          return location.future;
        });
    expect(notified, isTrue);
    expect(located, isFalse);
    expect(() => owners.capture(_alice),
        throwsA(isA<SessionStoreRetiredException>()));
    location.complete(directory);
    await erasing;
    expect(located, isTrue);
    expect(notice!.isActive, isFalse);
  });

  test('confirmed A fence drains a retired epoch and the fresh A epoch together',
      () async {
    final target = sessionFileFor(directory, _alice)
      ..writeAsStringSync('A retained while admitted IO runs');
    final entered = Completer<void>();
    final release = Completer<void>();
    final old = await openAppSessionStore(accountUserId: _alice,
        supportDirectory: directory, owners: owners,
        fileFactory: (file) => _HeldExistsFile(file, entered, release));
    final oldWriting = old.append(_record('old admitted epoch'));
    final oldRejected = expectLater(oldWriting,
        throwsA(isA<SessionStoreRetiredException>()));
    await entered.future;
    final retiring = owners.retireOwner(_alice);
    owners.resumeOwner(_alice);
    final fresh = await openAppSessionStore(accountUserId: _alice,
        supportDirectory: directory, owners: owners);
    final freshTicket = owners.currentTicket(_alice)!;
    var erased = false;
    final erasing = clearLocalHistoryFor(_alice,
        supportDirectory: directory, owners: owners,
        onNamespaceFenced: (fence) {
          expect(fence.isActive, isTrue);
          expect(freshTicket.isActive, isFalse);
        }).then((_) => erased = true);
    await Future<void>.delayed(Duration.zero);
    expect(erased, isFalse);
    expect(target.readAsStringSync(), 'A retained while admitted IO runs');
    await expectLater(fresh.recent(),
        throwsA(isA<SessionStoreRetiredException>()));
    await expectLater(openAppSessionStore(accountUserId: _alice,
        supportDirectory: directory, owners: owners),
        throwsA(isA<SessionStoreRetiredException>()));
    release.complete();
    await oldRejected;
    await retiring;
    await erasing;
    expect(erased, isTrue);
    expect(target.existsSync(), isFalse);
  });

  test('invalid owner rejects before directory resolution', () async {
    var resolutions = 0;
    await expectLater(
        clearLocalHistoryFor('../guest', owners: owners,
            directoryResolver: () async {
          resolutions++;
          return directory;
        }),
        throwsArgumentError);
    expect(resolutions, 0);
  });

  test(
      'failed cleanup keeps admission closed until an exact receipt retry succeeds',
      () async {
    final file = sessionFileFor(directory, _alice)
      ..writeAsStringSync('keep until retry');
    await expectLater(
        clearLocalHistoryFor(_alice,
            owners: owners,
            directoryResolver: () async =>
                throw const FileSystemException('unavailable')),
        throwsA(isA<FileSystemException>()));
    expect(owners.isErasing(_alice), isTrue);
    owners.resumeOwner(_alice);
    expect(() => owners.capture(_alice),
        throwsA(isA<SessionStoreRetiredException>()));
    expect(file.readAsStringSync(), 'keep until retry');
    await clearLocalHistoryFor(_alice,
        owners: owners, supportDirectory: directory);
    expect(owners.isErasing(_alice), isFalse);
    expect(file.existsSync(), isFalse);
    expect(owners.capture(_alice).isActive, isTrue);
  });

  test(
      'UUID-only runtime reconciliation erases the account-wide same UUID namespace',
      () async {
    // The frozen public runtime callback carries only a UUID, so the host
    // cannot distinguish an old receipt from erasure of the new same-UUID
    // lifetime. Its documented policy is account-wide erasure, not retention.
    final first = owners.capture(_alice);
    await owners.retireOwner(_alice);
    owners.resumeOwner(_alice);
    expect(identical(first, owners.capture(_alice)), isFalse);
    final fresh = await openAppSessionStore(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    await fresh.append(_record('fresh A before old confirmation'));
    await clearLocalHistoryFor(_alice,
        supportDirectory: directory, owners: owners);
    expect(await sessionFileFor(directory, _alice).exists(), isFalse);
    await expectLater(
        fresh.recent(), throwsA(isA<SessionStoreRetiredException>()));
  });
  test('registered camera close ACK drains before confirmed namespace deletion', () async {
    final ticket = owners.capture(_alice);
    final ack = Completer<void>();
    var stops = 0;
    ticket.registerResource(() { stops++; return ack.future; });
    final file = sessionFileFor(directory, _alice)..writeAsStringSync('retained until ACK');
    var settled = false;
    final deletion = clearLocalHistoryFor(_alice,
        supportDirectory: directory, owners: owners).whenComplete(() => settled = true);
    expect(ticket.isActive, isFalse);
    expect(stops, 1);
    expect(owners.isErasing(_alice), isTrue);
    expect(() => owners.capture(_alice), throwsA(isA<SessionStoreRetiredException>()));
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse);
    expect(file.readAsStringSync(), 'retained until ACK');
    ack.complete();
    await deletion.timeout(const Duration(seconds: 2));
    expect(file.existsSync(), isFalse);
    expect(stops, 1);
  });

  test('failed registered camera close keeps namespace quarantine and data', () async {
    final ticket = owners.capture(_alice);
    ticket.registerResource(() => Future<void>.error(StateError('close-uncertain')));
    final file = sessionFileFor(directory, _alice)..writeAsStringSync('retained on failure');
    await expectLater(clearLocalHistoryFor(_alice,
        supportDirectory: directory, owners: owners), throwsStateError);
    expect(ticket.isActive, isFalse);
    expect(owners.isErasing(_alice), isTrue);
    expect(file.readAsStringSync(), 'retained on failure');
    expect(() => owners.capture(_alice), throwsA(isA<SessionStoreRetiredException>()));
  });

  test('ordinary failed resource retirement cannot be bypassed by cold readmission', () async {
    final ticket = owners.capture(_alice);
    ticket.registerResource(() => Future<void>.error(StateError('close-uncertain')));
    await expectLater(owners.retireOwner(_alice), throwsStateError);
    owners.resumeOwner(_alice);
    expect(() => owners.capture(_alice), throwsA(isA<SessionStoreRetiredException>()));
    owners.resumeOwner(_bob);
    expect(() => owners.capture(_bob), throwsA(isA<SessionStoreRetiredException>()));
    await expectLater(owners.retirementBarrier!, throwsStateError);
  });

  test('pending resource retirement blocks a successor owner until ACK', () async {
    final ticket = owners.capture(_alice);
    final ack = Completer<void>();
    ticket.registerResource(() => ack.future);
    final retiring = owners.retireOwner(_alice);
    owners.resumeOwner(_bob);
    expect(() => owners.capture(_bob), throwsA(isA<SessionStoreRetiredException>()));
    ack.complete();
    await retiring.timeout(const Duration(seconds: 2));
    owners.resumeOwner(_bob);
    expect(owners.capture(_bob).isActive, isTrue);
  });

  test('close callback reentry cannot admit another owner before barrier publication', () async {
    final ack = Completer<void>();
    var rejected = false;
    owners.capture(_alice).registerResource(() {
      owners.resumeOwner(_bob);
      expect(() => owners.capture(_bob), throwsA(isA<SessionStoreRetiredException>()));
      rejected = true;
      return ack.future;
    });
    final retiring = owners.retireOwner(_alice);
    expect(rejected, isTrue);
    ack.complete();
    await retiring.timeout(const Duration(seconds: 2));
    owners.resumeOwner(_bob);
    expect(owners.capture(_bob).isActive, isTrue);
  });

}
