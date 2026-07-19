import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_services_api.dart';
import 'package:starforge_staff/features/services/backend_services_controllers.dart';

void main() {
  group('BackendContentController', () {
    test(
      'loads the hierarchy, paginates files, and persists exact approval',
      () async {
        final transport = _FakeTransport()
          ..responses.addAll([
            _page([
              {
                'id': 1,
                'name': 'Staff library',
                'visibility': 'tenant',
                'is_active': true,
              },
            ]),
            _page([
              {'id': 11, 'library': 1, 'title': 'Algebra', 'order': 1},
            ]),
            _page([
              {'id': 21, 'library': 1, 'name': 'Shared'},
            ]),
            _page([
              {
                'id': 31,
                'title': 'Worksheet',
                'content_type': 'application/pdf',
                'size_bytes': 1024,
                'status': 'clean',
                'version': 1,
                'is_approved_teacher': false,
                'is_approved_manager': false,
              },
            ], hasNext: true),
            _page([
              {
                'id': 41,
                'library': 1,
                'library_name': 'Staff library',
                'title': 'Revision guide',
                'status': 'draft',
              },
            ]),
            _page([
              {'id': 12, 'course': 11, 'title': 'Linear equations', 'order': 1},
            ]),
            _page([
              {'id': 13, 'module': 12, 'title': 'Practice', 'order': 1},
            ]),
            _page([
              {
                'id': 32,
                'title': 'Answer key',
                'content_type': 'application/pdf',
                'size_bytes': 800,
                'status': 'pending',
                'version': 1,
              },
            ], page: 2),
            _response(
              data: {
                'id': 31,
                'title': 'Worksheet',
                'content_type': 'application/pdf',
                'size_bytes': 1024,
                'status': 'clean',
                'version': 1,
                'is_approved_teacher': true,
                'is_approved_manager': false,
              },
            ),
          ]);
        final controller = BackendContentController(
          BackendServicesApi(transport),
        );

        await controller.refresh();

        expect(controller.phase, BackendLoadPhase.ready);
        expect(controller.selectedLibraryId, 1);
        expect(controller.courses.single.title, 'Algebra');
        expect(controller.modules.single.title, 'Linear equations');
        expect(controller.lessons.single.title, 'Practice');
        expect(controller.folders.single.title, 'Shared');
        expect(controller.files.single.title, 'Worksheet');
        expect(controller.materials.single.title, 'Revision guide');
        expect(controller.hasMoreFiles, isTrue);

        await controller.loadMoreFiles();
        expect(controller.files.map((item) => item.id), [31, 32]);
        final pageTwoCall = transport.calls.firstWhere(
          (call) =>
              call.path == '/api/v1/content/files/' && call.query['page'] == 2,
        );
        expect(pageTwoCall.query['page_size'], 100);

        final approved = await controller.approveTeacher(31);
        expect(approved.approvedByTeacher, isTrue);
        expect(controller.files.first.approvedByTeacher, isTrue);
        expect(
          transport.calls.last.path,
          '/api/v1/content/files/31/approve-teacher/',
        );
        expect(transport.calls.last.method, 'POST');

        controller.dispose();
      },
    );

    test(
      'treats scoped 403 as unavailable rather than fake empty content',
      () async {
        final transport = _FakeTransport()
          ..errors.add(
            const ApiException(
              message: 'Forbidden',
              statusCode: 403,
              code: 'forbidden',
            ),
          );
        final controller = BackendContentController(
          BackendServicesApi(transport),
        );

        await controller.refresh();

        expect(controller.phase, BackendLoadPhase.unavailable);
        expect(controller.libraries, isEmpty);
        controller.dispose();
      },
    );

    test('requests a fresh media URL and records a best-effort view', () async {
      final transport = _FakeTransport()
        ..responses.addAll([
          _response(data: {'url': 'https://media.example/signed/video.mp4'}),
          _response(),
          _response(data: {'url': 'https://media.example/signed/video-v2.mp4'}),
          _response(),
        ]);
      final controller = BackendContentController(
        BackendServicesApi(transport),
      );

      final url = await controller.requestPlaybackUrl(44);
      final refreshedUrl = await controller.requestPlaybackUrl(44);

      expect(url, 'https://media.example/signed/video.mp4');
      expect(refreshedUrl, 'https://media.example/signed/video-v2.mp4');
      expect(transport.calls, hasLength(4));
      expect(transport.calls.map((call) => call.path), [
        '/api/v1/content/files/44/download-url/',
        '/api/v1/content/files/44/track-view/',
        '/api/v1/content/files/44/download-url/',
        '/api/v1/content/files/44/track-view/',
      ]);
      controller.dispose();
    });
  });

  group('BackendPrintController', () {
    test(
      'reads jobs/printers and creates only the server-supported job shape',
      () async {
        final transport = _FakeTransport()
          ..responses.addAll([
            _page([
              {
                'id': 5,
                'branch': 3,
                'status': 'queued',
                'source': 'assignment',
                'source_id': 80,
                'payload_s3_key': 'tenant/assignment.pdf',
                'pages': 2,
                'copies': 1,
              },
            ]),
            _page([
              {
                'id': 7,
                'branch': 3,
                'name': 'Staff room',
                'model_name': 'LaserJet',
                'capabilities': {'duplex': true},
                'is_active': true,
              },
            ]),
            _response(
              data: {
                'id': 6,
                'branch': 3,
                'status': 'queued',
                'source': 'report',
                'source_id': 91,
                'payload_s3_key': 'tenant/report.pdf',
                'pages': 4,
                'copies': 2,
                'color': true,
                'duplex': true,
              },
            ),
          ]);
        final controller = BackendPrintController(
          BackendServicesApi(transport),
        );

        await controller.refresh();
        final job = await controller.createJob(
          source: 'report',
          sourceId: 91,
          payloadKey: 'tenant/report.pdf',
          branchId: 3,
          pages: 4,
          copies: 2,
          color: true,
          duplex: true,
        );

        expect(controller.jobs.length, 2);
        expect(controller.printers.single.name, 'Staff room');
        expect(job.id, 6);
        final call = transport.calls.last;
        expect(call.path, '/api/v1/printing/jobs/');
        expect(call.method, 'POST');
        expect(call.body, {
          'source': 'report',
          'source_id': 91,
          'payload_s3_key': 'tenant/report.pdf',
          'branch': 3,
          'pages': 4,
          'copies': 2,
          'color': true,
          'duplex': true,
        });
        controller.dispose();
      },
    );
  });

  group('BackendAiController', () {
    test(
      'uses real request, budget, list-shaped usage, and exam endpoints',
      () async {
        final transport = _FakeTransport()
          ..responses.addAll([
            _page([
              {
                'id': 10,
                'feature': 'content_summary',
                'status': 'succeeded',
                'input_tokens': 50,
                'output_tokens': 20,
                'cost_microusd': 1200,
              },
            ]),
            _response(
              data: {
                'daily_token_limit': 1000,
                'monthly_token_limit': 10000,
                'tokens_used_today': 70,
                'tokens_used_month': 500,
                'is_enabled': true,
              },
            ),
            _response(
              data: [
                {
                  'feature': 'content_summary',
                  'requests': 1,
                  'input_tokens': 50,
                  'output_tokens': 20,
                  'cost_microusd': 1200,
                },
              ],
            ),
            _response(data: {'request_id': 11}),
            _page([
              {'id': 11, 'feature': 'exam_generation', 'status': 'queued'},
            ]),
            _response(
              data: {
                'daily_token_limit': 1000,
                'monthly_token_limit': 10000,
                'tokens_used_today': 70,
                'tokens_used_month': 500,
                'is_enabled': true,
              },
            ),
            _response(
              data: [
                {
                  'feature': 'exam_generation',
                  'requests': 1,
                  'input_tokens': 0,
                  'output_tokens': 0,
                  'cost_microusd': 0,
                },
              ],
            ),
          ]);
        final controller = BackendAiController(BackendServicesApi(transport));

        await controller.refresh();
        expect(controller.requests.single.feature, 'content_summary');
        expect(controller.budget!.tokensUsedToday, 70);
        expect(controller.usage.single['requests'], 1);

        final queued = await controller.generateExam(
          subjectId: 9,
          examType: 'quiz',
          questionCount: 12,
          difficulty: 'hard',
        );
        expect(queued.requestId, 11);
        expect(queued.status, 'queued');
        final call = transport.calls.firstWhere(
          (value) => value.path == '/api/v1/ai/exam-generation/',
        );
        expect(call.body, {
          'subject_id': 9,
          'exam_type': 'quiz',
          'question_count': 12,
          'difficulty': 'hard',
        });
        expect(controller.requests.single.feature, 'exam_generation');
        controller.dispose();
      },
    );
  });

  group('BackendAuditController', () {
    test(
      'uses cursor tokens, preserves immutable detail, and applies filters',
      () async {
        final transport = _FakeTransport()
          ..responses.addAll([
            _cursorPage(
              [
                {
                  'id': 1,
                  'actor_username': 'teacher',
                  'action': 'task.updated',
                  'resource_type': 'tasks.task',
                  'resource_id': '9',
                  'before': {'status': 'open'},
                  'after': {'status': 'done'},
                },
              ],
              next:
                  'https://tenant.example/api/v1/audit/?cursor=opaque%2Btoken',
            ),
            _cursorPage([
              {
                'id': 2,
                'actor_username': 'teacher',
                'action': 'task.created',
                'resource_type': 'tasks.task',
                'resource_id': '10',
              },
            ]),
            _cursorPage([
              {
                'id': 3,
                'actor': 12,
                'action': 'lesson.updated',
                'resource_type': 'schedule.lesson',
                'resource_id': '7',
              },
            ]),
            _response(
              data: {
                'id': 3,
                'actor': 12,
                'actor_repr': 'Teacher Twelve',
                'action': 'lesson.updated',
                'resource_type': 'schedule.lesson',
                'resource_id': '7',
                'before': {'room': 1},
                'after': {'room': 2},
                'ip': '127.0.0.1',
              },
            ),
          ]);
        final controller = BackendAuditController(
          BackendServicesApi(transport),
        );

        await controller.refresh();
        expect(controller.hasMore, isTrue);
        await controller.loadMore();
        expect(controller.entries.map((item) => item.id), [1, 2]);
        final cursorCall = transport.calls[1];
        expect(cursorCall.query['cursor'], 'opaque+token');

        await controller.applyFilters(
          actor: 12,
          actionValue: 'lesson.updated',
          resourceTypeValue: 'schedule.lesson',
          resourceIdValue: '7',
        );
        final filterCall = transport.calls[2];
        expect(filterCall.query, containsPair('actor', 12));
        expect(filterCall.query, containsPair('action', 'lesson.updated'));
        expect(controller.entries.single.id, 3);

        final detail = await controller.entryDetail(3);
        expect(detail.before['room'], 1);
        expect(detail.after['room'], 2);
        expect(detail.actorRepresentation, 'Teacher Twelve');
        controller.dispose();
      },
    );
  });
}

ApiResponse _page(List<Object?> data, {int page = 1, bool hasNext = false}) =>
    _response(
      data: data,
      pagination: {
        'total': data.length + (hasNext ? 1 : 0),
        'page': page,
        'page_size': 100,
        'pages': hasNext ? page + 1 : page,
        'has_next': hasNext,
        'has_prev': page > 1,
      },
    );

ApiResponse _cursorPage(List<Object?> data, {String? next, String? previous}) =>
    _response(data: data, pagination: {'next': next, 'previous': previous});

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'services-test',
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
      throw StateError('No response queued for $method $path');
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
