import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/demo_seed.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/staff/staff_app_state_screens.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _stateApp(AppState state, Widget child) {
  final colors = sfColorsFor(SfPalette.marvarid);
  return SfTheme(
    colors: colors,
    palette: SfPalette.marvarid,
    dark: false,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: false),
      home: AppScope(notifier: state, child: child),
    ),
  );
}

Future<AppState> _auditorState() async {
  final seed = DemoSeed.snapshot();
  final snapshot = AppSnapshot(
    session: DemoSeed.demoAccounts['aziz.audit'],
    settings: seed.settings,
    tasks: seed.tasks,
    attendanceSheets: seed.attendanceSheets,
    cards: seed.cards,
    messageThreads: seed.messageThreads,
    notifications: seed.notifications,
    surveys: seed.surveys,
    printJobs: seed.printJobs,
    auditAnomalies: seed.auditAnomalies,
    auditCases: seed.auditCases,
  );
  return AppState.bootstrap(
    storage: MemoryAppStorage({
      'starforge.staff.snapshot.v1': jsonEncode(snapshot.toJson()),
    }),
    clock: () => DateTime.utc(2026, 7, 17, 12),
  );
}

Future<AppState> _assistantState() async {
  final seed = DemoSeed.snapshot();
  final snapshot = AppSnapshot(
    session: DemoSeed.demoAccounts['sardor.aliyev'],
    settings: seed.settings,
    tasks: seed.tasks,
    attendanceSheets: seed.attendanceSheets,
    cards: seed.cards,
    messageThreads: seed.messageThreads,
    notifications: seed.notifications,
    surveys: seed.surveys,
    printJobs: seed.printJobs,
    auditAnomalies: seed.auditAnomalies,
    auditCases: seed.auditCases,
  );
  return AppState.bootstrap(
    storage: MemoryAppStorage({
      'starforge.staff.snapshot.v1': jsonEncode(snapshot.toJson()),
    }),
  );
}

void main() {
  testWidgets(
    'auditor signal queue marks review without editing source fields',
    (tester) async {
      final state = await _auditorState();
      final source = state.auditAnomalies.first;
      final originalTitle = source.title;
      final originalDescription = source.description;

      await tester.pumpWidget(
        _stateApp(state, const AuditSignalsRouteScreen()),
      );
      expect(find.text('FAQAT O\u2018QISH'), findsWidgets);

      final acknowledge = find.text('Ko\u2018rib chiqildi').first;
      await tester.ensureVisible(acknowledge);
      await tester.tap(acknowledge);
      await tester.pumpAndSettle();

      final updated = state.auditAnomalies.firstWhere(
        (item) => item.id == source.id,
      );
      expect(updated.status, AnomalyStatus.acknowledged);
      expect(updated.title, originalTitle);
      expect(updated.description, originalDescription);
    },
  );

  testWidgets('case detail writes notes through AppState', (tester) async {
    final state = await _auditorState();
    final auditCase = state.auditCases.first;

    await tester.pumpWidget(
      _stateApp(state, AuditCaseDetailRouteScreen(caseId: auditCase.id)),
    );

    await tester.enterText(
      find.byType(TextField).last,
      'Dalil filial jurnali bilan solishtirildi.',
    );
    await tester.pump();
    await tester.tap(find.text('Qaydni saqlash'));
    await tester.pumpAndSettle();

    final updated = state.auditCases.firstWhere(
      (item) => item.id == auditCase.id,
    );
    expect(updated.notes.last, 'Dalil filial jurnali bilan solishtirildi.');
  });

  testWidgets('non-auditor cannot open audit dashboard', (tester) async {
    final state = await _assistantState();

    await tester.pumpWidget(
      _stateApp(state, const AuditorDashboardRouteScreen()),
    );
    expect(find.text('Kirish cheklangan'), findsOneWidget);
  });
}
