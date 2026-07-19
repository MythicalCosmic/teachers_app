import 'api_client.dart';
import 'api_models.dart';
import 'starforge_api.dart';

typedef BackendJson = Map<String, Object?>;

/// Small transport seam around [StarforgeApi].
///
/// The backend repositories only need JSON verbs. Keeping the seam here makes
/// contract adapters deterministic in tests without weakening the session and
/// 401 handling owned by [StarforgeApi].
abstract interface class BackendTransport {
  Future<ApiResponse> get(String path, {Map<String, Object?> query = const {}});

  Future<ApiResponse> post(String path, {Object? body, String? idempotencyKey});

  Future<ApiResponse> patch(String path, {Object? body});

  Future<ApiResponse> put(String path, {Object? body});

  Future<ApiResponse> delete(String path, {Object? body});
}

final class StarforgeBackendTransport implements BackendTransport {
  const StarforgeBackendTransport(this.api);

  final StarforgeApi api;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) => api.get(path, query: query);

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) => api.post(path, body: body, idempotencyKey: idempotencyKey);

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      api.patch(path, body: body);

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      api.put(path, body: body);

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      api.delete(path, body: body);
}

enum BackendModuleAvailability { available, unavailable }

/// Result of one independently refreshable backend module.
///
/// A 403 or scoped 404 is normal for a role-driven staff application. Those
/// responses become [unavailable] instead of aborting the entire dashboard
/// refresh. Authentication, transport and server failures still throw so the
/// owner can apply the correct global recovery policy.
final class BackendModuleResult<T> {
  const BackendModuleResult._({
    required this.availability,
    this.value,
    this.error,
    this.warnings = const [],
  });

  factory BackendModuleResult.available(
    T value, {
    List<String> warnings = const [],
  }) => BackendModuleResult._(
    availability: BackendModuleAvailability.available,
    value: value,
    warnings: List.unmodifiable(warnings),
  );

  factory BackendModuleResult.unavailable(ApiException error) =>
      BackendModuleResult._(
        availability: BackendModuleAvailability.unavailable,
        error: error,
      );

  final BackendModuleAvailability availability;
  final T? value;
  final ApiException? error;
  final List<String> warnings;

  bool get isAvailable => availability == BackendModuleAvailability.available;

  bool get isUnavailable => !isAvailable;
}

Future<BackendModuleResult<T>> backendModuleGuard<T>(
  Future<({T value, List<String> warnings})> Function() operation,
) async {
  try {
    final result = await operation();
    return BackendModuleResult.available(
      result.value,
      warnings: result.warnings,
    );
  } on ApiException catch (error) {
    if (error.statusCode == 403 || error.statusCode == 404) {
      return BackendModuleResult.unavailable(error);
    }
    rethrow;
  }
}

final class BackendPage<T> {
  const BackendPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.pages,
    required this.hasNext,
    required this.hasPrevious,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int pages;
  final bool hasNext;
  final bool hasPrevious;

  factory BackendPage.fromResponse(
    ApiResponse response,
    T Function(BackendJson json) decode,
  ) {
    final rawItems = backendMaps(response.data);
    final pagination = backendMap(response.pagination);
    return BackendPage<T>(
      items: List.unmodifiable(rawItems.map(decode)),
      page: backendInt(pagination['page'], fallback: 1),
      pageSize: backendInt(pagination['page_size'], fallback: rawItems.length),
      total: backendInt(pagination['total'], fallback: rawItems.length),
      pages: backendInt(pagination['pages'], fallback: 1),
      hasNext: backendBool(pagination['has_next']),
      hasPrevious: backendBool(pagination['has_prev']),
    );
  }
}

final class BackendCursorPage<T> {
  const BackendCursorPage({required this.items, this.next, this.previous});

  final List<T> items;
  final String? next;
  final String? previous;

  factory BackendCursorPage.fromResponse(
    ApiResponse response,
    T Function(BackendJson json) decode,
  ) {
    final pagination = backendMap(response.pagination);
    return BackendCursorPage<T>(
      items: List.unmodifiable(backendMaps(response.data).map(decode)),
      next: backendNullableString(pagination['next']),
      previous: backendNullableString(pagination['previous']),
    );
  }
}

/// Common upload-grant representation. Assignments and messaging return an S3
/// multipart POST policy while content returns a presigned PUT URL.
final class BackendUploadGrant {
  const BackendUploadGrant({
    required this.url,
    required this.method,
    required this.key,
    this.fileId,
    this.grantId,
    this.fields = const {},
    this.expiresAt,
    this.expiresIn,
  });

  final String url;
  final String method;
  final String key;
  final int? fileId;
  final String? grantId;
  final BackendJson fields;
  final DateTime? expiresAt;
  final int? expiresIn;

  factory BackendUploadGrant.fromJson(
    BackendJson json, {
    String fallbackMethod = 'POST',
  }) => BackendUploadGrant(
    url: backendString(json['url']),
    method: backendString(json['method'], fallback: fallbackMethod),
    key: backendString(json['key']),
    fileId: backendNullableInt(json['file_id']),
    grantId: backendNullableString(json['grant_id']),
    fields: backendMap(json['fields']),
    expiresAt: backendDate(json['expires_at']),
    expiresIn: backendNullableInt(json['expires_in']),
  );
}

BackendJson backendMap(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const <String, Object?>{};

List<BackendJson> backendMaps(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, Object?>.from(item),
      ]
    : const [];

List<Object?> backendList(Object? value) =>
    value is List ? List<Object?>.from(value) : const [];

List<String> backendStrings(Object? value) => value is List
    ? [
        for (final item in value)
          if (item != null) item.toString(),
      ]
    : const [];

List<int> backendInts(Object? value) {
  if (value is! List) return const [];
  final result = <int>[];
  for (final item in value) {
    final parsed = backendNullableInt(item);
    if (parsed != null) result.add(parsed);
  }
  return result;
}

String backendString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? backendNullableString(Object? value) {
  final text = backendString(value);
  return text.isEmpty ? null : text;
}

int backendInt(Object? value, {int fallback = 0}) =>
    backendNullableInt(value) ?? fallback;

int? backendNullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double backendDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool backendBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  return switch (value?.toString().trim().toLowerCase()) {
    'true' || '1' || 'yes' || 'on' => true,
    'false' || '0' || 'no' || 'off' => false,
    _ => fallback,
  };
}

DateTime? backendDate(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(backendString(value));
}

BackendJson backendQuery({
  int pageSize = 100,
  Map<String, Object?> values = const {},
}) => {
  'page_size': pageSize,
  for (final entry in values.entries)
    if (entry.value != null && backendString(entry.value).isNotEmpty)
      entry.key: entry.value,
};
