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
      top: SfNavBar(
        title: staffTr(context, 'So‘rovnomalar', 'Surveys'),
        subtitle: staffTr(
          context,
          '${pending.length} ta kutilmoqda · ${submitted.length} ta yuborilgan',
          '${pending.length} pending · ${submitted.length} submitted',
        ),
        leading: IconButton(
          tooltip: staffTr(context, 'Orqaga', 'Back'),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/more'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: state.isProduction && state.formsLoading && state.surveys.isEmpty
          ? SfLoadingState(
              label: staffTr(
                context,
                'So‘rovnomalar yangilanmoqda…',
                'Refreshing forms…',
              ),
              motionEnabled: !state.settings.reducedMotion,
            )
          : state.isProduction &&
                state.formsError != null &&
                state.surveys.isEmpty
          ? SfErrorState(
              title: state.formsAvailable
                  ? staffTr(
                      context,
                      'So‘rovnomalarni yuklab bo‘lmadi',
                      'Forms could not be loaded',
                    )
                  : staffTr(
                      context,
                      'Bu rol uchun so‘rovnoma yo‘q',
                      'Forms are unavailable for this role',
                    ),
              message: state.formsError,
              onRetry: state.refreshForms,
            )
          : RefreshIndicator.adaptive(
              onRefresh: state.refreshForms,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  _SurveyOverview(
                    pending: pending.length,
                    submitted: submitted.length,
                  ),
                  const SizedBox(height: 14),
                  if (!canAnswer) ...[
                    SfHintCard(
                      title: staffTr(
                        context,
                        'Faqat ko‘rish rejimi',
                        'Read-only mode',
                      ),
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
                    _SurveyEmptyExperience(canAnswer: canAnswer)
                  else ...[
                    Text(
                      staffTr(context, 'KUTILMOQDA', 'PENDING'),
                      style: SfType.eyebrow(color: c.muted),
                    ),
                    const SizedBox(height: 8),
                    if (pending.isEmpty)
                      SfHintCard(
                        title: staffTr(
                          context,
                          'Hammasi tayyor',
                          'All caught up',
                        ),
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
            ),
    );
  }
}

class _SurveyOverview extends StatelessWidget {
  const _SurveyOverview({required this.pending, required this.submitted});

  final int pending;
  final int submitted;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
          child: _SurveyOverviewTile(
            key: const Key('survey-overview-pending'),
            icon: Icons.pending_actions_rounded,
            value: pending,
            label: staffTr(context, 'Kutilmoqda', 'Pending'),
            color: c.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _SurveyOverviewTile(
            key: const Key('survey-overview-submitted'),
            icon: Icons.task_alt_rounded,
            value: submitted,
            label: staffTr(context, 'Yuborilgan', 'Submitted'),
            color: c.success,
          ),
        ),
      ],
    );
  }
}

class _SurveyOverviewTile extends StatelessWidget {
  const _SurveyOverviewTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: SfType.mono(
                    size: 19,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(size: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyEmptyExperience extends StatelessWidget {
  const _SurveyEmptyExperience({required this.canAnswer});

  final bool canAnswer;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SfSurfaceCard(
          key: const Key('surveys-rich-empty-state'),
          color: c.primarySoft,
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.fact_check_outlined, color: c.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffTr(
                        context,
                        'Hozircha hammasi bajarilgan',
                        'You are all caught up',
                      ),
                      style: SfType.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      staffTr(
                        context,
                        canAnswer
                            ? 'Yangi so‘rovnoma tayinlanganda savollar va muddat shu yerda paydo bo‘ladi.'
                            : 'Sizga ko‘rish uchun so‘rovnoma tayinlansa, u shu yerda paydo bo‘ladi.',
                        canAnswer
                            ? 'Questions and the due date will appear here as soon as a survey is assigned.'
                            : 'A survey will appear here when one is assigned for you to view.',
                      ),
                      style: SfType.ui(size: 11.5, color: c.ink2, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SfSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffTr(context, 'Qanday ishlaydi', 'How it works'),
                style: SfType.ui(
                  size: 13.5,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 11),
              _SurveyGuideRow(
                icon: Icons.notifications_active_outlined,
                text: staffTr(
                  context,
                  'Yangi topshiriq kelganda ilova sizni ogohlantiradi.',
                  'The app alerts you when a new survey arrives.',
                ),
              ),
              const SizedBox(height: 10),
              _SurveyGuideRow(
                icon: Icons.lock_outline_rounded,
                text: staffTr(
                  context,
                  'Yuborilgan javoblar serverda xavfsiz saqlanadi.',
                  'Submitted answers are stored securely on the server.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurveyGuideRow extends StatelessWidget {
  const _SurveyGuideRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: c.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: SfType.ui(size: 11, color: c.ink2, height: 1.4),
          ),
        ),
      ],
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
