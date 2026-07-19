import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_learning_api.dart';
import 'package:starforge_staff/data/api/backend_services_api.dart';
import 'package:starforge_staff/data/api/backend_work_api.dart';

void main() {
  group('backend contract adapters', () {
    test(
      'list adapters request page_size 100 and preserve unknown states',
      () async {
        final transport = _FakeTransport()
          ..responses.add(
            _response(
              data: [
                {
                  'id': 4,
                  'title': 'Speaking lab',
                  'status': 'rescheduled_by_ai',
                  'room': null,
                  'starts_at': null,
                },
              ],
              pagination: {
                'total': 1,
                'page': 1,
                'page_size': 100,
                'pages': 1,
                'has_next': false,
                'has_prev': false,
              },
              warnings: const ['notifications is degraded'],
            ),
          );
        final api = BackendLearningApi(transport);

        final result = await api.lessons(status: 'scheduled');

        expect(result.isAvailable, isTrue);
        expect(result.warnings, ['notifications is degraded']);
        expect(result.value!.items.single.status, 'rescheduled_by_ai');
        expect(result.value!.items.single.hasKnownStatus, isFalse);
        expect(result.value!.items.single.roomId, isNull);
        expect(result.value!.items.single.startsAt, isNull);
        expect(transport.calls.single.path, '/api/v1/schedule/lessons/');
        expect(transport.calls.single.query['page_size'], 100);
        expect(transport.calls.single.query['status'], 'scheduled');
      },
    );

    test(
      'attendance mark sends the source-required top-level JSON array',
      () async {
        final transport = _FakeTransport()
          ..responses.add(
            _response(
              data: {
                'created': 1,
                'updated': 0,
                'records': [
                  {'id': 9, 'student': 42, 'lesson': 7, 'status': 'present'},
                ],
              },
            ),
          );
        final api = BackendLearningApi(transport);

        final result = await api.markAttendance(7, const [
          BackendAttendanceEntry(
            studentId: 42,
            status: 'present',
            note: 'On time',
          ),
        ]);

        expect(result.value!.created, 1);
        expect(transport.calls.single.method, 'POST');
        expect(transport.calls.single.body, isA<List<Object?>>());
        expect((transport.calls.single.body! as List).single, {
          'student': 42,
          'status': 'present',
          'note': 'On time',
        });
      },
    );

    test('403 and scoped 404 become per-module unavailable results', () async {
      final transport = _FakeTransport()
        ..errors.addAll(const [
          ApiException(
            message: 'Forbidden',
            statusCode: 403,
            code: 'forbidden',
          ),
          ApiException(
            message: 'Not a teacher',
            statusCode: 404,
            code: 'not_a_teacher',
          ),
        ]);
      final work = BackendWorkApi(transport);
      final learning = BackendLearningApi(transport);

      final taskResult = await work.myTasks();
      final dashboardResult = await learning.teacherDashboard();

      expect(taskResult.isUnavailable, isTrue);
      expect(taskResult.error!.statusCode, 403);
      expect(dashboardResult.isUnavailable, isTrue);
      expect(dashboardResult.error!.code, 'not_a_teacher');
    });

    test(
      'global 500 failures still throw instead of hiding a broken refresh',
      () async {
        final transport = _FakeTransport()
          ..errors.add(
            const ApiException(
              message: 'Down',
              statusCode: 500,
              code: 'server_error',
            ),
          );

        await expectLater(
          BackendWorkApi(transport).notifications(),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'statusCode',
              500,
            ),
          ),
        );
      },
    );

    test('bare cursor notifications retain next and previous links', () async {
      final transport = _FakeTransport()
        ..responses.add(
          _response(
            data: [
              {
                'id': 1,
                'event_type': 'future_event',
                'title': 'Updated',
                'data': null,
              },
            ],
            pagination: {
              'next': 'https://tenant/api/v1/notifications/?cursor=next',
              'previous': null,
            },
          ),
        );

      final result = await BackendWorkApi(transport).notifications();

      expect(result.value!.items.single.eventType, 'future_event');
      expect(result.value!.items.single.data, isEmpty);
      expect(result.value!.next, contains('cursor=next'));
      expect(result.value!.previous, isNull);
      expect(transport.calls.single.query['page_size'], 100);
    });

    test(
      'upload adapters distinguish multipart POST from content PUT',
      () async {
        final transport = _FakeTransport()
          ..responses.addAll([
            _response(
              data: {
                'url': 'https://s3.example/form',
                'method': 'POST',
                'key': 'tenant/messages/a.png',
                'fields': {'policy': 'opaque'},
              },
            ),
            _response(
              data: {
                'file_id': 90,
                'url': 'https://s3.example/object',
                'key': 'tenant/content/a.pdf',
                'expires_in': 600,
              },
            ),
          ]);
        final work = BackendWorkApi(transport);
        final services = BackendServicesApi(transport);

        final message = await work.messageUploadGrant(
          filename: 'a.png',
          sizeBytes: 12,
          contentType: 'image/png',
        );
        final content = await services.contentUploadGrant(
          filename: 'a.pdf',
          contentType: 'application/pdf',
          sizeBytes: 30,
          folderId: 8,
        );

        expect(message.value!.method, 'POST');
        expect(message.value!.fields['policy'], 'opaque');
        expect(content.value!.method, 'PUT');
        expect(content.value!.fileId, 90);
        expect(content.value!.expiresIn, 600);
      },
    );

    test(
      'task assignment can explicitly clear nullable server fields',
      () async {
        final transport = _FakeTransport()
          ..responses.add(_response(data: {'id': 2, 'title': 'Follow up'}));

        await BackendWorkApi(transport).assignTask(
          2,
          setAssignee: true,
          assigneeId: null,
          setDepartment: true,
          departmentId: null,
        );

        expect(transport.calls.single.body, {
          'assignee': null,
          'department': null,
        });
      },
    );
  });
}

ApiResponse _response({
  Object? data,
  Object? pagination,
  int statusCode = 200,
  List<String> warnings = const [],
}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: statusCode,
  requestId: 'test-request',
  warnings: warnings,
);

final class _Call {
  const _Call({
    required this.method,
    required this.path,
    required this.query,
    this.body,
  });

  final String method;
  final String path;
  final Map<String, Object?> query;
  final Object? body;
}

final class _FakeTransport implements BackendTransport {
  final List<ApiResponse> responses = [];
  final List<ApiException> errors = [];
  final List<_Call> calls = [];

  Future<ApiResponse> _next(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) async {
    calls.add(_Call(method: method, path: path, query: query, body: body));
    if (errors.isNotEmpty) throw errors.removeAt(0);
    if (responses.isEmpty) {
      throw StateError('No fake response queued for $method $path');
    }
    return responses.removeAt(0);
  }

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      _next('DELETE', path, body: body);

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) => _next('GET', path, query: query);

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      _next('PATCH', path, body: body);

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) => _next('POST', path, body: body);

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      _next('PUT', path, body: body);
}
