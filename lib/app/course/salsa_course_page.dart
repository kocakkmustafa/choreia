import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_content/motion_content.dart';

import '../live/live_environment.dart';
import '../shell/choreia_page_route.dart';
import '../theme.dart';
import '../ui_language.dart';
import 'media/lesson_media_slot.dart';
import 'salsa_course.dart';
import 'salsa_course_repository.dart';
import 'salsa_progress.dart';
import 'salsa_session_preparation.dart';
import 'salsa_weekly_activity.dart';

/// The teaching route never requests a camera, microphone or music permission.
class SalsaCourseEntry extends StatelessWidget {
  const SalsaCourseEntry({this.env = const LiveEnvironment(), super.key});
  final LiveEnvironment env;
  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    return GlassPanel(
      radius: 18,
      tint: ChoreiaColors.amber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Salsa On1 · Solo', style: ChoreiaType.display(size: 25)),
        const SizedBox(height: 8),
        Text(
            tr
                ? '8 modül · 48 ders · Türkçe / English'
                : '8 modules · 48 lessons · Türkçe / English',
            style: ChoreiaType.body()),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('salsa.open'),
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => Navigator.of(context).push(ChoreiaPageRoute<void>(
              settings: const RouteSettings(name: 'course/salsa-on1'),
              builder: (_) => SalsaCoursePage(env: env))),
          label: Text(tr ? 'Kurs ve ilerlemem' : 'Course & my progress'),
        ),
      ]),
    );
  }
}

class SalsaCoursePage extends StatefulWidget {
  const SalsaCoursePage({
    this.env = const LiveEnvironment(),
    this.nowForWeeklyPractice,
    super.key,
  });
  final LiveEnvironment env;

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
  bool get tr => _turkish ?? UiLanguage.isTurkish(context);
  String t(String english, String turkish) => tr ? turkish : english;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.env.accountUserId?.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant SalsaCoursePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.env != widget.env) {
      oldWidget.env.accountUserId?.removeListener(_load);
      widget.env.accountUserId?.addListener(_load);
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.env.accountUserId?.removeListener(_load);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recompute the dated weekly snapshot after a night in the background.
      if (mounted) setState(() {});
    } else {
      _preparation.reset();
    }
  }

  Future<void> _load() async {
    final request = ++_loadId;
    final owner = widget.env.accountUserId?.value;
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
      final course = await SalsaCourseRepository.load(
        widget.env.bundle ?? rootBundle,
      );
      final store = await SalsaProgressStore.open(
          accountUserId: owner,
          supportDirectory: widget.env.historyDirectoryOverride);
      final progress = await store.read();
      if (!mounted ||
          request != _loadId ||
          owner != widget.env.accountUserId?.value) {
        return;
      }
      setState(() {
        _course = course;
        _store = store;
        _progress = progress;
      });
    } on ContentException catch (error) {
      if (mounted && request == _loadId) {
        setState(() {
          _failed = true;
          _integrityFailure = switch (error.error.code) {
            ContentErrorCode.timeout || ContentErrorCode.io => false,
            _ => true,
          };
        });
      }
    } catch (_) {
      if (mounted && request == _loadId) setState(() => _failed = true);
    }
  }

  Future<void> _open(SalsaLesson lesson) async {
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
            initialTurkish: tr)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      appBar: AppBar(title: const Text('Salsa On1'), actions: [
        TextButton(
            onPressed: () => setState(() => _turkish = !tr),
            child: Text(tr ? 'English' : 'Türkçe')),
      ]),
      body: ChoreiaBackdrop(
          child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                  child: _failed
                      ? _failure()
                      : course == null
                          ? const Center(child: CircularProgressIndicator())
                          : _overview(course)))),
    );
  }

  Widget _failure() => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                _integrityFailure
                    ? t('The Salsa course in this app did not pass its content check. Your learning record was not changed. Update the app or contact support. Do not delete the app: progress saved on this device could be lost.',
                        'Bu uygulamadaki Salsa kursu içerik denetiminden geçmedi. Öğrenme kaydın değiştirilmedi. Uygulamayı güncelle veya desteğe ulaş. Uygulamayı silme: bu cihazdaki ilerleme kaybolabilir.')
                    : t('The course or progress could not be read. Existing records were not replaced. Retry to reopen them.',
                        'Kurs veya ilerleme okunamadı. Mevcut kayıtların üzerine yazılmadı. Yeniden açmak için tekrar dene.'),
                key: const Key('salsa.loadError'),
                style: ChoreiaType.body()),
            if (!_integrityFailure)
              TextButton(
                  onPressed: _load, child: Text(t('Retry', 'Tekrar dene'))),
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
          Text(course.title.inLanguage(tr),
              style: ChoreiaType.display(size: 34)),
          const SizedBox(height: 10),
          Text(course.subtitle.inLanguage(tr), style: ChoreiaType.body()),
          const SizedBox(height: 18),
          GlassPanel(
              tint: ChoreiaColors.amber,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Your learning record', 'Öğrenme kaydın'),
                        style: ChoreiaType.display(size: 25)),
                    const SizedBox(height: 10),
                    Text(
                        t('${completed.length} / 48 self-reported complete',
                            '${completed.length} / 48 öz beyanla tamamlandı'),
                        key: const Key('salsa.completedCount'),
                        style: ChoreiaType.body(size: 16)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: completed.length / course.lessons.length,
                        color: ChoreiaColors.amber,
                        semanticsLabel: t('Self-reported completion',
                            'Öz beyanla tamamlanma'),
                        semanticsValue:
                            '${(completed.length * 100 / course.lessons.length).round()}%'),
                    const SizedBox(height: 12),
                    Text(
                        t('${opened.length} opened · ${practised.length} practised lessons',
                            '${opened.length} açılan · ${practised.length} çalışılan ders'),
                        style: ChoreiaType.body()),
                    Text(
                        t('Saved on this device for ${_store!.owner == 'guest' ? 'guest' : 'the current account'}. No camera mastery score.',
                            'Bu cihazda ${_store!.owner == 'guest' ? 'misafir' : 'geçerli hesap'} için kayıtlı. Kamera ustalık puanı yok.'),
                        style: ChoreiaType.body()),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                        onPressed: () => _open(next),
                        key: const Key('salsa.continue'),
                        child: Text(t(
                            'Continue: ${next.order}. ${next.title.en}',
                            'Devam: ${next.order}. ${next.title.tr}'))),
                  ])),
          const SizedBox(height: 16),
          GlassPanel(
              key: const Key('salsa.weeklyPractice'),
              tint: ChoreiaColors.rose,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Practice by week', 'Haftalık pratik'),
                        style: ChoreiaType.display(size: 22)),
                    const SizedBox(height: 6),
                    Text(
                        t(
                            'Four calendar weeks as of ${_shortDate(weeklyPractice.asOf)}. '
                                'Saved course actions include rhythm-only practice; '
                                'they do not prove movement or camera skill.',
                            '${_shortDate(weeklyPractice.asOf)} itibarıyla dört takvim haftası. '
                                'Kayıtlı kurs denemelerine yalnız ritim çalışması da dahildir; '
                                'bunlar hareket veya kamera becerisini kanıtlamaz.'),
                        style: ChoreiaType.body()),
                    const SizedBox(height: 12),
                    for (var i = 0; i < weeklyPractice.weeks.length; i++)
                      _weeklyPracticeRow(weeklyPractice.weeks[i], i),
                    if (weeklyPractice.futureDatedAttempts > 0)
                      Text(
                          t(
                              'Future-dated saved attempts: ${weeklyPractice.futureDatedAttempts}. '
                                  'They remain in course history and the overall lesson count, '
                                  'but are omitted from these weeks. Check the device clock.',
                              'Gelecek tarihli kayıtlı deneme: ${weeklyPractice.futureDatedAttempts}. '
                                  'Kurs geçmişinde ve genel ders sayısında durur; '
                                  'bu haftalara eklenmez. Cihaz saatini kontrol et.'),
                          key: const Key('salsa.weeklyPractice.futureDateNote'),
                          style: ChoreiaType.body(size: 12)),
                  ])),
          const SizedBox(height: 16),
          Text(course.outcome.inLanguage(tr), style: ChoreiaType.body()),
          const SizedBox(height: 8),
          Text(
              t('Lessons are open to revisit. Prerequisites suggest a learning order. Completion records the option you used.',
                  'Dersleri istediğin zaman yeniden açabilirsin. Önkoşullar önerilen sırayı gösterir. Tamamlanma, kullandığın seçenekle kaydedilir.'),
              style: ChoreiaType.body()),
          const SizedBox(height: 18),
          for (final module in course.modules) ...[
            Text(
                '${module.order.toString().padLeft(2, '0')} · ${module.title.inLanguage(tr)}',
                style: ChoreiaType.display(size: 26)),
            const SizedBox(height: 8),
            for (final lesson
                in course.lessons.where((l) => l.moduleId == module.id))
              Card(
                  color: ChoreiaColors.oxblood.withValues(alpha: .7),
                  child: ListTile(
                    key: Key('salsa.lesson.${lesson.id}'),
                    leading: Text(lesson.order.toString().padLeft(2, '0'),
                        style: ChoreiaType.label(size: 12)),
                    title: Text(lesson.title.inLanguage(tr)),
                    subtitle: Text(completed.contains(lesson.id)
                        ? t('Self-reported complete · revisit',
                            'Öz beyanla tamamlandı · tekrar aç')
                        : practised.contains(lesson.id)
                            ? t('Practised', 'Çalışıldı')
                            : opened.contains(lesson.id)
                                ? t('Opened', 'Açıldı')
                                : t('Suggested ${lesson.minutes} min · adjust freely',
                                    'Öneri ${lesson.minutes} dk · kendine göre ayarla')),
                    trailing: Icon(
                        completed.contains(lesson.id)
                            ? Icons.check_circle_outline
                            : Icons.chevron_right,
                        color: ChoreiaColors.amber),
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
                      title: Text(
                          course.lesson(event.lessonId).title.inLanguage(tr)),
                      subtitle: Text(
                          '${_eventLabel(event.kind, tr)} · ${_optionLabel(event.option, tr)}\n'
                          '${event.at.toLocal().toString().substring(0, 16)}')),
                if (historical > 0)
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(t(
                          '$historical records from other content versions are retained and excluded from this version’s totals.',
                          'Başka içerik sürümlerinden $historical kayıt korunuyor; bu sürümün toplamına eklenmiyor.'))),
              ]),
          ExpansionTile(
              title: Text(t('About this course', 'Bu kurs hakkında')),
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(course.selectionBasis.inLanguage(tr),
                        style: ChoreiaType.body()))
              ]),
          _safetyPanel(course, tr),
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
          Text(dates, style: ChoreiaType.label(size: 11)),
          const SizedBox(height: 3),
          Text(
              t(
                  'Saved attempts: ${week.practiceAttempts} · '
                      'Lessons with attempts: ${week.distinctLessons}',
                  'Kayıtlı deneme: ${week.practiceAttempts} · '
                      'Denenen ders: ${week.distinctLessons}'),
              style: ChoreiaType.body(size: 13)),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class SalsaLessonPage extends StatefulWidget {
  const SalsaLessonPage(
      {required this.course,
      required this.lesson,
      required this.store,
      required this.env,
      required this.initialTurkish,
      this.preparationSession,
      super.key});
  final SalsaCourse course;
  final SalsaLesson lesson;
  final SalsaProgressStore store;
  final LiveEnvironment env;
  final bool initialTurkish;
  final SalsaPreparationSession? preparationSession;
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
  SalsaPracticeOption _option = SalsaPracticeOption.standard;
  Timer? _timer;
  int _count = 1;
  double _pace = 80;
  String t(String english, String turkish) => tr ? turkish : english;
  bool get _needsPreparation =>
      _lesson.requiresMovementPreparation &&
      _option != SalsaPracticeOption.rhythmOnly &&
      !_preparation.acknowledged;
  bool get _physicalOption =>
      _lesson.requiresMovementPreparation &&
      _option != SalsaPracticeOption.rhythmOnly;
  bool get _ownerMatches =>
      SalsaProgressStore.ownerFor(widget.env.accountUserId?.value) ==
      widget.store.owner;
  @override
  void initState() {
    super.initState();
    _preparation = widget.preparationSession ?? SalsaPreparationSession();
    _lesson = widget.lesson;
    tr = widget.initialTurkish;
    _checks = List.filled(_lesson.selfCheck.en.length, false);
    WidgetsBinding.instance.addObserver(this);
    widget.env.accountUserId?.addListener(_onAccount);
    _record(SalsaEvidence.viewed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.env.accountUserId?.removeListener(_onAccount);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _revokePreparation();
    }
  }

  void _onAccount() {
    _revokePreparation();
    if (mounted) setState(() => _accountChanged = true);
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
    if (_accountChanged || _needsPreparation) return;
    _count = 1;
    _timer =
        Timer.periodic(Duration(milliseconds: (60000 / _pace).round()), (_) {
      if (_needsPreparation) {
        _pause();
        return;
      }
      if (mounted) setState(() => _count = _count % 8 + 1);
    });
    setState(() {});
  }

  Future<void> _record(SalsaEvidence evidence) async {
    if (_busy || _accountChanged || !_ownerMatches) return;
    if (evidence != SalsaEvidence.viewed && _needsPreparation) return;
    final sessionEpoch = _sessionEpoch;
    setState(() {
      _busy = true;
      _saveFailed = false;
    });
    try {
      await widget.store
          .record(widget.course, _lesson, evidence, option: _option);
      if (!mounted || _accountChanged || !_ownerMatches) return;
      setState(() {
        if (evidence == SalsaEvidence.practised &&
            sessionEpoch == _sessionEpoch &&
            (!_physicalOption || _preparation.acknowledged)) {
          _practiceSaved = true;
        }
        if (evidence == SalsaEvidence.selfReportedComplete) _completed = true;
      });
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    _pause();
    setState(() {
      _lesson = widget.course.lessons[_lesson.order];
      _checks = List.filled(_lesson.selfCheck.en.length, false);
      _practiceSaved = false;
      _completed = false;
      _saveFailed = false;
      _option = SalsaPracticeOption.standard;
      _count = 1;
    });
    _record(SalsaEvidence.viewed);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    return Scaffold(
      appBar: AppBar(title: Text('${lesson.order} / 48'), actions: [
        TextButton(
            onPressed: () => setState(() => tr = !tr),
            child: Text(tr ? 'English' : 'Türkçe')),
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
                            t('The account changed. Return to the course to use the current account’s progress.',
                                'Hesap değişti. Geçerli hesabın ilerlemesi için kursa geri dön.'),
                            key: const Key('salsa.accountChanged'),
                            style: ChoreiaType.body()),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(t('Back to course', 'Kursa dön'))),
                      ])),
                    Text(lesson.title.inLanguage(tr),
                        style: ChoreiaType.display(size: 34)),
                    LessonMediaSlot.empty(
                      key: ValueKey('salsa.mediaSlot.${lesson.id}'),
                      bundle: widget.env.bundle ?? rootBundle,
                      lessonId: lesson.id,
                      locale: tr ? 'tr' : 'en',
                      accountUserId: widget.env.accountUserId,
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
                    Text(lesson.goal.inLanguage(tr),
                        style: ChoreiaType.body(size: 16)),
                    const SizedBox(height: 8),
                    Text(
                        t('Suggested ${lesson.minutes} minutes, including pauses. Take the time you need.',
                            'Molalar dahil öneri ${lesson.minutes} dakika. Süreyi kendine göre ayarla.'),
                        style: ChoreiaType.body()),
                    if (lesson.prerequisites.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                          t('Recommended first: ${widget.course.lesson(lesson.prerequisites.first).title.en}',
                              'Önce önerilen: ${widget.course.lesson(lesson.prerequisites.first).title.tr}'),
                          style: ChoreiaType.body()),
                    ],
                    _sectionTitle(t('Learn', 'Öğren')),
                    for (final (index, instruction)
                        in lesson.teaching.inLanguage(tr).indexed)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text('${index + 1}. $instruction',
                              style: ChoreiaType.body(size: 15))),
                    _sectionTitle(t('Try it', 'Uygula')),
                    Text(
                        t('Keep movement comfortable. Stop for pain, dizziness or feeling unwell.',
                            'Hareketi rahat sınırında tut. Ağrı, baş dönmesi veya kötü hissetmede dur.'),
                        style: ChoreiaType.body(color: ChoreiaColors.amber)),
                    const SizedBox(height: 10),
                    if (_needsPreparation)
                      Text(
                          t('Prepare above before moving, or choose rhythm / spoken only below.',
                              'Harekete geçmeden önce yukarıdaki hazırlığı yap veya aşağıdan yalnız ritim / sözlü seçeneğini seç.'),
                          key: const Key('salsa.preparation.required'),
                          style: ChoreiaType.body())
                    else ...[
                      if (_option == SalsaPracticeOption.rhythmOnly)
                        Text(
                            t('Read this lesson’s sequence and describe it in your own words. If useful, speak 1-2-3, 5-6-7 with the silent guide. Keep this attempt to reading and voice; leave footwork, weight transfer, turns and crossings untried. Record only this spoken option.',
                                'Bu dersin sırasını oku ve kendi sözlerinle anlat. İstersen sessiz rehberle 1-2-3, 5-6-7 sayımını sesli söyle. Bu denemeyi okuma ve sesle sınırla; ayak çalışması, ağırlık aktarımı, dönüş ve çapraz adımlar denenmedi olarak kalsın. Yalnız bu sözlü seçeneği kaydet.'),
                            key: const Key('salsa.spokenPractice'),
                            style: ChoreiaType.body(size: 15))
                      else
                        Text(lesson.practice.inLanguage(tr),
                            style: ChoreiaType.body(size: 15)),
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
                    Text(lesson.adaptation.inLanguage(tr),
                        style: ChoreiaType.body()),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final option in SalsaPracticeOption.values)
                        ChoiceChip(
                            key: Key('salsa.option.${option.name}'),
                            label: Text(_optionLabel(option, tr)),
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
                    Text(
                        t('Tick each statement only if it matches your chosen practice option. These are your observations.',
                            'Her ifadeyi yalnız seçtiğin pratik seçeneğinde sana uyuyorsa işaretle. Bunlar senin gözlemlerin.'),
                        style: ChoreiaType.body()),
                    for (final (index, statement)
                        in lesson.selfCheck.inLanguage(tr).indexed)
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
                    Text(lesson.repeat.inLanguage(tr),
                        style: ChoreiaType.body()),
                    const SizedBox(height: 16),
                    if (_saveFailed)
                      Text(
                          t('Could not save. Your earlier records were not replaced. Return to the course and retry.',
                              'Kaydedilemedi. Önceki kayıtların üzerine yazılmadı. Kursa dönüp tekrar dene.'),
                          key: const Key('salsa.saveError'),
                          style: ChoreiaType.body(color: ChoreiaColors.amber)),
                    FilledButton(
                        onPressed: _busy ||
                                _accountChanged ||
                                _needsPreparation ||
                                !_practiceSaved ||
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
                          t('Saved as self-reported complete · ${_optionLabel(_option, false)}. This is not a camera skill assessment.',
                              'Öz beyanla tamamlandı · ${_optionLabel(_option, true)} olarak kaydedildi. Bu bir kamera beceri değerlendirmesi değildir.'),
                          key: const Key('salsa.saved'),
                          style: ChoreiaType.body()),
                      if (lesson.order < widget.course.lessons.length)
                        TextButton(
                            key: const Key('salsa.next'),
                            onPressed: _busy || _accountChanged ? null : _next,
                            child: Text(t('Next lesson', 'Sonraki ders'))),
                    ],
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(t('Back to course', 'Kursa dön'))),
                    _safetyPanel(widget.course, tr),
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
                                          style: ChoreiaType.body()),
                                      SelectableText(source.url,
                                          style: ChoreiaType.body()),
                                      if (source.supports case final support?)
                                        Text(
                                            '${t('Supports only:', 'Yalnız destekler:')} ${support.inLanguage(tr)}',
                                            key: Key(
                                                'salsa.sourceScope.${source.id}'),
                                            style: ChoreiaType.body()),
                                      if (source.doesNotSupport
                                          case final limit?)
                                        Text(
                                            '${t('Does not establish:', 'Kanıtlamaz:')} ${limit.inLanguage(tr)}',
                                            key: Key(
                                                'salsa.sourceLimit.${source.id}'),
                                            style: ChoreiaType.body()),
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
    _pause();
    setState(() {
      _option = option;
      _practiceSaved = false;
      _completed = false;
      _checks = List.filled(_checks.length, false);
    });
  }

  Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: ChoreiaType.display(size: 25)));
  Widget _counter() => GlassPanel(
      tint: ChoreiaColors.amber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('Silent count guide', 'Sessiz sayım rehberi'),
            style: ChoreiaType.display(size: 24)),
        const SizedBox(height: 8),
        Text(widget.course.musicCopy.inLanguage(tr), style: ChoreiaType.body()),
        const SizedBox(height: 14),
        Wrap(spacing: 6, runSpacing: 8, children: [
          for (var number = 1; number <= 8; number++)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _count == number
                            ? ChoreiaColors.amber
                            : ChoreiaColors.text(.55))),
                child: Text('$number',
                    style: ChoreiaType.label(
                        size: 16,
                        color: _count == number
                            ? ChoreiaColors.amber
                            : ChoreiaColors.bright))),
        ]),
        const SizedBox(height: 8),
        Text(
            t('${_pace.round()} visual pulses / minute',
                '${_pace.round()} görsel nabız / dakika'),
            style: ChoreiaType.body()),
        Slider(
            value: _pace,
            min: 40,
            max: 160,
            divisions: 24,
            label: '${_pace.round()}',
            semanticFormatterCallback: (value) => t(
                '${value.round()} visual pulses per minute',
                'Dakikada ${value.round()} görsel nabız'),
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

Widget _safetyPanel(SalsaCourse course, bool tr) => ExpansionTile(
      title:
          Text(tr ? 'Rahatlık ve durma işaretleri' : 'Comfort & stop signals'),
      children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.safety.inLanguage(tr), style: ChoreiaType.body()),
              const SizedBox(height: 12),
              for (final source in course.sources.where((s) =>
                  ['health', 'pregnancy', 'pregnancySignals'].contains(s.id)))
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child:
                        SelectableText(source.url, style: ChoreiaType.body())),
            ]))
      ],
    );
String _eventLabel(SalsaEvidence kind, bool tr) => switch (kind) {
      SalsaEvidence.viewed => tr ? 'Açıldı' : 'Opened',
      SalsaEvidence.practised => tr ? 'Pratik beyanı' : 'Practice reported',
      SalsaEvidence.selfReportedComplete =>
        tr ? 'Öz beyanla tamamlandı' : 'Self-reported complete',
    };
String _optionLabel(SalsaPracticeOption option, bool tr) => switch (option) {
      SalsaPracticeOption.standard => tr ? 'Dersin akışı' : 'As written',
      SalsaPracticeOption.adapted => tr ? 'Uyarlanmış' : 'Adapted',
      SalsaPracticeOption.rhythmOnly =>
        tr ? 'Yalnız ritim / sözlü' : 'Rhythm / spoken only',
    };
