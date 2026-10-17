import 'package:flutter/material.dart';

import '../live/live_environment.dart';
import '../ui_language.dart';
import 'media/lesson_media_slot.dart';
import 'salsa_progress.dart';

/// Self-reported study, using the existing owner-fenced atomic course store.
/// It cannot award course completion, sensor evidence or mastery.
class WrittenUnitPractice extends StatefulWidget {
  const WrittenUnitPractice(
      {required this.courseId,
      required this.version,
      required this.unitId,
      required this.bundle,
      required this.env,
      super.key});
  final String courseId, unitId;
  final int version;
  final AssetBundle bundle;
  final LiveEnvironment env;
  @override
  State<WrittenUnitPractice> createState() => _WrittenUnitPracticeState();
}

class _WrittenUnitPracticeState extends State<WrittenUnitPractice>
    with WidgetsBindingObserver {
  late final LiveEnvironment _ownerEnv;
  SalsaProgressStore? _store;
  int _epoch = 0;
  int? _count;
  bool _busy = false, _failed = false, _retired = false, _foreground = true;

  @override
  void initState() {
    super.initState();
    _ownerEnv = widget.env;
    WidgetsBinding.instance.addObserver(this);
    widget.env.accountUserId?.addListener(_retire);
    widget.env.ownerEpoch?.addListener(_retire);
    widget.env.passwordRecovery?.addListener(_onRecovery);
    if (widget.env.passwordRecovery?.value == true) _retired = true;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _load();
  }

  @override
  void didUpdateWidget(covariant WrittenUnitPractice old) {
    super.didUpdateWidget(old);
    if (old.courseId != widget.courseId ||
        old.unitId != widget.unitId ||
        old.version != widget.version ||
        old.env != widget.env) {
      // A replacement must start a fresh route; never rebind a pending write.
      _retired = true;
      _epoch++;
    }
  }

  void _onRecovery() {
    if (widget.env.passwordRecovery?.value == true) _retire();
  }

  void _retire() {
    _retired = true;
    _epoch++;
    if (mounted) setState(() {});
  }

  bool _current(int epoch) =>
      mounted && !_retired && _foreground && epoch == _epoch;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _epoch++;
    if (mounted) setState(() {});
    if (_foreground && !_retired) _load();
  }

  int _entries(SalsaProgress progress) => progress.events
      .where((e) =>
          e.courseId == widget.courseId &&
          e.version == widget.version &&
          e.lessonId == widget.unitId &&
          e.kind == SalsaEvidence.practised)
      .length;

  Future<void> _load() async {
    if (_retired || !_foreground) return;
    final epoch = ++_epoch;
    setState(() {
      _busy = true;
      _failed = false;
      _count = null;
    });
    try {
      final store = await SalsaProgressStore.open(
          accountUserId: widget.env.accountUserId?.value,
          supportDirectory: widget.env.historyDirectoryOverride,
          owners: widget.env.storeOwners,
          writtenStudy: true);
      if (!_current(epoch)) return;
      final progress = await store.read();
      if (!_current(epoch)) return;
      setState(() {
        _store = store;
        _count = _entries(progress);
        _busy = false;
      });
    } on Object {
      if (_current(epoch)) {
        setState(() {
          _failed = true;
          _busy = false;
        });
      }
    }
  }

  Future<void> _record() async {
    final store = _store;
    if (_busy || _failed || store == null || _retired || !_foreground) return;
    final epoch = _epoch;
    setState(() => _busy = true);
    try {
      final progress = await store.recordWrittenStudy(
          courseId: widget.courseId,
          version: widget.version,
          lessonId: widget.unitId);
      if (!_current(epoch)) return;
      setState(() {
        _count = _entries(progress);
        _busy = false;
      });
    } on Object {
      if (_current(epoch)) {
        setState(() {
          _failed = true;
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _epoch++;
    _ownerEnv.accountUserId?.removeListener(_retire);
    _ownerEnv.ownerEpoch?.removeListener(_retire);
    _ownerEnv.passwordRecovery?.removeListener(_onRecovery);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = UiLanguage.isTurkish(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LessonMediaSlot.empty(
          lessonId: widget.unitId,
          locale: tr ? 'tr' : 'en',
          bundle: widget.bundle,
          accountUserId: widget.env.accountUserId,
          passwordRecovery: widget.env.passwordRecovery,
          ownerEpoch: widget.env.ownerEpoch),
      if (_retired)
        Text(tr
            ? 'Hesap oturumu değişti. Derse yeniden gir.'
            : 'The account session changed. Reopen the lesson.')
      else if (_failed) ...[
        Text(tr
            ? 'Çalışma kaydı okunamadı veya kaydedilemedi. Mevcut kayıtlar korunuyor.'
            : 'The study record could not be read or saved. Existing records are preserved.'),
        TextButton(
            key: Key('written.retry.${widget.unitId}'),
            onPressed: _busy ? null : _load,
            child: Text(tr ? 'Kaydı yeniden oku' : 'Reload record')),
      ] else ...[
        Text(
            _count == null
                ? (tr ? 'Çalışma kaydı okunuyor…' : 'Reading study record…')
                : (tr
                    ? 'Kendi çalışma kaydın: $_count'
                    : 'Your study entries: $_count'),
            key: Key('written.count.${widget.unitId}')),
        OutlinedButton(
            key: Key('written.record.${widget.unitId}'),
            onPressed: _busy || _count == null || !_foreground ? null : _record,
            child: Text(tr
                ? 'Bu birimi çalıştığımı kaydet'
                : 'Record my study of this unit')),
      ],
      Text(tr
          ? 'Bu öz beyanlı kayıttır. Adım/faz, müziğe uyum veya ustalık doğrulanmaz.'
          : 'This is your own report. Step, phase, musical timing and mastery are not verified.'),
    ]);
  }
}
