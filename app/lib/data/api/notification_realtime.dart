import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef NotificationRealtimeValueProvider = FutureOr<String?> Function();

typedef NotificationRealtimeDelay = Future<void> Function(Duration duration);

typedef NotificationRealtimeSocketFactory =
    NotificationRealtimeSocket Function(
      Uri uri, {
      required Iterable<String> protocols,
    });

/// Small socket surface that keeps the realtime lifecycle independently testable.
abstract interface class NotificationRealtimeSocket {
  Future<void> get ready;

  Stream<Object?> get messages;

  int? get closeCode;

  void send(Object? message);

  Future<void> close([int? closeCode, String? closeReason]);
}

enum NotificationRealtimeStatus {
  idle,
  connecting,
  connected,
  waitingToReconnect,
  paused,
  authenticationRequired,
  forbidden,
  disposed,
}

/// Diagnostics are deliberately data-free so credentials, URLs, and payloads can
/// never leak through logs or analytics attached by an app-level consumer.
enum NotificationRealtimeIssue {
  credentialsUnavailable,
  invalidWebSocketUrl,
  connectionFailed,
  malformedFrame,
  sendFailed,
}

final class RealtimeNotification {
  const RealtimeNotification({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.data,
    required this.payload,
    this.createdAt,
  });

  final String id;
  final String eventType;
  final String title;
  final String body;
  final Map<String, Object?> data;
  final Map<String, Object?> payload;
  final DateTime? createdAt;

  static RealtimeNotification? tryDecode(Object? value) {
    if (value is! Map) return null;
    final frame = Map<String, Object?>.from(value);
    if (frame['type'] != 'notification' || frame['payload'] is! Map) {
      return null;
    }
    final payload = Map<String, Object?>.from(frame['payload']! as Map);
    final rawData = payload['data'];
    return RealtimeNotification(
      id: _text(payload['id']),
      eventType: _text(payload['event_type']),
      title: _text(payload['title']),
      body: _text(payload['body']),
      data: rawData is Map
          ? Map<String, Object?>.from(rawData)
          : const <String, Object?>{},
      payload: Map.unmodifiable(payload),
      createdAt: DateTime.tryParse(_text(payload['created_at'])),
    );
  }
}

/// Owns the notification WebSocket without depending on app/session state.
///
/// [wsUrl] and [accessToken] are evaluated for every connection attempt, so a
/// resumed or reconnected client automatically picks up rotated credentials.
final class NotificationRealtimeClient {
  NotificationRealtimeClient({
    required NotificationRealtimeValueProvider wsUrl,
    required NotificationRealtimeValueProvider accessToken,
    NotificationRealtimeSocketFactory? socketFactory,
    NotificationRealtimeDelay? delay,
    Random? random,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
  }) : assert(!initialReconnectDelay.isNegative),
       assert(maxReconnectDelay >= initialReconnectDelay),
       // Public callback names stay clear while the credential providers remain
       // private implementation details.
       // ignore: prefer_initializing_formals
       _wsUrl = wsUrl,
       // ignore: prefer_initializing_formals
       _accessToken = accessToken,
       _socketFactory = socketFactory ?? _connectSocket,
       // Keep the public named argument `delay` while storing its optional
       // test override privately.
       // ignore: prefer_initializing_formals
       _delay = delay,
       _random = random ?? Random.secure();

  static const unauthorizedCloseCode = 4401;
  static const forbiddenCloseCode = 4403;

  final NotificationRealtimeValueProvider _wsUrl;
  final NotificationRealtimeValueProvider _accessToken;
  final NotificationRealtimeSocketFactory _socketFactory;
  final NotificationRealtimeDelay? _delay;
  final Random _random;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;

  final StreamController<RealtimeNotification> _notifications =
      StreamController<RealtimeNotification>.broadcast();
  final StreamController<NotificationRealtimeStatus> _states =
      StreamController<NotificationRealtimeStatus>.broadcast();
  final StreamController<NotificationRealtimeIssue> _issues =
      StreamController<NotificationRealtimeIssue>.broadcast();

  NotificationRealtimeSocket? _socket;
  StreamSubscription<Object?>? _subscription;
  NotificationRealtimeStatus _status = NotificationRealtimeStatus.idle;
  bool _active = false;
  bool _disposed = false;
  bool _reconnectScheduled = false;
  Timer? _reconnectTimer;
  int _epoch = 0;
  int _reconnectAttempt = 0;

  Stream<RealtimeNotification> get notifications => _notifications.stream;

  Stream<NotificationRealtimeStatus> get states => _states.stream;

  Stream<NotificationRealtimeIssue> get issues => _issues.stream;

  NotificationRealtimeStatus get status => _status;

  bool get isConnected => _status == NotificationRealtimeStatus.connected;

  bool get isPaused => _status == NotificationRealtimeStatus.paused;

  bool get isDisposed => _disposed;

  Future<void> start() => resume();

  Future<void> resume() async {
    if (_disposed) {
      throw StateError('Notification realtime client is disposed.');
    }
    if (_active) return;
    _cancelReconnect();
    _active = true;
    _reconnectScheduled = false;
    _reconnectAttempt = 0;
    final epoch = ++_epoch;
    await _connect(epoch);
  }

  Future<void> pause() async {
    if (_disposed || (!_active && isPaused)) return;
    _active = false;
    _cancelReconnect();
    ++_epoch;
    await _closeCurrent(1000, 'paused');
    _setStatus(NotificationRealtimeStatus.paused);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _active = false;
    _cancelReconnect();
    ++_epoch;
    await _closeCurrent(1000, 'disposed');
    _setStatus(NotificationRealtimeStatus.disposed);
    await _notifications.close();
    await _states.close();
    await _issues.close();
  }

  Future<void> _connect(int epoch) async {
    if (!_isCurrent(epoch)) return;
    _setStatus(NotificationRealtimeStatus.connecting);
    NotificationRealtimeSocket? candidate;
    try {
      final rawUrl = (await _wsUrl())?.trim() ?? '';
      if (!_isCurrent(epoch)) return;
      final token = (await _accessToken())?.trim() ?? '';
      if (!_isCurrent(epoch)) return;
      if (rawUrl.isEmpty || token.isEmpty) {
        _stopForConfigurationIssue(
          NotificationRealtimeIssue.credentialsUnavailable,
        );
        return;
      }
      final uri = Uri.tryParse(rawUrl);
      if (uri == null ||
          !uri.hasScheme ||
          uri.host.isEmpty ||
          (uri.scheme != 'ws' && uri.scheme != 'wss')) {
        _stopForConfigurationIssue(
          NotificationRealtimeIssue.invalidWebSocketUrl,
        );
        return;
      }
      candidate = _socketFactory(uri, protocols: <String>['bearer.$token']);
      _socket = candidate;
      await candidate.ready;
      if (!_isCurrent(epoch) || !identical(_socket, candidate)) {
        await _safeClose(candidate, 1000, 'stale');
        return;
      }
      _reconnectAttempt = 0;
      _subscription = candidate.messages.listen(
        (frame) => _handleFrame(candidate!, epoch, frame),
        onError: (Object _, StackTrace _) {
          unawaited(_handleDisconnect(candidate!, epoch));
        },
        onDone: () {
          unawaited(_handleDisconnect(candidate!, epoch));
        },
      );
      _setStatus(NotificationRealtimeStatus.connected);
    } on Object {
      final rejectedCloseCode = candidate?.closeCode;
      if (candidate != null) {
        if (identical(_socket, candidate)) _socket = null;
        await _safeClose(candidate, 1011, 'connect-failed');
      }
      if (_isCurrent(epoch)) {
        if (_stopForTerminalClose(rejectedCloseCode)) return;
        _emitIssue(NotificationRealtimeIssue.connectionFailed);
        _scheduleReconnect(epoch);
      }
    }
  }

  void _handleFrame(
    NotificationRealtimeSocket socket,
    int epoch,
    Object? rawFrame,
  ) {
    if (!_isCurrent(epoch) || !identical(_socket, socket)) return;
    final decoded = _decodeFrame(rawFrame);
    if (decoded is! Map) {
      _emitIssue(NotificationRealtimeIssue.malformedFrame);
      return;
    }
    final frame = Map<String, Object?>.from(decoded);
    if (frame['type'] == 'ping') {
      try {
        socket.send(jsonEncode(const {'type': 'pong'}));
      } on Object {
        _emitIssue(NotificationRealtimeIssue.sendFailed);
      }
      return;
    }
    final notification = RealtimeNotification.tryDecode(frame);
    if (notification == null) {
      _emitIssue(NotificationRealtimeIssue.malformedFrame);
      return;
    }
    if (!_notifications.isClosed) _notifications.add(notification);
  }

  Future<void> _handleDisconnect(
    NotificationRealtimeSocket socket,
    int epoch,
  ) async {
    if (!_isCurrent(epoch) || !identical(_socket, socket)) return;
    final closeCode = socket.closeCode;
    _socket = null;
    _subscription = null;
    await _safeClose(socket);
    if (!_isCurrent(epoch)) return;
    if (_stopForTerminalClose(closeCode)) return;
    _scheduleReconnect(epoch);
  }

  bool _stopForTerminalClose(int? closeCode) {
    final terminalStatus = switch (closeCode) {
      unauthorizedCloseCode =>
        NotificationRealtimeStatus.authenticationRequired,
      forbiddenCloseCode => NotificationRealtimeStatus.forbidden,
      _ => null,
    };
    if (terminalStatus == null) return false;
    _active = false;
    _setStatus(terminalStatus);
    return true;
  }

  void _scheduleReconnect(int epoch) {
    if (!_isCurrent(epoch) || _reconnectScheduled) return;
    _reconnectScheduled = true;
    _setStatus(NotificationRealtimeStatus.waitingToReconnect);
    final wait = _nextReconnectDelay();
    final customDelay = _delay;
    if (customDelay != null) {
      unawaited(() async {
        await customDelay(wait);
        if (!_isCurrent(epoch)) return;
        _reconnectScheduled = false;
        await _connect(epoch);
      }());
      return;
    }
    _reconnectTimer = Timer(wait, () {
      _reconnectTimer = null;
      if (!_isCurrent(epoch)) return;
      _reconnectScheduled = false;
      unawaited(_connect(epoch));
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectScheduled = false;
  }

  void _stopForConfigurationIssue(NotificationRealtimeIssue issue) {
    _emitIssue(issue);
    _active = false;
    _cancelReconnect();
    // A missing or malformed endpoint cannot heal by retrying the same tenant
    // configuration forever. A later explicit resume re-reads both providers.
    _setStatus(NotificationRealtimeStatus.paused);
  }

  Duration _nextReconnectDelay() {
    final initialMs = initialReconnectDelay.inMilliseconds;
    final maxMs = maxReconnectDelay.inMilliseconds;
    if (maxMs == 0) {
      _reconnectAttempt++;
      return Duration.zero;
    }
    final exponent = _reconnectAttempt.clamp(0, 20);
    _reconnectAttempt++;
    final expanded = initialMs * (1 << exponent);
    final capped = min(expanded, maxMs);
    final floor = capped ~/ 2;
    final jittered = floor + ((capped - floor) * _random.nextDouble()).round();
    return Duration(milliseconds: min(jittered, maxMs));
  }

  Future<void> _closeCurrent(int closeCode, String reason) async {
    final subscription = _subscription;
    final socket = _socket;
    _subscription = null;
    _socket = null;
    await subscription?.cancel();
    if (socket != null) await _safeClose(socket, closeCode, reason);
  }

  Future<void> _safeClose(
    NotificationRealtimeSocket socket, [
    int? closeCode,
    String? reason,
  ]) async {
    try {
      await socket.close(closeCode, reason);
    } on Object {
      // Closing is best effort; lifecycle state must still converge locally.
    }
  }

  bool _isCurrent(int epoch) => !_disposed && _active && epoch == _epoch;

  void _setStatus(NotificationRealtimeStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_states.isClosed) _states.add(next);
  }

  void _emitIssue(NotificationRealtimeIssue issue) {
    if (!_issues.isClosed) _issues.add(issue);
  }
}

Object? _decodeFrame(Object? frame) {
  if (frame is Map) return frame;
  try {
    if (frame is String) return jsonDecode(frame);
    if (frame is List<int>) return jsonDecode(utf8.decode(frame));
  } on FormatException {
    return null;
  }
  return null;
}

String _text(Object? value) => value?.toString().trim() ?? '';

NotificationRealtimeSocket _connectSocket(
  Uri uri, {
  required Iterable<String> protocols,
}) => _WebSocketRealtimeSocket(
  WebSocketChannel.connect(uri, protocols: protocols),
);

final class _WebSocketRealtimeSocket implements NotificationRealtimeSocket {
  const _WebSocketRealtimeSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  int? get closeCode => _channel.closeCode;

  @override
  Stream<Object?> get messages => _channel.stream;

  @override
  Future<void> get ready => _channel.ready;

  @override
  void send(Object? message) => _channel.sink.add(message);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    await _channel.sink.close(closeCode, closeReason);
  }
}
