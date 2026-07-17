import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';

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
        title: 'So‘rovnomalar',
        subtitle:
            '${pending.length} ta kutilmoqda · ${submitted.length} ta yuborilgan',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (!canAnswer) ...[
            const SfHintCard(
              title: 'Faqat ko‘rish rejimi',
              message: 'Sizning rolingiz so‘rovnomalarga javob bera olmaydi.',
              tone: SfHintTone.info,
            ),
            const SizedBox(height: 14),
          ],
          if (state.surveys.isEmpty)
            const SfEmptyState(
              title: 'So‘rovnoma yo‘q',
              message: 'Yangi so‘rovnoma tayinlanganda shu yerda ko‘rinadi.',
            )
          else ...[
            Text('KUTILMOQDA', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              const SfHintCard(
                title: 'Hammasi tayyor',
                message: 'Hozir javob berilishi kerak bo‘lgan so‘rovnoma yo‘q.',
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
              Text('YUBORILGAN', style: SfType.eyebrow(color: c.muted)),
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
    return SfSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: enabled || survey.isSubmitted
            ? () => context.push(
                '/surveys/form?id=${Uri.encodeQueryComponent(survey.id)}',
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                      survey.title,
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
                survey.summary,
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
                    ? 'Yuborilgan · javoblar o‘zgarmaydi'
                    : 'Muddat: ${_dateLabel(survey.dueAt)}',
                style: SfType.ui(
                  size: 11,
                  weight: FontWeight.w600,
                  color: survey.isSubmitted ? c.success : c.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
