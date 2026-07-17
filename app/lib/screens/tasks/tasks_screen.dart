import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../router.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../widgets/sf_toast.dart';

enum _TaskFilter { active, mine, completed, all }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.active;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final userId = state.session?.userId;
    final tasks =
        state.tasks
            .where((task) {
              return switch (_filter) {
                _TaskFilter.active => task.status != TaskStatus.done,
                _TaskFilter.mine => task.assigneeId == userId,
                _TaskFilter.completed => task.status == TaskStatus.done,
                _TaskFilter.all => true,
              };
            })
            .toList(growable: false)
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final canCreate = state.can(StaffCapability.createTasks);

    return SfScaffold(
      tab: SfTab.tasks,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: SfLargeAppBar(
        title: 'Vazifalar',
        subtitle:
            '${state.tasks.where((task) => task.status != TaskStatus.done).length} ta faol vazifa',
        actions: [
          if (canCreate)
            IconButton(
              tooltip: 'Yangi vazifa',
              onPressed: () => context.push('/tasks/new'),
              icon: const Icon(SfIcons.plus),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          SegmentedButton<_TaskFilter>(
            segments: const [
              ButtonSegment(value: _TaskFilter.active, label: Text('Faol')),
              ButtonSegment(value: _TaskFilter.mine, label: Text('Meniki')),
              ButtonSegment(
                value: _TaskFilter.completed,
                label: Text('Tayyor'),
              ),
              ButtonSegment(value: _TaskFilter.all, label: Text('Barchasi')),
            ],
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _filter = selection.first),
          ),
          const SizedBox(height: 12),
          if (!state.can(StaffCapability.updateOwnTasks)) ...[
            const SfHintCard(
              message:
                  'Siz vazifalarni ko‘rishingiz mumkin, ammo ularning holatini o‘zgartira olmaysiz.',
              tone: SfHintTone.info,
              compact: true,
            ),
            const SizedBox(height: 12),
          ],
          if (tasks.isEmpty)
            SfEmptyState(
              title: 'Bu ro‘yxat bo‘sh',
              message: 'Filtrni almashtiring yoki yangi vazifa yarating.',
              actionLabel: canCreate ? 'Yangi vazifa' : null,
              onAction: canCreate ? () => context.push('/tasks/new') : null,
            )
          else
            for (final task in tasks) ...[
              _TaskCard(task: task),
              const SizedBox(height: 9),
            ],
        ],
      ),
      bottom: canCreate
          ? Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SfButton(
                kind: SfButtonKind.primary,
                block: true,
                height: 48,
                label: 'Yangi vazifa',
                leading: SfIcons.plus,
                onPressed: () => context.push('/tasks/new'),
              ),
            )
          : null,
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final StaffTask task;

  Future<void> _changeStatus(BuildContext context, TaskStatus status) async {
    final old = task.status;
    if (old == status) return;
    try {
      await AppScope.of(context).setTaskStatus(task.id, status);
      if (!context.mounted) return;
      SfToast.show(
        context,
        title: 'Vazifa yangilandi',
        message: _statusLabel(status),
        tone: status == TaskStatus.done
            ? SfToastTone.success
            : SfToastTone.info,
        actionLabel: 'Bekor qilish',
        onAction: () => AppScope.of(context).setTaskStatus(task.id, old),
      );
    } on Object catch (error) {
      if (context.mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final accent = _priorityColor(context, task.priority);
    final canUpdate = AppScope.of(context).can(StaffCapability.updateOwnTasks);
    return SfSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(
          '/tasks/detail?id=${Uri.encodeQueryComponent(task.id)}',
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        _StatusPill(status: task.status),
                        Text(
                          _priorityLabel(task.priority),
                          style: SfType.eyebrow(color: accent, size: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: task.status == TaskStatus.done ? c.muted : c.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded, size: 14, color: c.muted),
                        const SizedBox(width: 4),
                        Text(
                          '${task.completedSteps}/${task.checklist.length}',
                          style: SfType.mono(size: 10, color: c.muted),
                        ),
                        const Spacer(),
                        Icon(Icons.schedule_rounded, size: 13, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          _dateLabel(task.dueAt),
                          style: SfType.mono(
                            size: 10,
                            weight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canUpdate)
                PopupMenuButton<TaskStatus>(
                  tooltip: 'Holatni o‘zgartirish',
                  initialValue: task.status,
                  onSelected: (status) => _changeStatus(context, status),
                  itemBuilder: (_) => [
                    for (final status in TaskStatus.values)
                      PopupMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                  ],
                )
              else
                Icon(SfIcons.chevR, size: 17, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final color = switch (status) {
      TaskStatus.todo => c.muted,
      TaskStatus.inProgress => c.primary,
      TaskStatus.inReview => c.warn,
      TaskStatus.done => c.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: SfType.eyebrow(color: color, size: 9),
      ),
    );
  }
}

String _statusLabel(TaskStatus status) => switch (status) {
  TaskStatus.todo => 'Boshlanmagan',
  TaskStatus.inProgress => 'Bajarilmoqda',
  TaskStatus.inReview => 'Tekshiruvda',
  TaskStatus.done => 'Tugatildi',
};

String _priorityLabel(TaskPriority priority) => switch (priority) {
  TaskPriority.low => 'PAST',
  TaskPriority.medium => 'O‘RTA',
  TaskPriority.high => 'YUQORI',
  TaskPriority.urgent => 'SHOSHILINCH',
};

Color _priorityColor(BuildContext context, TaskPriority priority) {
  final c = SfTheme.colorsOf(context);
  return switch (priority) {
    TaskPriority.low => c.muted,
    TaskPriority.medium => c.primary,
    TaskPriority.high => c.warn,
    TaskPriority.urgent => c.danger,
  };
}

String _dateLabel(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
