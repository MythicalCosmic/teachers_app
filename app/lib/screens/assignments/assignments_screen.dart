import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../router.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final items = [
      _A('Kvadrat tenglamalar', '9-B Algebra', 'Ertaga · 23:59', '24/24', 'review', cnt: 7, ai: true),
      _A('Funksiyalar grafigi', '9-A Algebra', 'Pen · 23:59', '18/22', 'open'),
      _A('Yozma ish · Geometriya', '10-V', 'Ju · 18:00', '12/19', 'open', ai: true),
      _A('Olimpiada mashqlari', '11-B Tayyorlov', '20 May · 23:59', '13/13', 'graded'),
      _A('Matematik induktsiya', '11-B Tayyorlov', 'Yopildi · 12 May', '13/13', 'closed'),
    ];
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Topshiriqlar',
            subtitle: '2 ta tekshirish kutmoqda',
            actions: const [Icon(SfIcons.filter), SizedBox(width: 14), Icon(SfIcons.plus)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final entry in [
                    ('Hammasi', 12, true),
                    ('Tekshirish', 2, false),
                    ('Ochiq', 5, false),
                    ('Yopiq', 5, false),
                  ].asMap().entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: entry.value.$3 ? c.ink : Colors.transparent,
                          border: entry.value.$3 ? null : Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Text(entry.value.$1,
                                style: SfType.ui(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: entry.value.$3 ? c.bg : c.muted)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: entry.value.$3
                                    ? c.bg.withValues(alpha: 0.2)
                                    : c.surface2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('${entry.value.$2}',
                                  style: SfType.ui(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: entry.value.$3 ? c.bg : c.muted)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          for (final it in items) ...[
            GestureDetector(
              onTap: () => context.go('/assignments/grade'),
              child: SfSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: _AssignmentTile(it),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _A {
  final String t, cohort, deadline, sub, state;
  final int? cnt;
  final bool ai;
  _A(this.t, this.cohort, this.deadline, this.sub, this.state, {this.cnt, this.ai = false});
}

class _AssignmentTile extends StatelessWidget {
  final _A it;
  const _AssignmentTile(this.it);

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final state = switch (it.state) {
      'review' => (SfPillTone.primary, 'Tekshirish'),
      'open' => (SfPillTone.accent, 'Ochiq'),
      'graded' => (SfPillTone.success, 'Baholandi'),
      _ => (SfPillTone.neutral, 'Yopiq'),
    };
    final parts = it.sub.split('/');
    final pct = int.parse(parts[0]) / int.parse(parts[1]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SfPill(tone: state.$1, label: state.$2),
                      if (it.ai) const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: SfAiBadge(label: 'Yordam', compact: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(it.t,
                      style: SfType.ui(
                          size: 16,
                          weight: FontWeight.w700,
                          color: c.ink,
                          letterSpacing: -0.16,
                          height: 1.2)),
                  const SizedBox(height: 3),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${it.cohort} · ', style: SfType.ui(size: 12, color: c.muted)),
                    TextSpan(
                        text: it.deadline,
                        style:
                            SfType.ui(size: 12, weight: FontWeight.w600, color: c.ink2)),
                  ])),
                ],
              ),
            ),
            if (it.state == 'review' && it.cnt != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: c.primary, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text('${it.cnt}',
                    style: SfType.ui(
                        size: 16, weight: FontWeight.w800, color: const Color(0xFFFFFCF5))),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: c.surface2,
                  valueColor:
                      AlwaysStoppedAnimation(it.state == 'graded' ? c.success : c.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(it.sub, style: SfType.mono(size: 11, color: c.muted)),
          ],
        ),
      ],
    );
  }
}
