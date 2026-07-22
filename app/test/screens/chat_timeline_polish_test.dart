import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/features/messaging/voice_note_capture.dart';
import 'package:starforge_staff/screens/chat_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

var _resetSequence = 0;

Future<AppState> _teacherState({bool reducedMotion = false}) async {
  MessagingController.shared.initialize(
    userId: 'chat-test-reset-${_resetSequence++}',
    userName: 'Reset',
    sourceThreads: const [],
    storageScope: 'chat-test-reset',
  );
  await MessagingController.shared.restored;
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  await state.updateSettings(
    state.settings.copyWith(locale: AppLocale.en, reducedMotion: reducedMotion),
  );
  return state;
}

Future<AppState> _productionTeacherState({
  List<Uri>? requests,
  Completer<void>? dayLoadGate,
}) async {
  const connection = TenantConnection(
    slug: 'chat-identity-test',
    name: 'Chat identity test',
    baseUrl: 'https://chat-identity.example',
    wsUrl: '',
    locale: 'en',
  );
  final api = StarforgeApi(
    platformBaseUrl: connection.baseUrl,
    vault: MemorySessionVault(
      const StoredSession(
        accessToken: 'private-test-token',
        connection: connection,
        deviceId: 'chat-test-device',
      ),
    ),
    client: ApiClient(
      httpClient: MockClient((request) async {
        requests?.add(request.url);
        final path = request.url.path;
        if (path == '/api/v1/users/me/') {
          return _jsonResponse({
            'id': 42,
            'full_name': 'Current Teacher',
            'username': 'current.teacher',
            'principal_kind': 'teacher',
            'role_memberships': <Object?>[],
          });
        }
        if (path == '/api/v1/messaging/contacts/') {
          return _jsonResponse(
            [
              {
                'user_id': 2,
                'principal_kind': 'staff',
                'principal_id': 202,
                'category': 'staff',
                'display_name': 'Other Teacher',
                'role_label': 'Teacher',
                'role_slug': 'teacher',
                'username': 'other.teacher',
                'is_online': true,
              },
            ],
            pagination: {..._page(), 'self_user_id': 1},
          );
        }
        if (path == '/api/v1/messaging/threads/') {
          return _jsonResponse([
            {
              'id': 10,
              'subject': 'Production identity chat',
              'created_by': 1,
              'participants': [
                {'user': 1},
                {'user': 2},
              ],
              'unread_count': 0,
              'last_message_at': '2026-07-22T10:02:00Z',
            },
          ], pagination: _page());
        }
        if (path == '/api/v1/messaging/threads/10/messages/') {
          if (dayLoadGate != null &&
              request.url.queryParameters.keys.any(
                (key) => key.contains('created_at'),
              )) {
            await dayLoadGate.future;
          }
          return _jsonResponse([
            {
              'id': 501,
              'thread': 10,
              'sender': 2,
              'body': 'Incoming production message',
              'attachments': <String>[],
              'created_at': '2026-07-22T10:01:00Z',
            },
            {
              'id': 502,
              'thread': 10,
              'sender': 1,
              'body': 'Outgoing production message',
              'attachments': <String>[],
              'created_at': '2026-07-22T10:02:00Z',
            },
          ], pagination: _page());
        }
        return _jsonResponse(<Object?>[], pagination: _page());
      }),
    ),
  );
  final state = await AppState.bootstrap(storage: MemoryAppStorage(), api: api);
  if (!state.isInitialized) {
    final ready = Completer<void>();
    void listener() {
      if (state.isInitialized && !ready.isCompleted) ready.complete();
    }

    state.addListener(listener);
    listener();
    await ready.future.timeout(const Duration(seconds: 3));
    state.removeListener(listener);
  }
  await state.messagingController.restored;
  await state.updateSettings(state.settings.copyWith(locale: AppLocale.en));
  return state;
}

Map<String, Object?> _page() => {
  'total': 1,
  'page': 1,
  'page_size': 100,
  'pages': 1,
  'has_next': false,
  'has_prev': false,
};

http.Response _jsonResponse(Object? data, {Object? pagination}) =>
    http.Response(
      jsonEncode({'success': true, 'data': data, 'pagination': ?pagination}),
      200,
      headers: const {'content-type': 'application/json'},
    );

({Widget host, GoRouter router}) _host(
  AppState state, {
  String threadId = 'thread-methodist',
}) {
  final colors = sfColorsFor(SfPalette.daryo);
  final router = GoRouter(
    initialLocation: '/messages/chat?thread=$threadId',
    routes: [
      GoRoute(
        path: '/messages/chat',
        builder: (_, _) => ChatScreen(voiceCapture: _NoopVoiceCapture()),
      ),
    ],
  );
  return (
    router: router,
    host: AppScope(
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
    ),
  );
}

Future<void> _pumpChat(
  WidgetTester tester,
  AppState state, {
  String threadId = 'thread-methodist',
}) async {
  final mounted = _host(state, threadId: threadId);
  addTearDown(mounted.router.dispose);
  await tester.pumpWidget(mounted.host);
  await tester.pump();
  if (MessagingController.shared.isRestoring) {
    await tester.runAsync(() => MessagingController.shared.restored);
  }
  await tester.pumpAndSettle();
}

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('chat uses messaging identity for two-sided bubbles and stars', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    await _pumpChat(tester, state);

    final theirs = tester.widget<Align>(
      find.byKey(
        const ValueKey('chat-message-theirs-message-001'),
        skipOffstage: false,
      ),
    );
    final mine = tester.widget<Align>(
      find.byKey(
        const ValueKey('chat-message-mine-message-002'),
        skipOffstage: false,
      ),
    );
    expect(theirs.alignment, Alignment.centerLeft);
    expect(mine.alignment, Alignment.centerRight);
    expect(find.byKey(const ValueKey('chat-star-background')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'production bubbles use bridge identity when profile id is different',
    (tester) async {
      final requests = <Uri>[];
      final dayLoadGate = Completer<void>();
      final state = (await tester.runAsync(
        () => _productionTeacherState(
          requests: requests,
          dayLoadGate: dayLoadGate,
        ),
      ))!;
      expect(state.session?.userId, '42');
      expect(state.messagingController.currentUserId, '1');

      await _pumpChat(tester, state, threadId: '10');

      final incoming = tester.widget<Align>(
        find.byKey(
          const ValueKey('chat-message-theirs-501'),
          skipOffstage: false,
        ),
      );
      final outgoing = tester.widget<Align>(
        find.byKey(
          const ValueKey('chat-message-mine-502'),
          skipOffstage: false,
        ),
      );
      expect(incoming.alignment, Alignment.centerLeft);
      expect(outgoing.alignment, Alignment.centerRight);
      expect(find.text('Incoming production message'), findsOneWidget);
      expect(find.text('Outgoing production message'), findsOneWidget);

      int messageReads() => requests
          .where((uri) => uri.path == '/api/v1/messaging/threads/10/messages/')
          .length;
      expect(messageReads(), 1);
      await tester.tap(find.byKey(const ValueKey('chat-date-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chat-date-filter-button')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chat-active-date-filter')),
        findsNothing,
      );
      dayLoadGate.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-active-date-filter')),
        findsOneWidget,
      );
      expect(messageReads(), 2);

      await tester.tap(find.byKey(const ValueKey('chat-clear-date-filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-active-date-filter')),
        findsNothing,
      );
      expect(messageReads(), 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar filters the timeline and can be cleared', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    await _pumpChat(tester, state);

    await tester.tap(find.byKey(const ValueKey('chat-date-filter-button')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chat-active-date-filter')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('chat-clear-date-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-active-date-filter')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image bubbles never expose attachment filenames', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    await _pumpChat(tester, state);
    const filename = 'IMG_849302_super_long_private_camera_filename.jpeg';

    await tester.runAsync(
      () => MessagingController.shared.sendImage(
        'thread-methodist',
        label: filename,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(filename), findsNothing);
    expect(find.byKey(const ValueKey('chat-image-preview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('latest control works on a narrow reduced-motion phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = (await tester.runAsync(
      () => _teacherState(reducedMotion: true),
    ))!;
    await _pumpChat(tester, state);

    await tester.runAsync(() async {
      final sends = <Future<Object>>[];
      for (var index = 0; index < 28; index++) {
        sends.add(
          MessagingController.shared.sendText(
            'thread-methodist',
            'Timeline message $index',
          ),
        );
      }
      await Future.wait(sends);
    });
    await tester.pump();
    await tester.pump();

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('chat-timeline')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(180));
    position.jumpTo(
      (position.maxScrollExtent - 400).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-jump-to-latest')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-jump-to-latest')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-jump-to-latest')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown explicit thread never opens another conversation', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    await _pumpChat(tester, state, threadId: 'missing-thread');

    expect(find.text('Conversation not found'), findsOneWidget);
    expect(find.text('Metodistlar guruhi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _NoopVoiceCapture implements VoiceNoteCapture {
  @override
  bool get isRecording => false;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> start() async {}

  @override
  Future<CapturedVoiceNote> stop(Duration duration) async => CapturedVoiceNote(
    bytes: Uint8List(0),
    duration: duration,
    filename: 'unused.mp3',
  );
}
