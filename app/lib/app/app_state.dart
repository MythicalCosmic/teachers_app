import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/app_storage.dart';
import '../data/demo_seed.dart';
import '../data/models.dart';

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
  bool _isPersisting = false;
  String? _persistenceError;
  int _idCounter = 0;

  static Future<AppState> bootstrap({
    AppStorage? storage,
    DateTime Function()? clock,
  }) async {
    final resolvedStorage =
        storage ?? await SharedPreferencesAppStorage.create();
    final resolvedClock = clock ?? DateTime.now;
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
    return AppState._(
      storage: resolvedStorage,
      clock: resolvedClock,
      snapshot: snapshot,
      bootstrapError: error,
    );
  }

  bool get isInitialized => true;
  bool get isPersisting => _isPersisting;
  String? get persistenceError => _persistenceError;
  StaffSession? get session => _session;
  AppSettings get settings => _settings;
  List<StaffTask> get tasks => List.unmodifiable(_tasks);
  List<AttendanceSheet> get attendanceSheets =>
      List.unmodifiable(_attendanceSheets);
  List<RecognitionCard> get cards => List.unmodifiable(_cards);
  List<MessageThread> get messageThreads => List.unmodifiable(_messageThreads);
  List<StaffNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<SurveyAssignment> get surveys => List.unmodifiable(_surveys);
  List<PrintJob> get printJobs => List.unmodifiable(_printJobs);
  List<AuditAnomaly> get auditAnomalies => List.unmodifiable(_auditAnomalies);
  List<AuditCase> get auditCases => List.unmodifiable(_auditCases);

  int get unreadMessageCount {
    final userId = _session?.userId;
    if (userId == null) return 0;
    return _messageThreads.fold(
      0,
      (sum, thread) => sum + thread.unreadCountFor(userId),
    );
  }

  int get unreadNotificationCount =>
      _notifications.where((item) => !item.isRead).length;

  bool can(StaffCapability capability) => _session?.can(capability) ?? false;

  Future<StaffSession> signIn({
    required String username,
    required String password,
    bool persistSession = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final authenticated = DemoSeed.authenticate(username, password);
    if (authenticated == null) {
      throw const AuthenticationException(
        'Foydalanuvchi nomi yoki parol noto‘g‘ri.',
      );
    }
    _session = authenticated;
    _persistSession = persistSession;
    notifyListeners();
    await _persist();
    return authenticated;
  }

  Future<void> signOut() async {
    _session = null;
    _persistSession = true;
    notifyListeners();
    await _persist();
  }

  Future<void> updateProfile({
    required String displayName,
    required String email,
  }) async {
    final current = _requireSession();
    final cleanName = displayName.trim();
    final cleanEmail = email.trim();
    if (cleanName.length < 3 || !cleanEmail.contains('@')) {
      throw ArgumentError('Ism va email manzilini to‘g‘ri kiriting.');
    }
    _session = StaffSession(
      userId: current.userId,
      displayName: cleanName,
      role: current.role,
      branchId: current.branchId,
      branchName: current.branchName,
      email: cleanEmail,
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
  Future<void> setLocale(AppLocale value) =>
      updateSettings(_settings.copyWith(locale: value));
  Future<void> setLiquidGlass(bool value) =>
      updateSettings(_settings.copyWith(liquidGlass: value));
  Future<void> setReducedMotion(bool value) =>
      updateSettings(_settings.copyWith(reducedMotion: value));
  Future<void> setHaptics(bool value) =>
      updateSettings(_settings.copyWith(haptics: value));
  Future<void> setCoachMarks(bool value) =>
      updateSettings(_settings.copyWith(coachMarks: value));
  Future<void> completeWelcome() =>
      updateSettings(_settings.copyWith(hasCompletedWelcome: true));

  Future<StaffTask> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
    String? assigneeId,
    String? assigneeName,
    Iterable<String> checklist = const [],
  }) async {
    _requireCapability(StaffCapability.createTasks);
    final current = _requireSession();
    final cleanTitle = title.trim();
    if (cleanTitle.length < 3) {
      throw ArgumentError('Vazifa sarlavhasi juda qisqa.');
    }
    final now = _clock();
    final task = StaffTask(
      id: _newId('task'),
      title: cleanTitle,
      description: description.trim(),
      status: TaskStatus.todo,
      priority: priority,
      creatorId: current.userId,
      creatorName: current.displayName,
      assigneeId: assigneeId ?? current.userId,
      assigneeName: assigneeName ?? current.displayName,
      dueAt: dueAt ?? now.add(const Duration(days: 2)),
      createdAt: now,
      checklist: [
        for (final entry in checklist.where((value) => value.trim().isNotEmpty))
          TaskChecklistItem(id: _newId('step'), title: entry.trim()),
      ],
    );
    _tasks = [task, ..._tasks];
    notifyListeners();
    await _persist();
    return task;
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    _requireCapability(StaffCapability.updateOwnTasks);
    final index = _indexById(_tasks, taskId, (item) => item.id);
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
    final items = [
      for (final item in task.checklist)
        item.id == checklistId ? item.copyWith(isDone: !item.isDone) : item,
    ];
    _tasks[index] = task.copyWith(checklist: items);
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
      throw StateError('Yuborilgan davomatni tahrirlab bo‘lmaydi.');
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
    if (!found) throw StateError('O‘quvchi topilmadi.');
    _attendanceSheets[index] = sheet.copyWith(entries: entries);
    notifyListeners();
    await _persist();
  }

  Future<void> submitAttendance(String sheetId) async {
    _requireCapability(StaffCapability.takeAttendance);
    final index = _indexById(_attendanceSheets, sheetId, (item) => item.id);
    final sheet = _attendanceSheets[index];
    if (!sheet.isComplete) {
      throw StateError('Barcha o‘quvchilar uchun holatni belgilang.');
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
      throw ArgumentError('Karta sababini aniqroq yozing.');
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
      throw ArgumentError('Xabar bo‘sh bo‘lishi mumkin emas.');
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

  Future<void> answerSurvey(
    String surveyId,
    String questionId,
    String answer,
  ) async {
    _requireCapability(StaffCapability.answerSurveys);
    final index = _indexById(_surveys, surveyId, (item) => item.id);
    final survey = _surveys[index];
    if (survey.isSubmitted) {
      throw StateError('So‘rovnoma allaqachon yuborilgan.');
    }
    _surveys[index] = survey.copyWith(
      answers: {...survey.answers, questionId: answer.trim()},
    );
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
    if (missing) throw StateError('Majburiy savollarga javob bering.');
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
      throw ArgumentError('Print sozlamalarini tekshiring.');
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
      throw StateError('Bu print ishini bekor qilishga ruxsat yo‘q.');
    }
    if (job.status == PrintJobStatus.completed) {
      throw StateError('Tugagan ishni bekor qilib bo‘lmaydi.');
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
      throw StateError('Bu print ishini qayta yuborishga ruxsat yo‘q.');
    }
    if (job.status != PrintJobStatus.failed &&
        job.status != PrintJobStatus.cancelled) {
      throw StateError('Faqat xato yoki bekor qilingan ish qayta yuboriladi.');
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
      throw ArgumentError('Holat sarlavhasini to‘ldiring.');
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
      throw ArgumentError('Izoh bo‘sh bo‘lishi mumkin emas.');
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
    if (value == null) throw StateError('Avval tizimga kiring.');
    return value;
  }

  void _requireCapability(StaffCapability capability) {
    if (!can(capability)) throw StateError('Bu amal uchun ruxsat yo‘q.');
  }

  String _newId(String prefix) =>
      '$prefix-${_clock().toUtc().microsecondsSinceEpoch}-${_idCounter++}';

  int _indexById<T>(List<T> values, String id, String Function(T) idOf) {
    final index = values.indexWhere((value) => idOf(value) == id);
    if (index < 0) throw StateError('Ma’lumot topilmadi: $id');
    return index;
  }

  AppSnapshot _snapshotForPersistence() => AppSnapshot(
    session: _persistSession ? _session : null,
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
}
