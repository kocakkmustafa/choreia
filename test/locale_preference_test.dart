import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:choreia/app/localization/choreia_locale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('choreia-language-');
    file = File('${directory.path}/preference.json');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  ChoreiaLocaleController controller() =>
      ChoreiaLocaleController.persisted(preferenceFile: () async => file);

  test('script locale and explicit system preference survive a real reopen',
      () async {
    final first = controller();
    await first.select(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    expect(jsonDecode(await file.readAsString())['locale'], 'zh-Hans');
    first.dispose();
    final second = controller();
    await second.restore();
    expect(ChoreiaLocaleController.tag(second.value!), 'zh-Hans');
    await second.select(null);
    second.dispose();
    final third = controller();
    await third.restore();
    expect(third.value, isNull);
    expect(third.readFailed, false);
    expect(third.persistenceFailed, false);
    third.dispose();
    expect(await File('${file.path}.tmp').exists(), false);
  });
  for (final bad in [
    'invalid json',
    '{"schemaVersion":2,"locale":"fr"}',
    '{"schemaVersion":1,"locale":"unknown"}'
  ]) {
    test('unreadable saved preference is distinct from a save failure: $bad',
        () async {
      await file.writeAsString(bad);
      final value = controller();
      await value.restore();
      expect(value.value, isNull);
      expect(value.readFailed, true);
      expect(value.persistenceFailed, false);
      expect(await file.readAsString(), bad);
      await value.select(const Locale('pl'));
      expect(value.readFailed, false);
      expect(jsonDecode(await file.readAsString())['locale'], 'pl');
      value.dispose();
    });
  }
  test('missing file is normal and is not created by restore', () async {
    final value = controller();
    await value.restore();
    expect(value.readFailed, false);
    expect(await file.exists(), false);
    value.dispose();
  });
  test('late restore cannot change the first fallback after its total deadline',
      () async {
    await file.writeAsString('{"schemaVersion":1,"locale":"ja"}');
    final path = Completer<File>();
    final value =
        ChoreiaLocaleController.persisted(preferenceFile: () => path.future);
    await value.restore(deadline: const Duration(milliseconds: 1));
    expect(value.readFailed, true);
    path.complete(file);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(value.value, isNull);
    expect(value.readFailed, true);
    value.dispose();
  });
  test('selection during a pending restore owns the final UI', () async {
    await file.writeAsString('{"schemaVersion":1,"locale":"ja"}');
    final path = Completer<File>();
    final value =
        ChoreiaLocaleController.persisted(preferenceFile: () => path.future);
    final restore = value.restore();
    await value.select(const Locale('fr'), persist: false);
    path.complete(file);
    await restore;
    expect(value.value, const Locale('fr'));
    expect(value.readFailed, false);
    value.dispose();
  });
  test('a timed out earlier write cannot finish after the newest real write',
      () async {
    final path = Completer<File>();
    final value =
        ChoreiaLocaleController.persisted(preferenceFile: () => path.future);
    final first = value.select(const Locale('ja'),
        deadline: const Duration(milliseconds: 1));
    final last = value.select(const Locale('pl'));
    await first;
    expect(value.value, const Locale('pl'));
    path.complete(file);
    await last;
    expect(jsonDecode(await file.readAsString())['locale'], 'pl');
    expect(value.persistenceFailed, false);
    value.dispose();
  });
  test(
      'write failure leaves the selection usable and exposes only the save issue',
      () async {
    final blocker = File('${directory.path}/not-a-directory');
    await blocker.writeAsString('unchanged');
    final value = ChoreiaLocaleController.persisted(
        preferenceFile: () async => File('${blocker.path}/preference.json'));
    await value.select(const Locale('it'));
    expect(value.value, const Locale('it'));
    expect(value.persistenceFailed, true);
    expect(value.readFailed, false);
    expect(await blocker.readAsString(), 'unchanged');
    value.dispose();
  });
  test('disposed controller ignores late read and further selections',
      () async {
    final path = Completer<File>();
    final value =
        ChoreiaLocaleController.persisted(preferenceFile: () => path.future);
    final restore = value.restore();
    value.dispose();
    path.complete(file);
    await restore;
    await value.select(const Locale('ar'));
    expect(await file.exists(), false);
  });
}
