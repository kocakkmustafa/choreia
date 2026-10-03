import 'dart:async';

import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';

/// Exercise second entry through the real owned Core protocol. The fake native
/// camera refuses acquisition until the previous owner's stop reply settles.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('kameraya İKİNCİ giriş (C-195)', () {
    late _SharedCamera device;
    setUp(() => device = _SharedCamera());
    tearDown(() => device.dispose());

    test('önceki dersin kapanışı bitmeden ikinci ders açılmaz', () async {
      device.heldClose = Completer<void>();
      device.stopObserved = Completer<void>();
      final first = CameraPoseSource(controller: device.controller());
      final second = CameraPoseSource(controller: device.controller());
      expect(await first.start(modelPath: '/m', modelId: 'id'), isNull);
      // State.dispose cannot await; keep the actual closure future for cleanup.
      final closing = first.stop();
      await device.stopObserved!.future;
      var settled = false;
      final starting = second.start(modelPath: '/m', modelId: 'id').then((
        value,
      ) {
        settled = true;
        return value;
      });
      try {
        await Future<void>.delayed(Duration.zero);
        expect(device.starts, 1);
        expect(device.startsRefused, 0);
        expect(settled, isFalse);
      } finally {
        device.heldClose!.complete();
        await closing;
        expect(await starting, isNull);
        device.heldClose = null;
        await second.stop();
      }
      expect(device.starts, 2, reason: 'her iki ders de gerçekten açıldı');
      expect(device.startsRefused, 0);
      expect(device.current, isNull);
    });

    test('POZİTİF KONTROL: kilit olmasaydı bu senaryo ÇÖKERDİ', () async {
      device.heldClose = Completer<void>();
      device.stopObserved = Completer<void>();
      final first = device.controller().createCaptureLease();
      final second = device.controller().createCaptureLease();
      await first.start(modelPath: '/m', modelId: 'id');
      final closing = first.close();
      await device.stopObserved!.future;
      try {
        await expectLater(
          second.start(modelPath: '/m', modelId: 'id'),
          throwsA(
            isA<CameraException>().having(
              (error) => error.failure,
              'failure',
              CameraFailure.alreadyRunning,
            ),
          ),
        );
        expect(device.startsRefused, 1);
        expect(
          device.current,
          first.ownerId,
          reason: 'Rejected owner cannot close the previous camera.',
        );
      } finally {
        device.heldClose!.complete();
        await closing;
        await second.close();
      }
    });

    test('birinci ders hiç olmadıysa BEKLEME de yok', () async {
      final only = CameraPoseSource(controller: device.controller());
      try {
        expect(await only.start(modelPath: '/m', modelId: 'id'), isNull);
        expect(device.starts, 1);
        expect(device.startsRefused, 0);
      } finally {
        await only.stop();
      }
    });
  });

  group('İKİNCİ okumada hâlâ doğru mu', () {
    test('tanıtım metni "ilk kez" sınıfı bir iddia taşımıyor', () {
      // The intro is shown once — unless the marker file cannot be written,
      // in which case it appears again BY DESIGN (failing open beats failing
      // closed on a launch path). So every sentence in it has to survive a
      // second reading.
      final String all = <String>[
        IntroStrings.what,
        IntroStrings.camera,
        IntroStrings.music,
        IntroStrings.limits,
        IntroStrings.continueLabel,
      ].join(' ').toLowerCase();

      const List<String> firstTimeClaims = <String>[
        'for the first time',
        'first time',
        'welcome back',
        'once again',
        'as you saw',
        'last time',
        'again',
      ];
      for (final String claim in firstTimeClaims) {
        expect(
          all,
          isNot(contains(claim)),
          reason:
              'tanıtım ikinci kez okunabiliyor (işaret dosyası '
              'yazılamazsa tasarım gereği tekrar görünür) — "$claim" '
              'okuyucunun kaçıncı kez baktığını iddia ediyor',
        );
      }
    });
  });
}

/// One native camera shared by fresh controllers, with owner-specific closure
/// receipts. Legacy start/stop are rejected so they cannot mask an owned API gap.
final class _SharedCamera {
  static const control = MethodChannel('choreia/test/nth_owned');
  static const frames = EventChannel('choreia/test/nth_owned_frames');
  String? current;
  int generation = 0;
  int starts = 0;
  int startsRefused = 0;
  final generations = <String, int>{};
  final closeSequences = <String, int>{};
  Completer<void>? heldClose;
  Completer<void>? stopObserved;

  _SharedCamera() {
    messenger.setMockMethodCallHandler(control, handle);
  }

  TestDefaultBinaryMessenger get messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  MotionCameraController controller() =>
      MotionCameraController(control: control, frames: frames);

  Map<String, Object> closed(String owner, int nonce) => {
    'protocol': 1,
    'ownerId': owner,
    'generation': generations[owner] ?? 0,
    'state': 'closed',
    'captureClosed': true,
    'modelsClosed': true,
    'closeSequence': closeSequences[owner] ?? 0,
    'nonce': nonce,
  };

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'start' || call.method == 'stop') {
      throw StateError('Legacy control cannot validate owned capture.');
    }
    final args = call.arguments as Map<Object?, Object?>;
    final owner = args['ownerId']! as String;
    switch (call.method) {
      case 'startOwned':
        if (current != null) {
          startsRefused++;
          throw PlatformException(code: 'already-running');
        }
        current = owner;
        generations[owner] = ++generation;
        starts++;
        return {
          'protocol': 1,
          'ownerId': owner,
          'generation': generation,
          'w': 720,
          'h': 1280,
          'clock': 'monotonic',
          'library': 'nth-owned',
        };
      case 'stopOwned':
        closeSequences[owner] = (closeSequences[owner] ?? 0) + 1;
        if (current == owner) {
          if (!(stopObserved?.isCompleted ?? true)) stopObserved!.complete();
          await heldClose?.future;
          if (current == owner) current = null;
        }
        return closed(owner, 0);
      case 'readback':
        return closed(owner, args['nonce']! as int);
      default:
        throw StateError('Unexpected native method ${call.method}');
    }
  }

  void dispose() => messenger.setMockMethodCallHandler(control, null);
}
