import 'package:flutter/material.dart';

import '../library/library_catalog.dart';
import '../library/library_view.dart';
import '../theme.dart';
import '../ui_language.dart';

/// The first thing a user sees, once.
///
/// What this screen is for
/// -----------------------
/// Until it existed, launching Choreia dropped a person straight into a
/// catalogue of 34 dance names with no statement of what the app does, that a
/// camera would be involved, or how much of the catalogue is actually open.
/// The App Store reads that as an app that does not explain itself; a dancer
/// reads it as a shop with most of the shelves empty and no sign on the door.
///
/// What it refuses to be
/// ---------------------
/// Not a tour, not a carousel, not a sales pitch. One screen, scrollable, four
/// plain statements and a way in. No progress dots implying a journey, no
/// "Let's go!", no illustration of a dancer we did not film. The family's line
/// against cheering applies hardest here, because onboarding is exactly where
/// products lie about themselves most cheaply.
///
/// Why the numbers are DERIVED
/// ---------------------------
/// The "where the app is today" paragraph counts the real catalogue at build
/// time. A hardcoded "one style is open" would be true the day it was typed
/// and quietly false the day a second one opened — the same rot the library
/// tally exists to prevent. Nothing here is a measurement OF THE DANCER, so
/// counting is honest; band language is for judgements, not inventory.
class FirstRunView extends StatelessWidget {
  const FirstRunView({
    super.key,
    required this.tally,
    required this.onContinue,
    this.cameraSessionsAvailable = false,
  });

  final LibraryTally tally;
  final VoidCallback onContinue;
  final bool cameraSessionsAvailable;

  static const Key continueKey = Key('intro.continue');
  static const Key cameraKey = Key('intro.camera');
  static const Key stateKey = Key('intro.state');

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ChoreiaBackdrop(
          child: SafeArea(
            // The way in is PINNED, the reading scrolls. Measured at 375x812:
            // with the button inside the list it sat below the fold, so the
            // only exit from the first screen a user ever sees was behind a
            // scroll they had no reason to expect. A first-run screen whose
            // exit must be discovered is a dead end with extra steps
            // (M-F-268).
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
                    children: <Widget>[
                      Text(
                        IntroStrings.title,
                        style: ChoreiaType.display(
                          size: 34,
                          color: ChoreiaColors.text(0.92),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        UiLanguage.text(
                          context,
                          en: IntroStrings.what,
                          tr: 'Beş solo dans yolunu sıralı yazılı dersler, çalışma '
                              'görevleri ve öz denetimlerle keşfet: Hip-Hop, Salsa '
                              'On1, Line Dance, Latin Fusion ve özgün kısa dans. '
                              'Hesap veya kamera gerekmez. Çalışma kaydın bu cihazda kalır.',
                        ),
                        style: ChoreiaType.body(
                          size: 15,
                          color: ChoreiaColors.text(0.78),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _panel(
                        key: cameraKey,
                        icon: Icons.videocam_outlined,
                        tone: ChoreiaColors.rose,
                        title: UiLanguage.text(
                          context,
                          en: IntroStrings.cameraTitle,
                          tr: 'KAMERA',
                        ),
                        body: UiLanguage.text(context,
                            en: IntroStrings.cameraStatus(
                                cameraSessionsAvailable),
                            tr: IntroStrings.cameraStatus(
                                cameraSessionsAvailable,
                                turkish: true)),
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        icon: Icons.music_note_outlined,
                        tone: ChoreiaColors.amber,
                        title: UiLanguage.text(
                          context,
                          en: IntroStrings.musicTitle,
                          tr: 'KENDİ MÜZİĞİN',
                        ),
                        body: UiLanguage.text(
                          context,
                          en: IntroStrings.music,
                          tr: 'Choreia içinde müzik kütüphanesi yok. İstersen '
                              'başka bir uygulamadan müzik açabilir veya '
                              'müziksiz çalışabilirsin. Kurs adımları otomatik '
                              'saymaz; müziğin ritmine göre puan verilmez.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        icon: Icons.straighten_outlined,
                        tone: ChoreiaColors.amber,
                        title: UiLanguage.text(
                          context,
                          en: IntroStrings.limitsTitle,
                          tr: 'NEYE PUAN VERMEZ',
                        ),
                        body: UiLanguage.text(
                          context,
                          en: IntroStrings.limits,
                          tr: 'Kurs ilerlemesi kendi çalışma kaydındır. Otomatik '
                              'hareket doğruluğu, ritim, zamanlama veya ustalık '
                              'puanı verilmez. His, tarz ve ifade sana aittir.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        key: stateKey,
                        icon: Icons.inventory_2_outlined,
                        tone: ChoreiaColors.roseDeep,
                        title: UiLanguage.text(
                          context,
                          en: IntroStrings.todayTitle,
                          tr: 'BUGÜNKÜ DURUM',
                        ),
                        body: UiLanguage.text(
                          context,
                          en: IntroStrings.today(tally,
                              cameraSessionsAvailable: cameraSessionsAvailable),
                          tr: IntroStrings.todayTr(tally,
                              cameraSessionsAvailable: cameraSessionsAvailable),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: continueKey,
                      onPressed: onContinue,
                      child: Text(
                        UiLanguage.text(
                          context,
                          en: IntroStrings.continueLabel,
                          tr: 'Kataloğu aç',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _panel({
    Key? key,
    required IconData icon,
    required Color tone,
    required String title,
    required String body,
  }) =>
      GlassPanel(
        key: key,
        tint: tone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatusRing(icon: icon, tone: tone, breathing: false, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: ChoreiaType.label(size: 9.5, color: tone)),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: ChoreiaType.body(
                      size: 13,
                      color: ChoreiaColors.text(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// The intro's copy, in one place — same seam as `ShellStrings`.
abstract final class IntroStrings {
  IntroStrings._();

  static const String title = 'Choreia';

  static const String what =
      'Explore five solo dance paths through sequenced written lessons, practice '
      'tasks and self-checks: Hip-Hop, Salsa On1, Line Dance, Latin Fusion and '
      'original short-form dance. No account or camera is required. Your '
      'study record stays on this device.';

  static const String currentCamera =
      'Live camera practice and subscription sales are closed in this release. '
      'The Salsa course does not capture video; it uses your own practice '
      'record and self-checks.';

  static String cameraStatus(bool available, {bool turkish = false}) {
    if (!available) {
      return turkish
          ? 'Bu sürümde canlı kamera pratiği ve abonelik satışı kapalıdır. '
              'Salsa kursu video yakalamaz; kendi çalışma kaydını ve öz denetimlerini kullanır.'
          : currentCamera;
    }
    return turkish
        ? '${LibraryStrings.sessionNotice(true, turkish: true)} Abonelik satışı kapalı kalır. '
            'Salsa kursu video yakalamaz; kendi çalışma kaydını ve öz denetimlerini kullanır.'
        : '${LibraryStrings.sessionNotice(true)} Subscription sales remain closed. '
            'The Salsa course does not capture video; it uses your own practice record and self-checks.';
  }

  static const String cameraTitle = 'THE CAMERA';

  /// **Byte-for-byte the iOS permission string.**
  ///
  /// The sentence a person reads before granting camera access and the
  /// sentence they read here must be the same sentence. Two copies of a
  /// privacy promise drift, and the one that drifts is always the one nobody
  /// is looking at — `content_claims_test` pins them equal so an edit to
  /// either fails the build.
  /// ⚠️ `no video is recorded` — the two words carry the whole point, and they
  /// were added because THIS FIX BROKE THE SCREEN (C-277, H-10 / Lissom's
  /// class read from the other direction).
  ///
  /// The card used to end *"nothing is recorded or uploaded"*. True on its own
  /// — the subject is video. But the last card on the same screen now says
  /// *"What you practise is kept on this phone"*, and a learner reading both
  /// meets one screen that appears to say nothing is kept AND that something
  /// is. `recorded` was doing double duty: video in one clause, saved in the
  /// reader's ear in the other.
  ///
  /// **And the ambiguity is NEW, caused by the honest fix.** Before C-275 the
  /// last card said *"Nothing you do is saved anywhere"* — which AGREED with
  /// the misreading. The screen was internally consistent and externally
  /// FALSE; correcting the false half made it true and incoherent.
  ///
  /// ⇒ ***COHERENCE IS A PROPERTY OF THE SET, NOT OF THE MEMBERS — SO FIXING
  /// ONE SENTENCE CAN BREAK A SCREEN THAT EVERY TEST STILL PASSES.***
  static const String camera =
      'Choreia watches your dancing to give you feedback on your steps. '
      'Video never leaves your phone — we only read the positions of your '
      'joints, and no video is recorded or uploaded.';

  static const String musicTitle = 'YOUR OWN MUSIC';

  /// There is no music library inside the app and there will not be one: a
  /// catalogue means licensing. Saying so plainly beats letting someone
  /// discover the silence and assume the app is broken.
  static const String music =
      'There is no music inside Choreia. Put on whatever you like — from any '
      'app, or nothing at all — and dance to that. The course does not count '
      'steps automatically or score track timing.';

  static const String limitsTitle = 'WHAT IT DOES NOT JUDGE';

  /// The rhythm sentence is load-bearing. The app measures body positions and
  /// has no timing or rhythm score of any kind; a user who assumes otherwise
  /// will read every silence as a bad grade. Stating the absence is the only
  /// way it stays an absence rather than an implied zero.
  static const String limits =
      'Course progress is your own practice record. There is no rhythm or timing score, '
      'automatic movement-correctness grade or mastery certification. Feel, '
      'style and expression are yours.';

  static const String todayTitle = 'WHERE THIS IS TODAY';

  /// Counted from the real catalogue every time this screen is built.
  static String today(LibraryTally tally,
      {bool cameraSessionsAvailable = false}) {
    final int openable = tally.scored + tally.openUngraded;
    return 'Open the Salsa On1 learning path from the library. The legacy '
        'dance catalogue has ${tally.total} style pages, including $openable '
        'styles with camera-session reference notes. '
        '${LibraryStrings.sessionNotice(cameraSessionsAvailable)} '
        '$_storage';
  }

  static String todayTr(LibraryTally tally,
      {bool cameraSessionsAvailable = false}) {
    final int openable = tally.scored + tally.openUngraded;
    return 'Salsa On1 öğrenme yolunu kütüphaneden aç. Önceki dans kataloğunda '
        '${tally.total} stil sayfası ve $openable stilde kamera seansı referans notları var. '
        '${LibraryStrings.sessionNotice(cameraSessionsAvailable, turkish: true)} Kendi çalışma kaydın '
        'bu cihazda saklanır; hesabına yüklenmez.';
  }

  /// What happens to a finished session — and it used to say the OPPOSITE.
  ///
  /// 🔴 **THE SENTENCE HERE WAS FALSE, AND IT WAS THE FIRST THING A NEW USER
  /// READ.** It said *"Nothing you do is saved anywhere in this version."*
  /// True when written; `C-268` built the session store, `C-269` measured it
  /// opening and writing on a real simulator, and this line never moved. So
  /// the app told every new learner their practice would be discarded, and
  /// then kept it.
  ///
  /// **Why it survived a gate built for exactly this class.** `C-269 ④` added
  /// the talkative-PRESENCE check — *"the mechanism exists, so the surface may
  /// no longer deny it"* — but it hunted a SYMBOL
  /// (`HistoryIntegrity.notRecorded`) in ONE file (the shell). This screen made
  /// the identical claim in prose, with no symbol to find, so the gate looked
  /// straight past it.
  ///
  /// ⇒ **A CLAIM IS NOT A SYMBOL.** The gate now scans the whole of `lib/` for
  /// the claim family rather than one identifier in one file
  /// (`publication_inventory_test`).
  ///
  /// **And why it was invisible to a reader, too:** it was concatenated onto a
  /// sentence that IS derived live from the catalogue (`tally`). A stale claim
  /// glued to a fresh one borrows its look of freshness — so it is split out
  /// here, as its own named thing that a gate can point at.
  static const String _storage =
      'What you practise is kept on this phone, so the progress tab can show '
      'you what you have actually done. It stays here — nothing about your '
      'practice is sent anywhere.';

  static const String continueLabel = 'Open the catalogue';
}
