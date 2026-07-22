import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/api/starforge_api.dart';

abstract interface class PushDeviceRegistrar {
  Future<void> registerPushToken(String token);
}

final class StarforgePushDeviceRegistrar implements PushDeviceRegistrar {
  const StarforgePushDeviceRegistrar(this.api);

  final StarforgeApi api;

  @override
  Future<void> registerPushToken(String token) => api.registerPushToken(token);
}

enum PushNotificationState {
  idle,
  starting,
  configurationMissing,
  permissionDenied,
  registering,
  ready,
  failed,
}

final class PushEnvelope {
  const PushEnvelope({required this.messageId, required this.data});

  final String messageId;
  final Map<String, String> data;

  String? get threadId {
    final candidate = data['thread_id']?.trim() ?? '';
    return RegExp(r'^\d+$').hasMatch(candidate) ? candidate : null;
  }

  String? get tenantSlug {
    final candidate = data['tenant_slug']?.trim() ?? '';
    return RegExp(r'^[a-z0-9_-]{1,100}$').hasMatch(candidate)
        ? candidate
        : null;
  }
}

abstract interface class PushMessagingGateway {
  Stream<String> get tokenRefreshes;
  Stream<PushEnvelope> get foregroundMessages;
  Stream<PushEnvelope> get openedMessages;

  Future<PushGatewayStartResult> start();
  Future<String?> getToken();
  Future<PushEnvelope?> getInitialMessage();
  Future<void> deleteToken();
}

enum PushGatewayStartResult { ready, permissionDenied, configurationMissing }

void registerStarforgeBackgroundPushHandler() {
  FirebaseMessaging.onBackgroundMessage(
    starforgeFirebaseMessagingBackgroundHandler,
  );
}

@pragma('vm:entry-point')
Future<void> starforgeFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Notification payloads are displayed by Android/iOS themselves. The
  // isolate only initializes Firebase so data remains available when the user
  // taps the system notification; it never creates a duplicate local banner.
  if (Firebase.apps.isNotEmpty) return;
  try {
    final options = FirebasePushMessagingGateway.environmentOptions;
    if (options == null) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: options);
    }
  } on Object {
    // A build without owner-supplied Firebase config remains usable; push is
    // reported as unavailable by the foreground service after authentication.
  }
}

/// Firebase-backed gateway. It deliberately does not synthesize Firebase
/// credentials: the default native project files or a complete set of CI Dart
/// defines must be supplied by the application owner.
final class FirebasePushMessagingGateway implements PushMessagingGateway {
  factory FirebasePushMessagingGateway({FirebaseMessaging? messaging}) =>
      FirebasePushMessagingGateway._(messaging);

  FirebasePushMessagingGateway._(this._messaging);

  FirebaseMessaging? _messaging;
  bool _started = false;

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'uz.starforge.starforgeEdu',
  );

  static FirebaseOptions? get environmentOptions {
    if (_apiKey.isEmpty ||
        _appId.isEmpty ||
        _senderId.isEmpty ||
        _projectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      iosBundleId: Platform.isIOS ? _iosBundleId : null,
    );
  }

  @override
  Stream<String> get tokenRefreshes =>
      (_messaging ?? FirebaseMessaging.instance).onTokenRefresh;

  @override
  Stream<PushEnvelope> get foregroundMessages => FirebaseMessaging.onMessage
      .map(_envelope)
      .where((message) => message != null)
      .cast<PushEnvelope>();

  @override
  Stream<PushEnvelope> get openedMessages => FirebaseMessaging
      .onMessageOpenedApp
      .map(_envelope)
      .where((message) => message != null)
      .cast<PushEnvelope>();

  @override
  Future<PushGatewayStartResult> start() async {
    if (_started) return PushGatewayStartResult.ready;
    try {
      if (Firebase.apps.isEmpty) {
        final options = environmentOptions;
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          // This succeeds when google-services.json / GoogleService-Info.plist
          // has been supplied by CI. Missing native config is caught below.
          await Firebase.initializeApp();
        }
      }
      final messaging = _messaging ??= FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      // Foreground messages already enter the realtime in-app feed. Suppress
      // the second, platform banner so one message never appears twice.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return PushGatewayStartResult.permissionDenied;
      }
      _started = true;
      return PushGatewayStartResult.ready;
    } on FirebaseException {
      return PushGatewayStartResult.configurationMissing;
    } on Object {
      return PushGatewayStartResult.configurationMissing;
    }
  }

  @override
  Future<String?> getToken() async {
    final messaging = _messaging;
    if (!_started || messaging == null) return null;
    if (Platform.isIOS) {
      // Current Firebase Apple SDKs require APNs registration to finish before
      // requesting an FCM token. Give the OS a short, bounded window.
      for (var attempt = 0; attempt < 20; attempt++) {
        if (await messaging.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (await messaging.getAPNSToken() == null) return null;
    }
    return messaging.getToken();
  }

  @override
  Future<PushEnvelope?> getInitialMessage() async => _envelope(
    await (_messaging ?? FirebaseMessaging.instance).getInitialMessage(),
  );

  @override
  Future<void> deleteToken() async {
    final messaging = _messaging;
    if (messaging == null) return;
    await messaging.deleteToken();
  }

  static PushEnvelope? _envelope(RemoteMessage? message) {
    if (message == null) return null;
    return PushEnvelope(
      messageId:
          message.messageId ??
          '${message.sentTime?.millisecondsSinceEpoch ?? 0}:${message.data}',
      data: {
        for (final entry in message.data.entries)
          entry.key: entry.value.toString(),
      },
    );
  }
}

/// Owns notification permission, token lifecycle and deep-link delivery. The
/// service never displays a local foreground notification; WebSocket/in-app UI
/// remains the single foreground presentation.
final class PushNotificationService extends ChangeNotifier {
  factory PushNotificationService({
    required PushDeviceRegistrar registrar,
    required PushMessagingGateway gateway,
    required String? Function() activeTenantSlug,
    required void Function(String threadId) openThread,
    required Future<void> Function(String threadId) refreshThread,
  }) => PushNotificationService._(
    registrar,
    gateway,
    activeTenantSlug,
    openThread,
    refreshThread,
  );

  PushNotificationService._(
    this._registrar,
    this._gateway,
    this._activeTenantSlug,
    this._openThread,
    this._refreshThread,
  );

  final PushDeviceRegistrar _registrar;
  final PushMessagingGateway _gateway;
  final String? Function() _activeTenantSlug;
  final void Function(String threadId) _openThread;
  final Future<void> Function(String threadId) _refreshThread;

  PushNotificationState _state = PushNotificationState.idle;
  PushNotificationState get state => _state;
  bool _authenticated = false;
  bool _started = false;
  bool _disposed = false;
  String? _registeredToken;
  Future<void> _serial = Future<void>.value();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Set<String> _handledOpenMessageIds = <String>{};

  void syncAuthenticated(bool authenticated) {
    if (_disposed || _authenticated == authenticated) return;
    _authenticated = authenticated;
    _enqueue(authenticated ? _activate : _deactivate);
  }

  Future<void> retry() async {
    if (_disposed || !_authenticated) return;
    await _enqueue(_activate);
  }

  void refreshRegistration() {
    if (_disposed || !_authenticated) return;
    _enqueue(_activate);
  }

  Future<void> _activate() async {
    if (!_authenticated || _disposed) return;
    _setState(PushNotificationState.starting);
    if (!_started) {
      final result = await _gateway.start();
      if (!_authenticated || _disposed) return;
      switch (result) {
        case PushGatewayStartResult.configurationMissing:
          _setState(PushNotificationState.configurationMissing);
          return;
        case PushGatewayStartResult.permissionDenied:
          _setState(PushNotificationState.permissionDenied);
          return;
        case PushGatewayStartResult.ready:
          _started = true;
          _subscriptions.add(
            _gateway.tokenRefreshes.listen(
              (token) => _queueToken(token),
              onError: (_) => _setState(PushNotificationState.failed),
            ),
          );
          _subscriptions.add(
            _gateway.foregroundMessages.listen((message) {
              final threadId = message.threadId;
              if (threadId != null &&
                  _authenticated &&
                  _matchesActiveTenant(message)) {
                unawaited(_refreshSilently(threadId));
              }
            }),
          );
          _subscriptions.add(
            _gateway.openedMessages.listen(_handleOpenedMessage),
          );
      }
    }

    _setState(PushNotificationState.registering);
    try {
      final token = await _gateway.getToken();
      if (token == null || token.trim().isEmpty) {
        _setState(PushNotificationState.failed);
        return;
      }
      await _register(token);
      if (!_authenticated || _disposed) return;
      final initial = await _gateway.getInitialMessage();
      if (initial != null) _handleOpenedMessage(initial);
      _setState(PushNotificationState.ready);
    } on Object {
      if (_authenticated && !_disposed) {
        _setState(PushNotificationState.failed);
      }
    }
  }

  void _queueToken(String token) {
    _enqueue(() => _register(token));
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    Future<void> guardedOperation() async {
      try {
        await operation();
      } on Object {
        if (_authenticated && !_disposed) {
          _setState(PushNotificationState.failed);
        }
      }
    }

    // Run after either outcome of the prior operation. A transient registration
    // failure must never poison logout, retry, or a future account session.
    _serial = _serial.then<void>(
      (_) => guardedOperation(),
      onError: (Object _, StackTrace _) => guardedOperation(),
    );
    return _serial;
  }

  Future<void> _register(String token) async {
    final normalized = token.trim();
    if (!_authenticated ||
        normalized.isEmpty ||
        normalized == _registeredToken) {
      return;
    }
    await _registrar.registerPushToken(normalized);
    if (!_authenticated || _disposed) return;
    _registeredToken = normalized;
    _setState(PushNotificationState.ready);
  }

  void _handleOpenedMessage(PushEnvelope message) {
    if (!_authenticated ||
        !_matchesActiveTenant(message) ||
        !_handledOpenMessageIds.add(message.messageId)) {
      return;
    }
    if (_handledOpenMessageIds.length > 64) {
      _handledOpenMessageIds.remove(_handledOpenMessageIds.first);
    }
    final threadId = message.threadId;
    if (threadId != null) unawaited(_refreshAndOpen(threadId));
  }

  Future<void> _refreshAndOpen(String threadId) async {
    await _refreshSilently(threadId);
    if (_authenticated && !_disposed) _openThread(threadId);
  }

  Future<void> _refreshSilently(String threadId) async {
    try {
      await _refreshThread(threadId);
    } on Object {
      // Navigation still opens cached data, while a foreground refresh failure
      // remains owned by the conversation screen's normal retry state.
    }
  }

  bool _matchesActiveTenant(PushEnvelope message) {
    final pushedTenant = message.tenantSlug;
    final activeTenant = _activeTenantSlug()?.trim();
    return pushedTenant != null &&
        activeTenant != null &&
        activeTenant.isNotEmpty &&
        pushedTenant == activeTenant;
  }

  Future<void> _deactivate() async {
    _registeredToken = null;
    if (!_started) {
      _setState(PushNotificationState.idle);
      return;
    }
    try {
      await _gateway.deleteToken();
    } on Object {
      // Server-side device revocation is attempted before the auth token is
      // cleared. Deleting the local FCM token is an additional best effort.
    }
    _setState(PushNotificationState.idle);
  }

  void _setState(PushNotificationState value) {
    if (_state == value || _disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
