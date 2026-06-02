import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// Provides the current [SfColors] anywhere in the tree, plus typography helpers
/// that route to Google Fonts (Manrope, Instrument Serif, JetBrains Mono).
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
      oldWidget.colors != colors || oldWidget.dark != dark || oldWidget.palette != palette;
}

/// Typography helpers.
class SfType {
  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.07, // -0.005em at 14px
    double? height,
  }) =>
      GoogleFonts.manrope(
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
  }) =>
      GoogleFonts.instrumentSerif(
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
  }) =>
      GoogleFonts.jetBrainsMono(
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

/// Holds the current palette + dark mode preferences and rebuilds the tree.
class SfThemeController extends StatefulWidget {
  final SfPalette initialPalette;
  final bool initialDark;
  final Widget Function(BuildContext, SfColors, SfPalette, bool, _SfControllerApi)
      builder;

  const SfThemeController({
    super.key,
    this.initialPalette = SfPalette.daryo,
    this.initialDark = false,
    required this.builder,
  });

  @override
  State<SfThemeController> createState() => _SfThemeControllerState();
}

class _SfControllerApi {
  final void Function(SfPalette) setPalette;
  final void Function(bool) setDark;
  _SfControllerApi({required this.setPalette, required this.setDark});
}

class _SfThemeControllerState extends State<SfThemeController> {
  late SfPalette _palette = widget.initialPalette;
  late bool _dark = widget.initialDark;

  @override
  Widget build(BuildContext context) {
    final colors = sfColorsFor(_palette, dark: _dark);
    final api = _SfControllerApi(
      setPalette: (p) => setState(() => _palette = p),
      setDark: (d) => setState(() => _dark = d),
    );
    return widget.builder(context, colors, _palette, _dark, api);
  }
}

/// Public re-export of the api type so screens can take it as a parameter.
typedef SfControllerApi = _SfControllerApi;

/// Build a MaterialApp ThemeData from current SfColors.
ThemeData buildMaterialTheme(SfColors c, {required bool dark}) {
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
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
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
  );
}
