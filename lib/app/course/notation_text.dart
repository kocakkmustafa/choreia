import 'package:flutter/material.dart';

/// A count/foot map whose source order describes physical positions.
///
/// Each line is laid out from left to right, including in an RTL interface.
/// Arabic labels shape in separate RTL boxes, so their bidi resolution cannot
/// move an adjacent arrow, count, bracket or L/R code to a different position.
/// Use ordinary [Text] for teaching prose, whose reading order should follow the
/// interface language instead.
class NotationText extends StatefulWidget {
  const NotationText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<NotationText> createState() => _NotationTextState();
}

class _NotationTextState extends State<NotationText> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingDirection = Directionality.of(context);
    final lines = widget.text.split('\n');

    // This Directionality controls layout/scroll origin, not Arabic shaping.
    // Every text run below also has its own explicit text direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
            label: widget.text,
            textDirection: readingDirection,
            // Keep one unmodified reading label. The scrollable ancestor keeps
            // its own accessibility scroll actions; only visual runs are hidden.
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var line = 0; line < lines.length; line++)
                    Row(
                      key: ValueKey('notation-line-$line'),
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        for (final run in _notationRuns(lines[line]))
                          Text(
                            _visibleWhitespace(run),
                            style: widget.style,
                            textDirection: _hasArabicLetter.hasMatch(run)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            textAlign: TextAlign.start,
                            softWrap: false,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Keep Arabic letters and their combining marks connected. Consecutive Arabic
// words form one label so phrases read normally within their fixed box. Arabic
// numerals, punctuation, arrows and Latin notation codes remain separate runs.
const _arabicLetters = '\u0620-\u065F\u066E-\u06D3\u06D5-\u06ED'
    '\u06EE-\u06EF\u06FA-\u06FC\u0750-\u077F\u08A0-\u08FF'
    '\uFB50-\uFDFF\uFE70-\uFEFC';
const _arabicWord = '[$_arabicLetters\u200C\u200D]+';
final _hasArabicLetter = RegExp('[$_arabicLetters]', unicode: true);
final _runPattern = RegExp(
  '$_arabicWord(?:[ \t]+$_arabicWord)*|[ \t]+|'
  '(?:(?![$_arabicLetters])'
  r'[\p{L}\p{M}\p{N}\u200C\u200D])+|'
  r'[\s\S]',
  unicode: true,
);

Iterable<String> _notationRuns(String line) {
  if (line.isEmpty) return const [''];
  return _runPattern.allMatches(line).map((match) => match.group(0)!);
}

String _visibleWhitespace(String run) {
  // Nonbreaking spaces retain the width of standalone whitespace boxes. The
  // original spaces/tabs/newlines remain unchanged in the semantics label.
  // A blank line also keeps one full line height at the inherited text scale.
  if (run.isEmpty) return '\u00A0';
  return run
      .replaceAll('\t', '\u00A0\u00A0\u00A0\u00A0')
      .replaceAll(' ', '\u00A0');
}
