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

class GiveCardScreen extends StatefulWidget {
  const GiveCardScreen({super.key});

  @override
  State<GiveCardScreen> createState() => _GiveCardScreenState();
}

class _GiveCardScreenState extends State<GiveCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  CardKind _kind = CardKind.praise;
  AttendanceEntry? _student;
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit(AttendanceSheet sheet) async {
    final student = _student;
    if (student == null || !(_formKey.currentState?.validate() ?? false)) {
      SfToast.show(
        context,
        message: 'O‘quvchi va sababni kiriting.',
        tone: SfToastTone.warning,
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Kartani berasizmi?'),
            content: Text(
              '${student.studentName} uchun ${_kind == CardKind.praise ? 'ijobiy karta' : 'ogohlantirish'} yoziladi.',
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text('Bekor'),
              ),
              FilledButton(
                onPressed: () => dialogContext.pop(true),
                child: const Text('Tasdiqlash'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      final card = await AppScope.of(context).issueCard(
        studentId: student.studentId,
        studentName: student.studentName,
        cohortName: '${sheet.cohortName} ${sheet.lessonName}',
        kind: _kind,
        label: _kind == CardKind.praise ? 'Yulduz karta' : 'Ogohlantirish',
        reason: _reason.text,
      );
      if (!mounted) return;
      context.pop();
      SfToast.show(
        context,
        title: 'Karta berildi',
        message: '${card.studentName} · ${card.label}',
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
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final sheet = state.attendanceSheets.firstOrNull;
    if (!state.can(StaffCapability.issueCards)) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Karta berish'),
        ),
        body: const SfEmptyState(
          title: 'Ruxsat mavjud emas',
          message: 'Sizning rolingiz o‘quvchilarga karta bera olmaydi.',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    if (sheet == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Karta berish'),
        ),
        body: const SfEmptyState(title: 'O‘quvchilar topilmadi'),
      );
    }
    return SfScaffold(
      top: SfNavBar(
        title: 'Karta berish',
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            const SfHintCard(
              title: 'Aniq va foydali izoh yozing',
              message:
                  'Karta o‘quvchining tarixida saqlanadi. Shaxsga emas, kuzatilgan harakatga baho bering.',
              tone: SfHintTone.info,
            ),
            const SizedBox(height: 18),
            Text('O‘QUVCHI', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            DropdownButtonFormField<AttendanceEntry>(
              initialValue: _student,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              hint: const Text('O‘quvchini tanlang'),
              items: [
                for (final entry in sheet.entries)
                  DropdownMenuItem(
                    value: entry,
                    child: Text(entry.studentName),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _student = value),
              validator: (value) => value == null ? 'O‘quvchini tanlang' : null,
            ),
            const SizedBox(height: 18),
            Text('KARTA TURI', style: SfType.eyebrow(color: c.muted)),
            const SizedBox(height: 7),
            SfSegmentedControl<CardKind>(
              expanded: true,
              value: _kind,
              segments: const [
                SfSegment(
                  value: CardKind.praise,
                  label: 'Ijobiy',
                  icon: Icons.star_rounded,
                ),
                SfSegment(
                  value: CardKind.warning,
                  label: 'Ogohlantirish',
                  icon: Icons.flag_rounded,
                ),
              ],
              onChanged: (value) => setState(() => _kind = value),
            ),
            const SizedBox(height: 18),
            SfTextField(
              controller: _reason,
              label: 'Sabab',
              hint: _kind == CardKind.praise
                  ? 'Masalan: murakkab misolni mustaqil yechdi'
                  : 'Masalan: uy vazifasini ikkinchi marta bajarmadi',
              helper: 'Kamida 4 ta belgi · ko‘pi bilan 240 ta',
              minLines: 3,
              maxLines: 5,
              maxLength: 240,
              validator: (value) => (value?.trim().length ?? 0) < 4
                  ? 'Sababni aniqroq yozing'
                  : null,
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _student == null
                  ? const SizedBox.shrink()
                  : SfSurfaceCard(
                      key: ValueKey('${_student!.studentId}-${_kind.name}'),
                      padding: const EdgeInsets.all(14),
                      color: _kind == CardKind.praise
                          ? c.accentSoft
                          : c.dangerSoft,
                      child: Row(
                        children: [
                          Icon(
                            _kind == CardKind.praise
                                ? Icons.star_rounded
                                : Icons.flag_rounded,
                            color: _kind == CardKind.praise
                                ? c.accentInk
                                : c.danger,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_student!.studentName} · ${_kind == CardKind.praise ? 'Yulduz karta' : 'Ogohlantirish'}',
                              style: SfType.ui(
                                size: 13,
                                weight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 50,
          label: _saving ? 'Saqlanmoqda…' : 'Kartani tasdiqlash',
          trailing: Icons.arrow_forward_rounded,
          onPressed: _saving ? null : () => _submit(sheet),
        ),
      ),
    );
  }
}
