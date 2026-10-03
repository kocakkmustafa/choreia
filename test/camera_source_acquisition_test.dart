import 'dart:async';
import 'dart:typed_data';

import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

/// A native protocol fixture exercising the real Core owned lease and actual
/// EventChannel listener installation. Legacy RPCs remain negative controls.
final class _NativeCamera {
  static const control = MethodChannel('choreia/test/camera_owned');
  static const eventName = 'choreia/test/camera_owned_frames';
  static const eventControl = MethodChannel(eventName);
  static const codec = StandardMethodCodec();
  final calls = <MethodCall>[];
  final eventCalls = <MethodCall>[];
  final generations = <String, int>{};
  final sequences = <String, int>{};
  String? current;
  int generation = 0;
  String busyCode = 'already-running';
  String clock = 'monotonic';
  Completer<void>? heldStart;
  Completer<void>? heldClose;
  Completer<void>? heldCancel;
  Completer<void>? startObserved;
  Completer<void>? listenObserved;
  Completer<void>? cancelObserved;
  bool badReadbackNonce = false;
  bool unknownStartFailure = false;

  _NativeCamera() {
    messenger.setMockMethodCallHandler(control, handle);
    messenger.setMockMethodCallHandler(eventControl, (call) async {
      eventCalls.add(call);
      if (call.method == 'listen') listenObserved?.complete();
      if (call.method == 'cancel') {
        cancelObserved?.complete();
        await heldCancel?.future;
        final owner = (call.arguments as Map<Object?, Object?>?)?['ownerId'];
        if (owner == null || owner == current) current = null;
      }
      return null;
    });
  }
  TestDefaultBinaryMessenger get messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  MotionCameraController controller() => MotionCameraController(
    control: control,
    frames: const EventChannel(eventName),
  );
  CameraPoseSource source() => CameraPoseSource(controller: controller());
  Map<String, Object> running(String owner) => {
    'protocol': 1,
    'ownerId': owner,
    'generation': generations[owner]!,
    'w': 720,
    'h': 1280,
    'clock': clock,
    'library': 'owned-fixture',
  };
  Map<String, Object> closed(String owner, {int nonce = 0}) => {
    'protocol': 1,
    'ownerId': owner,
    'generation': generations[owner] ?? 0,
    'state': 'closed',
    'captureClosed': true,
    'modelsClosed': true,
    'closeSequence': sequences[owner] ?? 0,
    'nonce': nonce,
  };
  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    if (call.method == 'start' || call.method == 'startOwned') {
      if (current != null) throw PlatformException(code: busyCode);
      final owner = call.method == 'start'
          ? 'legacy'
          : (call.arguments as Map<Object?, Object?>)['ownerId']! as String;
      startObserved?.complete();
      await heldStart?.future;
      current = owner;
      generations[owner] = ++generation;
      if (unknownStartFailure) {
        unknownStartFailure = false;
        throw PlatformException(code: 'undocumented-native-start-failure');
      }
      return running(owner);
    }
    if (call.method == 'stop') {
      current = null;
      await heldClose?.future;
      return null;
    }
    final args = call.arguments! as Map<Object?, Object?>;
    final owner = args['ownerId']! as String;
    if (call.method == 'stopOwned') {
      if (current == owner) current = null;
      sequences[owner] = (sequences[owner] ?? 0) + 1;
      await heldClose?.future;
      return closed(owner);
    }
    if (call.method == 'readback') {
      return closed(owner, nonce: badReadbackNonce ? 0 : args['nonce']! as int);
    }
    throw StateError('Unexpected control call ${call.method}');
  }

  Future<void> emit(
    int time, {
    String? owner,
    int? epoch,
    bool upright = true,
  }) async {
    final actualOwner = owner ?? current;
    if (actualOwner == null) return;
    await messenger.handlePlatformMessage(
      eventName,
      codec.encodeSuccessEnvelope({
        'ownerId': actualOwner,
        'generation': epoch ?? generations[actualOwner] ?? 0,
        't': time,
        'w': 720,
        'h': 1280,
        'model': 'owned-fixture+model',
        'clock': clock,
        'infUs': 1,
        'dropped': 0,
        upright ? 'up' : 'inv': Float32List.fromList(
          List.generate(132, (index) => index % 4 == 3 ? 1 : .5),
        ),
      }),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  void dispose() {
    messenger.setMockMethodCallHandler(control, null);
    messenger.setMockMethodCallHandler(eventControl, null);
  }
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);
Future<LiveState?> _start(CameraPoseSource source) =>
    source.start(modelPath: '/fixture/model.task', modelId: 'fixture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NativeCamera native;
  setUp(() => native = _NativeCamera());
  tearDown(() => native.dispose());

  test(
    'retired model preparation cannot enter or stop the native camera',
    () async {
      final model = Completer<String>();
      final source = DeviceCameraPoseSource(
        camera: native.source(),
        modelPathOpener: () => model.future,
      );
      final pending = source.begin();
      await source.stop();
      model.complete('/fixture/model.task');
      expect(await pending, isA<LiveInterrupted>());
      expect(native.calls, isEmpty);
    },
  );

  test('an unused denied source cannot stop another running owner', () async {
    final active = native.source();
    final denied = native.source();
    expect(await _start(active), isNull);
    final owner = native.current;
    await denied.stop();
    expect(native.current, owner);
    expect(native.calls.map((call) => call.method), ['startOwned']);
    await active.stop();
  });

  for (final code in ['already-running', 'camera-permission-denied']) {
    test(
      'closing $code owner preserves active owner and delivered frames',
      () async {
        native.busyCode = code;
        final active = native.source();
        final refused = native.source();
        expect(await _start(active), isNull);
        final owner = native.current;
        final seen = <PoseFrame>[];
        final subscription = active.frames().listen(seen.add);
        await _tick();
        await native.emit(1);
        final refusal = await _start(refused);
        expect(
          refusal,
          code == 'already-running'
              ? isA<LiveCameraUnavailable>()
              : isA<LivePermissionDenied>(),
        );
        await refused.stop();
        expect(native.current, owner);
        await native.emit(2);
        expect(seen.map((frame) => frame.tUs), [1, 2]);
        expect(native.calls.where((call) => call.method == 'stop'), isEmpty);
        await active.stop();
        await subscription.cancel();
      },
    );
  }

  test(
    'pending native creation is drained and late success is retired',
    () async {
      native.heldStart = Completer<void>();
      native.startObserved = Completer<void>();
      final source = native.source();
      final pending = _start(source);
      await native.startObserved!.future;
      var closed = false;
      final closing = source.stop().then((_) => closed = true);
      await _tick();
      expect(closed, isFalse);
      expect(native.calls.map((call) => call.method), [
        'startOwned',
        'stopOwned',
      ]);
      native.heldStart!.complete();
      expect(await pending, isA<LiveInterrupted>());
      await closing;
      expect(native.current, isNull);
      expect(
        native.calls.where((call) => call.method == 'stopOwned'),
        hasLength(2),
      );
      expect(native.calls.last.method, 'readback');
    },
  );

  test(
    'late paused subscription cancellation and old stop preserve successor',
    () async {
      final first = native.source();
      expect(await _start(first), isNull);
      final old = first.frames().listen((_) {});
      await _tick();
      old.pause();
      await first.stop();
      final next = native.source();
      expect(await _start(next), isNull);
      final owner = native.current;
      final seen = <PoseFrame>[];
      final current = next.frames().listen(seen.add);
      await _tick();
      final eventCount = native.eventCalls.length;
      await old.cancel();
      await first.stop();
      expect(native.eventCalls.length, eventCount);
      expect(native.current, owner);
      await native.emit(9);
      expect(seen.single.tUs, 9);
      await next.stop();
      await current.cancel();
    },
  );

  test(
    'retired start waiting on closure cannot enter native acquisition',
    () async {
      final first = native.source();
      expect(await _start(first), isNull);
      native.heldClose = Completer<void>();
      final closing = first.stop();
      final next = native.source();
      final pending = _start(next);
      final nextClosing = next.stop();
      await _tick();
      native.heldClose!.complete();
      await closing;
      await nextClosing;
      expect(await pending, isA<LiveInterrupted>());
      expect(
        native.calls.where(
          (call) => call.method == 'start' || call.method == 'startOwned',
        ),
        hasLength(1),
      );
      expect(native.current, isNull);
    },
  );

  for (final order in ['older-first', 'newer-first']) {
    test(
      'replacement waits for both overlapping owner closures $order',
      () async {
        final active = native.source();
        expect(await _start(active), isNull);
        final deniedClose = Completer<void>();
        native.heldClose = deniedClose;
        final denied = native.source();
        expect(await _start(denied), isA<LiveCameraUnavailable>());
        final olderClosing = denied.stop();
        final activeClose = Completer<void>();
        native.heldClose = activeClose;
        final newerClosing = active.stop();
        final successor = native.source();
        final successorStart = _start(successor);
        try {
          await _tick();
          (order == 'older-first' ? deniedClose : activeClose).complete();
          await _tick();
          expect(
            native.calls.where((call) => call.method == 'startOwned'),
            hasLength(2),
          );
        } finally {
          if (!deniedClose.isCompleted) deniedClose.complete();
          if (!activeClose.isCompleted) activeClose.complete();
          await olderClosing;
          await newerClosing;
        }
        expect(await successorStart, isNull);
        native.heldClose = null;
        await successor.stop();
      },
    );
  }

  test(
    'the same device adapter captures a fresh lease for a new attempt',
    () async {
      final camera = native.source();
      final source = DeviceCameraPoseSource(
        camera: camera,
        modelPathOpener: () async => '/fixture/model.task',
      );
      expect(await source.begin(), isNull);
      final first = camera.session!.ownerId;
      await source.stop();
      expect(await source.begin(), isNull);
      expect(camera.session!.ownerId, isNot(first));
      await source.stop();
    },
  );

  test(
    'owned frames reject foreign epochs and omit unplanned upright pass',
    () async {
      final source = native.source();
      expect(await _start(source), isNull);
      final owner = native.current!;
      final seen = <PoseFrame>[];
      final subscription = source.frames().listen(seen.add);
      await _tick();
      await native.emit(1, owner: 'foreign-owner');
      await native.emit(2, owner: owner, epoch: 999);
      await native.emit(3, upright: false);
      await native.emit(4);
      expect(seen.map((frame) => frame.tUs), [4]);
      await source.stop();
      await subscription.cancel();
    },
  );

  test('unknown camera clock never becomes audio-fusable', () async {
    native.clock = 'unknown';
    final source = native.source();
    expect(source.clockFusableWithAudio, isFalse);
    expect(await _start(source), isNull);
    expect(source.clockFusableWithAudio, isFalse);
    await source.stop();
  });

  test(
    'unknown start error publishes closure before a new wrapper acquires',
    () async {
      native.unknownStartFailure = true;
      native.heldClose = Completer<void>();
      final first = native.source();
      await expectLater(
        _start(first),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'undocumented-native-start-failure',
          ),
        ),
      );
      final next = native.source();
      var nextSettled = false;
      final successor = _start(next).then((result) {
        nextSettled = true;
        return result;
      });
      try {
        await _tick();
        expect(
          native.calls.where((call) => call.method == 'startOwned'),
          hasLength(1),
        );
        expect(nextSettled, isFalse);
      } finally {
        native.heldClose!.complete();
        await first.stop();
        expect(await successor, isNull);
        native.heldClose = null;
        await next.stop();
      }
    },
  );

  test('replacement waits for the actual native frame cancel reply', () async {
    native.listenObserved = Completer<void>();
    native.cancelObserved = Completer<void>();
    native.heldCancel = Completer<void>();
    final first = native.source();
    final next = native.source();
    expect(await _start(first), isNull);
    final owner = native.current;
    final subscription = first.frames().listen((_) {});
    await native.listenObserved!.future;
    var closeSettled = false;
    final closing = first.stop().then((_) => closeSettled = true);
    await native.cancelObserved!.future;
    var startSettled = false;
    final starting = _start(next).then((value) {
      startSettled = true;
      return value;
    });
    try {
      await _tick();
      expect(native.eventCalls.last.method, 'cancel');
      expect((native.eventCalls.last.arguments as Map)['ownerId'], owner);
      expect(
        native.calls.where((call) => call.method == 'startOwned'),
        hasLength(1),
      );
      expect(native.calls.where((call) => call.method == 'readback'), isEmpty);
      expect(closeSettled, isFalse);
      expect(startSettled, isFalse);
    } finally {
      native.heldCancel!.complete();
      await closing;
      expect(await starting, isNull);
      native.heldCancel = null;
      await next.stop();
      await subscription.cancel();
    }
    expect(closeSettled, isTrue);
    expect(startSettled, isTrue);
  });

  test(
    'control: framework event cancellation precedes native cancel reply',
    () async {
      const name = 'choreia/test/framework_cancel_control';
      const channel = MethodChannel(name);
      final listening = Completer<void>();
      final cancelling = Completer<void>();
      final reply = Completer<void>();
      final acknowledged = Completer<void>();
      native.messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'listen') listening.complete();
        if (call.method == 'cancel') {
          cancelling.complete();
          await reply.future;
          acknowledged.complete();
        }
        return null;
      });
      final subscription = const EventChannel(name)
          .receiveBroadcastStream()
          .listen((_) {});
      try {
        await listening.future;
        var cancelled = false;
        await subscription.cancel().then((_) => cancelled = true);
        await cancelling.future;
        expect(cancelled, isTrue);
        expect(
          acknowledged.isCompleted,
          isFalse,
          reason: 'Framework cancellation is not a native closure ACK.',
        );
      } finally {
        reply.complete();
        await acknowledged.future;
        native.messenger.setMockMethodCallHandler(channel, null);
      }
    },
  );

  // Quarantine deliberately lasts for this app isolate: put its regression last.
  test(
    'uncertain close rejects fresh controllers without legacy fallback',
    () async {
      final source = native.source();
      expect(await _start(source), isNull);
      native.badReadbackNonce = true;
      await expectLater(source.stop(), throwsA(isA<CameraException>()));
      native.badReadbackNonce = false;
      final before = native.calls.length;
      final result = await _start(native.source());
      expect(result, isA<LiveCameraUnavailable>());
      expect(
        (result! as LiveCameraUnavailable).failure,
        CameraFailure.closeUncertain,
      );
      expect(native.calls.length, before);
    },
  );
}
