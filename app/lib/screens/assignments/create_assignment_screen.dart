import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

enum _ResponseType { text, file, photo }

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  String _cohort = '9-B Algebra';
  _ResponseType _responseType = _ResponseType.file;
  DateTime _dueAt = DateTime.now().add(const Duration(days: 3));
  bool _publishing = false;

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      helpText: 'Topshirish muddatini tanlang',
    );
    if (value != null) {
      setState(
        () => _dueAt = DateTime(value.year, value.month, value.day, 23, 59),
      );
    }
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Topshiriq e’lon qilinsinmi?'),
            content: Text(
              '$_cohort guruhiga ${_formatDate(_dueAt)} muddat bilan yuboriladi.',
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text('Tekshirish'),
              ),
              FilledButton(
                onPressed: () => dialogContext.pop(true),
                child: const Text('E’lon qilish'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _publishing = true);
    try {
      final task = await AppScope.of(context).createTask(
        title: 'Topshiriq: ${_title.text.trim()}',
        description:
            '$_cohort · ${_responseLabel(_responseType)}\n${_instructions.text.trim()}',
        priority: TaskPriority.high,
        dueAt: _dueAt,
        checklist: const [
          'Topshiriqlarni kuzatish',
          'Har bir ishga yozma fikr yuborish',
        ],
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: 'Topshiriq e’lon qilindi',
        message: task.title.replaceFirst('Topshiriq: ', ''),
        tone: SfToastTone.success,
      );
      context.pop();
    } on Object catch (error) {
      if (mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (!state.can(StaffCapability.teachLessons) ||
        !state.can(StaffCapability.createTasks)) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Yangi topshiriq'),
        ),
        body: const SfEmptyState(
          title: 'Ruxsat mavjud emas',
          message: 'Topshiriq e’lon qilish o‘qituvchi ish maydoniga tegishli.',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return SfScaffold(
      top: SfNavBar(
        title: 'Yangi topshiriq',
        subtitle: 'Qoralama',
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
              title: 'Bahodan ko‘ra foydali fikr',
              message:
                  'Topshiriq jarayoni “topshirildi”, “fikr kutilmoqda” va “fikr yuborildi” holatlari bilan kuzatiladi.',
              tone: SfHintTone.info,
            ),
            const SizedBox(height: 18),
            SfTextField(
              controller: _title,
              label: 'Topshiriq nomi',
              hint: 'Masalan: Kvadrat tenglamalar · mashqlar 1–12',
              maxLength: 120,
              textInputAction: TextInputAction.next,
              validator: (value) => (value?.trim().length ?? 0) < 4
                  ? 'Nomni aniqroq kiriting'
                  : null,
            ),
            const SizedBox(height: 14),
            SfTextField(
              controller: _instructions,
              label: 'Ko‘rsatma',
              hint: 'Natija, material va topshirish usulini tushuntiring',
              minLines: 4,
              maxLines: 7,
              maxLength: 1000,
              validator: (value) => (value?.trim().length ?? 0) < 8
                  ? 'Qisqa ko‘rsatma yozing'
                  : null,
            ),
            const SizedBox(height: 16),
            Text('GURUH', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: _cohort,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: '9-B Algebra',
                  child: Text('9-B Algebra'),
                ),
                DropdownMenuItem(
                  value: '9-A Algebra',
                  child: Text('9-A Algebra'),
                ),
                DropdownMenuItem(
                  value: '11-B Tayyorlov',
                  child: Text('11-B Tayyorlov'),
                ),
              ],
              onChanged: (value) => setState(() => _cohort = value ?? _cohort),
            ),
            const SizedBox(height: 16),
            Text('JAVOB TURI', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            SfSegmentedControl<_ResponseType>(
              expanded: true,
              value: _responseType,
              segments: const [
                SfSegment(
                  value: _ResponseType.text,
                  label: 'Matn',
                  icon: Icons.text_fields_rounded,
                ),
                SfSegment(
                  value: _ResponseType.file,
                  label: 'Fayl',
                  icon: Icons.attach_file_rounded,
                ),
                SfSegment(
                  value: _ResponseType.photo,
                  label: 'Rasm',
                  icon: Icons.photo_camera_outlined,
                ),
              ],
              onChanged: (value) => setState(() => _responseType = value),
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
          label: _publishing ? 'E’lon qilinmoqda…' : 'E’lon qilish',
          trailing: Icons.send_rounded,
          onPressed: _publishing ? null : _publish,
        ),
      ),
    );
  }
}

String _responseLabel(_ResponseType type) => switch (type) {
  _ResponseType.text => 'Matnli javob',
  _ResponseType.file => 'Fayl yuklash',
  _ResponseType.photo => 'Rasm yuklash',
};

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
