import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import 'sf_star.dart';

class SfWordmark extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? accent;

  const SfWordmark({super.key, this.size = 18, this.color, this.accent});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final ink = color ?? c.ink;
    final acc = accent ?? c.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SfStar(size: size + 4, color: acc),
        SizedBox(width: size * 0.35),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'StarForge',
              style: SfType.ui(
                size: size,
                weight: FontWeight.w700,
                color: ink,
                letterSpacing: -size * 0.02,
              ),
            ),
            TextSpan(
              text: ' · EDU',
              style: SfType.ui(
                size: size,
                weight: FontWeight.w500,
                color: c.muted,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
