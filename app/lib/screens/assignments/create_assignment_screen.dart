import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../features/assignments/assignment_controller.dart';
import '../../features/assignments/assignment_l10n.dart';
import '../../features/assignments/assignment_models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key, this.controller});

  final AssignmentController? controller;

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _instructions = TextEditingController();
  String? _cohortId;
  AssignmentResponseType _responseType = AssignmentResponseType.document;
  DateTime _dueAt = DateTime.now().add(const Duration(days: 3));
  bool _publishing = false;

  AssignmentController get _controller =>
      widget.controller ?? AssignmentController.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.maybeOf(context);
    _controller.initialize(
      ownerId: app?.session?.userId ?? _controller.ownerId ?? 'demo-teacher',
    );
    _cohortId ??= _controller.availableCohorts.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final l = AssignmentL10n.of(context);
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _dueAt.isBefore(now) ? now : _dueAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      helpText: l.text('Topshirish muddatini tanlang', 'Choose a due date'),
    );
    if (value != null && mounted) {
      setState(
        () => _dueAt = DateTime(value.year, value.month, value.day, 23, 59),
      );
    }
  }

  Future<void> _publish() async {
    final l = AssignmentL10n.of(context);
    if (_controller.isRestoring || _controller.restoreError != null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cohort = _controller.availableCohorts.firstWhere(
      (item) => item.id == _cohortId,
    );
    final confirmed = await showSfConfirmDialog(
      context,
      title: l.text('Topshiriq e’lon qilinsinmi?', 'Publish assignment?'),
      message: l.text(
        '${cohort.name} guruhiga ${_formatDate(_dueAt)} muddat bilan yuboriladi.',
        'This will be sent to ${l.cohortName(cohort.name)} with a due date of ${_formatDate(_dueAt)}.',
      ),
      cancelLabel: l.text('Tekshirish', 'Review'),
      confirmLabel: l.text('E’lon qilish', 'Publish'),
    );
    if (!confirmed || !mounted) return;
    setState(() => _publishing = true);
    try {
      final assignment = await _controller.createAssignment(
        title: _title.text,
        instructions: _instructions.text,
        cohortId: cohort.id,
        responseType: _responseType,
        dueAt: _dueAt,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: l.text('Topshiriq e’lon qilindi', 'Assignment published'),
        message:
            '${l.cohortName(assignment.cohortName)} · ${l.responseLabel(assignment.responseType)}',
        tone: SfToastTone.success,
      );
      context.pop(assignment.id);
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
    final app = AppScope.maybeOf(context);
    final canTeach = app?.can(StaffCapability.teachLessons) ?? true;
    final c = SfTheme.colorsOf(context);
    final l = AssignmentL10n.of(context);
    if (!canTeach) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l.text('Yangi topshiriq', 'New assignment')),
        ),
        body: SfEmptyState(
          title: l.text('Ruxsat mavjud emas', 'Permission unavailable'),
          message: l.text(
            'Topshiriq e’lon qilish o‘qituvchi ish maydoniga tegishli.',
            'Publishing assignments is limited to the teacher workspace.',
          ),
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => SfScaffold(
        top: SfNavBar(
          title: l.text('Yangi topshiriq', 'New assignment'),
          subtitle: l.text('Qoralama', 'Draft'),
          leading: IconButton(
            tooltip: l.text('Bekor qilish', 'Cancel'),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: _controller.isRestoring
            ? SfLoadingState(
                label: l.text(
                  'Topshiriqlar tiklanmoqda…',
                  'Restoring assignments…',
                ),
              )
            : _controller.restoreError != null
            ? SfErrorState(
                title: l.text(
                  'Topshiriq yaratilmaydi',
                  'Assignment cannot be created',
                ),
                message: '${_controller.restoreError}',
                retryLabel: l.text('Qayta urinish', 'Try again'),
                onRetry: _controller.retryRestore,
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                  children: [
                    SfHintCard(
                      title: l.text(
                        'Javob turi aniq bo‘lsin',
                        'Make the response type clear',
                      ),
                      message: l.text(
                        'Matn, hujjat yoki rasm tanlovi o‘quvchiga aynan qanday natija topshirishini ko‘rsatadi.',
                        'Text, document, or photo tells students exactly what they need to submit.',
                      ),
                      tone: SfHintTone.info,
                    ),
                    const SizedBox(height: 18),
                    SfTextField(
                      key: const Key('assignment-title-field'),
                      controller: _title,
                      label: l.text('Topshiriq nomi', 'Assignment title'),
                      hint: l.text(
                        'Masalan: Kvadrat tenglamalar · mashqlar 1–12',
                        'For example: Quadratic equations · exercises 1–12',
                      ),
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value?.trim().length ?? 0) < 4
                          ? l.text(
                              'Nomni aniqroq kiriting',
                              'Enter a clearer title',
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    SfTextField(
                      key: const Key('assignment-instructions-field'),
                      controller: _instructions,
                      label: l.text('Ko‘rsatma', 'Instructions'),
                      hint: l.text(
                        'Natija, material va topshirish usulini tushuntiring',
                        'Explain the outcome, materials, and submission method',
                      ),
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 1000,
                      validator: (value) => (value?.trim().length ?? 0) < 8
                          ? l.text(
                              'Qisqa ko‘rsatma yozing',
                              'Add brief instructions',
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.text('GURUH', 'GROUP'),
                      style: SfType.eyebrow(color: c.muted),
                    ),
                    const SizedBox(height: 7),
                    DropdownButtonFormField<String>(
                      key: const Key('assignment-cohort-field'),
                      initialValue: _cohortId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.groups_2_outlined),
                      ),
                      items: [
                        for (final cohort in _controller.availableCohorts)
                          DropdownMenuItem(
                            value: cohort.id,
                            child: Text(l.cohortName(cohort.name)),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _cohortId = value ?? _cohortId),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.text('JAVOB TURI', 'RESPONSE TYPE'),
                      style: SfType.eyebrow(color: c.muted),
                    ),
                    const SizedBox(height: 7),
                    SfSegmentedControl<AssignmentResponseType>(
                      expanded: true,
                      value: _responseType,
                      segments: [
                        SfSegment(
                          value: AssignmentResponseType.text,
                          label: l.text('Matn', 'Text'),
                          icon: Icons.text_fields_rounded,
                        ),
                        SfSegment(
                          value: AssignmentResponseType.document,
                          label: l.text('Hujjat', 'Document'),
                          icon: Icons.attach_file_rounded,
                        ),
                        SfSegment(
                          value: AssignmentResponseType.photo,
                          label: l.text('Rasm', 'Photo'),
                          icon: Icons.photo_camera_outlined,
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _responseType = value),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.text('MUDDAT', 'DUE DATE'),
                      style: SfType.eyebrow(color: c.muted),
                    ),
                    const SizedBox(height: 7),
                    OutlinedButton.icon(
                      key: const Key('assignment-due-date-button'),
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
        bottom: _controller.isRestoring || _controller.restoreError != null
            ? null
            : Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: SfButton(
                  key: const Key('assignment-publish-button'),
                  kind: SfButtonKind.primary,
                  block: true,
                  height: 50,
                  label: _publishing
                      ? l.text('E’lon qilinmoqda…', 'Publishing…')
                      : l.text('E’lon qilish', 'Publish'),
                  trailing: Icons.send_rounded,
                  onPressed: _publishing ? null : _publish,
                ),
              ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
