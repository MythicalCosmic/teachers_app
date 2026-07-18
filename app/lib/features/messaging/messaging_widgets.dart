import 'package:flutter/material.dart';

import '../../theme/sf_theme.dart';
import 'messaging_l10n.dart';

/// Deterministic waveform used for voice recording and playback. It avoids
/// expensive continuous custom painting while still animating smoothly.
class MessagingWaveform extends StatelessWidget {
  const MessagingWaveform({
    super.key,
    required this.progress,
    this.barCount = 24,
    this.height = 28,
  }) : assert(progress >= 0 && progress <= 1),
       assert(barCount > 0);

  final double progress;
  final int barCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return Semantics(
      label: m.text('voice_progress', {'percent': (progress * 100).round()}),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < barCount; index++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: SfMotion.resolve(
                    context,
                    const Duration(milliseconds: 120),
                  ),
                  height: 5 + ((index * 13 + index * index * 3) % 19),
                  decoration: BoxDecoration(
                    color: index / barCount <= progress ? c.primary : c.muted2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (index != barCount - 1) const SizedBox(width: 2),
            ],
          ],
        ),
      ),
    );
  }
}

String messagingDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
