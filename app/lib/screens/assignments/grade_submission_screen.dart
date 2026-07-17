import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
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

enum _FeedbackStatus { ready, revise, conference }

class GradeSubmissionScreen extends StatefulWidget {
  const GradeSubmissionScreen({super.key});

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final _feedback = TextEditingController();
  _FeedbackStatus _status = _FeedbackStatus.ready;
  bool _sent = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_feedback.text.trim().length < 8) {
      SfToast.show(
        context,
        message: 'Fikrni aniqroq yozing.',
        tone: SfToastTone.warning,
      );
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Fikr yuborilsinmi?'),
            content: const Text(
              'O‘quvchi ushbu fikr va keyingi qadamni darhol ko‘radi.',
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
    setState(() => _sent = true);
    SfToast.show(
      context,
      title: 'Fikr yuborildi',
      message: 'Akbarov Akmal · ${_statusLabel(_status)}',
      tone: SfToastTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (!state.can(StaffCapability.teachLessons)) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Topshiriq fikri'),
        ),
        body: const SfEmptyState(
          title: 'Ruxsat mavjud emas',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return SfScaffold(
      top: SfNavBar(
        title: 'Topshiriq fikri',
        subtitle: 'Akbarov Akmal · 9-B Algebra',
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (_sent) ...[
            const SfHintCard(
              title: 'Fikr yuborilgan',
              message: 'Bu ish bo‘yicha keyingi qadam o‘quvchiga yetkazildi.',
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
                      'TOPSHIRILGAN ISH',
                      style: SfType.eyebrow(color: c.muted),
                    ),
                    const Spacer(),
                    Text(
                      'Bugun · 09:42',
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
                    'Diskriminant usuli to‘g‘ri qo‘llangan. 4-misolda ishora almashganda izoh yetishmaydi; yechim qadamlari ilova qilingan.',
                    style: SfType.ui(size: 13, color: c.ink2, height: 1.5),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => SfToast.show(
                    context,
                    message: 'Ish varaqasi ko‘rish rejimida ochildi.',
                    tone: SfToastTone.info,
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Biriktirilgan ishni ko‘rish'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SfAiSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SfAiBadge(label: 'Fikr yordamchisi'),
                SizedBox(height: 8),
                Text(
                  'Kuchli tomonni ayting, bitta aniq tuzatishni ko‘rsating va keyingi qadamni bering.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('KEYINGI HOLAT', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 7),
          SfSegmentedControl<_FeedbackStatus>(
            expanded: true,
            value: _status,
            segments: const [
              SfSegment(value: _FeedbackStatus.ready, label: 'Tayyor'),
              SfSegment(value: _FeedbackStatus.revise, label: 'Tuzatish'),
              SfSegment(value: _FeedbackStatus.conference, label: 'Suhbat'),
            ],
            onChanged: _sent
                ? (_) {}
                : (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 16),
          SfTextField(
            controller: _feedback,
            enabled: !_sent,
            label: 'Foydali fikr',
            hint: 'Kuchli tomon, tuzatish va keyingi qadam…',
            minLines: 4,
            maxLines: 7,
            maxLength: 800,
          ),
          const SizedBox(height: 10),
          const SfHintCard(
            message:
                'Bu jarayonda raqamli baho ishlatilmaydi; rivojlanish yozma fikr va holat bilan kuzatiladi.',
            tone: SfHintTone.info,
            compact: true,
          ),
        ],
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
          label: _sent ? 'Fikr yuborilgan' : 'Fikrni yuborish',
          leading: _sent ? Icons.check_circle_rounded : Icons.send_rounded,
          onPressed: _sent ? null : _send,
        ),
      ),
    );
  }
}

String _statusLabel(_FeedbackStatus value) => switch (value) {
  _FeedbackStatus.ready => 'Tayyor',
  _FeedbackStatus.revise => 'Tuzatish kerak',
  _FeedbackStatus.conference => 'Qisqa suhbat',
};
