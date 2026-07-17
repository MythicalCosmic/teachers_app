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
  final BoxBorder? border;
  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow> shadows;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  const SfGlassSurface({
    super.key,
    required this.child,
    this.enabled = true,
    this.platformAdaptive = true,
    this.blurSigma = 18,
    this.tintColor,
    this.fallbackColor,
    this.border,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.shadows = const [],
    this.padding,
    this.clipBehavior = Clip.antiAlias,
  }) : assert(blurSigma >= 0);

  static bool platformSupportsBlur(TargetPlatform platform) =>
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final useBlur =
        enabled &&
        (!platformAdaptive ||
            (!kIsWeb && platformSupportsBlur(defaultTargetPlatform)));
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));
    final opaqueFallback = (fallbackColor ?? c.surface).withValues(alpha: 1);
    final color = useBlur
        ? (tintColor ?? c.surface.withValues(alpha: 0.78))
        : opaqueFallback;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: border ?? Border.all(color: c.border.withValues(alpha: 0.82)),
        borderRadius: resolvedRadius,
        boxShadow: shadows,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
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
