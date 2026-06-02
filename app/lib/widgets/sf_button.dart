import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    late Color bg;
    late Color fg;
    Color? borderColor;
    switch (kind) {
      case SfButtonKind.primary:
        bg = c.primary;
        fg = const Color(0xFFFFFCF5);
        break;
      case SfButtonKind.ghost:
        bg = Colors.transparent;
        fg = c.ink;
        borderColor = c.borderStrong;
        break;
      case SfButtonKind.soft:
        bg = c.surface2;
        fg = c.ink;
        break;
      case SfButtonKind.ink:
        bg = c.ink;
        fg = c.bg;
        break;
    }
    if (overrideBg != null) bg = overrideBg!;
    if (overrideFg != null) fg = overrideFg!;

    final inner = child ??
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

    final btn = Material(
      color: bg,
      borderRadius: SfRadius.pillAll,
      child: InkWell(
        onTap: onPressed ?? () {},
        borderRadius: SfRadius.pillAll,
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: SfRadius.pillAll,
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
          alignment: Alignment.center,
          child: inner,
        ),
      ),
    );

    return block ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
