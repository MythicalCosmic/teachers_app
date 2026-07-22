import 'api_client.dart';
import 'backend_core.dart';
import 'backend_models.dart';
import 'starforge_api.dart';

/// Tasks, chat, assignments, forms and notifications.
final class BackendWorkApi {
  const BackendWorkApi(this.transport);

  factory BackendWorkApi.fromApi(StarforgeApi api) =>
      BackendWorkApi(StarforgeBackendTransport(api));

  final BackendTransport transport;

  // Tasks -----------------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendTask>>> tasks({
    String? status,
    String? priority,
    int? assigneeId,
    int? departmentId,
    int? branchId,
    String? search,
    String ordering = '-created_at',
  }) => _page(
    '/api/v1/tasks/',
    BackendTask.fromJson,
    query: {
      'status': status,
      'priority': priority,
      'assignee': assigneeId,
      'department': departmentId,
      'branch': branchId,
      'search': search,
      'ordering': ordering,
    },
  );

  Future<BackendModuleResult<BackendPage<BackendTask>>> myTasks() =>
      _page('/api/v1/tasks/mine/', BackendTask.fromJson);

  Future<BackendModuleResult<BackendTask>> task(int taskId) => _module(
    transport.get('/api/v1/tasks/$taskId/'),
    (response) => BackendTask.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendTask>> createTask({
    required String title,
    String description = '',
    String priority = 'normal',
    int? assigneeId,
    int? departmentId,
    int? branchId,
    DateTime? dueAt,
  }) => _module(
    transport.post(
      '/api/v1/tasks/',
      body: {
        'title': title,
        'description': description,
        'priority': priority,
        'assignee': ?assigneeId,
        'department': ?departmentId,
        'branch': ?branchId,
        if (dueAt != null) 'due_at': _iso(dueAt),
      },
    ),
    (response) => BackendTask.fromJson(backendMap(response.data)),
  );

  /// [setAssignee]/[setDepartment] distinguish "leave unchanged" from an
  /// explicit JSON null used to clear an assignment.
  Future<BackendModuleResult<BackendTask>> assignTask(
    int taskId, {
    bool setAssignee = false,
    int? assigneeId,
    bool setDepartment = false,
    int? departmentId,
  }) => _module(
    transport.post(
      '/api/v1/tasks/$taskId/assign/',
      body: {
        if (setAssignee) 'assignee': assigneeId,
        if (setDepartment) 'department': departmentId,
      },
    ),
    (response) => BackendTask.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendTask>> transitionTask(
    int taskId,
    String status,
  ) => _module(
    transport.post(
      '/api/v1/tasks/$taskId/transition/',
      body: {'status': status},
    ),
    (response) => BackendTask.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendJson>> autoAssignTasks({
    required List<int> taskIds,
    required int departmentId,
    String mode = 'fair',
  }) => _module(
    transport.post(
      '/api/v1/tasks/auto-assign/',
      body: {'task_ids': taskIds, 'department': departmentId, 'mode': mode},
    ),
    (response) => backendMap(response.data),
  );

  // Messaging -------------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendThread>>> threads({
    String ordering = '-last_message_at',
  }) => _page(
    '/api/v1/messaging/threads/',
    BackendThread.fromJson,
    query: {'ordering': ordering},
  );

  Future<BackendModuleResult<BackendThread>> createThread({
    required List<int> participantIds,
    String subject = '',
    String firstBody = '',
    List<String> attachments = const [],
  }) => _module(
    transport.post(
      '/api/v1/messaging/threads/',
      body: {
        'participant_ids': participantIds,
        if (subject.isNotEmpty) 'subject': subject,
        if (firstBody.isNotEmpty) 'first_body': firstBody,
        if (attachments.isNotEmpty) 'attachments': attachments,
      },
    ),
    (response) => BackendThread.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendThread>> thread(int threadId) => _module(
    transport.get('/api/v1/messaging/threads/$threadId/'),
    (response) => BackendThread.fromJson(backendMap(response.data)),
  );

  /// Server ordering is ascending/oldest-first. Callers should request later
  /// pages when rendering the most recent history.
  Future<BackendModuleResult<BackendPage<BackendMessage>>> messages(
    int threadId, {
    int page = 1,
    int? pageSize,
    DateTime? createdAtGte,
    DateTime? createdAtLt,
  }) {
    if ((createdAtGte == null) != (createdAtLt == null)) {
      throw ArgumentError(
        'createdAtGte and createdAtLt must be provided together.',
      );
    }
    if (pageSize != null && (pageSize < 1 || pageSize > 100)) {
      throw ArgumentError.value(pageSize, 'pageSize', 'Must be from 1 to 100.');
    }
    return _page(
      '/api/v1/messaging/threads/$threadId/messages/',
      BackendMessage.fromJson,
      query: {
        'page': page,
        'page_size': ?pageSize,
        'created_at_gte': ?createdAtGte?.toUtc().toIso8601String(),
        'created_at_lt': ?createdAtLt?.toUtc().toIso8601String(),
      },
    );
  }

  Future<BackendModuleResult<BackendMessage>> sendMessage(
    int threadId, {
    String body = '',
    List<String> attachments = const [],
  }) => _module(
    transport.post(
      '/api/v1/messaging/threads/$threadId/messages/',
      body: {
        if (body.isNotEmpty) 'body': body,
        if (attachments.isNotEmpty) 'attachments': attachments,
      },
    ),
    (response) => BackendMessage.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<bool>> markThreadRead(int threadId) => _module(
    transport.post('/api/v1/messaging/threads/$threadId/read/'),
    (response) => backendString(backendMap(response.data)['status']) == 'ok',
  );

  Future<BackendModuleResult<bool>> setThreadNotificationsMuted(
    int threadId, {
    required bool muted,
  }) => _module(
    transport.patch(
      '/api/v1/messaging/threads/$threadId/preferences/',
      body: {'notifications_muted': muted},
    ),
    (response) => backendBool(backendMap(response.data)['notifications_muted']),
  );

  Future<BackendModuleResult<BackendUploadGrant>> messageUploadGrant({
    required String filename,
    required int sizeBytes,
    String contentType = 'application/octet-stream',
  }) => _module(
    transport.post(
      '/api/v1/messaging/attachments/upload-url/',
      body: {
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      },
    ),
    (response) => BackendUploadGrant.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<String>> messageAttachmentDownloadUrl(
    int threadId,
    String key,
  ) => _module(
    transport.get(
      '/api/v1/messaging/threads/$threadId/attachments/download/',
      query: {'key': key},
    ),
    (response) => backendString(backendMap(response.data)['url']),
  );

  // Assignments -----------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendAssignment>>> assignments({
    int? cohortId,
    String? status,
    String ordering = '-due_at',
  }) => _page(
    '/api/v1/assignments/',
    BackendAssignment.fromJson,
    query: {'cohort': cohortId, 'status': status, 'ordering': ordering},
  );

  Future<BackendModuleResult<BackendAssignment>> assignment(int assignmentId) =>
      _module(
        transport.get('/api/v1/assignments/$assignmentId/'),
        (response) => BackendAssignment.fromJson(backendMap(response.data)),
      );

  Future<BackendModuleResult<BackendAssignment>> createAssignment({
    required int cohortId,
    required String title,
    required DateTime dueAt,
    String description = '',
    List<Object?> attachments = const [],
    Object? rubric = const [],
    String? maxScore,
    int? maxResubmits,
  }) => _module(
    transport.post(
      '/api/v1/assignments/',
      body: {
        'cohort': cohortId,
        'title': title,
        'due_at': _iso(dueAt),
        'description': description,
        'attachments': attachments,
        'rubric': rubric,
        'max_score': ?maxScore,
        'max_resubmits': ?maxResubmits,
      },
    ),
    (response) => BackendAssignment.fromJson(backendMap(response.data)),
  );

  /// Uses an explicit changes map because PATCH needs to preserve the semantic
  /// difference between omitted fields and an intentional JSON null.
  Future<BackendModuleResult<BackendAssignment>> updateAssignment(
    int assignmentId,
    BackendJson changes, {
    bool replace = false,
  }) => _module(
    replace
        ? transport.put('/api/v1/assignments/$assignmentId/', body: changes)
        : transport.patch('/api/v1/assignments/$assignmentId/', body: changes),
    (response) => BackendAssignment.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<bool>> deleteAssignment(int assignmentId) =>
      _module(
        transport.delete('/api/v1/assignments/$assignmentId/'),
        (response) => response.statusCode == 204,
      );

  Future<BackendModuleResult<BackendAssignment>> publishAssignment(
    int assignmentId,
  ) => _assignmentAction(assignmentId, 'publish');

  Future<BackendModuleResult<BackendAssignment>> closeAssignment(
    int assignmentId,
  ) => _assignmentAction(assignmentId, 'close');

  Future<BackendModuleResult<BackendPage<BackendSubmission>>>
  assignmentSubmissions(int assignmentId, {int page = 1}) => _page(
    '/api/v1/assignments/$assignmentId/submissions/',
    BackendSubmission.fromJson,
    query: {'page': page},
  );

  Future<BackendModuleResult<BackendPage<BackendSubmission>>> submissions({
    int page = 1,
  }) => _page(
    '/api/v1/assignments/submissions/',
    BackendSubmission.fromJson,
    query: {'page': page},
  );

  Future<BackendModuleResult<BackendSubmission>> submission(int submissionId) =>
      _module(
        transport.get('/api/v1/assignments/submissions/$submissionId/'),
        (response) => BackendSubmission.fromJson(backendMap(response.data)),
      );

  Future<BackendModuleResult<BackendSubmissionGrade>> gradeSubmission(
    int submissionId, {
    required String score,
    List<BackendJson> rubricScores = const [],
    String feedback = '',
  }) => _module(
    transport.post(
      '/api/v1/assignments/submissions/$submissionId/grade/',
      body: {
        'score': score,
        'rubric_scores': rubricScores,
        'feedback': feedback,
      },
    ),
    (response) => BackendSubmissionGrade.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendSubmission>> returnSubmission(
    int submissionId,
  ) => _module(
    transport.post('/api/v1/assignments/submissions/$submissionId/return/'),
    (response) => BackendSubmission.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendJson>> checkPlagiarism(int submissionId) =>
      _module(
        transport.post(
          '/api/v1/assignments/submissions/$submissionId/plagiarism/',
        ),
        (response) => backendMap(response.data),
      );

  Future<BackendModuleResult<String>> requestSubmissionAiFeedback(
    int submissionId,
  ) => _module(
    transport.post(
      '/api/v1/assignments/submissions/$submissionId/request-ai-feedback/',
    ),
    (response) => backendString(backendMap(response.data)['status']),
  );

  Future<BackendModuleResult<BackendUploadGrant>> assignmentUploadGrant({
    required String filename,
    required int sizeBytes,
    String contentType = 'application/octet-stream',
  }) => _module(
    transport.post(
      '/api/v1/assignments/upload-url/',
      body: {
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      },
    ),
    (response) => BackendUploadGrant.fromJson(backendMap(response.data)),
  );

  // Forms -----------------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendForm>>> forms({
    String? status,
    int? branchId,
    bool? anonymous,
    String? search,
    String ordering = '-created_at',
  }) => _page(
    '/api/v1/forms/',
    BackendForm.fromJson,
    query: {
      'status': status,
      'branch': branchId,
      'is_anonymous': anonymous,
      'search': search,
      'ordering': ordering,
    },
  );

  Future<BackendModuleResult<BackendForm>> form(int formId) => _module(
    transport.get('/api/v1/forms/$formId/'),
    (response) => BackendForm.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendForm>> createForm({
    required String title,
    String description = '',
    bool isAnonymous = false,
    bool allowMultiple = false,
    int? branchId,
    DateTime? opensAt,
    DateTime? closesAt,
    List<String> audienceRoles = const [],
    List<int> audienceUserIds = const [],
  }) => _module(
    transport.post(
      '/api/v1/forms/',
      body: {
        'title': title,
        'description': description,
        'is_anonymous': isAnonymous,
        'allow_multiple': allowMultiple,
        'branch': ?branchId,
        if (opensAt != null) 'opens_at': _iso(opensAt),
        if (closesAt != null) 'closes_at': _iso(closesAt),
        'audience_roles': audienceRoles,
        'audience_user_ids': audienceUserIds,
      },
    ),
    (response) => BackendForm.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendForm>> updateForm(
    int formId,
    BackendJson changes, {
    bool replace = false,
  }) => _module(
    replace
        ? transport.put('/api/v1/forms/$formId/', body: changes)
        : transport.patch('/api/v1/forms/$formId/', body: changes),
    (response) => BackendForm.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendFormField>> addFormField(
    int formId, {
    required String label,
    required String fieldType,
    bool required = false,
    int? order,
    List<Object?> options = const [],
    String helpText = '',
  }) => _module(
    transport.post(
      '/api/v1/forms/$formId/fields/',
      body: {
        'label': label,
        'field_type': fieldType,
        'required': required,
        'order': ?order,
        'options': options,
        'help_text': helpText,
      },
    ),
    (response) => BackendFormField.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendForm>> publishForm(int formId) =>
      _formAction(formId, 'publish');

  Future<BackendModuleResult<BackendForm>> closeForm(int formId) =>
      _formAction(formId, 'close');

  Future<BackendModuleResult<BackendJson>> submitForm(
    int formId,
    List<BackendJson> answers,
  ) => _module(
    transport.post('/api/v1/forms/$formId/submit/', body: {'answers': answers}),
    (response) => backendMap(response.data),
  );

  Future<BackendModuleResult<BackendPage<BackendFormResponse>>> formResponses(
    int formId,
  ) => _page('/api/v1/forms/$formId/responses/', BackendFormResponse.fromJson);

  Future<BackendModuleResult<BackendJson>> formSummary(int formId) => _module(
    transport.get('/api/v1/forms/$formId/summary/'),
    (response) => backendMap(response.data),
  );

  Future<BackendModuleResult<BackendQueuedRequest>> analyzeForm(int formId) =>
      _module(
        transport.post('/api/v1/forms/$formId/analyze/'),
        (response) => BackendQueuedRequest.fromJson(backendMap(response.data)),
      );

  // Notifications ---------------------------------------------------------

  Future<BackendModuleResult<BackendCursorPage<BackendNotification>>>
  notifications({String? eventType, String? readAt, String? cursor}) => _module(
    transport.get(
      '/api/v1/notifications/',
      query: backendQuery(
        values: {'event_type': eventType, 'read_at': readAt, 'cursor': cursor},
      ),
    ),
    (response) =>
        BackendCursorPage.fromResponse(response, BackendNotification.fromJson),
  );

  Future<BackendModuleResult<int>> unreadNotificationCount() => _module(
    transport.get('/api/v1/notifications/unread-count/'),
    (response) => backendInt(backendMap(response.data)['count']),
  );

  Future<BackendModuleResult<bool>> markNotificationRead(int notificationId) =>
      _module(
        transport.post('/api/v1/notifications/$notificationId/read/'),
        (response) => backendBool(backendMap(response.data)['read']),
      );

  Future<BackendModuleResult<int>> markAllNotificationsRead() => _module(
    transport.post('/api/v1/notifications/read-all/'),
    (response) => backendInt(backendMap(response.data)['updated']),
  );

  Future<BackendModuleResult<List<BackendNotificationPreference>>>
  notificationPreferences() => _module(
    transport.get('/api/v1/notifications/preferences/'),
    (response) => [
      for (final item in backendMaps(response.data))
        BackendNotificationPreference.fromJson(item),
    ],
  );

  Future<BackendModuleResult<List<BackendNotificationPreference>>>
  updateNotificationPreferences(
    List<BackendNotificationPreference> preferences,
  ) => _module(
    transport.put(
      '/api/v1/notifications/preferences/',
      body: {
        'preferences': [for (final item in preferences) item.toJson()],
      },
    ),
    (response) => [
      for (final item in backendMaps(response.data))
        BackendNotificationPreference.fromJson(item),
    ],
  );

  // Helpers ---------------------------------------------------------------

  Future<BackendModuleResult<BackendAssignment>> _assignmentAction(
    int assignmentId,
    String action,
  ) => _module(
    transport.post('/api/v1/assignments/$assignmentId/$action/'),
    (response) => BackendAssignment.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendForm>> _formAction(
    int formId,
    String action,
  ) => _module(
    transport.post('/api/v1/forms/$formId/$action/'),
    (response) => BackendForm.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPage<T>>> _page<T>(
    String path,
    T Function(BackendJson json) decode, {
    Map<String, Object?> query = const {},
  }) => _module(
    transport.get(path, query: backendQuery(values: query)),
    (response) => BackendPage.fromResponse(response, decode),
  );

  Future<BackendModuleResult<T>> _module<T>(
    Future<ApiResponse> request,
    T Function(ApiResponse response) decode,
  ) => backendModuleGuard(() async {
    final response = await request;
    return (value: decode(response), warnings: response.warnings);
  });
}

String _iso(DateTime value) => value.toUtc().toIso8601String();
