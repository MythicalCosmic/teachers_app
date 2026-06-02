import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';

/// The signature "Ai · LABEL" badge.
class SfAiBadge extends StatelessWidget {
  final String? label;
  final bool compact;

  const SfAiBadge({super.key, this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final aiFontSize = compact ? 13.0 : 14.0;
    final labelFontSize = compact ? 10.0 : 11.0;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: c.aiGradient,
        border: Border.all(color: c.aiBorder),
        borderRadius: SfRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ai',
            style: SfType.display(
              size: aiFontSize,
              weight: FontWeight.w400,
              color: c.ai,
            ),
          ),
          if (label != null && label != 'AI') ...[
            const SizedBox(width: 6),
            Text(
              label!.toUpperCase(),
              style: SfType.ui(
                size: labelFontSize,
                weight: FontWeight.w700,
                color: c.ai,
                letterSpacing: 0.06 * labelFontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
