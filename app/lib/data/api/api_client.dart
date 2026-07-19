import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_models.dart';

final class ApiResponse {
  const ApiResponse({
    required this.data,
    required this.pagination,
    required this.statusCode,
    required this.requestId,
    this.warnings = const [],
  });

  final Object? data;
  final Object? pagination;
  final int statusCode;
  final String requestId;
  final List<String> warnings;
}

final class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this._timeout = ApiConfig.requestTimeout,
    Random? random,
  }) : _http = httpClient ?? http.Client(),
       _random = random ?? Random.secure();

  final http.Client _http;
  final Duration _timeout;
  final Random _random;

  Future<ApiResponse> get(
    String baseUrl,
    String path, {
    String? token,
    String locale = 'uz',
    Map<String, Object?> query = const {},
  }) => _send(
    method: 'GET',
    baseUrl: baseUrl,
    path: path,
    token: token,
    locale: locale,
    query: query,
    retrySafe: true,
  );

  Future<ApiResponse> post(
    String baseUrl,
    String path, {
    String? token,
    String locale = 'uz',
    Object? body,
    String? idempotencyKey,
  }) => _send(
    method: 'POST',
    baseUrl: baseUrl,
    path: path,
    token: token,
    locale: locale,
    body: body,
    idempotencyKey: idempotencyKey,
  );

  Future<ApiResponse> patch(
    String baseUrl,
    String path, {
    String? token,
    String locale = 'uz',
    Object? body,
  }) => _send(
    method: 'PATCH',
    baseUrl: baseUrl,
    path: path,
    token: token,
    locale: locale,
    body: body,
  );

  Future<ApiResponse> put(
    String baseUrl,
    String path, {
    String? token,
    String locale = 'uz',
    Object? body,
  }) => _send(
    method: 'PUT',
    baseUrl: baseUrl,
    path: path,
    token: token,
    locale: locale,
    body: body,
  );

  Future<ApiResponse> delete(
    String baseUrl,
    String path, {
    String? token,
    String locale = 'uz',
    Object? body,
  }) => _send(
    method: 'DELETE',
    baseUrl: baseUrl,
    path: path,
    token: token,
    locale: locale,
    body: body,
  );

  Future<ApiResponse> _send({
    required String method,
    required String baseUrl,
    required String path,
    String? token,
    String locale = 'uz',
    Map<String, Object?> query = const {},
    Object? body,
    String? idempotencyKey,
    bool retrySafe = false,
  }) async {
    final requestId = _uuid();
    final uri = _buildUri(baseUrl, path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': locale,
      'X-Request-ID': requestId,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      'Idempotency-Key': ?idempotencyKey,
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final attempts = retrySafe ? 3 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await _dispatch(
          method,
          uri,
          headers,
          encodedBody,
        ).timeout(_timeout);
        if (retrySafe && response.statusCode >= 500 && attempt + 1 < attempts) {
          await Future<void>.delayed(_retryDelay(attempt));
          continue;
        }
        return _decode(response, requestId);
      } on ApiException {
        rethrow;
      } on TimeoutException {
        // Retried below for idempotent reads.
      } on http.ClientException {
        // Retried below for idempotent reads.
      }
      if (attempt + 1 < attempts) {
        await Future<void>.delayed(_retryDelay(attempt));
      }
    }
    throw ApiException(
      message:
          'Server bilan bog‘lanib bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.',
      code: 'network_error',
      requestId: requestId,
      isNetworkError: true,
    );
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) => switch (method) {
    'GET' => _http.get(uri, headers: headers),
    'POST' => _http.post(uri, headers: headers, body: body),
    'PATCH' => _http.patch(uri, headers: headers, body: body),
    'PUT' => _http.put(uri, headers: headers, body: body),
    'DELETE' => _http.delete(uri, headers: headers, body: body),
    _ => throw ArgumentError.value(method, 'method'),
  };

  ApiResponse _decode(http.Response response, String fallbackRequestId) {
    final requestId = response.headers['x-request-id'] ?? fallbackRequestId;
    final retryAfterSeconds = int.tryParse(
      response.headers['retry-after'] ?? '',
    );
    Object? decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw ApiException(
            message: 'Server noto‘g‘ri javob qaytardi.',
            statusCode: response.statusCode,
            code: 'invalid_response',
            requestId: requestId,
          );
        }
      }
    }
    final map = decoded is Map
        ? Map<String, Object?>.from(decoded)
        : const <String, Object?>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawErrors = map['errors'] ?? map['fields'];
      throw ApiException(
        message: apiString(
          map['message'],
          fallback: _fallbackMessage(response.statusCode),
        ),
        statusCode: response.statusCode,
        code: apiString(map['code'], fallback: 'error'),
        fields: _decodeFields(rawErrors),
        requestId: requestId,
        retryAfter: retryAfterSeconds == null
            ? null
            : Duration(seconds: retryAfterSeconds),
      );
    }
    final warnings = map['warnings'] is List
        ? (map['warnings']! as List).map((value) => value.toString()).toList()
        : const <String>[];
    final isBareCursorPage =
        !map.containsKey('success') && map['results'] is List;
    return ApiResponse(
      data: isBareCursorPage
          ? map['results']
          : map.containsKey('success')
          ? map['data']
          : decoded,
      pagination: isBareCursorPage
          ? {'next': map['next'], 'previous': map['previous']}
          : map['pagination'],
      statusCode: response.statusCode,
      requestId: requestId,
      warnings: warnings,
    );
  }

  Uri _buildUri(String baseUrl, String path, Map<String, Object?> query) {
    final normalizedBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    if (query.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null && entry.value.toString().isNotEmpty)
            entry.key: entry.value.toString(),
      },
    );
  }

  Map<String, List<String>> _decodeFields(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value is List
            ? (entry.value as List).map((value) => value.toString()).toList()
            : [entry.value.toString()],
    };
  }

  Duration _retryDelay(int attempt) =>
      Duration(milliseconds: const [300, 800, 1600][attempt.clamp(0, 2)]);

  String _uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String _fallbackMessage(int status) => switch (status) {
    401 => 'Sessiya tugagan. Qayta kiring.',
    402 => 'Markaz obunasi faol emas.',
    403 => 'Bu amal uchun ruxsat yo‘q.',
    404 => 'Ma’lumot topilmadi.',
    409 =>
      'Ma’lumot boshqa joyda o‘zgargan. Yangilang va qayta urinib ko‘ring.',
    429 => 'Juda ko‘p urinish. Biroz kuting.',
    _ => 'Server xatosi yuz berdi.',
  };
}
