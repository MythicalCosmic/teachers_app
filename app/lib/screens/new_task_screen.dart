import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
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
  final List<String> _steps = [];
  TaskPriority _priority = TaskPriority.medium;
  DateTime _dueAt = DateTime.now().add(const Duration(days: 2));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _step.dispose();
    super.dispose();
  }

  void _addStep() {
    final value = _step.text.trim();
    if (value.isEmpty) return;
    if (_steps.contains(value)) {
      SfToast.show(
        context,
        message: 'Bu qadam allaqachon qo‘shilgan.',
        tone: SfToastTone.warning,
      );
      return;
    }
    setState(() {
      _steps.add(value);
      _step.clear();
    });
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Vazifa muddatini tanlang',
    );
    if (value != null) {
      setState(() => _dueAt = DateTime(value.year, value.month, value.day, 18));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step.text.trim().isNotEmpty) _addStep();
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Vazifa yaratilsinmi?'),
            content: Text(
              '${_title.text.trim()}\nMuddat: ${_formatDate(_dueAt)}',
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text('Tekshirish'),
              ),
              FilledButton(
                onPressed: () => dialogContext.pop(true),
                child: const Text('Yaratish'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      final task = await AppScope.of(context).createTask(
        title: _title.text,
        description: _description.text,
        priority: _priority,
        dueAt: _dueAt,
        checklist: _steps,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: 'Vazifa yaratildi',
        message: '${task.title} · ${_formatDate(task.dueAt)}',
        tone: SfToastTone.success,
      );
      context.pop();
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
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (!state.can(StaffCapability.createTasks)) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Yangi vazifa'),
        ),
        body: const SfEmptyState(
          title: 'Ruxsat mavjud emas',
          message: 'Sizning rolingiz vazifa yarata olmaydi.',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return SfScaffold(
      top: SfNavBar(
        title: 'Yangi vazifa',
        leading: IconButton(
          tooltip: 'Bekor qilish',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          children: [
            const SfHintCard(
              message:
                  'Aniq natija, real muddat va kichik qadamlar vazifani bajarishni osonlashtiradi.',
              tone: SfHintTone.info,
            ),
            const SizedBox(height: 18),
            SfTextField(
              controller: _title,
              label: 'Vazifa nomi',
              hint: 'Masalan: Haftalik hisobotni yakunlash',
              maxLength: 120,
              textInputAction: TextInputAction.next,
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Kamida 3 ta belgi kiriting'
                  : null,
            ),
            const SizedBox(height: 14),
            SfTextField(
              controller: _description,
              label: 'Izoh',
              hint: 'Natija va kerakli ma’lumotlarni yozing',
              minLines: 3,
              maxLines: 5,
              maxLength: 600,
            ),
            const SizedBox(height: 16),
            Text('MUHIMLIK', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            SfSegmentedControl<TaskPriority>(
              expanded: true,
              value: _priority,
              segments: const [
                SfSegment(value: TaskPriority.low, label: 'Past'),
                SfSegment(value: TaskPriority.medium, label: 'O‘rta'),
                SfSegment(value: TaskPriority.high, label: 'Yuqori'),
                SfSegment(value: TaskPriority.urgent, label: 'Shoshilinch'),
              ],
              onChanged: (value) => setState(() => _priority = value),
            ),
            const SizedBox(height: 16),
            Text('MUDDAT', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(_formatDate(_dueAt)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 18),
            Text('QADAMLAR', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SfTextField(
                    controller: _step,
                    hint: 'Bitta kichik qadam',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Qadam qo‘shish',
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final entry in _steps.asMap().entries)
                ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    child: Text('${entry.key + 1}'),
                  ),
                  title: Text(entry.value),
                  trailing: IconButton(
                    tooltip: 'Olib tashlash',
                    onPressed: () => setState(() => _steps.removeAt(entry.key)),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
            ],
          ],
        ),
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 50,
          label: _saving ? 'Yaratilmoqda…' : 'Vazifani yaratish',
          trailing: Icons.arrow_forward_rounded,
          onPressed: _saving ? null : _submit,
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
