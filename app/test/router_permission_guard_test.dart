import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/demo_seed.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/router.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _stateFor(String username) async {
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

Future<AppState> _remoteReceptionState(String accountTypeSlug) async {
  final seeded = DemoSeed.snapshot();
  final snapshot = AppSnapshot(
    session: StaffSession(
      userId: 'remote-$accountTypeSlug',
      displayName: 'Remote Finance Staff',
      role: StaffRole.reception,
      branchId: 'branch-1',
      branchName: 'Server Academy',
      email: '$accountTypeSlug@example.com',
      accountTypeSlug: accountTypeSlug,
      isRemote: true,
    ),
    settings: seeded.settings.copyWith(
      hasCompletedWelcome: true,
      locale: AppLocale.en,
      reducedMotion: true,
    ),
    tasks: seeded.tasks,
    attendanceSheets: seeded.attendanceSheets,
    cards: seeded.cards,
    messageThreads: seeded.messageThreads,
    notifications: seeded.notifications,
    surveys: seeded.surveys,
    printJobs: seeded.printJobs,
    auditAnomalies: seeded.auditAnomalies,
    auditCases: seeded.auditCases,
  );
  return AppState.bootstrap(
    storage: MemoryAppStorage({
      'starforge.staff.snapshot.v1': jsonEncode(snapshot.toJson()),
    }),
  );
}

Widget _host(AppState state, GoRouter router) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      reducedMotion: true,
      child: MaterialApp.router(
        locale: const Locale('en'),
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

Future<String> _resolvedPath(
  WidgetTester tester, {
  required String username,
  required String location,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
  final state = (await tester.runAsync(() => _stateFor(username)))!;
  final router = buildRouter(state, initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(_host(state, router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  return router.routeInformationProvider.value.uri.path;
}

void main() {
  testWidgets('deep links cannot build assistant-forbidden modules', (
    tester,
  ) async {
    for (final location in const [
      '/cards/give',
      '/ai',
      '/lesson',
      '/staff/operations/payments',
      '/staff/operations/risk',
      '/staff/operations/procurement',
    ]) {
      expect(
        await _resolvedPath(
          tester,
          username: 'sardor.aliyev',
          location: location,
        ),
        '/home',
        reason: '$location must redirect before its page is built',
      );
    }
  });

  testWidgets('reception cannot deep-link into teaching or AI workspaces', (
    tester,
  ) async {
    for (final location in const [
      '/content',
      '/ai/chat',
      '/assignments',
      '/cards',
      '/staff/audit',
    ]) {
      expect(
        await _resolvedPath(
          tester,
          username: 'malika.qodirova',
          location: location,
        ),
        '/home',
        reason: '$location must remain hidden from reception',
      );
    }
  });

  testWidgets('authorized service deep links remain reachable', (tester) async {
    expect(
      await _resolvedPath(
        tester,
        username: 'nigora.karimova',
        location: '/staff/operations/risk',
      ),
      '/staff/operations/risk',
    );
    expect(
      await _resolvedPath(
        tester,
        username: 'malika.qodirova',
        location: '/staff/operations/payments',
      ),
      '/staff/operations/payments',
    );
  });

  testWidgets('unknown staff service ids return to the service hub', (
    tester,
  ) async {
    expect(
      await _resolvedPath(
        tester,
        username: 'sardor.aliyev',
        location: '/staff/operations/not-a-real-module',
      ),
      '/staff/operations',
    );
  });

  testWidgets(
    'non-lead reception accounts get honest service shell destinations',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.reset);
      final state = (await tester.runAsync(
        () => _remoteReceptionState('accountant'),
      ))!;
      addTearDown(state.dispose);
      expect(state.can(StaffCapability.viewLeads), isFalse);

      final router = buildRouter(state, initialLocation: '/workspace');
      addTearDown(router.dispose);
      await tester.pumpWidget(_host(state, router));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('staff-services-overview')),
        findsOneWidget,
      );
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Leads'), findsNothing);
      expect(find.text('Reception'), findsNothing);
      expect(find.byType(BackButton), findsNothing);

      router.go('/work');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/work');
      expect(
        find.byKey(const ValueKey('staff-services-overview')),
        findsNothing,
      );
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Leads'), findsNothing);
      expect(find.text('Reception'), findsNothing);

      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Xizmatlarni ochish'), findsOneWidget);
      expect(find.text('Lidlarni ochish'), findsNothing);
      expect(find.textContaining('Yangi lidga'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cohort attendance mutations stay hidden without permission', (
    tester,
  ) async {
    expect(
      await _resolvedPath(
        tester,
        username: 'rano.karimova',
        location: '/cohort?id=cohort-9b-algebra',
      ),
      '/cohort',
    );
    expect(find.byKey(const ValueKey('group-attendance-action')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('group-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('Take attendance'), findsNothing);
    expect(find.text('Mark'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
