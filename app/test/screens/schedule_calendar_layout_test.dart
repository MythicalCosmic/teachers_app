import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/screens/schedule_screen.dart';
import 'package:starforge_staff/screens/today/today_data.dart';
import 'package:starforge_staff/screens/today_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host(Widget child, {Size size = const Size(393, 852)}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: false),
      locale: const Locale('en'),
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
}

void main() {
  setUp(() => debugSetStaffToday(DateTime(2026, 7, 14)));
  tearDown(() => debugSetStaffToday(null));

  testWidgets('home week calendar navigates complete weeks without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const TodayScreen()));
    await tester.pump(const Duration(milliseconds: 450));
    final nextWeek = find.byKey(const Key('today-week-next'));
    await tester.scrollUntilVisible(
      nextWeek,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    await tester.tap(nextWeek);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('today-date-21')), findsOneWidget);
    expect(find.text('20\u201326 July'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month calendar remains usable on a narrow phone', (
    tester,
  ) async {
    const size = Size(320, 700);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const ScheduleScreen(), size: size));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('schedule-view-month')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('month-day-2026-6-29')), findsOneWidget);
    expect(find.byKey(const Key('month-day-2026-8-9')), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
