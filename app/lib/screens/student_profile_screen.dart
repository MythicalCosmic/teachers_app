import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_tab_bar.dart';
import '../router.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: SfNavBar(
        title: 'O‘quvchi',
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(SfIcons.arrowL, size: 18),
              SizedBox(width: 2),
              Text('9-B'),
            ],
          ),
        ),
        actions: const [
          Icon(SfIcons.chat),
          SizedBox(width: 12),
          Icon(SfIcons.more),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SfAvatar(name: 'Akmal Akbarov', size: 64, color: c.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akbarov Akmal',
                            style: SfType.ui(
                              size: 20,
                              weight: FontWeight.w800,
                              color: c.ink,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'DEMO-2026-00042',
                            style: SfType.mono(size: 11, color: c.muted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              SfPill(tone: SfPillTone.primary, label: '9-B'),
                              SizedBox(width: 6),
                              SfPill(tone: SfPillTone.accent, label: 'Yulduz'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final s in [
                      ('↑12', 'Up karta', const Color(0xFF7A4F0E)),
                      ('↓1', 'Down karta', c.danger),
                      ('96', 'Davomat %', c.success),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.$1,
                                  style: SfType.mono(
                                    size: 20,
                                    weight: FontWeight.w700,
                                    color: s.$3,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.$2.toUpperCase(),
                                  style: SfType.eyebrow(
                                    color: c.muted,
                                    size: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                Text(
                  'Karta tarixi',
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '13 ta',
                  style: SfType.ui(
                    size: 11,
                    weight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
                Icon(SfIcons.chevR, size: 11, color: c.primary),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final r in const [
                  (
                    '19 May · 09:42',
                    'Yulduz karta',
                    'Mustaqil yechim · 3-misol',
                    'up',
                  ),
                  (
                    '17 May · 10:18',
                    'Aktivlik',
                    'Sinfdoshlariga yordam berdi',
                    'up',
                  ),
                  (
                    '12 May · 11:30',
                    'Yulduz karta',
                    'Daftar — namunaviy',
                    'up',
                  ),
                  (
                    '8 May · 09:05',
                    'Ogohlantirish',
                    'Darsda telefon bilan band',
                    'down',
                  ),
                  (
                    '5 May · 14:22',
                    'Yulduz karta',
                    'Olimpiada · 2-bosqich',
                    'up',
                  ),
                ])
                  _CardRow(date: r.$1, type: r.$2, reason: r.$3, kind: r.$4),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SfButton(
            kind: SfButtonKind.soft,
            block: true,
            label: 'Karta berish',
            leading: SfIcons.plus,
            onPressed: () => context.push('/cards/give'),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Ota-ona aloqasi',
              style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final g in [
                ('Akbarov Anvar', 'Ota · birinchi', '+998 90 222 11 33'),
                ('Akbarova Dilnoza', 'Ona', '+998 91 444 55 66'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SfSurfaceCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SfAvatar(name: g.$1, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            g.$1,
                            style: SfType.ui(
                              size: 13,
                              weight: FontWeight.w600,
                              color: c.ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            g.$2,
                            style: SfType.ui(size: 10, color: c.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g.$3,
                            style: SfType.mono(size: 11, color: c.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'O‘quvchi haqida'),
                const SizedBox(height: 10),
                Text(
                  '"Akmal — sinfning eng kuchli o‘quvchilaridan. Bu oy 12 ta Up karta oldi. Olimpiada tayyorgarligi tavsiya etiladi."',
                  style: SfType.display(size: 16, color: c.ink, height: 1.4),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: const [
                    SfPill(tone: SfPillTone.ai, label: 'Qo‘shimcha mashq'),
                    SfPill(tone: SfPillTone.ai, label: 'Olimpiada nomzodi'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.successSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.check, size: 20, color: c.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To‘lov · may oyi',
                        style: SfType.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        '600 000 so‘m · 7 may, Click',
                        style: SfType.mono(size: 11, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SfPill(tone: SfPillTone.success, label: 'To‘langan'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String date;
  final String type;
  final String reason;
  final String kind;
  const _CardRow({
    required this.date,
    required this.type,
    required this.reason,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final isUp = kind == 'up';
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUp
                    ? const [Color(0xFFF6E0AC), Color(0xFFE9C272)]
                    : const [Color(0xFFF0C9BE), Color(0xFFD88A75)],
              ),
              border: Border.all(
                color: isUp ? const Color(0xFFC49A3A) : const Color(0xFFA14026),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: SfStar(
              size: 12,
              color: isUp ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: isUp ? c.ink : c.danger,
                  ),
                ),
                Text(
                  '"$reason"',
                  style: SfType.display(
                    size: 11,
                    color: c.muted,
                    style: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Text(date, style: SfType.mono(size: 10, color: c.muted)),
        ],
      ),
    );
  }
}
