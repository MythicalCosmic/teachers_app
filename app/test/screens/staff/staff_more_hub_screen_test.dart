import 'package:flutter/material.dart';
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

    expect(find.text('Ta\u2018lim sifati'), findsOneWidget);
    expect(find.text('To\u2018lov holati'), findsNothing);
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
    expect(find.text('To\u2018lov holati'), findsOneWidget);
    expect(find.text('Audit markazi'), findsNothing);
    expect(find.text('Ta\u2018lim sifati'), findsNothing);
  });
}
