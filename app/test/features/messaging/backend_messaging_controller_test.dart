import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_work_api.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/features/messaging/messaging_models.dart';
import 'package:starforge_staff/features/messaging/messaging_storage.dart';

void main() {
  group('production MessagingController', () {
    test(
      'hydrates server threads and preserves device-only overlays',
      () async {
        final transport = _RoutingTransport(_baseHandler);
        final controller = _controller(transport);
        addTearDown(controller.dispose);

        await _initialize(controller);

        expect(controller.threads, hasLength(1));
        expect(controller.threads.single.id, '10');
        expect(controller.threads.single.title, 'Metodika');
        expect(controller.threads.single.isRead, isFalse);
        expect(
          controller.contacts.map((item) => item.id),
          containsAll(['2', '3']),
        );
        expect(
          controller.contacts.map((item) => item.id),
          isNot(contains('4')),
        );

        controller.togglePinned(const ['10']);
        controller.toggleMuted(const ['10']);
        controller.setArchived(const ['10'], true);
        controller.setFolder('10', 'folder-important', included: true);
        await controller.refreshThreads();

        final refreshed = controller.threadById('10')!;
        expect(refreshed.isPinned, isTrue);
        expect(refreshed.isMuted, isTrue);
        expect(refreshed.isArchived, isTrue);
        expect(refreshed.folderIds, contains('folder-important'));
      },
    );

    test(
      'loads newest page first and prepends older message history',
      () async {
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path.endsWith('/messages/')) {
            final page = query['page'] as int? ?? 1;
            return page == 1
                ? _response(
                    data: [_messageJson(1, body: 'older')],
                    pagination: _page(page: 1, pages: 2, hasNext: true),
                  )
                : _response(
                    data: [_messageJson(2, body: 'newest')],
                    pagination: _page(page: 2, pages: 2, hasPrevious: true),
                  );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);

        await controller.loadThreadMessages('10');
        expect(controller.threadById('10')!.messages.map((item) => item.body), [
          'newest',
        ]);
        expect(controller.hasOlderMessages('10'), isTrue);

        await controller.loadOlderMessages('10');
        expect(controller.threadById('10')!.messages.map((item) => item.body), [
          'older',
          'newest',
        ]);
        expect(controller.hasOlderMessages('10'), isFalse);
      },
    );

    test('optimistic send replaces success and rolls back failure', () async {
      final send = Completer<ApiResponse>();
      var failNext = false;
      final transport = _RoutingTransport((method, path, query, body) async {
        if (method == 'POST' && path.endsWith('/messages/')) {
          if (failNext) {
            throw const ApiException(
              message: 'Server unavailable',
              statusCode: 503,
              code: 'server_error',
            );
          }
          return send.future;
        }
        return _baseHandler(method, path, query, body);
      });
      final controller = _controller(transport);
      addTearDown(controller.dispose);
      await _initialize(controller);

      final sending = controller.sendText('10', 'Salom');
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.threadById('10')!.messages.single.delivery,
        MessagingDelivery.sending,
      );
      send.complete(
        _response(data: _messageJson(70, body: 'Salom', sender: 1)),
      );
      final delivered = await sending;
      expect(delivered.id, '70');
      expect(controller.threadById('10')!.messages.single.id, '70');

      failNext = true;
      await expectLater(
        controller.sendText('10', 'Rollback'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        controller
            .threadById('10')!
            .messages
            .where((item) => item.body == 'Rollback'),
        isEmpty,
      );
    });

    test(
      'uses exact grant multipart upload then sends only attachment key',
      () async {
        http.Request? uploaded;
        Object? sentBody;
        final uploadClient = MockClient((request) async {
          uploaded = request;
          return http.Response('', 204);
        });
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path.endsWith('/attachments/upload-url/')) {
            expect(body, {
              'filename': 'board.png',
              'content_type': 'image/png',
              'size_bytes': 3,
            });
            return _response(
              data: {
                'url': 'https://uploads.example.test/form',
                'method': 'POST',
                'key': 'tenant/messaging/1/grant/board.png',
                'fields': {'policy': 'opaque-policy', 'x-meta': 'safe'},
              },
            );
          }
          if (method == 'POST' && path.endsWith('/messages/')) {
            sentBody = body;
            return _response(
              data: _messageJson(
                80,
                sender: 1,
                attachments: const ['tenant/messaging/1/grant/board.png'],
              ),
            );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = MessagingController(
          storage: MemoryMessagingStorage(),
          backend: BackendWorkApi(transport),
          uploadClientFactory: () => uploadClient,
        );
        addTearDown(controller.dispose);
        await _initialize(controller);

        final message = await controller.sendAttachment(
          threadId: '10',
          filename: 'board.png',
          contentType: 'image/png',
          bytes: Uint8List.fromList(utf8.encode('abc')),
          kind: MessagingKind.image,
        );

        expect(uploaded, isNotNull);
        expect(uploaded!.method, 'POST');
        expect(
          uploaded!.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        expect(uploaded!.body, contains('opaque-policy'));
        expect(uploaded!.body, contains('board.png'));
        expect(sentBody, {
          'attachments': ['tenant/messaging/1/grant/board.png'],
        });
        expect(message.attachmentKeys, ['tenant/messaging/1/grant/board.png']);
        expect(controller.uploadProgress, isNull);
      },
    );

    test('rejects videos over one minute before requesting a grant', () async {
      final transport = _RoutingTransport(_baseHandler);
      final controller = _controller(transport);
      addTearDown(controller.dispose);
      await _initialize(controller);
      final callsBefore = transport.calls.length;

      await expectLater(
        controller.sendAttachment(
          threadId: '10',
          filename: 'long.mp4',
          contentType: 'video/mp4',
          bytes: Uint8List.fromList(const [1]),
          kind: MessagingKind.video,
          duration: const Duration(seconds: 61),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(transport.calls, hasLength(callsBefore));
    });

    test('uploads a real MP3 voice note and restores its duration', () async {
      Object? grantBody;
      Object? messageBody;
      final transport = _RoutingTransport((method, path, query, body) async {
        if (path.endsWith('/attachments/upload-url/')) {
          grantBody = body;
          return _response(
            data: {
              'url': 'https://uploads.example.test/form',
              'method': 'POST',
              'key': 'tenant/messaging/1/grant/voice_123_4200ms.mp3',
              'fields': <String, Object?>{},
            },
          );
        }
        if (method == 'POST' && path.endsWith('/messages/')) {
          messageBody = body;
          return _response(
            data: _messageJson(
              81,
              sender: 1,
              attachments: const [
                'tenant/messaging/1/grant/voice_123_4200ms.mp3',
              ],
            ),
          );
        }
        return _baseHandler(method, path, query, body);
      });
      final controller = MessagingController(
        storage: MemoryMessagingStorage(),
        backend: BackendWorkApi(transport),
        uploadClientFactory: () =>
            MockClient((_) async => http.Response('', 204)),
      );
      addTearDown(controller.dispose);
      await _initialize(controller);

      final message = await controller.sendAttachment(
        threadId: '10',
        filename: 'voice_123_4200ms.mp3',
        contentType: 'audio/mpeg',
        bytes: Uint8List.fromList(const [0x49, 0x44, 0x33]),
        kind: MessagingKind.voice,
        duration: const Duration(milliseconds: 4200),
      );

      expect(grantBody, {
        'filename': 'voice_123_4200ms.mp3',
        'content_type': 'audio/mpeg',
        'size_bytes': 3,
      });
      expect(messageBody, {
        'attachments': ['tenant/messaging/1/grant/voice_123_4200ms.mp3'],
      });
      expect(message.kind, MessagingKind.voice);
      expect(message.mediaDuration, const Duration(milliseconds: 4200));
    });

    test('rejects invalid voice-note durations before upload', () async {
      final transport = _RoutingTransport(_baseHandler);
      final controller = _controller(transport);
      addTearDown(controller.dispose);
      await _initialize(controller);
      final callsBefore = transport.calls.length;

      for (final duration in const [
        Duration(milliseconds: 499),
        Duration(seconds: 61),
      ]) {
        await expectLater(
          controller.sendAttachment(
            threadId: '10',
            filename: 'voice.mp3',
            contentType: 'audio/mpeg',
            bytes: Uint8List.fromList(const [1]),
            kind: MessagingKind.voice,
            duration: duration,
          ),
          throwsA(isA<ArgumentError>()),
        );
      }
      expect(transport.calls, hasLength(callsBefore));
    });
  });
}

MessagingController _controller(_RoutingTransport transport) =>
    MessagingController(
      storage: MemoryMessagingStorage(),
      backend: BackendWorkApi(transport),
    );

Future<void> _initialize(MessagingController controller) async {
  controller.initialize(
    userId: '1',
    userName: 'Current Teacher',
    sourceThreads: const [],
  );
  await controller.restored;
}

Future<ApiResponse> _baseHandler(
  String method,
  String path,
  Map<String, Object?> query,
  Object? body,
) async {
  if (path == '/api/v1/messaging/threads/') {
    return _response(data: [_threadJson()], pagination: _page());
  }
  if (path == '/api/v1/users/') {
    return _response(
      data: [
        _userJson(2, 'Ali Teacher', ['teacher']),
        _userJson(3, 'Sara Assistant', ['assistant']),
        _userJson(4, 'Executive', ['manager']),
      ],
    );
  }
  if (path.endsWith('/read/')) return _response(data: {'status': 'ok'});
  throw StateError('Unhandled fake request: $method $path');
}

Map<String, Object?> _threadJson() => {
  'id': 10,
  'subject': 'Metodika',
  'created_by': 1,
  'participants': [
    {'user': 1},
    {'user': 2},
  ],
  'unread_count': 2,
  'last_message_at': '2026-07-19T10:00:00Z',
};

Map<String, Object?> _messageJson(
  int id, {
  String body = '',
  int sender = 2,
  List<String> attachments = const [],
}) => {
  'id': id,
  'thread': 10,
  'sender': sender,
  'body': body,
  'attachments': attachments,
  'created_at': '2026-07-19T10:00:00Z',
};

Map<String, Object?> _userJson(int id, String name, List<String> roles) => {
  'id': id,
  'username': 'user$id',
  'full_name': name,
  'phone': '+998$id',
  'email': 'user$id@example.test',
  'is_active': true,
  'is_staff': true,
  'role_memberships': [
    for (final role in roles) {'account_type_slug': role},
  ],
};

Map<String, Object?> _page({
  int page = 1,
  int pages = 1,
  bool hasNext = false,
  bool hasPrevious = false,
}) => {
  'total': pages,
  'page': page,
  'page_size': 100,
  'pages': pages,
  'has_next': hasNext,
  'has_prev': hasPrevious,
};

ApiResponse _response({Object? data, Object? pagination}) => ApiResponse(
  data: data,
  pagination: pagination,
  statusCode: 200,
  requestId: 'test-request',
);

typedef _Handler =
    Future<ApiResponse> Function(
      String method,
      String path,
      Map<String, Object?> query,
      Object? body,
    );

final class _RoutingTransport implements BackendTransport {
  _RoutingTransport(this.handler);

  final _Handler handler;
  final List<String> calls = <String>[];

  Future<ApiResponse> _call(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) {
    calls.add('$method $path');
    return handler(method, path, query, body);
  }

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      _call('DELETE', path, body: body);

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) => _call('GET', path, query: query);

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      _call('PATCH', path, body: body);

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) => _call('POST', path, body: body);

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      _call('PUT', path, body: body);
}
