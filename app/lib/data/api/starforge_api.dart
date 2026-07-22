import 'dart:io';
import 'dart:math';

import 'api_client.dart';
import 'api_config.dart';
import 'api_models.dart';
import 'session_vault.dart';
import 'transport_security.dart';

final class StarforgeApi {
  StarforgeApi({
    ApiClient? client,
    SessionVault? vault,
    String platformBaseUrl = ApiConfig.platformBaseUrl,
  }) : _client = client ?? ApiClient(),
       _vault = vault ?? SecureSessionVault(),
       platformBaseUrl = platformBaseUrl.replaceAll(RegExp(r'/+$'), '');

  final ApiClient _client;
  final SessionVault _vault;
  final String platformBaseUrl;

  StoredSession? _stored;
  String _locale = 'uz';
  bool _remembered = false;
  int? _pushDeviceResourceId;
  String? _authenticatedTenantSlug;
  Future<void> Function()? _onAuthenticationRequired;

  bool get hasSession => _stored != null;
  TenantConnection? get connection => _stored?.connection;
  String get deviceId => _stored?.deviceId ?? '';
  String? get authenticatedTenantSlug => _authenticatedTenantSlug;

  /// Read only by in-process transports such as the notification WebSocket.
  /// Never place this value in a URL, diagnostic, or persisted UI model.
  String? get currentAccessToken => _stored?.accessToken;

  void setLocale(String locale) => _locale = locale;

  /// Lets the application remove user-visible state as soon as any backend
  /// request reports an expired or revoked session.
  void setAuthenticationRequiredHandler(Future<void> Function()? handler) {
    _onAuthenticationRequired = handler;
  }

  Future<AuthenticatedIdentity?> restore() async {
    final stored = await _vault.read();
    if (stored == null) return null;
    try {
      _validateConnection(stored.connection);
    } on ApiException {
      await _vault.clear();
      rethrow;
    }
    _stored = stored;
    _pushDeviceResourceId = null;
    _authenticatedTenantSlug = null;
    _remembered = true;
    try {
      final profile = await me();
      return AuthenticatedIdentity(
        accessToken: stored.accessToken,
        connection: stored.connection,
        profile: profile,
        principalKind: apiString(profile['principal_kind']),
        mustChangePassword: apiBool(profile['must_change_password']),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 && hasSession) {
        await _clearExpiredSession(stored);
      }
      rethrow;
    }
  }

  Future<TenantConnection> resolveCenter(String slug) async {
    final normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) {
      final safePlatformBaseUrl = _requireSecurePlatformBaseUrl();
      final uri = Uri.parse(safePlatformBaseUrl);
      return TenantConnection(
        slug: uri.host,
        name: 'StarForge EDU',
        baseUrl: safePlatformBaseUrl,
        wsUrl:
            '${uri.scheme == 'https' ? 'wss' : 'ws'}://${uri.authority}/ws/notifications/',
        locale: _locale,
      );
    }
    if (normalized.startsWith('https://') || normalized.startsWith('http://')) {
      final uri = Uri.tryParse(normalized);
      if (uri == null || !isPermittedHttpUri(uri)) {
        throw const ApiException(
          message:
              'Markaz serveri HTTPS ishlatishi kerak. HTTP faqat shu qurilmadagi test serveri uchun ruxsat etiladi.',
          code: 'insecure_transport',
        );
      }
      final base = uri
          .replace(path: '', query: null, fragment: null)
          .toString();
      return TenantConnection(
        slug: uri.host,
        name: 'StarForge EDU',
        baseUrl: base,
        wsUrl:
            '${uri.scheme == 'https' ? 'wss' : 'ws'}://${uri.authority}/ws/notifications/',
        locale: _locale,
      );
    }
    final response = await _client.get(
      _requireSecurePlatformBaseUrl(),
      '/api/v1/platform/resolve/',
      locale: _locale,
      query: {'slug': normalized},
    );
    if (response.data is! Map) {
      throw const ApiException(
        message: 'Markaz serveri noto‘g‘ri javob qaytardi.',
        code: 'invalid_response',
      );
    }
    try {
      final connection = TenantConnection.fromJson(
        Map<String, Object?>.from(response.data! as Map),
        slug: normalized,
      );
      _validateConnection(connection);
      return connection;
    } on FormatException {
      throw const ApiException(
        message: 'Markaz serveri xavfsiz HTTPS/WSS manzilini qaytarmadi.',
        code: 'insecure_transport',
      );
    }
  }

  Future<AuthenticatedIdentity> signIn({
    required String centerSlug,
    required String username,
    required String password,
    required bool remember,
  }) async {
    final requestedCenter = centerSlug.trim().isEmpty
        ? ApiConfig.defaultCenterSlug
        : centerSlug;
    final connection = await resolveCenter(requestedCenter);
    final priorDeviceId = await _vault.readDeviceId();
    final stableDeviceId = priorDeviceId?.isNotEmpty == true
        ? priorDeviceId!
        : _newDeviceId();
    await _vault.writeDeviceId(stableDeviceId);
    final response = await _client.post(
      connection.baseUrl,
      '/api/v1/auth/role-login/',
      locale: _locale,
      body: {
        'username': username.trim(),
        'password': password,
        'device_id': stableDeviceId,
        'platform': _platform,
      },
    );
    if (response.data is! Map) {
      throw const ApiException(
        message: 'Kirish javobi noto‘g‘ri.',
        code: 'invalid_response',
      );
    }
    final auth = Map<String, Object?>.from(response.data! as Map);
    final token = apiString(auth['access']);
    if (token.isEmpty) {
      throw const ApiException(
        message: 'Server sessiya kalitini qaytarmadi.',
        code: 'invalid_response',
      );
    }
    final authenticatingSession = StoredSession(
      accessToken: token,
      connection: connection,
      deviceId: stableDeviceId,
    );
    _stored = authenticatingSession;
    _pushDeviceResourceId = null;
    _authenticatedTenantSlug = null;
    try {
      final profile = await me();
      final principalKind = apiString(profile['principal_kind']);
      if (principalKind != 'teacher' && principalKind != 'staff') {
        await signOut(remote: true);
        throw const ApiException(
          message: 'Bu ilova faqat o‘qituvchi va xodimlar uchun.',
          statusCode: 403,
          code: 'staff_app_only',
        );
      }
      if (!identical(_stored, authenticatingSession)) {
        throw const ApiException(
          message: 'Sessiya kirish vaqtida o‘zgardi.',
          code: 'session_changed',
        );
      }
      if (remember) {
        await _vault.write(authenticatingSession);
      } else {
        await _vault.clear();
      }
      if (!identical(_stored, authenticatingSession)) {
        throw const ApiException(
          message: 'Sessiya kirish vaqtida o‘zgardi.',
          code: 'session_changed',
        );
      }
      _remembered = remember;
      return AuthenticatedIdentity(
        accessToken: token,
        connection: connection,
        profile: profile,
        principalKind: principalKind,
        mustChangePassword: apiBool(auth['must_change_password']),
      );
    } on Object {
      await clearSession(expectedSession: authenticatingSession);
      rethrow;
    }
  }

  Future<ApiJson> me() async {
    final expectedSession = _requireSession();
    final response = await get('/api/v1/users/me/');
    if (response.data is! Map) {
      throw const ApiException(
        message: 'Profil javobi noto‘g‘ri.',
        code: 'invalid_response',
      );
    }
    if (!identical(_stored, expectedSession)) {
      throw const ApiException(
        message: 'Sessiya profil yuklanayotganda o‘zgardi.',
        code: 'session_changed',
      );
    }
    final profile = Map<String, Object?>.from(response.data! as Map);
    final tenantSlug = apiString(profile['tenant_slug']).trim();
    _authenticatedTenantSlug =
        RegExp(r'^[a-z0-9_-]{1,100}$').hasMatch(tenantSlug) ? tenantSlug : null;
    return profile;
  }

  Future<ApiJson> updateMe(ApiJson changes) async {
    final response = await patch('/api/v1/users/me/', body: changes);
    if (response.data is! Map) {
      throw const ApiException(
        message: 'Profil javobi noto‘g‘ri.',
        code: 'invalid_response',
      );
    }
    return Map<String, Object?>.from(response.data! as Map);
  }

  Future<void> requestPasswordReset({
    required String identifier,
    String accountType = 'staff',
  }) async {
    await _client.post(
      _requireSecurePlatformBaseUrl(),
      '/api/v1/auth/password/reset/request/',
      locale: _locale,
      body: {'identifier': identifier.trim(), 'account_type': accountType},
    );
  }

  Future<void> confirmPasswordReset({
    required String identifier,
    required String code,
    required String newPassword,
    String accountType = 'staff',
  }) async {
    await _client.post(
      _requireSecurePlatformBaseUrl(),
      '/api/v1/auth/password/reset/confirm/',
      locale: _locale,
      body: {
        'identifier': identifier.trim(),
        'code': code.trim(),
        'new_password': newPassword,
        'account_type': accountType,
      },
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final expectedSession = _requireSession();
    final response = await post(
      '/api/v1/auth/password/change/',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
    if (response.data is! Map) return;
    final newToken = apiString((response.data! as Map)['access']);
    if (newToken.isEmpty || !identical(_stored, expectedSession)) return;
    _stored = StoredSession(
      accessToken: newToken,
      connection: expectedSession.connection,
      deviceId: expectedSession.deviceId,
    );
    if (_remembered) await _vault.write(_stored!);
  }

  /// Registers (or refreshes) this installation's FCM token against the
  /// authenticated tenant. The backend owns tenant isolation; only the stable
  /// device id created before login is sent.
  Future<void> registerPushToken(String token) async {
    final expectedSession = _requireSession();
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        token,
        'token',
        'Push token must not be empty.',
      );
    }
    final response = await post(
      '/api/v1/users/devices/',
      body: {
        'device_id': expectedSession.deviceId,
        'platform': _platform,
        'push_token': normalized,
      },
    );
    if (!identical(_stored, expectedSession) || response.data is! Map) return;
    final rawId = (response.data! as Map)['id'];
    _pushDeviceResourceId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');
  }

  /// Revokes this installation without exposing its token. Used before local
  /// credential deletion so a signed-out device cannot keep receiving staff
  /// messages. A missing resource is already the desired state.
  Future<void> revokeCurrentPushDevice() async {
    final expectedSession = _requireSession();
    var resourceId = _pushDeviceResourceId;
    if (resourceId == null) {
      final response = await get(
        '/api/v1/users/devices/',
        query: const {'page_size': 100},
      );
      if (!identical(_stored, expectedSession)) return;
      for (final item in apiMaps(response.data)) {
        if (apiString(item['device_id']) != expectedSession.deviceId) continue;
        resourceId = item['id'] is int
            ? item['id']! as int
            : int.tryParse(item['id']?.toString() ?? '');
        break;
      }
    }
    if (resourceId == null || !identical(_stored, expectedSession)) return;
    try {
      await delete('/api/v1/users/devices/$resourceId/');
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
    }
    if (identical(_stored, expectedSession)) _pushDeviceResourceId = null;
  }

  String _requireSecurePlatformBaseUrl() {
    final uri = Uri.tryParse(platformBaseUrl);
    if (uri == null || !isPermittedHttpUri(uri)) {
      throw const ApiException(
        message:
            'Platform serveri HTTPS ishlatishi kerak. HTTP faqat shu qurilmadagi test serveri uchun ruxsat etiladi.',
        code: 'insecure_transport',
      );
    }
    return platformBaseUrl;
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final session = _requireSession();
    return _guardSession(
      session,
      () => _client.get(
        session.connection.baseUrl,
        path,
        token: session.accessToken,
        locale: _locale,
        query: query,
      ),
    );
  }

  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) async {
    final session = _requireSession();
    return _guardSession(
      session,
      () => _client.post(
        session.connection.baseUrl,
        path,
        token: session.accessToken,
        locale: _locale,
        body: body,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<ApiResponse> patch(String path, {Object? body}) async {
    final session = _requireSession();
    return _guardSession(
      session,
      () => _client.patch(
        session.connection.baseUrl,
        path,
        token: session.accessToken,
        locale: _locale,
        body: body,
      ),
    );
  }

  Future<ApiResponse> put(String path, {Object? body}) async {
    final session = _requireSession();
    return _guardSession(
      session,
      () => _client.put(
        session.connection.baseUrl,
        path,
        token: session.accessToken,
        locale: _locale,
        body: body,
      ),
    );
  }

  Future<ApiResponse> delete(String path, {Object? body}) async {
    final session = _requireSession();
    return _guardSession(
      session,
      () => _client.delete(
        session.connection.baseUrl,
        path,
        token: session.accessToken,
        locale: _locale,
        body: body,
      ),
    );
  }

  Future<ApiResponse> _guardSession(
    StoredSession expectedSession,
    Future<ApiResponse> Function() operation,
  ) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      if (error.statusCode == 401 && identical(_stored, expectedSession)) {
        await _clearExpiredSession(expectedSession);
      }
      rethrow;
    }
  }

  Future<void> _clearExpiredSession(StoredSession expectedSession) async {
    Future<void>? cleanup;
    try {
      cleanup = _onAuthenticationRequired?.call();
    } on Object {
      // Credential removal below remains mandatory even if the UI callback
      // fails synchronously.
    }
    await clearSession(expectedSession: expectedSession);
    try {
      await cleanup;
    } on Object {
      // The token is already gone. UI/cache cleanup reports its own failure.
    }
  }

  Future<void> signOut({bool remote = true}) async {
    final session = _stored;
    if (remote && session != null) {
      try {
        await revokeCurrentPushDevice();
      } on Object {
        // Logout must remain available offline. The local FCM token is deleted
        // separately and the backend token is invalidated by Firebase on send.
      }
    }
    await clearSession(expectedSession: session);
    if (remote && session != null) {
      try {
        await _client.post(
          session.connection.baseUrl,
          '/api/v1/auth/logout/',
          token: session.accessToken,
          locale: _locale,
        );
      } on Object {
        // Local credential removal is mandatory even when the server is offline.
      }
    }
  }

  Future<void> clearSession({StoredSession? expectedSession}) async {
    if (expectedSession != null && !identical(_stored, expectedSession)) return;
    _stored = null;
    _pushDeviceResourceId = null;
    _authenticatedTenantSlug = null;
    _remembered = false;
    await _vault.clear();
  }

  Future<void> clearSessionIfCurrent(String? expectedAccessToken) async {
    if (expectedAccessToken == null || expectedAccessToken.isEmpty) return;
    final session = _stored;
    if (session == null || session.accessToken != expectedAccessToken) return;
    await clearSession(expectedSession: session);
  }

  void _validateConnection(TenantConnection connection) {
    final baseUri = Uri.tryParse(connection.baseUrl);
    if (baseUri == null || !isPermittedHttpUri(baseUri)) {
      throw const ApiException(
        message: 'Saqlangan markaz serveri HTTPS bilan himoyalanmagan.',
        code: 'insecure_transport',
      );
    }
    if (connection.wsUrl.isEmpty) return;
    final wsUri = Uri.tryParse(connection.wsUrl);
    if (wsUri == null || !isPermittedWebSocketUri(wsUri)) {
      throw const ApiException(
        message: 'Saqlangan bildirishnoma manzili WSS bilan himoyalanmagan.',
        code: 'insecure_transport',
      );
    }
  }

  StoredSession _requireSession() {
    final session = _stored;
    if (session == null) {
      throw const ApiException(
        message: 'Sessiya topilmadi. Qayta kiring.',
        statusCode: 401,
        code: 'authentication_failed',
      );
    }
    return session;
  }

  String _newDeviceId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String get _platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }
}
