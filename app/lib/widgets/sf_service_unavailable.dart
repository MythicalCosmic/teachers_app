import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import 'sf_button.dart';
import 'sf_card.dart';

/// A deliberately blocking service state for permission failures and outages.
///
/// The obscured preview preserves the page's visual context without leaving
/// stale or permission-scoped controls interactive. The blur is only built
/// while the service is unavailable, so it has no cost during normal use.
class SfServiceUnavailable extends StatelessWidget {
  const SfServiceUnavailable({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.preview,
    this.icon = Icons.cloud_off_rounded,
    this.statusLabel,
    this.retryLabel,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;
  final Widget? preview;
  final IconData icon;
  final String? statusLabel;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.42,
              child: preview ?? const _UnavailablePreview(),
            ),
          ),
        ),
        ColoredBox(color: c.bg.withValues(alpha: 0.58)),
        SafeArea(
          minimum: const EdgeInsets.all(20),
          child: Center(
            child: Semantics(
              liveRegion: true,
              container: true,
              label: '$title. $message',
              child: TweenAnimationBuilder<double>(
                duration: reducedMotion
                    ? Duration.zero
                    : SfMotion.resolve(context, SfMotion.standard),
                curve: SfMotion.enter,
                tween: Tween(begin: 0.96, end: 1),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SfSurfaceCard(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: c.dangerSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: c.danger.withValues(alpha: 0.20),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, color: c.danger, size: 27),
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: c.surface2,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel!,
                              style: SfType.mono(
                                size: 10,
                                weight: FontWeight.w700,
                                color: c.muted,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 13),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: SfType.ui(
                            size: 20,
                            weight: FontWeight.w800,
                            color: c.ink,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: SfType.ui(
                            size: 12.5,
                            color: c.muted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SfButton(
                          key: const Key('service-unavailable-retry'),
                          block: true,
                          leading: Icons.refresh_rounded,
                          label: retryLabel ?? 'Try again',
                          onPressed: onRetry,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnavailablePreview extends StatelessWidget {
  const _UnavailablePreview();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        Container(
          height: 124,
          decoration: BoxDecoration(
            gradient: c.aiGradient,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < 4; index++) ...[
          SfSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: index.isEven ? c.primarySoft : c.accentSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 11,
                        width: double.infinity,
                        color: c.borderStrong,
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 0.64,
                        child: Container(height: 8, color: c.border),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
