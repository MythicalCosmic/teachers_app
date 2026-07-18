import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_tab_bar.dart';
import 'groups/group_l10n.dart';
import 'groups/group_workspace_store.dart';

class CohortListScreen extends StatefulWidget {
  const CohortListScreen({super.key, this.store});

  final GroupWorkspaceStore? store;

  @override
  State<CohortListScreen> createState() => _CohortListScreenState();
}

class _CohortListScreenState extends State<CohortListScreen> {
  late final GroupWorkspaceStore _store;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? groupWorkspaceStore;
    _search = TextEditingController(text: _store.query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _showFilters() async {
    var sort = _store.sort;
    var threshold = _store.minimumAttendance.toDouble();
    var todayOnly = _store.todayOnly;
    final result = await showModalBottomSheet<_GroupFilterResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SfTheme.colorsOf(context).surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final c = SfTheme.colorsOf(context);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.gt('filter_title'),
                          style: SfType.ui(
                            size: 20,
                            weight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          sort = GroupSort.nextLesson;
                          threshold = 0;
                          todayOnly = false;
                        }),
                        child: Text(context.gt('clear')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.gt('order'),
                    style: SfType.eyebrow(color: c.muted),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<GroupSort>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: GroupSort.nextLesson,
                        label: Text(context.gt('next_lesson')),
                      ),
                      ButtonSegment(
                        value: GroupSort.attendance,
                        label: Text(context.gt('attendance')),
                      ),
                      ButtonSegment(
                        value: GroupSort.name,
                        label: Text(context.gt('name')),
                      ),
                    ],
                    selected: {sort},
                    onSelectionChanged: (value) =>
                        setSheetState(() => sort = value.first),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        context.gt('minimum_attendance'),
                        style: SfType.eyebrow(color: c.muted),
                      ),
                      const Spacer(),
                      Text(
                        threshold == 0
                            ? context.gt('unlimited')
                            : '${threshold.round()}%',
                        style: SfType.mono(
                          weight: FontWeight.w800,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: threshold,
                    min: 0,
                    max: 95,
                    divisions: 19,
                    label: threshold == 0
                        ? context.gt('unlimited')
                        : '${threshold.round()}%',
                    onChanged: (value) =>
                        setSheetState(() => threshold = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.gt('today_only'),
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    subtitle: Text(
                      context.gt('today_only_desc'),
                      style: SfType.ui(size: 12, color: c.muted),
                    ),
                    value: todayOnly,
                    onChanged: (value) =>
                        setSheetState(() => todayOnly = value),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () => Navigator.pop(
                      context,
                      _GroupFilterResult(
                        sort: sort,
                        minimumAttendance: threshold.round(),
                        todayOnly: todayOnly,
                      ),
                    ),
                    child: Text(context.gt('show_results')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result == null) return;
    _store.applyFilters(
      sort: result.sort,
      minimumAttendance: result.minimumAttendance,
      todayOnly: result.todayOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final groups = _store.visibleGroups;
        final activeFilters =
            (_store.minimumAttendance > 0 ? 1 : 0) +
            (_store.todayOnly ? 1 : 0) +
            (_store.sort != GroupSort.nextLesson ? 1 : 0);
        final activeCount = _store.groups
            .where((group) => !group.archived)
            .length;
        final studentCount = _store.groups
            .where((group) => !group.archived)
            .fold<int>(0, (sum, group) => sum + group.students.length);
        return SfScaffold(
          tab: SfTab.cohort,
          onTabChanged: (tab) => _handleLegacyTab(context, tab),
          top: Column(
            children: [
              SfLargeAppBar(
                title: context.gt('groups'),
                subtitle: context.gt(
                  'active_summary',
                  values: {'active': activeCount, 'students': studentCount},
                ),
                actions: [
                  SfPressable(
                    key: const ValueKey('group-filter-button'),
                    onPressed: _showFilters,
                    haptic: true,
                    semanticLabel: context.gt('filter_groups'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: activeFilters > 0
                                ? c.primarySoft
                                : c.surface2,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            SfIcons.filter,
                            size: 20,
                            color: activeFilters > 0 ? c.primary : c.ink2,
                          ),
                        ),
                        if (activeFilters > 0)
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.surface, width: 2),
                              ),
                              child: Text(
                                '$activeFilters',
                                style: SfType.mono(
                                  size: 8,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                color: c.surface,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Column(
                  children: [
                    TextField(
                      key: const ValueKey('group-search-field'),
                      controller: _search,
                      onChanged: _store.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: context.gt('search_group_student'),
                        prefixIcon: Icon(SfIcons.search, color: c.muted),
                        suffixIcon: _store.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: context.gt('clear_search'),
                                onPressed: () {
                                  _search.clear();
                                  _store.setQuery('');
                                },
                                icon: Icon(SfIcons.x, color: c.muted),
                              ),
                        filled: true,
                        fillColor: c.surface2,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: GroupCategory.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          final category = GroupCategory.values[index];
                          return _CategoryChip(
                            key: ValueKey('group-category-${category.name}'),
                            category: category,
                            selected: category == _store.category,
                            onPressed: () => _store.setCategory(category),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        groups.isEmpty
                            ? context.gt('no_results')
                            : context.gt(
                                'group_count',
                                values: {'count': groups.length},
                              ),
                        style: SfType.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: c.ink2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _sortLabel(context, _store.sort),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: SfType.ui(size: 11, color: c.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyGroups(
                    hasQuery: _store.query.isNotEmpty,
                    onReset: () {
                      _search.clear();
                      _store.setQuery('');
                      _store.setCategory(GroupCategory.all);
                      _store.clearFilters();
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  sliver: SliverList.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                      key: ValueKey(groups[index].id),
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 230 + index * 45),
                      curve: SfMotion.enter,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: _GroupCard(
                        group: groups[index],
                        attendance: _store.attendanceRate(groups[index].id),
                        onPressed: () => context.push(
                          '/cohort?id=${Uri.encodeQueryComponent(groups[index].id)}',
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                sliver: SliverToBoxAdapter(
                  child: _GroupsIntelligence(store: _store),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.attendance,
    required this.onPressed,
  });

  final TeacherGroup group;
  final double attendance;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final statusColor = attendance >= 93
        ? c.success
        : attendance >= 88
        ? c.warn
        : c.danger;
    return SfPressable(
      onPressed: onPressed,
      haptic: true,
      pressedScale: .975,
      semanticLabel: context.gt('open_group', values: {'group': group.name}),
      borderRadius: BorderRadius.circular(22),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface2 : c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: state.hovered ? c.borderStrong : c.border),
          boxShadow: [
            BoxShadow(
              color: c.ink.withValues(alpha: state.pressed ? .02 : .055),
              blurRadius: state.pressed ? 4 : 18,
              offset: Offset(0, state.pressed ? 2 : 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _categoryColor(context, group.category),
                        _categoryColor(
                          context,
                          group.category,
                        ).withValues(alpha: .72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: const SfStar(size: 28, color: Color(0xFFFFFCF5)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: SfType.ui(
                                size: 16,
                                weight: FontWeight.w800,
                                color: c.ink,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                          Icon(SfIcons.chevR, size: 20, color: c.muted),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${group.level} · ${context.gt('student_count', values: {'count': group.students.length})} · ${group.room}-${context.gt('room')}',
                        style: SfType.ui(size: 11.5, color: c.muted),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(SfIcons.clock, size: 14, color: c.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              group.archived
                                  ? context.gt('archived_group')
                                  : _lessonLabel(context, group.nextLesson),
                              style: SfType.ui(
                                size: 12,
                                weight: FontWeight.w700,
                                color: group.archived ? c.muted : c.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 122),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${attendance.round()}%',
                        style: SfType.mono(
                          size: 13,
                          weight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          context.gt('attendance_upper'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.eyebrow(color: c.muted, size: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final entry in group.trend.asMap().entries)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: FractionallySizedBox(
                                heightFactor: entry.value / 100,
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: SfMotion.standard,
                                  decoration: BoxDecoration(
                                    color: entry.key == group.trend.length - 1
                                        ? statusColor
                                        : c.surface3,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.gt('eight_lessons'),
                  style: SfType.ui(size: 10, color: c.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onPressed,
  });

  final GroupCategory category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      selected: selected,
      onPressed: onPressed,
      haptic: true,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.ink : c.borderStrong),
        ),
        child: Text(
          _categoryLabel(context, category),
          style: SfType.ui(
            size: 11.5,
            weight: FontWeight.w700,
            color: selected ? c.bg : c.muted,
          ),
        ),
      ),
    );
  }
}

class _GroupsIntelligence extends StatelessWidget {
  const _GroupsIntelligence({required this.store});

  final GroupWorkspaceStore store;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final active = store.groups.where((group) => !group.archived).toList();
    final atRisk = [...active]
      ..sort(
        (a, b) =>
            store.attendanceRate(a.id).compareTo(store.attendanceRate(b.id)),
      );
    if (active.isEmpty) return const SizedBox.shrink();
    final group = atRisk.first;
    return SfAiSurface(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SfAiBadge(label: context.gt('groups_analysis')),
              const Spacer(),
              Icon(Icons.auto_graph_rounded, size: 18, color: c.ai),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.gt('needs_attention', values: {'group': group.name}),
            style: SfType.ui(size: 15, weight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 5),
          Text(
            context.gt(
              'analysis_body',
              values: {'rate': store.attendanceRate(group.id).round()},
            ),
            style: SfType.ui(size: 12.5, color: c.ink2, height: 1.45),
          ),
          const SizedBox(height: 12),
          SfPressable(
            onPressed: () =>
                context.push('/cohort?id=${group.id}&tab=attendance'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.gt('detailed_analysis'),
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
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.hasQuery, required this.onReset});

  final bool hasQuery;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(SfIcons.search, color: c.muted, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery
                  ? context.gt('no_group_query')
                  : context.gt('no_filter_group'),
              style: SfType.ui(size: 17, weight: FontWeight.w800, color: c.ink),
            ),
            const SizedBox(height: 5),
            Text(
              context.gt('adjust_search'),
              textAlign: TextAlign.center,
              style: SfType.ui(size: 12.5, color: c.muted),
            ),
            const SizedBox(height: 15),
            TextButton(onPressed: onReset, child: Text(context.gt('show_all'))),
          ],
        ),
      ),
    );
  }
}

class _GroupFilterResult {
  const _GroupFilterResult({
    required this.sort,
    required this.minimumAttendance,
    required this.todayOnly,
  });

  final GroupSort sort;
  final int minimumAttendance;
  final bool todayOnly;
}

String _categoryLabel(BuildContext context, GroupCategory category) =>
    switch (category) {
      GroupCategory.all => context.gt('all'),
      GroupCategory.algebra => context.gt('algebra'),
      GroupCategory.geometry => context.gt('geometry'),
      GroupCategory.examPrep => context.gt('exam_prep'),
      GroupCategory.archived => context.gt('archive'),
    };

String _sortLabel(BuildContext context, GroupSort sort) => switch (sort) {
  GroupSort.nextLesson => context.gt('sort_next'),
  GroupSort.attendance => context.gt('sort_attendance'),
  GroupSort.name => context.gt('sort_name'),
};

Color _categoryColor(BuildContext context, GroupCategory category) {
  final c = SfTheme.colorsOf(context);
  return switch (category) {
    GroupCategory.algebra => c.primary,
    GroupCategory.geometry => c.accent,
    GroupCategory.examPrep => c.ink2,
    GroupCategory.archived || GroupCategory.all => c.muted,
  };
}

String _lessonLabel(BuildContext context, DateTime value) {
  final day = _sameDate(value, DateTime(2026, 7, 18))
      ? context.gt('today')
      : GroupL10n.weekday(context, value.weekday);
  return '$day · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

void _handleLegacyTab(BuildContext context, SfTab tab) {
  final route = switch (tab) {
    SfTab.home => '/home',
    SfTab.cohort => '/workspace',
    SfTab.tasks => '/work',
    SfTab.ai || SfTab.print => '/more',
  };
  context.go(route);
}
