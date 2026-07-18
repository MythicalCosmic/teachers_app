import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/router.dart';
import 'package:starforge_staff/screens/staff/reception_workspace_screen.dart';
import 'package:starforge_staff/screens/staff/staff_workspace_models.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _signedInState(String username) async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: username, password: 'demo2026');
  await state.updateSettings(
    state.settings.copyWith(
      hasCompletedWelcome: true,
      locale: AppLocale.en,
      reducedMotion: true,
    ),
  );
  return state;
}

Widget _host(AppState state, GoRouter router) {
  final colors = sfColorsFor(SfPalette.marvarid);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.marvarid,
      dark: false,
      reducedMotion: true,
      child: MaterialApp.router(
        locale: Locale(state.settings.locale.name),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        routerConfig: router,
      ),
    ),
  );
}

Future<GoRouter> _pumpRoute(
  WidgetTester tester, {
  required String username,
  required String location,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
  final state = (await tester.runAsync(() => _signedInState(username)))!;
  final router = buildRouter(state, initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(_host(state, router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return router;
}

void main() {
  testWidgets('production reception route creates, calls and opens a lead', (
    tester,
  ) async {
    final before = receptionWorkspaceStore.leads.length;
    await _pumpRoute(
      tester,
      username: 'malika.qodirova',
      location: '/staff/reception',
    );

    await tester.tap(find.byKey(const ValueKey('reception-add-lead')));
    await tester.pump();
    expect(find.text('New lead'), findsOneWidget);
    expect(find.text('Student name'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('reception-lead-student')),
      'Route Test Student',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reception-lead-guardian')),
      'Route Test Guardian',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reception-lead-phone')),
      '+998 90 123 45 67',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reception-lead-course')),
      'Geometry',
    );
    await tester.pump();
    tester.testTextInput.hide();
    await tester.pump();
    final submit = find.byKey(const ValueKey('reception-create-lead-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 300));

    expect(receptionWorkspaceStore.leads.length, before + 1);
    final lead = receptionWorkspaceStore.leads.first;
    expect(lead.studentName, 'Route Test Student');
    expect(
      tester
          .widget<ReceptionWorkspaceScreen>(
            find.byType(ReceptionWorkspaceScreen),
          )
          .onCall,
      isNotNull,
    );

    final call = find.byKey(ValueKey('call-lead-${lead.id}'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump();
    await tester.ensureVisible(call);
    await tester.pump();
    await tester.tap(call);
    await tester.pump();
    expect(find.text('Record conversation'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reception-record-call')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(receptionWorkspaceStore.leads.first.lastContactAt, isNotNull);
    expect(receptionWorkspaceStore.leads.first.stage, LeadStage.contacted);

    final details = find.byKey(ValueKey('open-lead-${lead.id}'));
    await tester.tap(details);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('reception-lead-details')),
      findsOneWidget,
    );
    expect(find.text('Contact person'), findsOneWidget);
    expect(find.text('Route Test Guardian'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production audit refresh and CSV export are operational', (
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
    final before = auditWorkspaceRefreshStore.revision;
    final router = await _pumpRoute(
      tester,
      username: 'aziz.audit',
      location: '/staff/audit',
    );

    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pump(const Duration(milliseconds: 180));
    await refresh;
    await tester.pump();
    expect(auditWorkspaceRefreshStore.revision, before + 1);
    expect(find.textContaining('#${before + 1}'), findsOneWidget);

    router.go('/staff/audit/log');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('audit-export-csv')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('audit-csv-preview')), findsOneWidget);
    expect(find.text('Audit CSV preview'), findsOneWidget);
    expect(find.text('Copy CSV'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('copy-audit-csv')));
    await tester.pump();
    expect(clipboard, contains('"integrity_hash"'));
    expect(clipboard, contains('"Nazorat tizimi"'));
    expect(tester.takeException(), isNull);
  });
}
