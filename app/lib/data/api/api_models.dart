import 'dart:convert';

import 'transport_security.dart';

typedef ApiJson = Map<String, Object?>;

final class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code = 'error',
    this.fields = const {},
    this.requestId,
    this.retryAfter,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final String code;
  final Map<String, List<String>> fields;
  final String? requestId;
  final Duration? retryAfter;
  final bool isNetworkError;

  bool get isAuthenticationFailure =>
      statusCode == 401 &&
      (code == 'authentication_failed' || code == 'invalid_credentials');

  bool get isSessionExpired =>
      statusCode == 401 && code == 'authentication_failed';

  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

final class TenantConnection {
  const TenantConnection({
    required this.slug,
    required this.name,
    required this.baseUrl,
    required this.wsUrl,
    required this.locale,
    this.logoUrl = '',
  });

  final String slug;
  final String name;
  final String baseUrl;
  final String wsUrl;
  final String locale;
  final String logoUrl;

  ApiJson toJson() => {
    'slug': slug,
    'name': name,
    'base_url': baseUrl,
    'ws_url': wsUrl,
    'locale': locale,
    'logo': logoUrl,
  };

  factory TenantConnection.fromJson(ApiJson json, {String? slug}) {
    final baseUrl = _requiredString(
      json,
      'base_url',
    ).replaceAll(RegExp(r'/+$'), '');
    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null || !isPermittedHttpUri(baseUri)) {
      throw const FormatException(
        'Tenant base_url must use HTTPS (HTTP is allowed only on loopback).',
      );
    }
    final wsUrl = _string(json['ws_url']);
    final wsUri = wsUrl.isEmpty ? null : Uri.tryParse(wsUrl);
    if (wsUrl.isNotEmpty &&
        (wsUri == null || !isPermittedWebSocketUri(wsUri))) {
      throw const FormatException(
        'Tenant ws_url must use WSS (WS is allowed only on loopback).',
      );
    }
    return TenantConnection(
      slug: slug ?? _string(json['slug']),
      name: _string(json['name'], fallback: 'StarForge EDU'),
      baseUrl: baseUrl,
      wsUrl: wsUrl,
      locale: _string(json['locale'], fallback: 'uz'),
      logoUrl: _string(json['logo']),
    );
  }
}

final class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.connection,
    required this.deviceId,
  });

  final String accessToken;
  final TenantConnection connection;
  final String deviceId;

  String encode() => jsonEncode({
    'access_token': accessToken,
    'connection': connection.toJson(),
    'device_id': deviceId,
  });

  factory StoredSession.decode(String raw) {
    final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
    return StoredSession(
      accessToken: _requiredString(json, 'access_token'),
      connection: TenantConnection.fromJson(
        Map<String, Object?>.from(json['connection']! as Map),
      ),
      deviceId: _requiredString(json, 'device_id'),
    );
  }
}

final class AuthenticatedIdentity {
  const AuthenticatedIdentity({
    required this.accessToken,
    required this.connection,
    required this.profile,
    required this.principalKind,
    required this.mustChangePassword,
  });

  final String accessToken;
  final TenantConnection connection;
  final ApiJson profile;
  final String principalKind;
  final bool mustChangePassword;
}

final class ApiPage<T> {
  const ApiPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
    required this.hasPrevious,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;
  final bool hasPrevious;

  factory ApiPage.fromEnvelope(
    Object? data,
    Object? pagination,
    T Function(ApiJson json) decode,
  ) {
    final list = data is List ? data : const <Object?>[];
    final page = pagination is Map
        ? Map<String, Object?>.from(pagination)
        : const <String, Object?>{};
    return ApiPage<T>(
      items: [
        for (final value in list)
          if (value is Map) decode(Map<String, Object?>.from(value)),
      ],
      page: _integer(page['page'], fallback: 1),
      pageSize: _integer(page['page_size'], fallback: list.length),
      total: _integer(page['total'], fallback: list.length),
      hasNext: page['has_next'] == true,
      hasPrevious: page['has_prev'] == true,
    );
  }
}

String apiString(Object? value, {String fallback = ''}) =>
    _string(value, fallback: fallback);

int apiInt(Object? value, {int fallback = 0}) =>
    _integer(value, fallback: fallback);

bool apiBool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

DateTime? apiDate(Object? value) => DateTime.tryParse(_string(value));

List<ApiJson> apiMaps(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, Object?>.from(item),
      ]
    : const [];

String _requiredString(ApiJson json, String key) {
  final value = _string(json[key]);
  if (value.isEmpty) throw FormatException('Missing API field: $key');
  return value;
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
