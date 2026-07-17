import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/screens/today_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host({required double textScale}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: false),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const TodayScreen(),
    ),
  );
}

void main() {
  testWidgets('today dashboard reflows on a narrow accessibility viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_host(textScale: 1.3));
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('BUGUNGI DARS'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('BUGUNGI DARS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Tavsiyani ko‘rish'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Tavsiyani ko‘rish'), findsOneWidget);
    expect(find.text('Keyinroq'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
