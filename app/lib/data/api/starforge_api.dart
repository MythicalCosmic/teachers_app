import 'dart:io';
import 'dart:math';

import 'api_client.dart';
import 'api_config.dart';
import 'api_models.dart';
import 'session_vault.dart';

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
  Future<void> Function()? _onAuthenticationRequired;

  bool get hasSession => _stored != null;
  TenantConnection? get connection => _stored?.connection;
  String get deviceId => _stored?.deviceId ?? '';

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
    _stored = stored;
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
        await _clearExpiredSession();
      }
      rethrow;
    }
  }

  Future<TenantConnection> resolveCenter(String slug) async {
    final normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) {
      final uri = Uri.parse(platformBaseUrl);
      return TenantConnection(
        slug: uri.host,
        name: 'StarForge EDU',
        baseUrl: platformBaseUrl,
        wsUrl: 'wss://${uri.authority}/ws/notifications/',
        locale: _locale,
      );
    }
    if (normalized.startsWith('https://') || normalized.startsWith('http://')) {
      final uri = Uri.parse(normalized);
      if (!uri.hasScheme || uri.host.isEmpty) {
        throw const ApiException(
          message: 'Markaz server manzili noto‘g‘ri.',
          code: 'validation_error',
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
      platformBaseUrl,
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
    return TenantConnection.fromJson(
      Map<String, Object?>.from(response.data! as Map),
      slug: normalized,
    );
  }

  Future<AuthenticatedIdentity> signIn({
    required String centerSlug,
    required String username,
    required String password,
    required bool remember,
  }) async {
    final connection = await resolveCenter(centerSlug);
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
    _stored = StoredSession(
      accessToken: token,
      connection: connection,
      deviceId: stableDeviceId,
    );
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
      if (remember) {
        await _vault.write(_stored!);
      } else {
        await _vault.clear();
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
      _stored = null;
      await _vault.clear();
      rethrow;
    }
  }

  Future<ApiJson> me() async {
    final response = await get('/api/v1/users/me/');
    if (response.data is! Map) {
      throw const ApiException(
        message: 'Profil javobi noto‘g‘ri.',
        code: 'invalid_response',
      );
    }
    return Map<String, Object?>.from(response.data! as Map);
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
      platformBaseUrl,
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
      platformBaseUrl,
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
    final response = await post(
      '/api/v1/auth/password/change/',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
    if (response.data is! Map) return;
    final newToken = apiString((response.data! as Map)['access']);
    final current = _stored;
    if (newToken.isEmpty || current == null) return;
    _stored = StoredSession(
      accessToken: newToken,
      connection: current.connection,
      deviceId: current.deviceId,
    );
    if (_remembered) await _vault.write(_stored!);
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async {
    final session = _requireSession();
    return _guardSession(
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
    Future<ApiResponse> Function() operation,
  ) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _clearExpiredSession();
      rethrow;
    }
  }

  Future<void> _clearExpiredSession() async {
    await clearSession();
    await _onAuthenticationRequired?.call();
  }

  Future<void> signOut({bool remote = true}) async {
    final session = _stored;
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
    await clearSession();
  }

  Future<void> clearSession() async {
    _stored = null;
    _remembered = false;
    await _vault.clear();
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
