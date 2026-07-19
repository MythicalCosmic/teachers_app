import 'api_client.dart';
import 'api_models.dart';
import 'backend_core.dart';
import 'backend_models.dart';
import 'starforge_api.dart';

final class BackendAttendanceEntry {
  const BackendAttendanceEntry({
    required this.studentId,
    required this.status,
    this.arrivedAt,
    this.note = '',
  });

  final int studentId;
  final String status;
  final DateTime? arrivedAt;
  final String note;

  BackendJson toJson() => {
    'student': studentId,
    'status': status,
    if (arrivedAt != null) 'arrived_at': _iso(arrivedAt!),
    if (note.isNotEmpty) 'note': note,
  };
}

/// One active, server-configured student recognition type.
///
/// StarForge's `/cards/` domain represents physical QR/NFC access cards. The
/// teacher-facing "up card" contract is the achievements catalogue instead;
/// keeping that distinction here prevents the mobile app from issuing an
/// access credential when a teacher means to recognise classroom behaviour.
final class BackendRecognitionType {
  const BackendRecognitionType({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.scope,
    required this.status,
    this.cohortId,
  });

  final int id;
  final String name;
  final String description;
  final String emoji;
  final String scope;
  final String status;
  final int? cohortId;

  bool isVisibleForCohort(int cohortId) =>
      status == 'active' && (scope == 'global' || this.cohortId == cohortId);

  factory BackendRecognitionType.fromJson(BackendJson json) =>
      BackendRecognitionType(
        id: backendInt(json['id']),
        name: backendString(json['name']),
        description: backendString(json['description']),
        emoji: backendString(json['emoji'], fallback: '⭐'),
        scope: backendString(json['scope'], fallback: 'global'),
        status: backendString(json['status'], fallback: 'unknown'),
        cohortId: backendNullableInt(json['cohort']),
      );
}

final class BackendRecognitionReceipt {
  const BackendRecognitionReceipt({
    required this.id,
    required this.achievementId,
    required this.studentId,
    required this.note,
    this.grantedAt,
  });

  final int id;
  final int achievementId;
  final int studentId;
  final String note;
  final DateTime? grantedAt;

  factory BackendRecognitionReceipt.fromJson(BackendJson json) =>
      BackendRecognitionReceipt(
        id: backendInt(json['id']),
        achievementId: backendInt(json['achievement']),
        studentId: backendInt(json['student']),
        note: backendString(json['note']),
        grantedAt: backendDate(json['granted_at']),
      );
}

final class BackendCorrectionReceipt {
  const BackendCorrectionReceipt({
    required this.id,
    required this.studentId,
    required this.points,
    required this.reason,
    required this.status,
    this.issuedAt,
  });

  final int id;
  final int studentId;
  final int points;
  final String reason;
  final String status;
  final DateTime? issuedAt;

  factory BackendCorrectionReceipt.fromJson(BackendJson json) =>
      BackendCorrectionReceipt(
        id: backendInt(json['id']),
        studentId: backendInt(json['student']),
        points: backendInt(json['points']),
        reason: backendString(json['reason']),
        status: backendString(json['status'], fallback: 'active'),
        issuedAt: backendDate(json['issued_at']),
      );
}

/// Teacher-facing academic API surface: dashboard, calendar, cohorts and
/// attendance. All list reads use the backend's maximum supported mobile page
/// size so a refresh does not silently truncate at the default 25 rows.
final class BackendLearningApi {
  const BackendLearningApi(this.transport);

  factory BackendLearningApi.fromApi(StarforgeApi api) =>
      BackendLearningApi(StarforgeBackendTransport(api));

  final BackendTransport transport;

  Future<BackendModuleResult<BackendTeacherDashboard>> teacherDashboard() =>
      _module(
        transport.get('/api/v1/teachers/dashboard/'),
        (response) =>
            BackendTeacherDashboard.fromJson(backendMap(response.data)),
      );

  Future<BackendModuleResult<BackendPage<BackendLesson>>> lessons({
    DateTime? from,
    DateTime? to,
    int? cohortId,
    int? teacherId,
    int? roomId,
    String? status,
    int? termId,
    String ordering = 'starts_at',
  }) => _allPages(
    path: '/api/v1/schedule/lessons/',
    query: backendQuery(
      values: {
        'date_from': from == null ? null : _iso(from),
        'date_to': to == null ? null : _iso(to),
        'cohort': cohortId,
        'teacher': teacherId,
        'room': roomId,
        'status': status,
        'term': termId,
        'ordering': ordering,
      },
    ),
    decode: BackendLesson.fromJson,
    resourceName: 'Schedule',
  );

  Future<BackendModuleResult<BackendLesson>> lesson(int lessonId) => _module(
    transport.get('/api/v1/schedule/lessons/$lessonId/'),
    (response) => BackendLesson.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendLesson>> cancelLesson(
    int lessonId, {
    String reason = '',
  }) => _module(
    transport.post(
      '/api/v1/schedule/lessons/$lessonId/cancel/',
      body: {'reason': reason},
    ),
    (response) => BackendLesson.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendLesson>> moveLesson(
    int lessonId, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) => _module(
    transport.post(
      '/api/v1/schedule/lessons/$lessonId/move/',
      body: {'starts_at': _iso(startsAt), 'ends_at': _iso(endsAt)},
    ),
    (response) => BackendLesson.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<List<BackendJson>>> terms() =>
      _jsonList('/api/v1/schedule/terms/');

  Future<BackendModuleResult<List<BackendJson>>> lessonTypes() =>
      _jsonList('/api/v1/schedule/lesson-types/');

  Future<BackendModuleResult<List<BackendJson>>> timeSlots({int? branchId}) =>
      _jsonList('/api/v1/schedule/timeslots/', query: {'branch': branchId});

  Future<BackendModuleResult<List<BackendJson>>> recurrenceRules({
    int? termId,
    int? cohortId,
    int? teacherId,
    bool? active,
  }) => _jsonList(
    '/api/v1/schedule/rules/',
    query: {
      'term': termId,
      'cohort': cohortId,
      'teacher': teacherId,
      'is_active': active,
    },
  );

  Future<BackendModuleResult<int>> bulkReschedule(
    int ruleId, {
    required int shiftMinutes,
  }) => _module(
    transport.post(
      '/api/v1/schedule/rules/$ruleId/bulk-reschedule/',
      body: {'shift_minutes': shiftMinutes},
    ),
    (response) => backendInt(backendMap(response.data)['moved_count']),
  );

  Future<BackendModuleResult<String>> personalCalendarUrl() => _module(
    transport.get('/api/v1/schedule/ical-url/'),
    (response) => backendString(backendMap(response.data)['url']),
  );

  Future<BackendModuleResult<BackendPage<BackendCohort>>> cohorts({
    int? branchId,
    int? departmentId,
    bool? archived,
    String? search,
    String ordering = 'name',
  }) => _module(
    transport.get(
      '/api/v1/cohorts/',
      query: backendQuery(
        values: {
          'branch': branchId,
          'department': departmentId,
          'is_archived': archived,
          'search': search,
          'ordering': ordering,
        },
      ),
    ),
    (response) => BackendPage.fromResponse(response, BackendCohort.fromJson),
  );

  Future<BackendModuleResult<BackendCohort>> cohort(int cohortId) => _module(
    transport.get('/api/v1/cohorts/$cohortId/'),
    (response) => BackendCohort.fromJson(backendMap(response.data)),
  );

  /// This backend endpoint is deliberately unpaginated.
  Future<BackendModuleResult<List<BackendCohortMember>>> cohortMembers(
    int cohortId,
  ) => _module(
    transport.get('/api/v1/cohorts/$cohortId/members/'),
    (response) => [
      for (final item in backendMaps(response.data))
        BackendCohortMember.fromJson(item),
    ],
  );

  Future<BackendModuleResult<List<BackendCohortTeacher>>> cohortTeachers(
    int cohortId,
  ) => _module(
    transport.get('/api/v1/cohorts/$cohortId/teachers/'),
    (response) => [
      for (final item in backendMaps(response.data))
        BackendCohortTeacher.fromJson(item),
    ],
  );

  Future<BackendModuleResult<BackendPage<BackendAttendanceRecord>>>
  attendanceRecords({
    int? studentId,
    int? lessonId,
    int? cohortId,
    String? status,
    DateTime? from,
    DateTime? to,
    String ordering = '-marked_at',
  }) => _allPages(
    path: '/api/v1/attendance/records/',
    query: backendQuery(
      values: {
        'student': studentId,
        'lesson': lessonId,
        'cohort': cohortId,
        'status': status,
        'date_from': from == null ? null : _iso(from),
        'date_to': to == null ? null : _iso(to),
        'ordering': ordering,
      },
    ),
    decode: BackendAttendanceRecord.fromJson,
    resourceName: 'Attendance',
  );

  Future<BackendModuleResult<BackendAttendanceMarkResult>> markAttendance(
    int lessonId,
    List<BackendAttendanceEntry> entries,
  ) => _module(
    transport.post(
      '/api/v1/attendance/lessons/$lessonId/mark/',
      // The source contract requires a top-level array, not {entries: [...]}.
      body: [for (final entry in entries) entry.toJson()],
    ),
    (response) =>
        BackendAttendanceMarkResult.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendAttendanceDashboard>> attendanceDashboard(
    int cohortId, {
    DateTime? from,
    DateTime? to,
  }) => _module(
    transport.get(
      '/api/v1/attendance/cohorts/$cohortId/dashboard/',
      query: {
        if (from != null) 'date_from': _iso(from),
        if (to != null) 'date_to': _iso(to),
      },
    ),
    (response) =>
        BackendAttendanceDashboard.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendJson>> attendanceSummary({
    required int studentId,
    required int termId,
  }) => _module(
    transport.get(
      '/api/v1/attendance/summary/',
      query: {'student': studentId, 'term': termId},
    ),
    (response) => backendMap(response.data),
  );

  /// Active positive-recognition cards available to a teacher.
  ///
  /// We intentionally fetch the caller-scoped catalogue without a cohort
  /// query so centre-wide (`global`) cards are not accidentally filtered out.
  Future<BackendModuleResult<List<BackendRecognitionType>>> recognitionCatalog({
    required int cohortId,
  }) => _module(
    transport.get(
      '/api/v1/achievements/',
      query: backendQuery(values: const {'status': 'active'}),
    ),
    (response) => [
      for (final item in backendMaps(response.data))
        if (BackendRecognitionType.fromJson(item).isVisibleForCohort(cohortId))
          BackendRecognitionType.fromJson(item),
    ],
  );

  Future<BackendModuleResult<BackendRecognitionReceipt>> grantRecognition({
    required int achievementId,
    required int studentId,
    String note = '',
  }) => _module(
    transport.post(
      '/api/v1/achievements/$achievementId/grant/',
      body: {
        'student': studentId,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    ),
    (response) => BackendRecognitionReceipt.fromJson(backendMap(response.data)),
  );

  /// Records a negative/down classroom card through the backend's auditable
  /// student-demerit workflow. This is deliberately not a fake local card.
  Future<BackendModuleResult<BackendCorrectionReceipt>> issueCorrection({
    required int studentId,
    required int points,
    required String reason,
  }) => _module(
    transport.post(
      '/api/v1/rulebook/penalties/',
      body: {'student': studentId, 'points': points, 'reason': reason.trim()},
    ),
    (response) => BackendCorrectionReceipt.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<List<BackendJson>>> _jsonList(
    String path, {
    Map<String, Object?> query = const {},
  }) => _module(
    transport.get(path, query: backendQuery(values: query)),
    (response) => backendMaps(response.data),
  );

  /// Resolves every page of a page-number endpoint into one immutable view.
  ///
  /// Calendar months and cohort attendance periods regularly exceed the API's
  /// maximum 100-row page size. Treating the first page as complete can hide a
  /// later lesson or part of the attendance table, so period reads follow the
  /// server's `has_next` contract before exposing data to the UI.
  Future<BackendModuleResult<BackendPage<T>>> _allPages<T>({
    required String path,
    required BackendJson query,
    required T Function(BackendJson json) decode,
    required String resourceName,
  }) => backendModuleGuard(() async {
    const pageSize = 100;
    var pageNumber = 1;
    var reportedTotal = 0;
    var reportedPages = 1;
    final items = <T>[];
    final warnings = <String>[];

    while (true) {
      final response = await transport.get(
        path,
        query: {...query, 'page_size': pageSize, 'page': pageNumber},
      );
      final decoded = BackendPage.fromResponse(response, decode);
      items.addAll(decoded.items);
      warnings.addAll(response.warnings);
      reportedTotal = decoded.total;
      reportedPages = decoded.pages;
      if (!decoded.hasNext) break;
      pageNumber++;
      if (pageNumber > 1000) {
        throw ApiException(
          message: '$resourceName pagination exceeded the safe page limit.',
          code: 'pagination_limit',
        );
      }
    }

    return (
      value: BackendPage<T>(
        items: List<T>.unmodifiable(items),
        page: 1,
        pageSize: pageSize,
        total: reportedTotal < items.length ? items.length : reportedTotal,
        pages: reportedPages,
        hasNext: false,
        hasPrevious: false,
      ),
      warnings: List<String>.unmodifiable(warnings),
    );
  });

  Future<BackendModuleResult<T>> _module<T>(
    Future<ApiResponse> request,
    T Function(ApiResponse response) decode,
  ) => backendModuleGuard(() async {
    final response = await request;
    return (value: decode(response), warnings: response.warnings);
  });
}

String _iso(DateTime value) => value.toUtc().toIso8601String();
