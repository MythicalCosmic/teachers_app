import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import 'sf_glass_surface.dart';
import 'sf_pressable.dart';

enum SfToastTone { info, success, warning, error }

/// Floating, animated StarForge feedback built on [ScaffoldMessenger].
abstract final class SfToast {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    String? title,
    SfToastTone tone = SfToastTone.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showClose = true,
    bool replaceCurrent = true,
    bool glassEnabled = true,
    bool motionEnabled = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (replaceCurrent) messenger.hideCurrentSnackBar();

    void close() => messenger.hideCurrentSnackBar();
    void runAction() {
      messenger.hideCurrentSnackBar();
      onAction?.call();
    }

    return messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        dismissDirection: DismissDirection.down,
        content: _SfToastContent(
          message: message,
          title: title,
          tone: tone,
          actionLabel: actionLabel,
          onAction: onAction == null ? null : runAction,
          onClose: showClose ? close : null,
          glassEnabled: glassEnabled,
          motionEnabled: motionEnabled,
        ),
      ),
    );
  }
}

class _SfToastContent extends StatelessWidget {
  final String message;
  final String? title;
  final SfToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  final bool glassEnabled;
  final bool motionEnabled;

  const _SfToastContent({
    required this.message,
    required this.title,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
    required this.glassEnabled,
    required this.motionEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final palette = switch (tone) {
      SfToastTone.info => (c.primary, Icons.info_outline_rounded),
      SfToastTone.success => (c.success, Icons.check_circle_outline_rounded),
      SfToastTone.warning => (c.warn, Icons.warning_amber_rounded),
      SfToastTone.error => (c.danger, Icons.error_outline_rounded),
    };
    final animate = SfMotion.isEnabled(context, enabled: motionEnabled);
    final animationDuration = SfMotion.resolve(
      context,
      SfMotion.emphasized,
      enabled: motionEnabled,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animationDuration,
      curve: SfMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: SfGlassSurface(
          enabled: glassEnabled,
          borderRadius: BorderRadius.circular(18),
          tintColor: c.surface.withValues(alpha: 0.82),
          fallbackColor: c.surface,
          border: Border.all(color: palette.$1.withValues(alpha: 0.36)),
          shadows: const [
            BoxShadow(
              color: Color(0x2D14110D),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
          padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.$1.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(palette.$2, color: palette.$1, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: SfType.ui(
                          size: 13,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(size: 12, color: c.ink2, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 6),
                SfPressable(
                  onPressed: onAction,
                  semanticLabel: actionLabel,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    child: Text(
                      actionLabel!,
                      style: SfType.ui(
                        size: 12,
                        weight: FontWeight.w800,
                        color: palette.$1,
                      ),
                    ),
                  ),
                ),
              ],
              if (onClose != null)
                SizedBox.square(
                  dimension: 44,
                  child: SfPressable(
                    onPressed: onClose,
                    semanticLabel: 'Yopish',
                    tooltip: 'Yopish',
                    pressedScale: 0.92,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.close_rounded, color: c.muted, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
