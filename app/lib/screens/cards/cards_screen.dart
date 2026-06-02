import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../router.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  static const _recent = <_C>[
    _C('Akbarov Akmal', '9-B Algebra', 'Yulduz karta', 'Mustaqil yechim · 3-misol', '09:42', true),
    _C('Halimova Zilola', '9-B Algebra', 'Aktivlik', 'Sinfdoshlariga yordam berdi', '09:38', true),
    _C('Eshmatov Otabek', '9-B Algebra', 'Ogohlantirish', 'Uy ishi tayyor emas (2-marta)', '09:12', false),
    _C('Davronova Sevinch', 'Algebra · Mid', 'Yulduz karta', 'Toza daftar', 'Dush · 14:20', true),
    _C('Bakirov Sherzod', 'Algebra · Mid', 'Ogohlantirish', 'Darsda telefon bilan', 'Dush · 11:05', false),
    _C('Azizova Madina', '9-B Algebra', 'Yulduz karta', 'Olimpiada · 2-bosqich', 'Yak · 18:40', true),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Kartalar',
            subtitle: 'Bu hafta · 14 berildi',
            actions: const [Icon(SfIcons.filter), SizedBox(width: 14), Icon(SfIcons.plus)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              color: c.bg,
              child: Row(
                children: [
                  Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      width: 44,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFF6E0AC), Color(0xFFE9C272)]),
                        border: Border.all(color: const Color(0xFFC49A3A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const SfStar(size: 20, color: Color(0xFF7A4F0E)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('↑ 11',
                                style: SfType.mono(
                                    size: 22,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF7A4F0E))),
                            const SizedBox(width: 4),
                            Text('Up',
                                style: SfType.ui(
                                    size: 11, weight: FontWeight.w600, color: c.muted)),
                            const SizedBox(width: 14),
                            Text('↓ 3',
                                style: SfType.mono(
                                    size: 22, weight: FontWeight.w700, color: c.danger)),
                            const SizedBox(width: 4),
                            Text('Down',
                                style: SfType.ui(
                                    size: 11, weight: FontWeight.w600, color: c.muted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: 'Joriy sozlama: ',
                              style: SfType.ui(size: 11, color: c.muted)),
                          TextSpan(
                              text: 'Yulduz / Ogohlantirish',
                              style: SfType.ui(
                                  size: 11, weight: FontWeight.w600, color: c.ink2)),
                          TextSpan(
                              text: ' · markaz tomonidan',
                              style: SfType.ui(size: 11, color: c.muted)),
                        ])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final e in ['Hammasi · 14', 'Up · 11', 'Down · 3', '9-B', 'Algebra Mid']
                    .asMap()
                    .entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: e.key == 0 ? c.ink : Colors.transparent,
                        border: e.key == 0 ? null : Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(e.value,
                          style: SfType.ui(
                              size: 12,
                              weight: FontWeight.w600,
                              color: e.key == 0 ? c.bg : c.muted)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Tahlil', compact: true),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Eshmatov Otabek',
                      style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink2)),
                  TextSpan(
                      text:
                          'ga shu oy 2 ta Down karta berildi. Ota-onaga avtomatik xabar yuborish tavsiya etiladi.',
                      style: SfType.ui(size: 13, color: c.ink2, height: 1.4)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('SO‘NGGI FAOLLIK', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          for (final r in _recent) ...[
            _Row(c: r),
            const SizedBox(height: 8),
          ],
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 50,
          label: 'Karta berish',
          leading: SfIcons.plus,
          onPressed: () => context.go('/cards/give'),
        ),
      ),
    );
  }
}

class _C {
  final String st;
  final String cohort;
  final String type;
  final String reason;
  final String t;
  final bool up;
  const _C(this.st, this.cohort, this.type, this.reason, this.t, this.up);
}

class _Row extends StatelessWidget {
  final _C c;
  const _Row({required this.c});

  @override
  Widget build(BuildContext context) {
    final col = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.up
                    ? const [Color(0xFFF6E0AC), Color(0xFFE9C272)]
                    : const [Color(0xFFF0C9BE), Color(0xFFD88A75)],
              ),
              border: Border.all(color: c.up ? const Color(0xFFC49A3A) : const Color(0xFFA14026)),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SfStar(size: 18, color: c.up ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C)),
                const SizedBox(height: 2),
                Text(c.up ? '↑ UP' : '↓ DOWN',
                    style: SfType.ui(
                        size: 9,
                        weight: FontWeight.w800,
                        color: c.up ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.st,
                          style:
                              SfType.ui(size: 13.5, weight: FontWeight.w700, color: col.ink)),
                    ),
                    Text(c.t, style: SfType.mono(size: 10, color: col.muted)),
                  ],
                ),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '${c.cohort} · ', style: SfType.ui(size: 11, color: col.muted)),
                  TextSpan(
                      text: c.type,
                      style: SfType.ui(
                          size: 11,
                          weight: FontWeight.w600,
                          color: c.up ? col.accentInk : col.danger)),
                ])),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: col.surface2, borderRadius: BorderRadius.circular(8)),
                  child: Text('"${c.reason}"',
                      style: SfType.display(
                          size: 12,
                          color: col.ink2,
                          style: FontStyle.italic,
                          height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
