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
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key, this.controller});

  final AssignmentController? controller;

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  AssignmentSubmissionStatus? _filter;
  String? _remindingStudentId;

  AssignmentController get _controller =>
      widget.controller ?? AssignmentController.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.maybeOf(context);
    _controller.initialize(
      ownerId: app?.session?.userId ?? _controller.ownerId ?? 'demo-teacher',
      api: app?.backendApi,
    );
  }

  Future<void> _remind(
    StaffAssignment assignment,
    AssignmentSubmission submission,
  ) async {
    final l = AssignmentL10n.of(context);
    final confirmed = await showSfConfirmDialog(
      context,
      title: l.text('Eslatma yuborilsinmi?', 'Send reminder?'),
      message: l.text(
        '${submission.studentName}ga “${assignment.title}” muddati haqida xabar yuboriladi.',
        '${submission.studentName} will receive a due-date reminder for “${l.assignmentTitle(assignment)}”.',
      ),
      cancelLabel: l.text('Bekor', 'Cancel'),
      confirmLabel: l.text('Yuborish', 'Send'),
    );
    if (!confirmed || !mounted) return;
    setState(() => _remindingStudentId = submission.studentId);
    try {
      await _controller.sendReminder(
        assignmentId: assignment.id,
        studentId: submission.studentId,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: l.text('Eslatma yuborildi', 'Reminder sent'),
        message: submission.studentName,
        tone: SfToastTone.success,
      );
    } on Object catch (error) {
      if (mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _remindingStudentId = null);
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
          title: Text(l.text('Jarayon', 'Gradebook')),
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
        final routeAssignmentId = GoRouterState.of(
          context,
        ).uri.queryParameters['assignmentId'];
        final assignment =
            _controller.assignmentById(routeAssignmentId) ??
            _controller.featuredAssignment;
        if (_controller.isRestoring) {
          return _gradebookScaffold(
            context,
            title: l.text('Topshiriq jarayoni', 'Assignment gradebook'),
            subtitle: l.text(
              'Saqlangan holat yuklanmoqda',
              'Loading saved progress',
            ),
            body: SfLoadingState(
              label: l.text('Jarayon tiklanmoqda…', 'Restoring gradebook…'),
            ),
          );
        }
        if (_controller.restoreError != null) {
          return _gradebookScaffold(
            context,
            title: l.text('Topshiriq jarayoni', 'Assignment gradebook'),
            body: SfErrorState(
              title: l.text(
                'Jarayon ochilmadi',
                'Gradebook could not be opened',
              ),
              message: '${_controller.restoreError}',
              retryLabel: l.text('Qayta urinish', 'Try again'),
              onRetry: _controller.retryRestore,
            ),
          );
        }
        if (assignment == null ||
            (routeAssignmentId != null &&
                _controller.assignmentById(routeAssignmentId) == null)) {
          return _gradebookScaffold(
            context,
            title: l.text('Topshiriq jarayoni', 'Assignment gradebook'),
            body: SfEmptyState(
              title: l.text('Topshiriq topilmadi', 'Assignment not found'),
              message: l.text(
                'Topshiriqlar ro‘yxatidan qayta tanlang.',
                'Choose it again from the assignments list.',
              ),
              icon: Icons.assignment_late_outlined,
            ),
          );
        }
        final submissions = _controller.submissionsFor(assignment.id);
        final visible = submissions
            .where((item) => _filter == null || item.status == _filter)
            .toList(growable: false);
        final completed = _controller.feedbackCompleteCount(assignment.id);
        final average = _controller.averageGrade(assignment.id);
        return _gradebookScaffold(
          context,
          title: l.assignmentTitle(assignment),
          subtitle: l.text(
            '$completed/${submissions.length} ta fikr yakunlangan',
            '$completed/${submissions.length} feedback reviews completed',
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              SfHintCard(
                title:
                    '${l.cohortName(assignment.cohortName)} · ${l.responseLabel(assignment.responseType)}',
                message: average == null
                    ? l.text(
                        'Baho hali berilmagan. Har bir topshiriq yozma fikr va 0–100 baho bilan yakunlanadi.',
                        'No grades yet. Each submission is completed with written feedback and a 0–100 grade.',
                      )
                    : l.text(
                        'Joriy o‘rtacha baho $average/100. Fikr, keyingi qadam va baho birga saqlanadi.',
                        'Current average: $average/100. Feedback, next step, and grade are saved together.',
                      ),
                tone: SfHintTone.info,
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      key: const Key('gradebook-filter-all'),
                      label: Text(l.text('Hammasi', 'All')),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 6),
                    for (final status in AssignmentSubmissionStatus.values) ...[
                      ChoiceChip(
                        key: Key('gradebook-filter-${status.name}'),
                        label: Text(l.statusLabel(status)),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                SfEmptyState(
                  title: l.text(
                    'Bu holatda o‘quvchi yo‘q',
                    'No students in this state',
                  ),
                  compact: true,
                )
              else
                for (final submission in visible) ...[
                  SfSurfaceCard(
                    key: Key('gradebook-student-${submission.studentId}'),
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        SfAvatar(name: submission.studentName, size: 38),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                submission.studentName,
                                style: SfType.ui(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                              Text(
                                _submissionDetail(l, submission),
                                style: SfType.ui(size: 10.5, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              context,
                              submission.status,
                            ).withValues(alpha: .11),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            submission.grade == null
                                ? l.statusLabel(submission.status)
                                : '${submission.grade}/100',
                            style: SfType.ui(
                              size: 10,
                              weight: FontWeight.w800,
                              color: _statusColor(context, submission.status),
                            ),
                          ),
                        ),
                        if (submission.status ==
                                AssignmentSubmissionStatus.notSubmitted &&
                            _controller.supportsReminders)
                          submission.reminderSentAt != null
                              ? IconButton(
                                  tooltip: l.text(
                                    'Eslatma yuborilgan',
                                    'Reminder sent',
                                  ),
                                  onPressed: null,
                                  icon: const Icon(
                                    Icons.notifications_active_rounded,
                                  ),
                                )
                              : IconButton(
                                  key: Key(
                                    'gradebook-remind-${submission.studentId}',
                                  ),
                                  tooltip: l.text(
                                    'Eslatma yuborish',
                                    'Send reminder',
                                  ),
                                  onPressed:
                                      _remindingStudentId ==
                                          submission.studentId
                                      ? null
                                      : () => _remind(assignment, submission),
                                  icon: const Icon(
                                    Icons.notifications_active_outlined,
                                  ),
                                )
                        else
                          IconButton(
                            key: Key('gradebook-open-${submission.studentId}'),
                            tooltip: submission.hasFeedback
                                ? l.text(
                                    'Fikrni ko‘rish yoki yangilash',
                                    'View or update feedback',
                                  )
                                : l.text('Ishni baholash', 'Grade submission'),
                            onPressed: () => _openSubmission(
                              context,
                              assignment.id,
                              submission.studentId,
                            ),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _gradebookScaffold(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget body,
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
    );
  }

  void _openSubmission(
    BuildContext context,
    String assignmentId,
    String studentId,
  ) {
    context.push(
      Uri(
        path: '/assignments/grade',
        queryParameters: {'assignmentId': assignmentId, 'studentId': studentId},
      ).toString(),
    );
  }
}

String _submissionDetail(AssignmentL10n l, AssignmentSubmission submission) {
  if (submission.reminderSentAt != null && !submission.isSubmitted) {
    return l.text(
      'Eslatma yuborilgan · ${_formatTime(submission.reminderSentAt!)}',
      'Reminder sent · ${_formatTime(submission.reminderSentAt!)}',
    );
  }
  if (submission.submittedAt == null) {
    return l.text('Hali topshirilmagan', 'Not submitted yet');
  }
  if (submission.feedbackSentAt != null) {
    return l.text(
      'Fikr ${_formatTime(submission.feedbackSentAt!)} yuborilgan',
      'Feedback sent · ${_formatTime(submission.feedbackSentAt!)}',
    );
  }
  return l.text(
    'Topshirildi · ${_formatTime(submission.submittedAt!)}',
    'Submitted · ${_formatTime(submission.submittedAt!)}',
  );
}

String _formatTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

Color _statusColor(BuildContext context, AssignmentSubmissionStatus status) {
  final c = SfTheme.colorsOf(context);
  return switch (status) {
    AssignmentSubmissionStatus.notSubmitted => c.danger,
    AssignmentSubmissionStatus.submitted => c.primary,
    AssignmentSubmissionStatus.feedbackNeeded => c.warn,
    AssignmentSubmissionStatus.feedbackShared => c.success,
    AssignmentSubmissionStatus.revisionRequested => c.warn,
    AssignmentSubmissionStatus.conferenceRequested => c.accent,
  };
}
