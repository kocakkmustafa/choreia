import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:motion_core/motion_core.dart' show SessionRecord, SessionStore;

import '../history/session_store_access.dart';
import '../library/library_catalog.dart';
import '../live/live_environment.dart';
import '../onboarding/first_run_flag.dart';
import '../onboarding/first_run_view.dart';
import '../library/library_view.dart';
import '../practice_lab/practice_lab_view.dart';
import '../progress_summary.dart';
import '../progress_view.dart';
import '../theme.dart';
import '../today/today_view.dart';
import 'profile_view.dart';

/// How long the shell waits for the practice record before calling it
/// unreachable.
///
/// Generous on purpose: this is a local file, and a value tight enough to trip
/// on a slow phone would report a healthy record as lost. Named rather than
/// inlined so a test can drive the clock past it without copying the number.
const Duration historyReadTimeout = Duration(seconds: 10);

/// The app's navigation shell.
///
/// What this replaces
/// ------------------
/// Until 2026-08-07 `main.dart` opened exactly one screen — a hardcoded
/// `stepId`/`lessonClass` pair — and `ProgressView` existed, passed its whole
/// test suite, and could not be reached from anywhere. A user opening the app
/// could go nowhere. This widget is the prerequisite the design-ahead inventory
/// named as blocking every other item.
///
/// Why five destinations, and why three of them are named but not built
/// -----------------------------------------------------------------
/// Until CHO-P1-001 (2026-08-19) this shell had two tabs — Styles and
/// Progress — because everything else in the app's screen graph is reached
/// BY GOING somewhere (a style, then a lesson, then the live path), pushed
/// rather than switched between, and a tab per pushed screen would put a
/// permanent tab bar under a live camera session, the one screen that
/// should not offer a sideways exit mid-attempt. The file used to call the
/// tab count itself an open, coordinator-deferred IA question (the
/// design-ahead doc explicitly declines to settle it — see DEFTER C-321 for
/// the full paper trail across three design documents that each say
/// something different).
///
/// That question is now settled by the roadmap: five tabs — Today, Styles,
/// Practice Lab, Progress, Profile (§5). What is NOT settled is what three
/// of those five actually show: Today, Practice Lab and full Profile each
/// name capabilities (a daily path, segment looping, calibration, export/
/// delete…) that do not exist anywhere in this app yet. Rather than hide
/// those three tabs until they are real, or fake content for them, they are
/// named here and say so — the exact discipline `library_view.dart` already
/// applies to unbuilt styles (M-F-186). See [TodayView], [PracticeLabView],
/// [ProfileView] and `not_built_tab_body.dart`.
class ChoreiaShell extends StatefulWidget {
  const ChoreiaShell({
    super.key,
    this.bundleOverride,
    this.flagOverride,
    this.env = const LiveEnvironment(),
  });

  /// The device-only dependencies of the whole flow — content bundle, pose
  /// source, session store — held HERE and forwarded down.
  ///
  /// The store in particular is read by this widget and written by the lesson
  /// three screens away. Two independent defaults would agree today and
  /// diverge the day one of them changes, silently: the app writes one file,
  /// the progress screen reads another, and the symptom is an empty history —
  /// indistinguishable from a learner who has not practised.
  final LiveEnvironment env;

  /// Lets a test drive the shell off repository files instead of the asset
  /// bundle — `rootBundle.loadString` deadlocks under `flutter test` in this
  /// setup (see `test/support/test_catalog.dart` for the measurement).
  final Future<LibraryCatalog> Function()? bundleOverride;

  /// Lets a test drive the first-run screen without touching the filesystem.
  /// Defaults to the real marker file; see `FileFirstRunFlag`.
  final FirstRunFlag? flagOverride;

  static const Key todayTabKey = Key('shell.tab.today');
  static const Key libraryTabKey = Key('shell.tab.library');
  static const Key practiceLabTabKey = Key('shell.tab.practiceLab');
  static const Key progressTabKey = Key('shell.tab.progress');
  static const Key profileTabKey = Key('shell.tab.profile');
  static const Key loadFailureKey = Key('shell.loadFailure');
  static const Key loadingKey = Key('shell.loading');
  static const Key historyLoadingKey = Key('shell.historyLoading');

  @override
  State<ChoreiaShell> createState() => _ChoreiaShellState();
}

class _ChoreiaShellState extends State<ChoreiaShell> {
  // Tab ORDER follows the roadmap (Today first, §5) — but the INITIAL
  // selection stays on Styles (index 1), the one tab with something real
  // behind it today. Landing a new or returning user on an honestly-empty
  // Today tab first would be the same "sahte dolu"-adjacent mistake in
  // reverse: not a fake full screen, but a real empty one presented as the
  // front door. `_progressIndex` below documents the full order.
  int _index = 1;
  late Future<LibraryCatalog> _catalog = _load();
  late final FirstRunFlag _flag =
      widget.flagOverride ?? const FileFirstRunFlag();

  /// `null` until the flag has been read. The intro must not flash on top of
  /// the catalogue for one frame and then vanish — a returning user should
  /// never see it at all, so the shell waits for the answer rather than
  /// guessing `false` and correcting itself.
  bool? _introSeen;

  /// The practice record, READ FROM THE STORE.
  ///
  /// `null` until the first read completes, and the progress tab shows a WAIT
  /// while it is — never a placeholder summary. Every value a placeholder
  /// could carry is a claim: an empty history says "you have not practised",
  /// an `unavailable` says "we lost it". There is no honest filler.
  ///
  /// ⚠️ The wait is scoped to that ONE tab, deliberately. Blocking the whole
  /// shell on it — which is how this was first written — makes the app's
  /// launch wait on a disk read that the catalogue and the intro do not need,
  /// and a store slow to open would hold the entire app on its loading
  /// sentence.
  ProgressSummary? _progress;

  /// Cancelled on dispose — see [_withinTimeout].
  Timer? _historyTimer;

  @override
  void initState() {
    super.initState();
    _flag.hasSeenIntro().then((bool seen) {
      if (mounted) setState(() => _introSeen = seen);
    });
    _catalog.then((LibraryCatalog library) => _refreshProgress(library));
  }

  /// Re-read the history. Called once at launch and again whenever the learner
  /// goes to the progress tab, which is the only moment they can be looking at
  /// it — a session finished a second ago must not be missing from the screen
  /// that exists to show it.
  Future<void> _refreshProgress(LibraryCatalog library) async {
    ProgressSummary next;
    try {
      // ⏱ BOUNDED, and the bound is not defensive decoration.
      //
      // A store that THROWS is handled by the catch below. A store that
      // never ANSWERS is not: a hang is not an exception, so without this the
      // tab sits on "Reading your practice record…" forever, with nothing to
      // do and nothing said — the dead end M-F-268 forbids, introduced by the
      // very change that made this screen read anything at all.
      //
      // Not hypothetical: `getApplicationSupportDirectory()` under
      // `flutter test` neither completes nor throws (measured — the
      // navigability gate caught this the same hour), and a device with a
      // wedged platform channel is the same shape.
      //
      // The timeout FAILS INTO `unavailable`, never into an empty history:
      // "we could not open your record" and "you have no record" are the two
      // readings this surface spends the most effort keeping apart.
      next = await _withinTimeout(() async {
        final SessionStore store =
            await (widget.env.storeOpener ?? openAppSessionStore)();
        return ProgressSummary.from(store: store, catalog: library.allCourses);
      });
    } on Object {
      // The store could not be OPENED, or did not answer in time — a
      // different fact from an empty history, and the distinction is the whole
      // reason this branch exists. `ProgressSummary.from` draws it for read
      // failures; opening happens before that call, so it has to be drawn
      // again here.
      next = ProgressSummary.build(
        history: const <SessionRecord>[],
        catalog: library.allCourses,
        integrity: HistoryIntegrity.unavailable,
      );
    }
    if (mounted) setState(() => _progress = next);
  }

  /// [work], or a [TimeoutException] once [historyReadTimeout] has passed.
  ///
  /// Hand-rolled rather than `Future.timeout` because the timer must be
  /// CANCELLABLE. `Future.timeout` owns its timer, and a store that never
  /// answers therefore leaves one alive after the widget is gone — a leak in
  /// production and a hard failure in any test that disposes the tree
  /// (`flutter_test` asserts on pending timers, which is how this was found:
  /// five onboarding tests went red on a screen they do not even open).
  ///
  /// The timer is also cancelled on SUCCESS, so a healthy read leaves nothing
  /// behind either.
  Future<ProgressSummary> _withinTimeout(
      Future<ProgressSummary> Function() work) {
    final Completer<ProgressSummary> out = Completer<ProgressSummary>();
    _historyTimer?.cancel();
    _historyTimer = Timer(historyReadTimeout, () {
      if (!out.isCompleted) {
        out.completeError(TimeoutException(
            'practice record did not answer', historyReadTimeout));
      }
    });
    work().then((ProgressSummary v) {
      if (!out.isCompleted) out.complete(v);
    }, onError: (Object e, StackTrace st) {
      if (!out.isCompleted) out.completeError(e, st);
    });
    return out.future.whenComplete(() {
      _historyTimer?.cancel();
      _historyTimer = null;
    });
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    super.dispose();
  }

  Future<void> _dismissIntro() async {
    await _flag.markSeen();
    if (mounted) setState(() => _introSeen = true);
  }

  Future<LibraryCatalog> _load() => widget.bundleOverride != null
      ? widget.bundleOverride!()
      : LibraryCatalog.load(rootBundle);

  void _retry() {
    setState(() => _catalog = _load());
    _catalog.then((LibraryCatalog library) => _refreshProgress(library));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<LibraryCatalog>(
        future: _catalog,
        builder: (BuildContext context, AsyncSnapshot<LibraryCatalog> snap) {
          // A catalogue that will not load is NOT an empty catalogue. Rendering
          // "0 styles" here would be the same defect as a zero standing in for
          // an unread history: a number the user reads as a fact about the
          // product when it is a fact about a failure. NO DEAD END (M-F-268) —
          // the branch always offers an action.
          if (snap.hasError) return _failure();
          if (!snap.hasData || _introSeen == null) return _loading();
          if (_introSeen == false) {
            // Built from the SAME catalogue the library will show, so the
            // intro can never quote a different inventory than the screen
            // behind it.
            return FirstRunView(
              tally: LibraryTally.from(snap.data!.cards),
              onContinue: _dismissIntro,
            );
          }
          return _shell(snap.data!);
        },
      );

  Widget _loading() => Scaffold(
        body: ChoreiaBackdrop(
          child: SafeArea(
            child: Center(
              child: Text(
                ShellStrings.loading,
                key: ChoreiaShell.loadingKey,
                textAlign: TextAlign.center,
                style:
                    ChoreiaType.body(size: 14, color: ChoreiaColors.text(0.6)),
              ),
            ),
          ),
        ),
      );

  /// The progress tab before its first read lands.
  ///
  /// Says WHAT is being waited for. "Loading…" would leave a learner unable to
  /// tell a slow read from an empty record, and those are the two readings
  /// this surface spends the most effort keeping apart.
  Widget _historyLoading() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            ShellStrings.historyLoading,
            key: ChoreiaShell.historyLoadingKey,
            textAlign: TextAlign.center,
            style: ChoreiaType.body(size: 14, color: ChoreiaColors.text(0.6)),
          ),
        ),
      );

  Widget _failure() => Scaffold(
        body: ChoreiaBackdrop(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassPanel(
                  key: ChoreiaShell.loadFailureKey,
                  tint: ChoreiaColors.roseDeep,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      StatusRing(
                        icon: Icons.error_outline,
                        tone: ChoreiaColors.roseDeep,
                        breathing: false,
                        size: 52,
                      ),
                      const SizedBox(height: 16),
                      Text(ShellStrings.loadFailed,
                          style: ChoreiaType.body(
                              size: 14, color: ChoreiaColors.text(0.85))),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _retry,
                        child: const Text(ShellStrings.tryAgain),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  // Tab order matches the roadmap's own listing (§5): Today(0), Styles(1),
  // Practice Lab(2), Progress(3), Profile(4). The `IndexedStack` children
  // below and the `NavigationDestination`s in `_shell()` must stay in this
  // SAME order — only the Progress index is also needed as a value (the
  // arrival-refresh check), so only it gets a name; the rest is enforced by
  // keeping both lists in this documented order.
  static const int _progressIndex = 3;

  Widget _shell(LibraryCatalog library) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            const TodayView(),
            LibraryView(library: library, env: widget.env),
            const PracticeLabView(),
            // READ FROM THE STORE (2026-08-13). This used to hand
            // `ProgressSummary.build` an empty history and
            // `HistoryIntegrity.notRecorded` by hand, because nothing in the
            // app wrote a session — the surface was honest and the app was
            // empty. Now a finished lesson is appended, so `notRecorded` would
            // be the lie: it says "this app does not save", and it does.
            //
            // The three states downstream still hold and are still drawn by
            // the store's own answers: `ok` · `partial(n)` (some lines
            // unreadable — totals are a floor and say so) · `unavailable`
            // (could not open; no numbers shown).
            if (_progress == null)
              _historyLoading()
            else
              ProgressView(
                summary: _progress!,
                catalog: library.allCourses,
              ),
            const ProfileView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int i) {
            setState(() => _index = i);
            // Re-read on ARRIVAL, not on a timer: the learner may have
            // finished a lesson since this summary was built, and a progress
            // screen that is one session stale is a progress screen that
            // denies the practice you just did.
            if (i == _progressIndex) _refreshProgress(library);
          },
          backgroundColor: ChoreiaColors.oxblood.withValues(alpha: 0.55),
          indicatorColor: ChoreiaColors.rose.withValues(alpha: 0.16),
          surfaceTintColor: Colors.transparent,
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => ChoreiaType.label(
              size: 9.5,
              color: states.contains(WidgetState.selected)
                  ? ChoreiaColors.rose
                  : ChoreiaColors.text(0.5),
            ),
          ),
          destinations: const <Widget>[
            NavigationDestination(
              key: ChoreiaShell.todayTabKey,
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today_rounded),
              label: ShellStrings.todayTab,
            ),
            NavigationDestination(
              key: ChoreiaShell.libraryTabKey,
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: ShellStrings.libraryTab,
            ),
            NavigationDestination(
              key: ChoreiaShell.practiceLabTabKey,
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: ShellStrings.practiceLabTab,
            ),
            NavigationDestination(
              key: ChoreiaShell.progressTabKey,
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline_rounded),
              label: ShellStrings.progressTab,
            ),
            NavigationDestination(
              key: ChoreiaShell.profileTabKey,
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: ShellStrings.profileTab,
            ),
          ],
        ),
      );
}

/// The shell's own copy, in one place — same seam as `ProgressStrings`.
abstract final class ShellStrings {
  ShellStrings._();

  static const String todayTab = 'TODAY';
  static const String libraryTab = 'STYLES';
  static const String practiceLabTab = 'PRACTICE LAB';
  static const String progressTab = 'PROGRESS';
  static const String profileTab = 'PROFILE';

  /// The design's own instruction for its LOADING state: "no spinner tricks ·
  /// plain wait". Followed literally, as `LiveView` already does.
  static const String loading = 'Opening the catalogue…';

  /// NOT "loading": a learner must be able to tell a slow read from an empty
  /// record, and this screen's whole job is keeping those two apart.
  static const String historyLoading = 'Reading your practice record…';

  /// Names what failed and what it means, without a technical detail. The
  /// catalogue is a bundled asset, so this failing means the install is
  /// damaged — which the user can act on, unlike a parse error string.
  static const String loadFailed =
      'We could not read the style catalogue. Nothing is missing from your '
      'practice — this is the list of styles itself failing to load, and it '
      'ships inside the app, so reinstalling is the fix if trying again does '
      'not work.';

  static const String tryAgain = 'Try again';
}
