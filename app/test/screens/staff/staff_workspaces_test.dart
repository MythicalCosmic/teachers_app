import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/staff/audit_workspace_screens.dart';
import 'package:starforge_staff/screens/staff/methodist_quality_screen.dart';
import 'package:starforge_staff/screens/staff/reception_workspace_screen.dart';
import 'package:starforge_staff/screens/staff/staff_today_screen.dart';
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
  test('audit CSV contains real escaped rows', () {
    final csv = buildAuditCsv([
      ImmutableAuditEventView(
        id: 'event-1',
        actor: 'Aziz, auditor',
        action: 'Izoh "tasdiqlandi"',
        entity: 'Holat 7',
        occurredAt: DateTime.utc(2026, 7, 18, 10, 30),
        integrityHash: 'abc123',
      ),
    ]);

    expect(csv, contains('"id","actor","action"'));
    expect(csv, contains('"Aziz, auditor"'));
    expect(csv, contains('"Izoh ""tasdiqlandi"""'));
    expect(csv, contains('2026-07-18T10:30:00.000Z'));
  });

  test('reception store creates leads, records calls and refreshes', () async {
    var now = DateTime.utc(2026, 7, 18, 9);
    final store = DemoReceptionWorkspaceStore(seed: const [], now: () => now);
    final lead = await store.createLead(
      const ReceptionLeadDraft(
        studentName: 'Yangi O\u2018quvchi',
        guardianName: 'Ota Ona',
        phone: '+998 90 000 00 00',
        course: 'Matematika',
      ),
    );

    expect(store.leads.single.id, lead.id);
    expect(lead.stage, LeadStage.newLead);
    now = DateTime.utc(2026, 7, 18, 9, 15);
    await store.recordCall(lead.id);
    expect(store.leads.single.stage, LeadStage.contacted);
    expect(store.leads.single.lastContactAt, now);

    now = DateTime.utc(2026, 7, 18, 9, 20);
    await store.refresh();
    expect(store.lastRefreshedAt, now);
    store.dispose();
  });

  testWidgets('staff Today refresh publishes a visible revision and time', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 7, 18, 9);
    final refresh = StaffWorkspaceRefreshStore(now: () => now);
    await tester.pumpWidget(
      _themed(
        StaffTodayScreen(
          role: StaffRole.assistant,
          refreshStore: refresh,
          onRefresh: refresh.refresh,
        ),
      ),
    );
    expect(find.textContaining('#0'), findsOneWidget);

    now = DateTime.utc(2026, 7, 18, 9, 5, 12);
    final todayRefresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pump(const Duration(milliseconds: 180));
    await todayRefresh;
    await tester.pump();
    expect(refresh.lastUpdatedAt, now);
    final todayStamp = find.byKey(
      const ValueKey('staff-today-refresh-1-false'),
    );
    expect(todayStamp, findsOneWidget);
    expect(tester.widget<Text>(todayStamp).data, startsWith('Updated'));
    expect(find.textContaining('#1'), findsOneWidget);
    refresh.dispose();
  });

  testWidgets('refresh affordance is hidden without a real operation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themed(const StaffTodayScreen(role: StaffRole.assistant)),
    );
    expect(find.byType(RefreshIndicator), findsNothing);

    await tester.pumpWidget(_themed(const AuditorDashboardScreen()));
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('audit refresh and CSV clipboard export expose real output', (
    tester,
  ) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var now = DateTime.utc(2026, 7, 18, 10);
    final refresh = StaffWorkspaceRefreshStore(now: () => now);
    await tester.pumpWidget(
      _themed(
        AuditorDashboardScreen(
          refreshStore: refresh,
          onRefresh: refresh.refresh,
        ),
      ),
    );
    now = DateTime.utc(2026, 7, 18, 10, 1, 30);
    final auditRefresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pump(const Duration(milliseconds: 180));
    await auditRefresh;
    await tester.pump();
    expect(refresh.lastUpdatedAt, now);
    final auditStamp = find.byKey(const ValueKey('audit-refresh-1-false'));
    expect(auditStamp, findsOneWidget);
    expect(tester.widget<Text>(auditStamp).data, startsWith('Updated'));
    expect(find.textContaining('#1'), findsOneWidget);

    final event = ImmutableAuditEventView(
      id: 'log-1',
      actor: 'Aziz',
      action: 'Signal ko\u2018rildi',
      entity: 'Guruh 10-A',
      occurredAt: DateTime.utc(2026, 7, 18, 10),
      integrityHash: 'deadbeef',
    );
    final csv = buildAuditCsv([event]);
    await tester.pumpWidget(
      _themed(
        ImmutableAuditLogScreen(events: [event], onExport: () async => csv),
      ),
    );
    expect(find.byTooltip('Export audit log'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('audit-export-csv')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('audit-csv-preview')), findsOneWidget);
    expect(find.text('Audit CSV preview'), findsOneWidget);
    expect(find.text('Copy CSV'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('copy-audit-csv')));
    await tester.pump();
    expect(clipboard, csv);
    expect(clipboard, contains('"integrity_hash"'));
    refresh.dispose();
  });

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
