import 'package:choreia/app/live/camera_pose_source.dart';
import 'package:choreia/app/live/live_state.dart';
import 'package:choreia/app/onboarding/first_run_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_camera/motion_camera.dart';

/// **The N-th time.** Every other test in this repository photographs one
/// moment: does the screen render, is the sentence true, does the gate fall.
/// None of them asks what happens the SECOND time.
///
/// The class is invisible by construction at N=1 — nothing has happened yet,
/// so nothing can be stale, held, or repeated. That is exactly why it survives
/// a suite that is otherwise thorough.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('kameraya İKİNCİ giriş (C-195)', () {
    setUp(() async {
      // The latch is process-wide, so it must not leak between tests. Drained
      // through a FAKE controller: draining through the default one would
      // reach for a real MethodChannel and fail before measuring anything.
      await CameraPoseSource(controller: _SharedCamera()).stop();
    });

    test('önceki dersin kapanışı bitmeden ikinci ders açılmaz', () async {
      // Reproduces the device: `stop` is a platform round trip, and starting
      // while it is in flight is answered with `already-running`.
      final _SharedCamera device = _SharedCamera();

      // Lesson 1 runs and the user leaves. `State.dispose` is SYNCHRONOUS and
      // cannot await, so this call is deliberately not awaited — that is the
      // real call site, not a simplification.
      final CameraPoseSource first = CameraPoseSource(controller: device);
      await first.start(modelPath: '/m', modelId: 'id');
      unawaited(first.stop());

      // Lesson 2 opens immediately.
      final CameraPoseSource second = CameraPoseSource(controller: device);
      final LiveState? refusal =
          await second.start(modelPath: '/m', modelId: 'id');

      expect(refusal, isNull,
          reason: 'ikinci ders "$refusal" ile açılmadı. Birinci dersin '
              'kapanışı hâlâ uçuyorken start çağrıldı — kullanıcı, birinci '
              'dersin sebep olduğu bir arızayı ikinci derste görüyor');
      expect(device.startsRefused, 0);
      expect(device.starts, 2, reason: 'her iki ders de gerçekten açıldı');
    });

    test('POZİTİF KONTROL: kilit olmasaydı bu senaryo ÇÖKERDİ', () async {
      // Without this the test above could be passing because the fake is too
      // forgiving. Here the fake is driven directly, with no serialisation in
      // front of it, and it must refuse — proving the scenario is real and
      // that `CameraPoseSource` is what prevents it.
      final _SharedCamera device = _SharedCamera();
      await device.start(modelPath: '/m', modelId: 'id');
      unawaited(device.stop());

      await expectLater(
        device.start(modelPath: '/m', modelId: 'id'),
        throwsA(isA<CameraException>()),
      );
      expect(device.startsRefused, 1);
    });

    test('birinci ders hiç olmadıysa BEKLEME de yok', () async {
      // The latch must cost nothing at N=1. A serialisation that always waits
      // would trade a rare bug for a delay on every first launch.
      final _SharedCamera device = _SharedCamera();
      final CameraPoseSource only = CameraPoseSource(controller: device);
      expect(await only.start(modelPath: '/m', modelId: 'id'), isNull);
      expect(device.starts, 1);
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
        'for the first time', 'first time', 'welcome back', 'once again',
        'as you saw', 'last time', 'again',
      ];
      for (final String claim in firstTimeClaims) {
        expect(all, isNot(contains(claim)),
            reason: 'tanıtım ikinci kez okunabiliyor (işaret dosyası '
                'yazılamazsa tasarım gereği tekrar görünür) — "$claim" '
                'okuyucunun kaçıncı kez baktığını iddia ediyor');
      }
    });
  });
}

/// One camera, shared by every source — like the device.
///
/// Imitates the FAILURE MODE, not just the signature (C-115): `stop` takes
/// real asynchronous time, and `start` during that window is refused with the
/// plugin's own exception rather than quietly succeeding.
class _SharedCamera extends MotionCameraController {
  bool _running = false;
  bool _stopping = false;
  int starts = 0;
  int startsRefused = 0;

  @override
  Future<CameraSessionInfo> start({
    required String modelPath,
    required String modelId,
    CameraLens lens = CameraLens.front,
    PassPlan initialPlan = PassPlan.uprightOnly,
  }) async {
    if (_running || _stopping) {
      startsRefused++;
      throw CameraException(CameraFailure.alreadyRunning, 'still shutting down');
    }
    _running = true;
    starts++;
    return const CameraSessionInfo(
      width: 720,
      height: 1280,
      clockDomain: ClockDomain.monotonic,
      libraryTag: 'mp-test-0.0.0',
    );
  }

  @override
  Future<void> stop() async {
    _stopping = true;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _running = false;
    _stopping = false;
  }
}

void unawaited(Future<void> f) {}
