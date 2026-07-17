import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
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
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  _SubmissionFilter _filter = _SubmissionFilter.all;

  static const _seed = [
    _Assignment(
      'Kvadrat tenglamalar',
      '9-B Algebra',
      24,
      7,
      _SubmissionState.needsFeedback,
    ),
    _Assignment(
      'Funksiyalar grafigi',
      '9-A Algebra',
      22,
      18,
      _SubmissionState.collecting,
    ),
    _Assignment(
      'Yozma ish · Geometriya',
      '10-V',
      19,
      12,
      _SubmissionState.collecting,
    ),
    _Assignment(
      'Olimpiada mashqlari',
      '11-B Tayyorlov',
      13,
      13,
      _SubmissionState.feedbackShared,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final fromTasks = state.tasks
        .where((task) => task.title.startsWith('Topshiriq: '))
        .map(
          (task) => _Assignment(
            task.title.substring('Topshiriq: '.length),
            task.description.isEmpty ? 'Mening guruhim' : task.description,
            0,
            0,
            _SubmissionState.collecting,
          ),
        );
    final all = [...fromTasks, ..._seed];
    final visible = all
        .where((item) {
          return switch (_filter) {
            _SubmissionFilter.all => true,
            _SubmissionFilter.needsFeedback =>
              item.state == _SubmissionState.needsFeedback,
            _SubmissionFilter.collecting =>
              item.state == _SubmissionState.collecting,
            _SubmissionFilter.complete =>
              item.state == _SubmissionState.feedbackShared,
          };
        })
        .toList(growable: false);
    final canTeach = state.can(StaffCapability.teachLessons);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: SfLargeAppBar(
        title: 'Topshiriqlar',
        subtitle:
            '${all.where((item) => item.state == _SubmissionState.needsFeedback).length} ta fikr kutmoqda',
        actions: [
          IconButton(
            tooltip: 'Jarayon ko‘rinishi',
            onPressed: () => context.push('/assignments/gradebook'),
            icon: const Icon(Icons.view_kanban_outlined),
          ),
          if (canTeach)
            IconButton(
              tooltip: 'Topshiriq yaratish',
              onPressed: () => context.push('/assignments/new'),
              icon: const Icon(SfIcons.plus),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          SegmentedButton<_SubmissionFilter>(
            segments: const [
              ButtonSegment(
                value: _SubmissionFilter.all,
                label: Text('Barchasi'),
              ),
              ButtonSegment(
                value: _SubmissionFilter.needsFeedback,
                label: Text('Fikr kerak'),
              ),
              ButtonSegment(
                value: _SubmissionFilter.collecting,
                label: Text('Jarayonda'),
              ),
              ButtonSegment(
                value: _SubmissionFilter.complete,
                label: Text('Yakun'),
              ),
            ],
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _filter = selection.first),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const SfEmptyState(
              title: 'Bu holatda topshiriq yo‘q',
              message: 'Boshqa filtrni tanlang.',
              compact: true,
            )
          else
            for (final item in visible) ...[
              _AssignmentCard(item: item, canOpen: canTeach),
              const SizedBox(height: 9),
            ],
        ],
      ),
      bottom: canTeach
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
                label: 'Yangi topshiriq',
                leading: SfIcons.plus,
                onPressed: () => context.push('/assignments/new'),
              ),
            )
          : null,
    );
  }
}

enum _SubmissionState { collecting, needsFeedback, feedbackShared }

class _Assignment {
  const _Assignment(
    this.title,
    this.cohort,
    this.total,
    this.submitted,
    this.state,
  );
  final String title;
  final String cohort;
  final int total;
  final int submitted;
  final _SubmissionState state;
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.item, required this.canOpen});
  final _Assignment item;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final status = switch (item.state) {
      _SubmissionState.collecting => (
        SfPillTone.primary,
        'Javoblar kelmoqda',
        c.primary,
      ),
      _SubmissionState.needsFeedback => (
        SfPillTone.warn,
        'Fikr kutilmoqda',
        c.warn,
      ),
      _SubmissionState.feedbackShared => (
        SfPillTone.success,
        'Fikr yuborilgan',
        c.success,
      ),
    };
    final progress = item.total == 0 ? 0.0 : item.submitted / item.total;
    return SfSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: canOpen ? () => context.push('/assignments/grade') : null,
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
                      item.title,
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
              Text(item.cohort, style: SfType.ui(size: 11, color: c.muted)),
              const SizedBox(height: 11),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
                color: status.$3,
                backgroundColor: c.surface3,
              ),
              const SizedBox(height: 6),
              Text(
                item.total == 0
                    ? 'Hali topshirilmagan'
                    : '${item.submitted}/${item.total} ta topshirildi',
                style: SfType.mono(size: 10, color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
