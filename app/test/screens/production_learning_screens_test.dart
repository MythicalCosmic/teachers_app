import 'dart:async';
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
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_learning_api.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/learning/learning_workspace_controller.dart';
import 'package:starforge_staff/screens/learning/production_learning_screens.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

void main() {
  testWidgets('today renders only the server lesson and dashboard', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(fixture.dispose);
    await tester.runAsync(
      () => fixture.controller.refreshToday(DateTime.now(), force: true),
    );

    await tester.pumpWidget(
      fixture.host(ProductionTodayScreen(controller: fixture.controller)),
    );
    await tester.pump();
    expect(find.text('3'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Server calculus'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Server calculus'), findsOneWidget);
    expect(find.textContaining('Server Teacher'), findsWidgets);
    expect(fixture.app.centerName, 'Server Academy');
    expect(find.textContaining('Demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty today keeps every useful card visible with stable encouragement',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => _fixture(responder: _emptyTodayResponse),
      ))!;
      addTearDown(fixture.dispose);
      await tester.runAsync(
        () => fixture.controller.refreshToday(DateTime.now(), force: true),
      );

      await tester.pumpWidget(
        fixture.host(
          ProductionTodayScreen(
            controller: fixture.controller,
            motivationIndexOverride: 0,
          ),
        ),
      );
      await tester.pump();

      for (var index = 0; index < 3; index++) {
        final metric = find.byKey(ValueKey('production-today-metric-$index'));
        expect(metric, findsOneWidget);
        expect(
          find.descendant(of: metric, matching: find.text('0')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: metric, matching: find.text('Empty')),
          findsOneWidget,
        );
      }
      expect(find.text('Your calm creates room for learning'), findsOneWidget);
      expect(
        find.textContaining('Every thoughtful minute of preparation'),
        findsOneWidget,
      );

      await tester.runAsync(
        () => fixture.controller.loadDashboard(force: true),
      );
      await tester.pump();
      expect(find.text('Your calm creates room for learning'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('No lessons on this date'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No lessons on this date'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('production-today-attention-card')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pending forms'), findsOneWidget);
      expect(find.text('Rule acknowledgements'), findsOneWidget);
      expect(find.text('Upcoming exams'), findsOneWidget);
      expect(
        find.text('All clear — nothing is waiting right now.'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('today encouragement follows the selected app language', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => _fixture(responder: _emptyTodayResponse),
    ))!;
    addTearDown(fixture.dispose);
    await tester.runAsync(
      () => fixture.controller.refreshToday(DateTime.now(), force: true),
    );

    await tester.pumpWidget(
      fixture.host(
        ProductionTodayScreen(
          controller: fixture.controller,
          motivationIndexOverride: 1,
        ),
        locale: const Locale('uz'),
      ),
    );
    await tester.pump();

    expect(
      find.text('Kichik tayyorgarlik katta ishonch beradi'),
      findsOneWidget,
    );
    expect(find.textContaining('Bugungi sokin vaqtni'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty schedule stays useful and every status filter fits a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => _fixture(
          responder: (call) => call.path == '/api/v1/schedule/lessons/'
              ? _pageResponse(<Object?>[])
              : _learningResponse(call),
        ),
      ))!;
      addTearDown(fixture.dispose);
      await tester.runAsync(
        () => fixture.controller.loadLessons(
          LearningWorkspaceController.weekRange(DateTime.now()),
          force: true,
        ),
      );

      await tester.pumpWidget(
        fixture.host(ProductionScheduleScreen(controller: fixture.controller)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('production-empty-lesson-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('production-empty-schedule-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('production-schedule-motivation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('production-empty-schedule-actions')),
        findsOneWidget,
      );
      expect(find.text('0 lessons'), findsWidgets);
      expect(find.text('0 min'), findsOneWidget);

      final all = tester.getRect(
        find.byKey(const ValueKey('production-schedule-filter-all')),
      );
      final cancelled = tester.getRect(
        find.byKey(const ValueKey('production-schedule-filter-cancelled')),
      );
      expect(all.left, greaterThanOrEqualTo(0));
      expect(cancelled.right, lessThanOrEqualTo(390));
      expect(cancelled.top, greaterThan(all.top));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('groups search is sent to the server and has no add action', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(fixture.dispose);
    await tester.runAsync(() => fixture.controller.loadCohorts(force: true));

    await tester.pumpWidget(
      fixture.host(ProductionCohortListScreen(controller: fixture.controller)),
    );
    await tester.pump();
    expect(find.text('Server Algebra'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('production-group-search')),
      'algebra',
    );
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pump();

    final searchCall = fixture.transport.calls.lastWhere(
      (call) => call.path == '/api/v1/cohorts/' && call.query['search'] != null,
    );
    expect(searchCall.query['search'], 'algebra');
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid server cohort id never falls back to a demo group', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      fixture.host(
        ProductionCohortDetailScreen(
          controller: fixture.controller,
          groupId: 'cohort-10v-geometry',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No group selected'), findsWidgets);
    expect(find.textContaining('10-V'), findsNothing);
    expect(fixture.transport.calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance controls and lesson card action fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      fixture.host(
        ProductionAttendanceScreen(
          controller: fixture.controller,
          cohortId: '42',
          lessonId: '700',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ali Server'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget);
    expect(find.text('Excused'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('production-give-card-501')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Absent'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('production-attendance-note')),
      findsOneWidget,
    );
    expect(find.text('Save status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'attendance refresh rehydrates selected lesson and preserves server arrival',
    (tester) async {
      const arrivedAt = '2026-07-19T09:17:00.000Z';
      var serverNote = 'Original server note';
      late _LearningTransport transport;
      final fixture = (await tester.runAsync(
        () => _fixture(
          responder: (call) {
            if (call.path == '/api/v1/attendance/records/') {
              return _pageResponse([
                _attendanceRecord(
                  status: 'late',
                  note: serverNote,
                  arrivedAt: arrivedAt,
                ),
              ]);
            }
            if (call.path == '/api/v1/attendance/lessons/700/mark/') {
              return _response(
                data: {
                  'created': 0,
                  'updated': 1,
                  'records': [
                    _attendanceRecord(
                      status: 'late',
                      note: serverNote,
                      arrivedAt: arrivedAt,
                    ),
                  ],
                },
              );
            }
            return _learningResponse(call);
          },
        ),
      ))!;
      transport = fixture.transport;
      addTearDown(fixture.dispose);

      await tester.pumpWidget(
        fixture.host(
          ProductionAttendanceScreen(
            controller: fixture.controller,
            cohortId: '42',
            lessonId: '700',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original server note'), findsOneWidget);

      serverNote = 'Refreshed server note';
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(find.text('Refreshed server note'), findsOneWidget);
      expect(find.text('Original server note'), findsNothing);

      await _submitAttendance(tester);
      final markCall = transport.calls.lastWhere(
        (call) => call.path == '/api/v1/attendance/lessons/700/mark/',
      );
      final entry = (markCall.body! as List<Object?>).single!;
      expect(entry, isA<Map<String, Object?>>());
      expect(
        (entry as Map<String, Object?>)['arrived_at'],
        DateTime.parse(arrivedAt).toUtc().toIso8601String(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new late mark never invents an arrival timestamp', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => _fixture(
        responder: (call) {
          if (call.path == '/api/v1/attendance/lessons/700/mark/') {
            return _response(
              data: {
                'created': 1,
                'updated': 0,
                'records': [_attendanceRecord(status: 'late')],
              },
            );
          }
          return _learningResponse(call);
        },
      ),
    ))!;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      fixture.host(
        ProductionAttendanceScreen(
          controller: fixture.controller,
          cohortId: '42',
          lessonId: '700',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Late'));
    await tester.pump();
    await _submitAttendance(tester);

    final markCall = fixture.transport.calls.lastWhere(
      (call) => call.path == '/api/v1/attendance/lessons/700/mark/',
    );
    final entry = (markCall.body! as List<Object?>).single!;
    expect(entry, isA<Map<String, Object?>>());
    expect((entry as Map<String, Object?>), isNot(contains('arrived_at')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lesson card sheet grants a server recognition type', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      fixture.host(
        ProductionAttendanceScreen(
          controller: fixture.controller,
          cohortId: '42',
          lessonId: '700',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('production-give-card-501')));
    await tester.pumpAndSettle();

    expect(find.text('Center card types'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('production-recognition-11')));
    await tester.pump();
    await tester.ensureVisible(find.text('Give up card'));
    await tester.tap(find.text('Give up card'));
    await tester.pumpAndSettle();
    expect(find.text('Give this card?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(
      fixture.transport.calls.map((call) => call.path),
      contains('/api/v1/achievements/11/grant/'),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<_Fixture> _fixture({
  ApiResponse Function(_LearningCall call)? responder,
}) async {
  final app = await _productionState();
  await app.updateSettings(
    app.settings.copyWith(
      locale: AppLocale.en,
      reducedMotion: true,
      hasCompletedWelcome: true,
    ),
  );
  final transport = _LearningTransport(responder ?? _learningResponse);
  return _Fixture(
    app: app,
    transport: transport,
    controller: LearningWorkspaceController(app, BackendLearningApi(transport)),
  );
}

final class _Fixture {
  _Fixture({
    required this.app,
    required this.transport,
    required this.controller,
  });

  final AppState app;
  final _LearningTransport transport;
  final LearningWorkspaceController controller;
  final List<GoRouter> _routers = [];

  Widget host(Widget screen, {Locale locale = const Locale('en')}) {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => screen)],
    );
    _routers.add(router);
    final colors = sfColorsFor(SfPalette.daryo);
    return AppScope(
      notifier: app,
      child: SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        reducedMotion: true,
        child: MaterialApp.router(
          locale: locale,
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
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

  Future<void> dispose() async {
    await _settleBackendStartup(app);
    controller.dispose();
    for (final router in _routers) {
      router.dispose();
    }
    app.dispose();
  }
}

Future<AppState> _productionState() async {
  const connection = TenantConnection(
    slug: 'server-academy',
    name: 'Server Academy',
    baseUrl: 'https://tenant.example',
    wsUrl: '',
    locale: 'en',
  );
  final client = MockClient((request) async {
    if (request.url.path == '/api/v1/users/me/') {
      return http.Response(
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
  final state = await AppState.bootstrap(
    storage: MemoryAppStorage(),
    api: StarforgeApi(
      client: ApiClient(httpClient: client),
      vault: MemorySessionVault(
        const StoredSession(
          accessToken: 'access-token',
          connection: connection,
          deviceId: 'test-device',
        ),
      ),
      platformBaseUrl: 'https://platform.example',
    ),
  );
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

ApiResponse _learningResponse(_LearningCall call) {
  switch (call.path) {
    case '/api/v1/teachers/dashboard/':
      return _response(
        data: {
          'groups_count': 3,
          'students_count': 28,
          'next_lessons': <Object?>[],
          'pending_forms': <Object?>[],
        },
      );
    case '/api/v1/schedule/lessons/':
      final start = DateTime.now().toUtc().add(const Duration(hours: 1));
      return _pageResponse([
        {
          'id': 700,
          'cohort': 42,
          'cohort_name': 'Server Algebra',
          'title': 'Server calculus',
          'status': 'scheduled',
          'starts_at': start.toIso8601String(),
          'ends_at': start.add(const Duration(hours: 1)).toIso8601String(),
        },
      ]);
    case '/api/v1/cohorts/':
      return _pageResponse([
        {
          'id': 42,
          'name': 'Server Algebra',
          'branch_name': 'Server Academy',
          'department_name': 'Math',
          'level': 'B2',
          'capacity': 20,
          'primary_teacher_name': 'Server Teacher',
          'default_room_name': '304',
          'is_archived': false,
          'teachers': <Object?>[],
        },
      ]);
    case '/api/v1/cohorts/42/':
      return _response(
        data: {
          'id': 42,
          'name': 'Server Algebra',
          'branch_name': 'Server Academy',
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
            'id': 1,
            'cohort': 42,
            'cohort_name': 'Server Algebra',
            'student': 501,
            'student_name': 'Ali Server',
          },
        ],
      );
    case '/api/v1/schedule/lessons/700/':
      final start = DateTime.now().toUtc().add(const Duration(hours: 1));
      return _response(
        data: {
          'id': 700,
          'cohort': 42,
          'cohort_name': 'Server Algebra',
          'title': 'Server calculus',
          'status': 'scheduled',
          'starts_at': start.toIso8601String(),
          'ends_at': start.add(const Duration(hours: 1)).toIso8601String(),
        },
      );
    case '/api/v1/attendance/cohorts/42/dashboard/':
      return _response(
        data: {'cohort': 42, 'rate': 100, 'students': <Object?>[]},
      );
    case '/api/v1/attendance/records/':
      return _pageResponse(<Object?>[]);
    case '/api/v1/achievements/':
      return _pageResponse([
        {
          'id': 11,
          'name': 'Smart card',
          'emoji': '🧠',
          'scope': 'global',
          'status': 'active',
        },
      ]);
    case '/api/v1/achievements/11/grant/':
      return _response(
        data: {
          'id': 88,
          'achievement': 11,
          'student': 501,
          'note': '',
          'granted_at': '2026-07-19T10:00:00Z',
        },
      );
  }
  throw StateError('Unexpected learning request: ${call.path}');
}

ApiResponse _emptyTodayResponse(_LearningCall call) {
  switch (call.path) {
    case '/api/v1/teachers/dashboard/':
      return _response(
        data: {
          'groups_count': 0,
          'students_count': 0,
          'level_groups': <String, Object?>{},
          'next_lessons': <Object?>[],
          'upcoming_exams': <Object?>[],
          'expected_graduations': <Object?>[],
          'pending_rule_acknowledgments': 0,
          'pending_forms': <Object?>[],
        },
      );
    case '/api/v1/schedule/lessons/':
      return _pageResponse(<Object?>[]);
  }
  return _learningResponse(call);
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

Map<String, Object?> _attendanceRecord({
  required String status,
  String note = '',
  String? arrivedAt,
}) => {
  'id': 99,
  'student': 501,
  'student_name': 'Ali Server',
  'lesson': 700,
  'lesson_title': 'Server calculus',
  'cohort': 42,
  'cohort_name': 'Server Algebra',
  'status': status,
  if (note.isNotEmpty) 'note': note,
  'arrived_at': ?arrivedAt,
};

Future<void> _submitAttendance(WidgetTester tester) async {
  await tester.tap(find.text('Submit').first);
  await tester.pumpAndSettle();
  final dialog = find.byType(AlertDialog);
  expect(dialog, findsOneWidget);
  expect(find.text('Submit attendance?'), findsOneWidget);
  await tester.tap(
    find.descendant(
      of: dialog,
      matching: find.widgetWithText(FilledButton, 'Submit'),
    ),
  );
  await tester.pumpAndSettle();
}

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'learning-screen-test',
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
