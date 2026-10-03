import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../history/account_store_lifetime.dart';
import 'salsa_course.dart';
import 'salsa_self_check_policy.dart';

export 'salsa_self_check_policy.dart' show SalsaPracticeOption;

enum SalsaEvidence { viewed, practised, selfReportedComplete }

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

/// Same-process writes share a lock per absolute owner path. The host ticket
/// closes admission synchronously and drains queued and dispatched operations
/// before deletion; an opener retains its ticket across directory resolution.
final class SalsaProgressStore {
  SalsaProgressStore._(this.file, this.owner, this._ownerTicket);
  final File file;
  final String owner;
  final AppStoreOwnerTicket _ownerTicket;
  static final Map<String, Future<void>> _tails = {};
  static final RegExp accountIdPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  static String ownerFor(String? id) => appStoreOwnerFor(id);

  static String fileNameFor(String? id) =>
      'course-choreia-${ownerFor(id)}.json';
  static Future<SalsaProgressStore> open(
      {String? accountUserId,
      Directory? supportDirectory,
      Future<Directory> Function()? directoryResolver,
      File Function(File file)? fileFactory,
      AppStoreOwnerRegistry? owners}) async {
    final ticket = (owners ?? appStoreOwners).capture(accountUserId);
    final support = supportDirectory ??
        await (directoryResolver ?? getApplicationSupportDirectory)();
    ticket.checkActive();
    final file = File('${support.absolute.path}/${fileNameFor(accountUserId)}');
    return SalsaProgressStore._(
        fileFactory?.call(file) ?? file, ownerFor(accountUserId), ticket);
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

  void _checkOwner() {
    _ownerTicket.checkActive();
  }

  Future<SalsaProgress> read() =>
      _ownerTicket.run(() => _locked(file.path, () async {
            _checkOwner();
            return _read();
          }));
  Future<SalsaProgress> _read() async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    _checkOwner();
    if (type == FileSystemEntityType.notFound) return SalsaProgress([]);
    if (type != FileSystemEntityType.file) {
      throw const FileSystemException('Course progress is not a regular file.');
    }
    final data = jsonDecode(await file.readAsString());
    _checkOwner();
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
      _ownerTicket.run(() => _locked(file.path, () async {
            _checkOwner();
            if (!course.lessons.any((l) => identical(l, lesson))) {
              throw ArgumentError('Lesson does not belong to this course.');
            }
            if (kind == SalsaEvidence.selfReportedComplete &&
                !lesson.selfChecksFor(option).completionAllowed) {
              throw StateError(
                  'This option records practice without completion.');
            }
            final current = await _read();
            _checkOwner();
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
            _checkOwner();
            final temporary = File('${file.path}.tmp');
            final tempType =
                await FileSystemEntity.type(temporary.path, followLinks: false);
            _checkOwner();
            if (tempType != FileSystemEntityType.notFound &&
                tempType != FileSystemEntityType.file) {
              throw const FileSystemException(
                  'Temporary progress path is not a regular file.');
            }
            var temporaryStarted = false;
            try {
              temporaryStarted = true;
              await temporary.writeAsString(
                  jsonEncode({
                    'schemaVersion': 1,
                    'owner': owner,
                    'events': updated.events.map((e) => e.toJson()).toList()
                  }),
                  flush: true);
              _checkOwner();
              await temporary.rename(file.path);
              _checkOwner();
              return updated;
            } finally {
              if (temporaryStarted &&
                  await FileSystemEntity.type(temporary.path,
                          followLinks: false) ==
                      FileSystemEntityType.file) {
                await temporary.delete();
              }
            }
          }));
  static Future<void> clearAccount(String accountUserId,
      {Directory? supportDirectory,
      Future<Directory> Function()? directoryResolver,
      AppStoreOwnerRegistry? owners}) {
    try {
      ownerFor(accountUserId);
      return (owners ?? appStoreOwners).erase(accountUserId, () async {
        final support = supportDirectory ??
            await (directoryResolver ?? getApplicationSupportDirectory)();
        final file =
            File('${support.absolute.path}/${fileNameFor(accountUserId)}');
        for (final path in [file.path, '${file.path}.tmp']) {
          if (await FileSystemEntity.type(path, followLinks: false) ==
              FileSystemEntityType.file) {
            await File(path).delete();
          }
        }
      });
    } catch (error, stack) {
      return Future<void>.error(error, stack);
    }
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
