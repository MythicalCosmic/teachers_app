import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  StaffTask? _resolveTask(BuildContext context) {
    final tasks = AppScope.of(context).tasks;
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    if (id != null) {
      final matches = tasks.where((task) => task.id == id);
      if (matches.isNotEmpty) return matches.first;
    }
    return tasks.firstOrNull;
  }

  Future<void> _setStatus(
    BuildContext context,
    StaffTask task,
    TaskStatus status,
  ) async {
    if (status == TaskStatus.done &&
        task.checklist.any((item) => !item.isDone)) {
      SfToast.show(
        context,
        title: 'Hali qadamlar bor',
        message: 'Vazifani tugatishdan oldin barcha qadamlarni belgilang.',
        tone: SfToastTone.warning,
      );
      return;
    }
    final previous = task.status;
    try {
      await AppScope.of(context).setTaskStatus(task.id, status);
      if (!context.mounted) return;
      SfToast.show(
        context,
        title: status == TaskStatus.done
            ? 'Vazifa tugatildi'
            : 'Holat saqlandi',
        message: _statusLabel(status),
        tone: status == TaskStatus.done
            ? SfToastTone.success
            : SfToastTone.info,
        actionLabel: 'Bekor qilish',
        onAction: () => AppScope.of(context).setTaskStatus(task.id, previous),
      );
    } on Object catch (error) {
      if (context.mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    }
  }

  Future<void> _toggleStep(
    BuildContext context,
    StaffTask task,
    TaskChecklistItem item,
  ) async {
    try {
      await AppScope.of(context).toggleTaskChecklistItem(task.id, item.id);
      if (!context.mounted) return;
      SfToast.show(
        context,
        message: item.isDone ? 'Qadam qayta ochildi.' : 'Qadam bajarildi.',
        tone: item.isDone ? SfToastTone.info : SfToastTone.success,
        actionLabel: 'Bekor qilish',
        onAction: () =>
            AppScope.of(context).toggleTaskChecklistItem(task.id, item.id),
      );
    } on Object catch (error) {
      if (context.mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final task = _resolveTask(context);
    final c = SfTheme.colorsOf(context);
    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Vazifa'),
        ),
        body: SfEmptyState(
          title: 'Vazifa topilmadi',
          actionLabel: 'Orqaga',
          onAction: () => context.pop(),
        ),
      );
    }
    final canUpdate = state.can(StaffCapability.updateOwnTasks);
    final progress = task.checklist.isEmpty
        ? 0.0
        : task.completedSteps / task.checklist.length;
    return SfScaffold(
      top: SfNavBar(
        title: 'Vazifa',
        subtitle: _statusLabel(task.status),
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (canUpdate)
            PopupMenuButton<TaskStatus>(
              tooltip: 'Holatni o‘zgartirish',
              initialValue: task.status,
              onSelected: (status) => _setStatus(context, task, status),
              itemBuilder: (_) => [
                for (final status in TaskStatus.values)
                  PopupMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                label: _priorityLabel(task.priority),
                color: _priorityColor(context, task.priority),
              ),
              _Tag(
                label: _statusLabel(task.status),
                color: _statusColor(context, task.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: SfType.display(size: 27, color: c.ink, height: 1.14),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              task.description,
              style: SfType.ui(size: 14, color: c.ink2, height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _MetaRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Mas’ul',
                  value: task.assigneeName,
                ),
                const Divider(height: 22),
                _MetaRow(
                  icon: Icons.schedule_rounded,
                  label: 'Muddat',
                  value: _dateLabel(task.dueAt),
                ),
                const Divider(height: 22),
                _MetaRow(
                  icon: Icons.account_circle_outlined,
                  label: 'Yaratgan',
                  value: task.creatorName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('QADAMLAR', style: SfType.eyebrow(color: c.muted)),
              const Spacer(),
              Text(
                '${task.completedSteps}/${task.checklist.length}',
                style: SfType.mono(size: 11, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            color: progress == 1 ? c.success : c.primary,
            backgroundColor: c.surface3,
          ),
          const SizedBox(height: 9),
          if (task.checklist.isEmpty)
            const SfHintCard(
              message: 'Bu vazifa uchun alohida qadamlar belgilanmagan.',
              compact: true,
            )
          else
            SfSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final entry in task.checklist.asMap().entries)
                    CheckboxListTile(
                      value: entry.value.isDone,
                      onChanged: canUpdate
                          ? (_) => _toggleStep(context, task, entry.value)
                          : null,
                      title: Text(
                        entry.value.title,
                        style:
                            SfType.ui(
                              size: 13,
                              color: entry.value.isDone ? c.muted : c.ink,
                              weight: FontWeight.w600,
                            ).copyWith(
                              decoration: entry.value.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: entry.key == task.checklist.length - 1
                          ? null
                          : Border(bottom: BorderSide(color: c.border)),
                    ),
                ],
              ),
            ),
          if (!canUpdate) ...[
            const SizedBox(height: 14),
            const SfHintCard(
              message: 'Bu vazifa siz uchun faqat ko‘rish rejimida.',
              tone: SfHintTone.info,
              compact: true,
            ),
          ],
        ],
      ),
      bottom: canUpdate && task.status != TaskStatus.done
          ? Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SfButton(
                kind: SfButtonKind.primary,
                block: true,
                height: 50,
                label: task.checklist.any((item) => !item.isDone)
                    ? 'Qadamlarni yakunlang'
                    : 'Vazifani tugatish',
                leading: Icons.check_circle_outline_rounded,
                onPressed: task.checklist.any((item) => !item.isDone)
                    ? null
                    : () => _setStatus(context, task, TaskStatus.done),
              ),
            )
          : null,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label.toUpperCase(),
      style: SfType.eyebrow(color: color, size: 10),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: c.primary),
        const SizedBox(width: 10),
        Text(label, style: SfType.ui(size: 12, color: c.muted)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: SfType.ui(size: 12, weight: FontWeight.w700, color: c.ink),
          ),
        ),
      ],
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
  TaskPriority.low => 'Past',
  TaskPriority.medium => 'O‘rta',
  TaskPriority.high => 'Yuqori',
  TaskPriority.urgent => 'Shoshilinch',
};

Color _statusColor(BuildContext context, TaskStatus status) {
  final c = SfTheme.colorsOf(context);
  return switch (status) {
    TaskStatus.todo => c.muted,
    TaskStatus.inProgress => c.primary,
    TaskStatus.inReview => c.warn,
    TaskStatus.done => c.success,
  };
}

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
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
