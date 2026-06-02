import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_star.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 1.2,
                  colors: [c.accentSoft, Colors.transparent],
                  stops: const [0, 0.55],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SfAvatar(name: 'Nigora Karimova', size: 92, color: c.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Xush kelibsiz,', style: SfType.display(size: 22, color: c.ink2)),
                  const SizedBox(height: 2),
                  Text(
                    'Nigora opa',
                    style: SfType.ui(
                      size: 26,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -0.65,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Matematika ustozi · Demo Akademiya',
                      style: SfType.ui(size: 12, color: c.muted)),
                  const SizedBox(height: 22),
                  SfSurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const SfStar(size: 22, color: Color(0xFFFFFCF5)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Yunusobod filiali',
                                  style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink)),
                              const SizedBox(height: 2),
                              Text('3 ta guruh · 2 ta fan · 58 o‘quvchi',
                                  style: SfType.ui(size: 11, color: c.muted)),
                            ],
                          ),
                        ),
                        Icon(SfIcons.check, size: 22, color: c.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: const [
                      SfPill(tone: SfPillTone.primary, label: 'Algebra'),
                      SfPill(tone: SfPillTone.accent, label: 'Geometriya'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final s in const [
                        ('3', 'Guruh'),
                        ('58', 'O‘quvchi'),
                        ('12', 'Dars / hafta'),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: c.border),
                              ),
                              child: Column(
                                children: [
                                  Text(s.$1,
                                      style: SfType.mono(
                                          size: 22,
                                          weight: FontWeight.w700,
                                          color: c.primary,
                                          height: 1)),
                                  const SizedBox(height: 3),
                                  Text(s.$2.toUpperCase(),
                                      style: SfType.eyebrow(color: c.muted, size: 10.5)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  SfButton(
                    kind: SfButtonKind.primary,
                    block: true,
                    height: 54,
                    label: 'Boshlash',
                    trailing: SfIcons.arrowR,
                    fontSize: 16,
                    onPressed: () => context.go('/today'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
