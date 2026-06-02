import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';

/// Container with the AI gradient + soft radial halo accent.
class SfAiSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const SfAiSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          gradient: c.aiGradient,
          border: Border.all(color: c.aiBorder),
          borderRadius: borderRadius,
        ),
        child: Stack(
          children: [
            // Halo
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      radius: 1.0,
                      colors: [c.accent.withValues(alpha: 0.22), Colors.transparent],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
