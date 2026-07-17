import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_tab_bar.dart';
import '../router.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const _days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const _hours = ['08', '09', '10', '11', '12', '13', '14', '15'];

  // (day, startHour, endHour, label, color tier)
  static const _lessons = [
    [0, 1.0, 1.75, 'Algebra · 9-B', 'primary'],
    [1, 1.0, 1.75, 'Algebra · 9-A', 'primary'],
    [1, 3.5, 4.5, 'Geom · 10-V', 'accent'],
    [2, 2.0, 3.0, 'Algebra · 9-B', 'primary'],
    [2, 6.0, 7.0, 'Tayyorlov · 11', 'ink'],
    [3, 0.5, 1.5, 'Algebra · 9-A', 'primary'],
    [3, 3.0, 4.0, 'Geom · 10-V', 'accent'],
    [4, 2.0, 3.0, 'Algebra · 9-B', 'primary'],
    [5, 1.0, 2.5, 'Konsultatsiya', 'ink'],
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: _Top(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: c.bg,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      for (final h in _hours)
                        Container(
                          height: 48,
                          padding: const EdgeInsets.only(top: 2, right: 4),
                          alignment: Alignment.topLeft,
                          child: Text(
                            '$h:00',
                            style: SfType.mono(size: 10, color: c.muted),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: 48.0 * _hours.length + 8,
                        child: Stack(
                          children: [
                            // grid lines
                            for (int h = 0; h < _hours.length; h++)
                              Positioned(
                                top: 8.0 + h * 48,
                                left: 0,
                                right: 0,
                                child: Container(height: 1, color: c.border),
                              ),
                            // day columns
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (int d = 0; d < 7; d++)
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(color: c.border),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          for (final l in _lessons.where(
                                            (x) => x[0] == d,
                                          ))
                                            Positioned(
                                              left: 2,
                                              right: 2,
                                              top: 4.0 + (l[1] as double) * 48,
                                              height:
                                                  ((l[2] as double) -
                                                          (l[1] as double)) *
                                                      48 -
                                                  4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _colorFor(
                                                    l[3] as String,
                                                    c,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  l[3] as String,
                                                  style: SfType.ui(
                                                    size: 9,
                                                    weight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFFFFFCF5,
                                                    ),
                                                    height: 1.15,
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
                            // now line
                            Positioned(
                              top: 8 + 1 * 48 + 24,
                              left: 0,
                              right: 0,
                              child: Container(height: 1.5, color: c.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Seshanba · bugun',
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '5 ta dars',
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final r in [
                  ('09:00', 'Algebra · 9-B', 'Hozir'),
                  ('10:00', 'Algebra · 9-A', 'Keyingi'),
                  ('11:30', 'Geom · 10-V', ''),
                ])
                  GestureDetector(
                    onTap: () => context.push('/lesson'),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 38,
                            child: Text(
                              r.$1,
                              style: SfType.mono(size: 12, color: c.muted),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.$2,
                              style: SfType.ui(
                                size: 13,
                                weight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          if (r.$3.isNotEmpty)
                            SfPill(
                              tone: r.$3 == 'Hozir'
                                  ? SfPillTone.primary
                                  : SfPillTone.accent,
                              label: r.$3,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String tier, dynamic c) {
    switch (tier) {
      case 'primary':
        return c.primary;
      case 'accent':
        return c.accent;
      default:
        return c.ink2;
    }
  }
}

class _Top extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('May 2026', style: SfType.ui(size: 12, color: c.muted)),
                  Text(
                    '19-hafta',
                    style: SfType.ui(
                      size: 24,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -0.48,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: i == 1 ? c.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: i == 1 ? null : Border.all(color: c.border),
                    ),
                    child: Text(
                      ['Kun', 'Hafta', 'Oy'][i],
                      style: SfType.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: i == 1 ? c.bg : c.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 0; i < ScheduleScreen._days.length; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i == 1 ? c.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ScheduleScreen._days[i].toUpperCase(),
                          style: SfType.ui(
                            size: 10,
                            color: i == 1 ? c.bg : c.ink2,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${18 + i}',
                          style: SfType.ui(
                            size: 18,
                            weight: FontWeight.w700,
                            color: i == 1 ? c.bg : c.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
