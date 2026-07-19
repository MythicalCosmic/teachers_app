import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/sf_theme.dart';
import 'sf_glass_surface.dart';
import 'sf_pressable.dart';

/// A generic destination for [SfAdaptiveBottomNavigation].
@immutable
class SfBottomDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? semanticLabel;
  final Widget? badge;

  const SfBottomDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.semanticLabel,
    this.badge,
  });
}

/// Adaptive bottom navigation with optional iOS/macOS liquid-glass styling.
///
/// On platforms where backdrop blur is not a good default, this automatically
/// becomes an opaque surface while preserving the same layout and interaction
/// model. The component owns its bottom [SafeArea].
class SfAdaptiveBottomNavigation extends StatelessWidget {
  final List<SfBottomDestination> destinations;
  final int activeIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool glassEnabled;
  final bool platformAdaptiveGlass;
  final bool motionEnabled;
  final bool hapticsEnabled;
  final bool safeBottom;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  const SfAdaptiveBottomNavigation({
    super.key,
    required this.destinations,
    required this.activeIndex,
    required this.onDestinationSelected,
    this.glassEnabled = false,
    this.platformAdaptiveGlass = true,
    this.motionEnabled = true,
    this.hapticsEnabled = true,
    this.safeBottom = true,
    this.margin = const EdgeInsets.fromLTRB(8, 0, 8, 4),
    this.padding = const EdgeInsets.fromLTRB(4, 4, 4, 3),
    this.borderRadius = const BorderRadius.all(Radius.circular(21)),
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
  }) : assert(destinations.length >= 2),
       assert(activeIndex >= 0 && activeIndex < destinations.length);

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final sf = SfTheme.of(context);
    final active = selectedColor ?? c.primary;
    final inactive = unselectedColor ?? c.muted;
    final duration = SfMotion.resolve(
      context,
      SfMotion.standard,
      enabled: motionEnabled,
    );

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: safeBottom,
      minimum: safeBottom ? const EdgeInsets.only(bottom: 2) : EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final phoneLayout = MediaQuery.sizeOf(context).shortestSide < 600;
          final width = constraints.maxWidth.isFinite
              ? phoneLayout
                    ? constraints.maxWidth
                    : constraints.maxWidth.clamp(0.0, 920.0).toDouble()
              : 920.0;
          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: margin,
                child: SfGlassSurface(
                  // A caller may request glass outside a glass-first visual
                  // style, but the persisted global switch always wins.
                  enabled: sf.liquidGlass && (glassEnabled || sf.usesGlass),
                  platformAdaptive: platformAdaptiveGlass,
                  blurSigma: sf.visualStyle == AppVisualStyle.liquidGlass
                      ? 30
                      : 20,
                  borderRadius: borderRadius,
                  tintColor:
                      backgroundColor ??
                      c.surface.withValues(alpha: sf.navigationOpacity),
                  fallbackColor: (backgroundColor ?? c.surface).withValues(
                    alpha: sf.navigationOpacity,
                  ),
                  translucentFallback: true,
                  shadows: [
                    BoxShadow(
                      color: c.ink.withValues(alpha: sf.dark ? 0.28 : 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  child: Padding(
                    padding: padding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (
                          var index = 0;
                          index < destinations.length;
                          index++
                        )
                          Expanded(
                            child: _SfBottomDestinationItem(
                              destination: destinations[index],
                              selected: index == activeIndex,
                              activeColor: active,
                              inactiveColor: inactive,
                              duration: duration,
                              motionEnabled: motionEnabled,
                              hapticsEnabled: hapticsEnabled,
                              onPressed: onDestinationSelected == null
                                  ? null
                                  : () => onDestinationSelected!(index),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SfBottomDestinationItem extends StatelessWidget {
  final SfBottomDestination destination;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Duration duration;
  final bool motionEnabled;
  final bool hapticsEnabled;
  final VoidCallback? onPressed;

  const _SfBottomDestinationItem({
    required this.destination,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.duration,
    required this.motionEnabled,
    required this.hapticsEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: SfPressable(
        onPressed: onPressed,
        selected: selected,
        haptic: hapticsEnabled,
        motionEnabled: motionEnabled,
        pressedScale: 0.96,
        semanticLabel: destination.semanticLabel ?? destination.label,
        borderRadius: BorderRadius.circular(14),
        builder: (context, state, _) {
          final background = state.pressed
              ? c.surface3.withValues(alpha: 0.9)
              : state.hovered
              ? c.surface2.withValues(alpha: 0.78)
              : selected
              ? c.primarySoft.withValues(alpha: 0.88)
              : Colors.transparent;
          return AnimatedContainer(
            duration: duration,
            curve: SfMotion.enter,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        size: 22,
                        color: selected ? activeColor : inactiveColor,
                      ),
                      child: selected
                          ? (destination.selectedIcon ?? destination.icon)
                          : destination.icon,
                    ),
                    if (destination.badge != null)
                      Positioned(right: -8, top: -6, child: destination.badge!),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(
                    size: 10.5,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? activeColor : inactiveColor,
                    letterSpacing: -0.05,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
