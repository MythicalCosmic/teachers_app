import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import 'sf_button.dart';
import 'sf_pressable.dart';

enum SfHintTone { info, success, warning, danger, ai }

/// Contextual, concise guidance that can optionally expose an action or close.
class SfHintCard extends StatelessWidget {
  final String message;
  final String? title;
  final SfHintTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool compact;
  final String? semanticLabel;

  const SfHintCard({
    super.key,
    required this.message,
    this.title,
    this.tone = SfHintTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.compact = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final palette = switch (tone) {
      SfHintTone.info => _HintPalette(
        c.primary,
        c.primarySoft,
        Icons.lightbulb_outline_rounded,
      ),
      SfHintTone.success => _HintPalette(
        c.success,
        c.successSoft,
        Icons.check_circle_outline,
      ),
      SfHintTone.warning => _HintPalette(
        c.warn,
        c.warnSoft,
        Icons.warning_amber_rounded,
      ),
      SfHintTone.danger => _HintPalette(
        c.danger,
        c.dangerSoft,
        Icons.error_outline_rounded,
      ),
      SfHintTone.ai => _HintPalette(
        c.ai,
        c.aiBg.first,
        Icons.auto_awesome_outlined,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: tone == SfHintTone.danger,
      label: semanticLabel,
      excludeSemantics:
          semanticLabel != null && onAction == null && onDismiss == null,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: BoxDecoration(
          color: palette.background,
          border: Border.all(color: palette.foreground.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 30 : 36,
              height: compact ? 30 : 36,
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon ?? palette.icon,
                size: compact ? 16 : 19,
                color: palette.foreground,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: SfType.ui(
                        size: compact ? 12.5 : 13.5,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message,
                    style: SfType.ui(
                      size: compact ? 11.5 : 12.5,
                      color: c.ink2,
                      height: 1.4,
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 9),
                    SfButton(
                      kind: SfButtonKind.ghost,
                      label: actionLabel,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      overrideFg: palette.foreground,
                      onPressed: onAction,
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 6),
              SizedBox.square(
                dimension: 44,
                child: SfPressable(
                  onPressed: onDismiss,
                  semanticLabel: 'Yopish',
                  tooltip: 'Yopish',
                  pressedScale: 0.92,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(Icons.close_rounded, size: 18, color: c.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HintPalette {
  final Color foreground;
  final Color background;
  final IconData icon;

  const _HintPalette(this.foreground, this.background, this.icon);
}
