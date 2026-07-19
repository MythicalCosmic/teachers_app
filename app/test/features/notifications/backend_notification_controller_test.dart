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
  String? lastCursor;
  Object? preferenceUpdate;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    if (path == '/api/v1/notifications/') {
      feedReads++;
      lastCursor = query['cursor'] as String?;
      if (lastCursor == null) {
        return _response(
          data: [
            _notification(1, createdAt: '2026-07-19T09:00:00Z'),
            _notification(2, createdAt: '2026-07-19T10:00:00Z'),
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
}) => {
  'id': id,
  'user': 1,
  'user_name': 'Teacher',
  'event_type': id == 2 ? 'message.received' : 'schedule.lesson_reminder',
  'title': 'Notification $id',
  'body': 'Body $id',
  'data': id == 2 ? {'thread_id': 10} : <String, Object?>{},
  'read_at': null,
  'created_at': createdAt,
};

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'test-request',
);
