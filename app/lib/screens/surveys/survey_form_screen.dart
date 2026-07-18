import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';
import '../today/today_data.dart';

class SurveyFormScreen extends StatefulWidget {
  const SurveyFormScreen({super.key});

  @override
  State<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<SurveyFormScreen> {
  final Map<String, String> _answers = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, GlobalKey> _questionKeys = {};
  String? _loadedSurveyId;
  bool _saving = false;
  bool _dirty = false;
  bool _justSubmitted = false;

  SurveyAssignment? _survey(BuildContext context) {
    final surveys = AppScope.of(context).surveys;
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    if (id != null) {
      final matches = surveys.where((survey) => survey.id == id);
      if (matches.isNotEmpty) return matches.first;
    }
    return surveys.firstOrNull;
  }

  void _load(SurveyAssignment survey) {
    if (_loadedSurveyId == survey.id) return;
    _loadedSurveyId = survey.id;
    _answers
      ..clear()
      ..addAll(survey.answers);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _questionKeys.clear();
    for (final question in survey.questions) {
      _questionKeys[question.id] = GlobalKey();
      if (question.kind == SurveyQuestionKind.freeText) {
        _controllers[question.id] = TextEditingController(
          text: survey.answers[question.id] ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setAnswer(String questionId, String value) {
    setState(() {
      _answers[questionId] = value;
      _dirty = true;
    });
  }

  void _syncTextAnswers() {
    for (final entry in _controllers.entries) {
      _answers[entry.key] = entry.value.text.trim();
    }
  }

  Future<void> _saveAnswers(SurveyAssignment survey) async {
    final appState = AppScope.of(context);
    _syncTextAnswers();
    for (final question in survey.questions) {
      final answer = _answers[question.id]?.trim();
      if (answer != null && answer != survey.answers[question.id]) {
        await appState.answerSurvey(survey.id, question.id, answer);
      }
    }
  }

  Future<void> _saveDraft(SurveyAssignment survey) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await _saveAnswers(survey);
      if (!mounted) return;
      setState(() => _dirty = false);
      SfToast.show(
        context,
        title: staffTr(context, 'Qoralama saqlandi', 'Draft saved'),
        message: staffTr(
          context,
          'Barcha tanlovlaringiz ushbu qurilmada saqlandi.',
          'All of your selections were saved on this device.',
        ),
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

  Future<void> _submit(SurveyAssignment survey) async {
    final appState = AppScope.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    _syncTextAnswers();
    final missing = survey.questions
        .where(
          (question) =>
              question.required &&
              (_answers[question.id]?.trim().isEmpty ?? true),
        )
        .toList();
    if (missing.isNotEmpty) {
      final target = _questionKeys[missing.first.id]?.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: SfMotion.resolve(context, SfMotion.emphasized),
          curve: SfMotion.enter,
          alignment: .15,
        );
      }
      if (!mounted) return;
      SfToast.show(
        context,
        title: staffTr(
          context,
          'Yana ${missing.length} ta javob kerak',
          '${missing.length} more answer${missing.length == 1 ? '' : 's'} needed',
        ),
        message: staffTr(
          context,
          'Ajratib ko‘rsatilgan majburiy savolni to‘ldiring.',
          'Complete the highlighted required question.',
        ),
        tone: SfToastTone.warning,
      );
      return;
    }
    final confirmed = await showSfConfirmDialog(
      context,
      title: staffTr(
        context,
        'Javoblarni yuborish',
        'Submit answers',
        ru: 'Отправить ответы',
      ),
      message: staffTr(
        context,
        'Uchala javob ham tayyor. Yuborilgandan keyin so‘rovnoma faqat ko‘rish uchun ochiladi.',
        'All three answers are ready. After submission, the survey will be read-only.',
        ru: 'Все три ответа готовы. После отправки опрос будет доступен только для просмотра.',
      ),
      cancelLabel: staffTr(
        context,
        'Yana tekshirish',
        'Review again',
        ru: 'Проверить ещё раз',
      ),
      confirmLabel: staffTr(context, 'Yuborish', 'Submit', ru: 'Отправить'),
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      await _saveAnswers(survey);
      await appState.submitSurvey(survey.id);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _justSubmitted = true;
      });
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
    final survey = _survey(context);
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (survey == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(staffTr(context, 'So‘rovnoma', 'Survey')),
        ),
        body: SfEmptyState(
          title: staffTr(context, 'So‘rovnoma topilmadi', 'Survey not found'),
        ),
      );
    }
    _load(survey);
    final editable =
        !survey.isSubmitted && state.can(StaffCapability.answerSurveys);
    final answered = survey.questions
        .where(
          (question) => (_answers[question.id]?.trim().isNotEmpty ?? false),
        )
        .length;
    final complete = answered == survey.questions.length;

    return SfScaffold(
      dismissKeyboardOnDrag: true,
      top: SfNavBar(
        title: staffTr(context, 'Haftalik so‘rovnoma', 'Weekly survey'),
        subtitle: survey.isSubmitted
            ? staffTr(
                context,
                'Yuborilgan · faqat ko‘rish',
                'Submitted · read-only',
              )
            : staffTr(
                context,
                '$answered/${survey.questions.length} javob tayyor',
                '$answered/${survey.questions.length} answers ready',
              ),
        leading: IconButton(
          tooltip: staffTr(context, 'Orqaga', 'Back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (_dirty && editable)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  staffTr(context, 'SAQLANMAGAN', 'UNSAVED'),
                  style: SfType.eyebrow(color: c.warn, size: 8),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          _SurveyIntro(
            title: _surveyTitle(context, survey),
            summary: _surveySummary(context, survey),
            answered: answered,
            total: survey.questions.length,
            submitted: survey.isSubmitted,
          ),
          if (_justSubmitted || survey.isSubmitted) ...[
            const SizedBox(height: 13),
            const _SubmissionSuccess(),
          ],
          const SizedBox(height: 18),
          for (final entry in survey.questions.asMap().entries) ...[
            _QuestionCard(
              key: _questionKeys[entry.value.id],
              number: entry.key + 1,
              question: entry.value,
              value: _answers[entry.value.id],
              controller: _controllers[entry.value.id],
              enabled: editable,
              onChanged: (value) => _setAnswer(entry.value.id, value),
            ),
            const SizedBox(height: 12),
          ],
          if (!editable) ...[
            const SizedBox(height: 4),
            SfButton(
              block: true,
              kind: SfButtonKind.ghost,
              label: staffTr(
                context,
                'So‘rovnomalar ro‘yxatiga qaytish',
                'Back to surveys',
              ),
              leading: SfIcons.arrowL,
              onPressed: () => context.pop(),
            ),
          ],
        ],
      ),
      bottom: editable
          ? _SurveyActionBar(
              saving: _saving,
              complete: complete,
              dirty: _dirty,
              answered: answered,
              total: survey.questions.length,
              onSave: () => _saveDraft(survey),
              onSubmit: () => _submit(survey),
            )
          : null,
    );
  }
}

class _SurveyIntro extends StatelessWidget {
  const _SurveyIntro({
    required this.title,
    required this.summary,
    required this.answered,
    required this.total,
    required this.submitted,
  });
  final String title;
  final String summary;
  final int answered;
  final int total;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final progress = total == 0 ? 0.0 : answered / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, Color.lerp(c.surface, c.accentSoft, .62)!],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.aiBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: submitted ? c.successSoft : c.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(
                  submitted
                      ? Icons.task_alt_rounded
                      : Icons.fact_check_outlined,
                  color: submitted ? c.success : c.primary,
                ),
              ),
              const Spacer(),
              Text(
                submitted
                    ? staffTr(context, 'YAKUNLANDI', 'COMPLETED')
                    : staffTr(context, '2 DAQIQA', '2 MINUTES'),
                style: SfType.eyebrow(
                  color: submitted ? c.success : c.primary,
                  size: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: SfType.ui(
              size: 22,
              weight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -.42,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: SfType.ui(size: 12.5, color: c.ink2, height: 1.5),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: SfMotion.resolve(context, SfMotion.emphasized),
                  curve: SfMotion.enter,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(9),
                    color: submitted ? c.success : c.primary,
                    backgroundColor: c.surface3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: SfMotion.resolve(context, SfMotion.quick),
                child: Text(
                  '$answered/$total',
                  key: ValueKey(answered),
                  style: SfType.mono(
                    size: 11,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmissionSuccess extends StatelessWidget {
  const _SubmissionSuccess();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: SfMotion.resolve(context, SfMotion.emphasized),
      curve: SfMotion.emphasizedCurve,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: .94 + value * .06, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.successSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.success.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: c.success, size: 27),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffTr(
                      context,
                      'Javoblar qabul qilindi',
                      'Answers received',
                    ),
                    style: SfType.ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    staffTr(
                      context,
                      'Rahmat — javoblaringiz metodika jamoasiga yuborildi.',
                      'Thank you — your answers were sent to the methodology team.',
                    ),
                    style: SfType.ui(size: 10.5, color: c.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.value,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final int number;
  final SurveyQuestion question;
  final String? value;
  final TextEditingController? controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final answered = value?.trim().isNotEmpty ?? false;
    return AnimatedContainer(
      duration: SfMotion.resolve(context, SfMotion.standard),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: answered ? c.primary.withValues(alpha: .48) : c.border,
          width: answered ? 1.4 : 1,
        ),
        boxShadow: answered
            ? [
                BoxShadow(
                  color: c.primary.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: SfMotion.resolve(context, SfMotion.quick),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: answered ? c.primary : c.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: SfMotion.resolve(context, SfMotion.quick),
                  child: answered
                      ? const Icon(
                          SfIcons.check,
                          key: ValueKey(true),
                          color: Color(0xFFFFFCF5),
                          size: 16,
                        )
                      : Text(
                          '$number',
                          key: const ValueKey(false),
                          style: SfType.mono(
                            size: 11,
                            weight: FontWeight.w800,
                            color: c.ink2,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                staffTr(context, 'SAVOL $number', 'QUESTION $number'),
                style: SfType.eyebrow(color: c.muted, size: 9),
              ),
              const Spacer(),
              if (question.required)
                Text(
                  staffTr(context, 'MAJBURIY', 'REQUIRED'),
                  style: SfType.eyebrow(color: c.danger, size: 8),
                ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            _questionPrompt(context, question),
            style: SfType.ui(
              size: 14,
              weight: FontWeight.w800,
              color: c.ink,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (question.kind == SurveyQuestionKind.freeText)
            SfTextField(
              key: Key('survey-text-${question.id}'),
              controller: controller,
              enabled: enabled,
              hint: staffTr(
                context,
                'Fikringizni ochiq yozing…',
                'Share your thoughts openly…',
              ),
              minLines: 4,
              maxLines: 7,
              maxLength: 1000,
              onChanged: onChanged,
            )
          else if (question.kind == SurveyQuestionKind.rating)
            _RatingControl(
              questionId: question.id,
              options: question.options,
              value: value,
              enabled: enabled,
              onChanged: onChanged,
            )
          else
            _ChoiceControl(
              questionId: question.id,
              options: question.options,
              value: value,
              enabled: enabled,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _RatingControl extends StatelessWidget {
  const _RatingControl({
    required this.questionId,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String questionId;
  final List<String> options;
  final String? value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final captions = staffIsEnglish(context)
        ? const ['Very low', 'Low', 'Average', 'Good', 'Excellent']
        : const ['Juda past', 'Past', 'O‘rtacha', 'Yaxshi', 'A’lo'];
    return Column(
      children: [
        Row(
          children: [
            for (final option in options.asMap().entries) ...[
              if (option.key > 0) const SizedBox(width: 7),
              Expanded(
                child: SfPressable(
                  key: Key('survey-$questionId-rating-${option.value}'),
                  semanticLabel:
                      '${option.value}, ${captions[option.key.clamp(0, 4)]}',
                  selected: value == option.value,
                  enabled: enabled,
                  haptic: true,
                  onPressed: enabled ? () => onChanged(option.value) : null,
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedContainer(
                    duration: SfMotion.resolve(context, SfMotion.standard),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: value == option.value ? c.primary : c.surface2,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: value == option.value ? c.primary : c.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option.value,
                      style: SfType.mono(
                        size: 16,
                        weight: FontWeight.w800,
                        color: value == option.value ? c.bg : c.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              staffTr(context, 'Juda past', 'Very low'),
              style: SfType.ui(size: 9, color: c.muted),
            ),
            const Spacer(),
            Text(
              staffTr(context, 'A’lo', 'Excellent'),
              style: SfType.ui(size: 9, color: c.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceControl extends StatelessWidget {
  const _ChoiceControl({
    required this.questionId,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String questionId;
  final List<String> options;
  final String? value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      children: [
        for (final option in options) ...[
          SfPressable(
            key: Key('survey-$questionId-choice-$option'),
            semanticLabel: _optionLabel(context, questionId, option),
            selected: value == option,
            enabled: enabled,
            haptic: true,
            onPressed: enabled ? () => onChanged(option) : null,
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: SfMotion.resolve(context, SfMotion.standard),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: value == option
                    ? c.primarySoft.withValues(alpha: .62)
                    : c.surface2.withValues(alpha: .52),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: value == option ? c.primary : c.border,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: SfMotion.resolve(context, SfMotion.quick),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: value == option ? c.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: value == option ? c.primary : c.borderStrong,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: value == option
                        ? Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: c.bg,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _optionLabel(context, questionId, option),
                      style: SfType.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (option != options.last) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _SurveyActionBar extends StatelessWidget {
  const _SurveyActionBar({
    required this.saving,
    required this.complete,
    required this.dirty,
    required this.answered,
    required this.total,
    required this.onSave,
    required this.onSubmit,
  });
  final bool saving;
  final bool complete;
  final bool dirty;
  final int answered;
  final int total;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 11),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.ink.withValues(alpha: .07),
            blurRadius: 20,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 320;
          final progress = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                complete
                    ? Icons.task_alt_rounded
                    : Icons.pending_actions_rounded,
                size: 18,
                color: complete ? c.success : c.warn,
              ),
              const SizedBox(width: 6),
              Text(
                complete
                    ? staffTr(context, 'Yuborishga tayyor', 'Ready to submit')
                    : staffTr(
                        context,
                        '$answered/$total javob',
                        '$answered/$total answers',
                      ),
                style: SfType.ui(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: c.ink2,
                ),
              ),
            ],
          );
          final buttons = Row(
            children: [
              Expanded(
                child: SfButton(
                  kind: SfButtonKind.ghost,
                  block: true,
                  height: 48,
                  label: saving
                      ? staffTr(context, 'Saqlanmoqda…', 'Saving…')
                      : dirty
                      ? staffTr(context, 'Qoralamani saqlash', 'Save draft')
                      : staffTr(context, 'Saqlandi', 'Saved'),
                  onPressed: saving || !dirty ? null : onSave,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SfButton(
                  key: const Key('survey-submit-button'),
                  block: true,
                  height: 48,
                  label: saving
                      ? staffTr(context, 'Yuborilmoqda…', 'Submitting…')
                      : staffTr(
                          context,
                          'Javoblarni yuborish',
                          'Submit answers',
                        ),
                  trailing: SfIcons.send,
                  onPressed: saving ? null : onSubmit,
                ),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [progress, const SizedBox(height: 8), buttons],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [progress, const SizedBox(height: 8), buttons],
          );
        },
      ),
    );
  }
}

String _surveyTitle(BuildContext context, SurveyAssignment survey) =>
    staffTr(context, survey.title, switch (survey.id) {
      'survey-001' => 'Weekly teaching experience',
      'survey-002' => 'AI assistant quality',
      _ => survey.title,
    });

String _surveySummary(BuildContext context, SurveyAssignment survey) =>
    staffTr(context, survey.summary, switch (survey.id) {
      'survey-001' => 'Three quick questions about lessons and teaching tools.',
      'survey-002' => 'Rate the new assistant features.',
      _ => survey.summary,
    });

String _questionPrompt(BuildContext context, SurveyQuestion question) =>
    staffTr(context, question.prompt, switch (question.id) {
      'survey-001-q1' => 'How effective were your lessons this week?',
      'survey-001-q2' => 'Which teaching tool was the most useful?',
      'survey-001-q3' => 'What would you like to improve next week?',
      'survey-002-q1' => 'Are the suggestions useful in practice?',
      _ => question.prompt,
    });

String _optionLabel(BuildContext context, String _, String option) =>
    staffTr(context, option, switch (option) {
      'Doska' => 'Whiteboard',
      'Slaydlar' => 'Slides',
      'Kartalar' => 'Cards',
      'AI yordamchi' => 'AI assistant',
      'Ha' => 'Yes',
      'Ba’zan' => 'Sometimes',
      'Yo‘q' => 'No',
      _ => option,
    });
