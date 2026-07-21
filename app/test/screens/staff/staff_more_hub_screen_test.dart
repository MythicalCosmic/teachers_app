import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/staff/staff_more_hub_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _themed(Widget child) {
  final colors = sfColorsFor(SfPalette.marvarid);
  return SfTheme(
    colors: colors,
    palette: SfPalette.marvarid,
    dark: false,
    child: MaterialApp(
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildMaterialTheme(colors, dark: false),
      home: child,
    ),
  );
}

void main() {
  test('teacher, assistant and methodist cannot view payment status', () {
    for (final role in const [
      StaffRole.teacher,
      StaffRole.assistant,
      StaffRole.methodist,
    ]) {
      expect(role.can(StaffCapability.viewPaymentStatus), isFalse);
    }
  });

  testWidgets('more hub hides finance and role switching for methodist', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        const StaffMoreHubScreen(
          role: StaffRole.methodist,
          displayName: 'Ra\u2018no Karimova',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('staff-services-featured')),
      findsOneWidget,
    );
    expect(find.text('Xodim xizmatlari'), findsOneWidget);
    expect(find.text('Ta’lim sifati'), findsOneWidget);
    expect(find.text('To‘lov holati'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.textContaining('rol almashtirish'), findsOneWidget);
    expect(find.byTooltip('Rolni almashtirish'), findsNothing);
  });

  testWidgets('reception sees only its permitted operational destination', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        const StaffMoreHubScreen(
          role: StaffRole.reception,
          displayName: 'Malika Qodirova',
        ),
      ),
    );

    expect(find.text('Lidlar va qabul'), findsOneWidget);
    expect(find.text('To‘lov holati'), findsOneWidget);
    expect(find.text('Audit markazi'), findsNothing);
    expect(find.text('Ta’lim sifati'), findsNothing);
  });

  testWidgets('more hub honors account-specific grants instead of role alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(
        StaffMoreHubScreen(
          role: StaffRole.teacher,
          displayName: 'Dilshod Karimov',
          canAccess: (capability) => switch (capability) {
            StaffCapability.viewStaffServices ||
            StaffCapability.acknowledgeStaffRules => true,
            _ => false,
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('staff-services-featured')),
      findsOneWidget,
    );
    expect(find.text('1 TA OCHIQ'), findsOneWidget);
    expect(find.text('Materiallar'), findsNothing);
    expect(find.text('StarForge AI'), findsNothing);
    expect(find.text('To‘lov holati'), findsNothing);
  });
}
