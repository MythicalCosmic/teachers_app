import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/api/notification_realtime.dart';

void main() {
  group('NotificationRealtimeClient', () {
    test(
      'connects with bearer subprotocol and decodes notifications',
      () async {
        const token = 'opaque-session-token.never-log-this';
        final harness = _SocketHarness();
        final client = NotificationRealtimeClient(
          wsUrl: () => 'wss://staff-center.example/ws/notifications/',
          accessToken: () => token,
          socketFactory: harness.create,
        );
        final notificationFuture = client.notifications.first;

        await client.start();
        harness.sockets.single.serverAdd(
          jsonEncode({
            'type': 'notification',
            'payload': {
              'id': 41,
              'event_type': 'assignment.graded',
              'title': 'Work reviewed',
              'body': 'A submission is ready.',
              'data': {'assignment_id': 8},
              'created_at': '2026-07-19T15:30:00+05:00',
            },
          }),
        );
        final notification = await notificationFuture;

        expect(
          harness.uris.single.toString(),
          'wss://staff-center.example/ws/notifications/',
        );
        expect(harness.uris.single.queryParameters, isEmpty);
        expect(harness.protocols.single, ['bearer.$token']);
        expect(client.status, NotificationRealtimeStatus.connected);
        expect(notification.id, '41');
        expect(notification.eventType, 'assignment.graded');
        expect(notification.title, 'Work reviewed');
        expect(notification.data, {'assignment_id': 8});
        expect(notification.createdAt?.year, 2026);
        expect(
          <String>[
            client.status.toString(),
            ...NotificationRealtimeIssue.values.map(
              (issue) => issue.toString(),
            ),
          ].join(' '),
          isNot(contains(token)),
        );

        await client.dispose();
      },
    );

    test('answers backend JSON ping with a JSON pong', () async {
      final harness = _SocketHarness();
      final client = _client(harness);
      await client.start();

      harness.sockets.single.serverAdd(jsonEncode(const {'type': 'ping'}));
      await _eventually(() => harness.sockets.single.sent.isNotEmpty);

      expect(jsonDecode(harness.sockets.single.sent.single! as String), {
        'type': 'pong',
      });
      await client.dispose();
    });

    test('ignores malformed frames and emits token-free diagnostics', () async {
      final harness = _SocketHarness();
      final client = _client(harness);
      final issues = <NotificationRealtimeIssue>[];
      final notifications = <RealtimeNotification>[];
      final issueSubscription = client.issues.listen(issues.add);
      final notificationSubscription = client.notifications.listen(
        notifications.add,
      );
      await client.start();

      harness.sockets.single.serverAdd('not-json');
      harness.sockets.single.serverAdd(
        jsonEncode({'type': 'notification', 'payload': 'wrong-shape'}),
      );
      await _eventually(() => issues.length == 2);

      expect(issues, everyElement(NotificationRealtimeIssue.malformedFrame));
      expect(notifications, isEmpty);
      await issueSubscription.cancel();
      await notificationSubscription.cancel();
      await client.dispose();
    });

    test(
      'retries failures with jittered exponential delay capped at max',
      () async {
        var attempts = 0;
        final waits = <Duration>[];
        final socket = _FakeSocket();
        final client = NotificationRealtimeClient(
          wsUrl: () => 'wss://staff-center.example/ws/notifications/',
          accessToken: () => 'opaque-token',
          socketFactory: (uri, {required protocols}) {
            attempts++;
            if (attempts <= 5) throw StateError('offline');
            return socket;
          },
          delay: (duration) async => waits.add(duration),
          random: _MaximumRandom(),
          initialReconnectDelay: const Duration(milliseconds: 10),
          maxReconnectDelay: const Duration(milliseconds: 40),
        );

        await client.start();
        await _eventually(() => client.isConnected);

        expect(attempts, 6);
        expect(waits, hasLength(5));
        expect(
          waits.map((duration) => duration.inMilliseconds),
          orderedEquals([10, 20, 40, 40, 40]),
        );
        expect(
          waits.every(
            (duration) => duration <= const Duration(milliseconds: 40),
          ),
          isTrue,
        );
        await client.dispose();
      },
    );

    test('pause cancels reconnect and resume reads the latest token', () async {
      var token = 'token-one';
      final waits = <Duration>[];
      final pendingWaits = <Completer<void>>[];
      final harness = _SocketHarness();
      final client = NotificationRealtimeClient(
        wsUrl: () => 'wss://staff-center.example/ws/notifications/',
        accessToken: () => token,
        socketFactory: harness.create,
        delay: (duration) {
          waits.add(duration);
          final completer = Completer<void>();
          pendingWaits.add(completer);
          return completer.future;
        },
        initialReconnectDelay: const Duration(milliseconds: 10),
        maxReconnectDelay: const Duration(milliseconds: 40),
      );
      await client.start();
      final first = harness.sockets.single;
      await first.serverClose(1006);
      await _eventually(() => waits.isNotEmpty);

      await client.pause();
      pendingWaits.single.complete();
      await Future<void>.delayed(Duration.zero);
      expect(client.status, NotificationRealtimeStatus.paused);
      expect(harness.sockets, hasLength(1));

      token = 'token-two';
      await client.resume();
      expect(harness.sockets, hasLength(2));
      expect(harness.protocols.last, ['bearer.token-two']);
      expect(first.clientCloseCode, anyOf(1000, isNull));
      await client.dispose();
    });

    test('terminal auth close waits for an explicit resume', () async {
      var token = 'expired-token';
      final harness = _SocketHarness();
      final client = _client(harness, token: () => token);
      await client.start();

      await harness.sockets.single.serverClose(
        NotificationRealtimeClient.unauthorizedCloseCode,
      );
      await _eventually(
        () =>
            client.status == NotificationRealtimeStatus.authenticationRequired,
      );
      await Future<void>.delayed(Duration.zero);
      expect(harness.sockets, hasLength(1));

      token = 'fresh-token';
      await client.resume();
      expect(harness.sockets, hasLength(2));
      expect(harness.protocols.last, ['bearer.fresh-token']);
      await client.dispose();
    });

    test('a handshake rejected with 4401 does not reconnect', () async {
      var attempts = 0;
      final client = NotificationRealtimeClient(
        wsUrl: () => 'wss://staff-center.example/ws/notifications/',
        accessToken: () => 'expired-token',
        socketFactory: (uri, {required protocols}) {
          attempts++;
          return _FakeSocket(
            readyError: StateError('handshake rejected'),
            initialCloseCode: NotificationRealtimeClient.unauthorizedCloseCode,
          );
        },
        delay: (_) async {},
        initialReconnectDelay: Duration.zero,
        maxReconnectDelay: Duration.zero,
      );

      await client.start();

      expect(client.status, NotificationRealtimeStatus.authenticationRequired);
      expect(attempts, 1);
      await Future<void>.delayed(Duration.zero);
      expect(attempts, 1);
      await client.dispose();
    });

    test(
      'dispose closes once, prevents reconnect, and rejects resume',
      () async {
        final harness = _SocketHarness();
        final client = _client(harness);
        await client.start();
        final socket = harness.sockets.single;

        await client.dispose();

        expect(client.status, NotificationRealtimeStatus.disposed);
        expect(socket.clientCloseCode, 1000);
        expect(socket.clientCloseReason, 'disposed');
        await expectLater(client.resume(), throwsStateError);
        await client.dispose();
        expect(socket.clientCloseCount, 1);
      },
    );
  });
}

NotificationRealtimeClient _client(
  _SocketHarness harness, {
  NotificationRealtimeValueProvider? token,
}) => NotificationRealtimeClient(
  wsUrl: () => 'wss://staff-center.example/ws/notifications/',
  accessToken: token ?? () => 'opaque-token',
  socketFactory: harness.create,
  delay: (_) async {},
  initialReconnectDelay: Duration.zero,
  maxReconnectDelay: Duration.zero,
);

final class _SocketHarness {
  final List<_FakeSocket> sockets = [];
  final List<Uri> uris = [];
  final List<List<String>> protocols = [];

  NotificationRealtimeSocket create(
    Uri uri, {
    required Iterable<String> protocols,
  }) {
    final socket = _FakeSocket();
    sockets.add(socket);
    uris.add(uri);
    this.protocols.add(protocols.toList(growable: false));
    return socket;
  }
}

final class _FakeSocket implements NotificationRealtimeSocket {
  _FakeSocket({this.readyError, int? initialCloseCode})
    : closeCode = initialCloseCode;

  final StreamController<Object?> _incoming =
      StreamController<Object?>.broadcast();
  final List<Object?> sent = [];
  final Object? readyError;

  @override
  int? closeCode;
  int clientCloseCount = 0;
  int? clientCloseCode;
  String? clientCloseReason;

  @override
  Stream<Object?> get messages => _incoming.stream;

  @override
  Future<void> get ready async {
    final error = readyError;
    if (error != null) throw error;
  }

  @override
  void send(Object? message) => sent.add(message);

  void serverAdd(Object? message) => _incoming.add(message);

  Future<void> serverClose(int code) async {
    closeCode = code;
    await _incoming.close();
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    clientCloseCount++;
    clientCloseCode = closeCode;
    clientCloseReason = closeReason;
    if (!_incoming.isClosed) await _incoming.close();
  }
}

final class _MaximumRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 1;

  @override
  int nextInt(int max) => max - 1;
}

Future<void> _eventually(
  bool Function() condition, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Condition was not reached.');
}
