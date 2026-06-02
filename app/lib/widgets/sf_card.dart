import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        border: Border.all(color: c.border),
        borderRadius: borderRadius,
      ),
      padding: padding,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
