import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/data/app_storage.dart';

const _connection = TenantConnection(
  slug: 'tenant',
  name: 'Tenant',
  baseUrl: 'https://tenant.example',
  wsUrl: '',
  locale: 'en',
);

void main() {
  test(
    'manager membership rejection revokes and clears a fresh token',
    () async {
      final paths = <String>[];
      final vault = MemorySessionVault();
      final api = _managerApi(vault: vault, paths: paths);
      final state = await AppState.bootstrap(
        storage: MemoryAppStorage(),
        api: api,
      );
      await _waitUntilInitialized(state);

      await expectLater(
        state.signIn(
          username: 'manager',
          password: 'valid-password',
          persistSession: true,
        ),
        throwsA(isA<AuthenticationException>()),
      );

      expect(paths, contains('/api/v1/auth/logout/'));
      expect(api.hasSession, isFalse);
      expect(vault.value, isNull);
      expect(state.session, isNull);
    },
  );

  test(
    'manager membership rejection clears a remembered token on restore',
    () async {
      final paths = <String>[];
      final vault = MemorySessionVault(
        const StoredSession(
          accessToken: 'remembered-manager-token',
          connection: _connection,
          deviceId: 'device-1',
        ),
      );
      final api = _managerApi(vault: vault, paths: paths);
      final state = await AppState.bootstrap(
        storage: MemoryAppStorage(),
        api: api,
      );
      await _waitUntilInitialized(state);

      expect(paths, contains('/api/v1/auth/logout/'));
      expect(api.hasSession, isFalse);
      expect(vault.value, isNull);
      expect(state.session, isNull);
      expect(state.syncError, isNotEmpty);
    },
  );

  test(
    'expired restore purges only its tenant cache before inbox initialization',
    () async {
      const tenantScope = 'tenant::https://tenant.example';
      const otherScope = 'other::https://shared.example/TenantPath';
      final tenantKey =
          'starforge.messaging.v1.${Uri.encodeComponent(tenantScope)}::77';
      final otherKey =
          'starforge.messaging.v1.${Uri.encodeComponent(otherScope)}::77';
      SharedPreferences.setMockInitialValues({
        tenantKey: '{"version":2}',
        otherKey: '{"version":2}',
      });
      final vault = MemorySessionVault(
        const StoredSession(
          accessToken: 'expired-token',
          connection: _connection,
          deviceId: 'device-expired',
        ),
      );
      final api = StarforgeApi(
        platformBaseUrl: _connection.baseUrl,
        vault: vault,
        client: ApiClient(
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'success': false,
                'code': 'authentication_failed',
                'message': 'Expired',
              }),
              401,
              headers: const {'content-type': 'application/json'},
            ),
          ),
        ),
      );

      final state = await AppState.bootstrap(
        storage: MemoryAppStorage(),
        api: api,
      );
      await _waitUntilInitialized(state);
      final preferences = await SharedPreferences.getInstance();

      expect(preferences.containsKey(tenantKey), isFalse);
      expect(preferences.containsKey(otherKey), isTrue);
      expect(api.hasSession, isFalse);
      expect(vault.value, isNull);
      expect(state.session, isNull);
    },
  );
}

StarforgeApi _managerApi({
  required MemorySessionVault vault,
  required List<String> paths,
}) => StarforgeApi(
  platformBaseUrl: _connection.baseUrl,
  vault: vault,
  client: ApiClient(
    httpClient: MockClient((request) async {
      paths.add(request.url.path);
      return switch (request.url.path) {
        '/api/v1/auth/role-login/' => _response({
          'access': 'manager-token',
          'role': 'staff',
        }),
        '/api/v1/users/me/' => _response({
          'id': 10,
          'principal_kind': 'staff',
          'username': 'manager',
          'full_name': 'Manager Account',
          'role_memberships': [
            {'account_type_slug': 'branch_manager', 'branch': '1'},
          ],
        }),
        '/api/v1/auth/logout/' => _response(const <String, Object?>{}),
        _ => http.Response(
          jsonEncode({
            'success': false,
            'code': 'not_found',
            'message': 'Unexpected route',
          }),
          404,
          headers: const {'content-type': 'application/json'},
        ),
      };
    }),
  ),
);

http.Response _response(Object data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: const {'content-type': 'application/json'},
);

Future<void> _waitUntilInitialized(AppState state) async {
  if (state.isInitialized) return;
  final ready = Completer<void>();
  void listener() {
    if (state.isInitialized && !ready.isCompleted) ready.complete();
  }

  state.addListener(listener);
  listener();
  await ready.future.timeout(const Duration(seconds: 2));
  state.removeListener(listener);
}
