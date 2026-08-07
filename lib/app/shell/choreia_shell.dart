import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:motion_core/motion_core.dart' show SessionRecord;

import '../library/library_catalog.dart';
import '../library/library_view.dart';
import '../progress_summary.dart';
import '../progress_view.dart';
import '../theme.dart';

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
/// Why two destinations and not more
/// ---------------------------------
/// The design draws nine screens, but seven of them are things you reach BY
/// GOING somewhere (a style, then a lesson, then the live path) — they are
/// pushed, not switched between. Only two are places you return to: the
/// catalogue and your own record. A tab per pushed screen would put a
/// permanent tab bar under a live camera session, which is the one screen that
/// should not offer a sideways exit mid-attempt.
///
/// **OPEN — coordinator's call, deliberately made cheap to reverse.** The
/// design-ahead doc §1 lists "tab bar vs. menu vs. only-from-lesson-end" as an
/// undecided IA question. A tab bar is chosen here so the shell could exist at
/// all; the choice lives entirely in [_destinations] and changing it touches
/// nothing else.
class ChoreiaShell extends StatefulWidget {
  const ChoreiaShell({super.key, this.bundleOverride});

  /// Lets a test drive the shell off repository files instead of the asset
  /// bundle — `rootBundle.loadString` deadlocks under `flutter test` in this
  /// setup (see `test/support/test_catalog.dart` for the measurement).
  final Future<LibraryCatalog> Function()? bundleOverride;

  static const Key libraryTabKey = Key('shell.tab.library');
  static const Key progressTabKey = Key('shell.tab.progress');
  static const Key loadFailureKey = Key('shell.loadFailure');
  static const Key loadingKey = Key('shell.loading');

  @override
  State<ChoreiaShell> createState() => _ChoreiaShellState();
}

class _ChoreiaShellState extends State<ChoreiaShell> {
  int _index = 0;
  late Future<LibraryCatalog> _catalog = _load();

  Future<LibraryCatalog> _load() => widget.bundleOverride != null
      ? widget.bundleOverride!()
      : LibraryCatalog.load(rootBundle);

  void _retry() => setState(() => _catalog = _load());

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
          if (!snap.hasData) return _loading();
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

  Widget _shell(LibraryCatalog library) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            LibraryView(library: library),
            ProgressView(
              // No `SessionStore` is wired up in this build (design-ahead
              // §10). This used to pass `unavailable`, whose sentence is "we
              // could not open your practice history" — and that describes a
              // store that exists and failed. A reader takes it to mean their
              // practice was recorded and is now out of reach.
              //
              // `notRecorded` is the honest state: nothing is written, so
              // nothing is missing (C-163). The publication inventory found
              // this by asking the USER-side question — not "what is missing"
              // but "which surface misinforms someone who opens the app today".
              summary: ProgressSummary.build(
                history: const <SessionRecord>[],
                catalog: library.allCourses,
                integrity: HistoryIntegrity.notRecorded,
              ),
              catalog: library.allCourses,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int i) => setState(() => _index = i),
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
              key: ChoreiaShell.libraryTabKey,
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: ShellStrings.libraryTab,
            ),
            NavigationDestination(
              key: ChoreiaShell.progressTabKey,
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline_rounded),
              label: ShellStrings.progressTab,
            ),
          ],
        ),
      );
}

/// The shell's own copy, in one place — same seam as `ProgressStrings`.
abstract final class ShellStrings {
  ShellStrings._();

  static const String libraryTab = 'STYLES';
  static const String progressTab = 'PROGRESS';

  /// The design's own instruction for its LOADING state: "no spinner tricks ·
  /// plain wait". Followed literally, as `LiveView` already does.
  static const String loading = 'Opening the catalogue…';

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
