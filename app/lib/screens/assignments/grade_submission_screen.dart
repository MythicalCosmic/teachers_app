import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../features/assignments/assignment_controller.dart';
import '../../features/assignments/assignment_l10n.dart';
import '../../features/assignments/assignment_models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class GradeSubmissionScreen extends StatefulWidget {
  const GradeSubmissionScreen({super.key, this.controller});

  final AssignmentController? controller;

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final _feedback = TextEditingController();
  AssignmentFeedbackStep _step = AssignmentFeedbackStep.ready;
  int _grade = 85;
  bool _saving = false;
  String? _loadedSubmissionKey;

  AssignmentController get _controller =>
      widget.controller ?? AssignmentController.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.maybeOf(context);
    _controller.initialize(
      ownerId: app?.session?.userId ?? _controller.ownerId ?? 'demo-teacher',
    );
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  void _syncDraft(AssignmentSubmission submission) {
    final key = '${submission.assignmentId}/${submission.studentId}';
    if (_loadedSubmissionKey == key) return;
    _loadedSubmissionKey = key;
    _feedback.text = submission.feedback;
    _step = submission.feedbackStep ?? AssignmentFeedbackStep.ready;
    _grade = submission.grade ?? 85;
  }

  Future<void> _save(
    StaffAssignment assignment,
    AssignmentSubmission submission,
  ) async {
    final l = AssignmentL10n.of(context);
    if (_feedback.text.trim().length < 8) {
      SfToast.show(
        context,
        message: l.text(
          'Fikrni aniqroq yozing.',
          'Write more specific feedback.',
        ),
        tone: SfToastTone.warning,
      );
      return;
    }
    final confirmed = await showSfConfirmDialog(
      context,
      title: submission.hasFeedback
          ? l.text('Fikr yangilansinmi?', 'Update feedback?')
          : l.text('Fikr yuborilsinmi?', 'Send feedback?'),
      message: l.text(
        '${submission.studentName} ushbu fikr, ${l.stepLabel(_step).toLowerCase()} holati va $_grade/100 bahoni ko‘radi.',
        '${submission.studentName} will see this feedback, the ${l.stepLabel(_step).toLowerCase()} next step, and a grade of $_grade/100.',
      ),
      cancelLabel: l.text('Tekshirish', 'Review'),
      confirmLabel: submission.hasFeedback
          ? l.text('Yangilash', 'Update')
          : l.text('Yuborish', 'Send'),
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      await _controller.saveFeedback(
        assignmentId: assignment.id,
        studentId: submission.studentId,
        feedback: _feedback.text,
        step: _step,
        grade: _grade,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: submission.hasFeedback
            ? l.text('Fikr yangilandi', 'Feedback updated')
            : l.text('Fikr yuborildi', 'Feedback sent'),
        message: '${submission.studentName} · $_grade/100',
        tone: SfToastTone.success,
      );
    } on Object catch (error) {
      if (mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAttachmentMetadata(AssignmentAttachment attachment) async {
    final c = SfTheme.colorsOf(context);
    final l = AssignmentL10n.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    attachment.mediaType.startsWith('image/')
                        ? Icons.image_outlined
                        : Icons.description_outlined,
                    color: c.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      style: SfType.ui(
                        size: 16,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MetadataRow(
                label: l.text('Turi', 'Type'),
                value: attachment.mediaType,
              ),
              _MetadataRow(
                label: l.text('Hajmi', 'Size'),
                value: attachment.formattedSize,
              ),
              if (attachment.pageCount != null)
                _MetadataRow(
                  label: l.text('Sahifalar', 'Pages'),
                  value: '${attachment.pageCount}',
                ),
              const SizedBox(height: 10),
              Text(
                l.attachmentSummary(attachment),
                style: SfType.ui(size: 13, color: c.ink2, height: 1.45),
              ),
              if (attachment.demoMetadataOnly) ...[
                const SizedBox(height: 14),
                SfHintCard(
                  title: l.text('Demo biriktirma', 'Demo attachment'),
                  message: l.text(
                    'Bu sinov ma’lumotida fayl baytlari mavjud emas. Faqat haqiqiy ko‘rinadigan nom, tur va hajm metadata sifatida saqlangan.',
                    'This demo record does not include file bytes. Only an honest file name, type, and size are stored as metadata.',
                  ),
                  tone: SfHintTone.warning,
                  compact: true,
                ),
              ],
              const SizedBox(height: 14),
              SfButton(
                block: true,
                kind: SfButtonKind.ink,
                label: l.text('Yopish', 'Close'),
                onPressed: () => sheetContext.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.maybeOf(context);
    final canTeach = app?.can(StaffCapability.teachLessons) ?? true;
    final l = AssignmentL10n.of(context);
    if (!canTeach) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(l.text('Topshiriq fikri', 'Assignment feedback')),
        ),
        body: SfEmptyState(
          title: l.text('Ruxsat mavjud emas', 'Permission unavailable'),
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final l = AssignmentL10n.of(context);
        final route = GoRouterState.of(context);
        final assignmentId = route.uri.queryParameters['assignmentId'];
        final studentId = route.uri.queryParameters['studentId'];
        final assignment = _controller.assignmentById(assignmentId);
        final submission = _controller.submissionById(assignmentId, studentId);
        if (_controller.isRestoring) {
          return _submissionScaffold(
            context,
            title: l.text('Topshiriq fikri', 'Assignment feedback'),
            body: SfLoadingState(
              label: l.text('Topshiriq tiklanmoqda…', 'Restoring assignment…'),
            ),
          );
        }
        if (_controller.restoreError != null) {
          return _submissionScaffold(
            context,
            title: l.text('Topshiriq fikri', 'Assignment feedback'),
            body: SfErrorState(
              title: l.text(
                'Topshiriq ochilmadi',
                'Assignment could not be opened',
              ),
              message: '${_controller.restoreError}',
              retryLabel: l.text('Qayta urinish', 'Try again'),
              onRetry: _controller.retryRestore,
            ),
          );
        }
        if (assignment == null || submission == null) {
          return _submissionScaffold(
            context,
            title: l.text('Topshiriq fikri', 'Assignment feedback'),
            body: SfEmptyState(
              title: l.text('Ish topilmadi', 'Submission not found'),
              message: l.text(
                'Topshiriq va o‘quvchi identifikatorini jarayon sahifasidan qayta tanlang.',
                'Choose the assignment and student again from the gradebook.',
              ),
              icon: Icons.assignment_late_outlined,
            ),
          );
        }
        if (!submission.isSubmitted) {
          return _submissionScaffold(
            context,
            title: l.assignmentTitle(assignment),
            subtitle: submission.studentName,
            body: SfEmptyState(
              title: l.text(
                'Ish hali topshirilmagan',
                'Work not submitted yet',
              ),
              message: l.text(
                'Topshirilmaguncha fikr va baho yuborib bo‘lmaydi.',
                'Feedback and a grade cannot be sent before submission.',
              ),
              icon: Icons.hourglass_empty_rounded,
            ),
          );
        }
        _syncDraft(submission);
        return _submissionScaffold(
          context,
          title: l.assignmentTitle(assignment),
          subtitle:
              '${submission.studentName} · ${l.cohortName(assignment.cohortName)}',
          body: _submissionBody(context, assignment, submission),
          bottom: _submissionBottom(context, assignment, submission),
        );
      },
    );
  }

  Widget _submissionBody(
    BuildContext context,
    StaffAssignment assignment,
    AssignmentSubmission submission,
  ) {
    final c = SfTheme.colorsOf(context);
    final l = AssignmentL10n.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        if (submission.hasFeedback) ...[
          SfHintCard(
            title: l.text(
              'Fikr yuborilgan · ${submission.grade}/100',
              'Feedback sent · ${submission.grade}/100',
            ),
            message: l.text(
              '${l.stepLabel(submission.feedbackStep ?? AssignmentFeedbackStep.ready)} holati saqlangan. Istasangiz fikr va bahoni yangilashingiz mumkin.',
              '${l.stepLabel(submission.feedbackStep ?? AssignmentFeedbackStep.ready)} is saved. You can update the feedback and grade at any time.',
            ),
            tone: SfHintTone.success,
          ),
          const SizedBox(height: 14),
        ],
        SfSurfaceCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.responseHeading(assignment.responseType),
                    style: SfType.eyebrow(color: c.muted),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime(submission.submittedAt!),
                    style: SfType.mono(size: 10, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  submission.responseText.isEmpty
                      ? l.text(
                          'O‘quvchi izoh qoldirmagan.',
                          'The student did not add a note.',
                        )
                      : l.submissionResponse(assignment, submission),
                  style: SfType.ui(size: 13, color: c.ink2, height: 1.5),
                ),
              ),
              if (assignment.responseType != AssignmentResponseType.text) ...[
                const SizedBox(height: 10),
                if (submission.attachment == null)
                  SfHintCard(
                    message: l.text(
                      'Bu demo javobda biriktirma metadata ham mavjud emas.',
                      'This demo response does not include attachment metadata.',
                    ),
                    tone: SfHintTone.warning,
                    compact: true,
                  )
                else
                  OutlinedButton.icon(
                    key: const Key('assignment-attachment-metadata'),
                    onPressed: () =>
                        _showAttachmentMetadata(submission.attachment!),
                    icon: Icon(
                      assignment.responseType == AssignmentResponseType.photo
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                    ),
                    label: Text(
                      '${submission.attachment!.fileName} · ${submission.attachment!.formattedSize}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SfAiSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SfAiBadge(label: l.text('Fikr yordamchisi', 'Feedback coach')),
              const SizedBox(height: 8),
              Text(
                l.text(
                  'Kuchli tomonni ayting, bitta aniq tuzatishni ko‘rsating va keyingi qadamni bering.',
                  'Name a strength, identify one precise correction, and provide the next step.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.text('KEYINGI HOLAT', 'NEXT STEP'),
          style: SfType.eyebrow(color: c.muted),
        ),
        const SizedBox(height: 7),
        SfSegmentedControl<AssignmentFeedbackStep>(
          expanded: true,
          value: _step,
          segments: [
            SfSegment(
              value: AssignmentFeedbackStep.ready,
              label: l.text('Tayyor', 'Ready'),
            ),
            SfSegment(
              value: AssignmentFeedbackStep.revise,
              label: l.text('Tuzatish', 'Revision'),
            ),
            SfSegment(
              value: AssignmentFeedbackStep.conference,
              label: l.text('Suhbat', 'Conference'),
            ),
          ],
          onChanged: (value) => setState(() => _step = value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l.text('BAHO', 'GRADE'),
                style: SfType.eyebrow(color: c.muted),
              ),
            ),
            Text(
              '$_grade/100',
              key: const Key('assignment-grade-value'),
              style: SfType.mono(
                size: 17,
                weight: FontWeight.w800,
                color: c.primary,
              ),
            ),
          ],
        ),
        Slider(
          key: const Key('assignment-grade-slider'),
          value: _grade.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '$_grade',
          onChanged: _saving
              ? null
              : (value) => setState(() => _grade = value.round()),
        ),
        const SizedBox(height: 10),
        SfTextField(
          key: const Key('assignment-feedback-field'),
          controller: _feedback,
          enabled: !_saving,
          label: l.text('Foydali fikr', 'Useful feedback'),
          hint: l.text(
            'Kuchli tomon, tuzatish va keyingi qadam…',
            'Strength, correction, and next step…',
          ),
          minLines: 4,
          maxLines: 7,
          maxLength: 800,
        ),
      ],
    );
  }

  Widget _submissionBottom(
    BuildContext context,
    StaffAssignment assignment,
    AssignmentSubmission submission,
  ) {
    final c = SfTheme.colorsOf(context);
    final l = AssignmentL10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SfButton(
        key: const Key('assignment-save-feedback'),
        kind: SfButtonKind.primary,
        block: true,
        height: 50,
        label: _saving
            ? l.text('Saqlanmoqda…', 'Saving…')
            : submission.hasFeedback
            ? l.text('Fikr va bahoni yangilash', 'Update feedback and grade')
            : l.text('Fikr va bahoni yuborish', 'Send feedback and grade'),
        leading: submission.hasFeedback
            ? Icons.sync_rounded
            : Icons.send_rounded,
        onPressed: _saving ? null : () => _save(assignment, submission),
      ),
    );
  }

  Widget _submissionScaffold(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget body,
    Widget? bottom,
  }) {
    final l = AssignmentL10n.of(context);
    return SfScaffold(
      top: SfNavBar(
        title: title,
        subtitle: subtitle,
        leading: IconButton(
          tooltip: l.text('Orqaga', 'Back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: body,
      bottom: bottom,
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: SfType.ui(size: 12, color: c.muted)),
          ),
          Text(
            value,
            style: SfType.mono(size: 12, weight: FontWeight.w700, color: c.ink),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
