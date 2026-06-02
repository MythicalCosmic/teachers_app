import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    Icon(SfIcons.arrowL, size: 18, color: c.primary),
                    const SizedBox(width: 2),
                    Text('Vazifalar',
                        style: SfType.ui(size: 15, weight: FontWeight.w600, color: c.primary)),
                  ],
                ),
              ),
              const Spacer(),
              Icon(SfIcons.printer, size: 18, color: c.ink2),
              const SizedBox(width: 12),
              Icon(SfIcons.more, size: 22, color: c.ink2),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Wrap(
            spacing: 6,
            children: [
              const SfPill(tone: SfPillTone.primary, label: 'BAJARILMOQDA'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(4)),
                child: Text('BOSHQARUV', style: SfType.eyebrow(color: c.bg, size: 10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('P1',
                    style: SfType.mono(size: 10, weight: FontWeight.w700, color: c.danger)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: 'May oyi yakuniy ',
                  style: SfType.ui(
                      size: 26,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -0.65)),
              TextSpan(text: 'hisobotini ', style: SfType.display(size: 26, color: c.ink)),
              TextSpan(
                  text: 'topshirish',
                  style: SfType.ui(
                      size: 26,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -0.65)),
            ]),
          ),
          const SizedBox(height: 18),
          for (final p in [
            ('Loyiha', 'Hisobot · oylik', SfIcons.brand, c.primary, false),
            ('Bergan', 'Karimova R. · Direktor', SfIcons.user, c.muted, false),
            ('Muddat', 'Ertaga · 18:00', SfIcons.cal, c.muted, true),
            ('Sub-vazifa', '2 / 4 bajarildi', SfIcons.check, c.muted, false),
            ('Tag', 'Markaz · Yarim oy · Mat', SfIcons.brand, c.muted, false),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Row(
                      children: [
                        Icon(p.$3, size: 13, color: c.muted),
                        const SizedBox(width: 6),
                        Text(p.$1, style: SfType.ui(size: 12, color: c.muted)),
                      ],
                    ),
                  ),
                  Text(p.$2,
                      style: SfType.ui(
                          size: 12,
                          weight: p.$5 ? FontWeight.w700 : FontWeight.w600,
                          color: p.$5 ? c.danger : c.ink2)),
                ],
              ),
            ),
          Container(height: 1, color: c.border, margin: const EdgeInsets.symmetric(vertical: 18)),
          Text(
            'May oyi bo‘yicha yakuniy hisobotni tayyorlash. Hisobotda quyidagilar bo‘lishi kerak:',
            style: SfType.ui(size: 14, color: c.ink, height: 1.6),
          ),
          const SizedBox(height: 14),
          for (final s in [
            ('Davomat statistikasi · 3 guruh', true, false),
            ('Up/Down kartalar tahlili', true, false),
            ('AI suhbat asosida tavsiyalar', false, true),
            ('Yakuniy xulosa · 1 sahifa', false, false),
          ])
            Container(
              decoration: BoxDecoration(
                color: s.$3 ? c.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              margin: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: s.$2 ? c.success : Colors.transparent,
                      border: s.$2
                          ? null
                          : Border.all(
                              color: s.$3 ? c.primary : c.borderStrong, width: 1.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: s.$2
                        ? const Icon(SfIcons.check, size: 12, color: Color(0xFFFFFCF5))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.$1,
                        style: SfType.ui(
                            size: 14,
                            weight: s.$3 ? FontWeight.w700 : FontWeight.w400,
                            color: s.$2 ? c.muted : c.ink)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('# Hisobot shabloni', style: SfType.mono(size: 12, color: c.muted)),
                Text('1. Yunusobod filiali · 3 guruh', style: SfType.mono(size: 12, color: c.ink2, height: 1.6)),
                Text('2. Davomat: 94% (+2 → o‘sib)', style: SfType.mono(size: 12, color: c.ink2, height: 1.6)),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '3. Up kartalar: ', style: SfType.mono(size: 12, color: c.ink2)),
                  TextSpan(text: '↑ 18', style: SfType.mono(size: 12, weight: FontWeight.w700, color: const Color(0xFF7A4F0E))),
                ])),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '4. Down kartalar: ', style: SfType.mono(size: 12, color: c.ink2)),
                  TextSpan(text: '↓ 4', style: SfType.mono(size: 12, weight: FontWeight.w700, color: c.danger)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Hisobot yordamchi'),
                const SizedBox(height: 8),
                Text(
                  '"Sizning 9-B, Algebra Mid va 10-V ma‘lumotlaringizdan yarim avtomatik hisobot tuzdim. Ko‘rib chiqing va kerakli joylarga qo‘l tegdiring."',
                  style: SfType.display(size: 15, color: c.ink2, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: const [
                    SfPill(tone: SfPillTone.ai, label: 'Qoralama tayyor'),
                    SfPill(tone: SfPillTone.ai, label: '3 sahifa · PDF'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('FAOLLIK · 4 TA', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 10),
          for (final a in [
            ('Karimova R.', 'vazifani sizga biriktirdi', '17 May · 14:08', false),
            ('Siz', '"Davomat statistikasi"ni tugatdingiz', '18 May · 10:22', false),
            ('Siz', '"Up/Down kartalar tahlili"ni tugatdingiz', '19 May · 09:42', false),
            ('AI', 'qoralama tayyorladi', 'Hozir', true),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.$4)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: c.aiGradient,
                        border: Border.all(color: c.aiBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text('Ai', style: SfType.display(size: 11, color: c.ai)),
                    )
                  else
                    SfAvatar(name: a.$1, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: a.$1,
                              style: SfType.ui(size: 12, weight: FontWeight.w700, color: c.ink)),
                          TextSpan(text: ' ${a.$2}', style: SfType.ui(size: 12, color: c.muted, height: 1.4)),
                        ])),
                        const SizedBox(height: 2),
                        Text(a.$3, style: SfType.mono(size: 10, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(child: SfButton(kind: SfButtonKind.soft, label: 'Qoldirish', onPressed: () => context.pop())),
            const SizedBox(width: 8),
            Expanded(
                child: SfButton(
              kind: SfButtonKind.primary,
              label: 'Tugatish',
              leading: SfIcons.check,
              onPressed: () => context.pop(),
            )),
          ],
        ),
      ),
    );
  }
}
