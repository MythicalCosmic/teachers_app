import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_work_api.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/features/messaging/messaging_storage.dart';
import 'package:starforge_staff/screens/new_message_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  await state.setLocale(AppLocale.en);
  return state;
}

Widget _host(AppState state, MessagingController controller) {
  final colors = sfColorsFor(SfPalette.daryo);
  final router = GoRouter(
    initialLocation: '/messages/new',
    routes: [
      GoRoute(
        path: '/messages/new',
        builder: (_, _) => NewMessageScreen(controller: controller),
      ),
      GoRoute(
        path: '/messages/chat',
        builder: (_, routeState) => Scaffold(
          body: Text('opened-${routeState.uri.queryParameters['thread']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
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
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'filters and searches permitted contacts then opens an empty direct chat',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final state = (await tester.runAsync(_teacherState))!;
      final transport = _MessagingTransport();
      final controller = MessagingController(
        storage: MemoryMessagingStorage(),
        backend: BackendWorkApi(transport),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(state, controller));
      await tester.pump();
      await tester.runAsync(() => controller.restored);
      await tester.pumpAndSettle();

      expect(find.text('Ali Teacher'), findsOneWidget);
      expect(find.text('Mina Student'), findsOneWidget);
      expect(find.byKey(const ValueKey('new-message-contact-9')), findsNothing);
      expect(
        find.byKey(const ValueKey('new-message-contact-filters')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byKey(const ValueKey('new-message-contact-filters')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('contact-filter-students')));
      await tester.pumpAndSettle();
      expect(find.text('Ali Teacher'), findsNothing);
      expect(find.text('Mina Student'), findsOneWidget);

      final search = find.descendant(
        of: find.byKey(const ValueKey('new-message-search')),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'mina');
      await tester.pumpAndSettle();
      expect(find.text('Ali Teacher'), findsNothing);
      expect(find.text('Mina Student'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('new-message-contact-5')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextButton, 'Open chat'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Open chat'));
      await tester.pumpAndSettle();

      expect(find.text('opened-77'), findsOneWidget);
      expect(transport.createBody, {
        'participant_ids': [5],
      });
      expect(tester.takeException(), isNull);
    },
  );
}

final class _MessagingTransport implements BackendTransport {
  Object? createBody;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    if (path == '/api/v1/messaging/contacts/') {
      return _response(
        data: const [
          {
            'user_id': 2,
            'principal_kind': 'teacher',
            'principal_id': 22,
            'category': 'staff',
            'display_name': 'Ali Teacher',
            'username': 'ali',
            'role_label': 'Teacher',
            'role_slug': 'teacher',
            'is_online': true,
          },
          {
            'user_id': 5,
            'principal_kind': 'student',
            'principal_id': 55,
            'category': 'student',
            'display_name': 'Mina Student',
            'username': 'mina',
            'role_label': 'Student',
            'role_slug': 'student',
            'is_online': false,
          },
        ],
        pagination: const {
          'total': 2,
          'page': 1,
          'page_size': 100,
          'pages': 1,
          'has_next': false,
          'has_prev': false,
          'self_user_id': 1,
        },
      );
    }
    if (path == '/api/v1/messaging/threads/') {
      return _response(
        data: const [
          {
            'id': 99,
            'subject': 'Existing restricted participant',
            'created_by': 1,
            'participants': [
              {'user': 1},
              {'user': 9},
            ],
            'unread_count': 0,
          },
        ],
        pagination: const {
          'total': 1,
          'page': 1,
          'page_size': 100,
          'pages': 1,
          'has_next': false,
          'has_prev': false,
        },
      );
    }
    throw StateError('Unhandled GET $path');
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) async {
    if (path == '/api/v1/messaging/threads/') {
      createBody = body;
      return _response(
        data: const {
          'id': 77,
          'subject': '',
          'created_by': 1,
          'participants': [
            {'user': 1},
            {'user': 5},
          ],
          'unread_count': 0,
        },
      );
    }
    throw StateError('Unhandled POST $path');
  }

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      throw UnimplementedError();
}

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'test-request',
);
