import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/router.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _forcedPasswordState(List<http.Request> requests) async {
  const connection = TenantConnection(
    slug: 'staff-tenant',
    name: 'Staff tenant',
    baseUrl: 'https://staff-tenant.example',
    wsUrl: '',
    locale: 'en',
  );
  final api = StarforgeApi(
    vault: MemorySessionVault(
      const StoredSession(
        accessToken: 'temporary-session',
        connection: connection,
        deviceId: 'test-device',
      ),
    ),
    client: ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/users/me/') {
          return _json(200, {
            'success': true,
            'data': {
              'id': 17,
              'full_name': 'Nodira Teacher',
              'username': 'nodira',
              'principal_kind': 'teacher',
              'must_change_password': true,
              'role_memberships': <Object?>[],
            },
          });
        }
        if (request.url.path == '/api/v1/auth/password/change/') {
          return _json(200, {
            'success': true,
            'data': {'access': 'rotated-session'},
          });
        }
        return _json(200, {
          'success': true,
          'data': <Object?>[],
          'pagination': {'count': 0, 'next': null, 'previous': null},
        });
      }),
    ),
    platformBaseUrl: 'https://staff-tenant.example',
  );
  final state = await AppState.bootstrap(storage: MemoryAppStorage(), api: api);
  if (!state.isInitialized) {
    final ready = Completer<void>();
    void listener() {
      if (state.isInitialized && !ready.isCompleted) ready.complete();
    }

    state.addListener(listener);
    listener();
    await ready.future.timeout(const Duration(seconds: 2));
    state.removeListener(listener);
  }
  return state;
}

Widget _routerHost(AppState state) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp.router(
        locale: const Locale('en'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        routerConfig: buildRouter(state, initialLocation: '/home'),
      ),
    ),
  );
}

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  testWidgets(
    'temporary-password session cannot enter workspace until changed',
    (tester) async {
      final requests = <http.Request>[];
      final state = (await tester.runAsync(
        () => _forcedPasswordState(requests),
      ))!;

      await tester.pumpWidget(_routerHost(state));
      await tester.pumpAndSettle();

      expect(state.session?.mustChangePassword, isTrue);
      expect(find.text('Create a new password'), findsOneWidget);
      expect(find.text('Today'), findsNothing);

      await tester.enterText(find.byType(TextFormField).at(0), 'Temp-pass-12');
      await tester.enterText(find.byType(TextFormField).at(1), 'Orbit-safe-93');
      await tester.enterText(find.byType(TextFormField).at(2), 'Orbit-safe-93');
      await tester.tap(find.text('Save password'));
      await tester.pumpAndSettle();

      expect(state.session?.mustChangePassword, isFalse);
      expect(find.text('Create a new password'), findsNothing);
      expect(find.text('Ish maydonini ochish'), findsOneWidget);
      final passwordRequest = requests.singleWhere(
        (request) => request.url.path == '/api/v1/auth/password/change/',
      );
      expect(passwordRequest.method, 'POST');
      expect(jsonDecode(passwordRequest.body), {
        'old_password': 'Temp-pass-12',
        'new_password': 'Orbit-safe-93',
      });
      expect(state.backendApi?.currentAccessToken, 'rotated-session');
    },
  );
}
