import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import 'sf_button.dart';

/// A calm empty state with an optional recovery action.
class SfEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const SfEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => _SfStateLayout(
    icon: icon,
    title: title,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    compact: compact,
    tone: _SfStateTone.neutral,
  );
}

/// An error state that communicates the problem and supports retry.
class SfErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final bool compact;

  const SfErrorState({
    super.key,
    this.title = 'Nimadir xato ketdi',
    this.message,
    this.retryLabel = 'Qayta urinish',
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => _SfStateLayout(
    icon: Icons.error_outline_rounded,
    title: title,
    message: message,
    actionLabel: onRetry == null ? null : retryLabel,
    onAction: onRetry,
    compact: compact,
    tone: _SfStateTone.error,
    liveRegion: true,
  );
}

/// A reduced-motion-aware loading state.
class SfLoadingState extends StatelessWidget {
  final String label;
  final String? message;
  final bool compact;
  final bool motionEnabled;

  const SfLoadingState({
    super.key,
    this.label = 'Yuklanmoqda…',
    this.message,
    this.compact = false,
    this.motionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final animate = SfMotion.isEnabled(context, enabled: motionEnabled);
    return Semantics(
      container: true,
      liveRegion: true,
      label: message == null ? label : '$label. $message',
      excludeSemantics: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: compact ? 28 : 38,
                    child: CircularProgressIndicator(
                      value: animate ? null : 0.72,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      color: c.primary,
                      backgroundColor: c.primarySoft,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: SfType.ui(
                    size: compact ? 13 : 15,
                    weight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: SfType.ui(size: 12, color: c.muted, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SfStateTone { neutral, error }

class _SfStateLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final _SfStateTone tone;
  final bool liveRegion;

  const _SfStateLayout({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.compact,
    required this.tone,
    this.liveRegion = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final foreground = tone == _SfStateTone.error ? c.danger : c.primary;
    final background = tone == _SfStateTone.error
        ? c.dangerSoft
        : c.primarySoft;
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 48 : 60,
                  height: compact ? 48 : 60,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(compact ? 16 : 20),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: foreground, size: compact ? 23 : 28),
                ),
                SizedBox(height: compact ? 12 : 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: SfType.ui(
                    size: compact ? 15 : 18,
                    weight: FontWeight.w800,
                    color: c.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: SfType.ui(
                      size: compact ? 12 : 13,
                      color: c.muted,
                      height: 1.45,
                    ),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 16),
                  SfButton(
                    kind: tone == _SfStateTone.error
                        ? SfButtonKind.ghost
                        : SfButtonKind.primary,
                    label: actionLabel,
                    leading: tone == _SfStateTone.error
                        ? Icons.refresh_rounded
                        : null,
                    overrideFg: tone == _SfStateTone.error ? c.danger : null,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
