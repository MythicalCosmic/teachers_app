import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_star.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -40,
              child: Opacity(opacity: 0.08, child: SfStar(size: 300, color: c.primary)),
            ),
            Positioned(
              left: -40,
              bottom: 120,
              child: Opacity(opacity: 0.05, child: SfStar(size: 200, color: c.accent)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wordmark
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Row(
                      children: [
                        SfStar(size: 28, color: c.primary),
                        const SizedBox(width: 10),
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: 'StarForge',
                              style: SfType.ui(
                                size: 15,
                                weight: FontWeight.w700,
                                color: c.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text: ' · EDU',
                              style: SfType.ui(size: 15, weight: FontWeight.w500, color: c.muted),
                            ),
                          ]),
                        ),
                        const Spacer(),
                        const SfPill(label: 'Ustoz'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Heading
                  Text(
                    'Assalomu',
                    style: SfType.display(size: 38, color: c.ink, height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'alaykum.',
                    style: SfType.ui(
                      size: 36,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -1.26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 280,
                    child: Text(
                      'Hisobingizga kiring. Login va parol o‘quv markazi ma‘muri tomonidan beriladi.',
                      style: SfType.ui(size: 14, color: c.muted, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Username
                  _fieldLabel(c, 'Foydalanuvchi nomi'),
                  const SizedBox(height: 8),
                  _UsernameField(),
                  const SizedBox(height: 16),
                  // Password
                  Row(
                    children: [
                      _fieldLabel(c, 'Parol'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/login/forgot'),
                        child: Text(
                          'Unutdingizmi?',
                          style:
                              SfType.ui(size: 11, color: c.primary, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PasswordField(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(SfIcons.check, size: 14, color: Color(0xFFFFFCF5)),
                      ),
                      const SizedBox(width: 10),
                      Text('Bu qurilmada eslab qol', style: SfType.ui(size: 13, color: c.ink2)),
                    ],
                  ),
                  const Spacer(),
                  SfButton(
                    kind: SfButtonKind.primary,
                    block: true,
                    height: 54,
                    label: 'Kirish',
                    trailing: SfIcons.arrowR,
                    fontSize: 16,
                    onPressed: () => context.go('/welcome'),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'D',
                            style: SfType.display(size: 16, color: const Color(0xFFFFFCF5)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Demo Akademiya',
                                  style:
                                      SfType.ui(size: 12, weight: FontWeight.w700, color: c.ink)),
                              const SizedBox(height: 2),
                              Text('Yunusobod filiali · demo.starforge.uz',
                                  style: SfType.mono(size: 10, color: c.muted)),
                            ],
                          ),
                        ),
                        Icon(SfIcons.chevR, size: 16, color: c.ink2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(SfIcons.globe, size: 14, color: c.muted),
                      const SizedBox(width: 4),
                      Text('O‘zbekcha', style: SfType.ui(size: 12, color: c.muted)),
                      const SizedBox(width: 18),
                      Text('·', style: SfType.ui(size: 12, color: c.muted)),
                      const SizedBox(width: 18),
                      Text('Yordam', style: SfType.ui(size: 12, color: c.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(SfColors c, String label) => Text(
        label.toUpperCase(),
        style: SfType.eyebrow(color: c.muted),
      );
}

class _UsernameField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: SfRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(SfIcons.user, size: 18, color: c.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'nigora.karimova',
              style: SfType.mono(size: 16, color: c.ink),
            ),
          ),
          Text('@demo', style: SfType.mono(size: 11, color: c.muted)),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.primary, width: 1.5),
        borderRadius: SfRadius.mdAll,
        boxShadow: [BoxShadow(color: c.primarySoft, blurRadius: 0, spreadRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(SfIcons.shield, size: 18, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < 8; i++) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                  ),
                  if (i < 7) const SizedBox(width: 4),
                ],
                const SizedBox(width: 6),
                Container(width: 2, height: 18, color: c.primary),
              ],
            ),
          ),
          Icon(SfIcons.search, size: 16, color: c.muted),
        ],
      ),
    );
  }
}
