import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/sf_theme.dart';
import 'sf_glass_surface.dart';

/// Generic StarForge surface card.
class SfSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;

  const SfSurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final sf = SfTheme.of(context);
    final content = Material(
      color: Colors.transparent,
      child: Padding(padding: padding, child: child),
    );

    return switch (sf.visualStyle) {
      AppVisualStyle.classic => Material(
        color: (color ?? c.surface).withValues(alpha: sf.surfaceOpacity),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
      AppVisualStyle.glassmorphism => SfGlassSurface(
        enabled: true,
        borderRadius: borderRadius,
        blurSigma: 18,
        tintColor: (color ?? c.surface).withValues(
          alpha: sf.surfaceOpacity.clamp(0.45, 0.86).toDouble(),
        ),
        fallbackColor: (color ?? c.surface).withValues(
          alpha: sf.surfaceOpacity.clamp(0.45, 0.86).toDouble(),
        ),
        shadows: [
          BoxShadow(
            color: c.ink.withValues(alpha: sf.dark ? 0.20 : 0.09),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
        child: content,
      ),
      AppVisualStyle.liquidGlass => SfGlassSurface(
        enabled: true,
        borderRadius: borderRadius,
        blurSigma: 30,
        tintColor: (color ?? c.surface).withValues(
          alpha: (sf.surfaceOpacity - 0.16).clamp(0.45, 0.80).toDouble(),
        ),
        fallbackColor: (color ?? c.surface).withValues(
          alpha: (sf.surfaceOpacity - 0.16).clamp(0.45, 0.80).toDouble(),
        ),
        shadows: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.13),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: c.ink.withValues(alpha: sf.dark ? 0.22 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        child: content,
      ),
      AppVisualStyle.claymorphism => Container(
        decoration: BoxDecoration(
          color: (color ?? c.surface2).withValues(alpha: sf.surfaceOpacity),
          borderRadius: borderRadius,
          border: Border.all(color: c.surface.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: c.ink.withValues(alpha: sf.dark ? 0.34 : 0.13),
              blurRadius: 22,
              offset: const Offset(9, 11),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: sf.dark ? 0.05 : 0.76),
              blurRadius: 18,
              offset: const Offset(-7, -7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
      AppVisualStyle.maximalism => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: color != null
                ? [color!, color!]
                : [
                    c.primarySoft.withValues(alpha: sf.surfaceOpacity),
                    c.accentSoft.withValues(
                      alpha: (sf.surfaceOpacity - 0.08)
                          .clamp(0.45, 0.92)
                          .toDouble(),
                    ),
                  ],
          ),
          borderRadius: borderRadius,
          border: Border.all(color: c.ink.withValues(alpha: 0.72), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: c.ink.withValues(alpha: 0.74),
              offset: const Offset(5, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    };
  }
}
