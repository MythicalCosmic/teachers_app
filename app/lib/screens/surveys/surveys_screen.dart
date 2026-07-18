import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_pressable.dart';
import '../today/today_data.dart';

class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final pending = state.surveys
        .where((survey) => !survey.isSubmitted)
        .toList();
    final submitted = state.surveys
        .where((survey) => survey.isSubmitted)
        .toList();
    final canAnswer = state.can(StaffCapability.answerSurveys);
    return SfScaffold(
      top: SfLargeAppBar(
        title: staffTr(context, 'So‘rovnomalar', 'Surveys'),
        subtitle: staffTr(
          context,
          '${pending.length} ta kutilmoqda · ${submitted.length} ta yuborilgan',
          '${pending.length} pending · ${submitted.length} submitted',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (!canAnswer) ...[
            SfHintCard(
              title: staffTr(context, 'Faqat ko‘rish rejimi', 'Read-only mode'),
              message: staffTr(
                context,
                'Sizning rolingiz so‘rovnomalarga javob bera olmaydi.',
                'Your role cannot answer surveys.',
              ),
              tone: SfHintTone.info,
            ),
            const SizedBox(height: 14),
          ],
          if (state.surveys.isEmpty)
            SfEmptyState(
              title: staffTr(context, 'So‘rovnoma yo‘q', 'No surveys'),
              message: staffTr(
                context,
                'Yangi so‘rovnoma tayinlanganda shu yerda ko‘rinadi.',
                'New assigned surveys will appear here.',
              ),
            )
          else ...[
            Text(
              staffTr(context, 'KUTILMOQDA', 'PENDING'),
              style: SfType.eyebrow(color: c.muted),
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              SfHintCard(
                title: staffTr(context, 'Hammasi tayyor', 'All caught up'),
                message: staffTr(
                  context,
                  'Hozir javob berilishi kerak bo‘lgan so‘rovnoma yo‘q.',
                  'There are no surveys waiting for an answer.',
                ),
                tone: SfHintTone.success,
                compact: true,
              )
            else
              for (final survey in pending) ...[
                _SurveyCard(survey: survey, enabled: canAnswer),
                const SizedBox(height: 9),
              ],
            if (submitted.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                staffTr(context, 'YUBORILGAN', 'SUBMITTED'),
                style: SfType.eyebrow(color: c.muted),
              ),
              const SizedBox(height: 8),
              for (final survey in submitted) ...[
                _SurveyCard(survey: survey, enabled: false),
                const SizedBox(height: 9),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.survey, required this.enabled});
  final SurveyAssignment survey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final progress = survey.progress;
    return SfPressable(
      semanticLabel: _surveyListTitle(context, survey),
      haptic: true,
      onPressed: enabled || survey.isSubmitted
          ? () => context.push(
              '/surveys/form?id=${Uri.encodeQueryComponent(survey.id)}',
            )
          : null,
      borderRadius: BorderRadius.circular(20),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface2 : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: state.hovered ? c.primary : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: survey.isSubmitted ? c.successSoft : c.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    survey.isSubmitted
                        ? Icons.task_alt_rounded
                        : Icons.fact_check_outlined,
                    color: survey.isSubmitted ? c.success : c.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _surveyListTitle(context, survey),
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.muted),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              _surveyListSummary(context, survey),
              style: SfType.ui(size: 12, color: c.ink2, height: 1.4),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                    color: survey.isSubmitted ? c.success : c.primary,
                    backgroundColor: c.surface3,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${survey.answeredCount}/${survey.questions.length}',
                  style: SfType.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              survey.isSubmitted
                  ? staffTr(
                      context,
                      'Yuborilgan · javoblar o‘zgarmaydi',
                      'Submitted · answers are locked',
                    )
                  : staffTr(
                      context,
                      'Muddat: ${_dateLabel(survey.dueAt)}',
                      'Due: ${_dateLabel(survey.dueAt)}',
                    ),
              style: SfType.ui(
                size: 11,
                weight: FontWeight.w600,
                color: survey.isSubmitted ? c.success : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _surveyListTitle(BuildContext context, SurveyAssignment survey) =>
    staffTr(context, survey.title, switch (survey.id) {
      'survey-001' => 'Weekly teaching experience',
      'survey-002' => 'AI assistant quality',
      _ => survey.title,
    });

String _surveyListSummary(BuildContext context, SurveyAssignment survey) =>
    staffTr(context, survey.summary, switch (survey.id) {
      'survey-001' => 'Three quick questions about lessons and teaching tools.',
      'survey-002' => 'Rate the new assistant features.',
      _ => survey.summary,
    });
