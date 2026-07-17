import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';

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
    return Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
