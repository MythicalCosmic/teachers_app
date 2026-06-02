import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_tab_bar.dart';
import '../router.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: SfNavBar(
        title: 'Algebra · Daraja II',
        leading: GestureDetector(
          onTap: () => context.go('/schedule'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(SfIcons.arrowL, size: 18),
              SizedBox(width: 2),
              Text('Jadval'),
            ],
          ),
        ),
        actions: const [Icon(SfIcons.more)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Stack(
              children: [
                Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(opacity: 0.08, child: SfStar(size: 130, color: c.primary))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SfPill(tone: SfPillTone.primary, label: 'Hozir'),
                        const SizedBox(width: 8),
                        Text('L-204', style: SfType.mono(size: 11, color: c.muted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: 'Algebra · ',
                            style: SfType.ui(
                                size: 24,
                                weight: FontWeight.w800,
                                color: c.ink,
                                letterSpacing: -0.48)),
                        TextSpan(text: 'Daraja II', style: SfType.display(size: 24, color: c.ink)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: 'Mavzu: ', style: SfType.ui(size: 13.5, color: c.muted)),
                      TextSpan(
                          text: 'Kvadrat tenglamalarni yechish',
                          style: SfType.ui(
                              size: 13.5, weight: FontWeight.w600, color: c.ink2)),
                    ])),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final x in const [
                          ('Vaqt', '09:00 – 09:45', SfIcons.clock),
                          ('Xona', '304 · 2-qavat', SfIcons.pin),
                          ('Guruh', '9-B · 24 nafar', SfIcons.cohort),
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: c.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(x.$3, size: 12, color: c.muted),
                                        const SizedBox(width: 4),
                                        Text(x.$1.toUpperCase(),
                                            style: SfType.eyebrow(color: c.muted, size: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(x.$2,
                                        style: SfType.ui(
                                            size: 12,
                                            weight: FontWeight.w700,
                                            color: c.ink,
                                            height: 1.2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SfButton(
                            kind: SfButtonKind.primary,
                            label: 'Davomatni boshlash',
                            leading: SfIcons.check,
                            onPressed: () => context.go('/attendance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SfButton(
                          kind: SfButtonKind.ghost,
                          child: const Icon(SfIcons.edit, size: 18),
                          padding: const EdgeInsets.all(12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('Dars rejasi',
                    style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink)),
                const Spacer(),
                Text('4 bosqich', style: SfType.ui(size: 11, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (int i = 0; i < 4; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i < 3 ? Border(bottom: BorderSide(color: c.border)) : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: i == 0 ? c.success : Colors.transparent,
                            border: i == 0
                                ? null
                                : Border.all(color: c.borderStrong, width: 1.5),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: i == 0
                              ? const Icon(SfIcons.check, size: 14, color: Color(0xFFFFFCF5))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            [
                              'Salomlashish va davomat',
                              'Yangi mavzu: kvadrat formulasi',
                              'Mashqlar — guruhli ish',
                              'Uy ishi va xulosa',
                            ][i],
                            style: SfType.ui(
                              size: 14,
                              weight: FontWeight.w600,
                              color: i == 0 ? c.muted : c.ink,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Text(['5 daq', '15 daq', '20 daq', '5 daq'][i],
                            style: SfType.mono(size: 11, color: c.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('Materiallar',
                    style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink)),
                const Spacer(),
                Text('+ qo‘shish',
                    style:
                        SfType.ui(size: 11, color: c.primary, weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in [
                  ('Kvadrat tenglama.pdf', '2.1 MB · 8 bet', SfIcons.pdf, c.danger),
                  ('Mashq · 12 ta', 'Interaktiv', SfIcons.doc, c.primary),
                  ('Video tushuntirish', '6:42', SfIcons.video, c.accent),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 140,
                      child: SfSurfaceCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: f.$4,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(f.$3, size: 18, color: const Color(0xFFFFFCF5)),
                            ),
                            const SizedBox(height: 8),
                            Text(f.$1,
                                style: SfType.ui(
                                    size: 12.5, weight: FontWeight.w600, color: c.ink, height: 1.2)),
                            const SizedBox(height: 2),
                            Text(f.$2, style: SfType.ui(size: 10, color: c.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SfAiSurface(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Dars yordamchi'),
                const SizedBox(height: 10),
                Text(
                  '"Bu mavzuda o‘tgan oyda 4 nafar bola qiynalgan. Mashqdan oldin tezkor takrorlashni tavsiya qilaman."',
                  style: SfType.display(size: 17, color: c.ink, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    SfPill(tone: SfPillTone.ai, label: 'Takrorlash so‘rovi'),
                    SfPill(tone: SfPillTone.ai, label: 'Misol · oson'),
                    SfPill(tone: SfPillTone.ai, label: 'Vizual yordam'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
