import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _newStep = TextEditingController();
  final _comment = TextEditingController();
  String? _loadedTaskId;
  bool _editing = false;
  bool _saving = false;
  bool _addingComment = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _newStep.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final taskId = GoRouterState.of(context).uri.queryParameters['id'];
    final task = app.tasks.where((item) => item.id == taskId).firstOrNull;
    if (task == null) {
      return SfScaffold(
        top: SfNavBar(
          title: _copy(context, uz: 'Vazifa', ru: 'Задача', en: 'Task'),
          leading: const BackButton(),
        ),
        body: SfErrorState(
          title: _copy(
            context,
            uz: 'Vazifa topilmadi',
            ru: 'Задача не найдена',
            en: 'Task not found',
          ),
          message: _copy(
            context,
            uz: 'U o‘chirilgan yoki boshqa hisobga tegishli.',
            ru: 'Она удалена или относится к другому аккаунту.',
            en: 'It may have been deleted or belongs to another account.',
          ),
          onRetry: () => context.pop(),
        ),
      );
    }
    if (_loadedTaskId != task.id) {
      _loadedTaskId = task.id;
      _title.text = task.title;
      _description.text = task.description;
    }

    final c = SfTheme.colorsOf(context);
    final canUpdate = app.can(StaffCapability.updateOwnTasks);
    final canEditServerDetails = canUpdate && !app.isProduction;
    final progress = task.checklist.isEmpty
        ? 0.0
        : task.completedSteps / task.checklist.length;

    return SfScaffold(
      dismissKeyboardOnTap: true,
      top: SfNavBar(
        title: _copy(
          context,
          uz: 'Vazifa sahifasi',
          ru: 'Страница задачи',
          en: 'Task page',
        ),
        leading: IconButton(
          tooltip: _copy(context, uz: 'Orqaga', ru: 'Назад', en: 'Back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            tooltip: _copy(
              context,
              uz: 'Sevimli',
              ru: 'Избранное',
              en: 'Favorite',
            ),
            onPressed: () => unawaited(app.toggleTaskFavorite(task.id)),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                task.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                key: ValueKey(task.isFavorite),
                color: task.isFavorite ? c.accent : c.muted,
              ),
            ),
          ),
          IconButton(
            tooltip: _copy(
              context,
              uz: 'Sahifa amallari',
              ru: 'Действия',
              en: 'Page actions',
            ),
            onPressed: () => _moreActions(task),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          _PageCover(task: task),
          if (app.isProduction) ...[
            const SizedBox(height: 12),
            SfHintCard(
              compact: true,
              tone: SfHintTone.info,
              title: _copy(
                context,
                uz: 'Server vazifasi',
                ru: 'Серверная задача',
                en: 'Server task',
              ),
              message: _copy(
                context,
                uz: 'Holat server bilan sinxronlanadi. Teglar, qadamlar, sevimlilar va izohlar shu qurilmadagi shaxsiy tartibdir.',
                ru: 'Статус синхронизируется с сервером. Теги, шаги, избранное и заметки — личная организация на этом устройстве.',
                en: 'Status syncs with the server. Tags, checklist items, favorites, and notes are personal organization on this device.',
              ),
            ),
          ],
          const SizedBox(height: 14),
          AnimatedCrossFade(
            duration: SfTheme.of(
              context,
            ).duration(const Duration(milliseconds: 280)),
            crossFadeState: _editing
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _ReadPageHeader(
              task: task,
              canEdit: canEditServerDetails,
              onEdit: () => setState(() => _editing = true),
            ),
            secondChild: _EditPageHeader(
              title: _title,
              description: _description,
              saving: _saving,
              onCancel: () {
                _title.text = task.title;
                _description.text = task.description;
                setState(() => _editing = false);
              },
              onSave: () => _saveHeader(task),
            ),
          ),
          const SizedBox(height: 14),
          _SectionLabel(
            label: _copy(
              context,
              uz: 'XUSUSIYATLAR',
              ru: 'СВОЙСТВА',
              en: 'PROPERTIES',
            ),
          ),
          const SizedBox(height: 7),
          SfSurfaceCard(
            child: Column(
              children: [
                _PropertyRow(
                  icon: Icons.radio_button_checked_rounded,
                  label: _copy(
                    context,
                    uz: 'Holat',
                    ru: 'Статус',
                    en: 'Status',
                  ),
                  value: _statusLabel(context, task.status),
                  color: _statusColor(c, task.status),
                  onTap: canUpdate ? () => _pickStatus(task) : null,
                ),
                const Divider(height: 1),
                _PropertyRow(
                  icon: Icons.flag_rounded,
                  label: _copy(
                    context,
                    uz: 'Muhimlik',
                    ru: 'Приоритет',
                    en: 'Priority',
                  ),
                  value: _priorityLabel(context, task.priority),
                  color: _priorityColor(c, task.priority),
                  onTap: canEditServerDetails
                      ? () => _pickPriority(task)
                      : null,
                ),
                const Divider(height: 1),
                _PropertyRow(
                  icon: Icons.calendar_today_outlined,
                  label: _copy(
                    context,
                    uz: 'Muddat',
                    ru: 'Срок',
                    en: 'Due date',
                  ),
                  value: _dateTime(task.dueAt),
                  color:
                      task.status != TaskStatus.done &&
                          task.dueAt.isBefore(DateTime.now())
                      ? c.danger
                      : c.ink2,
                  onTap: canEditServerDetails ? () => _pickDueDate(task) : null,
                ),
                const Divider(height: 1),
                _PropertyRow(
                  icon: Icons.person_outline_rounded,
                  label: _copy(
                    context,
                    uz: 'Mas’ul',
                    ru: 'Исполнитель',
                    en: 'Assignee',
                  ),
                  value: task.assigneeName,
                  color: c.primary,
                  onTap: () => _showPeople(task),
                ),
                const Divider(height: 1),
                _PropertyRow(
                  icon: Icons.schedule_rounded,
                  label: _copy(
                    context,
                    uz: 'Yaratilgan',
                    ru: 'Создано',
                    en: 'Created',
                  ),
                  value: _dateTime(task.createdAt),
                  color: c.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _SectionHeader(
            title: _copy(context, uz: 'Teglar', ru: 'Теги', en: 'Tags'),
            icon: Icons.tag_rounded,
            actionLabel: canUpdate
                ? _copy(context, uz: 'Qo‘shish', ru: 'Добавить', en: 'Add')
                : null,
            onAction: canUpdate ? () => _addTag(task) : null,
          ),
          const SizedBox(height: 7),
          SfSurfaceCard(
            padding: const EdgeInsets.all(13),
            child: task.tags.isEmpty
                ? Text(
                    _copy(
                      context,
                      uz: 'Teg yo‘q. Sahifani tez topish uchun teg qo‘shing.',
                      ru: 'Тегов нет. Добавьте их для быстрого поиска.',
                      en: 'No tags yet. Add one to make this page easier to find.',
                    ),
                    style: SfType.ui(size: 11, color: c.muted),
                  )
                : Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final tag in task.tags)
                        InputChip(
                          avatar: const Icon(Icons.tag_rounded, size: 14),
                          label: Text(tag),
                          onDeleted: canUpdate
                              ? () => unawaited(app.removeTaskTag(task.id, tag))
                              : null,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 17),
          _SectionHeader(
            title: _copy(
              context,
              uz: 'Qadamlar',
              ru: 'Подзадачи',
              en: 'Checklist',
            ),
            icon: Icons.checklist_rounded,
            trailing: '${task.completedSteps}/${task.checklist.length}',
          ),
          const SizedBox(height: 7),
          SfSurfaceCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 480),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 7,
                                  backgroundColor: c.surface2,
                                  color: progress == 1 ? c.success : c.primary,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress * 100).round()}%',
                        style: SfType.mono(
                          size: 10.5,
                          weight: FontWeight.w800,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.checklist.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _copy(
                          context,
                          uz: 'Hali qadamlar yo‘q.',
                          ru: 'Подзадач пока нет.',
                          en: 'No checklist items yet.',
                        ),
                        style: SfType.ui(color: c.muted),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: task.checklist.length,
                    onReorderItem: canUpdate
                        ? (oldIndex, newIndex) => unawaited(
                            app.reorderTaskChecklist(
                              task.id,
                              oldIndex,
                              newIndex,
                            ),
                          )
                        : (_, _) {},
                    itemBuilder: (context, index) {
                      final item = task.checklist[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: canUpdate
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        background: Container(
                          color: c.dangerSoft,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 18),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: c.danger,
                          ),
                        ),
                        confirmDismiss: (_) => showSfConfirmDialog(
                          context,
                          title: _copy(
                            context,
                            uz: 'Qadam o‘chirilsinmi?',
                            ru: 'Удалить подзадачу?',
                            en: 'Delete this item?',
                          ),
                          message: item.title,
                          destructive: true,
                          confirmLabel: _copy(
                            context,
                            uz: 'O‘chirish',
                            ru: 'Удалить',
                            en: 'Delete',
                          ),
                        ),
                        onDismissed: (_) => unawaited(
                          app.removeTaskChecklistItem(task.id, item.id),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: c.border)),
                          ),
                          child: CheckboxListTile(
                            value: item.isDone,
                            onChanged: canUpdate
                                ? (_) => unawaited(
                                    app.toggleTaskChecklistItem(
                                      task.id,
                                      item.id,
                                    ),
                                  )
                                : null,
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: canUpdate
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PopupMenuButton<int>(
                                        enabled: task.checklist.length > 1,
                                        tooltip: _copy(
                                          context,
                                          uz: 'Qadamni ko‘chirish',
                                          ru: 'Переместить подзадачу',
                                          en: 'Move item',
                                        ),
                                        onSelected: (newIndex) => unawaited(
                                          app.reorderTaskChecklist(
                                            task.id,
                                            index,
                                            newIndex,
                                          ),
                                        ),
                                        itemBuilder: (context) => [
                                          if (index > 0)
                                            PopupMenuItem(
                                              value: index - 1,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .keyboard_arrow_up_rounded,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _copy(
                                                      context,
                                                      uz: 'Yuqoriga ko‘chirish',
                                                      ru: 'Переместить вверх',
                                                      en: 'Move up',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (index < task.checklist.length - 1)
                                            PopupMenuItem(
                                              value: index + 1,
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _copy(
                                                      context,
                                                      uz: 'Pastga ko‘chirish',
                                                      ru: 'Переместить вниз',
                                                      en: 'Move down',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                        icon: Icon(
                                          Icons.unfold_more_rounded,
                                          color: c.muted2,
                                          size: 20,
                                        ),
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Tooltip(
                                          message: _copy(
                                            context,
                                            uz: 'Tartibni o‘zgartirish',
                                            ru: 'Изменить порядок',
                                            en: 'Reorder item',
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                            ),
                                            child: Icon(
                                              Icons.drag_indicator_rounded,
                                              color: c.muted2,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                            title: Text(
                              item.title,
                              style:
                                  SfType.ui(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: item.isDone ? c.muted : c.ink,
                                  ).copyWith(
                                    decoration: item.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (canUpdate) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _newStep,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addStep(task),
                            decoration: InputDecoration(
                              hintText: _copy(
                                context,
                                uz: 'Yangi qadam…',
                                ru: 'Новая подзадача…',
                                en: 'New checklist item…',
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _copy(
                            context,
                            uz: 'Qo‘shish',
                            ru: 'Добавить',
                            en: 'Add',
                          ),
                          onPressed: () => _addStep(task),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 17),
          _SectionHeader(
            title: _copy(
              context,
              uz: 'Izohlar',
              ru: 'Комментарии',
              en: 'Comments',
            ),
            icon: Icons.chat_bubble_outline_rounded,
            trailing: '${task.comments.length}',
          ),
          const SizedBox(height: 7),
          SfSurfaceCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                if (task.comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.forum_outlined, color: c.muted2),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _copy(
                              context,
                              uz: 'Muhokamani birinchi bo‘lib boshlang.',
                              ru: 'Начните обсуждение первым.',
                              en: 'Be the first to start the discussion.',
                            ),
                            style: SfType.ui(size: 11, color: c.muted),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final comment in task.comments) ...[
                    _CommentBubble(comment: comment),
                    const SizedBox(height: 11),
                  ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SfAvatar(name: app.session?.displayName ?? '', size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _copy(
                            context,
                            uz: 'Izoh yozing…',
                            ru: 'Напишите комментарий…',
                            en: 'Write a comment…',
                          ),
                          filled: true,
                          fillColor: c.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    IconButton.filled(
                      tooltip: _copy(
                        context,
                        uz: 'Yuborish',
                        ru: 'Отправить',
                        en: 'Send',
                      ),
                      onPressed: _addingComment
                          ? null
                          : () => _sendComment(task),
                      icon: _addingComment
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _SectionHeader(
            title: _copy(
              context,
              uz: 'Faollik',
              ru: 'Активность',
              en: 'Activity',
            ),
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 7),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _ActivityRow(
                  color: c.primary,
                  title: _copy(
                    context,
                    uz: '${task.creatorName} sahifani yaratdi',
                    ru: '${task.creatorName} создал страницу',
                    en: '${task.creatorName} created this page',
                  ),
                  subtitle: _dateTime(task.createdAt),
                ),
                for (final comment in task.comments)
                  _ActivityRow(
                    color: c.accent,
                    title: _copy(
                      context,
                      uz: '${comment.authorName} izoh qoldirdi',
                      ru: '${comment.authorName} оставил комментарий',
                      en: '${comment.authorName} commented',
                    ),
                    subtitle: _dateTime(comment.createdAt),
                  ),
              ],
            ),
          ),
          if (!canUpdate) ...[
            const SizedBox(height: 14),
            SfHintCard(
              message: _copy(
                context,
                uz: 'Bu sahifa siz uchun faqat ko‘rish rejimida.',
                ru: 'Страница доступна только для просмотра.',
                en: 'This page is read-only for your role.',
              ),
              tone: SfHintTone.info,
              compact: true,
            ),
          ],
        ],
      ),
      bottom: canUpdate
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: SfButton(
                kind: task.status == TaskStatus.done
                    ? SfButtonKind.soft
                    : SfButtonKind.primary,
                block: true,
                height: 50,
                label: task.status == TaskStatus.done
                    ? _copy(
                        context,
                        uz: 'Vazifani qayta ochish',
                        ru: 'Открыть заново',
                        en: 'Reopen task',
                      )
                    : _copy(
                        context,
                        uz: 'Vazifani yakunlash',
                        ru: 'Завершить задачу',
                        en: 'Complete task',
                      ),
                leading: task.status == TaskStatus.done
                    ? Icons.restart_alt_rounded
                    : Icons.check_circle_outline_rounded,
                onPressed: () => unawaited(
                  app.setTaskStatus(
                    task.id,
                    task.status == TaskStatus.done
                        ? TaskStatus.inProgress
                        : TaskStatus.done,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _saveHeader(StaffTask task) async {
    if (_title.text.trim().length < 3) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(
        context,
      ).updateTask(task.id, title: _title.text, description: _description.text);
      if (mounted) setState(() => _editing = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addStep(StaffTask task) async {
    final value = _newStep.text.trim();
    if (value.isEmpty) return;
    _newStep.clear();
    await AppScope.of(context).addTaskChecklistItem(task.id, value);
  }

  Future<void> _sendComment(StaffTask task) async {
    if (_comment.text.trim().isEmpty) return;
    setState(() => _addingComment = true);
    try {
      await AppScope.of(context).addTaskComment(task.id, _comment.text);
      _comment.clear();
    } finally {
      if (mounted) setState(() => _addingComment = false);
    }
  }

  Future<void> _pickStatus(StaffTask task) async {
    final value = await showSfActionSheet<TaskStatus>(
      context,
      title: _copy(
        context,
        uz: 'Holatni tanlang',
        ru: 'Выберите статус',
        en: 'Choose a status',
      ),
      actions: [
        for (final status in TaskStatus.values)
          SfSheetAction(
            label: _statusLabel(context, status),
            value: status,
            icon: Icons.radio_button_checked_rounded,
          ),
      ],
    );
    if (value != null && mounted) {
      await AppScope.of(context).setTaskStatus(task.id, value);
    }
  }

  Future<void> _pickPriority(StaffTask task) async {
    final value = await showSfActionSheet<TaskPriority>(
      context,
      title: _copy(
        context,
        uz: 'Muhimlik darajasi',
        ru: 'Уровень приоритета',
        en: 'Priority level',
      ),
      actions: [
        for (final priority in TaskPriority.values)
          SfSheetAction(
            label: _priorityLabel(context, priority),
            value: priority,
            icon: Icons.flag_outlined,
          ),
      ],
    );
    if (value != null && mounted) {
      await AppScope.of(context).updateTask(task.id, priority: value);
    }
  }

  Future<void> _pickDueDate(StaffTask task) async {
    final date = await showDatePicker(
      context: context,
      initialDate: task.dueAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(task.dueAt),
    );
    if (!mounted) return;
    final selectedTime = time ?? TimeOfDay.fromDateTime(task.dueAt);
    await AppScope.of(context).updateTask(
      task.id,
      dueAt: DateTime(
        date.year,
        date.month,
        date.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
  }

  Future<void> _showPeople(StaffTask task) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _copy(
                context,
                uz: 'Vazifa ishtirokchilari',
                ru: 'Участники задачи',
                en: 'Task people',
              ),
              style: SfType.ui(size: 18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SfAvatar(name: task.assigneeName, size: 42),
              title: Text(task.assigneeName),
              subtitle: Text(
                _copy(context, uz: 'Mas’ul', ru: 'Исполнитель', en: 'Assignee'),
              ),
              trailing: const Icon(Icons.check_circle_rounded),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SfAvatar(name: task.creatorName, size: 42),
              title: Text(task.creatorName),
              subtitle: Text(
                _copy(context, uz: 'Yaratuvchi', ru: 'Автор', en: 'Creator'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _addTag(StaffTask task) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _copy(
            context,
            uz: 'Teg qo‘shish',
            ru: 'Добавить тег',
            en: 'Add a tag',
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => context.pop(value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.tag_rounded),
            hintText: 'Masalan: Hisobot',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              _copy(context, uz: 'Bekor', ru: 'Отмена', en: 'Cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => context.pop(controller.text),
            child: Text(
              _copy(context, uz: 'Qo‘shish', ru: 'Добавить', en: 'Add'),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      await AppScope.of(context).addTaskTag(task.id, value);
    }
  }

  Future<void> _moreActions(StaffTask task) async {
    final app = AppScope.of(context);
    final action = await showSfActionSheet<_DetailAction>(
      context,
      title: task.title,
      actions: [
        SfSheetAction(
          label: _copy(
            context,
            uz: 'Nusxa yaratish',
            ru: 'Создать копию',
            en: 'Duplicate page',
          ),
          value: _DetailAction.duplicate,
          icon: Icons.copy_all_outlined,
        ),
        if (!app.isProduction) ...[
          SfSheetAction(
            label: _copy(
              context,
              uz: 'Sahifani tahrirlash',
              ru: 'Изменить страницу',
              en: 'Edit page',
            ),
            value: _DetailAction.edit,
            icon: Icons.edit_outlined,
          ),
          SfSheetAction(
            label: _copy(context, uz: 'O‘chirish', ru: 'Удалить', en: 'Delete'),
            value: _DetailAction.delete,
            icon: Icons.delete_outline_rounded,
            destructive: true,
          ),
        ],
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _DetailAction.duplicate:
        final created = await app.createTask(
          title: '${task.title} · copy',
          description: task.description,
          priority: task.priority,
          dueAt: task.dueAt.add(const Duration(days: 1)),
          checklist: task.checklist.map((item) => item.title),
          tags: task.tags,
        );
        if (mounted) context.pushReplacement('/tasks/detail?id=${created.id}');
        return;
      case _DetailAction.edit:
        setState(() => _editing = true);
        return;
      case _DetailAction.delete:
        final approved = await showSfConfirmDialog(
          context,
          title: _copy(
            context,
            uz: 'Sahifa o‘chirilsinmi?',
            ru: 'Удалить страницу?',
            en: 'Delete this page?',
          ),
          message: _copy(
            context,
            uz: 'Vazifa va uning barcha izohlari o‘chadi.',
            ru: 'Задача и все комментарии будут удалены.',
            en: 'The task and all of its comments will be removed.',
          ),
          confirmLabel: _copy(
            context,
            uz: 'O‘chirish',
            ru: 'Удалить',
            en: 'Delete',
          ),
          destructive: true,
        );
        if (approved) {
          await app.deleteTask(task.id);
          if (mounted) context.pop();
        }
        return;
    }
  }
}

enum _DetailAction { duplicate, edit, delete }

class _PageCover extends StatelessWidget {
  const _PageCover({required this.task});
  final StaffTask task;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      height: 104,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _priorityColor(c, task.priority).withValues(alpha: .88),
            c.primary.withValues(alpha: .82),
            c.accent.withValues(alpha: .72),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -28,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 126,
              color: Colors.white.withValues(alpha: .09),
            ),
          ),
          Positioned(
            left: 15,
            bottom: 13,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: .48)),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadPageHeader extends StatelessWidget {
  const _ReadPageHeader({
    required this.task,
    required this.canEdit,
    required this.onEdit,
  });
  final StaffTask task;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: SfType.ui(
                  size: 25,
                  weight: FontWeight.w800,
                  color: c.ink,
                  height: 1.18,
                ),
              ),
            ),
            if (canEdit)
              IconButton.filledTonal(
                tooltip: _copy(
                  context,
                  uz: 'Tahrirlash',
                  ru: 'Изменить',
                  en: 'Edit',
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
          ],
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            task.description,
            style: SfType.ui(size: 13, color: c.ink2, height: 1.55),
          ),
        ],
      ],
    );
  }
}

class _EditPageHeader extends StatelessWidget {
  const _EditPageHeader({
    required this.title,
    required this.description,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });
  final TextEditingController title;
  final TextEditingController description;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => SfSurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        SfTextField(
          controller: title,
          label: _copy(context, uz: 'Sarlavha', ru: 'Заголовок', en: 'Title'),
          autofocus: true,
        ),
        const SizedBox(height: 11),
        SfTextField(
          controller: description,
          label: _copy(
            context,
            uz: 'Tavsif',
            ru: 'Описание',
            en: 'Description',
          ),
          minLines: 3,
          maxLines: 7,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: saving ? null : onCancel,
              child: Text(
                _copy(context, uz: 'Bekor', ru: 'Отмена', en: 'Cancel'),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _copy(context, uz: 'Saqlash', ru: 'Сохранить', en: 'Save'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: SfType.eyebrow(color: SfTheme.colorsOf(context).muted),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final IconData icon;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: c.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: SfType.ui(size: 15, weight: FontWeight.w800, color: c.ink),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: SfType.mono(size: 10, color: c.muted)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: c.muted),
      title: Text(label, style: SfType.ui(size: 11.5, color: c.muted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 175),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(
                size: 11.5,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 5),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.muted2),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});
  final TaskComment comment;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SfAvatar(name: comment.authorName, size: 32),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        style: SfType.ui(size: 10.5, weight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      _dateTime(comment.createdAt),
                      style: SfType.mono(size: 8, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: SfType.ui(size: 11.5, color: c.ink2, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: SfType.ui(size: 10.5, color: c.ink2)),
          ),
          Text(subtitle, style: SfType.mono(size: 8, color: c.muted)),
        ],
      ),
    );
  }
}

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

String _dateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

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
