import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_learning_api.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/features/learning/learning_workspace_controller.dart';

void main() {
  test('read started during session restore waits and then loads', () async {
    final profileGate = Completer<http.Response>();
    final app = await _productionState(profileGate: profileGate);
    final transport = _LearningTransport(_dashboardResponder);
    final controller = LearningWorkspaceController(
      app,
      BackendLearningApi(transport),
    );
    addTearDown(() async {
      await _settleBackendStartup(app);
      controller.dispose();
      app.dispose();
    });

    expect(app.isInitialized, isFalse);
    final operation = controller.loadDashboard();
    await Future<void>.delayed(Duration.zero);
    expect(transport.calls, isEmpty);

    profileGate.complete(_profileResponse());
    await operation.timeout(const Duration(seconds: 2));

    expect(controller.dashboard.phase, LearningLoadPhase.ready);
    expect(controller.dashboard.value!.groupsCount, 3);
    expect(transport.calls.single.path, '/api/v1/teachers/dashboard/');
  });

  test(
    'cohort workspace loads exact group modules and selected range',
    () async {
      final app = await _readyProductionState();
      final transport = _LearningTransport(_cohortResponder);
      final controller = LearningWorkspaceController(
        app,
        BackendLearningApi(transport),
      );
      addTearDown(() async {
        await _settleBackendStartup(app);
        controller.dispose();
        app.dispose();
      });
      final range = LearningRange(
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 31, 23, 59),
      );

      await controller.loadCohort(42, range: range);

      final state = controller.cohortState(42);
      expect(state.cohort.value!.name, 'Server Algebra');
      expect(state.members.value!.single.studentId, 501);
      expect(state.lessons.value!.single.cohortId, 42);
      expect(state.attendance.value!.rate, 94.5);
      expect(state.history.value!.single.lessonId, 700);
      expect(
        transport.calls.map((call) => call.path),
        containsAll([
          '/api/v1/cohorts/42/',
          '/api/v1/cohorts/42/members/',
          '/api/v1/schedule/lessons/',
          '/api/v1/attendance/cohorts/42/dashboard/',
          '/api/v1/attendance/records/',
        ]),
      );
      final lessonCall = transport.calls.firstWhere(
        (call) => call.path == '/api/v1/schedule/lessons/',
      );
      expect(lessonCall.query['cohort'], 42);
      expect(
        lessonCall.query['date_from'],
        range.from.toUtc().toIso8601String(),
      );
      expect(
        DateTime.parse(
          lessonCall.query['date_to']! as String,
        ).isAfter(range.to.toUtc()),
        isTrue,
        reason: 'group schedules include enough future runway for next lesson',
      );
    },
  );

  test('schedule period follows every server page', () async {
    final from = DateTime(2026, 7, 1);
    final to = DateTime(2026, 7, 31, 23, 59, 59);
    final transport = _LearningTransport((call) {
      expect(call.path, '/api/v1/schedule/lessons/');
      final page = call.query['page']! as int;
      if (page == 1) {
        return _pagedResponse(
          [
            for (var index = 0; index < 100; index++)
              _lessonJson(id: 700 + index, startsAt: '2026-07-01T09:00:00Z'),
          ],
          page: 1,
          total: 101,
          pages: 2,
          hasNext: true,
        );
      }
      if (page == 2) {
        return _pagedResponse(
          [_lessonJson(id: 999, startsAt: '2026-07-30T09:00:00Z')],
          page: 2,
          total: 101,
          pages: 2,
        );
      }
      throw StateError('Unexpected schedule page: $page');
    });

    final result = await BackendLearningApi(
      transport,
    ).lessons(from: from, to: to, cohortId: 42);

    expect(result.value!.items, hasLength(101));
    expect(result.value!.items.last.id, 999);
    expect(transport.calls.map((call) => call.query['page']), [1, 2]);
    for (final call in transport.calls) {
      expect(call.query['page_size'], 100);
      expect(call.query['cohort'], 42);
      expect(call.query['date_from'], from.toUtc().toIso8601String());
      expect(call.query['date_to'], to.toUtc().toIso8601String());
      expect(call.query['ordering'], 'starts_at');
    }
  });

  test('attendance history follows every server page', () async {
    final from = DateTime(2026, 6, 1);
    final to = DateTime(2026, 6, 30, 23, 59, 59);
    final transport = _LearningTransport((call) {
      expect(call.path, '/api/v1/attendance/records/');
      final page = call.query['page']! as int;
      if (page == 1) {
        return _pagedResponse(
          [
            for (var index = 0; index < 100; index++)
              _attendanceJson(id: index + 1),
          ],
          page: 1,
          total: 101,
          pages: 2,
          hasNext: true,
        );
      }
      if (page == 2) {
        return _pagedResponse(
          [_attendanceJson(id: 101)],
          page: 2,
          total: 101,
          pages: 2,
        );
      }
      throw StateError('Unexpected attendance page: $page');
    });

    final result = await BackendLearningApi(
      transport,
    ).attendanceRecords(cohortId: 42, from: from, to: to);

    expect(result.value!.items, hasLength(101));
    expect(result.value!.items.last.id, 101);
    expect(transport.calls.map((call) => call.query['page']), [1, 2]);
    for (final call in transport.calls) {
      expect(call.query['page_size'], 100);
      expect(call.query['cohort'], 42);
      expect(call.query['date_from'], from.toUtc().toIso8601String());
      expect(call.query['date_to'], to.toUtc().toIso8601String());
    }
  });

  test('module 403 is exposed as unavailable instead of fake data', () async {
    final app = await _readyProductionState();
    final transport = _LearningTransport((call) {
      throw const ApiException(
        message: 'Teacher dashboard is disabled.',
        statusCode: 403,
        code: 'forbidden',
      );
    });
    final controller = LearningWorkspaceController(
      app,
      BackendLearningApi(transport),
    );
    addTearDown(() async {
      await _settleBackendStartup(app);
      controller.dispose();
      app.dispose();
    });

    await controller.loadDashboard();

    expect(controller.dashboard.phase, LearningLoadPhase.unavailable);
    expect(controller.dashboard.value, isNull);
    expect(controller.dashboard.message, 'Teacher dashboard is disabled.');
  });

  test(
    'attendance write stays a top-level array and becomes server truth',
    () async {
      final app = await _readyProductionState();
      final transport = _LearningTransport((call) {
        if (call.path == '/api/v1/attendance/lessons/700/mark/') {
          return _response(
            data: {
              'created': 1,
              'updated': 0,
              'records': [
                {
                  'id': 99,
                  'student': 501,
                  'student_name': 'Ali Server',
                  'lesson': 700,
                  'cohort': 42,
                  'status': 'present',
                },
              ],
            },
          );
        }
        throw StateError('Unexpected call: ${call.path}');
      });
      final controller = LearningWorkspaceController(
        app,
        BackendLearningApi(transport),
      );
      addTearDown(() async {
        await _settleBackendStartup(app);
        controller.dispose();
        app.dispose();
      });

      final result = await controller.markAttendance(700, const [
        BackendAttendanceEntry(studentId: 501, status: 'present'),
      ]);

      expect(result.created, 1);
      expect(transport.calls.single.body, [
        {'student': 501, 'status': 'present'},
      ]);
      expect(controller.attendanceForLesson(700).value!.single.studentId, 501);
    },
  );

  test('lesson cards use achievement grants and audited penalties', () async {
    final app = await _readyProductionState();
    final transport = _LearningTransport((call) {
      switch (call.path) {
        case '/api/v1/achievements/':
          return _pageResponse([
            {
              'id': 11,
              'name': 'Smart card',
              'emoji': '🧠',
              'scope': 'global',
              'status': 'active',
            },
            {
              'id': 12,
              'name': 'Group star',
              'emoji': '⭐',
              'scope': 'group',
              'cohort': 42,
              'status': 'active',
            },
            {
              'id': 13,
              'name': 'Other group',
              'scope': 'group',
              'cohort': 99,
              'status': 'active',
            },
          ]);
        case '/api/v1/achievements/11/grant/':
          return _response(
            data: {
              'id': 88,
              'achievement': 11,
              'student': 501,
              'note': 'Excellent reasoning',
              'granted_at': '2026-07-19T10:00:00Z',
            },
          );
        case '/api/v1/rulebook/penalties/':
          return _response(
            data: {
              'id': 89,
              'student': 501,
              'points': 2,
              'reason': 'Repeated disruption',
              'status': 'active',
            },
          );
      }
      throw StateError('Unexpected call: ${call.path}');
    });
    final controller = LearningWorkspaceController(
      app,
      BackendLearningApi(transport),
    );
    addTearDown(() async {
      await _settleBackendStartup(app);
      controller.dispose();
      app.dispose();
    });

    await controller.loadRecognitionCatalog(cohortId: 42);
    expect(controller.recognitionCatalog.value!.map((value) => value.id), [
      11,
      12,
    ]);
    final catalogueCall = transport.calls.first;
    expect(catalogueCall.query['status'], 'active');
    expect(catalogueCall.query['page_size'], 100);

    final grant = await controller.grantRecognition(
      achievementId: 11,
      studentId: 501,
      note: 'Excellent reasoning',
    );
    expect(grant.achievementId, 11);
    final grantCall = transport.calls[1];
    expect(grantCall.method, 'POST');
    expect(grantCall.body, {'student': 501, 'note': 'Excellent reasoning'});

    final correction = await controller.issueCorrection(
      studentId: 501,
      points: 2,
      reason: 'Repeated disruption',
    );
    expect(correction.points, 2);
    final correctionCall = transport.calls[2];
    expect(correctionCall.path, '/api/v1/rulebook/penalties/');
    expect(correctionCall.body, {
      'student': 501,
      'points': 2,
      'reason': 'Repeated disruption',
    });
  });

  test('recognition catalogue cache remains scoped to its cohort', () async {
    final app = await _readyProductionState();
    final transport = _LearningTransport((call) {
      if (call.path != '/api/v1/achievements/') {
        throw StateError('Unexpected call: ${call.path}');
      }
      return _pageResponse([
        {
          'id': 11,
          'name': 'Global star',
          'scope': 'global',
          'status': 'active',
        },
        {
          'id': 12,
          'name': 'Algebra star',
          'scope': 'group',
          'cohort': 42,
          'status': 'active',
        },
        {
          'id': 13,
          'name': 'Physics star',
          'scope': 'group',
          'cohort': 99,
          'status': 'active',
        },
      ]);
    });
    final controller = LearningWorkspaceController(
      app,
      BackendLearningApi(transport),
    );
    addTearDown(() async {
      await _settleBackendStartup(app);
      controller.dispose();
      app.dispose();
    });

    await controller.loadRecognitionCatalog(cohortId: 42);
    await controller.loadRecognitionCatalog(cohortId: 99);
    await controller.loadRecognitionCatalog(cohortId: 42);

    expect(
      controller.recognitionCatalogFor(42).value!.map((value) => value.id),
      [11, 12],
    );
    expect(
      controller.recognitionCatalogFor(99).value!.map((value) => value.id),
      [11, 13],
    );
    expect(controller.recognitionCatalog.value!.map((value) => value.id), [
      11,
      12,
    ]);
    expect(
      transport.calls.where((call) => call.path == '/api/v1/achievements/'),
      hasLength(2),
    );
  });
}

Future<AppState> _readyProductionState() async {
  final state = await _productionState();
  if (state.isInitialized) return state;
  final ready = Completer<void>();
  void listener() {
    if (state.isInitialized && !ready.isCompleted) ready.complete();
  }

  state.addListener(listener);
  listener();
  await ready.future.timeout(const Duration(seconds: 2));
  state.removeListener(listener);
  await _settleBackendStartup(state);
  return state;
}

Future<void> _settleBackendStartup(AppState state) async {
  await state.messagingController.restored.timeout(const Duration(seconds: 2));
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (state.tasksLoading ||
      state.formsLoading ||
      (state.backendNotifications?.isRefreshing ?? false) ||
      (state.backendNotifications?.preferencesLoading ?? false)) {
    if (DateTime.now().isAfter(deadline)) break;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  await state.messagingController.flushPersistence();
  await state.backendNotifications?.pause();
  await Future<void>.delayed(Duration.zero);
}

Future<AppState> _productionState({Completer<http.Response>? profileGate}) {
  const connection = TenantConnection(
    slug: 'server-school',
    name: 'Server School',
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
  final client = MockClient((request) async {
    if (request.url.path == '/api/v1/users/me/') {
      return profileGate == null ? _profileResponse() : profileGate.future;
    }
    return http.Response(
      jsonEncode({
        'success': false,
        'message': 'Module disabled in this test.',
        'code': 'forbidden',
      }),
      403,
      headers: {'content-type': 'application/json'},
    );
  });
  return AppState.bootstrap(
    storage: MemoryAppStorage(),
    api: StarforgeApi(
      client: ApiClient(httpClient: client),
      vault: vault,
      platformBaseUrl: 'https://platform.example',
    ),
  );
}

http.Response _profileResponse() => http.Response(
  jsonEncode({
    'success': true,
    'data': {
      'id': 'teacher-1',
      'principal_kind': 'teacher',
      'username': 'teacher',
      'full_name': 'Server Teacher',
      'email': 'teacher@example.com',
      'role_memberships': <Object?>[],
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

ApiResponse _dashboardResponder(_LearningCall call) {
  if (call.path != '/api/v1/teachers/dashboard/') {
    throw StateError('Unexpected call: ${call.path}');
  }
  return _response(
    data: {
      'groups_count': 3,
      'students_count': 28,
      'next_lessons': <Object?>[],
      'pending_forms': <Object?>[],
    },
  );
}

ApiResponse _cohortResponder(_LearningCall call) {
  switch (call.path) {
    case '/api/v1/cohorts/42/':
      return _response(
        data: {
          'id': 42,
          'name': 'Server Algebra',
          'branch_name': 'Main',
          'department_name': 'Math',
          'level': 'B2',
          'capacity': 20,
          'primary_teacher_name': 'Server Teacher',
          'default_room_name': '304',
          'is_archived': false,
          'teachers': <Object?>[],
        },
      );
    case '/api/v1/cohorts/42/members/':
      return _response(
        data: [
          {
            'id': 8,
            'cohort': 42,
            'cohort_name': 'Server Algebra',
            'student': 501,
            'student_name': 'Ali Server',
          },
        ],
      );
    case '/api/v1/schedule/lessons/':
      return _pageResponse([
        {
          'id': 700,
          'cohort': 42,
          'cohort_name': 'Server Algebra',
          'title': 'Linear equations',
          'status': 'scheduled',
          'starts_at': '2026-07-10T09:00:00Z',
          'ends_at': '2026-07-10T10:00:00Z',
        },
      ]);
    case '/api/v1/attendance/cohorts/42/dashboard/':
      return _response(
        data: {'cohort': 42, 'rate': 94.5, 'students': <Object?>[]},
      );
    case '/api/v1/attendance/records/':
      return _pageResponse([
        {
          'id': 99,
          'student': 501,
          'student_name': 'Ali Server',
          'lesson': 700,
          'lesson_title': 'Linear equations',
          'cohort': 42,
          'cohort_name': 'Server Algebra',
          'status': 'present',
        },
      ]);
  }
  throw StateError('Unexpected call: ${call.path}');
}

ApiResponse _pageResponse(List<Object?> data) => _response(
  data: data,
  pagination: {
    'page': 1,
    'page_size': 100,
    'total': data.length,
    'pages': 1,
    'has_next': false,
    'has_prev': false,
  },
);

ApiResponse _pagedResponse(
  List<Object?> data, {
  required int page,
  required int total,
  required int pages,
  bool hasNext = false,
}) => _response(
  data: data,
  pagination: {
    'page': page,
    'page_size': 100,
    'total': total,
    'pages': pages,
    'has_next': hasNext,
    'has_prev': page > 1,
  },
);

Map<String, Object?> _lessonJson({required int id, required String startsAt}) =>
    {
      'id': id,
      'cohort': 42,
      'cohort_name': 'Server Algebra',
      'title': 'Lesson $id',
      'status': 'scheduled',
      'starts_at': startsAt,
      'ends_at': DateTime.parse(
        startsAt,
      ).add(const Duration(hours: 1)).toIso8601String(),
    };

Map<String, Object?> _attendanceJson({required int id}) => {
  'id': id,
  'student': 500 + id,
  'student_name': 'Student $id',
  'lesson': 700,
  'lesson_title': 'Server calculus',
  'cohort': 42,
  'cohort_name': 'Server Algebra',
  'status': 'present',
};

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'learning-test',
);

final class _LearningCall {
  const _LearningCall({
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

final class _LearningTransport implements BackendTransport {
  _LearningTransport(this.respond);

  final ApiResponse Function(_LearningCall call) respond;
  final List<_LearningCall> calls = [];

  Future<ApiResponse> _call(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) async {
    final call = _LearningCall(
      method: method,
      path: path,
      query: Map.unmodifiable(query),
      body: body,
    );
    calls.add(call);
    return respond(call);
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) => _call('GET', path, query: query);

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) => _call('POST', path, body: body);

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      _call('PATCH', path, body: body);

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      _call('PUT', path, body: body);

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      _call('DELETE', path, body: body);
}
