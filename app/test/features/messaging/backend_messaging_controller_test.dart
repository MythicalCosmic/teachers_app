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
        var serverMuted = false;
        final transport = _RoutingTransport((method, path, query, body) async {
          if (method == 'GET' && path == '/api/v1/messaging/threads/') {
            return _response(
              data: [_threadJson(notificationsMuted: serverMuted)],
              pagination: _page(),
            );
          }
          if (method == 'PATCH' && path.endsWith('/preferences/')) {
            serverMuted =
                (body! as Map<String, Object?>)['notifications_muted']! as bool;
            return _response(data: {'notifications_muted': serverMuted});
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);

        await _initialize(controller);

        expect(controller.threads, hasLength(1));
        expect(controller.threads.single.id, '10');
        expect(controller.threads.single.title, 'Metodika');
        expect(controller.threads.single.isRead, isFalse);
        expect(
          controller.contacts.map((item) => item.id),
          containsAll(['2', '3', '5']),
        );
        expect(
          controller.contacts.map((item) => item.id),
          isNot(contains('4')),
        );
        expect(
          controller.contacts.map((item) => item.id),
          isNot(contains('88')),
        );
        expect(controller.currentUserId, '1');
        expect(controller.contactById('5')?.kind, MessagingContactKind.student);

        controller.togglePinned(const ['10']);
        await controller.setMuted('10', true);
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
      'refresh preserves optimistic mute while its write is pending',
      () async {
        var serverMuted = false;
        final writeStarted = Completer<void>();
        final releaseWrite = Completer<void>();
        final transport = _RoutingTransport((method, path, query, body) async {
          if (method == 'GET' && path == '/api/v1/messaging/threads/') {
            return _response(
              data: [_threadJson(notificationsMuted: serverMuted)],
              pagination: _page(),
            );
          }
          if (method == 'PATCH' && path.endsWith('/preferences/')) {
            writeStarted.complete();
            await releaseWrite.future;
            serverMuted =
                (body! as Map<String, Object?>)['notifications_muted']! as bool;
            return _response(data: {'notifications_muted': serverMuted});
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);

        final write = controller.setMuted('10', true);
        await writeStarted.future;
        await controller.refreshThreads();

        expect(controller.threadById('10')!.isMuted, isTrue);
        releaseWrite.complete();
        await write;
        expect(serverMuted, isTrue);
        expect(controller.threadById('10')!.isMuted, isTrue);
      },
    );

    test(
      'serializes rapid mute toggles and preserves the last intent',
      () async {
        var serverMuted = false;
        var activeWrites = 0;
        var maximumActiveWrites = 0;
        final writes = <bool>[];
        final gates = <Completer<void>>[];
        final transport = _RoutingTransport((method, path, query, body) async {
          if (method == 'GET' && path == '/api/v1/messaging/threads/') {
            return _response(
              data: [_threadJson(notificationsMuted: serverMuted)],
              pagination: _page(),
            );
          }
          if (method == 'PATCH' && path.endsWith('/preferences/')) {
            final muted =
                (body! as Map<String, Object?>)['notifications_muted']! as bool;
            writes.add(muted);
            activeWrites++;
            maximumActiveWrites = maximumActiveWrites < activeWrites
                ? activeWrites
                : maximumActiveWrites;
            final gate = Completer<void>();
            gates.add(gate);
            await gate.future;
            serverMuted = muted;
            activeWrites--;
            return _response(data: {'notifications_muted': serverMuted});
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);

        final mute = controller.setMuted('10', true);
        await Future<void>.delayed(Duration.zero);
        final unmute = controller.setMuted('10', false);
        await Future<void>.delayed(Duration.zero);

        expect(writes, [true]);
        expect(controller.threadById('10')!.isMuted, isFalse);
        gates.single.complete();
        await Future<void>.delayed(Duration.zero);
        expect(writes, [true, false]);
        gates.last.complete();
        await Future.wait([mute, unmute]);

        expect(maximumActiveWrites, 1);
        expect(serverMuted, isFalse);
        expect(controller.threadById('10')!.isMuted, isFalse);
      },
    );

    test(
      'keeps role-native session and messaging bridge identities separate',
      () async {
        final controller = _controller(_RoutingTransport(_baseHandler));
        addTearDown(controller.dispose);

        controller.initialize(
          userId: 'teacher-profile-42',
          userName: 'Current Teacher',
          sourceThreads: const [],
        );
        await controller.restored;

        expect(controller.currentUserId, '1');
        expect(controller.threadById('10')?.contact.id, '2');
        expect(
          controller.contacts.map((contact) => contact.id),
          isNot(contains('1')),
        );
      },
    );

    test(
      'keeps existing permitted contacts when the directory becomes unavailable',
      () async {
        var directoryUnavailable = false;
        final transport = _RoutingTransport((method, path, query, body) {
          if (path == '/api/v1/messaging/contacts/' && directoryUnavailable) {
            throw const ApiException(
              message: 'Not found',
              statusCode: 404,
              code: 'not_found',
            );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);
        final before = controller.contacts.map((item) => item.id).toSet();

        directoryUnavailable = true;
        await controller.refreshDirectory(force: true);

        expect(controller.contacts.map((item) => item.id).toSet(), before);
        expect(controller.directoryError, isNotNull);
        expect(controller.currentUserId, '1');
      },
    );

    test(
      'successful refresh removes revoked explicit directory contacts',
      () async {
        var reducedDirectory = false;
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path == '/api/v1/messaging/contacts/' && reducedDirectory) {
            return _response(
              data: [
                _contactJson(
                  2,
                  'Ali Teacher',
                  category: 'staff',
                  role: 'Teacher',
                ),
              ],
              pagination: {..._page(), 'self_user_id': 1},
            );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);
        expect(controller.contactById('5'), isNotNull);

        reducedDirectory = true;
        await controller.refreshDirectory(force: true);

        expect(controller.contactById('2'), isNotNull);
        expect(controller.contactById('3'), isNull);
        expect(controller.contactById('5'), isNull);
      },
    );

    test(
      'fails closed when the directory omits the bridge self identity',
      () async {
        var threadReads = 0;
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path == '/api/v1/messaging/contacts/') {
            return _response(
              data: [
                _contactJson(
                  5,
                  'Mina Student',
                  category: 'student',
                  role: 'Student',
                ),
              ],
              pagination: _page(),
            );
          }
          if (path == '/api/v1/messaging/threads/') threadReads++;
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);

        await _initialize(controller);

        expect(controller.currentUserId, isEmpty);
        expect(controller.contacts, isEmpty);
        expect(controller.directoryError, isNotNull);
        expect(threadReads, 0);
      },
    );

    test('creates a direct thread with the contact bridge user id', () async {
      Object? createBody;
      final transport = _RoutingTransport((method, path, query, body) async {
        if (method == 'POST' && path == '/api/v1/messaging/threads/') {
          createBody = body;
          return _response(
            data: {
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
        return _baseHandler(method, path, query, body);
      });
      final controller = _controller(transport);
      addTearDown(controller.dispose);
      await _initialize(controller);

      final thread = await controller.createOrOpenDirectThreadAsync('5');

      expect(createBody, {
        'participant_ids': [5],
      });
      expect(thread.id, '77');
      expect(thread.title, 'Mina Student');
      expect(thread.contact.kind, MessagingContactKind.student);
    });

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

    test(
      'loads and merges every bounded server page for one local calendar day',
      () async {
        final requestedPages = <int>[];
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path.endsWith('/messages/')) {
            expect(query['page_size'], 100);
            final lower = DateTime.parse(query['created_at_gte']! as String);
            final upper = DateTime.parse(query['created_at_lt']! as String);
            expect(lower.isUtc, isTrue);
            expect(upper.isUtc, isTrue);
            expect(upper.isAfter(lower), isTrue);
            expect(
              upper.difference(lower).inMinutes,
              inInclusiveRange(23 * 60, 25 * 60),
            );
            final page = query['page']! as int;
            requestedPages.add(page);
            return page == 1
                ? _response(
                    data: [
                      _messageJson(
                        20,
                        body: 'second',
                        createdAt: lower
                            .add(const Duration(hours: 2))
                            .toIso8601String(),
                      ),
                      _messageJson(
                        10,
                        body: 'first',
                        sender: 1,
                        createdAt: lower
                            .add(const Duration(hours: 1))
                            .toIso8601String(),
                      ),
                    ],
                    pagination: _page(
                      page: 1,
                      pages: 2,
                      total: 3,
                      hasNext: true,
                    ),
                  )
                : _response(
                    data: [
                      _messageJson(
                        30,
                        body: 'third',
                        createdAt: lower
                            .add(const Duration(hours: 3))
                            .toIso8601String(),
                      ),
                    ],
                    pagination: _page(
                      page: 2,
                      pages: 2,
                      total: 3,
                      hasPrevious: true,
                    ),
                  );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);

        final messages = await controller.loadMessagesForLocalDay(
          '10',
          DateTime(2026, 7, 19),
        );

        expect(requestedPages, [1, 2]);
        expect(messages.map((message) => message.id), ['10', '20', '30']);
        expect(
          controller.threadById('10')!.messages.map((message) => message.id),
          ['10', '20', '30'],
        );
        expect(messages.first.senderName, 'Current Teacher');
        expect(messages[1].senderName, 'Ali Teacher');
      },
    );

    test(
      'rejects a day whose result count exceeds the client safety cap',
      () async {
        var messageRequests = 0;
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path.endsWith('/messages/')) {
            messageRequests++;
            return _response(
              data: const <Object?>[],
              pagination: _page(
                pages: 6,
                total: MessagingController.maxDayFilterMessages + 1,
                hasNext: true,
              ),
            );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);

        await expectLater(
          controller.loadMessagesForLocalDay('10', DateTime(2026, 7, 19)),
          throwsA(isA<ArgumentError>()),
        );
        expect(messageRequests, 1);
      },
    );

    test('message range API rejects partial bounds and invalid page sizes', () {
      final api = BackendWorkApi(_RoutingTransport(_baseHandler));
      expect(
        () => api.messages(10, createdAtGte: DateTime.utc(2026, 7, 19)),
        throwsArgumentError,
      );
      expect(() => api.messages(10, pageSize: 101), throwsArgumentError);
    });

    test(
      'older overlapping thread load cannot replace newer messages',
      () async {
        final gates = [Completer<ApiResponse>(), Completer<ApiResponse>()];
        var messageReads = 0;
        final transport = _RoutingTransport((method, path, query, body) async {
          if (method == 'GET' && path.endsWith('/messages/')) {
            return gates[messageReads++].future;
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = _controller(transport);
        addTearDown(controller.dispose);
        await _initialize(controller);

        final olderRequest = controller.loadThreadMessages('10', refresh: true);
        await Future<void>.delayed(Duration.zero);
        final newerRequest = controller.loadThreadMessages('10', refresh: true);
        await Future<void>.delayed(Duration.zero);
        gates[1].complete(
          _response(
            data: [_messageJson(22, body: 'newer response')],
            pagination: _page(),
          ),
        );
        await newerRequest;
        gates[0].complete(
          _response(
            data: [_messageJson(21, body: 'older response')],
            pagination: _page(),
          ),
        );
        await olderRequest;

        expect(controller.threadById('10')!.messages.map((item) => item.body), [
          'newer response',
        ]);
      },
    );

    test(
      'production cache is tenant-scoped, metadata-only, and purged',
      () async {
        final storage = MemoryMessagingStorage({
          '1': '{"threads":[{"body":"legacy cross-tenant secret"}]}',
        });
        final transport = _RoutingTransport((method, path, query, body) async {
          if (path.endsWith('/messages/')) {
            return _response(
              data: [
                _messageJson(
                  9,
                  body: 'private lesson note',
                  attachments: const ['tenant/private/report.pdf'],
                ),
              ],
              pagination: _page(),
            );
          }
          return _baseHandler(method, path, query, body);
        });
        final controller = MessagingController(
          storage: storage,
          backend: BackendWorkApi(transport),
        );
        addTearDown(controller.dispose);

        controller.initialize(
          userId: '1',
          userName: 'Current Teacher',
          sourceThreads: const [],
          storageScope: 'https://tenant-a.example',
        );
        await controller.restored;
        await controller.loadThreadMessages('10');
        controller.togglePinned(const ['10']);
        await controller.flushPersistence();

        expect(storage.values, isNot(contains('1')));
        expect(storage.values, hasLength(1));
        final raw = storage.values.values.single;
        expect(raw, contains('"version":2'));
        expect(raw, contains('threadPreferences'));
        expect(raw, isNot(contains('private lesson note')));
        expect(raw, isNot(contains('tenant/private/report.pdf')));
        expect(raw, isNot(contains('Ali Teacher')));
        expect(raw, isNot(contains('+9982')));

        await controller.clearRemoteSession();
        expect(storage.values, isEmpty);
      },
    );

    test('center slug separates caches on a shared API host', () async {
      final storage = MemoryMessagingStorage();
      final first = MessagingController(
        storage: storage,
        backend: BackendWorkApi(_RoutingTransport(_baseHandler)),
      );
      first.initialize(
        userId: '1',
        userName: 'First Teacher',
        sourceThreads: const [],
        storageScope: 'center-a::https://shared.example/TenantPath',
      );
      await first.restored;
      first.togglePinned(const ['10']);
      await first.flushPersistence();
      first.dispose();

      final second = MessagingController(
        storage: storage,
        backend: BackendWorkApi(_RoutingTransport(_baseHandler)),
      );
      addTearDown(second.dispose);
      second.initialize(
        userId: '1',
        userName: 'Second Teacher',
        sourceThreads: const [],
        storageScope: 'center-b::https://shared.example/TenantPath',
      );
      await second.restored;

      expect(second.threadById('10')?.isPinned, isFalse);
      second.toggleMuted(const ['10']);
      await second.flushPersistence();
      expect(storage.values, hasLength(2));
      expect(storage.values.keys.toSet(), hasLength(2));
    });

    test('stale send failure cannot expire or mutate a new session', () async {
      final sendGate = Completer<ApiResponse>();
      var selfUserId = 1;
      final transport = _RoutingTransport((method, path, query, body) async {
        if (method == 'POST' && path.endsWith('/messages/')) {
          return sendGate.future;
        }
        if (path == '/api/v1/messaging/contacts/') {
          final response = await _baseHandler(method, path, query, body);
          return _response(
            data: response.data,
            pagination: {
              ...backendMap(response.pagination),
              'self_user_id': selfUserId,
            },
          );
        }
        return _baseHandler(method, path, query, body);
      });
      final controller = MessagingController(
        storage: MemoryMessagingStorage(),
        backend: BackendWorkApi(transport),
      );
      addTearDown(controller.dispose);
      var unauthorizedCalls = 0;
      controller.onUnauthorized = () async {
        unauthorizedCalls++;
      };
      controller.initialize(
        userId: '1',
        userName: 'First Teacher',
        sourceThreads: const [],
        storageScope: 'center-a::https://shared.example',
      );
      await controller.restored;

      final staleSend = controller.sendText('10', 'Old session message');
      await Future<void>.delayed(Duration.zero);
      await controller.clearRemoteSession(
        userId: '1',
        storageScope: 'center-a::https://shared.example',
      );
      selfUserId = 2;
      controller.initialize(
        userId: '2',
        userName: 'Second Teacher',
        sourceThreads: const [],
        storageScope: 'center-b::https://shared.example',
      );
      await controller.restored;
      sendGate.completeError(
        const ApiException(
          message: 'Old token expired',
          statusCode: 401,
          code: 'authentication_failed',
        ),
      );

      await expectLater(staleSend, throwsA(isA<StateError>()));
      expect(unauthorizedCalls, 0);
      expect(controller.currentUserId, '2');
      expect(
        controller
            .threadById('10')
            ?.messages
            .any((message) => message.body == 'Old session message'),
        isFalse,
      );
      expect(controller.isRefreshing, isFalse);
    });

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
              'filename': '100%photo.jpg',
              'content_type': 'image/png',
              'size_bytes': 3,
            });
            return _response(
              data: {
                'url': 'https://uploads.example.test/form',
                'method': 'POST',
                'key': 'tenant/messaging/1/grant/100%photo.jpg',
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
                attachments: const ['tenant/messaging/1/grant/100%photo.jpg'],
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
          filename: '100%photo.jpg',
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
        expect(uploaded!.body, contains('100%photo.jpg'));
        expect(sentBody, {
          'attachments': ['tenant/messaging/1/grant/100%photo.jpg'],
        });
        expect(message.attachmentKeys, [
          'tenant/messaging/1/grant/100%photo.jpg',
        ]);
        expect(message.mediaLabel, '100%photo.jpg');
        expect(controller.uploadProgress, isNull);
      },
    );

    test('rejects insecure remote upload and download grants', () async {
      var uploadRequests = 0;
      final transport = _RoutingTransport((method, path, query, body) async {
        if (path.endsWith('/attachments/upload-url/')) {
          return _response(
            data: {
              'url': 'http://remote-storage.example/upload',
              'method': 'PUT',
              'key': 'private/file.png',
              'fields': <String, Object?>{},
            },
          );
        }
        if (path.endsWith('/attachments/download/')) {
          return _response(
            data: {'url': 'http://remote-storage.example/download'},
          );
        }
        return _baseHandler(method, path, query, body);
      });
      final controller = MessagingController(
        storage: MemoryMessagingStorage(),
        backend: BackendWorkApi(transport),
        uploadClientFactory: () => MockClient((request) async {
          uploadRequests++;
          return http.Response('', 204);
        }),
      );
      addTearDown(controller.dispose);
      await _initialize(controller);

      await expectLater(
        controller.sendAttachment(
          threadId: '10',
          filename: 'file.png',
          contentType: 'image/png',
          bytes: Uint8List.fromList(const [1, 2, 3]),
          kind: MessagingKind.image,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        controller.attachmentDownloadUrl('10', 'private/file.png'),
        throwsA(isA<ArgumentError>()),
      );
      expect(uploadRequests, 0);
    });

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
  if (path == '/api/v1/messaging/contacts/') {
    return _response(
      data: [
        _contactJson(2, 'Ali Teacher', category: 'staff', role: 'Teacher'),
        _contactJson(3, 'Sara Assistant', category: 'staff', role: 'Assistant'),
        _contactJson(5, 'Mina Student', category: 'student', role: 'Student'),
        _contactJson(4, 'Parent User', category: 'parent', role: 'Parent'),
        {
          'id': 88,
          'principal_id': 88,
          'category': 'student',
          'display_name': 'Unsafe profile id',
        },
      ],
      pagination: {..._page(), 'self_user_id': 1},
    );
  }
  if (method == 'PATCH' && path.endsWith('/preferences/')) {
    final muted =
        (body! as Map<String, Object?>)['notifications_muted']! as bool;
    return _response(data: {'notifications_muted': muted});
  }
  if (path.endsWith('/read/')) return _response(data: {'status': 'ok'});
  throw StateError('Unhandled fake request: $method $path');
}

Map<String, Object?> _threadJson({bool notificationsMuted = false}) => {
  'id': 10,
  'subject': 'Metodika',
  'created_by': 1,
  'participants': [
    {'user': 1},
    {'user': 2},
  ],
  'unread_count': 2,
  'notifications_muted': notificationsMuted,
  'last_message_at': '2026-07-19T10:00:00Z',
};

Map<String, Object?> _messageJson(
  int id, {
  String body = '',
  int sender = 2,
  List<String> attachments = const [],
  String createdAt = '2026-07-19T10:00:00Z',
}) => {
  'id': id,
  'thread': 10,
  'sender': sender,
  'body': body,
  'attachments': attachments,
  'created_at': createdAt,
};

Map<String, Object?> _contactJson(
  int userId,
  String name, {
  required String category,
  required String role,
}) => {
  'user_id': userId,
  'principal_kind': category == 'student' ? 'student' : 'staff',
  'principal_id': 9000 + userId,
  'category': category,
  'display_name': name,
  'role_label': role,
  'role_slug': role.toLowerCase(),
  'username': 'user$userId',
  'is_online': false,
};

Map<String, Object?> _page({
  int page = 1,
  int pages = 1,
  int? total,
  bool hasNext = false,
  bool hasPrevious = false,
}) => {
  'total': total ?? pages,
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
