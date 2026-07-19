import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';

void main() {
  group('ApiClient', () {
    test(
      'uses the tenant host for legacy login and authenticated me',
      () async {
        final requests = <http.Request>[];
        final transport = MockClient((request) async {
          requests.add(request);
          return switch (request.url.path) {
            '/api/v1/auth/login/' => _jsonResponse(200, {
              'success': true,
              'data': {'access': 'legacy-token'},
            }),
            '/api/v1/users/me/' => _jsonResponse(200, {
              'success': true,
              'data': {'id': 17, 'principal_kind': 'teacher'},
            }),
            _ => _jsonResponse(404, {
              'success': false,
              'code': 'not_found',
              'message': 'Unexpected route',
            }),
          };
        });
        final client = ApiClient(httpClient: transport, random: Random(1));

        final login = await client.post(
          'https://teacher-center.example/',
          '/api/v1/auth/login/',
          locale: 'en',
          body: {
            'username': 'aziz.teacher',
            'password': 'secret-password',
            'device_id': 'device-1',
            'platform': 'ios',
          },
        );
        final access = (login.data! as Map)['access']! as String;
        final profile = await client.get(
          'https://teacher-center.example',
          'api/v1/users/me/',
          token: access,
          locale: 'en',
        );

        expect(requests, hasLength(2));
        expect(
          requests.map((request) => request.url.origin),
          everyElement('https://teacher-center.example'),
        );
        expect(requests[0].url.path, '/api/v1/auth/login/');
        expect(requests[1].url.path, '/api/v1/users/me/');
        expect(_header(requests[0], 'authorization'), isNull);
        expect(_header(requests[0], 'accept'), 'application/json');
        expect(_header(requests[0], 'accept-language'), 'en');
        expect(
          _header(requests[0], 'content-type'),
          'application/json; charset=utf-8',
        );
        expect(_header(requests[0], 'x-request-id'), _uuidV4Pattern);
        expect(
          jsonDecode(requests[0].body),
          containsPair('device_id', 'device-1'),
        );
        expect(_header(requests[1], 'authorization'), 'Bearer legacy-token');
        expect(profile.data, containsPair('principal_kind', 'teacher'));
      },
    );

    test('decodes the standard envelope, pagination, and warnings', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return _jsonResponse(
            200,
            {
              'success': true,
              'data': [
                {'id': 1},
                {'id': 2},
              ],
              'pagination': {
                'total': 42,
                'page': 2,
                'page_size': 2,
                'pages': 21,
                'has_next': true,
                'has_prev': true,
              },
              'warnings': ['AI summaries are temporarily delayed.'],
            },
            headers: {'x-request-id': 'server-request-id'},
          );
        }),
        random: Random(2),
      );

      final response = await client.get(
        'https://tenant.example',
        '/api/v1/tasks/mine/',
        token: 'access-token',
        locale: 'ru',
        query: {'page': 2, 'page_size': 2, 'empty': '', 'ignored': null},
      );

      expect(response.statusCode, 200);
      expect(response.requestId, 'server-request-id');
      expect(response.data, hasLength(2));
      expect(response.pagination, containsPair('total', 42));
      expect(response.warnings, ['AI summaries are temporarily delayed.']);
      expect(captured.url.queryParameters, {'page': '2', 'page_size': '2'});
      expect(_header(captured, 'authorization'), 'Bearer access-token');
      expect(_header(captured, 'accept-language'), 'ru');
    });

    test('decodes bare audit and notification cursor envelopes', () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => _jsonResponse(200, {
            'results': [
              {'id': 9, 'event': 'attendance.updated'},
            ],
            'next': 'https://tenant.example/api/v1/audit/?cursor=older',
            'previous': null,
          }),
        ),
        random: Random(3),
      );

      final response = await client.get(
        'https://tenant.example',
        '/api/v1/audit/',
        token: 'access-token',
      );

      expect(response.data, [
        {'id': 9, 'event': 'attendance.updated'},
      ]);
      expect(
        response.pagination,
        equals({
          'next': 'https://tenant.example/api/v1/audit/?cursor=older',
          'previous': null,
        }),
      );
    });

    test(
      'retries an idempotent GET up to three times with one request id',
      () async {
        var attempts = 0;
        final requestIds = <String?>[];
        final client = ApiClient(
          httpClient: MockClient((request) async {
            attempts++;
            requestIds.add(_header(request, 'x-request-id'));
            if (attempts < 3) {
              return _jsonResponse(503, {
                'success': false,
                'code': 'service_unavailable',
                'message': 'Try again',
              });
            }
            return _jsonResponse(200, {
              'success': true,
              'data': {'ready': true},
            });
          }),
          random: Random(4),
        );

        final response = await client.get(
          'https://tenant.example',
          '/api/v1/teachers/dashboard/',
          token: 'access-token',
        );

        expect(attempts, 3);
        expect(requestIds.toSet(), hasLength(1));
        expect(requestIds.first, _uuidV4Pattern);
        expect(response.data, {'ready': true});
      },
    );

    test('maps a 403 response to a forbidden ApiException', () async {
      final client = _errorClient(
        403,
        code: 'forbidden',
        message: 'No permission',
      );

      final error = await _captureError(
        client.get('https://tenant.example', '/api/v1/audit/'),
      );

      expect(error.statusCode, 403);
      expect(error.code, 'forbidden');
      expect(error.message, 'No permission');
      expect(error.isForbidden, isTrue);
    });

    test('maps a 409 response with field details', () async {
      late http.Request captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request;
          return _jsonResponse(409, {
            'success': false,
            'code': 'conflict',
            'message': 'Lesson overlaps another lesson.',
            'errors': {
              'starts_at': ['Conflicts with lesson 21'],
              'room': 'Already occupied',
            },
          });
        }),
        random: Random(6),
      );

      final error = await _captureError(
        client.post(
          'https://tenant.example',
          '/api/v1/schedule/lessons/',
          body: {'room': 4},
          idempotencyKey: 'logical-operation-id',
        ),
      );

      expect(error.statusCode, 409);
      expect(error.code, 'conflict');
      expect(error.fields['starts_at'], ['Conflicts with lesson 21']);
      expect(error.fields['room'], ['Already occupied']);
      expect(_header(captured, 'idempotency-key'), 'logical-operation-id');
    });

    test('maps a 429 response and exposes Retry-After', () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => _jsonResponse(
            429,
            {'success': false, 'code': 'throttled', 'message': 'Slow down'},
            headers: {
              'retry-after': '17',
              'x-request-id': 'rate-limit-request',
            },
          ),
        ),
        random: Random(7),
      );

      final error = await _captureError(
        client.get('https://tenant.example', '/api/v1/notifications/'),
      );

      expect(error.statusCode, 429);
      expect(error.code, 'throttled');
      expect(error.retryAfter, const Duration(seconds: 17));
      expect(error.requestId, 'rate-limit-request');
    });
  });
}

ApiClient _errorClient(
  int status, {
  required String code,
  required String message,
}) => ApiClient(
  httpClient: MockClient(
    (_) async => _jsonResponse(status, {
      'success': false,
      'code': code,
      'message': message,
    }),
  ),
  random: Random(5),
);

Future<ApiException> _captureError(Future<Object?> operation) async {
  try {
    await operation;
    fail('Expected ApiException');
  } on ApiException catch (error) {
    return error;
  }
}

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

final _uuidV4Pattern = matches(
  RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ),
);
