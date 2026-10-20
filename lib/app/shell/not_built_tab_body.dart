import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui_language.dart';

/// Shared body for a shell tab that is named in the product's plan but has
/// no real screen behind it yet.
///
/// Same discipline `library_view.dart` already applies to unbuilt styles
/// (M-F-186: no promise language, name what's true now, never hidden and
/// never faked). A tab sitting in the nav bar with nothing built behind it
/// is exactly the "sahte dolu" (fake-full) shape that screen's own doc
/// comment warns against — CHO-P1-001 (2026-08-19) grows the shell from two
/// destinations to the roadmap's five before three of those five have a
/// real screen to show. This widget is how the gap gets NAMED instead of
/// hidden or faked; DEFTER C-321 has the full accounting of why each of
/// Today/Practice Lab/Profile is not real yet (a design decision, a
/// cross-package data-model gap, or both — not a missed checkbox).
Widget notBuiltTabBody(
  BuildContext context, {
  required Key key,
  required String title,
  required String plannedContent,
  List<Widget> trailing = const [],
}) =>
    ChoreiaBackdrop(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: ChoreiaType.of(context).display(size: 24)),
                const SizedBox(height: 12),
                Text(
                  UiLanguage.text(
                    context,
                    en: 'Named here so you can see the whole plan. Nothing is '
                        'built here yet.',
                    tr: 'Bu bölüm plandaki yerini gösterir. Burada '
                        'kullanılabilir bir özellik yok.',
                  ),
                  style: ChoreiaType.of(context).body(
                    size: 13.5,
                    color: ChoreiaPalette.of(context).text(0.78),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  plannedContent,
                  style: ChoreiaType.of(context).body(
                    size: 12.5,
                    color: ChoreiaPalette.of(context).text(0.55),
                  ),
                ),
                ...trailing,
              ],
            ),
          ),
        ),
      ),
    );
