import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/staff/methodist_quality_screen.dart';
import 'package:starforge_staff/screens/staff/reception_workspace_screen.dart';
import 'package:starforge_staff/screens/staff/staff_workspace_models.dart';
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
  testWidgets('methodist quality workspace has no finance fields', (
    tester,
  ) async {
    await tester.pumpWidget(_themed(const MethodistQualityScreen()));
    expect(find.text('Ta\u2018lim sifati'), findsOneWidget);
    expect(find.textContaining('To\u2018lov'), findsNothing);
    expect(find.textContaining('Oylik'), findsNothing);
    expect(find.textContaining('Raqam hukm emas'), findsOneWidget);
  });

  testWidgets('reception advances a lead with a real store action', (
    tester,
  ) async {
    final store = DemoReceptionWorkspaceStore();
    final lead = store.leads.first;
    expect(lead.stage, LeadStage.newLead);

    await tester.pumpWidget(_themed(ReceptionWorkspaceScreen(store: store)));
    final action = find.byKey(ValueKey('advance-lead-${lead.id}'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(store.leads.first.stage, LeadStage.contacted);
    store.dispose();
  });

  testWidgets('assistant is denied reception data', (tester) async {
    await tester.pumpWidget(
      _themed(const ReceptionWorkspaceScreen(role: StaffRole.assistant)),
    );
    expect(find.text('Kirish cheklangan'), findsOneWidget);
  });
}
