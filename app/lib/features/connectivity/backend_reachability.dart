import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum BackendReachabilityStatus { checking, online, offline }

/// A small, injectable boundary around the real backend reachability check.
///
/// An HTTP response proves that the network path reached a server. Its status
/// code deliberately does not decide whether the device is online: 401/403 are
/// authentication/authorization results, not connectivity failures.
abstract interface class BackendReachabilityProbe {
  Future<bool> canReachBackend();

  void dispose();
}

final class HttpBackendReachabilityProbe implements BackendReachabilityProbe {
  HttpBackendReachabilityProbe({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  /// Evaluated for every request so a restored tenant session can replace the
  /// public platform host without rebuilding the application.
  final String Function() baseUrl;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<bool> canReachBackend() async {
    try {
      final base = Uri.parse(baseUrl().trim());
      if (!_isPermittedBaseUrl(base)) return false;
      final health = base.replace(
        path: '/healthz/live',
        query: null,
        fragment: null,
      );
      final request = http.Request('GET', health)
        ..followRedirects = false
        ..headers.addAll(const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
        });
      final response = await _client.send(request).timeout(timeout);
      await response.stream.timeout(timeout).drain<void>();
      // Any actual HTTP response means the device reached the configured host.
      // In particular, never turn an expired session (401) or denied action
      // (403) into a misleading "no internet" screen.
      return response.statusCode >= 100 && response.statusCode <= 599;
    } on Object {
      return false;
    }
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

bool _isPermittedBaseUrl(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return false;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'https') return true;
  // Cleartext is useful for an emulator talking to a local dev server, but it
  // must never be accepted for a remote production host.
  return scheme == 'http' && _isLoopbackHost(uri.host);
}

bool _isLoopbackHost(String host) {
  final normalized = host.toLowerCase();
  if (normalized == 'localhost') return true;
  if (normalized == '::1' || normalized == '0:0:0:0:0:0:0:1') {
    return true;
  }
  final octets = normalized.split('.');
  if (octets.length != 4 || octets.first != '127') return false;
  return octets.every((octet) {
    final value = int.tryParse(octet);
    return value != null && value >= 0 && value <= 255;
  });
}

/// Owns the production connectivity gate and its bounded background probes.
///
/// Demo/local states pass [enabled] as false and are always left usable. The
/// online polling interval catches a connection that disappears while the app
/// remains foregrounded; lifecycle resume and the explicit retry action probe
/// immediately.
final class BackendReachabilityController extends ChangeNotifier {
  BackendReachabilityController({
    required this.enabled,
    required this.reachabilityProbe,
    this.onlinePollInterval = const Duration(seconds: 15),
    this.offlinePollInterval = const Duration(seconds: 5),
  }) : _status = enabled
           ? BackendReachabilityStatus.checking
           : BackendReachabilityStatus.online;

  final bool enabled;
  final Duration onlinePollInterval;
  final Duration offlinePollInterval;
  final BackendReachabilityProbe reachabilityProbe;

  BackendReachabilityStatus _status;
  bool _isChecking = false;
  bool _foreground = false;
  bool _disposed = false;
  Timer? _timer;
  Future<void>? _inFlight;

  BackendReachabilityStatus get status => _status;
  bool get isChecking => _isChecking;
  bool get blocksApp => enabled && _status != BackendReachabilityStatus.online;

  Future<void> start() {
    if (!enabled || _disposed) return Future<void>.value();
    _foreground = true;
    return _check(showCheckingSurface: true);
  }

  void pause() {
    _foreground = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> resume() {
    if (!enabled || _disposed) return Future<void>.value();
    _foreground = true;
    return _check(
      showCheckingSurface: _status != BackendReachabilityStatus.online,
    );
  }

  Future<void> retry() {
    if (!enabled || _disposed) return Future<void>.value();
    _foreground = true;
    return _check(showCheckingSurface: true);
  }

  Future<void> _check({required bool showCheckingSurface}) {
    final running = _inFlight;
    if (running != null) return running;

    _timer?.cancel();
    _timer = null;
    _isChecking = true;
    if (showCheckingSurface && _status != BackendReachabilityStatus.checking) {
      _status = BackendReachabilityStatus.checking;
    }
    notifyListeners();

    final future = _performCheck();
    _inFlight = future;
    return future;
  }

  Future<void> _performCheck() async {
    var reachable = false;
    try {
      reachable = await reachabilityProbe.canReachBackend();
    } on Object {
      reachable = false;
    }
    if (_disposed) return;
    _status = reachable
        ? BackendReachabilityStatus.online
        : BackendReachabilityStatus.offline;
    _isChecking = false;
    _inFlight = null;
    notifyListeners();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (!_foreground || _disposed || !enabled) return;
    final delay = _status == BackendReachabilityStatus.online
        ? onlinePollInterval
        : offlinePollInterval;
    if (delay <= Duration.zero) return;
    _timer = Timer(delay, () {
      if (_disposed || !_foreground) return;
      unawaited(_check(showCheckingSurface: false));
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    reachabilityProbe.dispose();
    super.dispose();
  }
}
