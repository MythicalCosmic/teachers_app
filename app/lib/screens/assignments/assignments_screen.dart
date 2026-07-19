import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../features/assignments/assignment_controller.dart';
import '../../features/assignments/assignment_l10n.dart';
import '../../features/assignments/assignment_models.dart';
import '../../router.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_tab_bar.dart';

enum _SubmissionFilter { all, needsFeedback, collecting, complete }

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key, this.controller});

  final AssignmentController? controller;

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  _SubmissionFilter _filter = _SubmissionFilter.all;

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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.maybeOf(context);
    final canTeach = app?.can(StaffCapability.teachLessons) ?? true;
    final c = SfTheme.colorsOf(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final l = AssignmentL10n.of(context);
        final assignments = _controller.assignments;
        final visible = assignments
            .where((item) {
              final progress = _controller.progressFor(item.id);
              return switch (_filter) {
                _SubmissionFilter.all => true,
                _SubmissionFilter.needsFeedback =>
                  progress == AssignmentProgressState.needsFeedback,
                _SubmissionFilter.collecting =>
                  progress == AssignmentProgressState.collecting,
                _SubmissionFilter.complete =>
                  progress == AssignmentProgressState.complete,
              };
            })
            .toList(growable: false);
        final featured = _controller.featuredAssignment;
        return SfScaffold(
          tab: SfTab.cohort,
          onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
          top: SfLargeAppBar(
            title: l.text('Topshiriqlar', 'Assignments'),
            subtitle: l.text(
              '${assignments.fold<int>(0, (sum, item) => sum + _controller.needsFeedbackCount(item.id))} ta fikr kutmoqda',
              '${assignments.fold<int>(0, (sum, item) => sum + _controller.needsFeedbackCount(item.id))} awaiting feedback',
            ),
            actions: [
              IconButton(
                tooltip: l.text('Jarayon ko‘rinishi', 'Open gradebook'),
                onPressed: featured == null
                    ? null
                    : () => _openGradebook(context, featured.id),
                icon: const Icon(Icons.view_kanban_outlined),
              ),
              if (canTeach)
                IconButton(
                  tooltip: l.text('Topshiriq yaratish', 'Create assignment'),
                  onPressed: () => context.push('/assignments/new'),
                  icon: const Icon(SfIcons.plus),
                ),
            ],
          ),
          body: _controller.isRestoring
              ? SfLoadingState(
                  label: l.text(
                    'Topshiriqlar tiklanmoqda…',
                    'Restoring assignments…',
                  ),
                  message: l.text(
                    _controller.isRemote
                        ? 'Serverdagi topshiriq va javoblar yuklanmoqda.'
                        : 'Saqlangan baho va fikrlar yuklanmoqda.',
                    _controller.isRemote
                        ? 'Loading assignments and submissions from the server.'
                        : 'Loading saved grades and feedback.',
                  ),
                )
              : _controller.restoreError != null
              ? SfErrorState(
                  title: l.text(
                    'Topshiriqlar ochilmadi',
                    'Assignments could not be opened',
                  ),
                  message: '${_controller.restoreError}',
                  retryLabel: l.text('Qayta urinish', 'Try again'),
                  onRetry: _controller.retryRestore,
                )
              : RefreshIndicator.adaptive(
                  onRefresh: _controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
                    children: [
                      SegmentedButton<_SubmissionFilter>(
                        segments: [
                          ButtonSegment(
                            value: _SubmissionFilter.all,
                            label: Text(l.text('Barchasi', 'All')),
                          ),
                          ButtonSegment(
                            value: _SubmissionFilter.needsFeedback,
                            label: Text(l.text('Fikr kerak', 'Needs feedback')),
                          ),
                          ButtonSegment(
                            value: _SubmissionFilter.collecting,
                            label: Text(l.text('Jarayonda', 'Collecting')),
                          ),
                          ButtonSegment(
                            value: _SubmissionFilter.complete,
                            label: Text(l.text('Yakun', 'Complete')),
                          ),
                        ],
                        selected: {_filter},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) =>
                            setState(() => _filter = selection.first),
                      ),
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        SfEmptyState(
                          title: l.text(
                            'Bu holatda topshiriq yo‘q',
                            'No assignments in this state',
                          ),
                          message: l.text(
                            'Boshqa filtrni tanlang.',
                            'Choose another filter.',
                          ),
                          compact: true,
                        )
                      else
                        for (final item in visible) ...[
                          _AssignmentCard(
                            assignment: item,
                            progress: _controller.progressFor(item.id),
                            submitted: _controller.submittedCount(item.id),
                            total: _controller.submissionsFor(item.id).length,
                            averageGrade: _controller.averageGrade(item.id),
                            canOpen: canTeach,
                            onOpen: () => _openGradebook(context, item.id),
                          ),
                          const SizedBox(height: 9),
                        ],
                    ],
                  ),
                ),
          bottom:
              canTeach &&
                  !_controller.isRestoring &&
                  _controller.restoreError == null
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
                    label: l.text('Yangi topshiriq', 'New assignment'),
                    leading: SfIcons.plus,
                    onPressed: () => context.push('/assignments/new'),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _openGradebook(BuildContext context, String assignmentId) {
    context.push(
      Uri(
        path: '/assignments/gradebook',
        queryParameters: {'assignmentId': assignmentId},
      ).toString(),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.progress,
    required this.submitted,
    required this.total,
    required this.averageGrade,
    required this.canOpen,
    required this.onOpen,
  });

  final StaffAssignment assignment;
  final AssignmentProgressState progress;
  final int submitted;
  final int total;
  final int? averageGrade;
  final bool canOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final l = AssignmentL10n.of(context);
    final status = switch (progress) {
      AssignmentProgressState.collecting => (
        SfPillTone.primary,
        l.text('Javoblar kelmoqda', 'Collecting responses'),
        c.primary,
      ),
      AssignmentProgressState.needsFeedback => (
        SfPillTone.warn,
        l.text('Fikr kutilmoqda', 'Feedback needed'),
        c.warn,
      ),
      AssignmentProgressState.complete => (
        SfPillTone.success,
        l.text('Fikr yuborilgan', 'Feedback shared'),
        c.success,
      ),
    };
    final submissionProgress = total == 0 ? 0.0 : submitted / total;
    return SfSurfaceCard(
      key: Key('assignment-card-${assignment.id}'),
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('assignment-open-${assignment.id}'),
        onTap: canOpen ? onOpen : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.assignmentTitle(assignment),
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ),
                  SfPill(label: status.$2, tone: status.$1),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${l.cohortName(assignment.cohortName)} · ${l.responseLabel(assignment.responseType)}',
                style: SfType.ui(size: 11, color: c.muted),
              ),
              const SizedBox(height: 11),
              LinearProgressIndicator(
                value: submissionProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
                color: status.$3,
                backgroundColor: c.surface3,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.text(
                        '$submitted/$total ta topshirildi',
                        '$submitted/$total submitted',
                      ),
                      style: SfType.mono(size: 10, color: c.muted),
                    ),
                  ),
                  if (averageGrade != null)
                    Text(
                      l.text(
                        'O‘rtacha $averageGrade/100',
                        'Average $averageGrade/100',
                      ),
                      style: SfType.mono(size: 10, color: c.ink2),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
