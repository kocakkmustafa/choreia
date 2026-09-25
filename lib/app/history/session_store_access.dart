import 'dart:io';

import 'package:motion_core/motion_core.dart';
import 'package:path_provider/path_provider.dart';

import '../account_bridge.dart';

/// Opens the app's session history.
///
/// **This is the app's SECOND piece of persistence, and the first that stores
/// anything about the learner.** `FirstRunFlag` wrote the pattern down before
/// this existed: *"the day a real session store arrives it has a pattern to
/// follow rather than a direct `path_provider` call buried in a widget"*. This
/// file is that day, and it follows it — a seam, a shipping implementation,
/// and a test twin, with the `path_provider` call in exactly one place.
///
/// Why an OPENER and not a store
/// -----------------------------
/// Locating the app-support directory is async and can FAIL. A widget that
/// held a `SessionStore` field would have to invent one before the directory
/// is known, and the only thing to invent is a store pointing at the wrong
/// path. `ProgressSummary.from` already distinguishes "store did not open"
/// from "history is empty" — that branch is only reachable if opening is
/// allowed to throw, so this signature deliberately keeps the failure.
typedef SessionStoreOpener = Future<SessionStore> Function();

/// One JSONL file in the app-support directory, beside the first-run marker.
///
/// Format is the core's (append-only JSONL, atomic tmp+rename). Nothing here
/// re-implements storage; this function's whole job is answering WHERE.
Future<SessionStore> openAppSessionStore({
  String? accountUserId,
  Directory? supportDirectory,
}) async {
  final Directory dir = supportDirectory ?? await getApplicationSupportDirectory();
  return JsonlSessionStore(sessionFileFor(dir, accountUserId));
}

/// Named rather than inlined so a test can assert the shipping path without
/// re-deriving the string — two copies of a filename drift, and the drift is
/// silent: the app writes one file and reads another, and the progress screen
/// reports an empty history that is not empty.
const String sessionsFileName = guestSessionsFileName;
