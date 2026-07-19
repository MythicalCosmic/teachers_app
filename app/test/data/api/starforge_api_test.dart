import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';

void main() {
  group('StarforgeApi authentication', () {
    test('role-login and me both go directly to the tenant host', () async {
      final requests = <http.Request>[];
      final vault = _RecordingVault();
      final api = StarforgeApi(
        platformBaseUrl: 'https://staff-tenant.example/',
        vault: vault,
        client: ApiClient(
          random: Random(11),
          httpClient: MockClient((request) async {
            requests.add(request);
            return switch (request.url.path) {
              '/api/v1/auth/role-login/' => _jsonResponse(200, {
                'success': true,
                'data': {
                  'access': 'role-token',
                  'role': 'teacher',
                  'must_change_password': true,
                },
              }),
              '/api/v1/users/me/' => _jsonResponse(200, {
                'success': true,
                'data': {
                  'id': 91,
                  'full_name': 'Aziz Teacher',
                  'principal_kind': 'teacher',
                },
              }),
              _ => _jsonResponse(404, {
                'success': false,
                'code': 'not_found',
                'message': 'Unexpected route',
              }),
            };
          }),
        ),
      )..setLocale('en');

      final identity = await api.signIn(
        centerSlug: '',
        username: '  aziz.teacher  ',
        password: 'secret-password',
        remember: true,
      );

      expect(requests.map((request) => request.url.path), [
        '/api/v1/auth/role-login/',
        '/api/v1/users/me/',
      ]);
      expect(
        requests.map((request) => request.url.origin),
        everyElement('https://staff-tenant.example'),
      );
      expect(
        jsonDecode(requests.first.body),
        containsPair('username', 'aziz.teacher'),
      );
      expect(_header(requests.first, 'authorization'), isNull);
      expect(_header(requests.first, 'accept-language'), 'en');
      expect(_header(requests.last, 'authorization'), 'Bearer role-token');
      expect(identity.principalKind, 'teacher');
      expect(identity.mustChangePassword, isTrue);
      expect(identity.profile['full_name'], 'Aziz Teacher');
      expect(api.hasSession, isTrue);
      expect(vault.value?.accessToken, 'role-token');
    });

    test('remember false keeps only the in-memory session', () async {
      final vault = _RecordingVault();
      final api = _signInApi(vault: vault);

      final identity = await api.signIn(
        centerSlug: '',
        username: 'teacher',
        password: 'password',
        remember: false,
      );

      expect(identity.accessToken, 'token-1');
      expect(api.hasSession, isTrue);
      expect(vault.value, isNull);
      expect(vault.writeCount, 0);
      expect(vault.clearCount, 1);
      expect(vault.deviceId, isNotEmpty);
      expect(api.deviceId, vault.deviceId);
    });

    test(
      'remember true restores the session and its tenant connection',
      () async {
        final vault = _RecordingVault();
        final api = _signInApi(vault: vault);

        await api.signIn(
          centerSlug: '',
          username: 'teacher',
          password: 'password',
          remember: true,
        );
        final restoredApi = StarforgeApi(
          platformBaseUrl: 'https://different-platform.example',
          vault: vault,
          client: ApiClient(
            random: Random(13),
            httpClient: MockClient((request) async {
              expect(request.url.origin, 'https://staff-tenant.example');
              expect(request.url.path, '/api/v1/users/me/');
              expect(_header(request, 'authorization'), 'Bearer token-1');
              return _profileResponse();
            }),
          ),
        );

        final restored = await restoredApi.restore();

        expect(restored, isNotNull);
        expect(restored!.accessToken, 'token-1');
        expect(restored.connection.baseUrl, 'https://staff-tenant.example');
        expect(restored.principalKind, 'teacher');
        expect(restoredApi.hasSession, isTrue);
      },
    );

    test('the device id remains stable across unremembered sign-ins', () async {
      final roleLoginDeviceIds = <String>[];
      var loginNumber = 0;
      final vault = _RecordingVault();
      final api = StarforgeApi(
        platformBaseUrl: 'https://staff-tenant.example',
        vault: vault,
        client: ApiClient(
          random: Random(14),
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/v1/auth/role-login/') {
              loginNumber++;
              final body = Map<String, Object?>.from(
                jsonDecode(request.body) as Map,
              );
              roleLoginDeviceIds.add(body['device_id']! as String);
              return _jsonResponse(200, {
                'success': true,
                'data': {'access': 'token-$loginNumber', 'role': 'teacher'},
              });
            }
            if (request.url.path == '/api/v1/users/me/') {
              return _profileResponse();
            }
            return _jsonResponse(404, {
              'success': false,
              'code': 'not_found',
              'message': 'Unexpected route',
            });
          }),
        ),
      );

      await api.signIn(
        centerSlug: '',
        username: 'teacher',
        password: 'password',
        remember: false,
      );
      await api.signOut(remote: false);
      await api.signIn(
        centerSlug: '',
        username: 'teacher',
        password: 'password',
        remember: true,
      );

      expect(roleLoginDeviceIds, hasLength(2));
      expect(roleLoginDeviceIds.toSet(), hasLength(1));
      expect(roleLoginDeviceIds.first, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(vault.deviceWriteCount, 2);
      expect(vault.value?.deviceId, roleLoginDeviceIds.first);
    });

    test(
      'a protected 401 clears both runtime and remembered session',
      () async {
        var requestCount = 0;
        var invalidationCount = 0;
        final vault = _RecordingVault();
        final api = StarforgeApi(
          platformBaseUrl: 'https://staff-tenant.example',
          vault: vault,
          client: ApiClient(
            random: Random(15),
            httpClient: MockClient((request) async {
              requestCount++;
              if (request.url.path == '/api/v1/auth/role-login/') {
                return _jsonResponse(200, {
                  'success': true,
                  'data': {'access': 'expired-later', 'role': 'teacher'},
                });
              }
              if (request.url.path == '/api/v1/users/me/') {
                return _profileResponse();
              }
              if (request.url.path == '/api/v1/tasks/mine/') {
                return _jsonResponse(
                  401,
                  {
                    'success': false,
                    'code': 'authentication_failed',
                    'message': 'Session expired',
                  },
                  headers: {'x-request-id': 'expired-session-request'},
                );
              }
              return _jsonResponse(404, {
                'success': false,
                'code': 'not_found',
                'message': 'Unexpected route',
              });
            }),
          ),
        );
        api.setAuthenticationRequiredHandler(() async {
          invalidationCount++;
        });
        await api.signIn(
          centerSlug: '',
          username: 'teacher',
          password: 'password',
          remember: true,
        );

        final error = await _captureError(api.get('/api/v1/tasks/mine/'));

        expect(error.statusCode, 401);
        expect(error.code, 'authentication_failed');
        expect(error.requestId, 'expired-session-request');
        expect(api.hasSession, isFalse);
        expect(vault.value, isNull);
        expect(invalidationCount, 1);
        final callsAfter401 = requestCount;
        final localError = await _captureError(
          api.get('/api/v1/teachers/dashboard/'),
        );
        expect(localError.isSessionExpired, isTrue);
        expect(requestCount, callsAfter401);
      },
    );
  });
}

StarforgeApi _signInApi({required _RecordingVault vault}) {
  var loginCount = 0;
  return StarforgeApi(
    platformBaseUrl: 'https://staff-tenant.example',
    vault: vault,
    client: ApiClient(
      random: Random(12),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/role-login/') {
          loginCount++;
          return _jsonResponse(200, {
            'success': true,
            'data': {'access': 'token-$loginCount', 'role': 'teacher'},
          });
        }
        if (request.url.path == '/api/v1/users/me/') {
          return _profileResponse();
        }
        return _jsonResponse(404, {
          'success': false,
          'code': 'not_found',
          'message': 'Unexpected route',
        });
      }),
    ),
  );
}

final class _RecordingVault implements SessionVault {
  StoredSession? value;
  String? deviceId;
  int writeCount = 0;
  int clearCount = 0;
  int deviceWriteCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
    value = null;
  }

  @override
  Future<StoredSession?> read() async => value;

  @override
  Future<String?> readDeviceId() async => deviceId ?? value?.deviceId;

  @override
  Future<void> write(StoredSession session) async {
    writeCount++;
    value = session;
  }

  @override
  Future<void> writeDeviceId(String value) async {
    deviceWriteCount++;
    deviceId = value;
  }
}

Future<ApiException> _captureError(Future<Object?> operation) async {
  try {
    await operation;
    fail('Expected ApiException');
  } on ApiException catch (error) {
    return error;
  }
}

http.Response _profileResponse() => _jsonResponse(200, {
  'success': true,
  'data': {
    'id': 1,
    'full_name': 'Teacher Account',
    'principal_kind': 'teacher',
  },
});

http.Response _jsonResponse(
  int statusCode,
  Object body, {
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json', ...headers},
);

String? _header(http.Request request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
