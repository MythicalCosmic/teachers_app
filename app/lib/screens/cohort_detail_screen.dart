import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import 'groups/group_l10n.dart';
import 'groups/group_workspace_store.dart';

class CohortDetailScreen extends StatefulWidget {
  const CohortDetailScreen({
    super.key,
    this.store,
    this.groupId,
    this.initialTab,
  });

  final GroupWorkspaceStore? store;
  final String? groupId;
  final int? initialTab;

  @override
  State<CohortDetailScreen> createState() => _CohortDetailScreenState();
}

class _CohortDetailScreenState extends State<CohortDetailScreen> {
  late final GroupWorkspaceStore _store;
  final TextEditingController _studentSearch = TextEditingController();
  int _tab = 0;
  bool _routeApplied = false;
  bool _sortByRisk = false;
  AttendanceWindow _window = AttendanceWindow.thirtyDays;
  DateTimeRange? _customRange;
  String _lessonFilter = 'Hammasi';

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? groupWorkspaceStore;
    _tab = widget.initialTab?.clamp(0, 3).toInt() ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeApplied) return;
    _routeApplied = true;
    if (widget.initialTab != null) return;
    try {
      final query = GoRouterState.of(context).uri.queryParameters;
      if (query['tab'] == 'attendance') _tab = 2;
      if (query['tab'] == 'schedule') _tab = 3;
      if (query['tab'] == 'students') _tab = 1;
    } on Object {
      // Direct widget hosts do not have a GoRouter state.
    }
  }

  @override
  void dispose() {
    _studentSearch.dispose();
    super.dispose();
  }

  String _resolveGroupId() {
    if (widget.groupId != null) return widget.groupId!;
    return GoRouterState.of(context).uri.queryParameters['id'] ??
        _store.groups.first.id;
  }

  DateTimeRange _activeRange(String groupId) {
    final end = _store.currentDateTime;
    if (_window == AttendanceWindow.custom && _customRange != null) {
      return _customRange!;
    }
    return DateTimeRange(
      start: GroupWorkspaceStore.windowStart(_window, now: end),
      end: end,
    );
  }

  Future<void> _pickRange(String groupId) async {
    final current = _activeRange(groupId);
    final now = _store.currentDateTime;
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: current,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: context.gt('date_range_help'),
      saveText: context.gt('apply'),
    );
    if (selected == null) return;
    setState(() {
      _window = AttendanceWindow.custom;
      _customRange = selected;
    });
  }

  Future<void> _showMore(TeacherGroup group) async {
    final action = await showModalBottomSheet<_GroupAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: SfTheme.colorsOf(context).surface,
      builder: (context) {
        final c = SfTheme.colorsOf(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.insights_outlined, color: c.primary),
                  title: Text(context.gt('attendance_report')),
                  subtitle: Text(context.gt('attendance_report_sub')),
                  onTap: () => Navigator.pop(context, _GroupAction.attendance),
                ),
                ListTile(
                  leading: Icon(SfIcons.cal, color: c.primary),
                  title: Text(context.gt('schedule_report')),
                  subtitle: Text(context.gt('schedule_report_sub')),
                  onTap: () => Navigator.pop(context, _GroupAction.schedule),
                ),
                ListTile(
                  leading: Icon(Icons.summarize_outlined, color: c.primary),
                  title: Text(context.gt('group_passport')),
                  subtitle: Text(context.gt('group_passport_sub')),
                  onTap: () => Navigator.pop(context, _GroupAction.report),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _GroupAction.attendance:
        setState(() => _tab = 2);
      case _GroupAction.schedule:
        setState(() => _tab = 3);
      case _GroupAction.report:
        await _showPassport(group);
    }
  }

  Future<void> _showPassport(TeacherGroup group) => showDialog<void>(
    context: context,
    builder: (context) {
      final c = SfTheme.colorsOf(context);
      final rate = _store.attendanceRate(group.id);
      return AlertDialog(
        title: Text(
          context.gt('passport_title', values: {'group': group.name}),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportLine(label: context.gt('subject'), value: group.subject),
            _ReportLine(label: context.gt('level'), value: group.level),
            _ReportLine(label: context.gt('teacher'), value: group.teacher),
            _ReportLine(
              label: context.gt('students'),
              value: context.gt(
                'student_count_short',
                values: {'count': group.students.length},
              ),
            ),
            _ReportLine(
              label: context.gt('attendance'),
              value: '${rate.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                rate >= 93
                    ? context.gt('stable_group')
                    : context.gt('individual_plan'),
                style: SfType.ui(size: 12.5, color: c.primaryInk, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.gt('done')),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final groupId = _resolveGroupId();
    final group = _store.group(groupId);
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) => SfScaffold(
        top: SfNavBar(
          title: group.name,
          subtitle:
              '${context.gt('student_count', values: {'count': group.students.length})} · ${group.room}-${context.gt('room')}',
          leading: SfPressable(
            onPressed: context.pop,
            semanticLabel: context.gt('back_groups'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(SfIcons.arrowL, size: 18),
                const SizedBox(width: 4),
                Text(context.gt('groups')),
              ],
            ),
          ),
          actions: [
            SfPressable(
              onPressed: () => _showMore(group),
              semanticLabel: context.gt('group_actions'),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(SfIcons.more),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            _HeroCard(
              group: group,
              attendance: _store.attendanceRate(group.id),
              onAttendance: () =>
                  context.push('/attendance?cohort=${group.id}'),
              onMessage: () => context.push('/messages/new?group=${group.id}'),
            ),
            const SizedBox(height: 16),
            _DetailTabs(
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: SfMotion.resolve(context, SfMotion.standard),
              switchInCurve: SfMotion.enter,
              switchOutCurve: SfMotion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(.025, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: switch (_tab) {
                0 => _OverviewPanel(
                  key: const ValueKey('overview'),
                  group: group,
                  store: _store,
                  onOpenAttendance: () => setState(() => _tab = 2),
                  onOpenLesson: () {
                    final lesson = group.lessons.firstOrNull;
                    context.push(_lessonLocation(group.id, lesson?.id));
                  },
                ),
                1 => _StudentsPanel(
                  key: const ValueKey('students'),
                  group: group,
                  store: _store,
                  controller: _studentSearch,
                  sortByRisk: _sortByRisk,
                  onSortChanged: (value) => setState(() => _sortByRisk = value),
                ),
                2 => _AttendanceHistoryPanel(
                  key: const ValueKey('attendance'),
                  group: group,
                  store: _store,
                  window: _window,
                  range: _activeRange(group.id),
                  lessonFilter: _lessonFilter,
                  onWindowChanged: (value) => setState(() {
                    _window = value;
                    if (value != AttendanceWindow.custom) _customRange = null;
                  }),
                  onCustomRange: () => _pickRange(group.id),
                  onLessonChanged: (value) =>
                      setState(() => _lessonFilter = value),
                  onTakeAttendance: () =>
                      context.push('/attendance?cohort=${group.id}'),
                ),
                _ => _SchedulePanel(
                  key: const ValueKey('schedule'),
                  group: group,
                  onOpenLesson: (lesson) =>
                      context.push(_lessonLocation(group.id, lesson.id)),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.group,
    required this.attendance,
    required this.onAttendance,
    required this.onMessage,
  });

  final TeacherGroup group;
  final double attendance;
  final VoidCallback onAttendance;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -36,
            child: Opacity(
              opacity: .07,
              child: SfStar(size: 150, color: c.primary),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  SfPill(
                    tone: SfPillTone.primary,
                    label: '${group.subject} · ${group.level}',
                  ),
                  const SfPill(label: '2025–2026'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.name,
                style: SfType.ui(
                  size: 25,
                  weight: FontWeight.w800,
                  color: c.ink,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${group.teacher} · ${group.room}-${context.gt('room')}',
                style: SfType.ui(size: 12.5, color: c.muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _HeroMetric(
                    value: '${attendance.round()}%',
                    label: context.gt('attendance'),
                    color: attendance >= 92 ? c.success : c.warn,
                  ),
                  _HeroMetric(
                    value: '${group.students.length}',
                    label: context.gt('student'),
                    color: c.primary,
                  ),
                  _HeroMetric(
                    value:
                        '${group.students.fold<int>(0, (sum, item) => sum + item.upCards)}',
                    label: context.gt('achievement'),
                    color: c.accentInk,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 330;
                  final attendanceButton = SfButton(
                    block: true,
                    label: context.gt('take_attendance'),
                    leading: SfIcons.check,
                    haptic: true,
                    onPressed: onAttendance,
                  );
                  final messageButton = SfButton(
                    block: true,
                    kind: SfButtonKind.soft,
                    label: context.gt('message_group'),
                    leading: SfIcons.chat,
                    onPressed: onMessage,
                  );
                  if (narrow) {
                    return Column(
                      children: [
                        attendanceButton,
                        const SizedBox(height: 8),
                        messageButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: attendanceButton),
                      const SizedBox(width: 9),
                      Expanded(child: messageButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: SfType.mono(
                size: 18,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: SfType.eyebrow(size: 8.5, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final labels = [
      context.gt('analysis'),
      context.gt('students'),
      context.gt('attendance'),
      context.gt('lessons'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          for (final entry in labels.asMap().entries)
            Expanded(
              child: SfPressable(
                key: ValueKey('group-tab-${entry.key}'),
                onPressed: () => onChanged(entry.key),
                selected: selected == entry.key,
                haptic: true,
                child: AnimatedContainer(
                  duration: SfMotion.resolve(context, SfMotion.quick),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == entry.key
                        ? c.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected == entry.key
                        ? [
                            BoxShadow(
                              color: c.ink.withValues(alpha: .07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    entry.value,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: SfType.ui(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: selected == entry.key ? c.ink : c.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    super.key,
    required this.group,
    required this.store,
    required this.onOpenAttendance,
    required this.onOpenLesson,
  });

  final TeacherGroup group;
  final GroupWorkspaceStore store;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final history = store.history(group.id);
    final risk = [...group.students]
      ..sort(
        (a, b) => store
            .studentAttendanceRate(group.id, a.id)
            .compareTo(store.studentAttendanceRate(group.id, b.id)),
      );
    final best = [...group.students]
      ..sort(
        (a, b) => store
            .studentAttendanceRate(group.id, b.id)
            .compareTo(store.studentAttendanceRate(group.id, a.id)),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SfAiSurface(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SfAiBadge(label: context.gt('class_intelligence')),
              const SizedBox(height: 7),
              Text(
                context.gt(
                  'analysis_scope',
                  values: {
                    'lessons': history.length,
                    'students': group.students.length,
                  },
                ),
                style: SfType.ui(size: 10.5, color: c.muted),
              ),
              const SizedBox(height: 12),
              Text(
                context.gt('stable_attention'),
                style: SfType.ui(
                  size: 17,
                  weight: FontWeight.w800,
                  color: c.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.gt(
                  'risk_summary',
                  values: {'risk': risk.first.name, 'best': best.first.name},
                ),
                style: SfType.ui(size: 12.5, color: c.ink2, height: 1.5),
              ),
              const SizedBox(height: 13),
              SfPressable(
                onPressed: onOpenAttendance,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.gt('view_evidence'),
                      style: SfType.ui(
                        size: 12,
                        weight: FontWeight.w800,
                        color: c.ai,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(SfIcons.arrowR, size: 15, color: c.ai),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SfSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.gt('eight_lesson_rhythm'),
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${group.trend.last.round()}%',
                    style: SfType.mono(
                      size: 15,
                      weight: FontWeight.w800,
                      color: c.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 88,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final entry in group.trend.asMap().entries)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: entry.value / 100,
                                    ),
                                    duration: Duration(
                                      milliseconds: 350 + entry.key * 55,
                                    ),
                                    curve: SfMotion.enter,
                                    builder: (context, value, _) =>
                                        FractionallySizedBox(
                                          heightFactor: value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  entry.key ==
                                                      group.trend.length - 1
                                                  ? c.primary
                                                  : c.primarySoft,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(6),
                                                  ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${entry.key + 1}',
                                style: SfType.mono(size: 8, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _NextLessonCard(group: group, onPressed: onOpenLesson),
      ],
    );
  }
}

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.group, required this.onPressed});

  final TeacherGroup group;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final lesson = group.lessons.firstOrNull;
    if (lesson == null) return const SizedBox.shrink();
    return SfPressable(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.bg.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(SfIcons.book, color: c.bg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.gt(
                      'next_lesson_upper',
                      values: {'time': _time(lesson.startsAt)},
                    ),
                    style: SfType.eyebrow(
                      color: c.bg.withValues(alpha: .6),
                      size: 9,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.topic,
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w800,
                      color: c.bg,
                    ),
                  ),
                  Text(
                    context.gt(
                      'open_lesson_plan',
                      values: {'room': lesson.room},
                    ),
                    style: SfType.ui(
                      size: 10.5,
                      color: c.bg.withValues(alpha: .66),
                    ),
                  ),
                ],
              ),
            ),
            Icon(SfIcons.chevR, color: c.bg),
          ],
        ),
      ),
    );
  }
}

class _StudentsPanel extends StatefulWidget {
  const _StudentsPanel({
    super.key,
    required this.group,
    required this.store,
    required this.controller,
    required this.sortByRisk,
    required this.onSortChanged,
  });

  final TeacherGroup group;
  final GroupWorkspaceStore store;
  final TextEditingController controller;
  final bool sortByRisk;
  final ValueChanged<bool> onSortChanged;

  @override
  State<_StudentsPanel> createState() => _StudentsPanelState();
}

class _StudentsPanelState extends State<_StudentsPanel> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final students = widget.group.students
        .where(
          (student) => student.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    if (widget.sortByRisk) {
      students.sort(
        (a, b) => widget.store
            .studentAttendanceRate(widget.group.id, a.id)
            .compareTo(
              widget.store.studentAttendanceRate(widget.group.id, b.id),
            ),
      );
    } else {
      students.sort((a, b) => a.name.compareTo(b.name));
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('student-search-field'),
                controller: widget.controller,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: context.gt('search_student'),
                  prefixIcon: Icon(SfIcons.search, color: c.muted),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<bool>(
              tooltip: context.gt('sort'),
              initialValue: widget.sortByRisk,
              onSelected: widget.onSortChanged,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: false,
                  child: Text(context.gt('sort_surname')),
                ),
                PopupMenuItem(
                  value: true,
                  child: Text(context.gt('sort_risk')),
                ),
              ],
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.sortByRisk ? c.primarySoft : c.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: c.border),
                ),
                alignment: Alignment.center,
                child: Icon(SfIcons.filter, color: c.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SfSurfaceCard(
          child: AnimatedSize(
            duration: SfMotion.resolve(context, SfMotion.standard),
            curve: SfMotion.enter,
            child: Column(
              children: [
                for (final entry in students.asMap().entries)
                  _StudentRow(
                    key: ValueKey(entry.value.id),
                    student: entry.value,
                    attendance: widget.store.studentAttendanceRate(
                      widget.group.id,
                      entry.value.id,
                    ),
                    showDivider: entry.key < students.length - 1,
                    onPressed: () => context.push(
                      Uri(
                        path: '/student',
                        queryParameters: {
                          'id': entry.value.id,
                          'group': widget.group.id,
                        },
                      ).toString(),
                    ),
                  ),
                if (students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: Text(
                      context.gt('no_student'),
                      style: SfType.ui(size: 13, color: c.muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    super.key,
    required this.student,
    required this.attendance,
    required this.showDivider,
    required this.onPressed,
  });

  final GroupStudent student;
  final double attendance;
  final bool showDivider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = attendance >= 92
        ? c.success
        : attendance >= 85
        ? c.warn
        : c.danger;
    return SfPressable(
      onPressed: onPressed,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: c.border))
              : null,
        ),
        child: Row(
          children: [
            SfAvatar(name: student.name, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: SfType.ui(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '↑${student.upCards}  ↓${student.downCards} · ${student.id.substring(student.id.length - 5)}',
                    style: SfType.mono(size: 9.5, color: c.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${attendance.round()}%',
                style: SfType.mono(
                  size: 11,
                  weight: FontWeight.w800,
                  color: tone,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(SfIcons.chevR, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHistoryPanel extends StatelessWidget {
  const _AttendanceHistoryPanel({
    super.key,
    required this.group,
    required this.store,
    required this.window,
    required this.range,
    required this.lessonFilter,
    required this.onWindowChanged,
    required this.onCustomRange,
    required this.onLessonChanged,
    required this.onTakeAttendance,
  });

  final TeacherGroup group;
  final GroupWorkspaceStore store;
  final AttendanceWindow window;
  final DateTimeRange range;
  final String lessonFilter;
  final ValueChanged<AttendanceWindow> onWindowChanged;
  final VoidCallback onCustomRange;
  final ValueChanged<String> onLessonChanged;
  final VoidCallback onTakeAttendance;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final history = store.history(
      group.id,
      start: range.start,
      end: range.end,
      lesson: lessonFilter,
    );
    final allLessons =
        store.history(group.id).map((row) => row.lessonTitle).toSet().toList()
          ..sort();
    final totalStatuses = history.fold<int>(
      0,
      (sum, row) => sum + row.statuses.length,
    );
    final absent = history.fold<int>(
      0,
      (sum, row) => sum + row.count(AttendanceStatus.absent),
    );
    final late = history.fold<int>(
      0,
      (sum, row) => sum + row.count(AttendanceStatus.late),
    );
    final rate = totalStatuses == 0
        ? 0
        : (totalStatuses - absent) / totalStatuses * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _WindowChip(
                label: context.gt('seven_days'),
                selected: window == AttendanceWindow.sevenDays,
                onPressed: () => onWindowChanged(AttendanceWindow.sevenDays),
              ),
              _WindowChip(
                label: context.gt('last_month'),
                selected: window == AttendanceWindow.thirtyDays,
                onPressed: () => onWindowChanged(AttendanceWindow.thirtyDays),
              ),
              _WindowChip(
                label: context.gt('semester'),
                selected: window == AttendanceWindow.term,
                onPressed: () => onWindowChanged(AttendanceWindow.term),
              ),
              _WindowChip(
                label: window == AttendanceWindow.custom
                    ? '${_shortDate(range.start)}–${_shortDate(range.end)}'
                    : context.gt('choose_date'),
                selected: window == AttendanceWindow.custom,
                icon: SfIcons.cal,
                onPressed: onCustomRange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final dropdown = DropdownButtonFormField<String>(
              key: const ValueKey('attendance-lesson-filter'),
              initialValue: lessonFilter,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.gt('lesson_type'),
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: c.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
              ),
              selectedItemBuilder: (context) => [
                Text(
                  context.gt('all_lessons'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                for (final lesson in allLessons)
                  Text(lesson, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              items: [
                DropdownMenuItem(
                  value: 'Hammasi',
                  child: Text(context.gt('all_lessons')),
                ),
                for (final lesson in allLessons)
                  DropdownMenuItem(value: lesson, child: Text(lesson)),
              ],
              onChanged: (value) => onLessonChanged(value ?? 'Hammasi'),
            );
            final action = SfButton(
              block: constraints.maxWidth < 360,
              label: context.gt('mark'),
              leading: SfIcons.check,
              haptic: true,
              onPressed: onTakeAttendance,
            );
            if (constraints.maxWidth < 360) {
              return Column(
                children: [dropdown, const SizedBox(height: 8), action],
              );
            }
            return Row(
              children: [
                Expanded(child: dropdown),
                const SizedBox(width: 9),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            _HistoryMetric(
              label: context.gt('attendance_upper'),
              value: '${rate.round()}%',
              color: c.success,
            ),
            _HistoryMetric(
              label: context.gt('lesson_upper'),
              value: '${history.length}',
              color: c.primary,
            ),
            _HistoryMetric(
              label: context.gt('late_upper'),
              value: '$late',
              color: c.warn,
            ),
            _HistoryMetric(
              label: context.gt('absent_upper'),
              value: '$absent',
              color: c.danger,
            ),
          ],
        ),
        const SizedBox(height: 13),
        if (history.isEmpty)
          SfSurfaceCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy_outlined, size: 34, color: c.muted),
                  const SizedBox(height: 9),
                  Text(
                    context.gt('no_lessons_range'),
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.gt('change_date_filter'),
                    style: SfType.ui(size: 11.5, color: c.muted),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _AttendanceMatrix(group: group, history: history, store: store),
          const SizedBox(height: 14),
          _AttendanceInsight(group: group, history: history, store: store),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                context.gt('lesson_history'),
                style: SfType.ui(
                  size: 15,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${_shortDate(range.start)} — ${_shortDate(range.end)}',
                style: SfType.mono(size: 9.5, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in history) ...[
            _HistoryLessonRow(group: group, record: row),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _AttendanceMatrix extends StatelessWidget {
  const _AttendanceMatrix({
    required this.group,
    required this.history,
    required this.store,
  });

  final TeacherGroup group;
  final List<GroupAttendanceRecord> history;
  final GroupWorkspaceStore store;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final columns = history.take(7).toList().reversed.toList();
    return SfSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.gt('by_student'),
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                ),
                Text(
                  context.gt(
                    'last_n_lessons',
                    values: {'count': columns.length},
                  ),
                  style: SfType.ui(size: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 46,
              dataRowMinHeight: 47,
              dataRowMaxHeight: 47,
              horizontalMargin: 14,
              columnSpacing: 18,
              dividerThickness: .7,
              columns: [
                DataColumn(label: Text(context.gt('student_upper'))),
                const DataColumn(numeric: true, label: Text('%')),
                for (final row in columns)
                  DataColumn(
                    label: Text(
                      _dayMonth(context, row.lessonAt),
                      style: SfType.mono(size: 9.5, color: c.muted),
                    ),
                  ),
              ],
              rows: [
                for (final student in group.students)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SfType.ui(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${store.studentAttendanceRate(group.id, student.id, start: history.last.lessonAt, end: history.first.lessonAt).round()}',
                          style: SfType.mono(
                            size: 10.5,
                            weight: FontWeight.w800,
                            color: c.ink2,
                          ),
                        ),
                      ),
                      for (final row in columns)
                        DataCell(_StatusDot(status: row.statuses[student.id])),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 13),
            child: Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                _Legend(
                  status: AttendanceStatus.present,
                  label: context.gt('present'),
                ),
                _Legend(
                  status: AttendanceStatus.late,
                  label: context.gt('late'),
                ),
                _Legend(
                  status: AttendanceStatus.absent,
                  label: context.gt('absent'),
                ),
                _Legend(
                  status: AttendanceStatus.excused,
                  label: context.gt('excused'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceInsight extends StatelessWidget {
  const _AttendanceInsight({
    required this.group,
    required this.history,
    required this.store,
  });

  final TeacherGroup group;
  final List<GroupAttendanceRecord> history;
  final GroupWorkspaceStore store;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final students = [...group.students]
      ..sort(
        (a, b) => store
            .studentAttendanceRate(
              group.id,
              a.id,
              start: history.last.lessonAt,
              end: history.first.lessonAt,
            )
            .compareTo(
              store.studentAttendanceRate(
                group.id,
                b.id,
                start: history.last.lessonAt,
                end: history.first.lessonAt,
              ),
            ),
      );
    final first = students.first;
    final rate = store.studentAttendanceRate(
      group.id,
      first.id,
      start: history.last.lessonAt,
      end: history.first.lessonAt,
    );
    return SfAiSurface(
      borderRadius: BorderRadius.circular(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SfAiBadge(label: context.gt('attendance_coach')),
          const SizedBox(height: 10),
          Text(
            '${first.name}: ${rate.round()}%',
            style: SfType.ui(size: 16, weight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 5),
          Text(
            context.gt('lowest_summary'),
            style: SfType.ui(size: 12.5, color: c.ink2, height: 1.45),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _EvidencePill(
                label: context.gt(
                  'lessons_reviewed',
                  values: {'count': history.length},
                ),
              ),
              _EvidencePill(
                label: context.gt(
                  'absence_count',
                  values: {
                    'count': history
                        .where(
                          (row) =>
                              row.statuses[first.id] == AttendanceStatus.absent,
                        )
                        .length,
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryLessonRow extends StatelessWidget {
  const _HistoryLessonRow({required this.group, required this.record});

  final TeacherGroup group;
  final GroupAttendanceRecord record;

  Future<void> _showDetails(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: SfTheme.colorsOf(context).surface,
    builder: (context) {
      final c = SfTheme.colorsOf(context);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.lessonTitle} · ${_dayMonth(context, record.lessonAt)}',
                style: SfType.ui(
                  size: 18,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.gt(
                  'record_summary',
                  values: {
                    'students': record.statuses.length,
                    'rate': record.attendanceRate.round(),
                  },
                ),
                style: SfType.ui(size: 12, color: c.muted),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.students.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: c.border, height: 1),
                  itemBuilder: (context, index) {
                    final student = group.students[index];
                    final status = record.statuses[student.id];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SfAvatar(name: student.name, size: 34),
                      title: Text(student.name),
                      subtitle: record.notes[student.id] == null
                          ? null
                          : Text(record.notes[student.id]!),
                      trailing: _StatusBadge(status: status),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: () => _showDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${record.lessonAt.day}',
                    style: SfType.mono(
                      size: 15,
                      weight: FontWeight.w800,
                      color: c.primary,
                    ),
                  ),
                  Text(
                    GroupL10n.month(context, record.lessonAt.month),
                    style: SfType.eyebrow(size: 7.5, color: c.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.lessonTitle,
                    style: SfType.ui(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.gt(
                      'record_counts',
                      values: {
                        'present': record.count(AttendanceStatus.present),
                        'absent': record.count(AttendanceStatus.absent),
                        'late': record.count(AttendanceStatus.late),
                      },
                    ),
                    style: SfType.ui(size: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
            Text(
              '${record.attendanceRate.round()}%',
              style: SfType.mono(
                size: 12,
                weight: FontWeight.w800,
                color: record.attendanceRate >= 92 ? c.success : c.warn,
              ),
            ),
            const SizedBox(width: 3),
            Icon(SfIcons.chevR, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    super.key,
    required this.group,
    required this.onOpenLesson,
  });

  final TeacherGroup group;
  final ValueChanged<GroupLesson> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.gt('upcoming_lessons'),
                    style: SfType.ui(
                      size: 16,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    context.gt('topic_time_room'),
                    style: SfType.ui(size: 11.5, color: c.muted),
                  ),
                ],
              ),
            ),
            Icon(SfIcons.cal, color: c.primary),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in group.lessons.asMap().entries) ...[
          SfPressable(
            onPressed: () => onOpenLesson(entry.value),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: entry.key == 0 ? c.primary : c.surface2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${entry.value.startsAt.day}',
                          style: SfType.mono(
                            size: 16,
                            weight: FontWeight.w800,
                            color: entry.key == 0 ? Colors.white : c.ink,
                          ),
                        ),
                        Text(
                          GroupL10n.month(context, entry.value.startsAt.month),
                          style: SfType.eyebrow(
                            size: 7.5,
                            color: entry.key == 0 ? Colors.white70 : c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.topic,
                          style: SfType.ui(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_time(entry.value.startsAt)} · ${entry.value.room}-${context.gt('room')} · ${entry.value.title}',
                          style: SfType.ui(size: 10.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(SfIcons.chevR, size: 19, color: c.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: SfPressable(
        onPressed: onPressed,
        selected: selected,
        child: AnimatedContainer(
          duration: SfMotion.resolve(context, SfMotion.quick),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c.ink : c.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c.ink : c.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? c.bg : c.muted),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: SfType.ui(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: selected ? c.bg : c.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: SfType.mono(
                size: 14,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, style: SfType.eyebrow(size: 7.5, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final AttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: status == AttendanceStatus.present
          ? Icon(SfIcons.check, size: 12, color: color)
          : Text(
              _statusInitial(context, status),
              style: SfType.mono(
                size: 8,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.status, required this.label});

  final AttendanceStatus status;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _StatusDot(status: status),
      const SizedBox(width: 4),
      Text(
        label,
        style: SfType.ui(size: 9.5, color: SfTheme.colorsOf(context).muted),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(context, status),
        style: SfType.ui(size: 10, weight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _EvidencePill extends StatelessWidget {
  const _EvidencePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.aiBorder),
      ),
      child: Text(
        label,
        style: SfType.ui(size: 9.5, weight: FontWeight.w700, color: c.ai),
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: SfType.ui(size: 12, color: c.muted)),
          const Spacer(),
          Text(
            value,
            style: SfType.ui(size: 12, weight: FontWeight.w700, color: c.ink),
          ),
        ],
      ),
    );
  }
}

enum _GroupAction { attendance, schedule, report }

String _lessonLocation(String groupId, String? lessonId) => Uri(
  path: '/lesson',
  queryParameters: {'group': groupId, 'lesson': ?lessonId},
).toString();

Color _statusColor(BuildContext context, AttendanceStatus? status) {
  final c = SfTheme.colorsOf(context);
  return switch (status) {
    AttendanceStatus.present => c.success,
    AttendanceStatus.absent => c.danger,
    AttendanceStatus.late => c.warn,
    AttendanceStatus.excused => c.muted,
    null => c.muted2,
  };
}

String _statusInitial(BuildContext context, AttendanceStatus? status) {
  final code = Localizations.localeOf(context).languageCode;
  return switch ((code, status)) {
    (_, null) => '—',
    ('en', AttendanceStatus.absent) => 'A',
    ('en', AttendanceStatus.late) => 'L',
    ('en', AttendanceStatus.excused) => 'E',
    ('en', AttendanceStatus.present) => 'P',
    ('ru', AttendanceStatus.absent) => 'Н',
    ('ru', AttendanceStatus.late) => 'О',
    ('ru', AttendanceStatus.excused) => 'У',
    ('ru', AttendanceStatus.present) => 'П',
    (_, AttendanceStatus.absent) => 'Y',
    (_, AttendanceStatus.late) => 'K',
    (_, AttendanceStatus.excused) => 'S',
    (_, AttendanceStatus.present) => 'B',
  };
}

String _statusLabel(BuildContext context, AttendanceStatus? status) =>
    switch (status) {
      AttendanceStatus.present => context.gt('present'),
      AttendanceStatus.absent => context.gt('absent'),
      AttendanceStatus.late => context.gt('late'),
      AttendanceStatus.excused => context.gt('excused'),
      null => '—',
    };

String _shortDate(DateTime value) =>
    '${value.day}.${value.month.toString().padLeft(2, '0')}';
String _dayMonth(BuildContext context, DateTime value) =>
    '${value.day} ${GroupL10n.month(context, value.month)}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
