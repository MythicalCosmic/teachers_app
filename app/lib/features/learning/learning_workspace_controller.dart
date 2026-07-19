import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/app_state.dart';
import '../../data/api/api_models.dart';
import '../../data/api/backend_core.dart';
import '../../data/api/backend_learning_api.dart';
import '../../data/api/backend_models.dart';

enum LearningLoadPhase {
  idle,
  waitingForSession,
  loading,
  ready,
  unavailable,
  failure,
}

@immutable
class LearningResource<T> {
  const LearningResource._({
    required this.phase,
    this.value,
    this.message,
    this.statusCode,
  });

  const LearningResource.idle() : this._(phase: LearningLoadPhase.idle);

  const LearningResource.waiting()
    : this._(phase: LearningLoadPhase.waitingForSession);

  const LearningResource.loading([T? previous])
    : this._(phase: LearningLoadPhase.loading, value: previous);

  const LearningResource.ready(T value)
    : this._(phase: LearningLoadPhase.ready, value: value);

  const LearningResource.unavailable({String? message, int? statusCode})
    : this._(
        phase: LearningLoadPhase.unavailable,
        message: message,
        statusCode: statusCode,
      );

  const LearningResource.failure(String message, {int? statusCode})
    : this._(
        phase: LearningLoadPhase.failure,
        message: message,
        statusCode: statusCode,
      );

  final LearningLoadPhase phase;
  final T? value;
  final String? message;
  final int? statusCode;

  bool get hasValue => value != null;
  bool get isLoading =>
      phase == LearningLoadPhase.loading ||
      phase == LearningLoadPhase.waitingForSession;
  bool get isUnavailable => phase == LearningLoadPhase.unavailable;
  bool get isFailure => phase == LearningLoadPhase.failure;
}

@immutable
class LearningRange {
  const LearningRange(this.from, this.to);

  final DateTime from;
  final DateTime to;

  String get key =>
      '${from.toUtc().toIso8601String()}|${to.toUtc().toIso8601String()}';
}

@immutable
class CohortLearningState {
  const CohortLearningState({
    this.cohort = const LearningResource.idle(),
    this.members = const LearningResource.idle(),
    this.lessons = const LearningResource.idle(),
    this.attendance = const LearningResource.idle(),
    this.history = const LearningResource.idle(),
    this.range,
  });

  final LearningResource<BackendCohort> cohort;
  final LearningResource<List<BackendCohortMember>> members;
  final LearningResource<List<BackendLesson>> lessons;
  final LearningResource<BackendAttendanceDashboard> attendance;
  final LearningResource<List<BackendAttendanceRecord>> history;
  final LearningRange? range;

  CohortLearningState copyWith({
    LearningResource<BackendCohort>? cohort,
    LearningResource<List<BackendCohortMember>>? members,
    LearningResource<List<BackendLesson>>? lessons,
    LearningResource<BackendAttendanceDashboard>? attendance,
    LearningResource<List<BackendAttendanceRecord>>? history,
    LearningRange? range,
  }) => CohortLearningState(
    cohort: cohort ?? this.cohort,
    members: members ?? this.members,
    lessons: lessons ?? this.lessons,
    attendance: attendance ?? this.attendance,
    history: history ?? this.history,
    range: range ?? this.range,
  );
}

final class LearningModuleUnavailableException implements Exception {
  const LearningModuleUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One session-scoped source of truth for teacher learning data.
///
/// The controller never imports demo models. Production screens therefore
/// cannot accidentally combine local seed data with server data. Reads started
/// during secure-session restoration wait for AppState to finish restoring.
final class LearningWorkspaceController extends ChangeNotifier {
  LearningWorkspaceController(this._app, this._repository) {
    _app.addListener(_handleAppState);
    _sessionKey = _currentSessionKey;
  }

  final AppState _app;
  final BackendLearningApi _repository;

  LearningResource<BackendTeacherDashboard> _dashboard =
      const LearningResource.idle();
  LearningResource<List<BackendCohort>> _cohorts =
      const LearningResource.idle();
  final Map<int, LearningResource<List<BackendRecognitionType>>>
  _recognitionCatalogs = {};
  final Map<String, LearningResource<List<BackendLesson>>> _lessonRanges = {};
  final Map<int, LearningResource<BackendLesson>> _lessonDetails = {};
  final Map<int, LearningResource<List<BackendAttendanceRecord>>>
  _lessonAttendance = {};
  final Map<int, CohortLearningState> _cohortStates = {};
  final Map<int, BackendLesson> _lessonsById = {};

  int _dashboardRequest = 0;
  int _cohortListRequest = 0;
  int _sessionGeneration = 0;
  final Map<String, int> _lessonRangeRequests = {};
  final Map<int, int> _lessonDetailRequests = {};
  final Map<int, int> _lessonAttendanceRequests = {};
  final Map<int, int> _cohortRequests = {};
  final Map<int, int> _recognitionRequests = {};
  int? _activeRecognitionCohortId;
  String? _sessionKey;
  bool _disposed = false;

  LearningResource<BackendTeacherDashboard> get dashboard => _dashboard;
  LearningResource<List<BackendCohort>> get cohorts => _cohorts;
  LearningResource<List<BackendRecognitionType>> get recognitionCatalog {
    final cohortId = _activeRecognitionCohortId;
    if (cohortId == null) return const LearningResource.idle();
    return recognitionCatalogFor(cohortId);
  }

  LearningResource<List<BackendRecognitionType>> recognitionCatalogFor(
    int cohortId,
  ) => _recognitionCatalogs[cohortId] ?? const LearningResource.idle();
  bool get waitingForSession => !_canRead;

  LearningResource<List<BackendLesson>> lessons(LearningRange range) =>
      _lessonRanges['${range.key}|all'] ?? const LearningResource.idle();

  LearningResource<BackendLesson> lesson(int lessonId) {
    final detail = _lessonDetails[lessonId];
    if (detail != null) return detail;
    final cached = _lessonsById[lessonId];
    return cached == null
        ? const LearningResource.idle()
        : LearningResource.ready(cached);
  }

  LearningResource<List<BackendAttendanceRecord>> attendanceForLesson(
    int lessonId,
  ) => _lessonAttendance[lessonId] ?? const LearningResource.idle();

  CohortLearningState cohortState(int cohortId) =>
      _cohortStates[cohortId] ?? const CohortLearningState();

  Future<void> refreshToday(DateTime date, {bool force = true}) async {
    final range = dayRange(date);
    await Future.wait([
      loadDashboard(force: force),
      loadLessons(range, force: force),
    ]);
  }

  Future<void> loadDashboard({bool force = false}) async {
    if (!force && _dashboard.value != null) return;
    final generation = _sessionGeneration;
    final request = ++_dashboardRequest;
    _dashboard = _canRead
        ? LearningResource.loading(_dashboard.value)
        : const LearningResource.waiting();
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _dashboardRequest) {
      return;
    }
    _dashboard = LearningResource.loading(_dashboard.value);
    _notify();
    final resolved = await _resolve(_repository.teacherDashboard());
    if (generation != _sessionGeneration || request != _dashboardRequest) {
      return;
    }
    _dashboard = resolved;
    _notify();
  }

  Future<void> loadLessons(
    LearningRange range, {
    bool force = false,
    int? cohortId,
  }) async {
    final key = '${range.key}|${cohortId ?? 'all'}';
    final existing = _lessonRanges[key] ?? const LearningResource.idle();
    if (!force && existing.value != null) return;
    final generation = _sessionGeneration;
    final request = (_lessonRangeRequests[key] ?? 0) + 1;
    _lessonRangeRequests[key] = request;
    _lessonRanges[key] = _canRead
        ? LearningResource.loading(existing.value)
        : const LearningResource.waiting();
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _lessonRangeRequests[key]) {
      return;
    }
    final resolved = await _resolve(
      _repository.lessons(from: range.from, to: range.to, cohortId: cohortId),
    );
    if (generation != _sessionGeneration ||
        request != _lessonRangeRequests[key]) {
      return;
    }
    final mapped = resolved.map((page) => page.items);
    _lessonRanges[key] = mapped;
    for (final lesson in mapped.value ?? const <BackendLesson>[]) {
      _lessonsById[lesson.id] = lesson;
    }
    _notify();
  }

  LearningResource<List<BackendLesson>> cohortLessons(
    LearningRange range,
    int cohortId,
  ) => _lessonRanges['${range.key}|$cohortId'] ?? const LearningResource.idle();

  Future<void> loadCohorts({
    String search = '',
    bool? archived = false,
    String ordering = 'name',
    bool force = false,
  }) async {
    if (!force &&
        _cohorts.value != null &&
        search.trim().isEmpty &&
        archived == false) {
      return;
    }
    final generation = _sessionGeneration;
    final request = ++_cohortListRequest;
    _cohorts = _canRead
        ? LearningResource.loading(_cohorts.value)
        : const LearningResource.waiting();
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _cohortListRequest) {
      return;
    }
    final resolved = await _resolve(
      _repository.cohorts(
        archived: archived,
        search: search.trim().isEmpty ? null : search.trim(),
        ordering: ordering,
      ),
    );
    if (generation != _sessionGeneration || request != _cohortListRequest) {
      return;
    }
    _cohorts = resolved.map((page) => page.items);
    _notify();
  }

  Future<void> loadRecognitionCatalog({
    required int cohortId,
    bool force = false,
  }) async {
    _activeRecognitionCohortId = cohortId;
    final previous = recognitionCatalogFor(cohortId);
    if (!force && previous.value != null) {
      _notify();
      return;
    }
    final generation = _sessionGeneration;
    final request = (_recognitionRequests[cohortId] ?? 0) + 1;
    _recognitionRequests[cohortId] = request;
    _recognitionCatalogs[cohortId] = _canRead
        ? LearningResource.loading(previous.value)
        : const LearningResource.waiting();
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _recognitionRequests[cohortId]) {
      return;
    }
    final resolved = await _resolve(
      _repository.recognitionCatalog(cohortId: cohortId),
    );
    if (generation != _sessionGeneration ||
        request != _recognitionRequests[cohortId]) {
      return;
    }
    _recognitionCatalogs[cohortId] = resolved;
    _notify();
  }

  Future<void> loadCohort(
    int cohortId, {
    required LearningRange range,
    bool force = false,
  }) async {
    final previous = cohortState(cohortId);
    if (!force &&
        previous.cohort.value != null &&
        previous.members.value != null &&
        previous.range?.key == range.key) {
      return;
    }
    final generation = _sessionGeneration;
    final request = (_cohortRequests[cohortId] ?? 0) + 1;
    _cohortRequests[cohortId] = request;
    _cohortStates[cohortId] = previous.copyWith(
      cohort: _waitingOrLoading(previous.cohort),
      members: _waitingOrLoading(previous.members),
      lessons: _waitingOrLoading(previous.lessons),
      attendance: _waitingOrLoading(previous.attendance),
      history: _waitingOrLoading(previous.history),
      range: range,
    );
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _cohortRequests[cohortId]) {
      return;
    }

    // Attendance analytics obey the user's exact range, while the group
    // schedule also needs enough future runway to render a truthful "next
    // lesson" card. Extending only the schedule read avoids polluting history
    // or percentage calculations with a hidden date range.
    final upcomingBoundary = DateTime.now().add(const Duration(days: 90));
    final scheduleTo = range.to.isAfter(upcomingBoundary)
        ? range.to
        : upcomingBoundary;

    final results = await Future.wait<Object>([
      _resolve(_repository.cohort(cohortId)),
      _resolve(_repository.cohortMembers(cohortId)),
      _resolve(
        _repository.lessons(
          cohortId: cohortId,
          from: range.from,
          to: scheduleTo,
        ),
      ),
      _resolve(
        _repository.attendanceDashboard(
          cohortId,
          from: range.from,
          to: range.to,
        ),
      ),
      _resolve(
        _repository.attendanceRecords(
          cohortId: cohortId,
          from: range.from,
          to: range.to,
        ),
      ),
    ]);
    if (generation != _sessionGeneration ||
        request != _cohortRequests[cohortId]) {
      return;
    }
    final cohort = results[0] as LearningResource<BackendCohort>;
    final members = results[1] as LearningResource<List<BackendCohortMember>>;
    final lessonsPage =
        results[2] as LearningResource<BackendPage<BackendLesson>>;
    final attendance =
        results[3] as LearningResource<BackendAttendanceDashboard>;
    final historyPage =
        results[4] as LearningResource<BackendPage<BackendAttendanceRecord>>;
    final lessons = lessonsPage.map((page) => page.items);
    final history = historyPage.map((page) => page.items);
    for (final lesson in lessons.value ?? const <BackendLesson>[]) {
      _lessonsById[lesson.id] = lesson;
    }
    _cohortStates[cohortId] = CohortLearningState(
      cohort: cohort,
      members: members,
      lessons: lessons,
      attendance: attendance,
      history: history,
      range: range,
    );
    _notify();
  }

  Future<void> loadLesson(int lessonId, {bool force = false}) async {
    final previous = lesson(lessonId);
    if (!force && previous.value != null) return;
    final generation = _sessionGeneration;
    final request = (_lessonDetailRequests[lessonId] ?? 0) + 1;
    _lessonDetailRequests[lessonId] = request;
    _lessonDetails[lessonId] = _waitingOrLoading(previous);
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _lessonDetailRequests[lessonId]) {
      return;
    }
    final resolved = await _resolve(_repository.lesson(lessonId));
    if (generation != _sessionGeneration ||
        request != _lessonDetailRequests[lessonId]) {
      return;
    }
    _lessonDetails[lessonId] = resolved;
    if (resolved.value case final lesson?) _lessonsById[lesson.id] = lesson;
    _notify();
  }

  Future<void> loadLessonAttendance(int lessonId, {bool force = false}) async {
    final previous = attendanceForLesson(lessonId);
    if (!force && previous.value != null) return;
    final generation = _sessionGeneration;
    final request = (_lessonAttendanceRequests[lessonId] ?? 0) + 1;
    _lessonAttendanceRequests[lessonId] = request;
    _lessonAttendance[lessonId] = _waitingOrLoading(previous);
    _notify();
    if (!await _waitUntilReadable() ||
        generation != _sessionGeneration ||
        request != _lessonAttendanceRequests[lessonId]) {
      return;
    }
    final resolved = await _resolve(
      _repository.attendanceRecords(lessonId: lessonId),
    );
    if (generation != _sessionGeneration ||
        request != _lessonAttendanceRequests[lessonId]) {
      return;
    }
    _lessonAttendance[lessonId] = resolved.map((page) => page.items);
    _notify();
  }

  Future<BackendAttendanceMarkResult> markAttendance(
    int lessonId,
    List<BackendAttendanceEntry> entries, {
    int? cohortId,
    LearningRange? refreshRange,
  }) async {
    if (!await _waitUntilReadable()) {
      throw const ApiException(
        message: 'Secure staff session is not ready.',
        code: 'session_not_ready',
      );
    }
    final generation = _sessionGeneration;
    final result = await _repository.markAttendance(lessonId, entries);
    if (result.isUnavailable || result.value == null) {
      throw LearningModuleUnavailableException(
        result.error?.message ?? 'Attendance is unavailable for this account.',
      );
    }
    if (generation != _sessionGeneration) return result.value!;
    _lessonAttendance[lessonId] = LearningResource.ready(result.value!.records);
    _notify();
    if (cohortId != null && refreshRange != null) {
      unawaited(loadCohort(cohortId, range: refreshRange, force: true));
    }
    return result.value!;
  }

  Future<BackendRecognitionReceipt> grantRecognition({
    required int achievementId,
    required int studentId,
    String note = '',
  }) async {
    if (!await _waitUntilReadable()) {
      throw const ApiException(
        message: 'Secure staff session is not ready.',
        code: 'session_not_ready',
      );
    }
    final result = await _repository.grantRecognition(
      achievementId: achievementId,
      studentId: studentId,
      note: note,
    );
    if (result.isUnavailable || result.value == null) {
      throw LearningModuleUnavailableException(
        result.error?.message ??
            'Student recognition is unavailable for this account.',
      );
    }
    return result.value!;
  }

  Future<BackendCorrectionReceipt> issueCorrection({
    required int studentId,
    required int points,
    required String reason,
  }) async {
    if (!await _waitUntilReadable()) {
      throw const ApiException(
        message: 'Secure staff session is not ready.',
        code: 'session_not_ready',
      );
    }
    final result = await _repository.issueCorrection(
      studentId: studentId,
      points: points,
      reason: reason,
    );
    if (result.isUnavailable || result.value == null) {
      throw LearningModuleUnavailableException(
        result.error?.message ??
            'Student corrections are unavailable for this account.',
      );
    }
    return result.value!;
  }

  Future<LearningResource<T>> _resolve<T>(
    Future<BackendModuleResult<T>> operation,
  ) async {
    try {
      final result = await operation;
      if (result.isUnavailable || result.value == null) {
        return LearningResource.unavailable(
          message: result.error?.message,
          statusCode: result.error?.statusCode,
        );
      }
      return LearningResource.ready(result.value as T);
    } on ApiException catch (error) {
      return LearningResource.failure(
        error.message,
        statusCode: error.statusCode,
      );
    } on Object {
      return const LearningResource.failure(
        'The server response could not be prepared for this screen.',
      );
    }
  }

  LearningResource<T> _waitingOrLoading<T>(LearningResource<T> previous) =>
      _canRead
      ? LearningResource.loading(previous.value)
      : const LearningResource.waiting();

  bool get _canRead =>
      _app.isInitialized &&
      _app.session != null &&
      _app.backendApi?.connection != null;

  String? get _currentSessionKey {
    final session = _app.session;
    final connection = _app.backendApi?.connection;
    if (session == null || connection == null) return null;
    return '${session.userId}|${connection.baseUrl}';
  }

  Future<bool> _waitUntilReadable() async {
    if (_canRead) return true;
    if (_app.isInitialized && _app.session == null) return false;
    final ready = Completer<bool>();
    void listener() {
      if (_canRead && !ready.isCompleted) ready.complete(true);
      if (_app.isInitialized && _app.session == null && !ready.isCompleted) {
        ready.complete(false);
      }
    }

    _app.addListener(listener);
    listener();
    final result = await ready.future;
    _app.removeListener(listener);
    return result;
  }

  void _handleAppState() {
    final nextSessionKey = _currentSessionKey;
    if (_sessionKey != nextSessionKey) {
      final hadSession = _sessionKey != null;
      _sessionKey = nextSessionKey;
      if (hadSession) _clearServerState();
    }
    _notify();
  }

  void _clearServerState() {
    _sessionGeneration++;
    _dashboard = const LearningResource.idle();
    _cohorts = const LearningResource.idle();
    _recognitionCatalogs.clear();
    _activeRecognitionCohortId = null;
    _lessonRanges.clear();
    _lessonDetails.clear();
    _lessonAttendance.clear();
    _cohortStates.clear();
    _lessonsById.clear();
    _dashboardRequest++;
    _cohortListRequest++;
    _recognitionRequests.clear();
    _lessonRangeRequests.clear();
    _lessonDetailRequests.clear();
    _lessonAttendanceRequests.clear();
    _cohortRequests.clear();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _app.removeListener(_handleAppState);
    super.dispose();
  }

  static LearningRange dayRange(DateTime date) => LearningRange(
    DateTime(date.year, date.month, date.day),
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
  );

  static LearningRange weekRange(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    return LearningRange(
      start,
      start
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1)),
    );
  }

  static LearningRange monthRange(DateTime date) {
    final start = DateTime(date.year, date.month);
    final end = DateTime(
      date.year,
      date.month + 1,
    ).subtract(const Duration(milliseconds: 1));
    return LearningRange(start, end);
  }
}

extension LearningResourceMap<T> on LearningResource<T> {
  LearningResource<R> map<R>(R Function(T value) convert) {
    final current = value;
    return switch (phase) {
      LearningLoadPhase.idle => const LearningResource.idle(),
      LearningLoadPhase.waitingForSession => const LearningResource.waiting(),
      LearningLoadPhase.loading => LearningResource.loading(
        current == null ? null : convert(current),
      ),
      LearningLoadPhase.ready => LearningResource.ready(convert(current as T)),
      LearningLoadPhase.unavailable => LearningResource.unavailable(
        message: message,
        statusCode: statusCode,
      ),
      LearningLoadPhase.failure => LearningResource.failure(
        message ?? 'Request failed.',
        statusCode: statusCode,
      ),
    };
  }
}

final Expando<LearningWorkspaceController> _learningControllers = Expando(
  'starforge.learning.workspace',
);

LearningWorkspaceController? learningWorkspaceFor(AppState app) {
  final backendApi = app.backendApi;
  if (backendApi == null) return null;
  return _learningControllers[app] ??= LearningWorkspaceController(
    app,
    BackendLearningApi.fromApi(backendApi),
  );
}
