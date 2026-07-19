import 'package:flutter/material.dart';

import '../data/models.dart';
import 'tokens.dart';

export 'sf_motion.dart';

/// Provides the current [SfColors] anywhere in the tree, plus typography helpers
/// backed by the bundled Manrope, Instrument Serif, and JetBrains Mono files.
class SfTheme extends InheritedWidget {
  final SfColors colors;
  final SfPalette palette;
  final bool dark;
  final AppVisualStyle visualStyle;
  final AppFontChoice fontChoice;
  final AppLayoutDensity layoutDensity;
  final double surfaceOpacity;
  final double navigationOpacity;
  final double motionIntensity;
  final bool liquidGlass;
  final bool reducedMotion;

  const SfTheme({
    super.key,
    required this.colors,
    required this.palette,
    required this.dark,
    this.visualStyle = AppVisualStyle.classic,
    this.fontChoice = AppFontChoice.manrope,
    this.layoutDensity = AppLayoutDensity.comfortable,
    this.surfaceOpacity = 1,
    this.navigationOpacity = 0.78,
    this.motionIntensity = 1,
    this.liquidGlass = true,
    this.reducedMotion = false,
    required super.child,
  });

  static SfTheme of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<SfTheme>();
    assert(w != null, 'SfTheme missing in tree');
    return w!;
  }

  static SfColors colorsOf(BuildContext context) => of(context).colors;

  double get spacingScale => switch (layoutDensity) {
    AppLayoutDensity.compact => 0.86,
    AppLayoutDensity.comfortable => 1,
    AppLayoutDensity.spacious => 1.14,
  };

  Duration duration(Duration base) => reducedMotion
      ? Duration.zero
      : Duration(microseconds: (base.inMicroseconds * motionIntensity).round());

  /// Whether the selected visual language should build real blur surfaces.
  ///
  /// [liquidGlass] is the global performance/accessibility switch; choosing a
  /// glass style no longer silently bypasses it.
  bool get usesGlass =>
      liquidGlass &&
      (visualStyle == AppVisualStyle.glassmorphism ||
          visualStyle == AppVisualStyle.liquidGlass);

  @override
  bool updateShouldNotify(SfTheme oldWidget) =>
      oldWidget.colors != colors ||
      oldWidget.dark != dark ||
      oldWidget.palette != palette ||
      oldWidget.visualStyle != visualStyle ||
      oldWidget.fontChoice != fontChoice ||
      oldWidget.layoutDensity != layoutDensity ||
      oldWidget.surfaceOpacity != surfaceOpacity ||
      oldWidget.navigationOpacity != navigationOpacity ||
      oldWidget.motionIntensity != motionIntensity ||
      oldWidget.liquidGlass != liquidGlass ||
      oldWidget.reducedMotion != reducedMotion;
}

/// Typography helpers.
class SfType {
  static String? _uiFamily = 'Manrope';
  static String? _displayFamily = 'Instrument Serif';
  static String? _monoFamily = 'JetBrains Mono';

  static void configure(AppFontChoice choice) {
    switch (choice) {
      case AppFontChoice.manrope:
        _uiFamily = 'Manrope';
        _displayFamily = 'Instrument Serif';
        _monoFamily = 'JetBrains Mono';
        break;
      case AppFontChoice.system:
        _uiFamily = null;
        _displayFamily = null;
        _monoFamily = 'JetBrains Mono';
        break;
      case AppFontChoice.editorial:
        _uiFamily = 'Instrument Serif';
        _displayFamily = 'Instrument Serif';
        _monoFamily = 'JetBrains Mono';
        break;
      case AppFontChoice.mono:
        _uiFamily = 'JetBrains Mono';
        _displayFamily = 'JetBrains Mono';
        _monoFamily = 'JetBrains Mono';
        break;
    }
  }

  static String? get uiFamily => _uiFamily;

  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.07, // -0.005em at 14px
    double? height,
  }) => TextStyle(
    fontFamily: _uiFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.italic,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: _displayFamily,
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    color: color,
    height: height,
  );

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
    double? height,
  }) => TextStyle(
    fontFamily: _monoFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Small uppercase eyebrow label.
  static TextStyle eyebrow({Color? color, double size = 11}) => ui(
    size: size,
    weight: FontWeight.w600,
    color: color,
    letterSpacing: size * 0.06,
  );
}

/// Build a MaterialApp ThemeData from current SfColors.
ThemeData buildMaterialTheme(
  SfColors c, {
  required bool dark,
  AppFontChoice fontChoice = AppFontChoice.manrope,
  AppLayoutDensity layoutDensity = AppLayoutDensity.comfortable,
}) {
  SfType.configure(fontChoice);
  final base = dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: c.primary,
      onPrimary: c.surface,
      secondary: c.accent,
      onSecondary: c.surface,
      surface: c.surface,
      onSurface: c.ink,
      error: c.danger,
      onError: c.surface,
    ),
    splashFactory: InkRipple.splashFactory,
    highlightColor: c.primary.withValues(alpha: 0.06),
    hoverColor: c.primary.withValues(alpha: 0.05),
    focusColor: c.primary.withValues(alpha: 0.10),
    visualDensity: switch (layoutDensity) {
      AppLayoutDensity.compact => VisualDensity.compact,
      AppLayoutDensity.comfortable => VisualDensity.standard,
      AppLayoutDensity.spacious => VisualDensity.comfortable,
    },
    textTheme: base.textTheme.apply(
      fontFamily: SfType.uiFamily,
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: c.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
