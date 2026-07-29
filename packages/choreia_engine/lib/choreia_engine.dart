/// Choreia's dance-scoring engine — pure Dart, no Flutter.
///
/// Boundary (CLAUDE.md hard rule + M-F-160): shared infrastructure comes from
/// `motion_core` at a pinned TAG and is never copied here; app logic never
/// leaks into the core. This package is what the Flutter shell consumes.
///
/// Today's scope is deliberately narrow and honest: read a reference artifact
/// built by the Python harvest pipeline, and judge a learner cycle against it
/// for the errors that are actually LIVE. There is no camera bridge in the
/// family yet, so replay against fixtures is the only verification path — and
/// therefore the only thing this package claims to support.
library;

export 'src/judge.dart';
export 'src/reference.dart';
