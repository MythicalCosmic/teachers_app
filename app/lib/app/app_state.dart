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

  Future<void> retryPersistence() => _persist();

  void clearPersistenceError() {
    if (_persistenceError == null) return;
    _persistenceError = null;
    notifyListeners();
  }

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
