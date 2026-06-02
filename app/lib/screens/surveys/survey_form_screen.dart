import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';

class SurveyFormScreen extends StatelessWidget {
  const SurveyFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Saqlab chiqish',
                          style:
                              SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary))),
                  const Spacer(),
                  Text('4 / 12 savol', style: SfType.ui(size: 11, color: c.muted)),
                  const Spacer(),
                  Text('2 kun 14s',
                      style: SfType.mono(
                          size: 11, weight: FontWeight.w700, color: c.danger)),
                ],
              ),
            ),
            Row(
              children: [
                for (int i = 0; i < 12; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 3,
                      decoration: BoxDecoration(
                          color: i < 4 ? c.primary : c.surface2,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        children: [
          Text('5-savol · 12'.toUpperCase(), style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 10),
          Text(
            'AI yordamchining tavsiyalari sizning ishingizga qanchalik foydali bo‘ldi?',
            style: SfType.display(size: 24, color: c.ink, height: 1.25),
          ),
          const SizedBox(height: 6),
          Text('1 = umuman foyda yo‘q · 10 = juda foydali',
              style: SfType.ui(size: 12, color: c.muted)),
          const SizedBox(height: 20),
          Row(
            children: [
              for (int n = 1; n <= 10; n++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: n == 8 ? c.primary : c.surface,
                          border: n == 8 ? null : Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: n == 8
                              ? [
                                  BoxShadow(
                                      color: c.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text('$n',
                            style: SfType.mono(
                                size: 13,
                                weight: FontWeight.w700,
                                color: n == 8 ? const Color(0xFFFFFCF5) : c.ink2)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Foyda yo‘q', style: SfType.ui(size: 10, color: c.muted)),
              Text('Juda foydali', style: SfType.ui(size: 10, color: c.muted)),
            ],
          ),
          const SizedBox(height: 22),
          Text('IZOH · IXTIYORIY', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 100,
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text:
                        'Karta sabab takliflari juda yaxshi — daftarda yozib o‘tirishimni qisqartirdi. Faqat ba‘zan',
                    style: SfType.ui(size: 13.5, color: c.ink, height: 1.5)),
                TextSpan(text: '|', style: SfType.ui(size: 13.5, color: c.primary)),
              ])),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(SfIcons.shield, size: 16, color: c.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: 'Bu so‘rovnoma ', style: SfType.ui(size: 11.5, color: c.ink2)),
                    TextSpan(
                        text: 'anonim',
                        style: SfType.ui(
                            size: 11.5, weight: FontWeight.w700, color: c.ink2)),
                    TextSpan(
                        text: '. Markaz faqat jamlangan natijani ko‘radi.',
                        style: SfType.ui(size: 11.5, color: c.ink2)),
                  ])),
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
            SfButton(
              kind: SfButtonKind.ghost,
              child: const Icon(SfIcons.arrowL, size: 18),
              padding: const EdgeInsets.all(14),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SfButton(
                  kind: SfButtonKind.primary,
                  label: 'Keyingisi',
                  trailing: SfIcons.arrowR,
                  onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
