import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';

class GradeSubmissionScreen extends StatelessWidget {
  const GradeSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: SfNavBar(
        title: 'Akmal Akbarov',
        subtitle: 'Kvadrat tenglamalar',
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(SfIcons.arrowL, size: 18),
              SizedBox(width: 2),
              Text('Ortga'),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text('5 / 24', style: SfType.ui(size: 12, color: c.muted)),
          ),
          const Icon(SfIcons.more),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SfAvatar(name: 'Akmal Akbarov', size: 44, color: c.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Akbarov Akmal',
                          style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Topshirildi: ', style: SfType.ui(size: 11, color: c.muted)),
                        TextSpan(
                            text: '16.05 14:23',
                            style: SfType.mono(size: 11, color: c.ink2)),
                      ])),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: c.surface2, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.arrowL, size: 16, color: c.ink2),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: c.surface2, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.arrowR, size: 16, color: c.ink2),
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
                Row(
                  children: [
                    Text('1-MISOL · X² − 5X + 6 = 0', style: SfType.eyebrow(color: c.muted)),
                    const Spacer(),
                    const SfPill(tone: SfPillTone.success, label: 'To‘g‘ri'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'D = 25 − 24 = 1\nx₁ = (5+1)/2 = 3\nx₂ = (5−1)/2 = 2',
                  style: SfType.mono(size: 14, color: c.ink2, height: 1.7),
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: c.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('2-MISOL · 2X² + 3X − 5 = 0', style: SfType.eyebrow(color: c.muted)),
                    const Spacer(),
                    const SfPill(tone: SfPillTone.danger, label: 'Xato'),
                  ],
                ),
                const SizedBox(height: 10),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'D = 9 + 40 = 49\n',
                      style: SfType.mono(size: 14, color: c.ink2, height: 1.7)),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      color: c.dangerSoft,
                      child: Text(
                        'x₁ = (−3 + 7) / 2 = 4',
                        style: SfType.mono(
                            size: 14,
                            color: c.ink2,
                            height: 1.7,
                            letterSpacing: 0),
                      ),
                    ),
                  ),
                  TextSpan(
                      text: '  ← 2 bo‘lishi kerak edi',
                      style: SfType.display(
                          size: 12, color: c.muted, style: FontStyle.italic)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SfAiSurface(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: SfAiBadge(label: 'Taklif qilingan baho')),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('4',
                            style: SfType.mono(
                                size: 30, weight: FontWeight.w700, color: c.ai)),
                        Text(' / 5', style: SfType.ui(size: 12, color: c.muted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"11 ta misol to‘g‘ri yechilgan. 2-misolda maxraj xatosi — diskriminant ishini takrorlash tavsiya etiladi."',
                  style: SfType.display(size: 16, color: c.ink, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.aiBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TAVSIYA ETILGAN IZOH',
                          style: SfType.eyebrow(color: c.muted, size: 11)),
                      const SizedBox(height: 6),
                      Text(
                        'Akmal, juda yaxshi ish! Faqat 2-misolda formula yozishda ikkiga bo‘lishni unutibsiz. Keyingi darsda biror misolda yana mashq qilamiz.',
                        style: SfType.ui(size: 13, color: c.ink2, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SfButton(
                        kind: SfButtonKind.ink,
                        label: 'Qabul qilish',
                        leading: SfIcons.check,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SfButton(
                      kind: SfButtonKind.ghost,
                      label: 'O‘zgartirish',
                      fontSize: 13,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('SIZNING BAHOYINGIZ', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final g in ['2', '3', '4', '5'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: g == '4' ? c.primarySoft : c.surface,
                              border: Border.all(
                                  color: g == '4' ? c.primary : c.border,
                                  width: g == '4' ? 2 : 1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(g,
                                style: SfType.mono(
                                    size: 22,
                                    weight: FontWeight.w700,
                                    color: g == '4' ? c.primary : c.ink2)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
                  child: Text('Izoh yozing yoki AI tavsiyasini ishlating...',
                      style: SfType.ui(size: 13, color: c.muted, height: 1.4)),
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
            Expanded(child: SfButton(kind: SfButtonKind.soft, label: 'Qoldirish')),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SfButton(
                  kind: SfButtonKind.primary,
                  label: 'Saqlash va keyingi',
                  trailing: SfIcons.arrowR,
                  onPressed: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}
