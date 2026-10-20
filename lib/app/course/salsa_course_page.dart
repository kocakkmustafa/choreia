import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:motion_content/motion_content.dart';

import '../live/live_environment.dart';
import '../shell/choreia_page_route.dart';
import '../theme.dart';
import '../ui_language.dart';
import '../support_action.dart';
import '../read_deadline.dart';
import 'media/choreia_source_projection_adapter.dart';
import 'media/lesson_media_slot.dart';
import 'practice_music_notice.dart';
import 'salsa_course.dart';
import 'course_localization.dart';
import '../localization/choreia_locale.dart';
import '../localization/language_picker.dart';
import 'salsa_course_repository.dart';
import 'salsa_progress.dart';
import 'salsa_session_preparation.dart';
import 'salsa_weekly_activity.dart';
import 'support_hold_demo.dart';

String _salsaLocale(BuildContext context, bool turkish) =>
    ChoreiaLocaleScope.maybeOf(context) == null
        ? (turkish ? 'tr' : 'en')
        : UiLanguage.tag(context).replaceAll('-', '_');

String _salsaNumber(BuildContext context, num value, bool turkish,
        {int minimumDigits = 1}) =>
    (NumberFormat.decimalPattern(_salsaLocale(context, turkish))
          ..minimumIntegerDigits = minimumDigits)
        .format(value);

String _salsaDate(BuildContext context, DateTime value, bool turkish,
    {bool includeTime = false}) {
  final locale = _salsaLocale(context, turkish);
  try {
    if (DateFormat.localeExists(locale) ||
        DateFormat.localeExists(locale.split('_').first)) {
      final format = DateFormat.yMMMd(locale);
      if (includeTime) format.add_jm();
      return format.format(value);
    }
  } on Exception {
    // intl can throw while checking localeExists before any date symbols have
    // been initialized. An isolated reader must still reach the fallback below.
  }
  // An isolated TR/EN reader may not install Flutter's localization delegates.
  // Preserve its usable numeric date until those date symbols are available.
  String part(int number, [int digits = 2]) =>
      NumberFormat(digits == 4 ? '0000' : '00', locale).format(number);
  final date = '${part(value.day)}.${part(value.month)}.${part(value.year, 4)}';
  return includeTime ? '$date ${part(value.hour)}:${part(value.minute)}' : date;
}

/// An isolated reader keeps its existing TR/EN switch; application routes
/// inherit the selected locale and translate before interpolating values.
String _salsaFormat(BuildContext context, bool turkish, String english,
    String translated, Map<String, Object> values) {
  if (ChoreiaLocaleScope.maybeOf(context) != null) {
    return UiLanguage.format(context,
        en: english, tr: translated, values: values);
  }
  final names = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}')
      .allMatches(english)
      .map((match) => match[1]!)
      .toSet();
  if (names.length != values.length || !names.every(values.containsKey)) {
    throw ArgumentError('Message values must match template placeholders.');
  }
  var result = turkish ? translated : english;
  for (final entry in values.entries) {
    final value = entry.value;
    result = result.replaceAll(
        '{${entry.key}}',
        value is num
            ? _salsaNumber(context, value, turkish)
            : value.toString());
  }
  return result;
}

/// The teaching route never requests a camera, microphone or music permission.
class SalsaCourseEntry extends StatelessWidget {
  const SalsaCourseEntry({
    this.env = const LiveEnvironment(),
    this.onSourceProjectionReadback,
    super.key,
  });
  final LiveEnvironment env;
  final ChoreiaSourceProjectionObserver? onSourceProjectionReadback;
  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    final entryEpoch = env.ownerEpoch?.value;
    return GlassPanel(
      radius: 18,
      tint: ChoreiaPalette.of(context).amber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Salsa On1 · Solo',
            style: ChoreiaType.of(context).display(size: 25)),
        const SizedBox(height: 8),
        Text(
            _salsaFormat(
                context,
                tr,
                '{modules} modules · {lessons} lessons · {languages} languages',
                '{modules} modül · {lessons} ders · {languages} dil', {
              'modules': 8,
              'lessons': 48,
              'languages': ChoreiaLocaleController.supported.length
            }),
            style: ChoreiaType.of(context).body()),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('salsa.open'),
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () {
            if (!context.mounted ||
                env.passwordRecovery?.value == true ||
                entryEpoch != env.ownerEpoch?.value) {
              return;
            }
            Navigator.of(context).push(ChoreiaPageRoute<void>(
                settings: const RouteSettings(name: 'course/salsa-on1'),
                builder: (_) => SalsaCoursePage(
                    env: env,
                    onSourceProjectionReadback: onSourceProjectionReadback)));
          },
          label: Text(UiLanguage.pair(context,
              turkish: tr,
              en: 'Course & my progress',
              tr: 'Kurs ve ilerlemem')),
        ),
      ]),
    );
  }
}

class SalsaCoursePage extends StatefulWidget {
  const SalsaCoursePage({
    this.env = const LiveEnvironment(),
    this.nowForWeeklyPractice,
    this.onSourceProjectionReadback,
    super.key,
  });
  final LiveEnvironment env;
  final ChoreiaSourceProjectionObserver? onSourceProjectionReadback;

  /// Allows a calendar-boundary test without changing the device clock.
  final DateTime Function()? nowForWeeklyPractice;
  @override
  State<SalsaCoursePage> createState() => _SalsaCoursePageState();
}

class _SalsaCoursePageState extends State<SalsaCoursePage>
    with WidgetsBindingObserver {
  final _preparation = SalsaPreparationSession();
  String? _sessionOwner;
  SalsaCourse? _course;
  SalsaProgress? _progress;
  SalsaProgressStore? _store;
  bool _failed = false;
  bool _integrityFailure = false;
  bool? _turkish;
  int _loadId = 0;
  final _reads = ReadDeadline(const Duration(seconds: 10));
  bool _recoveryRetired = false;
  bool _ownerEpochRetired = false;
  bool _foreground = true;
  bool get _admitted =>
      mounted &&
      !_recoveryRetired &&
      !_ownerEpochRetired &&
      widget.env.passwordRecovery?.value != true &&
      _foreground;
  bool get tr => ChoreiaLocaleScope.maybeOf(context) == null
      ? (_turkish ?? UiLanguage.isTurkish(context))
      : UiLanguage.isTurkish(context);
  String t(String english, String turkish) =>
      ChoreiaLocaleScope.maybeOf(context) == null
          ? (tr ? turkish : english)
          : UiLanguage.text(context, en: english, tr: turkish);
  String fmt(String english, String turkish, Map<String, Object> values) =>
      _salsaFormat(context, tr, english, turkish, values);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.env.accountUserId?.addListener(_load);
    widget.env.passwordRecovery?.addListener(_onRecovery);
    widget.env.ownerEpoch?.addListener(_onOwnerEpoch);
    _recoveryRetired = widget.env.passwordRecovery?.value == true;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _load();
  }

  @override
  void didUpdateWidget(covariant SalsaCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.env != widget.env) {
      oldWidget.env.accountUserId?.removeListener(_load);
      oldWidget.env.passwordRecovery?.removeListener(_onRecovery);
      oldWidget.env.ownerEpoch?.removeListener(_onOwnerEpoch);
      widget.env.accountUserId?.addListener(_load);
      widget.env.passwordRecovery?.addListener(_onRecovery);
      widget.env.ownerEpoch?.addListener(_onOwnerEpoch);
      if (oldWidget.env.ownerEpoch != widget.env.ownerEpoch) _onOwnerEpoch();
      if (widget.env.passwordRecovery?.value == true) _onRecovery();
      _load();
    }
  }

  @override
  void dispose() {
    _loadId++;
    _reads.retire();
    WidgetsBinding.instance.removeObserver(this);
    widget.env.accountUserId?.removeListener(_load);
    widget.env.passwordRecovery?.removeListener(_onRecovery);
    widget.env.ownerEpoch?.removeListener(_onOwnerEpoch);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (mounted && !_recoveryRetired && !_ownerEpochRetired) {
        if (_course == null) {
          _load();
        } else {
          // Recompute the dated snapshot without reopening a loaded journal.
          setState(() {});
        }
      }
    } else {
      _loadId++;
      _preparation.reset();
    }
  }

  void _onRecovery() {
    if (widget.env.passwordRecovery?.value != true) return;
    _recoveryRetired = true;
    _loadId++;
    _preparation.reset();
    if (mounted) {
      setState(() {
        _course = null;
        _progress = null;
        _store = null;
      });
    }
  }

  void _onOwnerEpoch() {
    _ownerEpochRetired = true;
    _loadId++;
    _preparation.reset();
    if (mounted) {
      setState(() {
        _course = null;
        _progress = null;
        _store = null;
      });
    }
  }

  Future<void> _load() async {
    final request = ++_loadId;
    if (!_admitted) return;
    final env = widget.env;
    final bundle = env.bundle ?? rootBundle;
    final owner = env.accountUserId?.value;
    final ownerEpoch = env.ownerEpoch?.value;
    bool current() =>
        mounted &&
        _admitted &&
        request == _loadId &&
        identical(env, widget.env) &&
        identical(bundle, widget.env.bundle ?? rootBundle) &&
        owner == widget.env.accountUserId?.value &&
        ownerEpoch == widget.env.ownerEpoch?.value;
    if (_sessionOwner != owner) _preparation.reset();
    _sessionOwner = owner;
    setState(() {
      _course = null;
      _progress = null;
      _store = null;
      _failed = false;
      _integrityFailure = false;
    });
    try {
      final course = await _reads.run(SalsaCourseRepository.load(
        bundle,
      ));
      if (!current()) return;
      final store = await _reads.run(SalsaProgressStore.open(
          accountUserId: owner,
          supportDirectory: env.historyDirectoryOverride,
          owners: env.storeOwners));
      if (!current()) return;
      final progress = await _reads.run(store.read());
      if (!current()) return;
      setState(() {
        _course = course;
        _store = store;
        _progress = progress;
      });
    } on ContentException catch (error) {
      if (current()) {
        setState(() {
          _failed = true;
          _integrityFailure = switch (error.error.code) {
            ContentErrorCode.timeout || ContentErrorCode.io => false,
            _ => true,
          };
        });
      }
    } catch (_) {
      if (current()) setState(() => _failed = true);
    }
  }

  Future<void> _open(SalsaLesson lesson) async {
    if (!_admitted || _course == null || _store == null) return;
    final course = _course!;
    final store = _store!;
    await Navigator.of(context).push(ChoreiaPageRoute<void>(
        settings: const RouteSettings(name: 'course/salsa-on1/lesson'),
        builder: (_) => SalsaLessonPage(
            course: course,
            lesson: lesson,
            store: store,
            preparationSession: _preparation,
            env: widget.env,
            onSourceProjectionReadback: widget.onSourceProjectionReadback,
            initialTurkish: tr)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      appBar: AppBar(title: const Text('Salsa On1'), actions: [
        if (ChoreiaLocaleScope.maybeOf(context) != null)
          const ChoreiaLanguagePicker(compact: true)
        else
          TextButton(
              onPressed: () => setState(() => _turkish = !tr),
              child: Text(UiLanguage.pair(context,
                  turkish: tr, en: 'Türkçe', tr: 'English'))),
      ]),
      body: ChoreiaBackdrop(
          child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                  child: _recoveryRetired || _ownerEpochRetired
                      ? Center(
                          child: Text(
                              _recoveryRetired
                                  ? t('Return to Account to finish password recovery.',
                                      'Parola kurtarmayı tamamlamak için Hesap’a dön.')
                                  : t('Your account session changed. Return to Account.',
                                      'Hesap oturumun değişti. Hesap’a dön.'),
                              key: Key(_recoveryRetired
                                  ? 'salsa.recoveryRetired'
                                  : 'salsa.ownerEpochRetired')))
                      : _failed
                          ? _failure()
                          : course == null
                              ? const Center(child: CircularProgressIndicator())
                              : _overview(course)))),
    );
  }

  Widget _failure() => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                _integrityFailure
                    ? t('The Salsa course in this app did not pass its content check. Your learning record was not changed. Update the app or contact support. Do not delete the app: progress saved on this device could be lost.',
                        'Bu uygulamadaki Salsa kursu içerik denetiminden geçmedi. Öğrenme kaydın değiştirilmedi. Uygulamayı güncelle veya desteğe ulaş. Uygulamayı silme: bu cihazdaki ilerleme kaybolabilir.')
                    : t('The course or progress could not be read. Existing records were not replaced. Retry to reopen them.',
                        'Kurs veya ilerleme okunamadı. Mevcut kayıtların üzerine yazılmadı. Yeniden açmak için tekrar dene.'),
                key: const Key('salsa.loadError'),
                style: ChoreiaType.of(context).body()),
            if (!_integrityFailure)
              TextButton(
                  onPressed: _load, child: Text(t('Retry', 'Tekrar dene'))),
            const SizedBox(height: 16),
            const SupportAction(surface: SupportSurface.salsa),
          ])));
  Widget _overview(SalsaCourse course) {
    final progress = _progress!;
    final weeklyPractice = salsaWeeklyActivity(progress, course,
        now: widget.nowForWeeklyPractice?.call());
    final opened = progress.lessonIds(course, SalsaEvidence.viewed);
    final practised = progress.lessonIds(course, SalsaEvidence.practised);
    final completed =
        progress.lessonIds(course, SalsaEvidence.selfReportedComplete);
    final next = course.lessons.firstWhere((l) => !completed.contains(l.id),
        orElse: () => course.lessons.last);
    final currentEvents = progress.forCourse(course);
    final historical = progress.events.length - currentEvents.length;
    return ListView(
        key: const Key('salsa.overview'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(course.title.localized(context, turkish: tr),
              style: ChoreiaType.of(context).display(size: 34)),
          const SizedBox(height: 10),
          Text(course.subtitle.localized(context, turkish: tr),
              style: ChoreiaType.of(context).body()),
          const SizedBox(height: 18),
          GlassPanel(
              tint: ChoreiaPalette.of(context).amber,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Your learning record', 'Öğrenme kaydın'),
                        style: ChoreiaType.of(context).display(size: 25)),
                    const SizedBox(height: 10),
                    Text(
                        fmt('{completed} / {total} self-reported complete',
                            '{completed} / {total} öz beyanla tamamlandı', {
                          'completed': completed.length,
                          'total': course.lessons.length
                        }),
                        key: const Key('salsa.completedCount'),
                        style: ChoreiaType.of(context).body(size: 16)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: completed.length / course.lessons.length,
                        color: ChoreiaPalette.of(context).amber,
                        semanticsLabel: t('Self-reported completion',
                            'Öz beyanla tamamlanma'),
                        semanticsValue: NumberFormat.percentPattern(
                                _salsaLocale(context, tr))
                            .format(completed.length / course.lessons.length)),
                    const SizedBox(height: 12),
                    Text(
                        fmt(
                            'Lessons opened: {opened} · Lessons practised: {practised}',
                            'Açılan ders: {opened} · Çalışılan ders: {practised}',
                            {
                              'opened': opened.length,
                              'practised': practised.length
                            }),
                        style: ChoreiaType.of(context).body()),
                    Text(
                        _store!.owner == 'guest'
                            ? t('Saved on this device for a guest. No camera mastery score.',
                                'Bu cihazda misafir için kayıtlı. Kamera ustalık puanı yok.')
                            : t('Saved on this device for the current account. No camera mastery score.',
                                'Bu cihazda geçerli hesap için kayıtlı. Kamera ustalık puanı yok.'),
                        style: ChoreiaType.of(context).body()),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                        onPressed: () => _open(next),
                        key: const Key('salsa.continue'),
                        child: Text(fmt('Continue: {order}. {title}',
                            'Devam: {order}. {title}', {
                          'order': next.order,
                          'title': next.title.localized(context, turkish: tr)
                        }))),
                  ])),
          const SizedBox(height: 16),
          GlassPanel(
              key: const Key('salsa.weeklyPractice'),
              tint: ChoreiaPalette.of(context).rose,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Practice by week', 'Haftalık pratik'),
                        style: ChoreiaType.of(context).display(size: 22)),
                    const SizedBox(height: 6),
                    Text(
                        fmt(
                            'Four calendar weeks as of {date}. '
                                'Saved course actions include rhythm-only practice; '
                                'they do not prove movement or camera skill.',
                            '{date} itibarıyla dört takvim haftası. '
                                'Kayıtlı kurs denemelerine yalnız ritim çalışması da dahildir; '
                                'bunlar hareket veya kamera becerisini kanıtlamaz.',
                            {'date': _shortDate(weeklyPractice.asOf)}),
                        style: ChoreiaType.of(context).body()),
                    const SizedBox(height: 12),
                    for (var i = 0; i < weeklyPractice.weeks.length; i++)
                      _weeklyPracticeRow(weeklyPractice.weeks[i], i),
                    if (weeklyPractice.futureDatedAttempts > 0)
                      Text(
                          fmt(
                              'Future-dated saved attempts: {count}. '
                                  'They remain in course history and the overall lesson count, '
                                  'but are omitted from these weeks. Check the device clock.',
                              'Gelecek tarihli kayıtlı deneme: {count}. '
                                  'Kurs geçmişinde ve genel ders sayısında durur; '
                                  'bu haftalara eklenmez. Cihaz saatini kontrol et.',
                              {'count': weeklyPractice.futureDatedAttempts}),
                          key: const Key('salsa.weeklyPractice.futureDateNote'),
                          style: ChoreiaType.of(context).body(size: 12)),
                  ])),
          const SizedBox(height: 16),
          Text(course.outcome.localized(context, turkish: tr),
              style: ChoreiaType.of(context).body()),
          const SizedBox(height: 8),
          Text(
              t('Lessons are open to revisit. Prerequisites suggest a learning order. Completion records the option you used.',
                  'Dersleri istediğin zaman yeniden açabilirsin. Önkoşullar önerilen sırayı gösterir. Tamamlanma, kullandığın seçenekle kaydedilir.'),
              style: ChoreiaType.of(context).body()),
          const SizedBox(height: 18),
          PracticeMusicNotice(turkish: tr),
          for (final module in course.modules) ...[
            Text(
                '${_salsaNumber(context, module.order, tr, minimumDigits: 2)} · ${module.title.localized(context, turkish: tr)}',
                style: ChoreiaType.of(context).display(size: 26)),
            const SizedBox(height: 8),
            for (final lesson
                in course.lessons.where((l) => l.moduleId == module.id))
              Card(
                  color:
                      ChoreiaPalette.of(context).oxblood.withValues(alpha: .7),
                  child: ListTile(
                    key: Key('salsa.lesson.${lesson.id}'),
                    leading: Text(
                        _salsaNumber(context, lesson.order, tr,
                            minimumDigits: 2),
                        style: ChoreiaType.of(context).label(size: 12)),
                    title: Text(lesson.title.localized(context, turkish: tr)),
                    subtitle: Text(completed.contains(lesson.id)
                        ? t('Self-reported complete · revisit',
                            'Öz beyanla tamamlandı · tekrar aç')
                        : practised.contains(lesson.id)
                            ? t('Practised', 'Çalışıldı')
                            : opened.contains(lesson.id)
                                ? t('Opened', 'Açıldı')
                                : fmt(
                                    'Suggested {minutes} min · adjust freely',
                                    'Öneri {minutes} dk · kendine göre ayarla',
                                    {'minutes': lesson.minutes})),
                    trailing: Icon(
                        completed.contains(lesson.id)
                            ? Icons.check_circle_outline
                            : Icons.chevron_right,
                        color: ChoreiaPalette.of(context).amber),
                    onTap: () => _open(lesson),
                  )),
            const SizedBox(height: 22),
          ],
          ExpansionTile(
              title: Text(t('Practice history', 'Pratik geçmişi')),
              children: [
                if (currentEvents
                    .where((e) => e.kind != SalsaEvidence.viewed)
                    .isEmpty)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t('No practice saved for this version.',
                          'Bu sürüm için kayıtlı pratik yok.'))),
                for (final event in currentEvents
                    .where((e) => e.kind != SalsaEvidence.viewed)
                    .toList()
                    .reversed)
                  ListTile(
                      title: Text(course
                          .lesson(event.lessonId)
                          .title
                          .localized(context, turkish: tr)),
                      subtitle: Text(
                          '${_eventLabel(context, event.kind, tr)} · ${_optionLabel(context, event.option, tr)}\n'
                          '${_salsaDate(context, event.at.toLocal(), tr, includeTime: true)}')),
                if (historical > 0)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(fmt(
                          '{count} records from other content versions are retained and excluded from this version’s totals.',
                          'Başka içerik sürümlerinden {count} kayıt korunuyor; bu sürümün toplamına eklenmiyor.',
                          {'count': historical}))),
              ]),
          ExpansionTile(
              title: Text(t('About this course', 'Bu kurs hakkında')),
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        course.selectionBasis.localized(context, turkish: tr),
                        style: ChoreiaType.of(context).body()))
              ]),
          _safetyPanel(context, course, tr),
        ]);
  }

  Widget _weeklyPracticeRow(SalsaPracticeWeek week, int index) {
    final end = DateTime(
        week.startsOn.year, week.startsOn.month, week.startsOn.day + 6);
    final dates = '${_shortDate(week.startsOn)} – ${_shortDate(end)}';
    return Padding(
      key: Key('salsa.weeklyPractice.week$index'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dates, style: ChoreiaType.of(context).label(size: 11)),
          const SizedBox(height: 3),
          Text(
              fmt('Saved attempts: {attempts} · Lessons with attempts: {lessons}',
                  'Kayıtlı deneme: {attempts} · Denenen ders: {lessons}', {
                'attempts': week.practiceAttempts,
                'lessons': week.distinctLessons
              }),
              style: ChoreiaType.of(context).body(size: 13)),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) => _salsaDate(context, date, tr);
}

class SalsaLessonPage extends StatefulWidget {
  const SalsaLessonPage(
      {required this.course,
      required this.lesson,
      required this.store,
      required this.env,
      required this.initialTurkish,
      this.preparationSession,
      this.onSourceProjectionReadback,
      super.key});
  final SalsaCourse course;
  final SalsaLesson lesson;
  final SalsaProgressStore store;
  final LiveEnvironment env;
  final bool initialTurkish;
  final SalsaPreparationSession? preparationSession;
  final ChoreiaSourceProjectionObserver? onSourceProjectionReadback;
  @override
  State<SalsaLessonPage> createState() => _SalsaLessonPageState();
}

class _SalsaLessonPageState extends State<SalsaLessonPage>
    with WidgetsBindingObserver {
  late SalsaLesson _lesson;
  late bool tr;
  late List<bool> _checks;
  late final SalsaPreparationSession _preparation;
  bool _busy = false, _practiceSaved = false, _completed = false;
  bool _accountChanged = false, _saveFailed = false;
  int _sessionEpoch = 0;
  int _sourceEpoch = 0;
  bool _foreground = true;
  bool _recoveryRetired = false;
  ChoreiaSourceProjectionResult _sourceReadback =
      const ChoreiaSourceUnavailableNoMedia();

  @visibleForTesting
  ChoreiaSourceProjectionResult get sourceProjectionReadback => _sourceReadback;

  bool get _admitted =>
      mounted &&
      !_accountChanged &&
      !_recoveryRetired &&
      widget.env.passwordRecovery?.value != true;
  SalsaPracticeOption _option = SalsaPracticeOption.standard;
  Timer? _timer;
  int _count = 1;
  double _pace = 80;
  String t(String english, String turkish) =>
      ChoreiaLocaleScope.maybeOf(context) == null
          ? (tr ? turkish : english)
          : UiLanguage.text(context, en: english, tr: turkish);
  String fmt(String english, String turkish, Map<String, Object> values) =>
      _salsaFormat(context, tr, english, turkish, values);
  bool get _needsPreparation =>
      _lesson.requiresMovementPreparation &&
      _option != SalsaPracticeOption.rhythmOnly &&
      !_preparation.acknowledged;
  bool get _physicalOption =>
      _lesson.requiresMovementPreparation &&
      _option != SalsaPracticeOption.rhythmOnly;
  bool get _ownerMatches {
    try {
      return SalsaProgressStore.ownerFor(widget.env.accountUserId?.value) ==
          widget.store.owner;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _preparation = widget.preparationSession ?? SalsaPreparationSession();
    _lesson = widget.lesson;
    tr = widget.initialTurkish;
    _resetChecks();
    WidgetsBinding.instance.addObserver(this);
    widget.env.accountUserId?.addListener(_onAccount);
    widget.env.passwordRecovery?.addListener(_onRecovery);
    widget.env.ownerEpoch?.addListener(_onOwnerEpoch);
    _recoveryRetired = widget.env.passwordRecovery?.value == true;
    _accountChanged = _recoveryRetired;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    unawaited(_readSourceProjection());
    _record(SalsaEvidence.viewed);
  }

  @override
  void didUpdateWidget(covariant SalsaLessonPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final envChanged = oldWidget.env != widget.env;
    if (envChanged) {
      oldWidget.env.accountUserId?.removeListener(_onAccount);
      oldWidget.env.passwordRecovery?.removeListener(_onRecovery);
      oldWidget.env.ownerEpoch?.removeListener(_onOwnerEpoch);
      widget.env.accountUserId?.addListener(_onAccount);
      widget.env.passwordRecovery?.addListener(_onRecovery);
      widget.env.ownerEpoch?.addListener(_onOwnerEpoch);
      if (oldWidget.env.ownerEpoch != widget.env.ownerEpoch) _onOwnerEpoch();
      if (oldWidget.env.accountUserId != widget.env.accountUserId ||
          !_ownerMatches) {
        _onAccount();
      }
      if (widget.env.passwordRecovery?.value == true) _onRecovery();
    }
    if (oldWidget.lesson != widget.lesson ||
        oldWidget.course != widget.course ||
        oldWidget.store != widget.store) {
      _revokePreparation();
      _lesson = widget.lesson;
      _practiceSaved = false;
      _completed = false;
      _resetChecks();
      if (!_ownerMatches) _onAccount();
    }
    if (envChanged ||
        oldWidget.lesson != widget.lesson ||
        oldWidget.course != widget.course ||
        oldWidget.store != widget.store ||
        oldWidget.onSourceProjectionReadback !=
            widget.onSourceProjectionReadback) {
      _retireSource();
      unawaited(_readSourceProjection());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ChoreiaLocaleScope.maybeOf(context) != null) {
      // Locale changes affect presentation only, never practice/check state.
      tr = UiLanguage.isTurkish(context);
    }
  }

  void _retireSource() {
    _sourceEpoch++;
    _sourceReadback = const ChoreiaSourceUnavailableNoMedia();
  }

  Future<void> _readSourceProjection() async {
    final epoch = ++_sourceEpoch;
    if (!_admitted || !_ownerMatches || !_foreground) return;
    final env = widget.env;
    final bundle = env.bundle ?? rootBundle;
    final owner = env.accountUserId?.value;
    final recovery = env.passwordRecovery;
    final ownerEpochNotifier = env.ownerEpoch;
    final ownerEpoch = ownerEpochNotifier?.value;
    final course = widget.course;
    final lessonId = _lesson.id;
    final observer = widget.onSourceProjectionReadback;
    bool current() =>
        mounted &&
        _admitted &&
        _ownerMatches &&
        _foreground &&
        epoch == _sourceEpoch &&
        identical(env, widget.env) &&
        identical(bundle, widget.env.bundle ?? rootBundle) &&
        identical(recovery, widget.env.passwordRecovery) &&
        identical(ownerEpochNotifier, widget.env.ownerEpoch) &&
        ownerEpoch == widget.env.ownerEpoch?.value &&
        owner == widget.env.accountUserId?.value &&
        identical(course, widget.course) &&
        lessonId == _lesson.id &&
        identical(observer, widget.onSourceProjectionReadback);
    try {
      final result = await ChoreiaSourceProjectionAdapter.load(
          bundle: bundle, isCurrent: current);
      if (!current()) return;
      _sourceReadback = result;
      if (observer != null) await observer(result);
    } catch (_) {
      // Both synchronous and asynchronous observer errors remain NO_MEDIA.
      // Never invoke the failed observer again to report its own error.
      if (current()) _sourceReadback = const ChoreiaSourceUnavailableNoMedia();
    }
  }

  @override
  void dispose() {
    _retireSource();
    _timer?.cancel();
    widget.env.accountUserId?.removeListener(_onAccount);
    widget.env.passwordRecovery?.removeListener(_onRecovery);
    widget.env.ownerEpoch?.removeListener(_onOwnerEpoch);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _retireSource();
    if (!_foreground) {
      _revokePreparation();
    } else {
      unawaited(_readSourceProjection());
    }
  }

  void _onAccount() {
    _accountChanged = true;
    _retireSource();
    _revokePreparation();
  }

  void _onOwnerEpoch() => _onAccount();

  void _onRecovery() {
    if (widget.env.passwordRecovery?.value != true) return;
    _recoveryRetired = true;
    _accountChanged = true;
    _retireSource();
    _revokePreparation();
  }

  void _revokePreparation() {
    _preparation.reset();
    _timer?.cancel();
    _timer = null;
    _sessionEpoch++;
    if (mounted) {
      setState(() {
        if (_physicalOption) {
          _practiceSaved = false;
          _checks = List.filled(_checks.length, false);
        }
      });
    }
  }

  void _acknowledgePreparation() {
    if (!_admitted || !_foreground) return;
    setState(() {
      // A day change can expire a shared session without a lifecycle event.
      _sessionEpoch++;
      _practiceSaved = false;
      _checks = List.filled(_checks.length, false);
      _preparation.acknowledged = true;
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }

  void _startCounter() {
    if (!_admitted || !_foreground || _needsPreparation) return;
    _count = 1;
    _timer =
        Timer.periodic(Duration(milliseconds: (60000 / _pace).round()), (_) {
      if (!_admitted || !_foreground || _needsPreparation) {
        _pause();
        return;
      }
      if (mounted) setState(() => _count = _count % 8 + 1);
    });
    setState(() {});
  }

  Future<void> _record(SalsaEvidence evidence) async {
    if (_busy || !_admitted || !_foreground || !_ownerMatches) return;
    if (evidence != SalsaEvidence.viewed && _needsPreparation) return;
    if (evidence == SalsaEvidence.selfReportedComplete &&
        (!_lesson.selfChecksFor(_option).completionAllowed ||
            _checks.isEmpty ||
            !_checks.every((checked) => checked))) {
      return;
    }
    final sessionEpoch = _sessionEpoch;
    setState(() {
      _busy = true;
      _saveFailed = false;
    });
    try {
      await widget.store
          .record(widget.course, _lesson, evidence, option: _option);
      if (!mounted || !_admitted || !_ownerMatches) return;
      setState(() {
        if (evidence == SalsaEvidence.practised &&
            sessionEpoch == _sessionEpoch &&
            (!_physicalOption || _preparation.acknowledged)) {
          _practiceSaved = true;
        }
        if (evidence == SalsaEvidence.selfReportedComplete &&
            sessionEpoch == _sessionEpoch &&
            (!_physicalOption || _preparation.acknowledged)) {
          _completed = true;
        }
      });
    } catch (_) {
      if (mounted && _admitted && _ownerMatches) {
        setState(() => _saveFailed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (!_admitted || !_foreground) return;
    _retireSource();
    _pause();
    setState(() {
      _lesson = widget.course.lessons[_lesson.order];
      _practiceSaved = false;
      _completed = false;
      _saveFailed = false;
      _option = SalsaPracticeOption.standard;
      _resetChecks();
      _count = 1;
    });
    unawaited(_readSourceProjection());
    _record(SalsaEvidence.viewed);
  }

  void _openSupportHoldDemo() {
    if (!_admitted || !_ownerMatches || !_foreground || _lesson.id != 'so_04') {
      return;
    }
    Navigator.of(context).push(ChoreiaPageRoute<void>(
        settings: const RouteSettings(name: 'course/salsa-on1/support-hold'),
        builder: (_) => SupportHoldDemo(turkish: tr)));
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final selection = lesson.selfChecksFor(_option);
    final statements = lesson.selfCheck.localized(context, turkish: tr);
    return Scaffold(
      appBar: AppBar(
          title: Text('${_salsaNumber(context, lesson.order, tr)} / '
              '${_salsaNumber(context, widget.course.lessons.length, tr)}'),
          actions: [
            if (ChoreiaLocaleScope.maybeOf(context) != null)
              const ChoreiaLanguagePicker(compact: true)
            else
              TextButton(
                  onPressed: () => setState(() => tr = !tr),
                  child: Text(UiLanguage.pair(context,
                      turkish: tr, en: 'Türkçe', tr: 'English'))),
          ]),
      body: ChoreiaBackdrop(
          child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                  child: ListView(
                      key: ValueKey('salsa.lessonBody.${lesson.id}'),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                    if (_accountChanged)
                      GlassPanel(
                          child: Column(children: [
                        Text(
                            _recoveryRetired
                                ? t('Return to Account to finish password recovery.',
                                    'Parola kurtarmayı tamamlamak için Hesap’a dön.')
                                : t('The account changed. Return to the course to use the current account’s progress.',
                                    'Hesap değişti. Geçerli hesabın ilerlemesi için kursa geri dön.'),
                            key: const Key('salsa.accountChanged'),
                            style: ChoreiaType.of(context).body()),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(t('Back to course', 'Kursa dön'))),
                      ])),
                    Text(lesson.title.localized(context, turkish: tr),
                        style: ChoreiaType.of(context).display(size: 34)),
                    LessonMediaSlot.empty(
                      key: ValueKey('salsa.mediaSlot.${lesson.id}'),
                      bundle: widget.env.bundle ?? rootBundle,
                      lessonId: lesson.id,
                      locale: ChoreiaLocaleScope.maybeOf(context) == null
                          ? (tr ? 'tr' : 'en')
                          : UiLanguage.tag(context),
                      accountUserId: widget.env.accountUserId,
                      passwordRecovery: widget.env.passwordRecovery,
                      ownerEpoch: widget.env.ownerEpoch,
                    ),
                    if (_needsPreparation) ...[
                      const SizedBox(height: 16),
                      SalsaSessionPreparation(
                          turkish: tr,
                          onPrepared: _busy || _accountChanged
                              ? null
                              : _acknowledgePreparation,
                          onSpokenOnly: _busy || _accountChanged
                              ? null
                              : () =>
                                  _chooseOption(SalsaPracticeOption.rhythmOnly),
                          onStop: () => Navigator.of(context).pop()),
                    ],
                    const SizedBox(height: 12),
                    Text(lesson.goal.localized(context, turkish: tr),
                        style: ChoreiaType.of(context).body(size: 16)),
                    const SizedBox(height: 8),
                    Text(
                        fmt(
                            'Suggested {minutes} minutes, including pauses. Take the time you need.',
                            'Molalar dahil öneri {minutes} dakika. Süreyi kendine göre ayarla.',
                            {'minutes': lesson.minutes}),
                        style: ChoreiaType.of(context).body()),
                    if (lesson.prerequisites.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                          fmt('Recommended first: {title}',
                              'Önce önerilen: {title}', {
                            'title': widget.course
                                .lesson(lesson.prerequisites.first)
                                .title
                                .localized(context, turkish: tr)
                          }),
                          style: ChoreiaType.of(context).body()),
                    ],
                    _sectionTitle(t('Learn', 'Öğren')),
                    for (final (index, instruction) in lesson.teaching
                        .localized(context, turkish: tr)
                        .indexed)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                              '${_salsaNumber(context, index + 1, tr)}. $instruction',
                              style: ChoreiaType.of(context).body(size: 15))),
                    if (lesson.id == 'so_04') ...[
                      Text(
                          t('A silent symbolic example for reading and description. It is not a physical demonstration, measured music beat or completion task.',
                              'Okuma ve anlatım için sessiz sembolik örnek. Fiziksel gösterim, ölçülmüş müzik vuruşu veya tamamlama görevi değildir.'),
                          style: ChoreiaType.of(context).body(size: 14)),
                      TextButton(
                          key: const Key('salsa.supportHoldDemo'),
                          onPressed: _admitted && _ownerMatches
                              ? _openSupportHoldDemo
                              : null,
                          child: Text(t('Inspect the support and hold diagram',
                              'Destek ve durak şemasını incele'))),
                    ],
                    _sectionTitle(t('Try it', 'Uygula')),
                    Text(
                        t('Keep movement comfortable. Stop for pain, dizziness or feeling unwell.',
                            'Hareketi rahat sınırında tut. Ağrı, baş dönmesi veya kötü hissetmede dur.'),
                        style: ChoreiaType.of(context)
                            .body(color: ChoreiaPalette.of(context).amber)),
                    const SizedBox(height: 10),
                    if (_needsPreparation)
                      Text(
                          t('Prepare above before moving, or choose rhythm / spoken only below.',
                              'Harekete geçmeden önce yukarıdaki hazırlığı yap veya aşağıdan yalnız ritim / sözlü seçeneğini seç.'),
                          key: const Key('salsa.preparation.required'),
                          style: ChoreiaType.of(context).body())
                    else ...[
                      if (_option == SalsaPracticeOption.rhythmOnly)
                        Text(
                            t('Read this lesson’s sequence and describe it in your own words. If useful, speak 1-2-3, 5-6-7 with the silent guide. Keep this attempt to reading and voice; leave footwork, weight transfer, turns and crossings untried. Record only this spoken option.',
                                'Bu dersin sırasını oku ve kendi sözlerinle anlat. İstersen sessiz rehberle 1-2-3, 5-6-7 sayımını sesli söyle. Bu denemeyi okuma ve sesle sınırla; ayak çalışması, ağırlık aktarımı, dönüş ve çapraz adımlar denenmedi olarak kalsın. Yalnız bu sözlü seçeneği kaydet.'),
                            key: const Key('salsa.spokenPractice'),
                            style: ChoreiaType.of(context).body(size: 15))
                      else
                        Text(lesson.practice.localized(context, turkish: tr),
                            style: ChoreiaType.of(context).body(size: 15)),
                      const SizedBox(height: 16),
                      _counter(),
                    ],
                    if (_preparation.acknowledged)
                      TextButton(
                          key: const Key('salsa.preparation.restart'),
                          onPressed: _revokePreparation,
                          child: Text(t('After a break · prepare again',
                              'Moladan sonra · yeniden hazırlan'))),
                    _sectionTitle(t('Choose your practice option',
                        'Pratik seçeneğini seç')),
                    Text(lesson.adaptation.localized(context, turkish: tr),
                        style: ChoreiaType.of(context).body()),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final option in SalsaPracticeOption.values)
                        ChoiceChip(
                            key: Key('salsa.option.${option.name}'),
                            label: Text(_optionLabel(context, option, tr)),
                            selected: _option == option,
                            onSelected: _busy || _accountChanged
                                ? null
                                : (_) => _chooseOption(option)),
                    ]),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                        onPressed: _busy || _accountChanged || _needsPreparation
                            ? null
                            : () {
                                _pause();
                                _record(SalsaEvidence.practised);
                              },
                        key: const Key('salsa.savePractice'),
                        child: Text(_practiceSaved
                            ? t('Practice saved · save another attempt',
                                'Pratik kaydedildi · yeni denemeyi kaydet')
                            : t('I tried the exercise · save practice',
                                'Alıştırmayı denedim · pratiği kaydet'))),
                    _sectionTitle(t('Review your own practice',
                        'Kendi pratiğini değerlendir')),
                    if (!selection.completionAllowed)
                      Text(
                          t('This spoken option saves practice only. Physical self-checks remain untried and do not count as completion.',
                              'Bu sözlü seçenek yalnız pratiği kaydeder. Fiziksel öz değerlendirmeler denenmedi olarak kalır; tamamlanma sayılmaz.'),
                          key: const Key('salsa.practiceOnly'),
                          style: ChoreiaType.of(context).body()),
                    if (selection.completionAllowed)
                      Text(
                          t('Tick each statement only if it matches your chosen practice option. These are your observations.',
                              'Her ifadeyi yalnız seçtiğin pratik seçeneğinde sana uyuyorsa işaretle. Bunlar senin gözlemlerin.'),
                          style: ChoreiaType.of(context).body()),
                    for (final (index, statement) in selection.indices
                        .map((index) => statements[index])
                        .indexed)
                      CheckboxListTile(
                          key: Key('salsa.check.$index'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(statement),
                          value: _checks[index],
                          onChanged: _busy || _accountChanged
                              ? null
                              : (value) => setState(
                                  () => _checks[index] = value ?? false)),
                    const SizedBox(height: 8),
                    Text(lesson.repeat.localized(context, turkish: tr),
                        style: ChoreiaType.of(context).body()),
                    const SizedBox(height: 16),
                    if (_saveFailed)
                      Text(
                          t('Could not save. Your earlier records were not replaced. Return to the course and retry.',
                              'Kaydedilemedi. Önceki kayıtların üzerine yazılmadı. Kursa dönüp tekrar dene.'),
                          key: const Key('salsa.saveError'),
                          style: ChoreiaType.of(context)
                              .body(color: ChoreiaPalette.of(context).error)),
                    FilledButton(
                        onPressed: _busy ||
                                _accountChanged ||
                                _needsPreparation ||
                                !_practiceSaved ||
                                !selection.completionAllowed ||
                                _checks.isEmpty ||
                                !_checks.every((checked) => checked)
                            ? null
                            : () {
                                _pause();
                                _record(SalsaEvidence.selfReportedComplete);
                              },
                        key: const Key('salsa.complete'),
                        child: Text(t('Save self-reported completion',
                            'Öz beyanla tamamlanmayı kaydet'))),
                    if (_completed) ...[
                      const SizedBox(height: 12),
                      Text(
                          fmt(
                              'Saved as self-reported complete · {option}. This is not a camera skill assessment.',
                              'Öz beyanla tamamlandı · {option} olarak kaydedildi. Bu bir kamera beceri değerlendirmesi değildir.',
                              {'option': _optionLabel(context, _option, tr)}),
                          key: const Key('salsa.saved'),
                          style: ChoreiaType.of(context).body()),
                      if (lesson.order < widget.course.lessons.length)
                        TextButton(
                            key: const Key('salsa.next'),
                            onPressed: _busy || _accountChanged ? null : _next,
                            child: Text(t('Next lesson', 'Sonraki ders'))),
                    ],
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(t('Back to course', 'Kursa dön'))),
                    _safetyPanel(context, widget.course, tr),
                    ExpansionTile(
                        title:
                            Text(t('Sources & context', 'Kaynaklar ve bağlam')),
                        children: [
                          for (final source in widget.course.sources
                              .where((s) => lesson.sourceIds.contains(s.id)))
                            Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(source.title,
                                          style:
                                              ChoreiaType.of(context).body()),
                                      SelectableText(source.url,
                                          style:
                                              ChoreiaType.of(context).body()),
                                      if (source.supports case final support?)
                                        Text(
                                            '${t('Supports only:', 'Yalnız destekler:')} ${support.localized(context, turkish: tr)}',
                                            key: Key(
                                                'salsa.sourceScope.${source.id}'),
                                            style:
                                                ChoreiaType.of(context).body()),
                                      if (source.doesNotSupport
                                          case final limit?)
                                        Text(
                                            '${t('Does not establish:', 'Kanıtlamaz:')} ${limit.localized(context, turkish: tr)}',
                                            key: Key(
                                                'salsa.sourceLimit.${source.id}'),
                                            style:
                                                ChoreiaType.of(context).body()),
                                      TextButton.icon(
                                          icon: const Icon(Icons.copy_outlined),
                                          onPressed: () => Clipboard.setData(
                                              ClipboardData(text: source.url)),
                                          label: Text(t('Copy source link',
                                              'Kaynak bağlantısını kopyala'))),
                                    ]))
                        ]),
                  ])))),
    );
  }

  void _chooseOption(SalsaPracticeOption option) {
    if (!_admitted || !_foreground) return;
    _pause();
    setState(() {
      _option = option;
      _sessionEpoch++;
      _practiceSaved = false;
      _completed = false;
      _resetChecks();
    });
  }

  void _resetChecks() => _checks =
      List.filled(_lesson.selfChecksFor(_option).indices.length, false);

  Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: ChoreiaType.of(context).display(size: 25)));
  Widget _counter() => GlassPanel(
      tint: ChoreiaPalette.of(context).amber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('Silent count guide', 'Sessiz sayım rehberi'),
            style: ChoreiaType.of(context).display(size: 24)),
        const SizedBox(height: 8),
        Text(widget.course.musicCopy.localized(context, turkish: tr),
            style: ChoreiaType.of(context).body()),
        const SizedBox(height: 14),
        PracticeMusicNotice(turkish: tr),
        Wrap(spacing: 6, runSpacing: 8, children: [
          for (var number = 1; number <= 8; number++)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _count == number
                            ? ChoreiaPalette.of(context).amber
                            : ChoreiaPalette.of(context).text(.55))),
                child: Text(_salsaNumber(context, number, tr),
                    style: ChoreiaType.of(context).label(
                        size: 16,
                        color: _count == number
                            ? ChoreiaPalette.of(context).amber
                            : ChoreiaPalette.of(context).bright))),
        ]),
        const SizedBox(height: 8),
        Text(
            fmt('{pace} visual pulses / minute', '{pace} görsel nabız / dakika',
                {'pace': _pace.round()}),
            style: ChoreiaType.of(context).body()),
        Slider(
            value: _pace,
            min: 40,
            max: 160,
            divisions: 24,
            label: _salsaNumber(context, _pace.round(), tr),
            semanticFormatterCallback: (value) => fmt(
                '{pace} visual pulses per minute',
                'Dakikada {pace} görsel nabız',
                {'pace': value.round()}),
            onChanged: _accountChanged
                ? null
                : (value) {
                    _pause();
                    setState(() => _pace = value);
                  }),
        FilledButton.tonalIcon(
            key: const Key('salsa.counter'),
            onPressed: _accountChanged
                ? null
                : _timer == null
                    ? _startCounter
                    : _pause,
            icon: Icon(_timer == null ? Icons.play_arrow : Icons.pause),
            label: Text(_timer == null
                ? t('Start count', 'Sayımı başlat')
                : t('Pause', 'Duraklat'))),
      ]));
}

Widget _safetyPanel(BuildContext context, SalsaCourse course, bool tr) =>
    ExpansionTile(
      title: Text(UiLanguage.pair(context,
          turkish: tr,
          en: 'Comfort & stop signals',
          tr: 'Rahatlık ve durma işaretleri')),
      children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.safety.localized(context, turkish: tr),
                  style: ChoreiaType.of(context).body()),
              const SizedBox(height: 12),
              for (final source in course.sources.where((s) =>
                  ['health', 'pregnancy', 'pregnancySignals'].contains(s.id)))
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SelectableText(source.url,
                        style: ChoreiaType.of(context).body())),
            ]))
      ],
    );
String _eventLabel(BuildContext context, SalsaEvidence kind, bool tr) =>
    switch (kind) {
      SalsaEvidence.viewed =>
        UiLanguage.pair(context, turkish: tr, en: 'Opened', tr: 'Açıldı'),
      SalsaEvidence.practised => UiLanguage.pair(context,
          turkish: tr, en: 'Practice reported', tr: 'Pratik beyanı'),
      SalsaEvidence.selfReportedComplete => UiLanguage.pair(context,
          turkish: tr,
          en: 'Self-reported complete',
          tr: 'Öz beyanla tamamlandı'),
    };
String _optionLabel(
        BuildContext context, SalsaPracticeOption option, bool tr) =>
    switch (option) {
      SalsaPracticeOption.standard => UiLanguage.pair(context,
          turkish: tr, en: 'As written', tr: 'Dersin akışı'),
      SalsaPracticeOption.adapted =>
        UiLanguage.pair(context, turkish: tr, en: 'Adapted', tr: 'Uyarlanmış'),
      SalsaPracticeOption.rhythmOnly => UiLanguage.pair(context,
          turkish: tr, en: 'Rhythm / spoken only', tr: 'Yalnız ritim / sözlü'),
    };
