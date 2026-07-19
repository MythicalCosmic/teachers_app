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
import 'package:starforge_staff/screens/settings_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host(AppState state, Widget screen) {
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
        home: screen,
      ),
    ),
  );
}

Future<AppState> _localState({bool signedIn = false}) async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  if (signedIn) {
    await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  }
  return state;
}

Future<AppState> _productionState() async {
  const connection = TenantConnection(
    slug: 'starforge-academy',
    name: 'StarForge Academy',
    baseUrl: 'https://tenant.example',
    wsUrl: '',
    locale: 'en',
  );
  final vault = MemorySessionVault(
    const StoredSession(
      accessToken: 'access-token',
      connection: connection,
      deviceId: 'test-device',
    ),
  );
  final httpClient = MockClient((request) async {
    expect(request.method, 'GET');
    expect(request.url.path, '/api/v1/users/me/');
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'id': 'teacher-1',
          'principal_kind': 'teacher',
          'username': 'nigora',
          'full_name': 'Nigora Karimova',
          'email': 'nigora@example.com',
          'role_memberships': <Object?>[],
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  final api = StarforgeApi(
    client: ApiClient(httpClient: httpClient),
    vault: vault,
    platformBaseUrl: 'https://platform.example',
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

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'nigora');
  await tester.enterText(find.byType(TextField).at(1), 'correct-password');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'login starts blank and contains no demo credentials or identity',
    (tester) async {
      final state = (await tester.runAsync(_localState))!;

      await tester.pumpWidget(_host(state, const LoginScreen()));
      await tester.pump();

      final username = tester.widget<TextField>(find.byType(TextField).first);
      expect(username.controller?.text, isEmpty);
      expect(find.textContaining('demo2026'), findsNothing);
      expect(find.text('Demo Akademiya'), findsNothing);
      expect(find.textContaining('staff.starforge.uz'), findsNothing);
      expect(find.text('Local development environment'), findsOneWidget);
    },
  );

  testWidgets('login identifies the configured production center and host', (
    tester,
  ) async {
    final state = (await tester.runAsync(_productionState))!;

    await tester.pumpWidget(_host(state, const LoginScreen()));
    await tester.pump();

    expect(state.isProduction, isTrue);
    expect(find.text('StarForge Academy'), findsOneWidget);
    expect(find.text('tenant.example'), findsOneWidget);
    expect(find.textContaining('/api'), findsNothing);
  });

  testWidgets('network authentication failure is clear and retryable', (
    tester,
  ) async {
    final state = (await tester.runAsync(_localState))!;

    await tester.pumpWidget(
      _host(
        state,
        LoginScreen(
          onSignIn:
              ({
                required username,
                required password,
                required persistSession,
              }) async {
                throw const AuthenticationException(
                  'Server bilan bog‘lanib bo‘lmadi. Internetni tekshiring.',
                );
              },
        ),
      ),
    );

    await _fillAndSubmit(tester);

    expect(find.text('Connection problem'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('throttled authentication asks the user to wait without retry', (
    tester,
  ) async {
    final state = (await tester.runAsync(_localState))!;

    await tester.pumpWidget(
      _host(
        state,
        LoginScreen(
          onSignIn:
              ({
                required username,
                required password,
                required persistSession,
              }) async {
                throw const AuthenticationException(
                  'Juda ko‘p urinish. Biroz kuting.',
                );
              },
        ),
      ),
    );

    await _fillAndSubmit(tester);

    expect(find.text('Too many attempts'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
  });

  testWidgets('demo reset is hidden in production and remains in local mode', (
    tester,
  ) async {
    final production = (await tester.runAsync(_productionState))!;
    expect(production.session, isNotNull, reason: production.syncError);

    await tester.pumpWidget(_host(production, const SettingsScreen()));
    await tester.pump();
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reset demo data'), findsNothing);

    final local = (await tester.runAsync(() => _localState(signedIn: true)))!;
    await tester.pumpWidget(_host(local, const SettingsScreen()));
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reset demo data'), findsOneWidget);
  });
}
