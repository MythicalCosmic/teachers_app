import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../l10n/sf_l10n.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_adaptive_dialog.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _step = TextEditingController();
  final _tag = TextEditingController();
  final List<String> _steps = [];
  final List<String> _tags = [];
  TaskPriority _priority = TaskPriority.medium;
  DateTime _dueAt = DateTime.now().add(const Duration(days: 2));
  _TaskTemplate _template = _TaskTemplate.blank;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _step.dispose();
    _tag.dispose();
    super.dispose();
  }

  void _applyTemplate(_TaskTemplate template) {
    setState(() {
      _template = template;
      _steps.clear();
      _tags.clear();
      switch (template) {
        case _TaskTemplate.blank:
          _title.clear();
          _description.clear();
          _priority = TaskPriority.medium;
          break;
        case _TaskTemplate.lesson:
          _title.text = _copy(
            context,
            uz: 'Keyingi darsni rejalashtirish',
            ru: 'Спланировать следующий урок',
            en: 'Plan the next lesson',
          );
          _description.text = _copy(
            context,
            uz: 'Maqsad, faoliyat, tekshiruv va yakuniy refleksiyani tayyorlash.',
            ru: 'Подготовить цель, активность, проверку и итоговую рефлексию.',
            en: 'Prepare the objective, activities, checks and closing reflection.',
          );
          _steps.addAll([
            _copy(
              context,
              uz: 'Dars maqsadini yozish',
              ru: 'Сформулировать цель',
              en: 'Define the learning objective',
            ),
            _copy(
              context,
              uz: 'Materiallarni biriktirish',
              ru: 'Прикрепить материалы',
              en: 'Attach learning materials',
            ),
            _copy(
              context,
              uz: 'Mini-tekshiruv yaratish',
              ru: 'Создать мини-проверку',
              en: 'Create a quick understanding check',
            ),
          ]);
          _tags.addAll(['Dars', 'Reja']);
          _priority = TaskPriority.high;
          break;
        case _TaskTemplate.assessment:
          _title.text = _copy(
            context,
            uz: 'Baholash natijalarini tahlil qilish',
            ru: 'Проанализировать результаты',
            en: 'Review assessment results',
          );
          _description.text = _copy(
            context,
            uz: 'Natijalarni guruh bo‘yicha ko‘rib, yordam kerak o‘quvchilarni aniqlash.',
            ru: 'Проверить результаты группы и выделить учеников, которым нужна поддержка.',
            en: 'Review group results and identify students who need support.',
          );
          _steps.addAll([
            _copy(
              context,
              uz: 'Natijalarni tekshirish',
              ru: 'Проверить результаты',
              en: 'Review results',
            ),
            _copy(
              context,
              uz: 'Xato mavzularni ajratish',
              ru: 'Выделить сложные темы',
              en: 'Identify difficult concepts',
            ),
            _copy(
              context,
              uz: 'Qayta o‘qitish rejasini tuzish',
              ru: 'Составить план повторения',
              en: 'Create a reteaching plan',
            ),
          ]);
          _tags.addAll(['Tahlil', 'Baholash']);
          _priority = TaskPriority.high;
          break;
        case _TaskTemplate.followUp:
          _title.text = _copy(
            context,
            uz: 'O‘quvchi bo‘yicha qayta aloqa',
            ru: 'Обратная связь по ученику',
            en: 'Student follow-up',
          );
          _description.text = _copy(
            context,
            uz: 'Kuzatuvlarni jamlang va keyingi aniq qadamni belgilang.',
            ru: 'Соберите наблюдения и определите следующий конкретный шаг.',
            en: 'Gather observations and agree on one clear next step.',
          );
          _steps.addAll([
            _copy(
              context,
              uz: 'Davomat va baholarni ko‘rish',
              ru: 'Проверить посещаемость и оценки',
              en: 'Review attendance and grades',
            ),
            _copy(
              context,
              uz: 'Kuzatuv yozish',
              ru: 'Записать наблюдения',
              en: 'Document observations',
            ),
            _copy(
              context,
              uz: 'Keyingi qadamni belgilash',
              ru: 'Определить следующий шаг',
              en: 'Set the next step',
            ),
          ]);
          _tags.addAll(['Follow-up']);
          _priority = TaskPriority.medium;
          break;
      }
    });
  }

  void _addStep() {
    final value = _step.text.trim();
    if (value.isEmpty || _steps.contains(value)) return;
    setState(() {
      _steps.add(value);
      _step.clear();
    });
  }

  void _addTag() {
    final value = _tag.text.trim();
    if (value.isEmpty ||
        _tags.any((tag) => tag.toLowerCase() == value.toLowerCase())) {
      return;
    }
    setState(() {
      _tags.add(value);
      _tag.clear();
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: _copy(
        context,
        uz: 'Vazifa muddatini tanlang',
        ru: 'Выберите срок задачи',
        en: 'Choose a due date',
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (!mounted) return;
    final resolved = time ?? TimeOfDay.fromDateTime(_dueAt);
    setState(
      () => _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        resolved.hour,
        resolved.minute,
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step.text.trim().isNotEmpty) _addStep();
    if (_tag.text.trim().isNotEmpty) _addTag();
    final approved = await showSfConfirmDialog(
      context,
      title: _copy(
        context,
        uz: 'Vazifa yaratilsinmi?',
        ru: 'Создать задачу?',
        en: 'Create this task?',
      ),
      message:
          '${_title.text.trim()}\n${_formatDate(_dueAt)} · ${_steps.length} ${_copy(context, uz: 'qadam', ru: 'подзадач', en: 'items')}',
      confirmLabel: _copy(context, uz: 'Yaratish', ru: 'Создать', en: 'Create'),
    );
    if (!approved || !mounted) return;
    setState(() => _saving = true);
    try {
      final task = await AppScope.of(context).createTask(
        title: _title.text,
        description: _description.text,
        priority: _priority,
        dueAt: _dueAt,
        checklist: _steps,
        tags: _tags,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: _copy(
          context,
          uz: 'Sahifa yaratildi',
          ru: 'Страница создана',
          en: 'Page created',
        ),
        message: task.title,
        tone: SfToastTone.success,
      );
      context.pushReplacement('/tasks/detail?id=${task.id}');
    } on Object catch (error) {
      if (mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (!app.can(StaffCapability.createTasks)) {
      return SfScaffold(
        top: SfNavBar(
          title: context.tr('new_task'),
          leading: const BackButton(),
        ),
        body: SfEmptyState(
          title: _copy(
            context,
            uz: 'Ruxsat mavjud emas',
            ru: 'Нет доступа',
            en: 'No access',
          ),
          message: _copy(
            context,
            uz: 'Sizning rolingiz vazifa yarata olmaydi.',
            ru: 'Ваша роль не может создавать задачи.',
            en: 'Your role cannot create tasks.',
          ),
          icon: Icons.lock_outline_rounded,
        ),
      );
    }

    return SfScaffold(
      dismissKeyboardOnTap: true,
      top: SfNavBar(
        title: context.tr('new_task'),
        leading: IconButton(
          tooltip: context.tr('cancel'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: Text(
              _copy(context, uz: 'Yaratish', ru: 'Создать', en: 'Create'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 108),
          children: [
            Text(
              _copy(
                context,
                uz: 'SHABLONDAN BOSHLASH',
                ru: 'НАЧАТЬ С ШАБЛОНА',
                en: 'START FROM A TEMPLATE',
              ),
              style: SfType.eyebrow(color: c.muted),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              key: const ValueKey('new-task-template-picker'),
              builder: (context, constraints) {
                const gap = 8.0;
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final useTwoColumns =
                    constraints.maxWidth < 340 || textScale > 1.3;
                final columns = useTwoColumns ? 2 : 4;
                final tileWidth =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;
                final tileHeight = useTwoColumns ? 86.0 : 92.0;
                final templates = <Widget>[
                  _TemplateTile(
                    template: _TaskTemplate.blank,
                    selected: _template == _TaskTemplate.blank,
                    icon: Icons.note_add_outlined,
                    label: _copy(
                      context,
                      uz: 'Bo‘sh',
                      ru: 'Пустая',
                      en: 'Blank',
                    ),
                    onTap: _applyTemplate,
                  ),
                  _TemplateTile(
                    template: _TaskTemplate.lesson,
                    selected: _template == _TaskTemplate.lesson,
                    icon: Icons.school_outlined,
                    label: _copy(
                      context,
                      uz: 'Dars rejasi',
                      ru: 'План урока',
                      en: 'Lesson plan',
                    ),
                    onTap: _applyTemplate,
                  ),
                  _TemplateTile(
                    template: _TaskTemplate.assessment,
                    selected: _template == _TaskTemplate.assessment,
                    icon: Icons.analytics_outlined,
                    label: _copy(
                      context,
                      uz: 'Baholash',
                      ru: 'Оценивание',
                      en: 'Assessment',
                    ),
                    onTap: _applyTemplate,
                  ),
                  _TemplateTile(
                    template: _TaskTemplate.followUp,
                    selected: _template == _TaskTemplate.followUp,
                    icon: Icons.person_search_outlined,
                    label: _copy(
                      context,
                      uz: 'Follow-up',
                      ru: 'Follow-up',
                      en: 'Follow-up',
                    ),
                    onTap: _applyTemplate,
                  ),
                ];
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final template in templates)
                      SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: template,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: c.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _copy(
                            context,
                            uz: 'Yangi ish sahifasi',
                            ru: 'Новая рабочая страница',
                            en: 'New work page',
                          ),
                          style: SfType.ui(
                            size: 16,
                            weight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SfTextField(
                    controller: _title,
                    label: _copy(
                      context,
                      uz: 'Sahifa nomi',
                      ru: 'Название страницы',
                      en: 'Page title',
                    ),
                    hint: _copy(
                      context,
                      uz: 'Aniq natijani yozing',
                      ru: 'Опишите ожидаемый результат',
                      en: 'Name the outcome clearly',
                    ),
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? _copy(
                            context,
                            uz: 'Kamida 3 ta belgi kiriting',
                            ru: 'Введите не менее 3 символов',
                            en: 'Enter at least 3 characters',
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SfTextField(
                    controller: _description,
                    label: _copy(
                      context,
                      uz: 'Tavsif',
                      ru: 'Описание',
                      en: 'Description',
                    ),
                    hint: _copy(
                      context,
                      uz: 'Kontekst, natija va foydali havolalarni yozing',
                      ru: 'Добавьте контекст, результат и полезные ссылки',
                      en: 'Add context, the outcome and useful links',
                    ),
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 900,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _copy(
                      context,
                      uz: 'XUSUSIYATLAR',
                      ru: 'СВОЙСТВА',
                      en: 'PROPERTIES',
                    ),
                    style: SfType.eyebrow(color: c.muted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _copy(
                      context,
                      uz: 'Muhimlik',
                      ru: 'Приоритет',
                      en: 'Priority',
                    ),
                    style: SfType.ui(size: 11, color: c.muted),
                  ),
                  const SizedBox(height: 6),
                  SfSegmentedControl<TaskPriority>(
                    expanded: true,
                    value: _priority,
                    segments: [
                      SfSegment(
                        value: TaskPriority.low,
                        label: _copy(
                          context,
                          uz: 'Past',
                          ru: 'Низк.',
                          en: 'Low',
                        ),
                      ),
                      SfSegment(
                        value: TaskPriority.medium,
                        label: _copy(
                          context,
                          uz: 'O‘rta',
                          ru: 'Сред.',
                          en: 'Medium',
                        ),
                      ),
                      SfSegment(
                        value: TaskPriority.high,
                        label: _copy(
                          context,
                          uz: 'Yuqori',
                          ru: 'Выс.',
                          en: 'High',
                        ),
                      ),
                      SfSegment(
                        value: TaskPriority.urgent,
                        label: _copy(
                          context,
                          uz: 'Shosh.',
                          ru: 'Срочно',
                          en: 'Urgent',
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _priority = value),
                  ),
                  const SizedBox(height: 13),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: c.primary,
                        size: 19,
                      ),
                    ),
                    title: Text(
                      _copy(context, uz: 'Muddat', ru: 'Срок', en: 'Due date'),
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                    subtitle: Text(
                      _formatDate(_dueAt),
                      style: SfType.ui(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _copy(
                            context,
                            uz: 'QADAMLAR',
                            ru: 'ПОДЗАДАЧИ',
                            en: 'CHECKLIST',
                          ),
                          style: SfType.eyebrow(color: c.muted),
                        ),
                      ),
                      Text(
                        '${_steps.length}',
                        style: SfType.mono(size: 10, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final entry in _steps.asMap().entries)
                    Dismissible(
                      key: ValueKey('${entry.key}-${entry.value}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          setState(() => _steps.removeAt(entry.key)),
                      background: Container(
                        color: c.dangerSoft,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: c.danger,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: c.primarySoft,
                          child: Text(
                            '${entry.key + 1}',
                            style: SfType.mono(size: 9, color: c.primary),
                          ),
                        ),
                        title: Text(
                          entry.value,
                          style: SfType.ui(size: 11.5, weight: FontWeight.w600),
                        ),
                        trailing: Icon(
                          Icons.drag_indicator_rounded,
                          color: c.muted2,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _step,
                          onSubmitted: (_) => _addStep(),
                          decoration: InputDecoration(
                            hintText: _copy(
                              context,
                              uz: 'Yangi qadam…',
                              ru: 'Новая подзадача…',
                              en: 'New checklist item…',
                            ),
                            prefixIcon: const Icon(Icons.add_rounded),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _addStep,
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _copy(context, uz: 'TEGLAR', ru: 'ТЕГИ', en: 'TAGS'),
                    style: SfType.eyebrow(color: c.muted),
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final tag in _tags)
                          InputChip(
                            label: Text(tag),
                            avatar: const Icon(Icons.tag_rounded, size: 14),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                          ),
                      ],
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tag,
                          onSubmitted: (_) => _addTag(),
                          decoration: InputDecoration(
                            hintText: _copy(
                              context,
                              uz: 'Masalan: Hisobot',
                              ru: 'Например: Отчёт',
                              en: 'For example: Report',
                            ),
                            prefixIcon: const Icon(Icons.tag_outlined),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SfHintCard(
              title: _copy(context, uz: 'Maslahat', ru: 'Совет', en: 'Tip'),
              message: _copy(
                context,
                uz: 'Aniq natija, real muddat va 3–5 kichik qadam vazifani bajarishni osonlashtiradi.',
                ru: 'Чёткий результат, реалистичный срок и 3–5 шагов упрощают выполнение.',
                en: 'A clear outcome, realistic date and 3–5 small steps make work easier to finish.',
              ),
              tone: SfHintTone.info,
              compact: true,
            ),
          ],
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 52,
          label: _saving
              ? _copy(
                  context,
                  uz: 'Yaratilmoqda…',
                  ru: 'Создание…',
                  en: 'Creating…',
                )
              : _copy(
                  context,
                  uz: 'Vazifa sahifasini yaratish',
                  ru: 'Создать страницу задачи',
                  en: 'Create task page',
                ),
          leading: Icons.auto_awesome_rounded,
          onPressed: _saving ? null : _submit,
        ),
      ),
    );
  }
}

enum _TaskTemplate { blank, lesson, assessment, followUp }

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final _TaskTemplate template;
  final bool selected;
  final IconData icon;
  final String label;
  final ValueChanged<_TaskTemplate> onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      key: ValueKey('new-task-template-${template.name}'),
      semanticLabel: label,
      onPressed: () => onTap(template),
      selected: selected,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: selected ? c.primary : c.muted),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(
                size: 10,
                weight: FontWeight.w700,
                color: selected ? c.primary : c.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

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
