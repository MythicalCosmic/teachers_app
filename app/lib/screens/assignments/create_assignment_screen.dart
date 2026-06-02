import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class CreateAssignmentScreen extends StatelessWidget {
  const CreateAssignmentScreen({super.key});

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
                child: Text('Bekor',
                    style: SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary)),
              ),
              const Spacer(),
              Column(
                children: [
                  Text('Yangi topshiriq',
                      style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
                  Text('Qoralama avtomatik saqlandi', style: SfType.ui(size: 11, color: c.muted)),
                ],
              ),
              const Spacer(),
              Text('E‘lon',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.primary)),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Text('SARLAVHA', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kvadrat tenglamalar · Mashqlar 1–12',
                    style: SfType.ui(size: 18, weight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 4),
                Text('Diskriminant va Viet formulasi orqali yechish',
                    style: SfType.ui(size: 13, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GURUH', style: SfType.eyebrow(color: c.muted)),
                    const SizedBox(height: 8),
                    SfSurfaceCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: c.primary, borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: const SfStar(size: 16, color: Color(0xFFFFFCF5)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('9-B Algebra',
                                  style:
                                      SfType.ui(size: 14, weight: FontWeight.w600, color: c.ink)),
                              Text('24 o‘quvchi', style: SfType.ui(size: 10, color: c.muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MUDDAT', style: SfType.eyebrow(color: c.muted)),
                    const SizedBox(height: 8),
                    SfSurfaceCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('23.05 · 23:59',
                              style: SfType.mono(
                                  size: 14, weight: FontWeight.w600, color: c.ink)),
                          Text('Pen · ertaga emas',
                              style: SfType.ui(size: 10, color: c.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('TUR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              for (final t in [
                ('Yozma', SfIcons.edit, true),
                ('Topshirish', SfIcons.upload, false),
                ('Test', SfIcons.check, false),
                ('Loyiha', SfIcons.folder, false),
              ])
                Container(
                  decoration: BoxDecoration(
                    color: t.$3 ? c.primary : c.surface,
                    border: t.$3 ? null : Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$2, size: 20, color: t.$3 ? c.bg : c.ink2),
                      const SizedBox(height: 6),
                      Text(t.$1,
                          style: SfType.ui(
                              size: 11,
                              weight: FontWeight.w600,
                              color: t.$3 ? c.bg : c.ink2)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SfAiSurface(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Topshiriq generatori'),
                const SizedBox(height: 8),
                Text(
                  '12 ta yangi mashq tayyorlandi — sinfning oldingi 3 darsiga moslashtirildi.',
                  style: SfType.display(size: 17, color: c.ink, height: 1.3),
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
                      Text('1-MISOL · OSON', style: SfType.eyebrow(color: c.muted)),
                      const SizedBox(height: 6),
                      Text('x² − 5x + 6 = 0',
                          style: SfType.mono(size: 14, color: c.ink)),
                      const SizedBox(height: 4),
                      Text('Diskriminantni hisoblang. Ildizlarni toping.',
                          style: SfType.ui(size: 11, color: c.muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '~420 ',
                            style: SfType.mono(
                                size: 11, weight: FontWeight.w700, color: c.ai)),
                        TextSpan(
                            text: 'token · markaz limiti',
                            style: SfType.ui(size: 11, color: c.muted)),
                      ])),
                    ),
                    SfButton(
                      kind: SfButtonKind.ink,
                      label: '12 misolni kiritish',
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('SOZLAMALAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final s in [
                  ('Maksimal baho', '5.0'),
                  ('Kechikish · gracePeriod', '24 soat'),
                  ('Qayta topshirish', '2 marta'),
                  ('Ota-onaga xabar', 'E‘lon qilingach'),
                ])
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.$1, style: SfType.ui(size: 13.5, color: c.ink))),
                        Text(s.$2, style: SfType.ui(size: 13, color: c.muted)),
                        const SizedBox(width: 6),
                        Icon(SfIcons.chevR, size: 14, color: c.muted),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
