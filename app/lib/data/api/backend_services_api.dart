import 'api_client.dart';
import 'backend_core.dart';
import 'backend_models.dart';
import 'starforge_api.dart';

/// Content library, print queue, asynchronous AI jobs and the immutable audit
/// timeline. Each method is independently availability-aware.
final class BackendServicesApi {
  const BackendServicesApi(this.transport);

  factory BackendServicesApi.fromApi(StarforgeApi api) =>
      BackendServicesApi(StarforgeBackendTransport(api));

  final BackendTransport transport;

  // Content ---------------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendContentLibrary>>>
  contentLibraries({
    int page = 1,
    String? visibility,
    int? departmentId,
    int? cohortId,
    bool? active,
    String? search,
  }) => _page(
    '/api/v1/content/libraries/',
    BackendContentLibrary.fromJson,
    query: {
      'page': page,
      'visibility': visibility,
      'department': departmentId,
      'cohort': cohortId,
      'is_active': active,
      'search': search,
    },
  );

  Future<BackendModuleResult<BackendContentLibrary>> createContentLibrary({
    required String name,
    String description = '',
    String visibility = 'tenant',
    int? departmentId,
    int? cohortId,
    List<String> allowedRoles = const [],
    bool active = true,
  }) => _module(
    transport.post(
      '/api/v1/content/libraries/',
      body: {
        'name': name,
        'description': description,
        'visibility': visibility,
        'department': departmentId,
        'cohort': cohortId,
        'allowed_roles': allowedRoles,
        'is_active': active,
      },
    ),
    (response) => BackendContentLibrary.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendContentLibrary>> updateContentLibrary(
    int libraryId,
    BackendJson changes, {
    bool replace = false,
  }) => _module(
    replace
        ? transport.put('/api/v1/content/libraries/$libraryId/', body: changes)
        : transport.patch(
            '/api/v1/content/libraries/$libraryId/',
            body: changes,
          ),
    (response) => BackendContentLibrary.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPage<BackendContentNode>>> contentCourses({
    int page = 1,
    int? libraryId,
    int? subjectId,
    String? search,
  }) => _page(
    '/api/v1/content/courses/',
    BackendContentNode.course,
    query: {
      'page': page,
      'library': libraryId,
      'subject': subjectId,
      'search': search,
    },
  );

  Future<BackendModuleResult<BackendPage<BackendContentNode>>> contentModules({
    int page = 1,
    int? courseId,
  }) => _page(
    '/api/v1/content/modules/',
    BackendContentNode.module,
    query: {'page': page, 'course': courseId},
  );

  Future<BackendModuleResult<BackendPage<BackendContentNode>>> contentLessons({
    int page = 1,
    int? moduleId,
    String? search,
  }) => _page(
    '/api/v1/content/lessons/',
    BackendContentNode.lesson,
    query: {'page': page, 'module': moduleId, 'search': search},
  );

  Future<BackendModuleResult<BackendPage<BackendContentNode>>> contentFolders({
    int page = 1,
    int? libraryId,
    int? parentId,
  }) => _page(
    '/api/v1/content/folders/',
    BackendContentNode.folder,
    query: {'page': page, 'library': libraryId, 'parent': parentId},
  );

  /// Generic typed node creation for the four small content hierarchy models.
  /// [kind] must be `courses`, `modules`, `lessons` or `folders`, while [body]
  /// follows the exact server fields for that kind.
  Future<BackendModuleResult<BackendContentNode>> createContentNode(
    String kind,
    BackendJson body,
  ) => _module(
    transport.post('/api/v1/content/$kind/', body: body),
    (response) => _contentNode(kind, backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendContentNode>> updateContentNode(
    String kind,
    int id,
    BackendJson changes, {
    bool replace = false,
  }) => _module(
    replace
        ? transport.put('/api/v1/content/$kind/$id/', body: changes)
        : transport.patch('/api/v1/content/$kind/$id/', body: changes),
    (response) => _contentNode(kind, backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPage<BackendContentFile>>> contentFiles({
    int page = 1,
    String? status,
    int? lessonId,
    int? folderId,
  }) => _page(
    '/api/v1/content/files/',
    BackendContentFile.fromJson,
    query: {
      'page': page,
      'status': status,
      'lesson': lessonId,
      'folder': folderId,
    },
  );

  Future<BackendModuleResult<BackendContentFile>> contentFile(int fileId) =>
      _module(
        transport.get('/api/v1/content/files/$fileId/'),
        (response) => BackendContentFile.fromJson(backendMap(response.data)),
      );

  Future<BackendModuleResult<BackendUploadGrant>> contentUploadGrant({
    required String filename,
    required String contentType,
    required int sizeBytes,
    String title = '',
    int? lessonId,
    int? folderId,
  }) => _module(
    transport.post(
      '/api/v1/content/upload-url/',
      body: {
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
        if (title.isNotEmpty) 'title': title,
        'lesson': ?lessonId,
        'folder': ?folderId,
      },
    ),
    (response) => BackendUploadGrant.fromJson(
      backendMap(response.data),
      fallbackMethod: 'PUT',
    ),
  );

  Future<BackendModuleResult<String>> confirmContentFile(int fileId) => _module(
    transport.post('/api/v1/content/files/$fileId/confirm/'),
    (response) => backendString(backendMap(response.data)['status']),
  );

  Future<BackendModuleResult<BackendUploadGrant>> newContentFileVersion(
    int fileId, {
    required String filename,
    required String contentType,
    required int sizeBytes,
  }) => _module(
    transport.post(
      '/api/v1/content/files/$fileId/new-version/',
      body: {
        'filename': filename,
        'content_type': contentType,
        'size_bytes': sizeBytes,
      },
    ),
    (response) => BackendUploadGrant.fromJson(
      backendMap(response.data),
      fallbackMethod: 'PUT',
    ),
  );

  Future<BackendModuleResult<String>> contentDownloadUrl(int fileId) => _module(
    transport.get('/api/v1/content/files/$fileId/download-url/'),
    (response) => backendString(backendMap(response.data)['url']),
  );

  Future<BackendModuleResult<bool>> trackContentView(int fileId) => _module(
    transport.post('/api/v1/content/files/$fileId/track-view/'),
    (response) => response.statusCode == 204,
  );

  Future<BackendModuleResult<BackendContentFile>> approveContentAsTeacher(
    int fileId,
  ) => _contentFileAction(fileId, 'approve-teacher');

  Future<BackendModuleResult<BackendContentFile>> approveContentAsManager(
    int fileId, {
    bool? downloadable,
  }) => _module(
    transport.post(
      '/api/v1/content/files/$fileId/approve-manager/',
      body: {'is_downloadable': ?downloadable},
    ),
    (response) => BackendContentFile.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPage<BackendMaterial>>> materials({
    int page = 1,
    int? libraryId,
    String? status,
    String? search,
  }) => _page(
    '/api/v1/content/materials/',
    BackendMaterial.fromJson,
    query: {
      'page': page,
      'library': libraryId,
      'status': status,
      'search': search,
    },
  );

  Future<BackendModuleResult<BackendMaterial>> createMaterial({
    required int libraryId,
    required String title,
    String topic = '',
  }) => _module(
    transport.post(
      '/api/v1/content/materials/',
      body: {'library': libraryId, 'title': title, 'topic': topic},
    ),
    (response) => BackendMaterial.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendMaterial>> updateMaterial(
    int materialId,
    BackendJson changes,
  ) => _module(
    transport.patch('/api/v1/content/materials/$materialId/', body: changes),
    (response) => BackendMaterial.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendQueuedRequest>> generateMaterial(
    int materialId,
  ) => _module(
    transport.post('/api/v1/content/materials/$materialId/generate/'),
    (response) => BackendQueuedRequest.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendMaterial>> publishMaterial(
    int materialId,
  ) => _module(
    transport.post('/api/v1/content/materials/$materialId/publish/'),
    (response) => BackendMaterial.fromJson(backendMap(response.data)),
  );

  // Printing --------------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendPrintJob>>> printJobs({
    int page = 1,
    String? status,
    String? source,
    int? branchId,
    String ordering = '-created_at',
  }) => _page(
    '/api/v1/printing/jobs/',
    BackendPrintJob.fromJson,
    query: {
      'page': page,
      'status': status,
      'source': source,
      'branch': branchId,
      'ordering': ordering,
    },
  );

  Future<BackendModuleResult<BackendPrintJob>> printJob(int jobId) => _module(
    transport.get('/api/v1/printing/jobs/$jobId/'),
    (response) => BackendPrintJob.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPrintJob>> createPrintJob({
    required String source,
    required int sourceId,
    required String payloadKey,
    required int branchId,
    required int pages,
    int copies = 1,
    bool color = false,
    bool duplex = false,
    int? cohortId,
  }) => _module(
    transport.post(
      '/api/v1/printing/jobs/',
      body: {
        'source': source,
        'source_id': sourceId,
        'payload_s3_key': payloadKey,
        'branch': branchId,
        'pages': pages,
        'copies': copies,
        'color': color,
        'duplex': duplex,
        'cohort': ?cohortId,
      },
    ),
    (response) => BackendPrintJob.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPage<BackendPrinter>>> printers({
    int page = 1,
    int? branchId,
    bool? active,
    String ordering = 'name',
  }) => _page(
    '/api/v1/printing/printers/',
    BackendPrinter.fromJson,
    query: {
      'page': page,
      'branch': branchId,
      'is_active': active,
      'ordering': ordering,
    },
  );

  Future<BackendModuleResult<BackendPrinter>> createPrinter({
    required int branchId,
    required String name,
    String modelName = '',
    BackendJson capabilities = const {},
    bool active = true,
  }) => _module(
    transport.post(
      '/api/v1/printing/printers/',
      body: {
        'branch': branchId,
        'name': name,
        'model_name': modelName,
        'capabilities': capabilities,
        'is_active': active,
      },
    ),
    (response) => BackendPrinter.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendPrinter>> updatePrinter(
    int printerId,
    BackendJson changes,
  ) => _module(
    transport.patch('/api/v1/printing/printers/$printerId/', body: changes),
    (response) => BackendPrinter.fromJson(backendMap(response.data)),
  );

  // AI --------------------------------------------------------------------

  Future<BackendModuleResult<BackendPage<BackendAiRequest>>> aiRequests({
    int page = 1,
    String? feature,
    String? status,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String ordering = '-created_at',
  }) => _page(
    '/api/v1/ai/requests/',
    BackendAiRequest.fromJson,
    query: {
      'page': page,
      'feature': feature,
      'status': status,
      'created_after': createdAfter == null ? null : _iso(createdAfter),
      'created_before': createdBefore == null ? null : _iso(createdBefore),
      'ordering': ordering,
    },
  );

  Future<BackendModuleResult<BackendAiRequest>> aiRequest(int requestId) =>
      _module(
        transport.get('/api/v1/ai/requests/$requestId/'),
        (response) => BackendAiRequest.fromJson(backendMap(response.data)),
      );

  Future<BackendModuleResult<BackendAiBudget>> aiBudget() => _module(
    transport.get('/api/v1/ai/budget/'),
    (response) => BackendAiBudget.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<BackendQueuedRequest>> generateExam({
    required int subjectId,
    required String examType,
    required int questionCount,
    required String difficulty,
  }) => _module(
    transport.post(
      '/api/v1/ai/exam-generation/',
      body: {
        'subject_id': subjectId,
        'exam_type': examType,
        'question_count': questionCount,
        'difficulty': difficulty,
      },
    ),
    (response) => BackendQueuedRequest.fromJson(backendMap(response.data)),
  );

  Future<BackendModuleResult<List<BackendJson>>> aiUsageReport({
    String? month,
  }) => _module(
    transport.get('/api/v1/ai/usage-report/', query: {'month': ?month}),
    (response) => backendMaps(response.data),
  );

  // Audit -----------------------------------------------------------------

  Future<BackendModuleResult<BackendCursorPage<BackendAuditEntry>>> audit({
    int? actorId,
    String? action,
    String? resourceType,
    String? resourceId,
    DateTime? from,
    DateTime? to,
    String? cursor,
  }) => _module(
    transport.get(
      '/api/v1/audit/',
      query: backendQuery(
        values: {
          'actor': actorId,
          'action': action,
          'resource_type': resourceType,
          'resource_id': resourceId,
          'ts_from': from == null ? null : _iso(from),
          'ts_to': to == null ? null : _iso(to),
          'cursor': cursor,
        },
      ),
    ),
    (response) =>
        BackendCursorPage.fromResponse(response, BackendAuditEntry.fromJson),
  );

  Future<BackendModuleResult<BackendAuditEntry>> auditEntry(int entryId) =>
      _module(
        transport.get('/api/v1/audit/$entryId/'),
        (response) => BackendAuditEntry.fromJson(backendMap(response.data)),
      );

  Future<BackendModuleResult<BackendContentFile>> _contentFileAction(
    int fileId,
    String action,
  ) => _module(
    transport.post('/api/v1/content/files/$fileId/$action/'),
    (response) => BackendContentFile.fromJson(backendMap(response.data)),
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

BackendContentNode _contentNode(String kind, BackendJson json) =>
    switch (kind) {
      'courses' => BackendContentNode.course(json),
      'modules' => BackendContentNode.module(json),
      'lessons' => BackendContentNode.lesson(json),
      'folders' => BackendContentNode.folder(json),
      _ => BackendContentNode(
        id: backendInt(json['id']),
        kind: kind,
        title: backendString(json['title'] ?? json['name']),
        parentId: null,
        parentLabel: '',
        order: backendInt(json['order']),
        raw: Map.unmodifiable(json),
      ),
    };

String _iso(DateTime value) => value.toUtc().toIso8601String();
