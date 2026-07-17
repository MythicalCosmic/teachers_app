import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';
import 'sf_pressable.dart';

enum SfButtonKind { primary, ghost, soft, ink }

class SfButton extends StatelessWidget {
  final SfButtonKind kind;
  final String? label;
  final IconData? leading;
  final IconData? trailing;
  final Widget? child; // overrides label + icons
  final VoidCallback? onPressed;
  final bool block;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final Color? overrideBg;
  final Color? overrideFg;
  final String? semanticLabel;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool haptic;
  final bool motionEnabled;

  const SfButton({
    super.key,
    this.kind = SfButtonKind.primary,
    this.label,
    this.leading,
    this.trailing,
    this.child,
    this.onPressed,
    this.block = false,
    this.height,
    this.padding,
    this.fontSize = 15,
    this.overrideBg,
    this.overrideFg,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.haptic = false,
    this.motionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    late Color bg;
    late Color fg;
    late Color hoverBg;
    late Color pressedBg;
    Color? borderColor;
    switch (kind) {
      case SfButtonKind.primary:
        bg = c.primary;
        fg = const Color(0xFFFFFCF5);
        hoverBg = Color.lerp(c.primary, c.primaryHover, 0.55)!;
        pressedBg = c.primaryHover;
        break;
      case SfButtonKind.ghost:
        bg = Colors.transparent;
        fg = c.ink;
        borderColor = c.borderStrong;
        hoverBg = c.surface2.withValues(alpha: 0.72);
        pressedBg = c.surface3.withValues(alpha: 0.86);
        break;
      case SfButtonKind.soft:
        bg = c.surface2;
        fg = c.ink;
        hoverBg = Color.lerp(c.surface2, c.surface3, 0.45)!;
        pressedBg = c.surface3;
        break;
      case SfButtonKind.ink:
        bg = c.ink;
        fg = c.bg;
        hoverBg = Color.lerp(c.ink, c.ink2, 0.4)!;
        pressedBg = c.ink2;
        break;
    }
    if (overrideBg != null) {
      bg = overrideBg!;
      hoverBg = Color.lerp(overrideBg!, c.ink, 0.06)!;
      pressedBg = Color.lerp(overrideBg!, c.ink, 0.12)!;
    }
    if (overrideFg != null) fg = overrideFg!;

    final inner =
        child ??
        Row(
          mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              Icon(leading, size: fontSize + 3, color: fg),
              const SizedBox(width: 8),
            ],
            if (label != null)
              Flexible(
                child: Text(
                  label!,
                  style: SfType.ui(
                    size: fontSize,
                    weight: FontWeight.w600,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Icon(trailing, size: fontSize + 3, color: fg),
            ],
          ],
        );

    final minimumHeight = height == null || height! < 44 ? 44.0 : height!;
    final transitionDuration = SfMotion.resolve(
      context,
      SfMotion.quick,
      enabled: motionEnabled,
    );
    final btn = SfPressable(
      onPressed: onPressed,
      haptic: haptic,
      motionEnabled: motionEnabled,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      focusNode: focusNode,
      autofocus: autofocus,
      borderRadius: SfRadius.pillAll,
      focusColor: c.primary,
      builder: (context, state, _) {
        final effectiveBg = state.pressed
            ? pressedBg
            : state.hovered
            ? hoverBg
            : bg;
        return AnimatedOpacity(
          opacity: state.enabled ? 1 : 0.46,
          duration: transitionDuration,
          child: AnimatedContainer(
            duration: transitionDuration,
            curve: SfMotion.enter,
            constraints: BoxConstraints(minHeight: minimumHeight),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: SfRadius.pillAll,
              border: borderColor != null
                  ? Border.all(color: borderColor)
                  : null,
            ),
            alignment: Alignment.center,
            child: inner,
          ),
        );
      },
    );

    return block ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
