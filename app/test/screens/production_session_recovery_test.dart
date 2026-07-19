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
import 'package:starforge_staff/screens/auth/login_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host(AppState state) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        home: const LoginScreen(),
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
  testWidgets('saved secure session can retry after startup network failure', (
    tester,
  ) async {
    var online = false;
    const connection = TenantConnection(
      slug: 'staff',
      name: 'Staff tenant',
      baseUrl: 'https://staff.example',
      wsUrl: '',
      locale: 'en',
    );
    final api = StarforgeApi(
      vault: MemorySessionVault(
        const StoredSession(
          accessToken: 'remembered-token',
          connection: connection,
          deviceId: 'device-1',
        ),
      ),
      client: ApiClient(
        httpClient: MockClient((request) async {
          if (!online) {
            return _json(503, {
              'success': false,
              'code': 'temporarily_unavailable',
              'message': 'Server temporarily unavailable.',
            });
          }
          if (request.url.path == '/api/v1/users/me/') {
            return _json(200, {
              'success': true,
              'data': {
                'id': 8,
                'principal_kind': 'teacher',
                'full_name': 'Recovered Teacher',
                'role_memberships': <Object?>[],
              },
            });
          }
          return _json(200, {
            'success': true,
            'data': <Object?>[],
            'pagination': {'has_next': false},
          });
        }),
      ),
    );
    final state = (await tester.runAsync(() async {
      final state = await AppState.bootstrap(
        storage: MemoryAppStorage(),
        api: api,
      );
      final ready = Completer<void>();
      void listener() {
        if (state.isInitialized && !ready.isCompleted) ready.complete();
      }

      state.addListener(listener);
      listener();
      await ready.future.timeout(const Duration(seconds: 8));
      state.removeListener(listener);
      return state;
    }))!;

    expect(state.session, isNull);
    expect(api.hasSession, isTrue);
    online = true;

    await tester.pumpWidget(_host(state));
    await tester.pumpAndSettle();
    expect(find.text('Server temporarily unavailable.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(state.session?.displayName, 'Recovered Teacher');
    expect(state.syncError, isNull);
    expect(find.text('Server temporarily unavailable.'), findsNothing);
    await state.backendNotifications?.pause();
    await tester.pump(const Duration(seconds: 2));
  });
}
