import 'dart:async';
import 'package:choreia/app/read_deadline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a non-answering local read fails within its observation deadline',
      () async {
    final deadline = ReadDeadline(const Duration(milliseconds: 10));
    await expectLater(deadline.run(Completer<int>().future),
        throwsA(isA<TimeoutException>()));
  });

  test('a late successful read cannot replace an observed timeout', () async {
    final pending = Completer<int>();
    final deadline = ReadDeadline(const Duration(milliseconds: 10));
    final observed = deadline.run(pending.future);
    await expectLater(observed, throwsA(isA<TimeoutException>()));
    pending.complete(42);
    await Future<void>.delayed(Duration.zero);
    await expectLater(observed, throwsA(isA<TimeoutException>()));
  });

  test('retiring the observer cancels its timer and ignores late errors',
      () async {
    final pending = Completer<int>();
    final deadline = ReadDeadline(const Duration(hours: 1));
    final observed = deadline.run(pending.future);
    final check = expectLater(observed, throwsA(isA<ReadRetired>()));
    deadline.retire();
    await check;
    pending.completeError(StateError('late platform read'));
    await Future<void>.delayed(Duration.zero);
  });
}
