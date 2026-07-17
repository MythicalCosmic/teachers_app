import 'package:flutter/material.dart';

import 'tokens.dart';

export 'sf_motion.dart';

/// Provides the current [SfColors] anywhere in the tree, plus typography helpers
/// backed by the bundled Manrope, Instrument Serif, and JetBrains Mono files.
class SfTheme extends InheritedWidget {
  final SfColors colors;
  final SfPalette palette;
  final bool dark;

  const SfTheme({
    super.key,
    required this.colors,
    required this.palette,
    required this.dark,
    required super.child,
  });

  static SfTheme of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<SfTheme>();
    assert(w != null, 'SfTheme missing in tree');
    return w!;
  }

  static SfColors colorsOf(BuildContext context) => of(context).colors;

  @override
  bool updateShouldNotify(SfTheme oldWidget) =>
      oldWidget.colors != colors ||
      oldWidget.dark != dark ||
      oldWidget.palette != palette;
}

/// Typography helpers.
class SfType {
  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.07, // -0.005em at 14px
    double? height,
  }) => TextStyle(
    fontFamily: 'Manrope',
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
    fontFamily: 'Instrument Serif',
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
    fontFamily: 'JetBrains Mono',
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
ThemeData buildMaterialTheme(SfColors c, {required bool dark}) {
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
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      fontFamily: 'Manrope',
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
  );
}
