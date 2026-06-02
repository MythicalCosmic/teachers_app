import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(SfIcons.arrowL, size: 18, color: c.primary)),
                  const SizedBox(width: 10),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: c.primary, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: const SfStar(size: 18, color: Color(0xFFFFFCF5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('9-B Algebra',
                                style: SfType.ui(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: c.ink)),
                            const SizedBox(width: 6),
                            const SfAiBadge(label: 'guruh', compact: true),
                          ],
                        ),
                        Text('24 o‘quvchi · sizning ma‘lumotlaringiz asosida',
                            style: SfType.ui(size: 10.5, color: c.muted)),
                      ],
                    ),
                  ),
                  Icon(SfIcons.more, size: 22, color: c.ink2),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in const [
                    'Haftalik xulosa',
                    'Kim qiynalmoqda?',
                    'Up karta nomzodlari',
                    'Ota-ona uchun xat'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: c.aiGradient,
                          border: Border.all(color: c.aiBorder),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(p,
                            style: SfType.ui(
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: c.ai)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        children: [
          _UserBubble('9-B kvadrat tenglamalar mavzusida qanday boryapti?'),
          const SizedBox(height: 10),
          _AiBubble(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Umuman barqaror. ',
                        style: SfType.display(size: 15, color: c.ink)),
                    TextSpan(
                        text:
                            '24 o‘quvchidan 18 nafari mavzuni mustaqil yechmoqda. 4 nafari diskriminant formulasida kichik xatolarga yo‘l qo‘ydi.',
                        style: SfType.ui(size: 13.5, color: c.ink, height: 1.5)),
                  ])),
                ),
                const SizedBox(height: 8),
                SfSurfaceCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final s in [
                            ('18', 'O‘zlashtirdi', c.success),
                            ('4', 'Qiynalmoqda', c.warn),
                            ('2', 'Tushunmagan', c.danger),
                          ])
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.$1,
                                      style: SfType.mono(
                                          size: 22,
                                          weight: FontWeight.w700,
                                          color: s.$3,
                                          height: 1)),
                                  const SizedBox(height: 4),
                                  Text(s.$2.toUpperCase(),
                                      style: SfType.eyebrow(color: c.muted, size: 10)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 6,
                          child: Row(
                            children: [
                              Expanded(flex: 75, child: Container(color: c.success)),
                              Expanded(flex: 17, child: Container(color: c.warn)),
                              Expanded(flex: 8, child: Container(color: c.danger)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Diqqat qaratish kerak bo‘lganlar:',
                    style: SfType.ui(size: 13.5, color: c.ink2, height: 1.5)),
                const SizedBox(height: 6),
                for (final s in [
                  ('Eshmatov Otabek', 'Diskriminant ishorasi · 2 marta xato'),
                  ('Bakirov Sherzod', 'Formulani eslamayotgan'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: c.warnSoft, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          SfAvatar(name: s.$1, size: 26),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.$1,
                                    style: SfType.ui(
                                        size: 12.5,
                                        weight: FontWeight.w600,
                                        color: c.ink2)),
                                Text(s.$2,
                                    style: SfType.ui(size: 10.5, color: c.warn)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Tavsiya: ', style: SfType.display(size: 13.5, color: c.ink2)),
                  TextSpan(
                      text:
                          'ertangi darsda 5 daqiqalik takrorlash + Eshmatov va Bakirov bilan qisqa individual ish.',
                      style: SfType.ui(size: 13.5, color: c.ink2, height: 1.5)),
                ])),
                const SizedBox(height: 8),
                Text('Sizning davomat va karta ma‘lumotlaringiz · 14 May–19 May',
                    style: SfType.mono(size: 9.5, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _UserBubble('Otabek otasiga yoziladigan qisqa xabar tayyorlab ber.'),
          const SizedBox(height: 8),
          _AiBubble(
            content: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: c.ai.withValues(alpha: 0.6), shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('9-B haqida savol bering...',
                          style: SfType.ui(size: 13, color: c.muted)),
                    ),
                    Text('~120 token', style: SfType.mono(size: 10, color: c.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(SfIcons.send, size: 18, color: Color(0xFFFFFCF5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble(this.text);
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.ink,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text,
              style: SfType.ui(size: 13.5, color: c.bg, height: 1.4)),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final Widget content;
  const _AiBubble({required this.content});
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: c.aiGradient,
            border: Border.all(color: c.aiBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text('Ai', style: SfType.display(size: 14, color: c.ai)),
        ),
        const SizedBox(width: 8),
        Expanded(child: content),
      ],
    );
  }
}
