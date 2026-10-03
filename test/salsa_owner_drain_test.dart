import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/course/salsa_course.dart';
import 'package:choreia/app/course/salsa_progress.dart';
import 'package:choreia/app/history/account_store_lifetime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

final class _HeldReadFile implements File {
  _HeldReadFile(this.inner, this.entered, this.release);
  final File inner;
  final Completer<void> entered;
  final Completer<void> release;
  @override
  String get path => inner.path;
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    entered.complete();
    await release.future;
    return inner.readAsString(encoding: encoding);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
      'Unexpected File operation: ${invocation.memberName}');
}

void main() {
  late Directory directory;
  late AppStoreOwnerRegistry owners;
  late SalsaCourse course;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('choreia-salsa-drain-');
    owners = AppStoreOwnerRegistry();
    course = SalsaCourse.fromJson(
        jsonDecode(File('content/salsa_on1_course.json').readAsStringSync())
            as Map<String, dynamic>);
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test('delayed Salsa opener cannot join a fresh same-UUID lifetime', () async {
    final location = Completer<Directory>();
    final opening = SalsaProgressStore.open(
        accountUserId: _alice,
        owners: owners,
        directoryResolver: () => location.future);
    final rejected =
        expectLater(opening, throwsA(isA<SessionStoreRetiredException>()));
    await owners.retireOwner(_alice);
    owners.resumeOwner(_alice);
    final fresh = await SalsaProgressStore.open(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    await fresh.record(course, course.lessons.first, SalsaEvidence.practised);
    location.complete(directory);
    await rejected;
    expect((await fresh.read()).events, hasLength(1));
  });

  test('account erase drains dispatched Salsa IO and rejects queued writes',
      () async {
    final seed = await SalsaProgressStore.open(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    final bob = await SalsaProgressStore.open(
        accountUserId: _bob, supportDirectory: directory, owners: owners);
    final guest = await SalsaProgressStore.open(
        supportDirectory: directory, owners: owners);
    for (final store in [seed, bob, guest]) {
      await store.record(course, course.lessons.first, SalsaEvidence.practised);
    }
    final journal = sessionFileFor(directory, _alice)
      ..writeAsStringSync('journal A');
    final entered = Completer<void>();
    final release = Completer<void>();
    final reading = await SalsaProgressStore.open(
        accountUserId: _alice,
        supportDirectory: directory,
        owners: owners,
        fileFactory: (file) => _HeldReadFile(file, entered, release));
    final dispatched = reading.read();
    final readRejected =
        expectLater(dispatched, throwsA(isA<SessionStoreRetiredException>()));
    await entered.future;
    final queued =
        seed.record(course, course.lessons[1], SalsaEvidence.practised);
    final queueRejected =
        expectLater(queued, throwsA(isA<SessionStoreRetiredException>()));
    var erased = false;
    final clearing = clearLocalHistoryFor(_alice,
            supportDirectory: directory, owners: owners)
        .then((_) => erased = true);
    await Future<void>.delayed(Duration.zero);
    expect(erased, isFalse);
    expect(await seed.file.exists(), isTrue);
    expect(await journal.exists(), isTrue);
    await expectLater(
        SalsaProgressStore.open(
            accountUserId: _alice, supportDirectory: directory, owners: owners),
        throwsA(isA<SessionStoreRetiredException>()));
    release.complete();
    await readRejected;
    await queueRejected;
    await clearing;
    expect(await seed.file.exists(), isFalse);
    expect(await journal.exists(), isFalse);
    expect((await bob.read()).events, hasLength(1));
    expect((await guest.read()).events, hasLength(1));
    final fresh = await SalsaProgressStore.open(
        accountUserId: _alice, supportDirectory: directory, owners: owners);
    await fresh.record(course, course.lessons[2], SalsaEvidence.practised);
    expect((await fresh.read()).events.single.lessonId, course.lessons[2].id);
  });

  test('overlapping course-only and whole-account erase retain both scopes',
      () async {
    final courseFile =
        File('${directory.path}/${SalsaProgressStore.fileNameFor(_alice)}')
          ..writeAsStringSync('old course');
    final journal = sessionFileFor(directory, _alice)
      ..writeAsStringSync('old journal');
    final location = Completer<Directory>();
    final courseClear = SalsaProgressStore.clearAccount(_alice,
        owners: owners, directoryResolver: () => location.future);
    final accountClear = clearLocalHistoryFor(_alice,
        supportDirectory: directory, owners: owners);
    expect(owners.isErasing(_alice), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(await journal.exists(), isTrue);
    location.complete(directory);
    await Future.wait([courseClear, accountClear]);
    expect(await courseFile.exists(), isFalse);
    expect(await journal.exists(), isFalse);
    expect(owners.isErasing(_alice), isFalse);
  });
}
