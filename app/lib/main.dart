import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_scope.dart';
import 'app/app_state.dart';
import 'data/models.dart';
import 'router.dart';
import 'theme/sf_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final appState = await AppState.bootstrap();
  runApp(StarForgeStaffApp(appState: appState));
}

class StarForgeStaffApp extends StatefulWidget {
  const StarForgeStaffApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<StarForgeStaffApp> createState() => _StarForgeStaffAppState();
}

class _StarForgeStaffAppState extends State<StarForgeStaffApp> {
  late final _router = buildRouter(widget.appState);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final settings = widget.appState.settings;
        final palette = _palette(settings.palette);
        final lightColors = sfColorsFor(palette);
        final darkColors = sfColorsFor(palette, dark: true);
        return AppScope(
          notifier: widget.appState,
          child: MaterialApp.router(
            title: 'StarForge EDU Staff',
            debugShowCheckedModeBanner: false,
            theme: buildMaterialTheme(lightColors, dark: false),
            darkTheme: buildMaterialTheme(darkColors, dark: true),
            themeMode: _themeMode(settings.themeMode),
            themeAnimationDuration: settings.reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            themeAnimationCurve: Curves.easeOutCubic,
            locale: Locale(settings.locale.name),
            supportedLocales: const [Locale('uz'), Locale('ru')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              final colors = dark ? darkColors : lightColors;
              final overlay = SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
              );
              return SfTheme(
                colors: colors,
                palette: palette,
                dark: dark,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlay,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

SfPalette _palette(AppPalette value) => switch (value) {
  AppPalette.daryo => SfPalette.daryo,
  AppPalette.saroy => SfPalette.saroy,
  AppPalette.marvarid => SfPalette.marvarid,
  AppPalette.samarqand => SfPalette.samarqand,
};

ThemeMode _themeMode(AppThemeMode value) => switch (value) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};
