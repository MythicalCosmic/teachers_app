import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class SurveyFormScreen extends StatefulWidget {
  const SurveyFormScreen({super.key});

  @override
  State<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends State<SurveyFormScreen> {
  final Map<String, String> _answers = {};
  final Map<String, TextEditingController> _controllers = {};
  String? _loadedSurveyId;
  bool _saving = false;

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
    for (final question in survey.questions.where(
      (question) => question.kind == SurveyQuestionKind.freeText,
    )) {
      _controllers[question.id] = TextEditingController(
        text: survey.answers[question.id] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncTextAnswers() {
    for (final entry in _controllers.entries) {
      _answers[entry.key] = entry.value.text.trim();
    }
  }

  Future<bool> _saveAnswers(SurveyAssignment survey) async {
    final appState = AppScope.of(context);
    _syncTextAnswers();
    for (final question in survey.questions) {
      final answer = _answers[question.id]?.trim();
      if (answer != null &&
          answer.isNotEmpty &&
          answer != survey.answers[question.id]) {
        await appState.answerSurvey(survey.id, question.id, answer);
      }
    }
    return true;
  }

  Future<void> _saveDraft(SurveyAssignment survey) async {
    setState(() => _saving = true);
    try {
      await _saveAnswers(survey);
      if (!mounted) return;
      SfToast.show(
        context,
        title: 'Qoralama saqlandi',
        message: 'Keyinroq shu joydan davom etishingiz mumkin.',
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
    _syncTextAnswers();
    final missing = survey.questions.where(
      (question) =>
          question.required && (_answers[question.id]?.isEmpty ?? true),
    );
    if (missing.isNotEmpty) {
      SfToast.show(
        context,
        title: 'Javoblar yetishmaydi',
        message: '${missing.length} ta majburiy savolga javob bering.',
        tone: SfToastTone.warning,
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('So‘rovnomani yuborasizmi?'),
            content: const Text(
              'Yuborilgandan keyin javoblarni o‘zgartirib bo‘lmaydi.',
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text('Tekshirish'),
              ),
              FilledButton(
                onPressed: () => dialogContext.pop(true),
                child: const Text('Yuborish'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      await _saveAnswers(survey);
      await appState.submitSurvey(survey.id);
      if (!mounted) return;
      SfToast.show(
        context,
        title: 'Javoblar yuborildi',
        message: 'Rahmat. So‘rovnoma muvaffaqiyatli qabul qilindi.',
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

  @override
  Widget build(BuildContext context) {
    final survey = _survey(context);
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (survey == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('So‘rovnoma'),
        ),
        body: const SfEmptyState(title: 'So‘rovnoma topilmadi'),
      );
    }
    _load(survey);
    final editable =
        !survey.isSubmitted && state.can(StaffCapability.answerSurveys);
    final localAnswered = survey.questions
        .where(
          (question) => (_answers[question.id]?.trim().isNotEmpty ?? false),
        )
        .length;
    return SfScaffold(
      top: SfNavBar(
        title: 'So‘rovnoma',
        subtitle: survey.isSubmitted
            ? 'Yuborilgan'
            : '$localAnswered/${survey.questions.length} javob',
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          Text(
            survey.title,
            style: SfType.display(size: 26, color: c.ink, height: 1.15),
          ),
          const SizedBox(height: 7),
          Text(
            survey.summary,
            style: SfType.ui(size: 13, color: c.ink2, height: 1.45),
          ),
          const SizedBox(height: 12),
          SfHintCard(
            title: survey.isSubmitted
                ? 'Javoblar qabul qilingan'
                : 'Qoralama avtomatik emas',
            message: survey.isSubmitted
                ? 'Ushbu javoblar endi faqat ko‘rish uchun ochiq.'
                : 'Chiqishdan oldin “Qoralamani saqlash” tugmasini bosing.',
            tone: survey.isSubmitted ? SfHintTone.success : SfHintTone.info,
            compact: true,
          ),
          const SizedBox(height: 18),
          for (final entry in survey.questions.asMap().entries) ...[
            _QuestionCard(
              number: entry.key + 1,
              question: entry.value,
              value: _answers[entry.value.id],
              controller: _controllers[entry.value.id],
              enabled: editable,
              onChanged: (value) =>
                  setState(() => _answers[entry.value.id] = value),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottom: editable
          ? Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SfButton(
                      kind: SfButtonKind.ghost,
                      block: true,
                      height: 48,
                      label: 'Qoralamani saqlash',
                      onPressed: _saving ? null : () => _saveDraft(survey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SfButton(
                      kind: SfButtonKind.primary,
                      block: true,
                      height: 48,
                      label: _saving ? 'Saqlanmoqda…' : 'Yuborish',
                      onPressed: _saving ? null : () => _submit(survey),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
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
    return SfSurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVOL $number${question.required ? ' · MAJBURIY' : ''}',
            style: SfType.eyebrow(color: c.muted, size: 10),
          ),
          const SizedBox(height: 6),
          Text(
            question.prompt,
            style: SfType.ui(
              size: 14,
              weight: FontWeight.w700,
              color: c.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (question.kind == SurveyQuestionKind.freeText)
            SfTextField(
              controller: controller,
              enabled: enabled,
              hint: 'Javobingizni yozing',
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              onChanged: onChanged,
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final option in question.options)
                  ChoiceChip(
                    label: Text(option),
                    selected: value == option,
                    onSelected: enabled
                        ? (selected) => selected ? onChanged(option) : null
                        : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
