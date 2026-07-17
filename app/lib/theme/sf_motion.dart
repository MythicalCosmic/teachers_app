import 'package:flutter/widgets.dart';

/// Shared motion tokens for the StarForge experience.
///
/// Every component still receives an explicit [enabled] switch so motion can
/// be disabled for a feature, while [isEnabled] also honours the platform's
/// reduced-motion accessibility preferences.
abstract final class SfMotion {
  static const Duration instant = Duration.zero;
  static const Duration press = Duration(milliseconds: 110);
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration emphasized = Duration(milliseconds: 360);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasizedCurve = Curves.easeOutBack;

  /// Whether animation should run in [context].
  ///
  /// [MediaQueryData.disableAnimations] is the direct reduced-motion signal.
  /// [MediaQueryData.accessibleNavigation] is also treated conservatively as
  /// a request to avoid non-essential movement.
  static bool isEnabled(BuildContext context, {bool enabled = true}) {
    if (!enabled) return false;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return true;
    return !media.disableAnimations && !media.accessibleNavigation;
  }

  /// Resolves [duration] to zero when motion is disabled.
  static Duration resolve(
    BuildContext context,
    Duration duration, {
    bool enabled = true,
  }) => isEnabled(context, enabled: enabled) ? duration : instant;
}
