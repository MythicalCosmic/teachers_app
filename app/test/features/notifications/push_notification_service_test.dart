import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/features/notifications/push_notification_service.dart';

void main() {
  test('only a numeric thread id is accepted for chat deep links', () {
    expect(
      const PushEnvelope(messageId: '1', data: {'thread_id': '42'}).threadId,
      '42',
    );
    expect(
      const PushEnvelope(
        messageId: '2',
        data: {'thread_id': '../settings'},
      ).threadId,
      isNull,
    );
  });

  test(
    'registers token and refreshes before opening the tapped chat',
    () async {
      final gateway = _FakeGateway(token: 'fcm-token');
      final registrar = _FakeRegistrar();
      final events = <String>[];
      final service = PushNotificationService(
        registrar: registrar,
        gateway: gateway,
        activeTenantSlug: () => 'center-a',
        openThread: (id) => events.add('open:$id'),
        refreshThread: (id) async => events.add('refresh:$id'),
      );

      service.syncAuthenticated(true);
      await _waitFor(() => service.state == PushNotificationState.ready);
      expect(registrar.tokens, ['fcm-token']);

      gateway.opened.add(
        const PushEnvelope(
          messageId: 'wrong-center',
          data: {'thread_id': '9', 'tenant_slug': 'center-b'},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);

      gateway.opened.add(
        const PushEnvelope(
          messageId: 'open-1',
          data: {'thread_id': '9', 'tenant_slug': 'center-a'},
        ),
      );
      await _waitFor(() => events.length == 2);
      expect(events, ['refresh:9', 'open:9']);

      // A provider redelivery of the same tap must not push a second route.
      gateway.opened.add(
        const PushEnvelope(
          messageId: 'open-1',
          data: {'thread_id': '9', 'tenant_slug': 'center-a'},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(2));
      service.dispose();
      await gateway.close();
    },
  );

  test('foreground message refreshes data without opening a route', () async {
    final gateway = _FakeGateway(token: 'token');
    final refreshed = <String>[];
    final opened = <String>[];
    final service = PushNotificationService(
      registrar: _FakeRegistrar(),
      gateway: gateway,
      activeTenantSlug: () => 'center-a',
      openThread: opened.add,
      refreshThread: (id) async => refreshed.add(id),
    );
    service.syncAuthenticated(true);
    await _waitFor(() => service.state == PushNotificationState.ready);

    gateway.foreground.add(
      const PushEnvelope(
        messageId: 'fg-1',
        data: {'thread_id': '7', 'tenant_slug': 'center-a'},
      ),
    );
    await _waitFor(() => refreshed.isNotEmpty);
    expect(refreshed, ['7']);
    expect(opened, isEmpty);
    service.dispose();
    await gateway.close();
  });

  test(
    'foreground refresh failure is contained and service remains usable',
    () async {
      final gateway = _FakeGateway(token: 'first');
      final registrar = _FakeRegistrar();
      final service = PushNotificationService(
        registrar: registrar,
        gateway: gateway,
        activeTenantSlug: () => 'center-a',
        openThread: (_) {},
        refreshThread: (_) async =>
            throw StateError('temporary refresh failure'),
      );
      service.syncAuthenticated(true);
      await _waitFor(() => service.state == PushNotificationState.ready);

      gateway.foreground.add(
        const PushEnvelope(
          messageId: 'fg-failure',
          data: {'thread_id': '7', 'tenant_slug': 'center-a'},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      gateway.refreshes.add('second');

      await _waitFor(() => registrar.tokens.length == 2);
      expect(registrar.tokens, ['first', 'second']);
      expect(service.state, PushNotificationState.ready);
      service.dispose();
      await gateway.close();
    },
  );

  test('signout deletes local token and a refresh registers once', () async {
    final gateway = _FakeGateway(token: 'first');
    final registrar = _FakeRegistrar();
    final service = PushNotificationService(
      registrar: registrar,
      gateway: gateway,
      activeTenantSlug: () => 'center-a',
      openThread: (_) {},
      refreshThread: (_) async {},
    );
    service.syncAuthenticated(true);
    await _waitFor(() => service.state == PushNotificationState.ready);

    gateway.refreshes.add('second');
    gateway.refreshes.add('second');
    await _waitFor(() => registrar.tokens.length == 2);
    expect(registrar.tokens, ['first', 'second']);

    service.syncAuthenticated(false);
    await _waitFor(() => service.state == PushNotificationState.idle);
    expect(gateway.deleteCalls, 1);
    service.dispose();
    await gateway.close();
  });

  test(
    'failed refresh registration cannot block logout or later login',
    () async {
      final gateway = _FakeGateway(token: 'first');
      final registrar = _FakeRegistrar(failOnceTokens: {'broken-refresh'});
      final service = PushNotificationService(
        registrar: registrar,
        gateway: gateway,
        activeTenantSlug: () => 'center-a',
        openThread: (_) {},
        refreshThread: (_) async {},
      );
      service.syncAuthenticated(true);
      await _waitFor(() => service.state == PushNotificationState.ready);

      gateway.refreshes.add('broken-refresh');
      await _waitFor(() => service.state == PushNotificationState.failed);
      service.syncAuthenticated(false);
      await _waitFor(() => service.state == PushNotificationState.idle);
      expect(gateway.deleteCalls, 1);

      gateway.token = 'after-login';
      service.syncAuthenticated(true);
      await _waitFor(
        () =>
            service.state == PushNotificationState.ready &&
            registrar.tokens.contains('after-login'),
      );
      expect(registrar.attempts, ['first', 'broken-refresh', 'after-login']);
      service.dispose();
      await gateway.close();
    },
  );

  test(
    'missing Firebase configuration fails closed without registration',
    () async {
      final gateway = _FakeGateway(
        token: null,
        starts: [PushGatewayStartResult.configurationMissing],
      );
      final registrar = _FakeRegistrar();
      final service = PushNotificationService(
        registrar: registrar,
        gateway: gateway,
        activeTenantSlug: () => 'center-a',
        openThread: (_) {},
        refreshThread: (_) async {},
      );
      service.syncAuthenticated(true);
      await _waitFor(
        () => service.state == PushNotificationState.configurationMissing,
      );
      expect(registrar.tokens, isEmpty);
      service.dispose();
      await gateway.close();
    },
  );
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

final class _FakeRegistrar implements PushDeviceRegistrar {
  _FakeRegistrar({Set<String> failOnceTokens = const {}})
    : _failOnceTokens = {...failOnceTokens};

  final List<String> tokens = [];
  final List<String> attempts = [];
  final Set<String> _failOnceTokens;

  @override
  Future<void> registerPushToken(String token) async {
    attempts.add(token);
    if (_failOnceTokens.remove(token)) {
      throw StateError('temporary registration failure');
    }
    tokens.add(token);
  }
}

final class _FakeGateway implements PushMessagingGateway {
  _FakeGateway({required this.token, List<PushGatewayStartResult>? starts})
    : starts = starts ?? [PushGatewayStartResult.ready];

  String? token;
  final List<PushGatewayStartResult> starts;
  final StreamController<String> refreshes = StreamController.broadcast();
  final StreamController<PushEnvelope> foreground =
      StreamController.broadcast();
  final StreamController<PushEnvelope> opened = StreamController.broadcast();
  int startCalls = 0;
  int deleteCalls = 0;

  @override
  Stream<PushEnvelope> get foregroundMessages => foreground.stream;

  @override
  Stream<PushEnvelope> get openedMessages => opened.stream;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Future<void> deleteToken() async => deleteCalls++;

  @override
  Future<PushEnvelope?> getInitialMessage() async => null;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<PushGatewayStartResult> start() async {
    final index = startCalls.clamp(0, starts.length - 1);
    startCalls++;
    return starts[index];
  }

  Future<void> close() async {
    await refreshes.close();
    await foreground.close();
    await opened.close();
  }
}
