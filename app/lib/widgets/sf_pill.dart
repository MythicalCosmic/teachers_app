import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';

enum SfPillTone { neutral, primary, accent, ai, success, warn, danger }

class SfPill extends StatelessWidget {
  final SfPillTone tone;
  final String label;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  const SfPill({
    super.key,
    this.tone = SfPillTone.neutral,
    required this.label,
    this.padding,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    Color bg;
    Color fg;
    Color borderC = Colors.transparent;
    switch (tone) {
      case SfPillTone.primary:
        bg = c.primarySoft;
        fg = c.primaryInk;
        break;
      case SfPillTone.accent:
        bg = c.accentSoft;
        fg = c.accentInk;
        break;
      case SfPillTone.ai:
        bg = c.aiBg.first;
        fg = c.ai;
        borderC = c.aiBorder;
        break;
      case SfPillTone.success:
        bg = c.successSoft;
        fg = c.success;
        break;
      case SfPillTone.warn:
        bg = c.warnSoft;
        fg = c.warn;
        break;
      case SfPillTone.danger:
        bg = c.dangerSoft;
        fg = c.danger;
        break;
      case SfPillTone.neutral:
        bg = c.surface2;
        fg = c.ink2;
        borderC = c.border;
        break;
    }
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SfRadius.pillAll,
        border: Border.all(color: borderC),
      ),
      child: Text(
        label.toUpperCase(),
        style: labelStyle ??
            SfType.ui(
              size: 11,
              weight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.22,
            ),
      ),
    );
  }
}
