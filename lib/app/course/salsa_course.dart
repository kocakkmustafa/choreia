/// Versioned, offline teaching content. No camera or score contract lives here.
final class CourseText {
  const CourseText(this.tr, this.en);
  factory CourseText.parse(Object? raw) {
    final map = _map(raw);
    return CourseText(_text(map['tr']), _text(map['en']));
  }
  final String tr;
  final String en;
  String inLanguage(bool turkish) => turkish ? tr : en;
}

final class CourseLines {
  CourseLines(this.tr, this.en);
  factory CourseLines.parse(Object? raw) {
    final map = _map(raw);
    return CourseLines(_strings(map['tr']), _strings(map['en']));
  }
  final List<String> tr;
  final List<String> en;
  List<String> inLanguage(bool turkish) => turkish ? tr : en;
}

final class SalsaSource {
  SalsaSource(Map<String, dynamic> data)
      : id = _text(data['id']),
        title = _text(data['title']),
        url = _text(data['url']),
        note = _text(data['note']) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        data['use'] != 'referenceOnly') {
      throw const FormatException('Sources must be HTTPS references only.');
    }
  }
  final String id, title, url, note;
}

final class SalsaModule {
  SalsaModule(Map<String, dynamic> data)
      : id = _text(data['id']),
        order = _positiveInt(data['order']),
        title = CourseText.parse(data['title']);
  final String id;
  final int order;
  final CourseText title;
}

final class SalsaLesson {
  SalsaLesson(Map<String, dynamic> data)
      : id = _text(data['id']),
        moduleId = _text(data['moduleId']),
        order = _positiveInt(data['order']),
        minutes = _positiveInt(data['minutes']),
        title = CourseText.parse(data['title']),
        goal = CourseText.parse(data['goal']),
        teaching = CourseLines.parse(data['teaching']),
        practice = CourseText.parse(data['practice']),
        selfCheck = CourseLines.parse(data['selfCheck']),
        repeat = CourseText.parse(data['repeat']),
        adaptation = CourseText.parse(data['adaptation']),
        sourceIds = _strings(data['sourceIds']),
        prerequisites = _strings(data['prerequisites'], allowEmpty: true) {
    if (!RegExp(r'^so_[0-9]{2}$').hasMatch(id) ||
        data['assessment'] != 'selfCheck' ||
        teaching.tr.length < 3 ||
        teaching.en.length < 3 ||
        selfCheck.tr.length < 2 ||
        selfCheck.en.length < 2 ||
        selfCheck.tr.length != selfCheck.en.length ||
        teaching.tr.length != teaching.en.length) {
      throw FormatException('Incomplete or unsupported lesson: $id');
    }
    final brief = _map(data['mediaBrief']);
    if (brief['status'] != 'planned') {
      throw const FormatException(
          'Unreviewed course media cannot be published.');
    }
    for (final key in ['id', 'format', 'camera', 'review', 'rights']) {
      _text(brief[key]);
    }
    CourseText.parse(brief['teachingAim']);
    CourseText.parse(brief['alternative']);
    CourseLines.parse(brief['sequence']);
    _text(data['minutesBasis']);
    _text(data['practiceKind']);
  }
  final String id, moduleId;
  final int order, minutes;
  final CourseText title, goal, practice, repeat, adaptation;
  final CourseLines teaching, selfCheck;
  final List<String> sourceIds, prerequisites;

  // These lessons use spoken/context or finger-count exercises only. Optional
  // footwork in listening lessons still requires preparation before movement.
  bool get requiresMovementPreparation =>
      !const {'so_01', 'so_03', 'so_46'}.contains(id);
}

final class SalsaCourse {
  SalsaCourse.fromJson(Map<String, dynamic> data)
      : id = _text(data['id']),
        version = _positiveInt(data['version']),
        title = CourseText.parse(data['title']),
        subtitle = CourseText.parse(data['subtitle']),
        selectionBasis = CourseText.parse(data['selectionBasis']),
        outcome = CourseText.parse(data['outcome']),
        safety = CourseText.parse(data['safety']),
        musicCopy = CourseText.parse(_map(data['music'])['copy']),
        modules = List.unmodifiable(
            _list(data['modules']).map((v) => SalsaModule(_map(v)))),
        lessons = List.unmodifiable(
            _list(data['lessons']).map((v) => SalsaLesson(_map(v)))),
        sources = List.unmodifiable(
            _list(data['sources']).map((v) => SalsaSource(_map(v)))) {
    final music = _map(data['music']);
    if (data['schemaVersion'] != 1 ||
        id != 'salsa_on1_solo' ||
        data['assessment'] != 'selfCheck' ||
        music['provided'] != false ||
        music['beatEvidence'] != 'unavailable' ||
        modules.length != 8 ||
        lessons.length != 48) {
      throw const FormatException('Unsupported Salsa course contract.');
    }
    final sourceIds = sources.map((s) => s.id).toSet();
    final moduleIds = modules.map((m) => m.id).toSet();
    if (sourceIds.length != sources.length ||
        moduleIds.length != modules.length) {
      throw const FormatException('Duplicate source or module.');
    }
    if (!_strings(data['safetySourceIds']).every(sourceIds.contains)) {
      throw const FormatException('Unknown safety source.');
    }
    final seen = <String>{};
    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      if (lesson.order != index + 1 ||
          seen.contains(lesson.id) ||
          !moduleIds.contains(lesson.moduleId) ||
          lesson.moduleId != modules[index ~/ 6].id ||
          lesson.sourceIds.any((s) => !sourceIds.contains(s)) ||
          lesson.prerequisites.any((id) => !seen.contains(id)) ||
          (index == 0 && lesson.prerequisites.isNotEmpty) ||
          (index > 0 &&
              !lesson.prerequisites.contains(lessons[index - 1].id))) {
        throw FormatException('Invalid sequence or reference at ${lesson.id}.');
      }
      seen.add(lesson.id);
    }
    for (var index = 0; index < modules.length; index++) {
      if (modules[index].order != index + 1) {
        throw const FormatException('Invalid module order.');
      }
    }
  }
  final String id;
  final int version;
  final CourseText title, subtitle, selectionBasis, outcome, safety, musicCopy;
  final List<SalsaModule> modules;
  final List<SalsaLesson> lessons;
  final List<SalsaSource> sources;
  SalsaLesson lesson(String id) => lessons.firstWhere((l) => l.id == id);
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected a content object.');
  }
  return value;
}

List<Object?> _list(Object? value) {
  if (value is! List || value.isEmpty) {
    throw const FormatException('Expected a nonempty content list.');
  }
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Expected nonempty text.');
  }
  return value;
}

int _positiveInt(Object? value) {
  if (value is! int || value <= 0) {
    throw const FormatException('Expected a positive integer.');
  }
  return value;
}

List<String> _strings(Object? value, {bool allowEmpty = false}) {
  if (value is! List || (!allowEmpty && value.isEmpty)) {
    throw const FormatException('Expected a text list.');
  }
  return List.unmodifiable(value.map(_text));
}
