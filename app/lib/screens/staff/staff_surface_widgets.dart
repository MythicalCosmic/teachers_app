import 'package:flutter/material.dart';

import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_star.dart';

Duration staffMotionDuration(
  BuildContext context, [
  Duration duration = const Duration(milliseconds: 220),
]) {
  final media = MediaQuery.maybeOf(context);
  return (media?.disableAnimations ?? false) ? Duration.zero : duration;
}

class StaffPageScaffold extends StatelessWidget {
  const StaffPageScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    this.leading,
    this.actions = const [],
    this.bottom,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.96),
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 4),
                        child: leading!,
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: SfType.eyebrow(color: c.primary, size: 10.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: SfType.ui(
                              size: 27,
                              weight: FontWeight.w800,
                              color: c.ink,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: SfType.ui(
                              size: 12.5,
                              color: c.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: body,
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

class StaffIconButton extends StatelessWidget {
  const StaffIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: c.surface2,
                foregroundColor: c.ink2,
                disabledBackgroundColor: c.surface2.withValues(alpha: 0.6),
              ),
            ),
            if ((badge ?? 0) > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.danger,
                    borderRadius: SfRadius.pillAll,
                    border: Border.all(color: c.surface, width: 2),
                  ),
                  child: Text(
                    badge! > 9 ? '9+' : '$badge',
                    style: SfType.mono(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: c.surface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StaffAdaptiveGrid extends StatelessWidget {
  const StaffAdaptiveGrid({
    super.key,
    required this.children,
    this.minCellWidth = 152,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double minCellWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawColumns =
            ((constraints.maxWidth + spacing) / (minCellWidth + spacing))
                .floor();
        final columns = rawColumns.clamp(1, 4).toInt();
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class StaffMetricCard extends StatelessWidget {
  const StaffMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.tone = StaffMetricTone.neutral,
    this.onTap,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final StaffMetricTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final (accent, soft) = switch (tone) {
      StaffMetricTone.success => (c.success, c.successSoft),
      StaffMetricTone.warning => (c.warn, c.warnSoft),
      StaffMetricTone.danger => (c.danger, c.dangerSoft),
      StaffMetricTone.primary => (c.primary, c.primarySoft),
      StaffMetricTone.accent => (c.accentInk, c.accentSoft),
      StaffMetricTone.neutral => (c.ink2, c.surface2),
    };

    final content = SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: SfRadius.smAll,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: accent),
              ),
              const Spacer(),
              if (onTap != null) Icon(SfIcons.chevR, size: 17, color: c.muted),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: SfType.mono(
              size: 22,
              weight: FontWeight.w700,
              color: accent,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: SfType.eyebrow(color: c.muted, size: 10),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              style: SfType.ui(size: 10.5, color: c.muted, height: 1.25),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: SfRadius.lgAll,
        child: content,
      ),
    );
  }
}

enum StaffMetricTone { neutral, primary, accent, success, warning, danger }

class StaffSectionHeader extends StatelessWidget {
  const StaffSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SfType.ui(
                  size: 17,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: SfType.ui(size: 11.5, color: c.muted),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class StaffHintCard extends StatelessWidget {
  const StaffHintCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      label: '$title. $message',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: c.aiGradient,
          border: Border.all(color: c.aiBorder),
          borderRadius: SfRadius.lgAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.55),
                borderRadius: SfRadius.smAll,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: c.ai),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SfType.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: SfType.ui(size: 11.5, color: c.ink2, height: 1.4),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: c.ai,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(SfIcons.arrowR, size: 15),
                      label: Text(
                        actionLabel!,
                        style: SfType.ui(size: 12, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffLoadingView extends StatelessWidget {
  const StaffLoadingView({
    super.key,
    this.label = 'Ma\u2018lumotlar tayyorlanmoqda',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Center(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(label, style: SfType.ui(size: 13, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class StaffEmptyState extends StatelessWidget {
  const StaffEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = SfIcons.check,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.1,
                  child: SfStar(size: 76, color: c.primary),
                ),
                Icon(icon, size: 28, color: c.primary),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: SfType.ui(size: 17, weight: FontWeight.w800, color: c.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: SfType.ui(size: 12.5, color: c.muted, height: 1.4),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class StaffErrorView extends StatelessWidget {
  const StaffErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StaffEmptyState(
      title: 'Ma\u2018lumot ochilmadi',
      message: message,
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Qayta urinish',
      onAction: onRetry,
    );
  }
}

class StaffStatusRow extends StatelessWidget {
  const StaffStatusRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = StaffMetricTone.neutral,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final StaffMetricTone tone;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final color = switch (tone) {
      StaffMetricTone.primary => c.primary,
      StaffMetricTone.accent => c.accentInk,
      StaffMetricTone.success => c.success,
      StaffMetricTone.warning => c.warn,
      StaffMetricTone.danger => c.danger,
      StaffMetricTone.neutral => c.ink2,
    };
    return Semantics(
      button: onTap != null,
      label: '$title. $subtitle',
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: SfRadius.mdAll,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: color),
        ),
        title: Text(
          title,
          style: SfType.ui(size: 13.5, weight: FontWeight.w700, color: c.ink),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: SfType.ui(size: 11.5, color: c.muted, height: 1.3),
          ),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(SfIcons.chevR, size: 18, color: c.muted)
                : null),
      ),
    );
  }
}

class StaffSegment<T> extends StatelessWidget {
  const StaffSegment({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      label: 'Filtr',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: SfRadius.mdAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              for (final value in values)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Semantics(
                    selected: value == selected,
                    button: true,
                    child: InkWell(
                      borderRadius: SfRadius.smAll,
                      onTap: () => onChanged(value),
                      child: AnimatedContainer(
                        duration: staffMotionDuration(
                          context,
                          const Duration(milliseconds: 180),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: value == selected
                              ? c.surface
                              : Colors.transparent,
                          borderRadius: SfRadius.smAll,
                          boxShadow: value == selected ? SfShadows.sm : null,
                        ),
                        child: Text(
                          labelOf(value),
                          style: SfType.ui(
                            size: 11.5,
                            weight: value == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: value == selected ? c.ink : c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StaffReadOnlyBanner extends StatelessWidget {
  const StaffReadOnlyBanner({
    super.key,
    this.message = 'Manba yozuvi o\u2018zgarmaydi',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: SfRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: c.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: SfType.ui(
                size: 11.5,
                weight: FontWeight.w600,
                color: c.ink2,
              ),
            ),
          ),
          const SfPill(tone: SfPillTone.neutral, label: 'Faqat o\u2018qish'),
        ],
      ),
    );
  }
}
