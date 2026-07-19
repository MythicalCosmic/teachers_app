import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../l10n/sf_l10n.dart';
import '../../router.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_tab_bar.dart';

enum _TaskFilter { all, myDay, high, favorites, completed }

enum _TaskView { list, board, calendar }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();
  _TaskFilter _filter = _TaskFilter.all;
  _TaskView _view = _TaskView.list;
  DateTime _selectedDate = _day(DateTime.now());

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tasks = _visibleTasks(
      app.tasks,
      app.session?.userId,
      includeCompletedForAll: _view == _TaskView.board,
    );
    final active = app.tasks
        .where((task) => task.status != TaskStatus.done)
        .length;
    final done = app.tasks.length - active;
    final overdue = app.tasks
        .where(
          (task) =>
              task.status != TaskStatus.done &&
              task.dueAt.isBefore(DateTime.now()),
        )
        .length;
    final progress = app.tasks.isEmpty ? 0.0 : done / app.tasks.length;
    final canCreate =
        app.can(StaffCapability.createTasks) &&
        (!app.isProduction || app.tasksAvailable);

    return SfScaffold(
      tab: SfTab.tasks,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: SfLargeAppBar(
        title: context.tr('tasks'),
        subtitle: _copy(
          context,
          uz: '$active ta faol · $done ta yakunlangan',
          ru: '$active активных · $done завершено',
          en: '$active active · $done completed',
        ),
        actions: [
          if (canCreate)
            IconButton.filledTonal(
              tooltip: context.tr('new_task'),
              onPressed: () => context.push('/tasks/new'),
              icon: const Icon(SfIcons.plus),
            ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: app.refreshTasks,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _CommandCenter(
                      progress: progress,
                      active: active,
                      overdue: overdue,
                      dueThisWeek: app.tasks.where(_isThisWeek).length,
                    ),
                    const SizedBox(height: 12),
                    _SearchAndView(
                      controller: _search,
                      view: _view,
                      onSearch: (_) => setState(() {}),
                      onViewChanged: (view) => setState(() => _view = view),
                    ),
                    const SizedBox(height: 10),
                    _Filters(
                      value: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (app.isProduction && app.tasksLoading && app.tasks.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 360,
                  child: SfLoadingState(
                    label: _copy(
                      context,
                      uz: 'Vazifalar yangilanmoqda…',
                      ru: 'Задачи обновляются…',
                      en: 'Refreshing tasks…',
                    ),
                    motionEnabled: !app.settings.reducedMotion,
                  ),
                ),
              )
            else if (app.isProduction && !app.tasksAvailable)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 360,
                  child: SfEmptyState(
                    icon: SfIcons.shield,
                    title: _copy(
                      context,
                      uz: 'Vazifalar bu rolga ochilmagan',
                      ru: 'Задачи недоступны для этой роли',
                      en: 'Tasks are unavailable for this role',
                    ),
                    message: app.tasksError,
                    actionLabel: _copy(
                      context,
                      uz: 'Qayta tekshirish',
                      ru: 'Проверить снова',
                      en: 'Check again',
                    ),
                    onAction: () => unawaited(app.refreshTasks()),
                  ),
                ),
              )
            else if (app.isProduction &&
                app.tasksError != null &&
                app.tasks.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 360,
                  child: SfErrorState(
                    title: _copy(
                      context,
                      uz: 'Vazifalarni yuklab bo‘lmadi',
                      ru: 'Не удалось загрузить задачи',
                      en: 'Tasks could not be loaded',
                    ),
                    message: app.tasksError,
                    onRetry: () => unawaited(app.refreshTasks()),
                  ),
                ),
              )
            else if (tasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
                  child: SizedBox(
                    height: 320,
                    child: SfEmptyState(
                      title: _copy(
                        context,
                        uz: 'Bu ko‘rinishda vazifa yo‘q',
                        ru: 'Здесь пока нет задач',
                        en: 'No tasks in this view',
                      ),
                      message: _copy(
                        context,
                        uz: 'Qidiruv yoki filtrni o‘zgartiring, yoxud yangi sahifa yarating.',
                        ru: 'Измените поиск или фильтр либо создайте новую страницу.',
                        en: 'Adjust the search or filter, or create a new task page.',
                      ),
                      actionLabel: canCreate ? context.tr('new_task') : null,
                      onAction: canCreate
                          ? () => context.push('/tasks/new')
                          : null,
                    ),
                  ),
                ),
              )
            else if (_view == _TaskView.list)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                sliver: SliverList.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) =>
                      _TaskPageCard(task: tasks[index]),
                ),
              )
            else if (_view == _TaskView.board)
              SliverToBoxAdapter(child: _TaskBoard(tasks: tasks))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                sliver: SliverToBoxAdapter(
                  child: _TaskCalendar(
                    tasks: tasks,
                    selectedDate: _selectedDate,
                    onDateChanged: (value) =>
                        setState(() => _selectedDate = value),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottom: canCreate
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: SfButton(
                kind: SfButtonKind.primary,
                block: true,
                height: 50,
                label: context.tr('new_task'),
                leading: SfIcons.plus,
                haptic: app.settings.haptics,
                motionEnabled: !app.settings.reducedMotion,
                onPressed: () => context.push('/tasks/new'),
              ),
            )
          : null,
    );
  }

  List<StaffTask> _visibleTasks(
    List<StaffTask> source,
    String? userId, {
    required bool includeCompletedForAll,
  }) {
    final query = _search.text.trim().toLowerCase();
    final now = DateTime.now();
    final values = source.where((task) {
      final matchesQuery =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.tags.any((tag) => tag.toLowerCase().contains(query));
      if (!matchesQuery) return false;
      return switch (_filter) {
        _TaskFilter.all =>
          includeCompletedForAll || task.status != TaskStatus.done,
        _TaskFilter.myDay =>
          task.assigneeId == userId &&
              (task.dueAt.isBefore(now.add(const Duration(days: 1))) ||
                  _sameDay(task.dueAt, now)),
        _TaskFilter.high =>
          task.status != TaskStatus.done &&
              (task.priority == TaskPriority.high ||
                  task.priority == TaskPriority.urgent),
        _TaskFilter.favorites => task.isFavorite,
        _TaskFilter.completed => task.status == TaskStatus.done,
      };
    }).toList();
    values.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return a.dueAt.compareTo(b.dueAt);
    });
    return values;
  }
}

class _CommandCenter extends StatelessWidget {
  const _CommandCenter({
    required this.progress,
    required this.active,
    required this.overdue,
    required this.dueThisWeek,
  });

  final double progress;
  final int active;
  final int overdue;
  final int dueThisWeek;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: SfTheme.of(
                    context,
                  ).duration(const Duration(milliseconds: 700)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: c.surface2,
                    color: c.primary,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: SfType.mono(
                    size: 13,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: c.ai, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      _copy(
                        context,
                        uz: 'Ish markazi',
                        ru: 'Рабочий центр',
                        en: 'Task command center',
                      ),
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _MiniStat(
                      value: '$active',
                      label: _copy(
                        context,
                        uz: 'faol',
                        ru: 'активно',
                        en: 'active',
                      ),
                      color: c.primary,
                    ),
                    _MiniStat(
                      value: '$dueThisWeek',
                      label: _copy(
                        context,
                        uz: 'haftada',
                        ru: 'на неделе',
                        en: 'this week',
                      ),
                      color: c.warn,
                    ),
                    _MiniStat(
                      value: '$overdue',
                      label: _copy(
                        context,
                        uz: 'kechikkan',
                        ru: 'просрочено',
                        en: 'overdue',
                      ),
                      color: c.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      '$value $label',
      style: SfType.ui(size: 9.5, weight: FontWeight.w700, color: color),
    ),
  );
}

class _SearchAndView extends StatelessWidget {
  const _SearchAndView({
    required this.controller,
    required this.view,
    required this.onSearch,
    required this.onViewChanged,
  });

  final TextEditingController controller;
  final _TaskView view;
  final ValueChanged<String> onSearch;
  final ValueChanged<_TaskView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _copy(
                context,
                uz: 'Sahifa va teglarni qidiring…',
                ru: 'Поиск страниц и тегов…',
                en: 'Search pages and tags…',
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _copy(
                        context,
                        uz: 'Tozalash',
                        ru: 'Очистить',
                        en: 'Clear',
                      ),
                      onPressed: () {
                        controller.clear();
                        onSearch('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: c.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              _ViewButton(
                icon: Icons.view_agenda_outlined,
                selected: view == _TaskView.list,
                onTap: () => onViewChanged(_TaskView.list),
              ),
              _ViewButton(
                icon: Icons.view_kanban_outlined,
                selected: view == _TaskView.board,
                onTap: () => onViewChanged(_TaskView.board),
              ),
              _ViewButton(
                icon: Icons.calendar_view_week_outlined,
                selected: view == _TaskView.calendar,
                onTap: () => onViewChanged(_TaskView.calendar),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onTap,
      selected: selected,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        width: 34,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: selected ? c.primary : c.muted),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.value, required this.onChanged});
  final _TaskFilter value;
  final ValueChanged<_TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _FilterChip(
          value: _TaskFilter.all,
          selected: value == _TaskFilter.all,
          label: _copy(context, uz: 'Faol', ru: 'Активные', en: 'Active'),
          icon: Icons.bolt_rounded,
          onTap: onChanged,
        ),
        _FilterChip(
          value: _TaskFilter.myDay,
          selected: value == _TaskFilter.myDay,
          label: _copy(
            context,
            uz: 'Mening kunim',
            ru: 'Мой день',
            en: 'My day',
          ),
          icon: Icons.wb_sunny_outlined,
          onTap: onChanged,
        ),
        _FilterChip(
          value: _TaskFilter.high,
          selected: value == _TaskFilter.high,
          label: _copy(context, uz: 'Muhim', ru: 'Важные', en: 'Priority'),
          icon: Icons.flag_outlined,
          onTap: onChanged,
        ),
        _FilterChip(
          value: _TaskFilter.favorites,
          selected: value == _TaskFilter.favorites,
          label: _copy(
            context,
            uz: 'Sevimli',
            ru: 'Избранное',
            en: 'Favorites',
          ),
          icon: Icons.star_outline_rounded,
          onTap: onChanged,
        ),
        _FilterChip(
          value: _TaskFilter.completed,
          selected: value == _TaskFilter.completed,
          label: _copy(
            context,
            uz: 'Yakunlangan',
            ru: 'Готово',
            en: 'Completed',
          ),
          icon: Icons.check_circle_outline_rounded,
          onTap: onChanged,
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.value,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final _TaskFilter value;
  final bool selected;
  final String label;
  final IconData icon;
  final ValueChanged<_TaskFilter> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon, size: 15),
      label: Text(label),
      onSelected: (_) => onTap(value),
    ),
  );
}

class _TaskPageCard extends StatelessWidget {
  const _TaskPageCard({required this.task, this.compact = false});
  final StaffTask task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final overdue =
        task.status != TaskStatus.done && task.dueAt.isBefore(DateTime.now());
    final progress = task.checklist.isEmpty
        ? 0.0
        : task.completedSteps / task.checklist.length;
    return SfPressable(
      onPressed: () => context.push('/tasks/detail?id=${task.id}'),
      borderRadius: BorderRadius.circular(20),
      child: SfSurfaceCard(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SfPressable(
                  onPressed: app.canUpdateTask(task)
                      ? () => unawaited(
                          app.setTaskStatus(
                            task.id,
                            task.status == TaskStatus.done
                                ? TaskStatus.todo
                                : TaskStatus.done,
                          ),
                        )
                      : null,
                  semanticLabel: task.status == TaskStatus.done
                      ? 'Qayta ochish'
                      : 'Yakunlash',
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: task.status == TaskStatus.done
                          ? c.success
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.status == TaskStatus.done
                            ? c.success
                            : c.borderStrong,
                        width: 1.7,
                      ),
                    ),
                    child: task.status == TaskStatus.done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style:
                            SfType.ui(
                              size: compact ? 12 : 14,
                              weight: FontWeight.w700,
                              color: task.status == TaskStatus.done
                                  ? c.muted
                                  : c.ink,
                            ).copyWith(
                              decoration: task.status == TaskStatus.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      if (!compact && task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 10.5,
                            color: c.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SfPressable(
                  onPressed: () => unawaited(app.toggleTaskFavorite(task.id)),
                  semanticLabel: 'Sevimli',
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      task.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 19,
                      color: task.isFavorite ? c.accent : c.muted2,
                    ),
                  ),
                ),
                SfPressable(
                  onPressed: () => _openTaskActions(context, task),
                  semanticLabel: 'Amallar',
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: c.muted,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 11),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _TaskProperty(
                    label: _statusLabel(context, task.status),
                    color: _statusColor(c, task.status),
                    icon: Icons.radio_button_checked_rounded,
                  ),
                  _TaskProperty(
                    label: _priorityLabel(context, task.priority),
                    color: _priorityColor(c, task.priority),
                    icon: Icons.flag_rounded,
                  ),
                  _TaskProperty(
                    label: _dateLabel(task.dueAt),
                    color: overdue ? c.danger : c.muted,
                    icon: overdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today_outlined,
                  ),
                  for (final tag in task.tags.take(2))
                    _TaskProperty(
                      label: tag,
                      color: c.primary,
                      icon: Icons.tag_rounded,
                    ),
                ],
              ),
              if (task.checklist.isNotEmpty) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: c.surface2,
                          color: c.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.completedSteps}/${task.checklist.length}',
                      style: SfType.mono(size: 9.5, color: c.muted),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskProperty extends StatelessWidget {
  const _TaskProperty({
    required this.label,
    required this.color,
    required this.icon,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: SfType.ui(size: 9, weight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}

class _TaskBoard extends StatefulWidget {
  const _TaskBoard({required this.tasks});
  final List<StaffTask> tasks;

  @override
  State<_TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<_TaskBoard> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _edgeScroll(DragUpdateDetails details) {
    if (!_scroll.hasClients) return;
    final width = MediaQuery.sizeOf(context).width;
    final x = details.globalPosition.dx;
    var delta = 0.0;
    if (x < 58) {
      delta = -14;
    } else if (x > width - 58) {
      delta = 14;
    }
    if (delta == 0) return;
    final next = (_scroll.offset + delta).clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 530,
    child: ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
      scrollDirection: Axis.horizontal,
      itemCount: TaskStatus.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final status = TaskStatus.values[index];
        final items = widget.tasks
            .where((task) => task.status == status)
            .toList();
        return _BoardColumn(
          status: status,
          tasks: items,
          onDragUpdate: _edgeScroll,
        );
      },
    ),
  );
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.tasks,
    required this.onDragUpdate,
  });
  final TaskStatus status;
  final List<StaffTask> tasks;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final color = _statusColor(c, status);
    return DragTarget<StaffTask>(
      onWillAcceptWithDetails: (details) =>
          app.canUpdateTask(details.data) && details.data.status != status,
      onAcceptWithDetails: (details) =>
          unawaited(app.setTaskStatus(details.data.id, status)),
      builder: (context, candidates, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 260,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? color.withValues(alpha: .12)
              : c.surface2.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: candidates.isNotEmpty ? color : c.border,
            width: candidates.isNotEmpty ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _statusLabel(context, status),
                    style: SfType.ui(size: 12, weight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${tasks.length}',
                  style: SfType.mono(size: 10, color: c.muted),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        '—',
                        style: SfType.display(size: 28, color: c.muted2),
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final card = _TaskPageCard(task: task, compact: true);
                        if (!app.canUpdateTask(task)) return card;
                        return LongPressDraggable<StaffTask>(
                          data: task,
                          maxSimultaneousDrags: 1,
                          onDragUpdate: onDragUpdate,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 240,
                              child: Opacity(opacity: .94, child: card),
                            ),
                          ),
                          childWhenDragging: Opacity(opacity: .28, child: card),
                          child: card,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCalendar extends StatelessWidget {
  const _TaskCalendar({
    required this.tasks,
    required this.selectedDate,
    required this.onDateChanged,
  });
  final List<StaffTask> tasks;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final start = _day(DateTime.now()).subtract(const Duration(days: 2));
    final days = [
      for (var index = 0; index < 14; index++) start.add(Duration(days: index)),
    ];
    final selectedTasks = tasks
        .where((task) => _sameDay(task.dueAt, selectedDate))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SfSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 70,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final day = days[index];
                final selected = _sameDay(day, selectedDate);
                final count = tasks
                    .where((task) => _sameDay(task.dueAt, day))
                    .length;
                return SfPressable(
                  onPressed: () => onDateChanged(day),
                  selected: selected,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 52,
                    decoration: BoxDecoration(
                      color: selected ? c.primary : c.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekday(day.weekday),
                          style: SfType.ui(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: selected ? Colors.white70 : c.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          style: SfType.mono(
                            size: 16,
                            weight: FontWeight.w800,
                            color: selected ? Colors.white : c.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: count == 0 ? 3 : 14,
                          height: 3,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : count == 0
                                ? c.muted2
                                : c.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${_dateLong(selectedDate)} · ${selectedTasks.length}',
          style: SfType.ui(size: 14, weight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 9),
        if (selectedTasks.isEmpty)
          SfSurfaceCard(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: Text(
                _copy(
                  context,
                  uz: 'Bu kunda muddat yo‘q',
                  ru: 'На этот день задач нет',
                  en: 'Nothing is due on this day',
                ),
                style: SfType.ui(color: c.muted),
              ),
            ),
          )
        else
          for (final task in selectedTasks) ...[
            _TaskPageCard(task: task),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

Future<void> _openTaskActions(BuildContext context, StaffTask task) async {
  final app = AppScope.of(context);
  final action = await showSfActionSheet<_TaskAction>(
    context,
    title: task.title,
    message: _copy(
      context,
      uz: 'Sahifa amallari',
      ru: 'Действия со страницей',
      en: 'Page actions',
    ),
    actions: [
      SfSheetAction(
        label: task.isFavorite
            ? _copy(
                context,
                uz: 'Sevimlidan olish',
                ru: 'Убрать из избранного',
                en: 'Remove favorite',
              )
            : _copy(
                context,
                uz: 'Sevimliga qo‘shish',
                ru: 'В избранное',
                en: 'Add to favorites',
              ),
        value: _TaskAction.favorite,
        icon: task.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
      ),
      SfSheetAction(
        label: _copy(
          context,
          uz: 'Bajarilmoqda',
          ru: 'В работе',
          en: 'Move to in progress',
        ),
        value: _TaskAction.progress,
        icon: Icons.play_arrow_rounded,
      ),
      SfSheetAction(
        label: _copy(
          context,
          uz: 'Yakunlash',
          ru: 'Завершить',
          en: 'Mark complete',
        ),
        value: _TaskAction.complete,
        icon: Icons.check_circle_outline_rounded,
      ),
      SfSheetAction(
        label: _copy(context, uz: 'O‘chirish', ru: 'Удалить', en: 'Delete'),
        value: _TaskAction.delete,
        icon: Icons.delete_outline_rounded,
        destructive: true,
      ),
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _TaskAction.favorite:
      await app.toggleTaskFavorite(task.id);
      return;
    case _TaskAction.progress:
      await app.setTaskStatus(task.id, TaskStatus.inProgress);
      return;
    case _TaskAction.complete:
      await app.setTaskStatus(task.id, TaskStatus.done);
      return;
    case _TaskAction.delete:
      final approved = await showSfConfirmDialog(
        context,
        title: _copy(
          context,
          uz: 'Vazifa o‘chirilsinmi?',
          ru: 'Удалить задачу?',
          en: 'Delete this task?',
        ),
        message: _copy(
          context,
          uz: 'Bu amalni ortga qaytarib bo‘lmaydi.',
          ru: 'Это действие нельзя отменить.',
          en: 'This action cannot be undone.',
        ),
        confirmLabel: _copy(
          context,
          uz: 'O‘chirish',
          ru: 'Удалить',
          en: 'Delete',
        ),
        destructive: true,
      );
      if (approved) await app.deleteTask(task.id);
      return;
  }
}

enum _TaskAction { favorite, progress, complete, delete }

String _statusLabel(BuildContext context, TaskStatus status) =>
    switch (status) {
      TaskStatus.todo => _copy(
        context,
        uz: 'Rejada',
        ru: 'Запланировано',
        en: 'To do',
      ),
      TaskStatus.inProgress => _copy(
        context,
        uz: 'Bajarilmoqda',
        ru: 'В работе',
        en: 'In progress',
      ),
      TaskStatus.inReview => _copy(
        context,
        uz: 'Tekshiruvda',
        ru: 'На проверке',
        en: 'In review',
      ),
      TaskStatus.done => _copy(
        context,
        uz: 'Yakunlangan',
        ru: 'Готово',
        en: 'Done',
      ),
    };

String _priorityLabel(BuildContext context, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.low => _copy(context, uz: 'Past', ru: 'Низкий', en: 'Low'),
      TaskPriority.medium => _copy(
        context,
        uz: 'O‘rta',
        ru: 'Средний',
        en: 'Medium',
      ),
      TaskPriority.high => _copy(
        context,
        uz: 'Yuqori',
        ru: 'Высокий',
        en: 'High',
      ),
      TaskPriority.urgent => _copy(
        context,
        uz: 'Shoshilinch',
        ru: 'Срочно',
        en: 'Urgent',
      ),
    };

Color _statusColor(SfColors c, TaskStatus status) => switch (status) {
  TaskStatus.todo => c.muted,
  TaskStatus.inProgress => c.primary,
  TaskStatus.inReview => c.warn,
  TaskStatus.done => c.success,
};

Color _priorityColor(SfColors c, TaskPriority priority) => switch (priority) {
  TaskPriority.low => c.muted,
  TaskPriority.medium => c.primary,
  TaskPriority.high => c.warn,
  TaskPriority.urgent => c.danger,
};

bool _isThisWeek(StaffTask task) {
  final now = DateTime.now();
  return task.status != TaskStatus.done &&
      task.dueAt.isAfter(now.subtract(const Duration(days: 1))) &&
      task.dueAt.isBefore(now.add(const Duration(days: 7)));
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
String _dateLong(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
String _weekday(int value) =>
    const ['DU', 'SE', 'CH', 'PA', 'JU', 'SH', 'YA'][value - 1];

String _copy(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (Localizations.localeOf(context).languageCode) {
  'ru' => ru,
  'en' => en,
  _ => uz,
};
