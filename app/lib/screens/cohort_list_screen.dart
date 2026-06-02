import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_tab_bar.dart';
import '../router.dart';

class CohortListScreen extends StatelessWidget {
  const CohortListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final cohorts = [
      ('9-B Algebra', 'Daraja II', 24, 94, 'Bugun · 09:00', c.primary),
      ('9-A Algebra', 'Daraja II', 22, 91, 'Bugun · 10:00', c.primary),
      ('10-V Geometriya', 'Daraja III', 19, 88, 'Bugun · 11:30', c.accent),
      ('11-B Tayyorlov', 'DTM', 13, 96, 'Bugun · 15:00', c.ink2),
      ('8-A Algebra', 'Daraja I', 26, 89, 'Ertaga · 08:30', c.primary),
    ];
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Guruhlar',
            subtitle: '4 ta faol · 78 o‘quvchi',
            actions: const [Icon(SfIcons.filter), SizedBox(width: 14), Icon(SfIcons.plus)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(SfIcons.search, size: 18, color: c.muted),
                        const SizedBox(width: 8),
                        Text('Guruh yoki o‘quvchini izlash',
                            style: SfType.ui(size: 14, color: c.muted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final entry in ['Hammasi', 'Algebra', 'Geometriya', 'Tayyorlov', 'Arxiv']
                          .asMap()
                          .entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: entry.key == 0 ? c.ink : Colors.transparent,
                              border:
                                  entry.key == 0 ? null : Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(entry.value,
                                style: SfType.ui(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: entry.key == 0 ? c.bg : c.muted)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          for (final co in cohorts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => context.go('/cohort'),
                child: SfSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: co.$6,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const SfStar(size: 28, color: Color(0xFFFFFCF5)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: const BoxDecoration(
                                color: Color(0x30000000),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                ),
                              ),
                              child: Text('${co.$3}',
                                  style: SfType.ui(
                                      size: 9,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFFFFFCF5))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(co.$1,
                                      style: SfType.ui(
                                          size: 16,
                                          weight: FontWeight.w700,
                                          color: c.ink,
                                          letterSpacing: -0.16)),
                                ),
                                SfPill(label: co.$2),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: 'Keyingi: ', style: SfType.ui(size: 12, color: c.muted)),
                              TextSpan(
                                  text: co.$5,
                                  style: SfType.ui(
                                      size: 12, weight: FontWeight.w600, color: c.ink2)),
                            ])),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text('${co.$4}%',
                                    style: SfType.mono(
                                        size: 14,
                                        weight: FontWeight.w700,
                                        color: co.$4 >= 92
                                            ? c.success
                                            : co.$4 >= 88
                                                ? c.warn
                                                : c.danger)),
                                const SizedBox(width: 4),
                                Text('DAVOMAT',
                                    style: SfType.eyebrow(color: c.muted, size: 10)),
                                const SizedBox(width: 10),
                                Container(width: 1, height: 14, color: c.border),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 16,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        for (final v in [60, 80, 92, 78, 88, 96, 84, 91, 87, co.$4]
                                            .asMap()
                                            .entries)
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 1),
                                              child: FractionallySizedBox(
                                                heightFactor: v.value / 100,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: v.key == 9 ? co.$6 : c.surface3,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Yoyish'),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '10-V ',
                      style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink2)),
                  TextSpan(
                      text:
                          'guruhida davomat oxirgi 2 haftada 4% tushdi. 3 o‘quvchini ko‘rib chiqing.',
                      style: SfType.ui(size: 13, color: c.ink2, height: 1.4)),
                ])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
