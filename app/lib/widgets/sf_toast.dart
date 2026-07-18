import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import 'sf_glass_surface.dart';
import 'sf_pressable.dart';

enum SfToastTone { info, success, warning, error }

/// Floating, adaptive feedback anchored to the top-right safe area.
abstract final class SfToast {
  static OverlayEntry? _currentEntry;

  static void show(
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
    final overlay = Overlay.of(context, rootOverlay: true);
    final resolvedMotionEnabled = SfMotion.isEnabled(
      context,
      enabled: motionEnabled,
    );
    if (replaceCurrent) {
      final current = _currentEntry;
      if (current?.mounted ?? false) current!.remove();
      _currentEntry = null;
    }

    final key = GlobalKey<_SfToastOverlayState>();
    late final OverlayEntry entry;
    void remove() {
      if (entry.mounted) entry.remove();
      if (identical(_currentEntry, entry)) {
        _currentEntry = null;
      }
    }

    entry = OverlayEntry(
      builder: (overlayContext) => _SfToastOverlay(
        key: key,
        duration: duration,
        motionEnabled: resolvedMotionEnabled,
        onRemoved: remove,
        child: _SfToastContent(
          message: message,
          title: title,
          tone: tone,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  key.currentState?.dismiss();
                  onAction();
                },
          onClose: showClose ? () => key.currentState?.dismiss() : null,
          glassEnabled: glassEnabled,
        ),
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _SfToastOverlay extends StatefulWidget {
  const _SfToastOverlay({
    super.key,
    required this.child,
    required this.duration,
    required this.motionEnabled,
    required this.onRemoved,
  });

  final Widget child;
  final Duration duration;
  final bool motionEnabled;
  final VoidCallback onRemoved;

  @override
  State<_SfToastOverlay> createState() => _SfToastOverlayState();
}

class _SfToastOverlayState extends State<_SfToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.motionEnabled
          ? const Duration(milliseconds: 420)
          : Duration.zero,
      reverseDuration: widget.motionEnabled
          ? const Duration(milliseconds: 210)
          : Duration.zero,
    )..forward();
    _timer = Timer(widget.duration, dismiss);
  }

  Future<void> dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    try {
      await _controller.reverse();
    } on TickerCanceled {
      return;
    }
    if (mounted) widget.onRemoved();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = (media.size.width - 24).clamp(0, 430).toDouble();
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned(
      top: media.padding.top + 10,
      right: 12,
      width: width,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.16, -0.72),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            alignment: Alignment.topRight,
            child: Dismissible(
              key: const ValueKey('sf-toast'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => widget.onRemoved(),
              child: Material(color: Colors.transparent, child: widget.child),
            ),
          ),
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

  const _SfToastContent({
    required this.message,
    required this.title,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
    required this.onClose,
    required this.glassEnabled,
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
    final platform = Theme.of(context).platform;
    final apple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final closeLabel = switch (Localizations.localeOf(context).languageCode) {
      'ru' => 'Закрыть',
      'en' => 'Close',
      _ => 'Yopish',
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: SfGlassSurface(
        enabled: glassEnabled && apple,
        borderRadius: BorderRadius.circular(apple ? 20 : 16),
        tintColor: c.surface.withValues(alpha: 0.76),
        fallbackColor: c.surface,
        border: Border.all(
          color: apple
              ? Colors.white.withValues(
                  alpha: SfTheme.of(context).dark ? 0.14 : 0.72,
                )
              : palette.$1.withValues(alpha: 0.36),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x2D14110D),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
        padding: EdgeInsets.fromLTRB(apple ? 12 : 14, 11, 8, 11),
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
                  semanticLabel: closeLabel,
                  tooltip: closeLabel,
                  pressedScale: 0.92,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(Icons.close_rounded, color: c.muted, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
