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

class CohortDetailScreen extends StatelessWidget {
  const CohortDetailScreen({super.key});

  static const _roster = <_R>[
    _R('Akbarov Akmal', 8, 0, 96, 'top'),
    _R('Azizova Madina', 6, 0, 98, 'top'),
    _R('Bakirov Sherzod', 2, 2, 88, ''),
    _R('Davronova Sevinch', 4, 0, 92, ''),
    _R('Eshmatov Otabek', 1, 4, 72, 'warn'),
    _R('Fayzullayev Diyor', 5, 1, 94, ''),
    _R('G‘aniyev Jasur', 3, 1, 89, ''),
    _R('Halimova Zilola', 7, 0, 95, 'top'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: SfNavBar(
        title: '9-B Algebra',
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(SfIcons.arrowL, size: 18),
              SizedBox(width: 2),
              Text('Guruhlar'),
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
                  right: -30,
                  top: -30,
                  child: Opacity(
                    opacity: 0.08,
                    child: SfStar(size: 140, color: c.primary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        SfPill(
                          tone: SfPillTone.primary,
                          label: 'Algebra · Daraja II',
                        ),
                        SizedBox(width: 8),
                        SfPill(label: '2025–2026'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '9-B · 24 o‘quvchi',
                      style: SfType.ui(
                        size: 22,
                        weight: FontWeight.w800,
                        color: c.ink,
                        letterSpacing: -0.44,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Asosiy o‘qituvchi: ',
                            style: SfType.ui(size: 13, color: c.muted),
                          ),
                          TextSpan(
                            text: 'Nigora Karimova',
                            style: SfType.ui(
                              size: 13,
                              weight: FontWeight.w600,
                              color: c.ink2,
                            ),
                          ),
                          TextSpan(
                            text: ' · Xona 304',
                            style: SfType.ui(size: 13, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final s in [
                          ('94', '%', 'Davomat', c.success),
                          ('↑18', '', 'Up karta', const Color(0xFF7A4F0E)),
                          ('↓4', '', 'Down karta', c.danger),
                          ('12', '', 'Topshiriq', c.ink2),
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: c.surface2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          s.$1,
                                          style: SfType.mono(
                                            size: 18,
                                            weight: FontWeight.w700,
                                            color: s.$4,
                                          ),
                                        ),
                                        Text(
                                          s.$2,
                                          style: SfType.ui(
                                            size: 10,
                                            color: c.muted,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.$3.toUpperCase(),
                                      style: SfType.eyebrow(
                                        color: c.muted,
                                        size: 9,
                                      ),
                                    ),
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
                            label: 'Davomat',
                            leading: SfIcons.check,
                            fontSize: 13,
                            onPressed: () => context.push('/attendance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SfButton(
                            kind: SfButtonKind.soft,
                            label: 'Xabar',
                            leading: SfIcons.chat,
                            fontSize: 13,
                            onPressed: () => context.push('/messages'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SfButton(
                          kind: SfButtonKind.ghost,
                          padding: const EdgeInsets.all(12),
                          child: const Icon(SfIcons.more, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                for (final tEntry in [
                  'O‘quvchilar',
                  'Kartalar',
                  'Topshiriqlar',
                  'Jadval',
                ].asMap().entries)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: tEntry.key == 0 ? c.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tEntry.value,
                        textAlign: TextAlign.center,
                        style: SfType.ui(
                          size: 12,
                          weight: FontWeight.w600,
                          color: tEntry.key == 0 ? c.ink : c.muted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('24 o‘quvchi', style: SfType.ui(size: 12, color: c.muted)),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Saralash: Familiya',
                    style: SfType.ui(
                      size: 12,
                      weight: FontWeight.w600,
                      color: c.ink2,
                    ),
                  ),
                  Icon(SfIcons.chevD, size: 12, color: c.ink2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (int i = 0; i < _roster.length; i++)
                  GestureDetector(
                    onTap: () => context.push('/student'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: BoxDecoration(
                        border: i < _roster.length - 1
                            ? Border(bottom: BorderSide(color: c.border))
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          SfAvatar(name: _roster[i].n, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _roster[i].n,
                                      style: SfType.ui(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: c.ink,
                                      ),
                                    ),
                                    if (_roster[i].t == 'top') ...[
                                      const SizedBox(width: 6),
                                      SfStar(size: 10, color: c.accent),
                                    ],
                                    if (_roster[i].t == 'warn') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: c.danger,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${_roster[i].att}%',
                                      style: SfType.mono(
                                        size: 11,
                                        weight: FontWeight.w600,
                                        color: _roster[i].att >= 92
                                            ? c.success
                                            : _roster[i].att >= 85
                                            ? c.warn
                                            : c.danger,
                                      ),
                                    ),
                                    Text(
                                      ' · ',
                                      style: SfType.ui(
                                        size: 11,
                                        color: c.muted,
                                      ),
                                    ),
                                    Text(
                                      '↑${_roster[i].up}',
                                      style: SfType.mono(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF7A4F0E),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '↓${_roster[i].down}',
                                      style: SfType.mono(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: _roster[i].down > 0
                                            ? c.danger
                                            : c.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(SfIcons.chevR, size: 16, color: c.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SfAiBadge(label: 'Sinf hisoboti'),
                    const Spacer(),
                    Text(
                      'Bu hafta',
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"Sinf umuman barqaror. Otabek va Sherzod oxirgi 2 haftada Down karta olgan — qisqa suhbat tavsiya etiladi."',
                  style: SfType.display(size: 17, color: c.ink, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _R {
  final String n;
  final int up;
  final int down;
  final int att;
  final String t;
  const _R(this.n, this.up, this.down, this.att, this.t);
}
