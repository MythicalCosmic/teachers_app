import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:starforge_staff/screens/today/today_data.dart';
import 'package:starforge_staff/screens/today_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host({required double textScale, bool dark = false}) {
  final colors = sfColorsFor(SfPalette.daryo, dark: dark);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: dark,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: dark),
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
  setUp(() => debugSetStaffToday(DateTime(2026, 7, 14)));
  tearDown(() => debugSetStaffToday(null));

  testWidgets('today dashboard reflows on a narrow accessibility viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_host(textScale: 1.3));
    await tester.pump(const Duration(milliseconds: 500));

    // Rendering exceptions are asserted after the first interaction so the
    // framework can print the complete offending widget diagnostics.

    await tester.scrollUntilVisible(
      find.text('Bugungi dars'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Bugungi dars'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Amaliy rejani ko‘rish'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Amaliy rejani ko‘rish'), findsOneWidget);
    expect(find.text('Keyinroq'), findsOneWidget);
  });

  testWidgets('survey banner remains readable in dark mode', (tester) async {
    final darkColors = sfColorsFor(SfPalette.daryo, dark: true);
    await tester.pumpWidget(_host(textScale: 1, dark: true));
    await tester.pump(const Duration(milliseconds: 500));

    final title = tester.widget<Text>(find.text('Haftalik dars tajribasi'));
    expect(title.style?.color, darkColors.ink);
    expect(find.byKey(const Key('today-survey-banner')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a date updates the home agenda', (tester) async {
    await tester.pumpWidget(_host(textScale: 1));
    await tester.pump(const Duration(milliseconds: 500));

    final nextLessonDate = staffToday.add(const Duration(days: 1));
    final dateKey = Key('today-date-${nextLessonDate.day}');
    await tester.scrollUntilVisible(
      find.byKey(dateKey),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(dateKey));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Algebra · 9-B'), findsWidgets);
    expect(find.textContaining('Viyet teoremasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('highlighted Today controls fit the iPhone layout cleanly', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    debugSetStaffToday(DateTime(2026, 7, 18));

    await tester.pumpWidget(_host(textScale: 1));
    await tester.pumpAndSettle();

    final openLesson = find.byKey(const ValueKey('today-open-lesson-action'));
    final attendance = find.byKey(const ValueKey('today-attendance-action'));
    expect(openLesson, findsOneWidget);
    expect(attendance, findsOneWidget);
    expect(tester.getSize(openLesson).width, greaterThan(250));
    expect(tester.getSize(attendance).width, greaterThan(250));
    expect(
      tester.getCenter(attendance).dy,
      greaterThan(tester.getCenter(openLesson).dy),
    );

    final lessonsMetric = find.byKey(
      const ValueKey('today-metric-/today/lessons'),
    );
    final attendanceMetric = find.byKey(
      const ValueKey('today-metric-/today/attendance'),
    );
    final performanceMetric = find.byKey(
      const ValueKey('today-metric-/today/performance'),
    );
    expect(
      (tester.getCenter(lessonsMetric).dy -
              tester.getCenter(attendanceMetric).dy)
          .abs(),
      lessThan(1),
    );
    expect(
      tester.getCenter(performanceMetric).dy,
      greaterThan(tester.getCenter(lessonsMetric).dy),
    );
    expect(
      tester.getSize(performanceMetric).width,
      greaterThan(tester.getSize(lessonsMetric).width * 1.9),
    );
    final aiBadge = find.byKey(const ValueKey('today-ai-badge'));
    await tester.scrollUntilVisible(
      aiBadge,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(aiBadge, findsOneWidget);

    final saturday = find.byKey(const Key('today-date-18'));
    await tester.scrollUntilVisible(
      saturday,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final saturdayRect = tester.getRect(saturday);
    expect(saturdayRect.left, greaterThanOrEqualTo(0));
    expect(saturdayRect.right, lessThanOrEqualTo(393));
    expect(tester.takeException(), isNull);
  });
}
