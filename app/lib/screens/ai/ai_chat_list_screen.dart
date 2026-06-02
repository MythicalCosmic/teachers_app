import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../router.dart';

class AiChatListScreen extends StatelessWidget {
  const AiChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final groups = [
      _G('9-B Algebra', '24 o‘quvchi · Mar/Yos/Ju', 'Bugun · 11:34', true,
          '"Bu hafta sinf umuman barqaror. 2 ta o‘quvchi diqqat talab qiladi…"', 8, 2, 94, c.primary),
      _G('Algebra · Mid', '21 o‘quvchi · Du/Cho/Pa', 'Bugun · 09:12', false,
          '"Davronova Sevinch va Halimova Zilola olimpiada darajasi…"', 6, 0, 96, c.primary),
      _G('10-V Geometriya', '19 o‘quvchi · Du/Pa', 'Kecha', false,
          '"Trapetsiya mavzusi yaxshi tushunilgan. 11-misol uchun ekstra…"', 4, 1, 88, c.accent),
    ];
    return SfScaffold(
      tab: SfTab.ai,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(opacity: 0.08, child: SfStar(size: 140, color: c.primary)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SfAiBadge(label: 'Yordamchi'),
                      const SizedBox(height: 8),
                      Text('Suhbat',
                          style: SfType.ui(
                              size: 28,
                              weight: FontWeight.w800,
                              color: c.ink,
                              letterSpacing: -0.7,
                              height: 1.05)),
                      const SizedBox(height: 2),
                      Text('guruhlaringiz haqida',
                          style: SfType.display(size: 16, color: c.muted)),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: c.surface2, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.search, size: 18, color: c.ink),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          SfAiSurface(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MARKAZ LIMITI · OY', style: SfType.eyebrow(color: c.muted)),
                const SizedBox(height: 4),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '4 320 / 50 000 ',
                      style: SfType.mono(size: 14, color: c.ink2)),
                  TextSpan(text: 'token', style: SfType.mono(size: 14, color: c.muted)),
                ])),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.086,
                    minHeight: 4,
                    backgroundColor: const Color(0x80FFFCF5),
                    valueColor: AlwaysStoppedAnimation(c.ai),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('MENING GURUHLARIM · 3', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          for (final g in groups) ...[
            GestureDetector(
              onTap: () => context.go('/ai/chat'),
              child: SfSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Stack(
                  children: [
                    Positioned(
                      right: -16,
                      top: -16,
                      child: Opacity(opacity: 0.06, child: SfStar(size: 84, color: g.color)),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: g.color, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: const SfStar(size: 22, color: Color(0xFFFFFCF5)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(g.n,
                                      style: SfType.ui(
                                          size: 14.5,
                                          weight: FontWeight.w700,
                                          color: c.ink)),
                                  if (g.pinned) ...[
                                    const SizedBox(width: 6),
                                    Icon(SfIcons.pin, size: 12, color: c.accent),
                                  ],
                                  const Spacer(),
                                  Text(g.t,
                                      style: SfType.mono(size: 10, color: c.muted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(g.sub, style: SfType.ui(size: 11, color: c.muted)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: c.aiGradient,
                                  border: Border.all(color: c.aiBorder),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Ai',
                                            style: SfType.display(
                                                size: 12, color: c.ai)),
                                        const SizedBox(width: 6),
                                        Text('OXIRGI XULOSA',
                                            style: SfType.eyebrow(
                                                color: c.muted, size: 9.5)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(g.preview,
                                        style: SfType.display(
                                            size: 12,
                                            color: c.ink2,
                                            height: 1.4,
                                            style: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '↑${g.up}',
                                        style: SfType.mono(
                                            size: 11,
                                            weight: FontWeight.w700,
                                            color: const Color(0xFF7A4F0E))),
                                    TextSpan(
                                        text: ' Up',
                                        style: SfType.ui(size: 11, color: c.muted)),
                                  ])),
                                  const SizedBox(width: 12),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: '↓${g.down}',
                                        style: SfType.mono(
                                            size: 11,
                                            weight: FontWeight.w700,
                                            color: c.danger)),
                                    TextSpan(
                                        text: ' Down',
                                        style: SfType.ui(size: 11, color: c.muted)),
                                  ])),
                                  const SizedBox(width: 12),
                                  Text.rich(TextSpan(children: [
                                    TextSpan(
                                        text: 'Davomat ',
                                        style: SfType.ui(size: 11, color: c.muted)),
                                    TextSpan(
                                        text: '${g.attend}%',
                                        style: SfType.mono(
                                            size: 11,
                                            weight: FontWeight.w700,
                                            color: g.attend >= 92 ? c.success : c.warn)),
                                  ])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text('YOKI UMUMIY SAVOL BERING', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          for (final q in const [
            'Ushbu hafta eng yaxshi 5 o‘quvchini ko‘rsat',
            'Ota-onaga jo‘natiladigan haftalik xulosa tuz',
            'Kim oxirgi 2 haftada karta olmadi?',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('Ai', style: SfType.display(size: 14, color: c.ai)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(q, style: SfType.ui(size: 13, color: c.ink2))),
                    Icon(SfIcons.arrowR, size: 14, color: c.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _G {
  final String n;
  final String sub;
  final String t;
  final bool pinned;
  final String preview;
  final int up;
  final int down;
  final int attend;
  final Color color;
  _G(this.n, this.sub, this.t, this.pinned, this.preview, this.up, this.down, this.attend,
      this.color);
}
