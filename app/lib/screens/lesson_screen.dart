import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_tab_bar.dart';
import 'groups/group_workspace_store.dart';
import 'today/today_data.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    this.slotId,
    this.groupId,
    this.groupLessonId,
    this.store,
  });

  final String? slotId;
  final String? groupId;
  final String? groupLessonId;
  final GroupWorkspaceStore? store;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final GroupWorkspaceStore _store;
  late TodayLessonData _lesson;
  String? _groupId;
  String? _groupLessonId;
  bool _loadedRoute = false;
  late String _topic;
  late String _room;
  late String _timeRange;
  final List<_PlanStep> _plan = [
    _PlanStep('Salomlashish va tezkor davomat', 5, true),
    _PlanStep('Oldingi mavzuni vizual takrorlash', 7, false),
    _PlanStep('Kvadrat formula · yangi tushuncha', 13, false),
    _PlanStep('Guruhli mashq va peer-check', 15, false),
    _PlanStep('Exit ticket va uy vazifasi', 5, false),
  ];
  final List<_LessonMaterial> _materials = [
    const _LessonMaterial(
      id: 'quadratic-pdf',
      title: 'Kvadrat tenglamalar.pdf',
      detail: '2.1 MB · 8 bet',
      type: _MaterialType.pdf,
    ),
    const _LessonMaterial(
      id: 'practice-12',
      title: '12 ta adaptiv mashq',
      detail: 'Interaktiv · 3 daraja',
      type: _MaterialType.exercise,
    ),
    const _LessonMaterial(
      id: 'video-642',
      title: 'Video tushuntirish',
      detail: '6:42 · subtitr bilan',
      type: _MaterialType.video,
    ),
  ];
  final Set<String> _activeMaterials = {};
  final List<String> _notes = [];
  String? _appliedSuggestion;
  Timer? _timer;
  int _elapsedSeconds = 8 * 60 + 26;
  bool _timerRunning = false;
  bool _sessionEnded = false;
  bool _focusMode = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? groupWorkspaceStore;
    _applyLessonContext(
      slotId: widget.slotId,
      groupId: widget.groupId,
      groupLessonId: widget.groupLessonId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRoute) return;
    _loadedRoute = true;
    if (widget.slotId != null ||
        widget.groupId != null ||
        widget.groupLessonId != null) {
      return;
    }
    try {
      final query = GoRouterState.of(context).uri.queryParameters;
      _applyLessonContext(
        slotId: query['slot'],
        groupId: query['group'],
        groupLessonId: query['lesson'],
      );
    } on Object {
      // Direct widget tests do not have a GoRouter state.
    }
  }

  void _applyLessonContext({
    String? slotId,
    String? groupId,
    String? groupLessonId,
  }) {
    final group = _store.tryGroup(groupId);
    if (group != null) {
      final scheduled =
          _store.lesson(group.id, groupLessonId) ?? group.lessons.firstOrNull;
      if (scheduled != null) {
        _groupId = group.id;
        _groupLessonId = scheduled.id;
        _lesson = _lessonFromGroup(group, scheduled, _store.currentDateTime);
      } else {
        _lesson = lessonById(slotId);
        _groupId = group.id;
        _groupLessonId = null;
      }
    } else {
      _lesson = lessonById(slotId);
      final matchedGroup = _matchGroup(_store, _lesson);
      _groupId = matchedGroup?.id;
      _groupLessonId = null;
    }
    _topic = _lesson.topic;
    _room = _lesson.room;
    _timeRange = _lesson.timeRange;
  }

  void _openGroup() {
    final groupId = _groupId;
    if (groupId == null) {
      context.go('/workspace');
      return;
    }
    context.push(
      Uri(path: '/cohort', queryParameters: {'id': groupId}).toString(),
    );
  }

  void _openAttendance() {
    final groupId = _groupId;
    if (groupId == null) {
      context.push('/attendance');
      return;
    }
    context.push(
      Uri(
        path: '/attendance',
        queryParameters: {
          'cohort': groupId,
          'lesson': _groupLessonId ?? _lesson.id,
          'at': _lessonStart(_lesson).toIso8601String(),
          'title': _topic,
        },
      ).toString(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _planProgress => _plan.isEmpty
      ? 0
      : _plan.where((step) => step.done).length / _plan.length;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: SfNavBar(
        title: '${staffLessonSubject(context, _lesson)} · ${_lesson.cohort}',
        subtitle: _sessionEnded
            ? staffTr(context, 'Dars yakunlandi', 'Lesson completed')
            : _timerRunning
            ? staffTr(
                context,
                'Jonli dars · taymer ishlamoqda',
                'Live lesson · timer running',
              )
            : staffTr(
                context,
                '$_timeRange · $_room-xona',
                '$_timeRange · Room $_room',
              ),
        leading: IconButton(
          tooltip: staffTr(context, 'Jadvalga qaytish', 'Back to schedule'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: staffTr(context, 'Dars amallari', 'Lesson actions'),
            icon: const Icon(SfIcons.more),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'focus',
                child: Text(staffTr(context, 'Fokus rejimi', 'Focus mode')),
              ),
              PopupMenuItem(
                value: 'copy',
                child: Text(
                  staffTr(context, 'Rejani nusxalash', 'Duplicate plan'),
                ),
              ),
              PopupMenuItem(
                value: 'reschedule',
                child: Text(
                  staffTr(context, 'Vaqtni o‘zgartirish', 'Reschedule'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          _LessonHero(
            lesson: _lesson,
            topic: _topic,
            room: _room,
            timeRange: _timeRange,
            focusMode: _focusMode,
            onEdit: _editLesson,
            onOpenGroup: _openGroup,
          ),
          const SizedBox(height: 13),
          _LiveLessonController(
            elapsedSeconds: _elapsedSeconds,
            running: _timerRunning,
            ended: _sessionEnded,
            progress: _planProgress,
            onToggleTimer: _toggleTimer,
            onEnd: _endSession,
            onRestart: _restartSession,
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: staffTr(context, 'Dars rejasi', 'Lesson plan'),
            caption: staffTr(
              context,
              '${_plan.where((step) => step.done).length}/${_plan.length} bosqich · ${(_planProgress * 100).round()}%',
              '${_plan.where((step) => step.done).length}/${_plan.length} steps · ${(_planProgress * 100).round()}%',
            ),
            action: staffTr(context, 'Bosqich qo‘shish', 'Add step'),
            onAction: _addPlanStep,
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _planProgress,
                  minHeight: 5,
                  color: c.success,
                  backgroundColor: c.surface3,
                ),
                for (final entry in _plan.asMap().entries)
                  _PlanStepRow(
                    key: ValueKey('${entry.key}-${entry.value.title}'),
                    number: entry.key + 1,
                    step: entry.value,
                    last: entry.key == _plan.length - 1,
                    onToggle: () => setState(() {
                      entry.value.done = !entry.value.done;
                    }),
                    onDelete: () => setState(() => _plan.removeAt(entry.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: staffTr(context, 'Dars asboblari', 'Lesson tools'),
            caption: staffTr(
              context,
              'Bir tegishda ish jarayonini oching',
              'Open a workflow in one tap',
            ),
          ),
          const SizedBox(height: 8),
          _QuickTools(
            onAttendance: _openAttendance,
            onAssignment: () => context.push('/assignments/new'),
            onGroup: _openGroup,
            onNote: _openNoteComposer,
          ),
          if (_notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            _LessonNotes(notes: _notes),
          ],
          const SizedBox(height: 18),
          _SectionTitle(
            title: staffTr(context, 'Materiallar', 'Materials'),
            caption: staffTr(
              context,
              '${_materials.length} ta · ${_activeMaterials.length} tasi darsga biriktirilgan',
              '${_materials.length} total · ${_activeMaterials.length} attached to the lesson',
            ),
            action: staffTr(context, 'Qo‘shish', 'Add'),
            onAction: _addMaterial,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _materials.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final material = _materials[index];
                return _MaterialCard(
                  material: material,
                  active: _activeMaterials.contains(material.id),
                  onTap: () => _openMaterial(material),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _LessonAiCoach(
            appliedSuggestion: _appliedSuggestion,
            onApply: _applySuggestion,
          ),
        ],
      ),
    );
  }

  void _toggleTimer() {
    if (_sessionEnded) return;
    setState(() => _timerRunning = !_timerRunning);
    _timer?.cancel();
    if (_timerRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++);
      });
    }
  }

  void _endSession() {
    setState(() {
      _timerRunning = false;
      _sessionEnded = true;
    });
    _timer?.cancel();
  }

  void _restartSession() {
    setState(() {
      _elapsedSeconds = 0;
      _sessionEnded = false;
      _timerRunning = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'focus':
        setState(() => _focusMode = !_focusMode);
        break;
      case 'copy':
        setState(() {
          _plan.addAll(
            _plan
                .where((step) => step.done)
                .map(
                  (step) => _PlanStep(
                    '${_planLabel(context, step.title)} · ${staffTr(context, 'nusxa', 'copy')}',
                    step.minutes,
                    false,
                  ),
                )
                .toList(),
          );
        });
        break;
      case 'reschedule':
        _showRescheduleSheet();
        break;
    }
  }

  Future<void> _editLesson() async {
    final topic = TextEditingController(text: _topic);
    final room = TextEditingController(text: _room);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          staffTr(
            context,
            'Dars tafsilotlarini tahrirlash',
            'Edit lesson details',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topic,
              decoration: InputDecoration(
                labelText: staffTr(context, 'Mavzu', 'Topic'),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: room,
              decoration: InputDecoration(
                labelText: staffTr(context, 'Xona', 'Room'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(staffTr(context, 'Bekor', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(staffTr(context, 'Saqlash', 'Save')),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _topic = topic.text.trim().isEmpty ? _topic : topic.text.trim();
        _room = room.text.trim().isEmpty ? _room : room.text.trim();
      });
    }
    topic.dispose();
    room.dispose();
  }

  Future<void> _addPlanStep() async {
    final title = TextEditingController();
    var minutes = 10;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(staffTr(context, 'Yangi bosqich', 'New plan step')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('new-plan-title'),
                controller: title,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: staffTr(context, 'Bosqich nomi', 'Step title'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: minutes,
                decoration: InputDecoration(
                  labelText: staffTr(context, 'Davomiylik', 'Duration'),
                ),
                items: [
                  for (final value in const [5, 10, 15, 20])
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        staffTr(context, '$value daqiqa', '$value minutes'),
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setDialogState(() => minutes = value ?? minutes),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(staffTr(context, 'Bekor', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(staffTr(context, 'Qo‘shish', 'Add')),
            ),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty && mounted) {
      setState(() => _plan.add(_PlanStep(title.text.trim(), minutes, false)));
    }
    title.dispose();
  }

  Future<void> _addMaterial() async {
    final title = TextEditingController();
    var type = _MaterialType.pdf;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(staffTr(context, 'Material qo‘shish', 'Add material')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: staffTr(context, 'Material nomi', 'Material name'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_MaterialType>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: staffTr(context, 'Turi', 'Type'),
                ),
                items: [
                  DropdownMenuItem(
                    value: _MaterialType.pdf,
                    child: Text(staffTr(context, 'Hujjat', 'Document')),
                  ),
                  DropdownMenuItem(
                    value: _MaterialType.exercise,
                    child: Text(
                      staffTr(
                        context,
                        'Interaktiv mashq',
                        'Interactive exercise',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: _MaterialType.video,
                    child: Text(staffTr(context, 'Video', 'Video')),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => type = value ?? type),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(staffTr(context, 'Bekor', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(staffTr(context, 'Qo‘shish', 'Add')),
            ),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty && mounted) {
      final id = 'material-${DateTime.now().microsecondsSinceEpoch}';
      setState(() {
        _materials.add(
          _LessonMaterial(
            id: id,
            title: title.text.trim(),
            detail: type == _MaterialType.video
                ? staffTr(context, 'Yangi video', 'New video')
                : type == _MaterialType.exercise
                ? staffTr(context, 'Yangi interaktiv', 'New interactive')
                : staffTr(context, 'Yangi hujjat', 'New document'),
            type: type,
          ),
        );
      });
    }
    title.dispose();
  }

  void _openMaterial(_LessonMaterial material) {
    final c = SfTheme.colorsOf(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.surface,
      builder: (sheetContext) {
        final active = _activeMaterials.contains(material.id);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MaterialIcon(type: material.type, large: true),
                const SizedBox(height: 13),
                Text(
                  _materialTitle(context, material),
                  style: SfType.ui(
                    size: 19,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staffTr(
                    context,
                    '${material.detail} · dars uchun tekshirilgan',
                    '${_materialDetail(context, material)} · verified for this lesson',
                  ),
                  style: SfType.ui(size: 12, color: c.muted),
                ),
                const SizedBox(height: 14),
                Text(switch (material.type) {
                  _MaterialType.pdf => staffTr(
                    context,
                    '8 betlik konspekt, 4 ta ishlangan misol va mustaqil mashq varaqasi.',
                    'An 8-page guide with 4 worked examples and an independent practice sheet.',
                  ),
                  _MaterialType.exercise => staffTr(
                    context,
                    'O‘quvchi javobiga qarab qiyinligi o‘zgaradigan 12 ta topshiriq.',
                    '12 questions that adapt their difficulty to each student’s response.',
                  ),
                  _MaterialType.video => staffTr(
                    context,
                    'Kvadrat formula kelib chiqishini bosqichma-bosqich ko‘rsatadigan video.',
                    'A step-by-step video explaining where the quadratic formula comes from.',
                  ),
                }, style: SfType.ui(size: 13, color: c.ink2, height: 1.5)),
                const SizedBox(height: 17),
                SfButton(
                  block: true,
                  height: 50,
                  label: active
                      ? staffTr(
                          context,
                          'Darsdan olib tashlash',
                          'Remove from lesson',
                        )
                      : staffTr(context, 'Darsda ishlatish', 'Use in lesson'),
                  leading: active ? SfIcons.x : SfIcons.check,
                  kind: active ? SfButtonKind.ghost : SfButtonKind.primary,
                  onPressed: () {
                    setState(() {
                      if (!_activeMaterials.add(material.id)) {
                        _activeMaterials.remove(material.id);
                      }
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNoteComposer() async {
    final controller = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          2,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staffTr(context, 'Jonli dars qaydi', 'Live lesson note'),
              style: SfType.ui(size: 18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('lesson-note-field'),
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: staffTr(
                  context,
                  'Kuzatuv, savol yoki keyingi qadam…',
                  'Observation, question, or next step…',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SfButton(
              block: true,
              height: 48,
              label: staffTr(context, 'Qaydni saqlash', 'Save note'),
              onPressed: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty && mounted) {
      setState(() => _notes.insert(0, controller.text.trim()));
    }
    controller.dispose();
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      _appliedSuggestion = suggestion;
      if (!_plan.any((step) => step.title == suggestion)) {
        _plan.insert(1, _PlanStep(suggestion, 5, false));
      }
    });
  }

  void _showRescheduleSheet() {
    final c = SfTheme.colorsOf(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffTr(context, 'Dars vaqtini tanlang', 'Choose lesson time'),
                style: SfType.ui(
                  size: 18,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 12),
              for (final time in const [
                '09:00–09:45',
                '10:00–10:45',
                '11:30–12:15',
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(SfIcons.clock, color: c.primary),
                  title: Text(time),
                  trailing: const Icon(SfIcons.chevR),
                  onTap: () {
                    setState(() => _timeRange = time);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanStep {
  _PlanStep(this.title, this.minutes, this.done);
  final String title;
  final int minutes;
  bool done;
}

enum _MaterialType { pdf, exercise, video }

class _LessonMaterial {
  const _LessonMaterial({
    required this.id,
    required this.title,
    required this.detail,
    required this.type,
  });
  final String id;
  final String title;
  final String detail;
  final _MaterialType type;
}

class _LessonHero extends StatelessWidget {
  const _LessonHero({
    required this.lesson,
    required this.topic,
    required this.room,
    required this.timeRange,
    required this.focusMode,
    required this.onEdit,
    required this.onOpenGroup,
  });
  final TodayLessonData lesson;
  final String topic;
  final String room;
  final String timeRange;
  final bool focusMode;
  final VoidCallback onEdit;
  final VoidCallback onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, Color.lerp(c.surface, c.primarySoft, .58)!],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: focusMode ? c.accentSoft : c.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  focusMode
                      ? staffTr(context, 'FOKUS REJIMI', 'FOCUS MODE')
                      : staffTr(context, 'JONLI DARS', 'LIVE LESSON'),
                  style: SfType.eyebrow(
                    color: focusMode ? c.accentInk : c.primary,
                    size: 8.5,
                  ),
                ),
              ),
              const Spacer(),
              SfPressable(
                semanticLabel: staffTr(
                  context,
                  'Darsni tahrirlash',
                  'Edit lesson',
                ),
                onPressed: onEdit,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.edit, size: 18, color: c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            '${staffLessonSubject(context, lesson)} · ${staffLessonLevel(context, lesson)}',
            style: SfType.ui(
              size: 24,
              weight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            staffIsEnglish(context) && topic == lesson.topic
                ? staffLessonTopic(context, lesson)
                : topic,
            style: SfType.ui(size: 13, color: c.ink2, height: 1.4),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroDetail(icon: SfIcons.clock, label: timeRange),
              _HeroDetail(
                icon: Icons.meeting_room_outlined,
                label: staffTr(context, '$room-xona', 'Room $room'),
              ),
              _HeroDetail(
                icon: SfIcons.cohort,
                label: staffTr(
                  context,
                  '${lesson.cohort} · ${lesson.students} nafar',
                  '${lesson.cohort} · ${lesson.students} students',
                ),
                onTap: onOpenGroup,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroDetail extends StatelessWidget {
  const _HeroDetail({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: SfType.ui(size: 10.5, weight: FontWeight.w700, color: c.ink),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(SfIcons.chevR, size: 14, color: c.muted),
          ],
        ],
      ),
    );
    return onTap == null
        ? content
        : SfPressable(onPressed: onTap, child: content);
  }
}

class _LiveLessonController extends StatelessWidget {
  const _LiveLessonController({
    required this.elapsedSeconds,
    required this.running,
    required this.ended,
    required this.progress,
    required this.onToggleTimer,
    required this.onEnd,
    required this.onRestart,
  });
  final int elapsedSeconds;
  final bool running;
  final bool ended;
  final double progress;
  final VoidCallback onToggleTimer;
  final VoidCallback onEnd;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 300;
          final timer = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ended
                    ? staffTr(context, 'DARS YAKUNLANDI', 'LESSON COMPLETE')
                    : running
                    ? staffTr(context, 'VAQT KETMOQDA', 'TIMER RUNNING')
                    : staffTr(context, 'TAYMER PAUZADA', 'TIMER PAUSED'),
                style: SfType.eyebrow(color: c.accent, size: 8.5),
              ),
              const SizedBox(height: 3),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: SfType.mono(
                  size: 27,
                  weight: FontWeight.w800,
                  color: c.bg,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                staffTr(
                  context,
                  '${(progress * 100).round()}% reja bajarildi',
                  '${(progress * 100).round()}% of plan complete',
                ),
                style: SfType.ui(size: 10, color: c.bg.withValues(alpha: .68)),
              ),
            ],
          );
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SfPressable(
                semanticLabel: ended
                    ? staffTr(
                        context,
                        'Darsni qayta boshlash',
                        'Restart lesson',
                      )
                    : running
                    ? staffTr(context, 'Pauza', 'Pause')
                    : staffTr(context, 'Davom ettirish', 'Resume'),
                haptic: true,
                onPressed: ended ? onRestart : onToggleTimer,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.bg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    ended
                        ? Icons.replay_rounded
                        : running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: c.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!ended)
                SfButton(
                  kind: SfButtonKind.ghost,
                  label: staffTr(context, 'Yakunlash', 'Finish'),
                  fontSize: 11,
                  overrideFg: c.bg,
                  onPressed: onEnd,
                ),
            ],
          );
          return narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [timer, const SizedBox(height: 13), controls],
                )
              : Row(
                  children: [
                    Expanded(child: timer),
                    controls,
                  ],
                );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.caption,
    this.action,
    this.onAction,
  });
  final String title;
  final String caption;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SfType.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              Text(caption, style: SfType.ui(size: 10, color: c.muted)),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({
    super.key,
    required this.number,
    required this.step,
    required this.last,
    required this.onToggle,
    required this.onDelete,
  });
  final int number;
  final _PlanStep step;
  final bool last;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Dismissible(
      key: ValueKey('plan-$number-${step.title}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.danger,
        padding: const EdgeInsets.only(right: 18),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFFFCF5),
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: SfPressable(
        key: Key('lesson-plan-step-$number'),
        semanticLabel: staffTr(
          context,
          '${step.title}, ${step.done ? 'bajarilgan' : 'bajarilmagan'}',
          '${_planLabel(context, step.title)}, ${step.done ? 'complete' : 'incomplete'}',
        ),
        selected: step.done,
        haptic: true,
        onPressed: onToggle,
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: SfMotion.resolve(context, SfMotion.quick),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: step.done ? c.successSoft.withValues(alpha: .34) : null,
            border: last ? null : Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: SfMotion.resolve(context, SfMotion.quick),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: step.done ? c.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: step.done ? c.success : c.borderStrong,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: step.done
                    ? const Icon(
                        SfIcons.check,
                        size: 15,
                        color: Color(0xFFFFFCF5),
                      )
                    : Text(
                        '$number',
                        style: SfType.mono(size: 9, color: c.muted),
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _planLabel(context, step.title),
                  style:
                      SfType.ui(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: step.done ? c.muted : c.ink,
                        height: 1.35,
                      ).copyWith(
                        decoration: step.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
              ),
              Text(
                staffTr(context, '${step.minutes} daq', '${step.minutes} min'),
                style: SfType.mono(size: 9.5, color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTools extends StatelessWidget {
  const _QuickTools({
    required this.onAttendance,
    required this.onAssignment,
    required this.onGroup,
    required this.onNote,
  });
  final VoidCallback onAttendance;
  final VoidCallback onAssignment;
  final VoidCallback onGroup;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tools = [
      (
        staffTr(context, 'Davomat', 'Attendance'),
        Icons.how_to_reg_rounded,
        c.success,
        onAttendance,
      ),
      (
        staffTr(context, 'Vazifa', 'Assignment'),
        Icons.assignment_outlined,
        c.primary,
        onAssignment,
      ),
      (staffTr(context, 'Guruh', 'Group'), SfIcons.cohort, c.accent, onGroup),
      (
        staffTr(context, 'Jonli qayd', 'Live note'),
        Icons.edit_note_rounded,
        c.ink2,
        onNote,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 320 ? 2 : 4;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tool in tools)
              SizedBox(
                width: width,
                child: SfPressable(
                  semanticLabel: tool.$1,
                  onPressed: tool.$4,
                  haptic: true,
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: tool.$3.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Icon(tool.$2, size: 18, color: tool.$3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tool.$1,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LessonNotes extends StatelessWidget {
  const _LessonNotes({required this.notes});
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            staffTr(context, 'JONLI QAYDLAR', 'LIVE NOTES'),
            style: SfType.eyebrow(color: c.primary, size: 9),
          ),
          const SizedBox(height: 8),
          for (final note in notes) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: SfType.ui(size: 11.5, color: c.ink2, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.active,
    required this.onTap,
  });
  final _LessonMaterial material;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      width: 156,
      child: SfPressable(
        semanticLabel: staffTr(
          context,
          '${material.title} materialini ochish',
          'Open ${_materialTitle(context, material)}',
        ),
        selected: active,
        haptic: true,
        onPressed: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: SfMotion.resolve(context, SfMotion.quick),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: active ? c.primarySoft.withValues(alpha: .55) : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? c.primary : c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MaterialIcon(type: material.type),
                  const Spacer(),
                  if (active)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: c.success,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                _materialTitle(context, material),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SfType.ui(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: c.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _materialDetail(context, material),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SfType.ui(size: 9, color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialIcon extends StatelessWidget {
  const _MaterialIcon({required this.type, this.large = false});
  final _MaterialType type;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final color = switch (type) {
      _MaterialType.pdf => c.danger,
      _MaterialType.exercise => c.primary,
      _MaterialType.video => c.accent,
    };
    final icon = switch (type) {
      _MaterialType.pdf => SfIcons.pdf,
      _MaterialType.exercise => SfIcons.doc,
      _MaterialType.video => SfIcons.video,
    };
    return Container(
      width: large ? 52 : 36,
      height: large ? 52 : 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(large ? 16 : 11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: large ? 25 : 18, color: color),
    );
  }
}

class _LessonAiCoach extends StatelessWidget {
  const _LessonAiCoach({
    required this.appliedSuggestion,
    required this.onApply,
  });
  final String? appliedSuggestion;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    const suggestions = [
      '5 daqiqalik vizual takrorlash',
      'Oson misoldan boshlash',
      '4 kishilik peer-check',
    ];
    return SfAiSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SfAiBadge(
            label: staffTr(context, 'Dars yordamchisi', 'Lesson assistant'),
          ),
          const SizedBox(height: 12),
          Text(
            appliedSuggestion == null
                ? staffTr(
                    context,
                    '4 o‘quvchi o‘tgan safar kvadrat formula bosqichida qiynalgan.',
                    '4 students struggled with the quadratic-formula step last time.',
                  )
                : staffTr(
                    context,
                    '“$appliedSuggestion” dars rejasiga qo‘shildi.',
                    '“$appliedSuggestion” was added to the lesson plan.',
                  ),
            style: SfType.ui(
              size: 15,
              weight: FontWeight.w800,
              color: c.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            appliedSuggestion == null
                ? staffTr(
                    context,
                    'Quyidagi mikro-usullardan birini tanlang — u darhol dars rejasiga qo‘shiladi.',
                    'Choose a micro-strategy below and it will be added to the plan immediately.',
                  )
                : staffTr(
                    context,
                    'Rejadagi yangi bosqichni istalgan vaqtda belgilash yoki surib o‘chirish mumkin.',
                    'You can complete the new step or swipe it away at any time.',
                  ),
            style: SfType.ui(size: 11.5, color: c.ink2, height: 1.45),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final suggestion in suggestions)
                _SuggestionChip(
                  label: _suggestionLabel(context, suggestion),
                  selected:
                      appliedSuggestion ==
                      _suggestionLabel(context, suggestion),
                  onTap: () => onApply(_suggestionLabel(context, suggestion)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      semanticLabel: staffTr(
        context,
        '$label tavsiyasini qo‘llash',
        'Apply $label suggestion',
      ),
      selected: selected,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.ai : c.surface.withValues(alpha: .66),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.ai : c.aiBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? SfIcons.check : SfIcons.plus,
              size: 14,
              color: selected ? c.bg : c.ai,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: SfType.ui(
                size: 10,
                weight: FontWeight.w700,
                color: selected ? c.bg : c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TodayLessonData _lessonFromGroup(
  TeacherGroup group,
  GroupLesson lesson,
  DateTime now,
) {
  final endsAt = lesson.startsAt.add(const Duration(minutes: 45));
  final progress = now.isAfter(endsAt)
      ? LessonProgress.completed
      : now.isBefore(lesson.startsAt)
      ? LessonProgress.upcoming
      : LessonProgress.live;
  return TodayLessonData(
    id: lesson.id,
    date: DateUtils.dateOnly(lesson.startsAt),
    start: _hourMinute(lesson.startsAt),
    end: _hourMinute(endsAt),
    subject: group.subject,
    level: group.level,
    cohort: _cohortLabel(group),
    room: lesson.room,
    students: group.students.length,
    topic: lesson.topic,
    progress: progress,
    tone: switch (group.category) {
      GroupCategory.geometry => 1,
      GroupCategory.examPrep => 2,
      _ => 0,
    },
  );
}

TeacherGroup? _matchGroup(GroupWorkspaceStore store, TodayLessonData lesson) {
  final cohort = lesson.cohort.toLowerCase().replaceAll(
    RegExp('[^a-z0-9]'),
    '',
  );
  for (final group in store.groups) {
    final name = group.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    if (name.contains(cohort) &&
        group.subject.toLowerCase().contains(lesson.subject.toLowerCase())) {
      return group;
    }
  }
  return null;
}

DateTime _lessonStart(TodayLessonData lesson) {
  final parts = lesson.start.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(
    lesson.date.year,
    lesson.date.month,
    lesson.date.day,
    hour,
    minute,
  );
}

String _hourMinute(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _cohortLabel(TeacherGroup group) {
  final suffix = group.subject.toLowerCase();
  final name = group.name.trim();
  if (name.toLowerCase().endsWith(suffix)) {
    return name.substring(0, name.length - group.subject.length).trim();
  }
  return name;
}

String _planLabel(BuildContext context, String value) =>
    staffTr(context, value, switch (value) {
      'Salomlashish va tezkor davomat' => 'Welcome and quick attendance',
      'Oldingi mavzuni vizual takrorlash' =>
        'Visual review of the previous topic',
      'Kvadrat formula · yangi tushuncha' => 'Quadratic formula · new concept',
      'Guruhli mashq va peer-check' => 'Group exercise and peer check',
      'Exit ticket va uy vazifasi' => 'Exit ticket and homework',
      _ => value,
    });

String _materialTitle(BuildContext context, _LessonMaterial material) =>
    staffTr(context, material.title, switch (material.id) {
      'quadratic-pdf' => 'Quadratic equations.pdf',
      'practice-12' => '12 adaptive exercises',
      'video-642' => 'Video explanation',
      _ => material.title,
    });

String _materialDetail(BuildContext context, _LessonMaterial material) =>
    staffTr(context, material.detail, switch (material.id) {
      'quadratic-pdf' => '2.1 MB · 8 pages',
      'practice-12' => 'Interactive · 3 levels',
      'video-642' => '6:42 · with captions',
      _ => material.detail,
    });

String _suggestionLabel(BuildContext context, String value) =>
    staffTr(context, value, switch (value) {
      '5 daqiqalik vizual takrorlash' => '5-minute visual review',
      'Oson misoldan boshlash' => 'Start with an easy example',
      '4 kishilik peer-check' => '4-person peer check',
      _ => value,
    });
