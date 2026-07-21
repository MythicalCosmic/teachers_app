import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/api/backend_core.dart';
import '../../data/api/backend_models.dart';
import '../../data/api/backend_services_api.dart';

enum BackendLoadPhase { idle, loading, ready, empty, unavailable, error }

abstract class BackendServicesController extends ChangeNotifier {
  BackendLoadPhase phase = BackendLoadPhase.idle;
  String? errorMessage;
  bool refreshing = false;
  bool loadingMore = false;
  bool _disposed = false;

  bool get hasError => phase == BackendLoadPhase.error;
  bool get isUnavailable => phase == BackendLoadPhase.unavailable;
  bool get isInitialLoading =>
      phase == BackendLoadPhase.loading && !hasRenderableData;

  bool get hasRenderableData;

  void notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final class BackendContentController extends BackendServicesController {
  BackendContentController(this.api);

  final BackendServicesApi api;

  List<BackendContentLibrary> libraries = const [];
  List<BackendContentNode> courses = const [];
  List<BackendContentNode> modules = const [];
  List<BackendContentNode> lessons = const [];
  List<BackendContentNode> folders = const [];
  List<BackendContentFile> files = const [];
  List<BackendMaterial> materials = const [];

  int? selectedLibraryId;
  int? selectedCourseId;
  int? selectedModuleId;
  String? fileStatus;

  bool filesUnavailable = false;
  bool materialsUnavailable = false;
  bool hierarchyUnavailable = false;

  int _libraryPage = 1;
  int _filePage = 1;
  int _materialPage = 1;
  bool hasMoreLibraries = false;
  bool hasMoreFiles = false;
  bool hasMoreMaterials = false;
  int _generation = 0;

  BackendContentLibrary? get selectedLibrary =>
      libraries.where((item) => item.id == selectedLibraryId).firstOrNull;

  BackendContentNode? get selectedCourse =>
      courses.where((item) => item.id == selectedCourseId).firstOrNull;

  BackendContentNode? get selectedModule =>
      modules.where((item) => item.id == selectedModuleId).firstOrNull;

  @override
  bool get hasRenderableData =>
      libraries.isNotEmpty || files.isNotEmpty || materials.isNotEmpty;

  Future<void> refresh({bool showSpinner = false}) async {
    final generation = ++_generation;
    errorMessage = null;
    if (!hasRenderableData || showSpinner) {
      phase = BackendLoadPhase.loading;
    } else {
      refreshing = true;
    }
    notifySafely();

    try {
      final result = await api.contentLibraries(page: 1, active: true);
      if (generation != _generation) return;
      if (result.isUnavailable) {
        phase = BackendLoadPhase.unavailable;
        refreshing = false;
        libraries = const [];
        notifySafely();
        return;
      }

      final page = result.value!;
      libraries = page.items;
      _libraryPage = page.page;
      hasMoreLibraries = page.hasNext;
      if (libraries.isEmpty) {
        _clearLibraryChildren();
        phase = BackendLoadPhase.empty;
        refreshing = false;
        notifySafely();
        return;
      }

      if (!libraries.any((item) => item.id == selectedLibraryId)) {
        selectedLibraryId = libraries.first.id;
      }
      await _loadLibrary(generation: generation);
      if (generation != _generation) return;
      phase = BackendLoadPhase.ready;
    } catch (error) {
      if (generation != _generation) return;
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      if (generation == _generation) {
        refreshing = false;
        notifySafely();
      }
    }
  }

  Future<void> selectLibrary(int libraryId) async {
    if (libraryId == selectedLibraryId && courses.isNotEmpty) return;
    final generation = ++_generation;
    selectedLibraryId = libraryId;
    selectedCourseId = null;
    selectedModuleId = null;
    phase = BackendLoadPhase.loading;
    notifySafely();
    try {
      await _loadLibrary(generation: generation);
      if (generation == _generation) phase = BackendLoadPhase.ready;
    } catch (error) {
      if (generation == _generation) {
        errorMessage = _friendlyError(error);
        phase = BackendLoadPhase.error;
      }
    } finally {
      if (generation == _generation) notifySafely();
    }
  }

  Future<void> selectCourse(int courseId) async {
    if (courseId == selectedCourseId && modules.isNotEmpty) return;
    final generation = ++_generation;
    selectedCourseId = courseId;
    selectedModuleId = null;
    modules = const [];
    lessons = const [];
    phase = BackendLoadPhase.loading;
    notifySafely();
    try {
      await _loadCourse(generation);
      if (generation == _generation) phase = BackendLoadPhase.ready;
    } catch (error) {
      if (generation == _generation) {
        errorMessage = _friendlyError(error);
        phase = BackendLoadPhase.error;
      }
    } finally {
      if (generation == _generation) notifySafely();
    }
  }

  Future<void> selectModule(int moduleId) async {
    if (moduleId == selectedModuleId && lessons.isNotEmpty) return;
    final generation = ++_generation;
    selectedModuleId = moduleId;
    lessons = const [];
    phase = BackendLoadPhase.loading;
    notifySafely();
    try {
      final result = await api.contentLessons(moduleId: moduleId);
      if (generation != _generation) return;
      if (result.isUnavailable) {
        hierarchyUnavailable = true;
      } else {
        lessons = result.value!.items;
      }
      phase = BackendLoadPhase.ready;
    } catch (error) {
      if (generation == _generation) {
        errorMessage = _friendlyError(error);
        phase = BackendLoadPhase.error;
      }
    } finally {
      if (generation == _generation) notifySafely();
    }
  }

  Future<void> setFileStatus(String? status) async {
    fileStatus = status;
    _filePage = 1;
    errorMessage = null;
    refreshing = true;
    notifySafely();
    try {
      final result = await api.contentFiles(page: 1, status: status);
      if (result.isUnavailable) {
        filesUnavailable = true;
        files = const [];
      } else {
        filesUnavailable = false;
        files = result.value!.items;
        hasMoreFiles = result.value!.hasNext;
      }
      phase = BackendLoadPhase.ready;
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      refreshing = false;
    }
    notifySafely();
  }

  Future<void> loadMoreLibraries() async {
    if (!hasMoreLibraries || loadingMore) return;
    loadingMore = true;
    errorMessage = null;
    notifySafely();
    try {
      final result = await api.contentLibraries(
        page: _libraryPage + 1,
        active: true,
      );
      if (result.isAvailable) {
        final page = result.value!;
        libraries = _mergeById(libraries, page.items, (item) => item.id);
        _libraryPage = page.page;
        hasMoreLibraries = page.hasNext;
        phase = BackendLoadPhase.ready;
      } else {
        hasMoreLibraries = false;
      }
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      loadingMore = false;
      notifySafely();
    }
  }

  Future<void> loadMoreFiles() async {
    if (!hasMoreFiles || loadingMore) return;
    loadingMore = true;
    errorMessage = null;
    notifySafely();
    try {
      final result = await api.contentFiles(
        page: _filePage + 1,
        status: fileStatus,
      );
      if (result.isAvailable) {
        final page = result.value!;
        files = _mergeById(files, page.items, (item) => item.id);
        _filePage = page.page;
        hasMoreFiles = page.hasNext;
        phase = BackendLoadPhase.ready;
      } else {
        hasMoreFiles = false;
      }
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      loadingMore = false;
      notifySafely();
    }
  }

  Future<void> loadMoreMaterials() async {
    if (!hasMoreMaterials || loadingMore) return;
    loadingMore = true;
    errorMessage = null;
    notifySafely();
    try {
      final result = await api.materials(
        page: _materialPage + 1,
        libraryId: selectedLibraryId,
      );
      if (result.isAvailable) {
        final page = result.value!;
        materials = _mergeById(materials, page.items, (item) => item.id);
        _materialPage = page.page;
        hasMoreMaterials = page.hasNext;
        phase = BackendLoadPhase.ready;
      } else {
        hasMoreMaterials = false;
      }
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      loadingMore = false;
      notifySafely();
    }
  }

  Future<BackendContentFile> approveTeacher(int fileId) async {
    final result = await api.approveContentAsTeacher(fileId);
    final file = _required(result, 'Teacher approval');
    _replaceFile(file);
    return file;
  }

  Future<BackendContentFile> approveManager(
    int fileId, {
    bool? downloadable,
  }) async {
    final result = await api.approveContentAsManager(
      fileId,
      downloadable: downloadable,
    );
    final file = _required(result, 'Manager approval');
    _replaceFile(file);
    return file;
  }

  Future<BackendUploadGrant> requestUpload({
    required String filename,
    required String contentType,
    required int sizeBytes,
    String title = '',
    int? lessonId,
    int? folderId,
  }) async => _required(
    await api.contentUploadGrant(
      filename: filename,
      contentType: contentType,
      sizeBytes: sizeBytes,
      title: title,
      lessonId: lessonId,
      folderId: folderId,
    ),
    'Upload link',
  );

  Future<BackendUploadGrant> requestNewVersion({
    required int fileId,
    required String filename,
    required String contentType,
    required int sizeBytes,
  }) async => _required(
    await api.newContentFileVersion(
      fileId,
      filename: filename,
      contentType: contentType,
      sizeBytes: sizeBytes,
    ),
    'New-version upload link',
  );

  Future<String> confirmUpload(int fileId) async {
    final status = _required(
      await api.confirmContentFile(fileId),
      'Upload confirmation',
    );
    await refresh();
    return status;
  }

  Future<String> requestDownloadUrl(int fileId) async =>
      _required(await api.contentDownloadUrl(fileId), 'Download link');

  /// Returns a fresh signed media URL and records a real server-side view.
  /// Tracking is intentionally best-effort: an analytics outage must not make
  /// an otherwise authorized lesson video or audio file unplayable.
  Future<String> requestPlaybackUrl(int fileId) async {
    final url = await requestDownloadUrl(fileId);
    unawaited(
      api.trackContentView(fileId).then<void>((_) {}).catchError((_) {}),
    );
    return url;
  }

  Future<BackendMaterial> createMaterial({
    required int libraryId,
    required String title,
    String topic = '',
  }) async {
    final material = _required(
      await api.createMaterial(
        libraryId: libraryId,
        title: title,
        topic: topic,
      ),
      'Material creation',
    );
    materials = _mergeById([material], materials, (item) => item.id);
    phase = BackendLoadPhase.ready;
    notifySafely();
    return material;
  }

  Future<BackendQueuedRequest> generateMaterial(int materialId) async =>
      _required(await api.generateMaterial(materialId), 'Material generation');

  Future<BackendMaterial> publishMaterial(int materialId) async {
    final material = _required(
      await api.publishMaterial(materialId),
      'Material publication',
    );
    materials = _mergeById(materials, [material], (item) => item.id);
    notifySafely();
    return material;
  }

  Future<void> _loadLibrary({required int generation}) async {
    final libraryId = selectedLibraryId;
    if (libraryId == null) return;
    filesUnavailable = false;
    materialsUnavailable = false;
    hierarchyUnavailable = false;
    _filePage = 1;
    _materialPage = 1;

    final results = await Future.wait<Object?>([
      api.contentCourses(libraryId: libraryId),
      api.contentFolders(libraryId: libraryId),
      api.contentFiles(status: fileStatus),
      api.materials(libraryId: libraryId),
    ]);
    if (generation != _generation) return;

    final courseResult =
        results[0] as BackendModuleResult<BackendPage<BackendContentNode>>;
    final folderResult =
        results[1] as BackendModuleResult<BackendPage<BackendContentNode>>;
    final fileResult =
        results[2] as BackendModuleResult<BackendPage<BackendContentFile>>;
    final materialResult =
        results[3] as BackendModuleResult<BackendPage<BackendMaterial>>;

    hierarchyUnavailable =
        courseResult.isUnavailable || folderResult.isUnavailable;
    courses = courseResult.value?.items ?? const [];
    folders = folderResult.value?.items ?? const [];

    filesUnavailable = fileResult.isUnavailable;
    files = fileResult.value?.items ?? const [];
    hasMoreFiles = fileResult.value?.hasNext ?? false;

    materialsUnavailable = materialResult.isUnavailable;
    materials = materialResult.value?.items ?? const [];
    hasMoreMaterials = materialResult.value?.hasNext ?? false;

    if (!courses.any((item) => item.id == selectedCourseId)) {
      selectedCourseId = courses.firstOrNull?.id;
    }
    await _loadCourse(generation);
  }

  Future<void> _loadCourse(int generation) async {
    final courseId = selectedCourseId;
    if (courseId == null) {
      modules = const [];
      lessons = const [];
      selectedModuleId = null;
      return;
    }
    final moduleResult = await api.contentModules(courseId: courseId);
    if (generation != _generation) return;
    if (moduleResult.isUnavailable) {
      hierarchyUnavailable = true;
      modules = const [];
      lessons = const [];
      return;
    }
    modules = moduleResult.value!.items;
    if (!modules.any((item) => item.id == selectedModuleId)) {
      selectedModuleId = modules.firstOrNull?.id;
    }
    final moduleId = selectedModuleId;
    if (moduleId == null) {
      lessons = const [];
      return;
    }
    final lessonResult = await api.contentLessons(moduleId: moduleId);
    if (generation != _generation) return;
    if (lessonResult.isUnavailable) {
      hierarchyUnavailable = true;
      lessons = const [];
    } else {
      lessons = lessonResult.value!.items;
    }
  }

  void _replaceFile(BackendContentFile file) {
    final updated = [...files];
    final index = updated.indexWhere((item) => item.id == file.id);
    if (index < 0) {
      updated.insert(0, file);
    } else {
      updated[index] = file;
    }
    files = List.unmodifiable(updated);
    notifySafely();
  }

  void _clearLibraryChildren() {
    selectedLibraryId = null;
    selectedCourseId = null;
    selectedModuleId = null;
    courses = const [];
    modules = const [];
    lessons = const [];
    folders = const [];
    files = const [];
    materials = const [];
    hasMoreLibraries = false;
    hasMoreFiles = false;
    hasMoreMaterials = false;
  }
}

final class BackendPrintController extends BackendServicesController {
  BackendPrintController(this.api);

  final BackendServicesApi api;
  List<BackendPrintJob> jobs = const [];
  List<BackendPrinter> printers = const [];
  String? status;
  bool printersUnavailable = false;
  int _page = 1;
  bool hasMoreJobs = false;
  int _generation = 0;

  @override
  bool get hasRenderableData => jobs.isNotEmpty || printers.isNotEmpty;

  Future<void> refresh({bool showSpinner = false}) async {
    final generation = ++_generation;
    errorMessage = null;
    if (!hasRenderableData || showSpinner) {
      phase = BackendLoadPhase.loading;
    } else {
      refreshing = true;
    }
    notifySafely();
    try {
      final values = await Future.wait<Object?>([
        api.printJobs(page: 1, status: status),
        api.printers(page: 1, active: true),
      ]);
      if (generation != _generation) return;
      final jobResult =
          values[0] as BackendModuleResult<BackendPage<BackendPrintJob>>;
      final printerResult =
          values[1] as BackendModuleResult<BackendPage<BackendPrinter>>;
      if (jobResult.isUnavailable) {
        phase = BackendLoadPhase.unavailable;
        jobs = const [];
      } else {
        final page = jobResult.value!;
        jobs = page.items;
        _page = page.page;
        hasMoreJobs = page.hasNext;
        printersUnavailable = printerResult.isUnavailable;
        printers = printerResult.value?.items ?? const [];
        phase = jobs.isEmpty && printers.isEmpty
            ? BackendLoadPhase.empty
            : BackendLoadPhase.ready;
      }
    } catch (error) {
      if (generation != _generation) return;
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      if (generation == _generation) {
        refreshing = false;
        notifySafely();
      }
    }
  }

  Future<void> setStatus(String? value) async {
    status = value;
    await refresh(showSpinner: true);
  }

  Future<void> loadMore() async {
    if (!hasMoreJobs || loadingMore) return;
    loadingMore = true;
    errorMessage = null;
    notifySafely();
    try {
      final result = await api.printJobs(page: _page + 1, status: status);
      if (result.isAvailable) {
        final page = result.value!;
        jobs = _mergeById(jobs, page.items, (item) => item.id);
        _page = page.page;
        hasMoreJobs = page.hasNext;
        phase = BackendLoadPhase.ready;
      } else {
        hasMoreJobs = false;
      }
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      loadingMore = false;
      notifySafely();
    }
  }

  Future<BackendPrintJob> createJob({
    required String source,
    required int sourceId,
    required String payloadKey,
    required int branchId,
    required int pages,
    int copies = 1,
    bool color = false,
    bool duplex = false,
    int? cohortId,
  }) async {
    final result = await api.createPrintJob(
      source: source,
      sourceId: sourceId,
      payloadKey: payloadKey,
      branchId: branchId,
      pages: pages,
      copies: copies,
      color: color,
      duplex: duplex,
      cohortId: cohortId,
    );
    final job = _required(result, 'Print job');
    jobs = _mergeById([job], jobs, (item) => item.id);
    phase = BackendLoadPhase.ready;
    notifySafely();
    return job;
  }
}

final class BackendAiController extends BackendServicesController {
  BackendAiController(this.api);

  final BackendServicesApi api;
  List<BackendAiRequest> requests = const [];
  BackendAiBudget? budget;
  List<BackendJson> usage = const [];
  String? feature;
  String? status;
  bool budgetUnavailable = false;
  bool usageUnavailable = false;
  int _page = 1;
  bool hasMoreRequests = false;
  int _generation = 0;

  @override
  bool get hasRenderableData =>
      requests.isNotEmpty || budget != null || usage.isNotEmpty;

  bool get serviceDisabled => budget?.isEnabled == false;

  Future<void> refresh({bool showSpinner = false}) async {
    final generation = ++_generation;
    errorMessage = null;
    if (!hasRenderableData || showSpinner) {
      phase = BackendLoadPhase.loading;
    } else {
      refreshing = true;
    }
    notifySafely();
    try {
      final values = await Future.wait<Object?>([
        api.aiRequests(page: 1, feature: feature, status: status),
        api.aiBudget(),
        api.aiUsageReport(),
      ]);
      if (generation != _generation) return;
      final requestResult =
          values[0] as BackendModuleResult<BackendPage<BackendAiRequest>>;
      final budgetResult = values[1] as BackendModuleResult<BackendAiBudget>;
      final usageResult = values[2] as BackendModuleResult<List<BackendJson>>;
      if (requestResult.isUnavailable) {
        requests = const [];
        phase = BackendLoadPhase.unavailable;
      } else {
        final page = requestResult.value!;
        requests = page.items;
        _page = page.page;
        hasMoreRequests = page.hasNext;
        budgetUnavailable = budgetResult.isUnavailable;
        budget = budgetResult.value;
        usageUnavailable = usageResult.isUnavailable;
        usage = usageResult.value ?? const [];
        phase = BackendLoadPhase.ready;
      }
    } catch (error) {
      if (generation != _generation) return;
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      if (generation == _generation) {
        refreshing = false;
        notifySafely();
      }
    }
  }

  Future<void> loadMore() async {
    if (!hasMoreRequests || loadingMore) return;
    loadingMore = true;
    errorMessage = null;
    notifySafely();
    try {
      final result = await api.aiRequests(
        page: _page + 1,
        feature: feature,
        status: status,
      );
      if (result.isAvailable) {
        final page = result.value!;
        requests = _mergeById(requests, page.items, (item) => item.id);
        _page = page.page;
        hasMoreRequests = page.hasNext;
        phase = BackendLoadPhase.ready;
      } else {
        hasMoreRequests = false;
      }
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      loadingMore = false;
      notifySafely();
    }
  }

  Future<BackendQueuedRequest> generateExam({
    required int subjectId,
    required String examType,
    required int questionCount,
    required String difficulty,
  }) async {
    final queued = _required(
      await api.generateExam(
        subjectId: subjectId,
        examType: examType,
        questionCount: questionCount,
        difficulty: difficulty,
      ),
      'Exam generation',
    );
    await refresh();
    return queued;
  }

  Future<BackendAiRequest> requestDetail(int requestId) async =>
      _required(await api.aiRequest(requestId), 'AI request');
}

final class BackendAuditController extends BackendServicesController {
  BackendAuditController(this.api);

  final BackendServicesApi api;
  List<BackendAuditEntry> entries = const [];
  int? actorId;
  String? action;
  String? resourceType;
  String? resourceId;
  DateTime? from;
  DateTime? to;
  String? _next;
  int _generation = 0;

  bool get hasMore => _next != null && _next!.isNotEmpty;

  @override
  bool get hasRenderableData => entries.isNotEmpty;

  Future<void> refresh({bool showSpinner = false}) async {
    final generation = ++_generation;
    errorMessage = null;
    if (!hasRenderableData || showSpinner) {
      phase = BackendLoadPhase.loading;
    } else {
      refreshing = true;
    }
    notifySafely();
    try {
      final result = await api.audit(
        actorId: actorId,
        action: _blankToNull(action),
        resourceType: _blankToNull(resourceType),
        resourceId: _blankToNull(resourceId),
        from: from,
        to: to,
      );
      if (generation != _generation) return;
      if (result.isUnavailable) {
        entries = const [];
        _next = null;
        phase = BackendLoadPhase.unavailable;
      } else {
        entries = result.value!.items;
        _next = result.value!.next;
        phase = entries.isEmpty
            ? BackendLoadPhase.empty
            : BackendLoadPhase.ready;
      }
    } catch (error) {
      if (generation != _generation) return;
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      if (generation == _generation) {
        refreshing = false;
        notifySafely();
      }
    }
  }

  Future<void> applyFilters({
    int? actor,
    String? actionValue,
    String? resourceTypeValue,
    String? resourceIdValue,
    DateTime? fromValue,
    DateTime? toValue,
  }) async {
    actorId = actor;
    action = _blankToNull(actionValue);
    resourceType = _blankToNull(resourceTypeValue);
    resourceId = _blankToNull(resourceIdValue);
    from = fromValue;
    to = toValue;
    await refresh(showSpinner: true);
  }

  Future<void> clearFilters() => applyFilters();

  Future<void> loadMore() async {
    final cursor = _cursorValue(_next);
    if (cursor == null || loadingMore) return;
    loadingMore = true;
    errorMessage = null;
    notifySafely();
    try {
      final result = await api.audit(
        actorId: actorId,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        from: from,
        to: to,
        cursor: cursor,
      );
      if (result.isAvailable) {
        entries = _mergeById(entries, result.value!.items, (item) => item.id);
        _next = result.value!.next;
        phase = BackendLoadPhase.ready;
      } else {
        _next = null;
      }
    } catch (error) {
      errorMessage = _friendlyError(error);
      phase = BackendLoadPhase.error;
    } finally {
      loadingMore = false;
      notifySafely();
    }
  }

  Future<BackendAuditEntry> entryDetail(int entryId) async =>
      _required(await api.auditEntry(entryId), 'Audit entry');
}

T _required<T>(BackendModuleResult<T> result, String label) {
  if (result.isUnavailable || result.value == null) {
    throw StateError('$label is unavailable for this staff account.');
  }
  return result.value as T;
}

List<T> _mergeById<T, K>(
  Iterable<T> existing,
  Iterable<T> incoming,
  K Function(T item) idOf,
) {
  final values = <K, T>{};
  for (final item in existing) {
    values[idOf(item)] = item;
  }
  for (final item in incoming) {
    values[idOf(item)] = item;
  }
  return List.unmodifiable(values.values);
}

String _friendlyError(Object error) {
  final value = error.toString().trim();
  return value.startsWith('Exception: ')
      ? value.substring('Exception: '.length)
      : value;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _cursorValue(String? next) {
  final raw = _blankToNull(next);
  if (raw == null) return null;
  final uri = Uri.tryParse(raw);
  return uri?.queryParameters['cursor'] ?? raw;
}
