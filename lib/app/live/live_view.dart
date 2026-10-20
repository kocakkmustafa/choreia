import 'package:choreia_engine/choreia_engine.dart';
import 'package:flutter/material.dart';
import 'package:motion_camera/motion_camera.dart';
import 'package:motion_core/motion_core.dart';

import '../theme.dart';
import '../ui_language.dart';
import 'live_lesson_copy.dart';
import 'live_state.dart';

/// Every user-facing string of the live surface, in one place (same seam as
/// `ProgressStrings`).
///
/// UNCHANGED by the design pass. `live_view_test.dart` pins several of these
/// verbatim (`LiveStrings.cycles(3) == '3 read so far'` in particular), and
/// the design brief's own copy for this screen is illustrative rather than
/// binding — style changes how this reads, not what it says (§9/§14 apply to
/// the STRUCTURE the copy carries, not to the words).
abstract final class LiveStrings {
  static const String title = 'Live practice';

  static const String idle = 'Getting the camera ready.';
  static const String interrupted =
      'Practice paused when you left the app. Restart the camera to continue.';

  static const String permanentlyDenied =
      'Camera access is turned off for Choreia. We cannot ask again from '
      'here — it has to be switched back on in your phone settings.';
  static const String deniedOnce =
      'We need the camera to watch your steps. Nothing is recorded and '
      'nothing leaves your phone — we only read where your joints are.';
  static const String openSettings = 'Open settings';
  static const String tryAgain = 'Try again';

  static const String noPerson =
      'We cannot see you well enough to check anything right now.';
  static String noPersonWhy(QualityIssue issue) => switch (issue) {
        QualityIssue.lowTrackingConfidence =>
          'Try more light, or a plainer background.',
        QualityIssue.outOfFrame =>
          'Some of you is outside the frame — try stepping back.',
        QualityIssue.torsoUnreliable =>
          'We cannot make out your upper body, so there is nothing to '
              'measure from.',
      };

  static const String watching = 'Watching. Keep going — we read a full '
      'repetition at a time.';

  /// "Nothing yet" is NOT zero. A bare 0 next to "repetitions" reads as a
  /// score of nothing; the absence of a count is a different fact.
  static String cycles(int? n) =>
      n == null ? 'No full repetition read so far' : '$n read so far';

  /// Ends the session and takes the learner to what was kept.
  ///
  /// "Finish" rather than "Stop": stopping is what the back arrow does, and it
  /// keeps nothing. The word has to carry the difference, because the two
  /// controls sit on the same screen and only one of them writes.
  static const String finish = 'Finish session';

  static const String gatedTitle = 'What we are NOT checking';
  static const String measuredTitle = 'What we measured';
  static const String findingsTitle = 'What we noticed';
  static const String nothingWrong =
      'Nothing we check came out wrong this time.';

  /// Names that other findings exist WITHOUT listing them.
  ///
  /// Single-correction is about where to put your attention, not about
  /// pretending the rest of the attempt was clean. The count says "there is
  /// more" and the sentence says why you are only being shown one.
  static String alsoSaw(int n) => n == 1
      ? 'One other thing came up. This is the one to fix first — the rest '
          'tends to follow.'
      : '$n other things came up. This is the one to fix first — the rest '
          'tends to follow.';

  static String cameraProblem(CameraFailure f) => switch (f) {
        CameraFailure.modelLoadFailed =>
          'The movement model would not load, so we cannot watch you. This '
              'one is on us, not your phone.',
        CameraFailure.noSuchCamera =>
          'We could not find a front camera on this device.',
        CameraFailure.alreadyRunning =>
          // NAMES OUR OWN FAULT (C-192). This said "in use by another part of
          // the app" — and Choreia has exactly ONE camera surface, so there
          // is no other part. The path cannot know what is holding the
          // camera; what it CAN know is that the only thing this app ever
          // opens is the previous lesson, so a session that failed to stop is
          // the honest suspect and the only one the user can act on.
          //
          // The old sentence also ended the screen: a blamed stranger leaves
          // nothing to do, which is the dead end M-F-268 forbids.
          'The camera is still busy from the last lesson. Going back and '
              'opening it again usually clears this — and if it does not, '
              'that is a fault on our side, not something you did wrong.',
        CameraFailure.notRunning => 'The camera session is not running.',
        CameraFailure.lifecycleUnavailable =>
          'The camera is not ready in this view yet. Return to the lesson '
              'and try again.',
        CameraFailure.sessionInterrupted =>
          'The camera session ended before it was ready. Open the lesson '
              'again and retry.',
        CameraFailure.ownedProtocolUnavailable =>
          'This build cannot safely control the camera session. Return to the '
              'lesson and install an updated version of the app.',
        CameraFailure.closeUncertain =>
          'Camera closure could not be confirmed. This attempt was not saved. '
              'Return to the lesson and reopen the app before using the camera.',
        CameraFailure.permissionDenied =>
          // Never reached: permission has its own state. Handled so the
          // switch stays exhaustive rather than defaulting.
          'Camera access is off.',
      };
}

String _cyclesTr(int? n) =>
    n == null ? 'Henüz tam tekrar okunmadı' : 'Şu ana kadar $n tekrar okundu';

String _alsoSawTr(int n) => n == 1
    ? 'Bir başka konu daha görüldü. Önce bunu düzeltin; diğer konu da bundan etkilenebilir.'
    : '$n başka konu daha görüldü. Önce bunu düzeltin; diğerleri de bundan etkilenebilir.';

String _noPersonWhyTr(QualityIssue issue) => switch (issue) {
      QualityIssue.lowTrackingConfidence =>
        'Daha fazla ışık veya daha sade bir arka plan deneyin.',
      QualityIssue.outOfFrame =>
        'Vücudunuzun bir kısmı kadraj dışında; biraz geri çekilin.',
      QualityIssue.torsoUnreliable =>
        'Üst bedeninizi yeterince seçemiyoruz; bu yüzden ölçüm yapamıyoruz.',
    };

String _cameraProblemTr(CameraFailure failure) => switch (failure) {
      CameraFailure.modelLoadFailed =>
        'Hareket modeli yüklenmediği için sizi izleyemiyoruz. Sorun telefonunuzda değil, bizde.',
      CameraFailure.noSuchCamera => 'Bu cihazda ön kamera bulamadık.',
      CameraFailure.alreadyRunning =>
        'Kamera önceki dersten beri meşgul görünüyor. Geri dönüp dersi yeniden açmayı deneyin. Sorun sürerse bizim tarafımızdadır.',
      CameraFailure.notRunning => 'Kamera oturumu çalışmıyor.',
      CameraFailure.lifecycleUnavailable =>
        'Kamera bu ekranda henüz hazır değil. Derse dönüp yeniden deneyin.',
      CameraFailure.sessionInterrupted =>
        'Kamera seansı hazır olmadan kesildi. Dersi yeniden açıp deneyin.',
      CameraFailure.ownedProtocolUnavailable =>
        'Bu sürüm kamera seansını güvenle yönetemiyor. Derse dönüp uygulamanın güncel sürümünü yükleyin.',
      CameraFailure.closeUncertain =>
        'Kameranın kapandığı doğrulanamadı. Bu deneme kaydedilmedi. Derse dönüp kamerayı kullanmadan önce uygulamayı yeniden açın.',
      CameraFailure.permissionDenied => 'Kamera erişimi kapalı.',
    };

/// Turns a raw [JudgeResult.measurements] key into words a learner can read.
///
/// **F1 audit (H-24): this was a no-op wearing a working function's shape.**
/// `_measuredCard` called `m.key.replaceAll('_', ' ')` — correct for a
/// snake_case key, and every key `judge.dart` actually produces
/// (`kneeDeltaDeg`, `identityWorstJointDeg`, …) is camelCase, so the
/// underscore replace never matched anything. The ONE currently-startable
/// lesson (`hh_l1_bounce`) is `demoOnly` and always renders through this
/// card — every real user who has ever opened it saw the raw identifier
/// `kneeDeltaDeg` next to a bare degree figure. The widget test that should
/// have caught this used `'left_knee'` as its fixture — snake_case, so the
/// broken transform happened to look correct against unrealistic data
/// (`live_view_test.dart`, fixed alongside this).
///
/// Strips the trailing unit suffix (`Deg` — the value is already rendered
/// with a `°`, so keeping it in the label would say the same thing twice),
/// splits camelCase AND snake_case alike (defensive: nothing in this file
/// should assume one specific key convention going forward), lowercases,
/// then capitalises only the first word — matching this file's own
/// sentence-case label style (`LiveStrings.watching`, `LiveStrings.noPerson`).
String _measurementLabel(String key) {
  final String stripped =
      key.endsWith('Deg') ? key.substring(0, key.length - 3) : key;
  final String spaced = stripped
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (Match m) => ' ')
      .replaceAll('_', ' ')
      .toLowerCase();
  return spaced.isEmpty
      ? spaced
      : spaced[0].toUpperCase() + spaced.substring(1);
}

/// The live lesson screen.
///
/// [LiveState] is `sealed`, so the compiler REQUIRES every case below. That is
/// the point: an unhandled state renders as a blank screen, and a blank screen
/// makes a claim about the user's dancing that nobody wrote.
///
/// THREE PATTERNS CARRIED IN FROM THE FAMILY (M-F-268):
///   · NO DEAD END — a camera failure never leaves the screen unopenable; it
///     flows INTO the session as a typed state with something to do next.
///   · PERMISSION HAS TWO FLAVOURS — a permanent denial offers settings, not
///     a "try again" button that cannot work.
///   · "NEVER STARTED" ≠ ZERO — the repetition counter is `int?`, and a null
///     renders as words, never as a bare 0.
///
/// DESIGN PASS (2026-08-06, `docs/design/`): restyled against the design
/// panel's "Live tour" + "§10 edge states" screens. The seven branches below,
/// their Keys and every string above are the STRUCTURE this pass inherited —
/// see the per-branch comments for where the design assumed data this state
/// does not carry, and what was kept instead.
class LiveView extends StatelessWidget {
  const LiveView({
    super.key,
    required this.state,
    required this.gated,
    required this.notMeasuredNote,
    this.lessonId,
    this.cyclesRead,
    this.permissionPermanentlyDenied = false,
    this.onRetry,
    this.onOpenSettings,
    this.onFinish,
  });

  final LiveState state;

  /// Shown in EVERY state, including failures: a check we cannot make is not
  /// something the learner should discover only when things go well.
  final List<GatedCheck> gated;
  final String notMeasuredNote;
  final String? lessonId;

  /// Null until a full repetition has been read. Not zero (M-F-268).
  final int? cyclesRead;

  final bool permissionPermanentlyDenied;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;

  /// Ends the session and writes it. Null while a write is already in flight,
  /// which is what stops one practice being appended twice.
  final VoidCallback? onFinish;

  static const Key bodyKey = Key('live.body');
  static const Key gatedKey = Key('live.gated');
  static const Key notMeasuredKey = Key('live.notMeasured');
  static const Key actionKey = Key('live.action');
  static const Key alsoSawKey = Key('live.alsoSaw');
  static const Key finishKey = Key('live.finish');

  /// Whether the camera has produced anything this session could keep.
  ///
  /// The finish control appears for exactly these states, and the rule is
  /// about the RECORD, not about tidiness: in `LiveIdle` nothing has started,
  /// and under a permission or camera failure nothing was ever seen — offering
  /// to "finish" there would promise to keep a session that does not exist.
  /// Those branches already carry their own action (M-F-268), so nothing is
  /// left without a way forward.
  bool get _sessionUnderway => switch (state) {
        LiveNoPerson() ||
        LiveWatching() ||
        LiveMeasured() ||
        LiveJudged() =>
          true,
        LiveObservationUnavailable() ||
        LiveIdle() ||
        LiveInterrupted() ||
        LivePermissionDenied() ||
        LiveCameraUnavailable() =>
          false,
      };

  @override
  Widget build(BuildContext context) {
    final bool tr = UiLanguage.isTurkish(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(tr ? 'Canlı çalışma' : LiveStrings.title)),
      body: ChoreiaBackdrop(
        child: SafeArea(
          child: ListView(
            key: bodyKey,
            // TOP PADDING IS A CONTENT MARGIN, NOT AN APPBAR OFFSET (C-154).
            //
            // It used to be 96. Measured 2026-08-07 at 375x812 with a 47pt
            // notch inset: that left 96pt of DEAD SPACE between the AppBar's
            // bottom edge and the first content. The cause is a double count —
            // `extendBodyBehindAppBar: true` makes Scaffold hand the body a top
            // inset that ALREADY INCLUDES the AppBar (47 status + 56 toolbar =
            // 103), `SafeArea` consumes all of it, and the padding then added
            // the AppBar's height a second time.
            //
            // Screen evidence found this; no test could. An overflow test asks
            // whether content fits, never whether it starts where it should.
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: <Widget>[
              ..._forState(tr),
              // THE TERMINAL. Until this existed the live path had no exit
              // that kept anything: the back arrow discarded the session, so
              // nothing was ever written and the progress surface was
              // hard-wired to say this app does not save. Placed directly
              // under the reading it ends, above the always-on limits.
              if (_sessionUnderway) ...<Widget>[
                const SizedBox(height: 18),
                FilledButton(
                  key: finishKey,
                  onPressed: onFinish,
                  child: Text(tr ? 'Seansı bitir' : LiveStrings.finish),
                ),
              ],
              const SizedBox(height: 20),
              _gatedSection(context, tr),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  LiveLessonCopy.identityLimit(lessonId, notMeasuredNote,
                      turkish: tr),
                  key: notMeasuredKey,
                  textAlign: TextAlign.center,
                  style: ChoreiaType.of(context).label(
                      size: 10.5, color: ChoreiaPalette.of(context).text(0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The compiler enforces exhaustiveness here — adding an eighth state
  /// breaks the build rather than silently rendering nothing.
  List<Widget> _forState(bool tr) => switch (state) {
        LiveIdle() => <Widget>[_idleCard(context, tr)],
        LiveInterrupted(:final accountChanged) => <Widget>[
            _interruptedCard(context, tr, accountChanged: accountChanged)
          ],
        LiveObservationUnavailable(:final reason) => <Widget>[
            _AttentionCard(
              icon: Icons.info_outline,
              tone: ChoreiaPalette.of(context).amber,
              body: switch (reason) {
                ObservationBlocker.unsupported => tr
                    ? 'Bu hareket için kamera değerlendirmesi desteklenmiyor. Yazılı derse devam edebilirsin.'
                    : 'Camera assessment is unsupported for this movement. You can continue with the written lesson.',
                ObservationBlocker.incompatible => tr
                    ? 'Hareket modeli ve ders sürümü eşleşmiyor. Yazılı derse devam edebilirsin.'
                    : 'The movement model and lesson versions do not match. You can continue with the written lesson.',
                ObservationBlocker.clockDiscontinuity => tr
                    ? 'Kamera verisinde kesinti var. Kesintiden önceki hareket değerlendirmeye katılmadı.'
                    : 'The camera stream was interrupted. Movement before the gap was excluded.',
              },
            ),
          ],
        LivePermissionDenied() => <Widget>[_permissionCard(context, tr)],
        LiveCameraUnavailable(:final CameraFailure failure) => <Widget>[
            _cameraProblemCard(context, failure, tr)
          ],
        LiveNoPerson(:final Set<QualityIssue> issues) => <Widget>[
            _noPersonCard(context, issues, tr),
          ],
        LiveWatching(:final int cyclesSeen) => <Widget>[
            _watchingCard(context, cyclesSeen, tr)
          ],
        // DEMO-ONLY: measurements only. This branch has no band to render
        // because `LiveMeasured` has no band FIELD — the guarantee is the
        // type, not this code remembering.
        LiveMeasured(:final Map<String, double> measurements) => <Widget>[
            _measuredCard(context, measurements, tr),
          ],
        LiveJudged(:final JudgeResult result) => <Widget>[
            _judgedCard(context, result, tr)
          ],
      };

  // ── Idle ─────────────────────────────────────────────────────────────
  //
  // The design's own rule for its LOADING edge state: "no spinner tricks ·
  // plain wait" (§10 states gallery). Honoured literally — no ring, no
  // shimmer, just the sentence, centred and unhurried.
  Widget _idleCard(BuildContext context, bool tr) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            tr ? 'Kamera hazırlanıyor.' : LiveStrings.idle,
            textAlign: TextAlign.center,
            style: ChoreiaType.of(context)
                .body(size: 14.5, color: ChoreiaPalette.of(context).text(0.65)),
          ),
        ),
      );

  Widget _interruptedCard(BuildContext context, bool tr,
          {bool accountChanged = false}) =>
      _AttentionCard(
        icon: Icons.pause_circle_outline,
        tone: ChoreiaPalette.of(context).amber,
        body: accountChanged
            ? (tr
                ? 'Hesap değişti. Bu deneme durduruldu. Yeni bir deneme için derse dön.'
                : 'The account changed. This attempt was stopped. Return to the lesson for a new attempt.')
            : tr
                ? 'Uygulamadan ayrılınca çalışma duraklatıldı. Devam etmek için kamerayı yeniden başlatın.'
                : LiveStrings.interrupted,
        action: FilledButton(
          key: actionKey,
          onPressed: onRetry,
          child: Text(accountChanged
              ? (tr ? 'Derse dön' : 'Back to lesson')
              : (tr ? 'Yeniden başlat' : 'Restart camera')),
        ),
      );

  // ── Permission ───────────────────────────────────────────────────────
  //
  // Design maps this to §10's "CAMERA · NOT NOW" / "CAMERA · BLOCKED", both
  // amber (a status, not an error). The action button is the one thing that
  // must differ between the two flavours, and it is the same widget/key
  // either way — only its label and callback change (M-F-268: a "try again"
  // that cannot work is worse than no button).
  Widget _permissionCard(BuildContext context, bool tr) => _AttentionCard(
        icon: permissionPermanentlyDenied
            ? Icons.videocam_off_outlined
            : Icons.videocam_outlined,
        tone: ChoreiaPalette.of(context).amber,
        body: permissionPermanentlyDenied
            ? (tr
                ? 'Choreia için kamera erişimi kapalı. Buradan tekrar izin isteyemiyoruz; telefon ayarlarından açabilirsiniz.'
                : LiveStrings.permanentlyDenied)
            : (tr
                ? 'Adımlarınızı izlemek için kameraya ihtiyacımız var. Görüntü kaydedilmez ve telefonunuzdan çıkmaz; yalnızca eklemlerinizin konumu okunur.'
                : LiveStrings.deniedOnce),
        action: permissionPermanentlyDenied
            ? FilledButton(
                key: actionKey,
                onPressed: onOpenSettings,
                child: Text(tr ? 'Ayarları aç' : LiveStrings.openSettings),
              )
            : FilledButton(
                key: actionKey,
                onPressed: onRetry,
                child: Text(tr ? 'Tekrar dene' : LiveStrings.tryAgain),
              ),
      );

  // ── Camera unavailable ───────────────────────────────────────────────
  //
  // Not a design-named edge state (the mockup's §10 gallery covers permission
  // and music, not a model/hardware fault) — closest borrowed tone is the
  // gallery's ERROR entry, since this IS a fault rather than a status. NO
  // DEAD END (M-F-268): the action button is always present here.
  Widget _cameraProblemCard(
          BuildContext context, CameraFailure failure, bool tr) =>
      _AttentionCard(
        icon: Icons.error_outline,
        tone: ChoreiaPalette.of(context).roseDeep,
        body:
            tr ? _cameraProblemTr(failure) : LiveStrings.cameraProblem(failure),
        action: FilledButton(
          key: actionKey,
          onPressed: onRetry,
          child: Text(
            failure == CameraFailure.closeUncertain ||
                    failure == CameraFailure.ownedProtocolUnavailable
                ? (tr ? 'Derse dön' : 'Back to lesson')
                : (tr ? 'Tekrar dene' : LiveStrings.tryAgain),
          ),
        ),
      );

  // ── No person ────────────────────────────────────────────────────────
  //
  // Closest structural match to the design's "liveBlocked" pattern (frame /
  // light / conf) — but that pattern's three named causes do not line up
  // 1:1 with the engine's real `QualityIssue` enum: the design assumes a
  // low-LIGHT signal this engine does not expose, and has no slot for
  // `torsoUnreliable`. Resolved per the brief's own rule (§3, "yapı kazanır"):
  // same visual shape (ring + title + reasons), REAL issues and REAL copy —
  // nothing invented to fill a design slot the engine cannot back. Named in
  // the giydirme report rather than silently reconciled.
  Widget _noPersonCard(
          BuildContext context, Set<QualityIssue> issues, bool tr) =>
      _AttentionCard(
        icon: Icons.person_search_outlined,
        tone: ChoreiaPalette.of(context).amber,
        body: tr
            ? 'Şu anda sizi değerlendirecek kadar iyi göremiyoruz.'
            : LiveStrings.noPerson,
        reasons: <String>[
          for (final QualityIssue i in issues)
            tr ? _noPersonWhyTr(i) : LiveStrings.noPersonWhy(i)
        ],
        trailing: Text(
            tr ? _cyclesTr(cyclesRead) : LiveStrings.cycles(cyclesRead),
            style: ChoreiaType.of(context)
                .label(size: 10, color: ChoreiaPalette.of(context).text(0.4))),
      );

  // ── Watching ─────────────────────────────────────────────────────────
  //
  // The design's live-tour showcase: a large breathing count inside a slow,
  // steady ring. The mockup also prints "cycle 3 of 8" — a target the
  // current `LiveWatching` state has no field for (it carries `cyclesSeen`
  // alone, no planned-cycle count), so that half is not reproduced rather
  // than invented; only what the state actually carries is shown.
  //
  // PLACEHOLDER(data): "cycle N of <planned total>" not shown — unblocked
  // by: LiveWatching (or the step config it is built from) carrying a
  // planned-cycle count the live surface can read; today it carries
  // cyclesSeen alone. See docs/design/PLACEHOLDER-REGISTER.md.
  Widget _watchingCard(BuildContext context, int cyclesSeen, bool tr) {
    final int? shown = cyclesSeen == 0 ? null : cyclesSeen;
    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SlowSpin(
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: ChoreiaPalette.of(context)
                              .rose
                              .withValues(alpha: 0.35),
                          width: 1.2),
                    ),
                  ),
                ),
                Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ChoreiaPalette.of(context).hairline(0.08)),
                  ),
                ),
                SlowBreath(
                  child: Text(
                    shown?.toString() ?? '—',
                    style: ChoreiaType.of(context).display(
                        size: 76, color: ChoreiaPalette.of(context).bright),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
              tr
                  ? 'İzliyoruz. Devam edin; her tam tekrarı ayrı okuyoruz.'
                  : LiveStrings.watching,
              textAlign: TextAlign.center,
              style: ChoreiaType.of(context).body(
                  size: 13.5, color: ChoreiaPalette.of(context).text(0.68))),
          const SizedBox(height: 10),
          Text(tr ? _cyclesTr(shown) : LiveStrings.cycles(shown),
              style: ChoreiaType.of(context).label(
                  size: 10.5, color: ChoreiaPalette.of(context).text(0.5))),
        ],
      ),
    );
  }

  // ── Measured (demo-only) ─────────────────────────────────────────────
  //
  // Mono type for the figures (design's typography rule: measurement
  // language is always Plex Mono, never the serif or the sans body face) —
  // and nothing else, on purpose: `LiveMeasured` has no findings field, so
  // there is no verdict section to style even by mistake.
  Widget _measuredCard(
          BuildContext context, Map<String, double> measurements, bool tr) =>
      GlassPanel(
        tint: ChoreiaPalette.of(context).amber,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(tr ? 'Ölçtüklerimiz' : LiveStrings.measuredTitle,
                style: ChoreiaType.of(context).body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: ChoreiaPalette.of(context).bright)),
            const SizedBox(height: 10),
            for (final MapEntry<String, double> m in measurements.entries)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                          LiveLessonCopy.measurementLabel(
                              lessonId, m.key, _measurementLabel(m.key),
                              turkish: tr),
                          style: ChoreiaType.of(context).body(
                              size: 12.5,
                              color: ChoreiaPalette.of(context).text(0.68))),
                    ),
                    const SizedBox(width: 8),
                    Text('${m.value.toStringAsFixed(1)}°',
                        style: ChoreiaType.of(context).label(
                            size: 12.5,
                            color: ChoreiaPalette.of(context).amberDeep,
                            letterSpacingEm: 0)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(tr ? _cyclesTr(cyclesRead) : LiveStrings.cycles(cyclesRead),
                style: ChoreiaType.of(context).label(
                    size: 10, color: ChoreiaPalette.of(context).text(0.42))),
          ],
        ),
      );

  // ── Judged ────────────────────────────────────────────────────────────
  //
  // Same findings as before, all of them — nothing added, nothing dropped.
  // The one change is visual: each finding is now coloured by its OWN
  // `verdict` field (fired → rose, ok → neutral, noVerdict → amber), which
  // the prior version read but never used for anything. Whether a
  // `noVerdict` finding here duplicates what `gated` already names is a
  // structural question this pass did not resolve — flagged in the giydirme
  // report, not decided unilaterally.
  Widget _judgedCard(BuildContext context, JudgeResult result, bool tr) =>
      GlassPanel(
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(tr ? 'Fark ettiklerimiz' : LiveStrings.findingsTitle,
                style: ChoreiaType.of(context).body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: ChoreiaPalette.of(context).bright)),
            const SizedBox(height: 12),
            // SINGLE-CORRECTION DISCIPLINE (C-136 (a)+(b), ruled 2026-08-07).
            //
            // The rule is "score + ONE correction — the single most important
            // error", and this card used to render EVERY finding. It now shows
            // the one [JudgeResult.correction] names, ordered by a priority
            // DERIVED from content's own unlock rule, not invented here.
            //
            // The other fired finding is not deleted from the world — it is
            // COUNTED below. Showing one correction is the rule; letting the
            // learner believe it was the only thing we saw would be a stronger
            // claim than the rule makes.
            if (result.correction == null)
              Text(
                  tr
                      ? 'Kontrol ettiğimiz alanlarda bu kez bir hata görmedik.'
                      : LiveStrings.nothingWrong,
                  style: ChoreiaType.of(context).body(
                      size: 13, color: ChoreiaPalette.of(context).text(0.7)))
            else ...<Widget>[
              _findingRow(context, result.correction!),
              if (result.otherFiredCount > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  tr
                      ? _alsoSawTr(result.otherFiredCount)
                      : LiveStrings.alsoSaw(result.otherFiredCount),
                  key: alsoSawKey,
                  style: ChoreiaType.of(context).body(
                      size: 12, color: ChoreiaPalette.of(context).text(0.55)),
                ),
              ],
            ],
            const SizedBox(height: 10),
            Text(tr ? _cyclesTr(cyclesRead) : LiveStrings.cycles(cyclesRead),
                style: ChoreiaType.of(context).label(
                    size: 10, color: ChoreiaPalette.of(context).text(0.42))),
          ],
        ),
      );

  Widget _findingRow(BuildContext context, ErrorFinding f) {
    final Color tone = switch (f.verdict) {
      Verdict.error => ChoreiaPalette.of(context).rose,
      Verdict.ok => ChoreiaPalette.of(context).text(0.4),
      Verdict.noVerdict => ChoreiaPalette.of(context).amber,
    };
    final IconData glyph = switch (f.verdict) {
      Verdict.error => Icons.circle,
      Verdict.ok => Icons.check_circle_outline,
      Verdict.noVerdict => Icons.remove_circle_outline,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(glyph, size: 14, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${f.code}${f.why == null ? '' : ' — ${f.why}'}',
              style: ChoreiaType.of(context).body(
                  size: 12.5, color: ChoreiaPalette.of(context).text(0.72)),
            ),
          ),
        ],
      ),
    );
  }

  /// Gated checks, ALWAYS on screen.
  ///
  /// Not folded away behind a tap: a check the app cannot make is exactly the
  /// thing a learner would otherwise assume passed (kalem-4, C-117). Styled
  /// with the same hollow-amber language the design uses for "in
  /// preparation" / "not open yet" — a named absence, not an error.
  Widget _gatedSection(BuildContext context, bool tr) => GlassPanel(
        key: gatedKey,
        tint: ChoreiaPalette.of(context).amber,
        borderColor: ChoreiaPalette.of(context).amber.withValues(alpha: 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(tr ? 'Kontrol etmediklerimiz' : LiveStrings.gatedTitle,
                style: ChoreiaType.of(context).label(
                    size: 9.5,
                    color: ChoreiaPalette.of(context).amberDeep,
                    letterSpacingEm: 0.12)),
            for (final GatedCheck g in gated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    LiveLessonCopy.gatedReason(lessonId, g.code, g.why,
                        turkish: tr),
                    style: ChoreiaType.of(context).body(
                        size: 12, color: ChoreiaPalette.of(context).text(0.7))),
              ),
          ],
        ),
      );
}

/// The shared "something needs your attention" card — permission, camera
/// fault and no-person all compose this. One ring, one title line, optional
/// per-reason list, optional action: the same shape the design's §10 gallery
/// uses for every named limit, so a learner who has seen one has seen them
/// all.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.tone,
    required this.body,
    this.reasons = const <String>[],
    this.action,
    this.trailing,
  });

  final IconData icon;
  final Color tone;
  final String body;
  final List<String> reasons;
  final Widget? action;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GlassPanel(
        radius: 22,
        tint: tone,
        borderColor: tone.withValues(alpha: 0.28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            StatusRing(icon: icon, tone: tone),
            const SizedBox(height: 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: ChoreiaType.of(context)
                  .body(size: 14, color: ChoreiaPalette.of(context).text(0.85)),
            ),
            for (final String r in reasons)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(r,
                    textAlign: TextAlign.center,
                    style: ChoreiaType.of(context).body(
                        size: 12.5,
                        color: ChoreiaPalette.of(context).text(0.6))),
              ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: action),
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(height: 12),
              trailing!,
            ],
          ],
        ),
      );
}
