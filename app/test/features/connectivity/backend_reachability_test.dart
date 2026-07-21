import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/features/connectivity/backend_reachability.dart';

void main() {
  group('HttpBackendReachabilityProbe', () {
    for (final statusCode in [200, 401, 403, 503]) {
      test('treats HTTP $statusCode as a reachable host', () async {
        late Uri requestedUri;
        late bool followedRedirects;
        final probe = HttpBackendReachabilityProbe(
          baseUrl: () => 'https://tenant.example/some/path',
          client: MockClient((request) async {
            requestedUri = request.url;
            followedRedirects = request.followRedirects;
            return http.Response('{}', statusCode);
          }),
        );

        expect(await probe.canReachBackend(), isTrue);
        expect(requestedUri, Uri.parse('https://tenant.example/healthz/live'));
        expect(followedRedirects, isFalse);
        probe.dispose();
      });
    }

    test('reports transport failures as offline', () async {
      final probe = HttpBackendReachabilityProbe(
        baseUrl: () => 'https://tenant.example',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(await probe.canReachBackend(), isFalse);
      probe.dispose();
    });

    test('bounds a response body that never completes', () async {
      final body = StreamController<List<int>>();
      final probe = HttpBackendReachabilityProbe(
        baseUrl: () => 'https://tenant.example',
        timeout: const Duration(milliseconds: 10),
        client: _StreamingClient(
          (_) async => http.StreamedResponse(body.stream, 200),
        ),
      );

      expect(await probe.canReachBackend(), isFalse);
      await body.close();
      probe.dispose();
    });

    test('permits plain HTTP only for canonical loopback hosts', () async {
      for (final baseUrl in [
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://127.255.10.8:8000',
        'http://[::1]:8000',
      ]) {
        var requests = 0;
        final probe = HttpBackendReachabilityProbe(
          baseUrl: () => baseUrl,
          client: MockClient((request) async {
            requests++;
            expect(request.url.scheme, 'http');
            return http.Response('{}', 200);
          }),
        );

        expect(await probe.canReachBackend(), isTrue, reason: baseUrl);
        expect(requests, 1, reason: baseUrl);
        probe.dispose();
      }
    });

    test(
      'rejects insecure remote, disguised, and credentialed targets',
      () async {
        var requests = 0;
        for (final baseUrl in [
          'http://tenant.example',
          'http://dev.localhost:8000',
          'http://127.0.0.1.example.test',
          'file:///private/cache',
          'https://user:password@tenant.example',
        ]) {
          final probe = HttpBackendReachabilityProbe(
            baseUrl: () => baseUrl,
            client: MockClient((_) async {
              requests++;
              return http.Response('', 200);
            }),
          );

          expect(await probe.canReachBackend(), isFalse, reason: baseUrl);
          probe.dispose();
        }
        expect(requests, 0);
      },
    );

    test('does not follow an HTTPS-to-HTTP redirect', () async {
      var requests = 0;
      final probe = HttpBackendReachabilityProbe(
        baseUrl: () => 'https://tenant.example',
        client: MockClient((request) async {
          requests++;
          expect(request.followRedirects, isFalse);
          return http.Response(
            '',
            302,
            headers: {'location': 'http://attacker.example/collect'},
          );
        }),
      );

      expect(await probe.canReachBackend(), isTrue);
      expect(requests, 1);
      probe.dispose();
    });
  });

  group('BackendReachabilityController', () {
    test('blocks production until a real probe succeeds', () async {
      final probe = _SequenceProbe([false, true]);
      final controller = _controller(probe);

      expect(controller.blocksApp, isTrue);
      expect(controller.status, BackendReachabilityStatus.checking);

      await controller.start();
      expect(controller.status, BackendReachabilityStatus.offline);
      expect(controller.blocksApp, isTrue);

      await controller.retry();
      expect(controller.status, BackendReachabilityStatus.online);
      expect(controller.blocksApp, isFalse);
      expect(probe.calls, 2);
      controller.dispose();
    });

    test('does not gate or probe demo/local mode', () async {
      final probe = _SequenceProbe([false]);
      final controller = BackendReachabilityController(
        enabled: false,
        reachabilityProbe: probe,
      );

      await controller.start();
      await controller.retry();
      await controller.resume();

      expect(controller.status, BackendReachabilityStatus.online);
      expect(controller.blocksApp, isFalse);
      expect(probe.calls, 0);
      controller.dispose();
    });

    test('coalesces overlapping retries into one backend request', () async {
      final completer = Completer<bool>();
      final probe = _CompleterProbe(completer);
      final controller = _controller(probe);

      final first = controller.start();
      final second = controller.retry();
      expect(probe.calls, 1);

      completer.complete(true);
      await Future.wait([first, second]);
      expect(controller.status, BackendReachabilityStatus.online);
      expect(probe.calls, 1);
      controller.dispose();
    });

    test('rechecks immediately when the app resumes', () async {
      final probe = _SequenceProbe([true, false]);
      final controller = _controller(probe);

      await controller.start();
      expect(controller.blocksApp, isFalse);
      controller.pause();

      await controller.resume();
      expect(controller.status, BackendReachabilityStatus.offline);
      expect(controller.blocksApp, isTrue);
      expect(probe.calls, 2);
      controller.dispose();
    });

    test('contains an unexpected probe exception and blocks safely', () async {
      final controller = _controller(_ThrowingProbe());

      await controller.start();

      expect(controller.status, BackendReachabilityStatus.offline);
      expect(controller.blocksApp, isTrue);
      controller.dispose();
    });
  });
}

BackendReachabilityController _controller(BackendReachabilityProbe probe) =>
    BackendReachabilityController(
      enabled: true,
      reachabilityProbe: probe,
      onlinePollInterval: const Duration(days: 1),
      offlinePollInterval: const Duration(days: 1),
    );

final class _SequenceProbe implements BackendReachabilityProbe {
  _SequenceProbe(this._results);

  final List<bool> _results;
  int calls = 0;

  @override
  Future<bool> canReachBackend() async => _results[calls++];

  @override
  void dispose() {}
}

final class _CompleterProbe implements BackendReachabilityProbe {
  _CompleterProbe(this.completer);

  final Completer<bool> completer;
  int calls = 0;

  @override
  Future<bool> canReachBackend() {
    calls++;
    return completer.future;
  }

  @override
  void dispose() {}
}

final class _ThrowingProbe implements BackendReachabilityProbe {
  @override
  Future<bool> canReachBackend() => throw StateError('probe failed');

  @override
  void dispose() {}
}

final class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
