import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/app_storage.dart';
import '../data/api/api_models.dart';
import '../data/api/backend_models.dart';
import '../data/api/backend_work_api.dart';
import '../data/api/notification_realtime.dart';
import '../data/api/starforge_api.dart';
import '../data/demo_seed.dart';
import '../data/models.dart';
import '../features/messaging/messaging_controller.dart';
import '../features/messaging/messaging_storage.dart';
import '../features/notifications/backend_notification_controller.dart';

final class AuthenticationException implements Exception {
  const AuthenticationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AppState extends ChangeNotifier {
  AppState._({
    required this._storage,
    required this._clock,
    required AppSnapshot snapshot,
    this._api,
    String? bootstrapError,
  }) : _session = snapshot.session,
       _settings = snapshot.settings,
       _tasks = snapshot.tasks.toList(),
       _attendanceSheets = snapshot.attendanceSheets.toList(),
       _cards = snapshot.cards.toList(),
       _messageThreads = snapshot.messageThreads.toList(),
       _notifications = snapshot.notifications.toList(),
       _surveys = snapshot.surveys.toList(),
       _printJobs = snapshot.printJobs.toList(),
       _auditAnomalies = snapshot.auditAnomalies.toList(),
       _auditCases = snapshot.auditCases.toList(),
       _persistenceError = bootstrapError;

  static const _snapshotKey = 'starforge.staff.snapshot.v1';

  final AppStorage _storage;
  final DateTime Function() _clock;
  final StarforgeApi? _api;
  MessagingController? _productionMessaging;
  BackendNotificationController? _productionNotifications;

  StaffSession? _session;
  AppSettings _settings;
  List<StaffTask> _tasks;
  List<AttendanceSheet> _attendanceSheets;
  List<RecognitionCard> _cards;
  List<MessageThread> _messageThreads;
  List<StaffNotification> _notifications;
  List<SurveyAssignment> _surveys;
  List<PrintJob> _printJobs;
  List<AuditAnomaly> _auditAnomalies;
  List<AuditCase> _auditCases;

  bool _persistSession = true;
  bool _isInitialized = false;
  bool _isPersisting = false;
  String? _persistenceError;
  String? _syncError;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  bool _tasksLoading = false;
  bool _tasksAvailable = true;
  String? _tasksError;
  bool _formsLoading = false;
  bool _formsAvailable = true;
  String? _formsError;
  int _idCounter = 0;

  static Future<AppState> bootstrap({
    AppStorage? storage,
    DateTime Function()? clock,
    StarforgeApi? api,
  }) async {
    final resolvedStorage =
        storage ?? await SharedPreferencesAppStorage.create();
    final resolvedClock = clock ?? DateTime.now;
    if (api != null && resolvedStorage is SharedPreferencesAppStorage) {
      await resolvedStorage.migrateLegacyDemoData();
    }
    var snapshot = DemoSeed.snapshot();
    String? error;
    try {
      final raw = await resolvedStorage.read(_snapshotKey);
      if (raw != null && raw.isNotEmpty) {
        snapshot = AppSnapshot.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map),
        );
      }
    } on Object catch (caught) {
      error = 'Saqlangan ma’lumotlar o‘qilmadi: $caught';
    }
    if (api != null) {
      snapshot = _remoteSnapshot(settings: snapshot.settings);
    }
    final state = AppState._(
      storage: resolvedStorage,
      clock: resolvedClock,
      snapshot: snapshot,
      api: api,
      bootstrapError: error,
    );
    if (api != null) state._configureBackendWork(api);
    state._isInitialized = api == null;
    if (api != null) {
      try {
        await resolvedStorage.write(
          _snapshotKey,
          jsonEncode(snapshot.toJson()),
        );
      } on Object catch (caught) {
        state._persistenceError =
            'Production keshini tozalab bo‘lmadi: $caught';
      }
      unawaited(state._restoreRemoteSession());
    }
    return state;
  }

  static AppSnapshot _remoteSnapshot({required AppSettings settings}) =>
      AppSnapshot(
        session: null,
        settings: settings,
        tasks: const [],
        attendanceSheets: const [],
        cards: const [],
        messageThreads: const [],
        notifications: const [],
        surveys: const [],
        printJobs: const [],
        auditAnomalies: const [],
        auditCases: const [],
      );

  void _configureBackendWork(StarforgeApi api) {
    api.setAuthenticationRequiredHandler(_expireRemoteSession);
    final work = BackendWorkApi.fromApi(api);
    final messaging = MessagingController(
      storage: SharedPreferencesMessagingStorage(),
      backend: work,
    );
    final notifications = BackendNotificationController(
      backend: work,
      realtime: NotificationRealtimeClient(
        wsUrl: () => api.connection?.wsUrl,
        accessToken: () => api.currentAccessToken,
      ),
    );
    messaging.onUnauthorized = _expireRemoteSession;
    notifications.onUnauthorized = _expireRemoteSession;
    notifications.onMessageReceived = (threadId) =>
        messaging.refreshForRealtime(threadId: threadId);
    messaging.addListener(_notifyFromBackendWork);
    notifications.addListener(_notifyFromBackendWork);
    _productionMessaging = messaging;
    _productionNotifications = notifications;
  }

  void _notifyFromBackendWork() {
    if (!hasListeners) return;
    notifyListeners();
  }

  void _startBackendRealtime() {
    if (_session == null) return;
    unawaited(_productionNotifications?.startRealtime());
  }

  Future<void> _expireRemoteSession() async {
    if (_api == null || _session == null) return;
    await _productionNotifications?.clearSession();
    _productionMessaging?.clearRemoteSession();
    _session = null;
    _tasks = [];
    _attendanceSheets = [];
    _cards = [];
    _messageThreads = [];
    _notifications = [];
    _surveys = [];
    _printJobs = [];
    _auditAnomalies = [];
    _auditCases = [];
    _tasksLoading = false;
    _tasksAvailable = true;
    _tasksError = null;
    _formsLoading = false;
    _formsAvailable = true;
    _formsError = null;
    _syncError =
        'Sessiya muddati tugadi. Xavfsiz davom etish uchun qayta kiring.';
    _lastSyncedAt = null;
    notifyListeners();
    await _persist();
  }

  void pauseRealtime() {
    unawaited(_productionNotifications?.pause());
  }

  void resumeRealtime() {
    if (_session != null) unawaited(_productionNotifications?.resume());
  }

  bool get isInitialized => _isInitialized;
  bool get isProduction => _api != null;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _api == null || (_session != null && _syncError == null);
  String? get syncError => _syncError;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String get centerName => _api?.connection?.name ?? _session?.branchName ?? '';
  String get serverHost => _api?.connection?.baseUrl ?? '';
  bool get isPersisting => _isPersisting;
  String? get persistenceError => _persistenceError;
  StaffSession? get session => _session;
  StarforgeApi? get backendApi => _api;
  MessagingController get messagingController =>
      _productionMessaging ?? MessagingController.shared;
  BackendNotificationController? get backendNotifications =>
      _productionNotifications;
  AppSettings get settings => _settings;
  List<StaffTask> get tasks => List.unmodifiable(_tasks);
  bool get tasksLoading => _tasksLoading;
  bool get tasksAvailable => _tasksAvailable;
  String? get tasksError => _tasksError;
  List<AttendanceSheet> get attendanceSheets =>
      List.unmodifiable(_attendanceSheets);
  List<RecognitionCard> get cards => List.unmodifiable(_cards);
  List<MessageThread> get messageThreads => List.unmodifiable(_messageThreads);
  List<StaffNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<SurveyAssignment> get surveys => List.unmodifiable(_surveys);
  bool get formsLoading => _formsLoading;
  bool get formsAvailable => _formsAvailable;
  String? get formsError => _formsError;
  List<PrintJob> get printJobs => List.unmodifiable(_printJobs);
  List<AuditAnomaly> get auditAnomalies => List.unmodifiable(_auditAnomalies);
  List<AuditCase> get auditCases => List.unmodifiable(_auditCases);

  Future<void> retryPersistence() => _persist();

  Future<void> retryConnection() async {
    if (_api == null) return;
    if (_session == null) {
      await _restoreRemoteSession();
      return;
    }
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    try {
      final profile = await _api.me();
      _session = _sessionFromIdentity(
        AuthenticatedIdentity(
          accessToken: '',
          connection: _api.connection!,
          profile: profile,
          principalKind: apiString(profile['principal_kind']),
          mustChangePassword: apiBool(profile['must_change_password']),
        ),
      );
      _lastSyncedAt = _clock();
      _startBackendRealtime();
      unawaited(refreshTasks());
      unawaited(refreshForms());
    } on ApiException catch (error) {
      await _handleRemoteError(error);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _restoreRemoteSession() async {
    final api = _api;
    if (api == null) return;
    _isInitialized = false;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    api.setLocale(_settings.locale.name);
    try {
      final identity = await api.restore();
      if (identity != null) {
        _session = _sessionFromIdentity(identity);
        _lastSyncedAt = _clock();
        _startBackendRealtime();
        unawaited(refreshTasks());
        unawaited(refreshForms());
      }
    } on ApiException catch (error) {
      _syncError = error.message;
    } on Object catch (error) {
      _syncError = 'Server sessiyasini tiklab bo‘lmadi: $error';
    } finally {
      _isInitialized = true;
      _isSyncing = false;
      notifyListeners();
    }
  }

  void clearPersistenceError() {
    if (_persistenceError == null) return;
    _persistenceError = null;
    notifyListeners();
  }

  int get unreadMessageCount {
    if (_productionMessaging case final messaging?) {
      return messaging.unreadCount;
    }
    final userId = _session?.userId;
    if (userId == null) return 0;
    return _messageThreads.fold(
      0,
      (sum, thread) => sum + thread.unreadCountFor(userId),
    );
  }

  int get unreadNotificationCount =>
      _productionNotifications?.unreadCount ??
      _notifications.where((item) => !item.isRead).length;

  bool can(StaffCapability capability) => _session?.can(capability) ?? false;

  Future<StaffSession> signIn({
    required String username,
    required String password,
    bool persistSession = true,
    String centerSlug = '',
  }) async {
    final api = _api;
    if (api != null) {
      _isSyncing = true;
      _syncError = null;
      notifyListeners();
      try {
        api.setLocale(_settings.locale.name);
        final identity = await api.signIn(
          centerSlug: centerSlug,
          username: username,
          password: password,
          remember: persistSession,
        );
        final authenticated = _sessionFromIdentity(identity);
        _session = authenticated;
        _persistSession = false;
        _lastSyncedAt = _clock();
        _startBackendRealtime();
        unawaited(refreshTasks());
        unawaited(refreshForms());
        notifyListeners();
        await _persist();
        return authenticated;
      } on ApiException catch (error) {
        _syncError = error.code == 'invalid_credentials' ? null : error.message;
        throw AuthenticationException(error.message);
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final authenticated = DemoSeed.authenticate(username, password);
    if (authenticated == null) {
      throw AuthenticationException(
        _message(
          uz: 'Foydalanuvchi nomi yoki parol noto‘g‘ri.',
          ru: 'Неверное имя пользователя или пароль.',
          en: 'Incorrect username or password.',
        ),
      );
    }
    _session = authenticated;
    _persistSession = persistSession;
    notifyListeners();
    await _persist();
    return authenticated;
  }

  Future<void> signOut() async {
    if (_api != null) {
      await _productionNotifications?.clearSession();
      _productionMessaging?.clearRemoteSession();
      await _api.signOut();
      _tasks = [];
      _attendanceSheets = [];
      _cards = [];
      _messageThreads = [];
      _notifications = [];
      _surveys = [];
      _printJobs = [];
      _auditAnomalies = [];
      _auditCases = [];
      _tasksLoading = false;
      _tasksAvailable = true;
      _tasksError = null;
      _formsLoading = false;
      _formsAvailable = true;
      _formsError = null;
      _syncError = null;
      _lastSyncedAt = null;
    }
    _session = null;
    _persistSession = true;
    notifyListeners();
    await _persist();
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
    String? username,
    String? phone,
    String? bio,
    int? avatarColorValue,
  }) async {
    final current = _requireSession();
    final cleanName = displayName.trim();
    final cleanEmail = email.trim();
    if (cleanName.length < 3 || !cleanEmail.contains('@')) {
      throw ArgumentError(
        _message(
          uz: 'Ism va email manzilini to‘g‘ri kiriting.',
          ru: 'Введите корректные имя и адрес почты.',
          en: 'Enter a valid name and email address.',
        ),
      );
    }
    if (_api != null) {
      try {
        final parts = cleanName
            .split(RegExp(r'\s+'))
            .where((value) => value.isNotEmpty)
            .toList();
        final profile = await _api.updateMe({
          'first_name': parts.firstOrNull ?? '',
          'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'email': cleanEmail,
          if (phone != null) 'phone': phone.trim(),
        });
        _session = _sessionFromIdentity(
          AuthenticatedIdentity(
            accessToken: '',
            connection: _api.connection!,
            profile: profile,
            principalKind: apiString(profile['principal_kind']),
            mustChangePassword: apiBool(profile['must_change_password']),
          ),
        );
        notifyListeners();
        await _persist();
        return;
      } on ApiException catch (error) {
        await _handleRemoteError(error);
        rethrow;
      }
    }
    _session = StaffSession(
      userId: current.userId,
      displayName: cleanName,
      role: current.role,
      branchId: current.branchId,
      branchName: current.branchName,
      email: cleanEmail,
      username: username?.trim() ?? current.username,
      phone: phone?.trim() ?? current.phone,
      bio: bio?.trim() ?? current.bio,
      avatarColorValue: avatarColorValue ?? current.avatarColorValue,
      accountTypeSlug: current.accountTypeSlug,
      mustChangePassword: current.mustChangePassword,
      isRemote: current.isRemote,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateSettings(AppSettings value) async {
    _settings = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(AppThemeMode value) =>
      updateSettings(_settings.copyWith(themeMode: value));
  Future<void> setPalette(AppPalette value) =>
      updateSettings(_settings.copyWith(palette: value));
  Future<void> setLocale(AppLocale value) {
    _api?.setLocale(value.name);
    return updateSettings(_settings.copyWith(locale: value));
  }

  Future<void> requestPasswordReset({
    required String identifier,
    String accountType = 'staff',
  }) async {
    final api = _api;
    if (api == null) {
      throw StateError('Password reset is only available with the server.');
    }
    await api.requestPasswordReset(
      identifier: identifier,
      accountType: accountType,
    );
  }

  Future<void> confirmPasswordReset({
    required String identifier,
    required String code,
    required String newPassword,
    String accountType = 'staff',
  }) async {
    final api = _api;
    if (api == null) {
      throw StateError('Password reset is only available with the server.');
    }
    await api.confirmPasswordReset(
      identifier: identifier,
      code: code,
      newPassword: newPassword,
      accountType: accountType,
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final api = _api;
    if (api == null) {
      throw StateError('Password change is only available with the server.');
    }
    try {
      await api.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      final current = _requireSession();
      _session = StaffSession(
        userId: current.userId,
        displayName: current.displayName,
        role: current.role,
        branchId: current.branchId,
        branchName: current.branchName,
        email: current.email,
        username: current.username,
        phone: current.phone,
        bio: current.bio,
        avatarColorValue: current.avatarColorValue,
        accountTypeSlug: current.accountTypeSlug,
        mustChangePassword: false,
        isRemote: true,
      );
      notifyListeners();
    } on ApiException catch (error) {
      await _handleRemoteError(error);
      rethrow;
    }
  }

  Future<void> setLiquidGlass(bool value) =>
      updateSettings(_settings.copyWith(liquidGlass: value));
  Future<void> setReducedMotion(bool value) =>
      updateSettings(_settings.copyWith(reducedMotion: value));
  Future<void> setHaptics(bool value) =>
      updateSettings(_settings.copyWith(haptics: value));
  Future<void> setCoachMarks(bool value) =>
      updateSettings(_settings.copyWith(coachMarks: value));
  Future<void> setVisualStyle(AppVisualStyle value) =>
      updateSettings(_settings.copyWith(visualStyle: value));
  Future<void> setFontChoice(AppFontChoice value) =>
      updateSettings(_settings.copyWith(fontChoice: value));
  Future<void> setLayoutDensity(AppLayoutDensity value) =>
      updateSettings(_settings.copyWith(layoutDensity: value));
  Future<void> setSurfaceOpacity(double value) =>
      updateSettings(_settings.copyWith(surfaceOpacity: value));
  Future<void> setNavigationOpacity(double value) =>
      updateSettings(_settings.copyWith(navigationOpacity: value));
  Future<void> setMotionIntensity(double value) =>
      updateSettings(_settings.copyWith(motionIntensity: value));
  Future<void> completeWelcome() =>
      updateSettings(_settings.copyWith(hasCompletedWelcome: true));

  /// Reloads the current staff member's server-owned tasks without replacing
  /// device-only organization such as favorites, checklists, tags and notes.
  Future<void> refreshTasks() async {
    final api = _api;
    if (api == null || _session == null || _tasksLoading) return;
    _tasksLoading = true;
    _tasksError = null;
    notifyListeners();
    try {
      final result = await BackendWorkApi.fromApi(api).myTasks();
      if (result.isUnavailable) {
        _tasksAvailable = false;
        _tasksError = result.error?.message;
        _tasks = [];
        return;
      }
      _tasksAvailable = true;
      final currentById = {for (final task in _tasks) task.id: task};
      _tasks = [
        for (final task in result.value?.items ?? const <BackendTask>[])
          _staffTaskFromBackend(task, overlay: currentById['${task.id}']),
      ];
      _lastSyncedAt = _clock();
      await _persist();
    } on ApiException catch (error) {
      _tasksError = error.message;
      await _handleRemoteError(error);
    } on Object catch (error) {
      _tasksError = error.toString();
    } finally {
      _tasksLoading = false;
      notifyListeners();
    }
  }

  Future<StaffTask> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
    String? assigneeId,
    String? assigneeName,
    Iterable<String> checklist = const [],
    Iterable<String> tags = const [],
  }) async {
    _requireCapability(StaffCapability.createTasks);
    final current = _requireSession();
    final cleanTitle = title.trim();
    if (cleanTitle.length < 3) {
      throw ArgumentError(
        _message(
          uz: 'Vazifa sarlavhasi juda qisqa.',
          ru: 'Название задачи слишком короткое.',
          en: 'The task title is too short.',
        ),
      );
    }
    final now = _clock();
    final selectedAssigneeId = assigneeId ?? current.userId;
    if (selectedAssigneeId != current.userId &&
        !current.can(StaffCapability.assignTasks)) {
      throw StateError(
        _message(
          uz: 'Boshqa xodimga vazifa biriktirishga ruxsat yo‘q.',
          ru: 'Нет разрешения назначать задачи другим сотрудникам.',
          en: 'You do not have permission to assign tasks to other staff.',
        ),
      );
    }
    final api = _api;
    if (api != null) {
      final result = await BackendWorkApi.fromApi(api).createTask(
        title: cleanTitle,
        description: description.trim(),
        priority: _backendTaskPriority(priority),
        assigneeId: int.tryParse(selectedAssigneeId),
        branchId: int.tryParse(current.branchId),
        dueAt: dueAt,
      );
      if (result.isUnavailable || result.value == null) {
        throw StateError(
          result.error?.message ??
              _message(
                uz: 'Vazifalar moduli bu rol uchun mavjud emas.',
                ru: 'Модуль задач недоступен для этой роли.',
                en: 'The tasks module is unavailable for this role.',
              ),
        );
      }
      final remote = _staffTaskFromBackend(result.value!);
      final task = remote.copyWith(
        checklist: [
          for (final entry in checklist.where(
            (value) => value.trim().isNotEmpty,
          ))
            TaskChecklistItem(id: _newId('step'), title: entry.trim()),
        ],
        tags: tags
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );
      _tasks = [task, ..._tasks.where((item) => item.id != task.id)];
      notifyListeners();
      await _persist();
      return task;
    }
    final task = StaffTask(
      id: _newId('task'),
      title: cleanTitle,
      description: description.trim(),
      status: TaskStatus.todo,
      priority: priority,
      creatorId: current.userId,
      creatorName: current.displayName,
      assigneeId: selectedAssigneeId,
      assigneeName: selectedAssigneeId == current.userId
          ? current.displayName
          : assigneeName ?? selectedAssigneeId,
      dueAt: dueAt ?? now.add(const Duration(days: 2)),
      createdAt: now,
      checklist: [
        for (final entry in checklist.where((value) => value.trim().isNotEmpty))
          TaskChecklistItem(id: _newId('step'), title: entry.trim()),
      ],
      tags: tags
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    );
    _tasks = [task, ..._tasks];
    notifyListeners();
    await _persist();
    return task;
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    _requireTaskUpdatePermission(_tasks[index]);
    final api = _api;
    if (api != null) {
      final numericId = int.tryParse(taskId);
      if (numericId == null) {
        throw StateError('Invalid server task id: $taskId');
      }
      final result = await BackendWorkApi.fromApi(
        api,
      ).transitionTask(numericId, _backendTaskStatus(status));
      if (result.isUnavailable || result.value == null) {
        throw StateError(
          result.error?.message ??
              _message(
                uz: 'Vazifa holatini o\'zgartirishga ruxsat yo\'q.',
                ru: 'Нет разрешения менять статус задачи.',
                en: 'You cannot change this task status.',
              ),
        );
      }
      _tasks[index] = _staffTaskFromBackend(
        result.value!,
        overlay: _tasks[index],
      );
      notifyListeners();
      await _persist();
      return;
    }
    _tasks[index] = _tasks[index].copyWith(status: status);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleTaskChecklistItem(
    String taskId,
    String checklistId,
  ) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    final items = [
      for (final item in task.checklist)
        item.id == checklistId ? item.copyWith(isDone: !item.isDone) : item,
    ];
    _tasks[index] = task.copyWith(checklist: items);
    notifyListeners();
    await _persist();
  }

  Future<void> reorderTaskChecklist(
    String taskId,
    int oldIndex,
    int newIndex,
  ) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    final items = task.checklist.toList();
    if (oldIndex < 0 || oldIndex >= items.length) {
      throw RangeError.index(oldIndex, items, 'oldIndex');
    }
    if (newIndex < 0 || newIndex >= items.length) {
      throw RangeError.index(newIndex, items, 'newIndex');
    }
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    _tasks[index] = task.copyWith(checklist: items);
    notifyListeners();
    await _persist();
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueAt,
  }) async {
    if (_api != null) {
      if (title != null ||
          description != null ||
          priority != null ||
          dueAt != null) {
        throw StateError(
          _message(
            uz: 'Server vazifa tafsilotlarini tahrirlashni hali qo\'llamaydi. Holatni o\'zgartirish mumkin.',
            ru: 'Сервер пока не поддерживает изменение деталей задачи. Можно изменить статус.',
            en: 'The server does not yet support editing task details. You can change its status.',
          ),
        );
      }
      if (status != null) await setTaskStatus(taskId, status);
      return;
    }
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final current = _tasks[index];
    _requireTaskUpdatePermission(current);
    final cleanTitle = title?.trim();
    if (cleanTitle != null && cleanTitle.length < 3) {
      throw ArgumentError(
        _message(
          uz: 'Vazifa sarlavhasi juda qisqa.',
          ru: 'Название задачи слишком короткое.',
          en: 'The task title is too short.',
        ),
      );
    }
    _tasks[index] = current.copyWith(
      title: cleanTitle,
      description: description?.trim(),
      status: status,
      priority: priority,
      dueAt: dueAt,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> addTaskChecklistItem(String taskId, String title) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError(
        _message(
          uz: 'Qadam nomini kiriting.',
          ru: 'Введите название шага.',
          en: 'Enter a checklist item.',
        ),
      );
    }
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    _tasks[index] = task.copyWith(
      checklist: [
        ...task.checklist,
        TaskChecklistItem(id: _newId('step'), title: cleanTitle),
      ],
    );
    notifyListeners();
    await _persist();
  }

  Future<void> removeTaskChecklistItem(
    String taskId,
    String checklistId,
  ) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    _tasks[index] = task.copyWith(
      checklist: task.checklist.where((item) => item.id != checklistId),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask(String taskId) async {
    if (_api != null) {
      throw StateError(
        _message(
          uz: 'Server vazifalarni o\'chirishni qo\'llamaydi.',
          ru: 'Сервер не поддерживает удаление задач.',
          en: 'The server does not support deleting tasks.',
        ),
      );
    }
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final current = _requireSession();
    final task = _tasks[index];
    if (task.assigneeId != current.userId && task.creatorId != current.userId) {
      throw StateError(
        _message(
          uz: 'Bu vazifani o‘chirishga ruxsat yo‘q.',
          ru: 'Нет разрешения на удаление этой задачи.',
          en: 'You do not have permission to delete this task.',
        ),
      );
    }
    _tasks.removeAt(index);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleTaskFavorite(String taskId) async {
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _tasks[index] = task.copyWith(isFavorite: !task.isFavorite);
    notifyListeners();
    await _persist();
  }

  Future<void> addTaskTag(String taskId, String tag) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final clean = tag.trim();
    if (clean.isEmpty) return;
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    if (task.tags.any((value) => value.toLowerCase() == clean.toLowerCase())) {
      return;
    }
    _tasks[index] = task.copyWith(tags: [...task.tags, clean]);
    notifyListeners();
    await _persist();
  }

  Future<void> removeTaskTag(String taskId, String tag) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    _tasks[index] = task.copyWith(
      tags: task.tags.where((value) => value != tag),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> addTaskComment(String taskId, String body) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final clean = body.trim();
    if (clean.isEmpty) {
      throw ArgumentError(
        _message(
          uz: 'Izoh bo‘sh bo‘lishi mumkin emas.',
          ru: 'Комментарий не может быть пустым.',
          en: 'A comment cannot be empty.',
        ),
      );
    }
    final current = _requireSession();
    final index = _indexById(_tasks, taskId, (item) => item.id);
    final task = _tasks[index];
    _requireTaskUpdatePermission(task);
    _tasks[index] = task.copyWith(
      comments: [
        ...task.comments,
        TaskComment(
          id: _newId('comment'),
          authorId: current.userId,
          authorName: current.displayName,
          body: clean,
          createdAt: _clock(),
        ),
      ],
    );
    notifyListeners();
    await _persist();
  }

  Future<void> markAttendance({
    required String sheetId,
    required String studentId,
    required AttendanceStatus status,
    String? note,
  }) async {
    _requireCapability(StaffCapability.takeAttendance);
    final index = _indexById(_attendanceSheets, sheetId, (item) => item.id);
    final sheet = _attendanceSheets[index];
    if (sheet.isSubmitted) {
      throw StateError(
        _message(
          uz: 'Yuborilgan davomatni tahrirlab bo‘lmaydi.',
          ru: 'Отправленную посещаемость нельзя изменить.',
          en: 'Submitted attendance cannot be edited.',
        ),
      );
    }
    var found = false;
    final entries = [
      for (final entry in sheet.entries)
        if (entry.studentId == studentId)
          (() {
            found = true;
            return entry.copyWith(status: status, note: note?.trim());
          })()
        else
          entry,
    ];
    if (!found) {
      throw StateError(
        _message(
          uz: 'O‘quvchi topilmadi.',
          ru: 'Ученик не найден.',
          en: 'Student not found.',
        ),
      );
    }
    _attendanceSheets[index] = sheet.copyWith(entries: entries);
    notifyListeners();
    await _persist();
  }

  Future<void> submitAttendance(String sheetId) async {
    _requireCapability(StaffCapability.takeAttendance);
    final index = _indexById(_attendanceSheets, sheetId, (item) => item.id);
    final sheet = _attendanceSheets[index];
    if (!sheet.isComplete) {
      throw StateError(
        _message(
          uz: 'Barcha o‘quvchilar uchun holatni belgilang.',
          ru: 'Укажите статус для каждого ученика.',
          en: 'Choose a status for every student.',
        ),
      );
    }
    _attendanceSheets[index] = sheet.copyWith(submittedAt: _clock());
    notifyListeners();
    await _persist();
  }

  Future<RecognitionCard> issueCard({
    required String studentId,
    required String studentName,
    required String cohortName,
    required CardKind kind,
    required String label,
    required String reason,
  }) async {
    _requireCapability(StaffCapability.issueCards);
    final current = _requireSession();
    if (reason.trim().length < 4) {
      throw ArgumentError(
        _message(
          uz: 'Karta sababini aniqroq yozing.',
          ru: 'Опишите причину подробнее.',
          en: 'Describe the recognition reason more clearly.',
        ),
      );
    }
    final card = RecognitionCard(
      id: _newId('card'),
      studentId: studentId,
      studentName: studentName,
      cohortName: cohortName,
      kind: kind,
      label: label.trim(),
      reason: reason.trim(),
      issuedById: current.userId,
      issuedByName: current.displayName,
      issuedAt: _clock(),
    );
    _cards = [card, ..._cards];
    notifyListeners();
    await _persist();
    return card;
  }

  Future<ChatMessage> sendMessage(String threadId, String body) async {
    _requireCapability(StaffCapability.useStaffMessaging);
    final current = _requireSession();
    final cleanBody = body.trim();
    if (cleanBody.isEmpty) {
      throw ArgumentError(
        _message(
          uz: 'Xabar bo‘sh bo‘lishi mumkin emas.',
          ru: 'Сообщение не может быть пустым.',
          en: 'A message cannot be empty.',
        ),
      );
    }
    final index = _indexById(_messageThreads, threadId, (item) => item.id);
    final message = ChatMessage(
      id: _newId('message'),
      senderId: current.userId,
      senderName: current.displayName,
      body: cleanBody,
      sentAt: _clock(),
      readBy: {current.userId},
    );
    final thread = _messageThreads[index];
    _messageThreads[index] = thread.copyWith(
      messages: [...thread.messages, message],
    );
    notifyListeners();
    await _persist();
    return message;
  }

  Future<void> markThreadRead(String threadId) async {
    final current = _requireSession();
    final index = _indexById(_messageThreads, threadId, (item) => item.id);
    final thread = _messageThreads[index];
    _messageThreads[index] = thread.copyWith(
      messages: [
        for (final message in thread.messages)
          message.copyWith(readBy: {...message.readBy, current.userId}),
      ],
    );
    notifyListeners();
    await _persist();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = _indexById(_notifications, notificationId, (item) => item.id);
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    await _persist();
  }

  Future<void> markAllNotificationsRead() async {
    _notifications = [
      for (final item in _notifications) item.copyWith(isRead: true),
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> refreshForms() async {
    final api = _api;
    if (api == null || _session == null || _formsLoading) return;
    _formsLoading = true;
    _formsError = null;
    notifyListeners();
    try {
      final work = BackendWorkApi.fromApi(api);
      final result = await work.forms(status: 'published');
      if (result.isUnavailable) {
        _formsAvailable = false;
        _formsError = result.error?.message;
        _surveys = [];
        return;
      }
      _formsAvailable = true;
      final currentById = {for (final form in _surveys) form.id: form};
      final values = <SurveyAssignment>[];
      for (var form in result.value?.items ?? const <BackendForm>[]) {
        if (form.fields.isEmpty) {
          final detail = await work.form(form.id);
          if (detail.isAvailable && detail.value != null) {
            form = detail.value!;
          }
        }
        values.add(
          _surveyFromBackend(form, overlay: currentById['${form.id}']),
        );
      }
      _surveys = values;
      _lastSyncedAt = _clock();
      await _persist();
    } on ApiException catch (error) {
      _formsError = error.message;
      await _handleRemoteError(error);
    } on Object catch (error) {
      _formsError = error.toString();
    } finally {
      _formsLoading = false;
      notifyListeners();
    }
  }

  Future<void> answerSurvey(
    String surveyId,
    String questionId,
    String answer,
  ) async {
    _requireCapability(StaffCapability.answerSurveys);
    final index = _indexById(_surveys, surveyId, (item) => item.id);
    final survey = _surveys[index];
    if (survey.isSubmitted) {
      throw StateError(
        _message(
          uz: 'So‘rovnoma allaqachon yuborilgan.',
          ru: 'Опрос уже отправлен.',
          en: 'This survey has already been submitted.',
        ),
      );
    }
    final cleanAnswer = answer.trim();
    final answers = Map<String, String>.of(survey.answers);
    if (cleanAnswer.isEmpty) {
      answers.remove(questionId);
    } else {
      answers[questionId] = cleanAnswer;
    }
    _surveys[index] = survey.copyWith(answers: answers);
    notifyListeners();
    await _persist();
  }

  Future<void> submitSurvey(String surveyId) async {
    _requireCapability(StaffCapability.answerSurveys);
    final index = _indexById(_surveys, surveyId, (item) => item.id);
    final survey = _surveys[index];
    final missing = survey.questions.any(
      (question) =>
          question.required &&
          (survey.answers[question.id]?.trim().isEmpty ?? true),
    );
    if (missing) {
      throw StateError(
        _message(
          uz: 'Majburiy savollarga javob bering.',
          ru: 'Ответьте на обязательные вопросы.',
          en: 'Answer every required question.',
        ),
      );
    }
    final api = _api;
    if (api != null) {
      final formId = int.tryParse(survey.id);
      if (formId == null) {
        throw StateError('Invalid server form id: ${survey.id}');
      }
      try {
        final result = await BackendWorkApi.fromApi(api).submitForm(formId, [
          for (final question in survey.questions)
            if (survey.answers[question.id]?.trim().isNotEmpty == true)
              {
                'field': int.parse(question.id),
                'value': _surveyAnswerForBackend(
                  question,
                  survey.answers[question.id]!,
                ),
              },
        ]);
        if (result.isUnavailable || result.value == null) {
          throw StateError(
            result.error?.message ??
                _message(
                  uz: 'Bu so‘rovnomaga javob yuborib bo‘lmaydi.',
                  ru: 'Нельзя отправить ответ на эту форму.',
                  en: 'This form cannot accept your response.',
                ),
          );
        }
      } on ApiException catch (error) {
        if (error.statusCode != 409) {
          await _handleRemoteError(error);
          rethrow;
        }
      }
    }
    _surveys[index] = survey.copyWith(submittedAt: _clock());
    notifyListeners();
    await _persist();
  }

  Future<PrintJob> submitPrintJob({
    required String documentName,
    required String printerId,
    required String printerName,
    required int copies,
    required int pageCount,
  }) async {
    _requireCapability(StaffCapability.submitPrintJobs);
    final current = _requireSession();
    if (documentName.trim().isEmpty ||
        copies < 1 ||
        copies > 99 ||
        pageCount < 1) {
      throw ArgumentError(
        _message(
          uz: 'Print sozlamalarini tekshiring.',
          ru: 'Проверьте настройки печати.',
          en: 'Check the print settings.',
        ),
      );
    }
    final job = PrintJob(
      id: _newId('print'),
      documentName: documentName.trim(),
      printerId: printerId,
      printerName: printerName,
      requestedById: current.userId,
      requestedAt: _clock(),
      copies: copies,
      pageCount: pageCount,
      status: PrintJobStatus.queued,
      progress: 0,
    );
    _printJobs = [job, ..._printJobs];
    notifyListeners();
    await _persist();
    return job;
  }

  Future<void> updatePrintJob(
    String jobId, {
    required PrintJobStatus status,
    required double progress,
    String? failureReason,
  }) async {
    _requireCapability(StaffCapability.managePrintQueue);
    final index = _indexById(_printJobs, jobId, (item) => item.id);
    _printJobs[index] = _printJobs[index].copyWith(
      status: status,
      progress: progress.clamp(0, 1).toDouble(),
      failureReason: failureReason,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> cancelPrintJob(String jobId) async {
    final current = _requireSession();
    final index = _indexById(_printJobs, jobId, (item) => item.id);
    final job = _printJobs[index];
    if (job.requestedById != current.userId &&
        !can(StaffCapability.managePrintQueue)) {
      throw StateError(
        _message(
          uz: 'Bu print ishini bekor qilishga ruxsat yo‘q.',
          ru: 'Нет разрешения на отмену этой печати.',
          en: 'You do not have permission to cancel this print job.',
        ),
      );
    }
    if (job.status == PrintJobStatus.completed) {
      throw StateError(
        _message(
          uz: 'Tugagan ishni bekor qilib bo‘lmaydi.',
          ru: 'Завершённую печать нельзя отменить.',
          en: 'A completed print job cannot be cancelled.',
        ),
      );
    }
    _printJobs[index] = job.copyWith(
      status: PrintJobStatus.cancelled,
      progress: 0,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> retryPrintJob(String jobId) async {
    final current = _requireSession();
    final index = _indexById(_printJobs, jobId, (item) => item.id);
    final job = _printJobs[index];
    if (job.requestedById != current.userId &&
        !can(StaffCapability.managePrintQueue)) {
      throw StateError(
        _message(
          uz: 'Bu print ishini qayta yuborishga ruxsat yo‘q.',
          ru: 'Нет разрешения на повтор этой печати.',
          en: 'You do not have permission to retry this print job.',
        ),
      );
    }
    if (job.status != PrintJobStatus.failed &&
        job.status != PrintJobStatus.cancelled) {
      throw StateError(
        _message(
          uz: 'Faqat xato yoki bekor qilingan ish qayta yuboriladi.',
          ru: 'Повторить можно только ошибочную или отменённую печать.',
          en: 'Only failed or cancelled print jobs can be retried.',
        ),
      );
    }
    _printJobs[index] = job.copyWith(
      status: PrintJobStatus.queued,
      progress: 0,
      failureReason: null,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> acknowledgeAnomaly(String anomalyId) async {
    _requireCapability(StaffCapability.reviewAnomalies);
    final current = _requireSession();
    final index = _indexById(_auditAnomalies, anomalyId, (item) => item.id);
    _auditAnomalies[index] = _auditAnomalies[index].copyWith(
      status: AnomalyStatus.acknowledged,
      acknowledgedById: current.userId,
    );
    notifyListeners();
    await _persist();
  }

  Future<AuditCase> createAuditCase({
    required String title,
    required String description,
    required AuditSeverity severity,
    Iterable<String> anomalyIds = const [],
  }) async {
    _requireCapability(StaffCapability.manageAuditCases);
    final current = _requireSession();
    if (title.trim().length < 4) {
      throw ArgumentError(
        _message(
          uz: 'Holat sarlavhasini to‘ldiring.',
          ru: 'Введите название кейса.',
          en: 'Enter a case title.',
        ),
      );
    }
    final item = AuditCase(
      id: _newId('case'),
      title: title.trim(),
      description: description.trim(),
      severity: severity,
      status: AuditCaseStatus.open,
      openedById: current.userId,
      openedAt: _clock(),
      anomalyIds: anomalyIds,
      notes: const [],
    );
    _auditCases = [item, ..._auditCases];
    _auditAnomalies = [
      for (final anomaly in _auditAnomalies)
        if (anomalyIds.contains(anomaly.id))
          anomaly.copyWith(
            status: AnomalyStatus.linked,
            acknowledgedById: current.userId,
          )
        else
          anomaly,
    ];
    notifyListeners();
    await _persist();
    return item;
  }

  Future<void> addAuditCaseNote(String caseId, String note) async {
    _requireCapability(StaffCapability.manageAuditCases);
    if (note.trim().isEmpty) {
      throw ArgumentError(
        _message(
          uz: 'Izoh bo‘sh bo‘lishi mumkin emas.',
          ru: 'Комментарий не может быть пустым.',
          en: 'A note cannot be empty.',
        ),
      );
    }
    final index = _indexById(_auditCases, caseId, (item) => item.id);
    final item = _auditCases[index];
    _auditCases[index] = item.copyWith(notes: [...item.notes, note.trim()]);
    notifyListeners();
    await _persist();
  }

  Future<void> setAuditCaseStatus(String caseId, AuditCaseStatus status) async {
    _requireCapability(StaffCapability.manageAuditCases);
    final index = _indexById(_auditCases, caseId, (item) => item.id);
    final item = _auditCases[index];
    _auditCases[index] = item.copyWith(
      status: status,
      resolvedAt:
          status == AuditCaseStatus.resolved ||
              status == AuditCaseStatus.dismissed
          ? _clock()
          : null,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> resetDemoData({bool keepSession = true}) async {
    if (_api != null) {
      throw StateError(
        _message(
          uz: 'Demo ma’lumotlari production rejimida mavjud emas.',
          ru: 'Демо-данные недоступны в рабочем режиме.',
          en: 'Demo data is unavailable in production mode.',
        ),
      );
    }
    final currentSession = keepSession ? _session : null;
    final currentSettings = _settings;
    final seed = DemoSeed.snapshot();
    _session = currentSession;
    _settings = currentSettings;
    _tasks = seed.tasks.toList();
    _attendanceSheets = seed.attendanceSheets.toList();
    _cards = seed.cards.toList();
    _messageThreads = seed.messageThreads.toList();
    _notifications = seed.notifications.toList();
    _surveys = seed.surveys.toList();
    _printJobs = seed.printJobs.toList();
    _auditAnomalies = seed.auditAnomalies.toList();
    _auditCases = seed.auditCases.toList();
    notifyListeners();
    await _persist();
  }

  StaffSession _requireSession() {
    final value = _session;
    if (value == null) {
      throw StateError(
        _message(
          uz: 'Avval tizimga kiring.',
          ru: 'Сначала войдите в систему.',
          en: 'Sign in first.',
        ),
      );
    }
    return value;
  }

  StaffSession _sessionFromIdentity(AuthenticatedIdentity identity) {
    final profile = identity.profile;
    final principalKind = apiString(profile['principal_kind']);
    final memberships = apiMaps(profile['role_memberships']);
    final slugs = memberships
        .map(
          (item) => apiString(
            item['account_type_slug'],
            fallback: apiString(item['legacy_role']),
          ).toLowerCase(),
        )
        .where((value) => value.isNotEmpty)
        .toSet();
    if (principalKind != 'teacher' && principalKind != 'staff') {
      throw const ApiException(
        message: 'Bu ilova faqat o‘qituvchi va xodimlar uchun.',
        statusCode: 403,
        code: 'staff_app_only',
      );
    }
    const blockedFragments = {'ceo', 'owner', 'director', 'manager'};
    if (slugs.any(
      (slug) => blockedFragments.any((blocked) => slug.contains(blocked)),
    )) {
      throw const ApiException(
        message: 'Rahbar hisobi bu xodimlar ilovasida ishlamaydi.',
        statusCode: 403,
        code: 'staff_app_only',
      );
    }
    final primarySlug = slugs.isEmpty ? principalKind : slugs.first;
    final role = principalKind == 'teacher'
        ? StaffRole.teacher
        : _staffRoleFor(primarySlug);
    final membership = memberships.firstOrNull;
    final branchId = apiString(
      profile['branch'],
      fallback: apiString(membership?['branch']),
    );
    final fullName = apiString(profile['full_name']);
    final fallbackName = [
      apiString(profile['first_name']),
      apiString(profile['last_name']),
    ].where((value) => value.isNotEmpty).join(' ');
    return StaffSession(
      userId: apiString(profile['id']),
      displayName: fullName.isNotEmpty
          ? fullName
          : fallbackName.isNotEmpty
          ? fallbackName
          : apiString(profile['username'], fallback: 'Staff'),
      role: role,
      branchId: branchId,
      branchName: identity.connection.name,
      email: apiString(profile['email']),
      username: apiString(profile['username']),
      phone: apiString(profile['phone']),
      accountTypeSlug: primarySlug,
      mustChangePassword:
          identity.mustChangePassword ||
          apiBool(profile['must_change_password']),
      isRemote: true,
    );
  }

  StaffRole _staffRoleFor(String slug) {
    if (slug.contains('audit') || slug.contains('compliance')) {
      return StaffRole.auditor;
    }
    if (slug.contains('method') ||
        slug.contains('academic') ||
        slug.contains('quality')) {
      return StaffRole.methodist;
    }
    if (slug.contains('reception') ||
        slug.contains('registr') ||
        slug.contains('admission') ||
        slug.contains('cashier') ||
        slug.contains('account')) {
      return StaffRole.reception;
    }
    return StaffRole.assistant;
  }

  StaffTask _staffTaskFromBackend(BackendTask value, {StaffTask? overlay}) {
    final current = _session;
    final assigneeId = '${value.assigneeId ?? current?.userId ?? ''}';
    final creatorId = '${value.createdBy ?? current?.userId ?? ''}';
    return StaffTask(
      id: '${value.id}',
      title: value.title,
      description: value.description,
      status: _taskStatusFromBackend(value.status),
      priority: _taskPriorityFromBackend(value.priority),
      creatorId: creatorId,
      creatorName: creatorId == current?.userId
          ? current!.displayName
          : creatorId.isEmpty
          ? 'StarForge staff'
          : 'Staff #$creatorId',
      assigneeId: assigneeId,
      assigneeName: assigneeId == current?.userId
          ? current!.displayName
          : assigneeId.isEmpty
          ? 'Unassigned'
          : 'Staff #$assigneeId',
      dueAt:
          value.dueAt ??
          value.createdAt?.add(const Duration(days: 2)) ??
          _clock().add(const Duration(days: 2)),
      createdAt: value.createdAt ?? _clock(),
      checklist: overlay?.checklist ?? const [],
      tags: overlay?.tags ?? const [],
      comments: overlay?.comments ?? const [],
      isFavorite: overlay?.isFavorite ?? false,
    );
  }

  TaskStatus _taskStatusFromBackend(String value) => switch (value) {
    'in_progress' => TaskStatus.inProgress,
    'blocked' => TaskStatus.inReview,
    'done' || 'cancelled' => TaskStatus.done,
    _ => TaskStatus.todo,
  };

  String _backendTaskStatus(TaskStatus value) => switch (value) {
    TaskStatus.todo => 'open',
    TaskStatus.inProgress => 'in_progress',
    TaskStatus.inReview => 'blocked',
    TaskStatus.done => 'done',
  };

  TaskPriority _taskPriorityFromBackend(String value) => switch (value) {
    'low' => TaskPriority.low,
    'high' => TaskPriority.high,
    'urgent' => TaskPriority.urgent,
    _ => TaskPriority.medium,
  };

  String _backendTaskPriority(TaskPriority value) => switch (value) {
    TaskPriority.low => 'low',
    TaskPriority.medium => 'normal',
    TaskPriority.high => 'high',
    TaskPriority.urgent => 'urgent',
  };

  SurveyAssignment _surveyFromBackend(
    BackendForm value, {
    SurveyAssignment? overlay,
  }) => SurveyAssignment(
    id: '${value.id}',
    title: value.title,
    summary: value.description,
    dueAt: value.closesAt ?? _clock().add(const Duration(days: 7)),
    questions: [
      for (final field in value.fields)
        SurveyQuestion(
          id: '${field.id}',
          prompt: field.label,
          kind: _surveyKindFromBackend(field.fieldType),
          options: switch (field.fieldType) {
            'boolean' => const ['true', 'false'],
            'rating' when field.options.isEmpty => const [
              '1',
              '2',
              '3',
              '4',
              '5',
            ],
            _ => field.options.map((item) => item.toString()),
          },
          required: field.required,
        ),
    ],
    answers: overlay?.answers ?? const {},
    submittedAt: overlay?.submittedAt,
  );

  SurveyQuestionKind _surveyKindFromBackend(String value) => switch (value) {
    'single_choice' => SurveyQuestionKind.singleChoice,
    'multi_choice' => SurveyQuestionKind.multiChoice,
    'number' => SurveyQuestionKind.number,
    'boolean' => SurveyQuestionKind.boolean,
    'rating' => SurveyQuestionKind.rating,
    'date' => SurveyQuestionKind.date,
    _ => SurveyQuestionKind.freeText,
  };

  Object _surveyAnswerForBackend(SurveyQuestion question, String answer) =>
      switch (question.kind) {
        SurveyQuestionKind.number => num.tryParse(answer) ?? answer,
        SurveyQuestionKind.boolean => answer.toLowerCase() == 'true',
        SurveyQuestionKind.rating => int.tryParse(answer) ?? answer,
        SurveyQuestionKind.multiChoice =>
          answer.split('\u001f').where((item) => item.isNotEmpty).toList(),
        _ => answer,
      };

  Future<void> _handleRemoteError(ApiException error) async {
    if (error.statusCode == 401) {
      await _expireRemoteSession();
    }
    if (error.code != 'invalid_credentials') {
      _syncError = error.message;
    }
    notifyListeners();
  }

  bool canUpdateTask(StaffTask task) {
    final current = _session;
    if (current == null || !current.can(StaffCapability.updateOwnTasks)) {
      return false;
    }
    return task.assigneeId == current.userId ||
        task.creatorId == current.userId ||
        current.can(StaffCapability.assignTasks);
  }

  void _requireTaskUpdatePermission(StaffTask task) {
    if (canUpdateTask(task)) return;
    throw StateError(
      _message(
        uz: 'Faqat o‘zingizga tegishli vazifani o‘zgartira olasiz.',
        ru: 'Можно изменять только свои задачи.',
        en: 'You can only update tasks assigned to or created by you.',
      ),
    );
  }

  void _requireCapability(StaffCapability capability) {
    if (!can(capability)) {
      throw StateError(
        _message(
          uz: 'Bu amal uchun ruxsat yo‘q.',
          ru: 'Нет разрешения на это действие.',
          en: 'You do not have permission for this action.',
        ),
      );
    }
  }

  String _newId(String prefix) =>
      '$prefix-${_clock().toUtc().microsecondsSinceEpoch}-${_idCounter++}';

  int _indexById<T>(List<T> values, String id, String Function(T) idOf) {
    final index = values.indexWhere((value) => idOf(value) == id);
    if (index < 0) {
      throw StateError(
        _message(
          uz: 'Ma’lumot topilmadi: $id',
          ru: 'Данные не найдены: $id',
          en: 'Record not found: $id',
        ),
      );
    }
    return index;
  }

  String _message({
    required String uz,
    required String ru,
    required String en,
  }) => switch (_settings.locale) {
    AppLocale.uz => uz,
    AppLocale.ru => ru,
    AppLocale.en => en,
  };

  AppSnapshot _snapshotForPersistence() => AppSnapshot(
    session: _api == null && _persistSession ? _session : null,
    settings: _settings,
    tasks: _tasks,
    attendanceSheets: _attendanceSheets,
    cards: _cards,
    messageThreads: _messageThreads,
    notifications: _notifications,
    surveys: _surveys,
    printJobs: _printJobs,
    auditAnomalies: _auditAnomalies,
    auditCases: _auditCases,
  );

  Future<void> _persist() async {
    _isPersisting = true;
    _persistenceError = null;
    notifyListeners();
    try {
      await _storage.write(
        _snapshotKey,
        jsonEncode(_snapshotForPersistence().toJson()),
      );
    } on Object catch (error) {
      _persistenceError = 'O‘zgarish qurilmaga saqlanmadi: $error';
    } finally {
      _isPersisting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final messaging = _productionMessaging;
    final notifications = _productionNotifications;
    messaging?.removeListener(_notifyFromBackendWork);
    notifications?.removeListener(_notifyFromBackendWork);
    messaging?.dispose();
    notifications?.dispose();
    super.dispose();
  }
}
