import 'dart:async';

/// Bounds observation of read-only I/O. Retiring a view cancels its timers,
/// not the underlying platform operation. Late results cannot change the view.
final class ReadDeadline {
  ReadDeadline(this.duration);
  final Duration duration;
  final Map<Timer, void Function()> _active = {};

  Future<T> run<T>(Future<T> work) {
    final result = Completer<T>();
    late Timer timer;
    void finishError(Object error, [StackTrace? trace]) {
      if (!result.isCompleted) result.completeError(error, trace);
      timer.cancel();
      _active.remove(timer);
    }

    timer = Timer(
        duration,
        () => finishError(TimeoutException(
            'The local read did not answer in time.', duration)));
    _active[timer] = () => finishError(const ReadRetired());
    work.then((value) {
      timer.cancel();
      _active.remove(timer);
      if (!result.isCompleted) result.complete(value);
    }, onError: (Object error, StackTrace trace) => finishError(error, trace));
    return result.future;
  }

  void retire() {
    for (final cancel in List<void Function()>.of(_active.values)) {
      cancel();
    }
  }
}

final class ReadRetired implements Exception {
  const ReadRetired();
}
