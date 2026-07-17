import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/screens/auth/login_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host({TextScaler textScaler = TextScaler.noScaling}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: false),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('login wordmark fits an iPhone viewport', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('StarForge EDU, Xodimlar'), findsOneWidget);
  });

  testWidgets('login wordmark reflows for large accessible text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(textScaler: const TextScaler.linear(2)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('XODIMLAR'), findsOneWidget);
  });
}
