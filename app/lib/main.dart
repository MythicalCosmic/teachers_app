import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'router.dart';
import 'theme/sf_theme.dart';
import 'theme/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const StarForgeEduApp());
}

class StarForgeEduApp extends StatelessWidget {
  const StarForgeEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SfThemeController(
      // Default per the design preview: Daryo (sage + brass), light mode.
      initialPalette: SfPalette.daryo,
      initialDark: false,
      builder: (context, colors, palette, dark, api) {
        return SfTheme(
          colors: colors,
          palette: palette,
          dark: dark,
          child: MaterialApp.router(
            title: 'StarForge EDU',
            debugShowCheckedModeBanner: false,
            theme: buildMaterialTheme(colors, dark: dark),
            routerConfig: buildRouter(),
          ),
        );
      },
    );
  }
}
