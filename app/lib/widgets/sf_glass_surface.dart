import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';

/// A platform-adaptive glass surface with a deliberately cheap fallback.
///
/// [BackdropFilter] is only added to the tree when glass is explicitly
/// [enabled] and the current platform is appropriate. Set [platformAdaptive]
/// to false when a caller has already established that blur is supported.
class SfGlassSurface extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final bool platformAdaptive;
  final double blurSigma;
  final Color? tintColor;
  final Color? fallbackColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow> shadows;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final bool specular;
  final bool translucentFallback;

  const SfGlassSurface({
    super.key,
    required this.child,
    this.enabled = true,
    this.platformAdaptive = true,
    this.blurSigma = 18,
    this.tintColor,
    this.fallbackColor,
    this.gradient,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.shadows = const [],
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    this.specular = true,
    this.translucentFallback = false,
  }) : assert(blurSigma >= 0);

  static bool platformSupportsBlur(TargetPlatform platform) =>
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final sf = SfTheme.of(context);
    final useBlur =
        enabled &&
        (!platformAdaptive ||
            (!kIsWeb && platformSupportsBlur(defaultTargetPlatform)));
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));
    final fallback = fallbackColor ?? c.surface;
    final fallbackAlpha = fallback.a < sf.surfaceOpacity
        ? fallback.a
        : sf.surfaceOpacity;
    final opaqueFallback = fallback.withValues(
      alpha: (enabled && sf.usesGlass) || translucentFallback
          ? fallbackAlpha
          : 1,
    );
    final color = useBlur
        ? (tintColor ?? c.surface.withValues(alpha: sf.surfaceOpacity))
        : opaqueFallback;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        border:
            border ??
            Border.all(
              color: useBlur
                  ? Colors.white.withValues(alpha: sf.dark ? 0.16 : 0.64)
                  : c.border.withValues(alpha: 0.82),
            ),
        borderRadius: resolvedRadius,
        boxShadow: shadows,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (useBlur && specular)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: resolvedRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, 0.22, 0.54, 1],
                      colors: [
                        Colors.white.withValues(alpha: sf.dark ? 0.13 : 0.30),
                        Colors.white.withValues(alpha: sf.dark ? 0.035 : 0.11),
                        Colors.transparent,
                        c.primary.withValues(alpha: sf.dark ? 0.055 : 0.035),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          padding == null ? child : Padding(padding: padding!, child: child),
        ],
      ),
    );

    if (useBlur) {
      // Keep blur construction entirely out of fallback trees. This matters on
      // Android devices where backdrop filtering can be disproportionately
      // expensive even when the visual result is subtle.
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: resolvedRadius,
        clipBehavior: clipBehavior,
        child: surface,
      ),
    );
  }
}
