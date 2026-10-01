import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'salsa_course.dart';

enum SalsaEvidence { viewed, practised, selfReportedComplete }

enum SalsaPracticeOption { standard, adapted, rhythmOnly }

/// Every record describes a user action. There is no sensor-evidence variant.
final class SalsaProgressEvent {
  const SalsaProgressEvent({
    required this.courseId,
    required this.version,
    required this.lessonId,
    required this.kind,
    required this.option,
    required this.at,
  });
  factory SalsaProgressEvent.fromJson(Map<String, dynamic> data) {
    final version = data['version'];
    final course = data['courseId'];
    final lesson = data['lessonId'];
    final at =
        DateTime.tryParse(data['at'] is String ? data['at'] as String : '');
    if (version is! int ||
        version < 1 ||
        course != 'salsa_on1_solo' ||
        lesson is! String ||
        !RegExp(r'^so_[0-9]{2}$').hasMatch(lesson) ||
        at == null) {
      throw const FormatException('Invalid course progress record.');
    }
    return SalsaProgressEvent(
      courseId: course as String,
      version: version,
      lessonId: lesson,
      kind: SalsaEvidence.values.byName(data['kind'] as String),
      option: SalsaPracticeOption.values.byName(data['option'] as String),
      at: at,
    );
  }
  final String courseId, lessonId;
  final int version;
  final SalsaEvidence kind;
  final SalsaPracticeOption option;
  final DateTime at;
  Map<String, Object> toJson() => {
        'courseId': courseId,
        'version': version,
        'lessonId': lessonId,
        'kind': kind.name,
        'option': option.name,
        'at': at.toUtc().toIso8601String(),
      };
}

final class SalsaProgress {
  SalsaProgress(Iterable<SalsaProgressEvent> events)
      : events = List.unmodifiable(events);
  final List<SalsaProgressEvent> events;
  List<SalsaProgressEvent> forCourse(SalsaCourse course) => events
      .where((e) =>
          e.courseId == course.id &&
          e.version == course.version &&
          course.lessons.any((l) => l.id == e.lessonId))
      .toList(growable: false);
  Set<String> lessonIds(SalsaCourse course, SalsaEvidence kind) =>
      forCourse(course)
          .where((e) => e.kind == kind)
          .map((e) => e.lessonId)
          .toSet();
}

/// Same-process writes and deletion share a lock per absolute owner path.
/// Stores opened before deletion become stale, preventing resurrection by an
/// outstanding lesson callback. A fresh store may be opened after local reset.
final class SalsaProgressStore {
  SalsaProgressStore._(this.file, this.owner, this._generation);
  final File file;
  final String owner;
  final int _generation;
  static final Map<String, Future<void>> _tails = {};
  static final Map<String, int> _generations = {};
  static final RegExp accountIdPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  static String ownerFor(String? id) {
    if (id == null) return 'guest';
    if (!accountIdPattern.hasMatch(id)) {
      throw ArgumentError('Expected account UUID.');
    }
    return id.toLowerCase();
  }

  static String fileNameFor(String? id) =>
      'course-choreia-${ownerFor(id)}.json';
  static Future<SalsaProgressStore> open(
      {String? accountUserId, Directory? supportDirectory}) async {
    final support = supportDirectory ?? await getApplicationSupportDirectory();
    final file = File('${support.absolute.path}/${fileNameFor(accountUserId)}');
    return SalsaProgressStore._(
        file, ownerFor(accountUserId), _generations[file.path] ?? 0);
  }

  static Future<T> _locked<T>(String path, Future<T> Function() action) {
    final completer = Completer<T>();
    final prior = _tails[path] ?? Future<void>.value();
    final next = prior.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    _tails[path] = next;
    unawaited(next.then((_) {
      if (identical(_tails[path], next)) _tails.remove(path);
    }));
    return completer.future;
  }

  void _checkGeneration() {
    if ((_generations[file.path] ?? 0) != _generation) {
      throw StateError('Progress store was cleared. Reopen it before writing.');
    }
  }

  Future<SalsaProgress> read() => _locked(file.path, () async {
        _checkGeneration();
        return _read();
      });
  Future<SalsaProgress> _read() async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return SalsaProgress([]);
    if (type != FileSystemEntityType.file) {
      throw const FileSystemException('Course progress is not a regular file.');
    }
    final data = jsonDecode(await file.readAsString());
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] != 1 ||
        data['owner'] != owner ||
        data['events'] is! List) {
      throw const FormatException(
          'Course progress is unreadable or has another owner.');
    }
    // No partial totals and no overwrite when any record is unreadable.
    return SalsaProgress((data['events'] as List)
        .map((v) => SalsaProgressEvent.fromJson(v as Map<String, dynamic>)));
  }

  Future<SalsaProgress> record(
          SalsaCourse course, SalsaLesson lesson, SalsaEvidence kind,
          {SalsaPracticeOption option = SalsaPracticeOption.standard,
          DateTime? at}) =>
      _locked(file.path, () async {
        _checkGeneration();
        if (!course.lessons.any((l) => identical(l, lesson))) {
          throw ArgumentError('Lesson does not belong to this course.');
        }
        final current = await _read();
        // Repeated views are a state; repeated practice/completion are actual events.
        if (kind == SalsaEvidence.viewed &&
            current
                .forCourse(course)
                .any((e) => e.lessonId == lesson.id && e.kind == kind)) {
          return current;
        }
        if (kind == SalsaEvidence.selfReportedComplete &&
            !current.forCourse(course).any((e) =>
                e.lessonId == lesson.id &&
                e.kind == SalsaEvidence.practised &&
                e.option == option)) {
          throw StateError(
              'Report a practice attempt with this option before completion.');
        }
        final updated = SalsaProgress([
          ...current.events,
          SalsaProgressEvent(
              courseId: course.id,
              version: course.version,
              lessonId: lesson.id,
              kind: kind,
              option: option,
              at: at ?? DateTime.now())
        ]);
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        final tempType =
            await FileSystemEntity.type(temporary.path, followLinks: false);
        if (tempType != FileSystemEntityType.notFound &&
            tempType != FileSystemEntityType.file) {
          throw const FileSystemException(
              'Temporary progress path is not a regular file.');
        }
        await temporary.writeAsString(
            jsonEncode({
              'schemaVersion': 1,
              'owner': owner,
              'events': updated.events.map((e) => e.toJson()).toList()
            }),
            flush: true);
        await temporary.rename(file.path);
        return updated;
      });
  static Future<void> clearAccount(String accountUserId,
      {Directory? supportDirectory}) async {
    final store = await open(
        accountUserId: accountUserId, supportDirectory: supportDirectory);
    return _locked(store.file.path, () async {
      _generations[store.file.path] = (_generations[store.file.path] ?? 0) + 1;
      for (final path in [store.file.path, '${store.file.path}.tmp']) {
        if (await FileSystemEntity.type(path, followLinks: false) ==
            FileSystemEntityType.file) {
          await File(path).delete();
        }
      }
    });
  }

  static Future<Set<String>> accountIds(Directory support) async {
    final ids = <String>{};
    if (!await support.exists()) return ids;
    await for (final entity in support.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final match = RegExp(r'^course-choreia-([0-9a-f-]+)\.json(?:\.tmp)?$')
          .firstMatch(name);
      if (match == null) continue;
      final id = match.group(1)!;
      if (accountIdPattern.hasMatch(id) &&
          (name == fileNameFor(id) || name == '${fileNameFor(id)}.tmp')) {
        ids.add(id);
      }
    }
    return ids;
  }
}
