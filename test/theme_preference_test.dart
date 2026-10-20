import 'dart:async';
import 'dart:convert';
import 'package:choreia/app/theme/theme_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryAppearanceStore implements ChoreiaThemeStore {
  String? contents;
  Future<String?>? readResult;
  final writes = <String>[];
  final barriers = <Completer<void>>[];
  bool failWrite = false;
  bool blockWrites = false;
  int active = 0, maxActive = 0;
  @override
  Future<String?> read() => readResult ?? Future.value(contents);
  @override
  Future<void> write(String value) async {
    active++;
    if (active > maxActive) maxActive = active;
    writes.add(value);
    try {
      if (blockWrites) {
        final barrier = Completer<void>();
        barriers.add(barrier);
        await barrier.future;
      }
      if (failWrite) throw StateError('disk unavailable');
      contents = value;
    } finally {
      active--;
    }
  }
}

void main() {
  for (final mode in ThemeMode.values) {
    test('restores exact ${mode.name} preference', () async {
      final store = MemoryAppearanceStore()
        ..contents = jsonEncode({'schemaVersion': 1, 'themeMode': mode.name});
      final controller = ChoreiaThemeController.persisted(store: store);
      await controller.restore();
      expect(controller.value, mode);
      expect(controller.readFailed, false);
      controller.dispose();
    });
  }
  test('missing preference uses system without writing', () async {
    final store = MemoryAppearanceStore();
    final controller = ChoreiaThemeController.persisted(store: store);
    await controller.restore();
    expect(controller.value, ThemeMode.system);
    expect(controller.readFailed, false);
    expect(store.writes, isEmpty);
    controller.dispose();
  });
  for (final bad in [
    'not json',
    '{"schemaVersion":2,"themeMode":"dark"}',
    '{"schemaVersion":1,"themeMode":"blue"}'
  ]) {
    test('invalid preference remains untouched: $bad', () async {
      final store = MemoryAppearanceStore()..contents = bad;
      final controller = ChoreiaThemeController.persisted(store: store);
      await controller.restore();
      expect(controller.value, ThemeMode.system);
      expect(controller.readFailed, true);
      expect(store.contents, bad);
      expect(store.writes, isEmpty);
      controller.dispose();
    });
  }
  test('read timeout retires late preference before first theme is displayed',
      () async {
    final read = Completer<String?>();
    final store = MemoryAppearanceStore()..readResult = read.future;
    final controller = ChoreiaThemeController.persisted(store: store);
    await controller.restore(deadline: const Duration(milliseconds: 1));
    expect(controller.readFailed, true);
    read.complete('{"schemaVersion":1,"themeMode":"dark"}');
    await Future<void>.delayed(Duration.zero);
    expect(controller.value, ThemeMode.system);
    controller.dispose();
  });
  test('a choice made during read wins', () async {
    final read = Completer<String?>();
    final store = MemoryAppearanceStore()..readResult = read.future;
    final controller = ChoreiaThemeController.persisted(store: store);
    final restore = controller.restore();
    await controller.select(ThemeMode.light);
    read.complete('{"schemaVersion":1,"themeMode":"dark"}');
    await restore;
    expect(controller.value, ThemeMode.light);
    controller.dispose();
  });
  test('timed out write stays serialized and only newest queued mode is saved',
      () async {
    final store = MemoryAppearanceStore()..blockWrites = true;
    final controller = ChoreiaThemeController.persisted(store: store);
    await controller.select(ThemeMode.dark,
        deadline: const Duration(milliseconds: 1));
    expect(controller.saveFailed, true);
    expect(store.active, 1);
    final light = controller.select(ThemeMode.light);
    final system = controller.select(ThemeMode.system);
    expect(controller.value, ThemeMode.system);
    expect(store.writes.length, 1);
    store.barriers.first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(store.writes.length, 2);
    expect(jsonDecode(store.writes.last)['themeMode'], 'system');
    expect(store.maxActive, 1);
    store.barriers.last.complete();
    await Future.wait([light, system]);
    expect(jsonDecode(store.contents!)['themeMode'], 'system');
    expect(controller.saveFailed, false);
    controller.dispose();
  });
  test('write failure is observable and same-mode retry can persist', () async {
    final store = MemoryAppearanceStore()..failWrite = true;
    final controller = ChoreiaThemeController.persisted(store: store);
    await controller.select(ThemeMode.light);
    expect(controller.value, ThemeMode.light);
    expect(controller.saveFailed, true);
    store.failWrite = false;
    await controller.select(ThemeMode.light);
    expect(controller.saveFailed, false);
    expect(jsonDecode(store.contents!)['themeMode'], 'light');
    controller.dispose();
  });
  test('dispose fences notifications while a real write completes', () async {
    final store = MemoryAppearanceStore()..blockWrites = true;
    final controller = ChoreiaThemeController.persisted(store: store);
    final pending = controller.select(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    store.barriers.first.complete();
    await pending;
    expect(store.active, 0);
  });
}
