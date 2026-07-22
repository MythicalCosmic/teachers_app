import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_work_api.dart';
import 'package:starforge_staff/data/api/notification_realtime.dart';
import 'package:starforge_staff/features/notifications/backend_notification_controller.dart';

void main() {
  group('BackendNotificationController', () {
    test('hydrates feed/count/preferences and follows a cursor page', () async {
      final socket = _FakeSocket();
      final transport = _NotificationTransport();
      final controller = _controller(transport, socket);
      addTearDown(controller.dispose);

      await controller.start();

      expect(controller.notifications.map((item) => item.id), [2, 1]);
      expect(controller.unreadCount, 2);
      expect(controller.hasMore, isTrue);
      expect(controller.preferences.single.eventType, 'message.received');

      await controller.loadMore();
      expect(transport.lastCursor, 'next-token');
      expect(controller.notifications.map((item) => item.id), [2, 1, 0]);
      expect(controller.hasMore, isFalse);

      await controller.markRead(2);
      expect(controller.notifications.first.readAt, isNotNull);
      expect(controller.unreadCount, 1);

      await controller.setPreference(controller.preferences.single, false);
      expect(controller.preferences.single.enabled, isFalse);
      expect(transport.preferenceUpdate, isNotNull);
    });

    test(
      'inserts realtime notification and refreshes its message thread',
      () async {
        final socket = _FakeSocket();
        final transport = _NotificationTransport();
        final controller = _controller(transport, socket);
        addTearDown(controller.dispose);
        String? refreshedThread;
        controller.onMessageReceived = (threadId) async {
          refreshedThread = threadId;
        };
        await controller.start();

        socket.add(
          jsonEncode({
            'type': 'notification',
            'payload': {
              'id': '9',
              'event_type': 'message.received',
              'title': 'New message',
              'body': 'Open the thread',
              'data': {'thread_id': 44, 'message_id': 90},
              'created_at': '2026-07-19T12:00:00Z',
            },
          }),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.notifications.first.id, 9);
        expect(controller.unreadCount, 3);
        expect(refreshedThread, '44');
      },
    );

    test(
      'refresh preserves realtime arrivals newer than its REST feed',
      () async {
        final socket = _FakeSocket();
        final transport = _NotificationTransport();
        final controller = _controller(transport, socket);
        addTearDown(controller.dispose);
        await controller.start();
        transport.feedGate = Completer<ApiResponse>();

        final refreshing = controller.refresh();
        await Future<void>.delayed(Duration.zero);
        socket.add(
          jsonEncode({
            'type': 'notification',
            'payload': {
              'id': '9',
              'event_type': 'message.received',
              'title': 'Realtime during refresh',
              'body': 'Must survive the older REST response',
              'data': {'thread_id': 44},
              'created_at': '2026-07-19T12:00:00Z',
            },
          }),
        );
        await Future<void>.delayed(Duration.zero);
        transport.feedGate!.complete(
          _response(
            data: [
              _notification(1, createdAt: '2026-07-19T09:00:00Z'),
              _notification(2, createdAt: '2026-07-19T10:00:00Z'),
            ],
            pagination: const {'next': null, 'previous': null},
          ),
        );
        await refreshing;

        expect(controller.notifications.map((item) => item.id), [9, 2, 1]);
        expect(controller.unreadCount, 3);
      },
    );

    test('rolls back optimistic read when server mutation fails', () async {
      final socket = _FakeSocket();
      final transport = _NotificationTransport()..failRead = true;
      final controller = _controller(transport, socket);
      addTearDown(controller.dispose);
      await controller.start();

      await controller.markRead(2);

      expect(controller.notifications.first.readAt, isNull);
      expect(controller.unreadCount, 2);
      expect(controller.error, 'Read failed');
    });

    test(
      'read rollback targets its id after realtime reorders the feed',
      () async {
        final socket = _FakeSocket();
        final transport = _NotificationTransport()
          ..readGate = Completer<ApiResponse>();
        final controller = _controller(transport, socket);
        addTearDown(controller.dispose);
        await controller.start();

        final marking = controller.markRead(2);
        await Future<void>.delayed(Duration.zero);
        socket.add(
          jsonEncode({
            'type': 'notification',
            'payload': {
              'id': '9',
              'event_type': 'message.received',
              'title': 'Concurrent event',
              'body': 'Must survive rollback',
              'data': {'thread_id': 44},
              'created_at': '2026-07-19T12:00:00Z',
            },
          }),
        );
        await Future<void>.delayed(Duration.zero);
        transport.readGate!.completeError(
          const ApiException(
            message: 'Read unavailable',
            statusCode: 403,
            code: 'permission_denied',
          ),
        );
        await marking;

        expect(controller.notifications.map((item) => item.id), [9, 2, 1]);
        expect(controller.notifications.first.title, 'Concurrent event');
        expect(
          controller.notifications.firstWhere((item) => item.id == 2).readAt,
          isNull,
        );
        expect(controller.unreadCount, 3);
      },
    );

    test('mark-all rollback preserves realtime arrivals', () async {
      final socket = _FakeSocket();
      final transport = _NotificationTransport()
        ..markAllGate = Completer<ApiResponse>();
      final controller = _controller(transport, socket);
      addTearDown(controller.dispose);
      await controller.start();

      final marking = controller.markAllRead();
      await Future<void>.delayed(Duration.zero);
      socket.add(
        jsonEncode({
          'type': 'notification',
          'payload': {
            'id': '9',
            'event_type': 'message.received',
            'title': 'Concurrent event',
            'body': 'Must survive rollback',
            'data': {'thread_id': 44},
            'created_at': '2026-07-19T12:00:00Z',
          },
        }),
      );
      await Future<void>.delayed(Duration.zero);
      transport.markAllGate!.completeError(
        const ApiException(
          message: 'Mark all unavailable',
          statusCode: 403,
          code: 'permission_denied',
        ),
      );
      await marking;

      expect(controller.notifications.map((item) => item.id), [9, 2, 1]);
      expect(
        controller.notifications.every((item) => item.readAt == null),
        isTrue,
      );
      expect(controller.unreadCount, 3);
    });

    test(
      'read rollback preserves a newer authoritative read timestamp',
      () async {
        final socket = _FakeSocket();
        final transport = _NotificationTransport()
          ..readGate = Completer<ApiResponse>();
        final controller = _controller(transport, socket);
        addTearDown(controller.dispose);
        await controller.start();

        final marking = controller.markRead(2);
        await Future<void>.delayed(Duration.zero);
        transport.readAtForTwo = '2026-07-19T11:30:00Z';
        await controller.refresh();
        transport.readGate!.completeError(
          const ApiException(
            message: 'Old request failed',
            statusCode: 503,
            code: 'server_error',
          ),
        );
        await marking;

        expect(
          controller.notifications.firstWhere((item) => item.id == 2).readAt,
          DateTime.parse('2026-07-19T11:30:00Z'),
        );
        expect(controller.unreadCount, 2);
      },
    );

    test('stale read failure cannot expire or wedge a new session', () async {
      final socket = _FakeSocket();
      final transport = _NotificationTransport()
        ..readGate = Completer<ApiResponse>();
      final controller = _controller(transport, socket);
      addTearDown(controller.dispose);
      var unauthorizedCalls = 0;
      controller.onUnauthorized = () async {
        unauthorizedCalls++;
      };
      await controller.start();

      final staleRead = controller.markRead(2);
      await Future<void>.delayed(Duration.zero);
      await controller.clearSession();
      await controller.start();
      transport.readGate!.completeError(
        const ApiException(
          message: 'Old token expired',
          statusCode: 401,
          code: 'authentication_failed',
        ),
      );
      await staleRead;

      expect(unauthorizedCalls, 0);
      expect(controller.notifications, isNotEmpty);
      expect(controller.isRefreshing, isFalse);
    });

    test(
      'replayed realtime frame does not make a read item unread again',
      () async {
        final socket = _FakeSocket();
        final transport = _NotificationTransport();
        final controller = _controller(transport, socket);
        addTearDown(controller.dispose);
        await controller.start();
        await controller.markRead(2);

        socket.add(
          jsonEncode({
            'type': 'notification',
            'payload': {
              'id': '2',
              'event_type': 'message.received',
              'title': 'Replay',
              'body': 'Same event',
              'data': {'thread_id': 10},
              'created_at': '2026-07-19T10:00:00Z',
            },
          }),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.notifications.first.readAt, isNotNull);
        expect(controller.unreadCount, 1);
      },
    );

    test('pauses and reconciles REST feed after lifecycle resume', () async {
      final socket = _FakeSocket();
      final transport = _NotificationTransport();
      final controller = _controller(transport, socket);
      addTearDown(controller.dispose);
      await controller.start();

      await controller.pause();
      expect(controller.realtimeStatus, NotificationRealtimeStatus.paused);
      transport.unreadCount = 5;
      await controller.resume();

      expect(controller.unreadCount, 5);
      expect(transport.feedReads, greaterThanOrEqualTo(2));
    });

    test(
      'REST resume refreshes only newly missed message threads once',
      () async {
        final socket = _FakeSocket();
        final transport = _NotificationTransport();
        final controller = _controller(transport, socket);
        addTearDown(controller.dispose);
        final refreshed = <String?>[];
        controller.onMessageReceived = (threadId) async {
          refreshed.add(threadId);
        };
        await controller.start();
        expect(refreshed, ['10']);

        transport.feedGate = Completer<ApiResponse>();
        final refresh = controller.refresh();
        transport.feedGate!.complete(
          _response(
            data: [
              _notification(2),
              {
                ..._notification(8),
                'event_type': 'message.received',
                'data': {'thread_id': 77},
              },
              {
                ..._notification(9),
                'event_type': 'message.received',
                'data': {'thread_id': 77},
              },
            ],
            pagination: const {'next': null, 'previous': null},
          ),
        );
        await refresh;
        expect(refreshed, ['10', '77']);

        transport.feedGate = null;
        await controller.refresh();
        expect(refreshed, ['10', '77']);
      },
    );
  });
}

BackendNotificationController _controller(
  _NotificationTransport transport,
  _FakeSocket socket,
) {
  final realtime = NotificationRealtimeClient(
    wsUrl: () => 'wss://tenant.example.test/ws/notifications/',
    accessToken: () => 'test-token',
    socketFactory: (uri, {required protocols}) => socket,
    delay: (_) => Completer<void>().future,
  );
  return BackendNotificationController(
    backend: BackendWorkApi(transport),
    realtime: realtime,
  );
}

final class _FakeSocket implements NotificationRealtimeSocket {
  final StreamController<Object?> _messages =
      StreamController<Object?>.broadcast();

  @override
  int? closeCode;

  @override
  Future<void> get ready async {}

  @override
  Stream<Object?> get messages => _messages.stream;

  void add(Object? frame) => _messages.add(frame);

  @override
  void send(Object? message) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    this.closeCode = closeCode;
  }
}

final class _NotificationTransport implements BackendTransport {
  int feedReads = 0;
  int unreadCount = 2;
  bool failRead = false;
  Completer<ApiResponse>? readGate;
  Completer<ApiResponse>? markAllGate;
  Completer<ApiResponse>? feedGate;
  String? lastCursor;
  Object? preferenceUpdate;
  String? readAtForTwo;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    if (path == '/api/v1/notifications/') {
      feedReads++;
      lastCursor = query['cursor'] as String?;
      final gatedFeed = feedGate;
      if (gatedFeed != null) return gatedFeed.future;
      if (lastCursor == null) {
        return _response(
          data: [
            _notification(1, createdAt: '2026-07-19T09:00:00Z'),
            _notification(
              2,
              createdAt: '2026-07-19T10:00:00Z',
              readAt: readAtForTwo,
            ),
          ],
          pagination: {
            'next':
                'https://tenant.example.test/api/v1/notifications/?cursor=next-token',
            'previous': null,
          },
        );
      }
      return _response(
        data: [_notification(0, createdAt: '2026-07-18T08:00:00Z')],
        pagination: const {'next': null, 'previous': 'previous-token'},
      );
    }
    if (path == '/api/v1/notifications/unread-count/') {
      return _response(data: {'count': unreadCount});
    }
    if (path == '/api/v1/notifications/preferences/') {
      return _response(
        data: [
          {
            'event_type': 'message.received',
            'channel': 'in_app',
            'enabled': true,
          },
        ],
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
    if (path.endsWith('/read/')) {
      final gate = readGate;
      if (gate != null) return gate.future;
      if (failRead) {
        throw const ApiException(
          message: 'Read failed',
          statusCode: 503,
          code: 'server_error',
        );
      }
      return _response(data: {'read': true});
    }
    if (path == '/api/v1/notifications/read-all/') {
      final gate = markAllGate;
      if (gate != null) return gate.future;
      return _response(data: {'updated': unreadCount});
    }
    throw StateError('Unhandled POST $path');
  }

  @override
  Future<ApiResponse> put(String path, {Object? body}) async {
    if (path == '/api/v1/notifications/preferences/') {
      preferenceUpdate = body;
      final map = Map<String, Object?>.from(body! as Map);
      return _response(data: map['preferences']);
    }
    throw StateError('Unhandled PUT $path');
  }

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      throw StateError('Unhandled DELETE $path');

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      throw StateError('Unhandled PATCH $path');
}

Map<String, Object?> _notification(
  int id, {
  String createdAt = '2026-07-19T10:00:00Z',
  String? readAt,
}) => {
  'id': id,
  'user': 1,
  'user_name': 'Teacher',
  'event_type': id == 2 ? 'message.received' : 'schedule.lesson_reminder',
  'title': 'Notification $id',
  'body': 'Body $id',
  'data': id == 2 ? {'thread_id': 10} : <String, Object?>{},
  'read_at': readAt,
  'created_at': createdAt,
};

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'test-request',
);
