import 'package:flutter/widgets.dart';

import '../localization/choreia_locale.dart';
import '../ui_language.dart';
import 'salsa_course.dart';

extension LocalizedCourseText on CourseText {
  String localized(BuildContext context, {bool? turkish}) =>
      ChoreiaLocaleScope.maybeOf(context) == null && turkish != null
          ? inLanguage(turkish)
          : UiLanguage.text(context, en: en, tr: tr);
}

extension LocalizedCourseLines on CourseLines {
  List<String> localized(BuildContext context, {bool? turkish}) {
    if (ChoreiaLocaleScope.maybeOf(context) == null && turkish != null) {
      return inLanguage(turkish);
    }
    return List.generate(en.length, (index) =>
        UiLanguage.text(context, en: en[index], tr: tr[index]), growable: false);
  }
}
