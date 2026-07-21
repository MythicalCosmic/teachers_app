import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/operations/staff_operations_controller.dart';
import 'package:starforge_staff/screens/staff/staff_operations_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

void main() {
  testWidgets('nested risk response becomes a task-oriented student card', (
    tester,
  ) async {
    final app = await AppState.bootstrap(storage: MemoryAppStorage());
    addTearDown(app.dispose);
    final api = StarforgeApi(
      vault: MemorySessionVault(
        const StoredSession(
          accessToken: 'staff-token',
          connection: TenantConnection(
            slug: 'staff',
            name: 'Staff center',
            baseUrl: 'https://staff.example',
            wsUrl: '',
            locale: 'uz',
          ),
          deviceId: 'device-1',
        ),
      ),
      client: ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/users/me/') {
            return _json(200, {
              'success': true,
              'data': {
                'id': 4,
                'principal_kind': 'teacher',
                'full_name': 'Teacher',
              },
            });
          }
          return _json(200, {
            'success': true,
            'data': {
              'count': 1,
              'page_size': 20,
              'results': [
                {
                  'student': 41,
                  'name': 'Aziza Karimova',
                  'cohort': 9,
                  'score': 3,
                  'level': 'medium',
                  'flags': [
                    {
                      'code': 'low_attendance',
                      'reason': 'Absent 4 of the last 10 lessons.',
                    },
                  ],
                },
              ],
            },
          });
        }),
      ),
    );
    await api.restore();
    final controller = StaffOperationsController(
      api: api,
      module: staffOperationModuleById('risk')!,
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    final colors = sfColorsFor(SfPalette.daryo);
    await tester.pumpWidget(
      AppScope(
        notifier: app,
        child: SfTheme(
          colors: colors,
          palette: SfPalette.daryo,
          dark: false,
          reducedMotion: true,
          child: MaterialApp(
            locale: const Locale('uz'),
            supportedLocales: const [Locale('uz'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildMaterialTheme(colors, dark: false),
            home: StaffOperationModuleScreen(
              moduleId: 'risk',
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aziza Karimova'), findsOneWidget);
    expect(find.text('O‘rta'), findsOneWidget);
    expect(find.textContaining('Xavf bali'), findsOneWidget);
    expect(find.textContaining('Server record'), findsNothing);
    expect(find.textContaining('Count'), findsNothing);
    expect(find.textContaining('Page size'), findsNothing);

    await tester.tap(find.text('Aziza Karimova'));
    await tester.pumpAndSettle();
    expect(find.text('SABABLAR'), findsOneWidget);
    expect(
      find.textContaining('Absent 4 of the last 10 lessons.'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('backend 403 exits the module without a forbidden page', (
    tester,
  ) async {
    final fixture = await _statusFixture(403);
    addTearDown(fixture.dispose);
    await fixture.controller.refresh();
    expect(fixture.controller.accessDenied, isTrue);

    final router = GoRouter(
      initialLocation: '/staff/operations/risk',
      routes: [
        GoRoute(
          path: '/staff/operations',
          builder: (_, _) =>
              const Scaffold(key: ValueKey('staff-services-safe-return')),
        ),
        GoRoute(
          path: '/staff/operations/:moduleId',
          builder: (_, state) => StaffOperationModuleScreen(
            moduleId: state.pathParameters['moduleId']!,
            controller: fixture.controller,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(fixture.routerHost(router));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/staff/operations');
    expect(
      find.byKey(const ValueKey('staff-services-safe-return')),
      findsOneWidget,
    );
    expect(find.textContaining('unavailable for your role'), findsNothing);
    expect(find.textContaining('roli'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backend 404 is presented as a retryable service outage', (
    tester,
  ) async {
    final fixture = await _statusFixture(404);
    addTearDown(fixture.dispose);
    await fixture.controller.refresh();
    expect(fixture.controller.accessDenied, isFalse);
    expect(fixture.controller.endpointUnavailable, isTrue);

    await tester.pumpWidget(
      fixture.host(
        StaffOperationModuleScreen(
          moduleId: 'risk',
          controller: fixture.controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Service temporarily unavailable'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.textContaining('unavailable for your role'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<_StatusFixture> _statusFixture(int status) async {
  final app = await AppState.bootstrap(storage: MemoryAppStorage());
  await app.updateSettings(
    app.settings.copyWith(locale: AppLocale.en, reducedMotion: true),
  );
  final api = StarforgeApi(
    vault: MemorySessionVault(
      const StoredSession(
        accessToken: 'staff-token',
        connection: TenantConnection(
          slug: 'staff',
          name: 'Staff center',
          baseUrl: 'https://staff.example',
          wsUrl: '',
          locale: 'en',
        ),
        deviceId: 'device-1',
      ),
    ),
    client: ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/users/me/') {
          return _json(200, {
            'success': true,
            'data': {
              'id': 4,
              'principal_kind': 'teacher',
              'full_name': 'Teacher',
            },
          });
        }
        return _json(status, {
          'success': false,
          'message': status == 403
              ? 'Permission denied by server.'
              : 'Endpoint is not enabled.',
          'code': status == 403 ? 'permission_denied' : 'not_found',
        });
      }),
    ),
  );
  await api.restore();
  return _StatusFixture(
    app: app,
    controller: StaffOperationsController(
      api: api,
      module: staffOperationModuleById('risk')!,
    ),
  );
}

final class _StatusFixture {
  const _StatusFixture({required this.app, required this.controller});

  final AppState app;
  final StaffOperationsController controller;

  Widget host(Widget child) {
    final colors = sfColorsFor(SfPalette.daryo);
    return AppScope(
      notifier: app,
      child: SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        reducedMotion: true,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('uz'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildMaterialTheme(colors, dark: false),
          home: child,
        ),
      ),
    );
  }

  Widget routerHost(GoRouter router) {
    final colors = sfColorsFor(SfPalette.daryo);
    return AppScope(
      notifier: app,
      child: SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        reducedMotion: true,
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: const [Locale('uz'), Locale('en')],
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

  void dispose() {
    controller.dispose();
    app.dispose();
  }
}

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
