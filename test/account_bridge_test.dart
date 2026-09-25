import 'dart:io';

import 'package:choreia/app/account_bridge.dart';
import 'package:choreia/app/live/live_environment.dart';
import 'package:choreia/app/shell/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_core/motion_core.dart';

void main() {
  const String alice = '11111111-1111-4111-8111-111111111111';
  const String bob = '22222222-2222-4222-8222-222222222222';
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('choreia-account-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('app id and filenames isolate guest and two Motion users', () {
    expect(motionAppId, 'choreia');
    expect(sessionFileNameFor(null), 'sessions.jsonl');
    expect(sessionFileNameFor(alice), 'sessions-choreia-$alice.jsonl');
    expect(sessionFileNameFor(bob), isNot(sessionFileNameFor(alice)));
    expect(() => sessionFileNameFor('../guest'), throwsArgumentError);
  });

  test('receipt scan returns only canonical app-owned regular files', () async {
    final File aliceFile = sessionFileFor(tmp, alice);
    await aliceFile.writeAsString('record');
    await File('${aliceFile.path}.tmp').writeAsString('unfinished');
    await File('${tmp.path}/sessions.jsonl').writeAsString('guest');
    await File('${tmp.path}/sessions-jablab-$bob.jsonl').writeAsString('other');
    await File('${tmp.path}/sessions-choreia-not-a-uuid.jsonl')
        .writeAsString('bad');
    await Directory('${tmp.path}/sessions-choreia-$bob.jsonl').create();
    await Link(
            '${tmp.path}/sessions-choreia-33333333-3333-4333-8333-333333333333.jsonl')
        .create(aliceFile.path);

    expect(
        await localHistoryAccountIds(supportDirectory: tmp), <String>[alice]);
    expect(
      await localHistoryAccountIds(
          supportDirectory: Directory('${tmp.path}/missing')),
      isEmpty,
    );
  });

  test('tmp-only crash residue is reconciled without touching other paths',
      () async {
    final File bobTmp = File('${sessionFileFor(tmp, bob).path}.tmp');
    await bobTmp.writeAsString('unfinished');
    final File guestTmp = File('${tmp.path}/sessions.jsonl.tmp');
    await guestTmp.writeAsString('guest');
    final File otherAppTmp =
        File('${tmp.path}/sessions-jablab-$alice.jsonl.tmp');
    await otherAppTmp.writeAsString('other');
    final File target = File('${tmp.path}/unrelated-data');
    await target.writeAsString('keep');
    final Link symlink = Link('${sessionFileFor(tmp, alice).path}.tmp');
    await symlink.create(target.path);

    expect(await localHistoryAccountIds(supportDirectory: tmp), <String>[bob]);
    await clearLocalHistoryFor(bob, supportDirectory: tmp);
    await clearLocalHistoryFor(alice, supportDirectory: tmp);
    expect(await bobTmp.exists(), isFalse);
    expect(await guestTmp.readAsString(), 'guest');
    expect(await otherAppTmp.readAsString(), 'other');
    expect(await target.readAsString(), 'keep');
    expect(await symlink.exists(), isTrue);
    expect(await localHistoryAccountIds(supportDirectory: tmp), isEmpty);
  });

  test('sign-in does not claim or copy a guest session; deletion is scoped',
      () async {
    final LiveEnvironment env = LiveEnvironment(historyDirectoryOverride: tmp);
    final SessionStore guest = await env.openStoreFor(null);
    await guest.append(SessionRecord(
      lessonId: 'guest-lesson',
      completedAt: DateTime.utc(2026, 9, 24),
      workedSeconds: 30,
      unitsCompleted: 1,
      plannedUnits: 1,
      unitLabel: 'cycle',
      lessonClass: 'demoOnly',
    ));

    final SessionStore signed = await env.openStoreFor(alice);
    expect(await signed.recent(), isEmpty);
    await signed.append(SessionRecord(
      lessonId: 'alice-lesson',
      completedAt: DateTime.utc(2026, 9, 24, 1),
      workedSeconds: 40,
      unitsCompleted: 2,
      plannedUnits: 2,
      unitLabel: 'cycle',
      lessonClass: 'demoOnly',
    ));
    expect(await (await env.openStoreFor(bob)).recent(), isEmpty);
    expect((await (await env.openStoreFor(null)).recent()).single.lessonId,
        'guest-lesson');

    final File accountTmp = File('${sessionFileFor(tmp, alice).path}.tmp');
    await accountTmp.writeAsString('interrupted write');
    await clearLocalHistoryFor(alice, supportDirectory: tmp);
    await clearLocalHistoryFor(alice, supportDirectory: tmp);
    expect(await accountTmp.exists(), isFalse);
    expect(await (await env.openStoreFor(alice)).recent(), isEmpty);
    expect((await (await env.openStoreFor(null)).recent()).single.lessonId,
        'guest-lesson');
  });

  testWidgets('profile only opens a real injected account route',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProfileView(
          accountPageBuilder: (_) =>
              const Scaffold(body: Center(child: Text('Real account page'))),
        ),
      ),
    ));
    await tester.tap(find.byKey(ProfileView.accountEntryKey));
    await tester.pumpAndSettle();
    expect(find.text('Real account page'), findsOneWidget);
  });
}
