import 'package:flutter/material.dart';

import '../theme.dart';

/// The one screen transition this app uses.
///
/// Straight from the design's motion spec via [ChoreiaMotion]: 400ms on
/// `cubic-bezier(.4,0,.2,1)`. The shape is a short rise plus a fade — the
/// design brief's "kardeş çakışması" clause says Choreia FLOWS where JabLab
/// cuts on snap, so there is no overshoot here and the opacity is tweened
/// rather than switched.
///
/// Written as a route class instead of a `PageRouteBuilder` at each call site
/// so that "how Choreia moves between screens" has exactly one definition. A
/// second call site copying the numbers is how two screens end up 40ms apart
/// and nobody can say which one is right.
class ChoreiaPageRoute<T> extends PageRoute<T> {
  ChoreiaPageRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => ChoreiaMotion.screenTransition;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final Animation<double> curved =
        CurvedAnimation(parent: animation, curve: ChoreiaMotion.transition);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
