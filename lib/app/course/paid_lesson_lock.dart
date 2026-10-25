import 'package:flutter/material.dart';

import '../theme.dart';
import '../ui_language.dart';
import 'course_access.dart';

/// Stands in for a paid lesson's body until a membership is confirmed.
///
/// Only the lesson's instruction and new practice are held back; the course's
/// saved progress and history stay readable elsewhere on the page.
class PaidLessonLock extends StatelessWidget {
  const PaidLessonLock({required this.access, this.onUnlocked, super.key});

  final CourseAccess access;
  final VoidCallback? onUnlocked;

  static const Key buttonKey = Key('course.paidLesson.unlock');

  static const String note =
      'This lesson is part of the membership. The first lessons of every '
      'course are free; a Choreia or Motion+ membership opens the rest. '
      'Eligible new members can start with a 14-day free trial. Your saved '
      'progress stays readable.';
  static const String noteTr =
      'Bu ders üyeliğe dahildir. Her kursun ilk dersleri ücretsizdir; kalanını '
      'Choreia veya Motion+ üyeliği açar. Uygun yeni üyeler 14 günlük ücretsiz '
      'denemeyle başlayabilir. Kayıtlı ilerlemen okunabilir kalır.';

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(UiLanguage.text(context, en: note, tr: noteTr),
              style: ChoreiaType.of(context).body()),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: buttonKey,
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.lock_open_outlined),
            onPressed: () async {
              final bool granted = await access.unlock(context);
              if (granted) onUnlocked?.call();
            },
            label: Text(UiLanguage.text(context,
                en: 'Unlock with membership', tr: 'Üyelikle aç')),
          ),
        ],
      );
}
