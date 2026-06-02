import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: SfNavBar(
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [Icon(SfIcons.arrowL, size: 18), SizedBox(width: 2), Text('Kirish')],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
              right: -60,
              top: -60,
              child: Opacity(opacity: 0.06, child: SfStar(size: 240, color: c.primary))),
          ListView(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
            children: [
              Text('Parolni',
                  style: SfType.display(size: 36, color: c.ink, height: 1)),
              Text('tiklash',
                  style: SfType.ui(
                      size: 34,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -1.2)),
              const SizedBox(height: 16),
              Text(
                'Hisobingizga bog‘langan foydalanuvchi nomini yozing. Markaz ma‘muri yangi parol tarqatadi.',
                style: SfType.ui(size: 14, color: c.muted, height: 1.5),
              ),
              const SizedBox(height: 32),
              Text('FOYDALANUVCHI NOMI', style: SfType.eyebrow(color: c.muted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.primary, width: 1.5),
                  borderRadius: SfRadius.mdAll,
                  boxShadow: [
                    BoxShadow(color: c.primarySoft, blurRadius: 0, spreadRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(SfIcons.user, size: 18, color: c.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('nigora.karimova',
                          style: SfType.mono(size: 16, color: c.ink)),
                    ),
                    Container(width: 2, height: 18, color: c.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SfSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(SfIcons.shield, size: 18, color: c.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Xavfsizlik: ',
                            style: SfType.ui(
                                size: 12, weight: FontWeight.w700, color: c.ink2)),
                        TextSpan(
                            text:
                                'Yangi parol siz uchun Markaz ma‘muri tomonidan ishlab chiqiladi. Telefonga SMS xabar yuborilmaydi.',
                            style: SfType.ui(size: 12, color: c.muted, height: 1.5)),
                      ])),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SfButton(
                kind: SfButtonKind.primary,
                block: true,
                height: 54,
                label: 'So‘rov yuborish',
                trailing: SfIcons.arrowR,
                fontSize: 16,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Yordam kerakmi? Markazga +998 71 200 11 11',
                  style: SfType.ui(size: 12, color: c.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
