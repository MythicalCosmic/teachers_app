import 'dart:collection';

typedef JsonMap = Map<String, Object?>;

const Object _unset = Object();

T _enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
  return values.where((value) => value.name == raw).firstOrNull ?? fallback;
}

DateTime _date(Object? raw) {
  final parsed = DateTime.tryParse(raw?.toString() ?? '');
  if (parsed == null) throw const FormatException('Invalid persisted date.');
  return parsed.toUtc();
}

List<JsonMap> _maps(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((value) => Map<String, Object?>.from(value))
      .toList(growable: false);
}

enum StaffRole { teacher, assistant, methodist, reception, auditor }

enum StaffCapability {
  viewToday,
  viewCohorts,
  teachLessons,
  takeAttendance,
  issueCards,
  createTasks,
  updateOwnTasks,
  assignTasks,
  useStaffMessaging,
  answerSurveys,
  manageSurveys,
  submitPrintJobs,
  managePrintQueue,
  viewQualityWorkspace,
  reviewTeacherQuality,
  viewLeads,
  manageAdmissions,
  viewPaymentStatus,
  sendPaymentReminder,
  viewAuditWorkspace,
  reviewAnomalies,
  manageAuditCases,
  viewImmutableAuditLog,
  exportAuditData,
}

extension StaffRoleAccess on StaffRole {
  String get label => switch (this) {
    StaffRole.teacher => 'Teacher',
    StaffRole.assistant => 'Assistant',
    StaffRole.methodist => 'Methodist',
    StaffRole.reception => 'Reception',
    StaffRole.auditor => 'Auditor',
  };

  String get uzLabel => switch (this) {
    StaffRole.teacher => 'O‘qituvchi',
    StaffRole.assistant => 'Yordamchi',
    StaffRole.methodist => 'Metodist',
    StaffRole.reception => 'Qabulxona',
    StaffRole.auditor => 'Auditor',
  };

  Set<StaffCapability> get capabilities => switch (this) {
    StaffRole.teacher => const {
      StaffCapability.viewToday,
      StaffCapability.viewCohorts,
      StaffCapability.teachLessons,
      StaffCapability.takeAttendance,
      StaffCapability.issueCards,
      StaffCapability.createTasks,
      StaffCapability.updateOwnTasks,
      StaffCapability.useStaffMessaging,
      StaffCapability.answerSurveys,
      StaffCapability.submitPrintJobs,
    },
    StaffRole.assistant => const {
      StaffCapability.viewToday,
      StaffCapability.viewCohorts,
      StaffCapability.takeAttendance,
      StaffCapability.createTasks,
      StaffCapability.updateOwnTasks,
      StaffCapability.useStaffMessaging,
      StaffCapability.answerSurveys,
      StaffCapability.submitPrintJobs,
    },
    StaffRole.methodist => const {
      StaffCapability.viewToday,
      StaffCapability.viewCohorts,
      StaffCapability.createTasks,
      StaffCapability.updateOwnTasks,
      StaffCapability.assignTasks,
      StaffCapability.useStaffMessaging,
      StaffCapability.answerSurveys,
      StaffCapability.manageSurveys,
      StaffCapability.submitPrintJobs,
      StaffCapability.viewQualityWorkspace,
      StaffCapability.reviewTeacherQuality,
    },
    StaffRole.reception => const {
      StaffCapability.viewToday,
      StaffCapability.takeAttendance,
      StaffCapability.createTasks,
      StaffCapability.updateOwnTasks,
      StaffCapability.assignTasks,
      StaffCapability.useStaffMessaging,
      StaffCapability.answerSurveys,
      StaffCapability.submitPrintJobs,
      StaffCapability.managePrintQueue,
      StaffCapability.viewLeads,
      StaffCapability.manageAdmissions,
      StaffCapability.viewPaymentStatus,
      StaffCapability.sendPaymentReminder,
    },
    StaffRole.auditor => const {
      StaffCapability.viewToday,
      StaffCapability.createTasks,
      StaffCapability.updateOwnTasks,
      StaffCapability.useStaffMessaging,
      StaffCapability.answerSurveys,
      StaffCapability.submitPrintJobs,
      StaffCapability.viewAuditWorkspace,
      StaffCapability.reviewAnomalies,
      StaffCapability.manageAuditCases,
      StaffCapability.viewImmutableAuditLog,
      StaffCapability.exportAuditData,
    },
  };

  bool can(StaffCapability capability) => capabilities.contains(capability);
}

enum AppThemeMode { system, light, dark }

enum AppPalette { daryo, saroy, marvarid, samarqand }

enum AppLocale { uz, ru, en }

/// The surface language used across cards, navigation and overlays.
///
/// `classic` intentionally remains the default so existing installations keep
/// their familiar StarForge look until a member of staff opts into another
/// expression.
enum AppVisualStyle {
  classic,
  glassmorphism,
  claymorphism,
  liquidGlass,
  maximalism,
}

enum AppFontChoice { manrope, system, editorial, mono }

enum AppLayoutDensity { compact, comfortable, spacious }

final class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.light,
    this.palette = AppPalette.daryo,
    this.locale = AppLocale.uz,
    this.hasCompletedWelcome = false,
    this.liquidGlass = true,
    this.reducedMotion = false,
    this.haptics = true,
    this.coachMarks = true,
    this.visualStyle = AppVisualStyle.classic,
    this.fontChoice = AppFontChoice.manrope,
    this.layoutDensity = AppLayoutDensity.comfortable,
    this.surfaceOpacity = 1,
    this.navigationOpacity = 0.78,
    this.motionIntensity = 1,
  });

  final AppThemeMode themeMode;
  final AppPalette palette;
  final AppLocale locale;
  final bool hasCompletedWelcome;
  final bool liquidGlass;
  final bool reducedMotion;
  final bool haptics;
  final bool coachMarks;
  final AppVisualStyle visualStyle;
  final AppFontChoice fontChoice;
  final AppLayoutDensity layoutDensity;
  final double surfaceOpacity;
  final double navigationOpacity;
  final double motionIntensity;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppPalette? palette,
    AppLocale? locale,
    bool? hasCompletedWelcome,
    bool? liquidGlass,
    bool? reducedMotion,
    bool? haptics,
    bool? coachMarks,
    AppVisualStyle? visualStyle,
    AppFontChoice? fontChoice,
    AppLayoutDensity? layoutDensity,
    double? surfaceOpacity,
    double? navigationOpacity,
    double? motionIntensity,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      locale: locale ?? this.locale,
      hasCompletedWelcome: hasCompletedWelcome ?? this.hasCompletedWelcome,
      liquidGlass: liquidGlass ?? this.liquidGlass,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      haptics: haptics ?? this.haptics,
      coachMarks: coachMarks ?? this.coachMarks,
      visualStyle: visualStyle ?? this.visualStyle,
      fontChoice: fontChoice ?? this.fontChoice,
      layoutDensity: layoutDensity ?? this.layoutDensity,
      surfaceOpacity: (surfaceOpacity ?? this.surfaceOpacity)
          .clamp(0.45, 1)
          .toDouble(),
      navigationOpacity: (navigationOpacity ?? this.navigationOpacity)
          .clamp(0.45, 1)
          .toDouble(),
      motionIntensity: (motionIntensity ?? this.motionIntensity)
          .clamp(0.65, 1.35)
          .toDouble(),
    );
  }

  JsonMap toJson() => {
    'themeMode': themeMode.name,
    'palette': palette.name,
    'locale': locale.name,
    'hasCompletedWelcome': hasCompletedWelcome,
    'liquidGlass': liquidGlass,
    'reducedMotion': reducedMotion,
    'haptics': haptics,
    'coachMarks': coachMarks,
    'visualStyle': visualStyle.name,
    'fontChoice': fontChoice.name,
    'layoutDensity': layoutDensity.name,
    'surfaceOpacity': surfaceOpacity,
    'navigationOpacity': navigationOpacity,
    'motionIntensity': motionIntensity,
  };

  factory AppSettings.fromJson(JsonMap json) => AppSettings(
    themeMode: _enumValue(
      AppThemeMode.values,
      json['themeMode'],
      AppThemeMode.light,
    ),
    palette: _enumValue(AppPalette.values, json['palette'], AppPalette.daryo),
    locale: _enumValue(AppLocale.values, json['locale'], AppLocale.uz),
    hasCompletedWelcome: json['hasCompletedWelcome'] as bool? ?? false,
    liquidGlass: json['liquidGlass'] as bool? ?? true,
    reducedMotion: json['reducedMotion'] as bool? ?? false,
    haptics: json['haptics'] as bool? ?? true,
    coachMarks: json['coachMarks'] as bool? ?? true,
    visualStyle: _enumValue(
      AppVisualStyle.values,
      json['visualStyle'],
      AppVisualStyle.classic,
    ),
    fontChoice: _enumValue(
      AppFontChoice.values,
      json['fontChoice'],
      AppFontChoice.manrope,
    ),
    layoutDensity: _enumValue(
      AppLayoutDensity.values,
      json['layoutDensity'],
      AppLayoutDensity.comfortable,
    ),
    surfaceOpacity: ((json['surfaceOpacity'] as num?)?.toDouble() ?? 1)
        .clamp(0.45, 1)
        .toDouble(),
    navigationOpacity: ((json['navigationOpacity'] as num?)?.toDouble() ?? 0.78)
        .clamp(0.45, 1)
        .toDouble(),
    motionIntensity: ((json['motionIntensity'] as num?)?.toDouble() ?? 1)
        .clamp(0.65, 1.35)
        .toDouble(),
  );
}

final class StaffSession {
  const StaffSession({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.branchId,
    required this.branchName,
    required this.email,
    this.username = '',
    this.phone = '',
    this.bio = '',
    this.avatarColorValue = 0,
    this.accountTypeSlug = '',
    this.mustChangePassword = false,
    this.isRemote = false,
  });

  final String userId;
  final String displayName;
  final StaffRole role;
  final String branchId;
  final String branchName;
  final String email;
  final String username;
  final String phone;
  final String bio;
  final int avatarColorValue;
  final String accountTypeSlug;
  final bool mustChangePassword;
  final bool isRemote;

  bool can(StaffCapability capability) => role.can(capability);

  JsonMap toJson() => {
    'userId': userId,
    'displayName': displayName,
    'role': role.name,
    'branchId': branchId,
    'branchName': branchName,
    'email': email,
    'username': username,
    'phone': phone,
    'bio': bio,
    'avatarColorValue': avatarColorValue,
    'accountTypeSlug': accountTypeSlug,
    'mustChangePassword': mustChangePassword,
    'isRemote': isRemote,
  };

  factory StaffSession.fromJson(JsonMap json) => StaffSession(
    userId: json['userId']! as String,
    displayName: json['displayName']! as String,
    role: _enumValue(StaffRole.values, json['role'], StaffRole.teacher),
    branchId: json['branchId']! as String,
    branchName: json['branchName']! as String,
    email: json['email']! as String,
    username: json['username'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    avatarColorValue: json['avatarColorValue'] as int? ?? 0,
    accountTypeSlug: json['accountTypeSlug'] as String? ?? '',
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    isRemote: json['isRemote'] as bool? ?? false,
  );
}

enum TaskStatus { todo, inProgress, inReview, done }

enum TaskPriority { low, medium, high, urgent }

final class TaskChecklistItem {
  const TaskChecklistItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  final String id;
  final String title;
  final bool isDone;

  TaskChecklistItem copyWith({bool? isDone}) =>
      TaskChecklistItem(id: id, title: title, isDone: isDone ?? this.isDone);

  JsonMap toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory TaskChecklistItem.fromJson(JsonMap json) => TaskChecklistItem(
    id: json['id']! as String,
    title: json['title']! as String,
    isDone: json['isDone'] as bool? ?? false,
  );
}

final class TaskComment {
  const TaskComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  JsonMap toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'body': body,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory TaskComment.fromJson(JsonMap json) => TaskComment(
    id: json['id']! as String,
    authorId: json['authorId']! as String,
    authorName: json['authorName']! as String,
    body: json['body']! as String,
    createdAt: _date(json['createdAt']),
  );
}

final class StaffTask {
  StaffTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.creatorId,
    required this.creatorName,
    required this.assigneeId,
    required this.assigneeName,
    required this.dueAt,
    required this.createdAt,
    required Iterable<TaskChecklistItem> checklist,
    Iterable<String> tags = const [],
    Iterable<TaskComment> comments = const [],
    this.isFavorite = false,
  }) : checklist = List.unmodifiable(checklist),
       tags = List.unmodifiable(tags),
       comments = List.unmodifiable(comments);

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String creatorId;
  final String creatorName;
  final String assigneeId;
  final String assigneeName;
  final DateTime dueAt;
  final DateTime createdAt;
  final List<TaskChecklistItem> checklist;
  final List<String> tags;
  final List<TaskComment> comments;
  final bool isFavorite;

  int get completedSteps => checklist.where((item) => item.isDone).length;

  StaffTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    String? assigneeName,
    DateTime? dueAt,
    Iterable<TaskChecklistItem>? checklist,
    Iterable<String>? tags,
    Iterable<TaskComment>? comments,
    bool? isFavorite,
  }) {
    return StaffTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      creatorId: creatorId,
      creatorName: creatorName,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt,
      checklist: checklist ?? this.checklist,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'assigneeId': assigneeId,
    'assigneeName': assigneeName,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'checklist': checklist.map((item) => item.toJson()).toList(),
    'tags': tags,
    'comments': comments.map((item) => item.toJson()).toList(),
    'isFavorite': isFavorite,
  };

  factory StaffTask.fromJson(JsonMap json) => StaffTask(
    id: json['id']! as String,
    title: json['title']! as String,
    description: json['description'] as String? ?? '',
    status: _enumValue(TaskStatus.values, json['status'], TaskStatus.todo),
    priority: _enumValue(
      TaskPriority.values,
      json['priority'],
      TaskPriority.medium,
    ),
    creatorId: json['creatorId']! as String,
    creatorName: json['creatorName']! as String,
    assigneeId: json['assigneeId']! as String,
    assigneeName: json['assigneeName']! as String,
    dueAt: _date(json['dueAt']),
    createdAt: _date(json['createdAt']),
    checklist: _maps(json['checklist']).map(TaskChecklistItem.fromJson),
    tags: (json['tags'] as List?)?.whereType<String>() ?? const [],
    comments: _maps(json['comments']).map(TaskComment.fromJson),
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
}

enum AttendanceStatus { present, absent, late, excused }

final class AttendanceEntry {
  const AttendanceEntry({
    required this.studentId,
    required this.studentName,
    this.status,
    this.note,
  });

  final String studentId;
  final String studentName;
  final AttendanceStatus? status;
  final String? note;

  AttendanceEntry copyWith({Object? status = _unset, Object? note = _unset}) {
    return AttendanceEntry(
      studentId: studentId,
      studentName: studentName,
      status: identical(status, _unset)
          ? this.status
          : status as AttendanceStatus?,
      note: identical(note, _unset) ? this.note : note as String?,
    );
  }

  JsonMap toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'status': status?.name,
    'note': note,
  };

  factory AttendanceEntry.fromJson(JsonMap json) => AttendanceEntry(
    studentId: json['studentId']! as String,
    studentName: json['studentName']! as String,
    status: json['status'] == null
        ? null
        : _enumValue(
            AttendanceStatus.values,
            json['status'],
            AttendanceStatus.present,
          ),
    note: json['note'] as String?,
  );
}

final class AttendanceSheet {
  AttendanceSheet({
    required this.id,
    required this.cohortId,
    required this.cohortName,
    required this.lessonName,
    required this.lessonAt,
    required Iterable<AttendanceEntry> entries,
    this.submittedAt,
  }) : entries = List.unmodifiable(entries);

  final String id;
  final String cohortId;
  final String cohortName;
  final String lessonName;
  final DateTime lessonAt;
  final List<AttendanceEntry> entries;
  final DateTime? submittedAt;

  bool get isComplete => entries.every((entry) => entry.status != null);
  bool get isSubmitted => submittedAt != null;

  AttendanceSheet copyWith({
    Iterable<AttendanceEntry>? entries,
    Object? submittedAt = _unset,
  }) {
    return AttendanceSheet(
      id: id,
      cohortId: cohortId,
      cohortName: cohortName,
      lessonName: lessonName,
      lessonAt: lessonAt,
      entries: entries ?? this.entries,
      submittedAt: identical(submittedAt, _unset)
          ? this.submittedAt
          : submittedAt as DateTime?,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'cohortId': cohortId,
    'cohortName': cohortName,
    'lessonName': lessonName,
    'lessonAt': lessonAt.toUtc().toIso8601String(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'submittedAt': submittedAt?.toUtc().toIso8601String(),
  };

  factory AttendanceSheet.fromJson(JsonMap json) => AttendanceSheet(
    id: json['id']! as String,
    cohortId: json['cohortId']! as String,
    cohortName: json['cohortName']! as String,
    lessonName: json['lessonName']! as String,
    lessonAt: _date(json['lessonAt']),
    entries: _maps(json['entries']).map(AttendanceEntry.fromJson),
    submittedAt: json['submittedAt'] == null
        ? null
        : _date(json['submittedAt']),
  );
}

enum CardKind { praise, warning }

final class RecognitionCard {
  const RecognitionCard({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.cohortName,
    required this.kind,
    required this.label,
    required this.reason,
    required this.issuedById,
    required this.issuedByName,
    required this.issuedAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String cohortName;
  final CardKind kind;
  final String label;
  final String reason;
  final String issuedById;
  final String issuedByName;
  final DateTime issuedAt;

  JsonMap toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'cohortName': cohortName,
    'kind': kind.name,
    'label': label,
    'reason': reason,
    'issuedById': issuedById,
    'issuedByName': issuedByName,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
  };

  factory RecognitionCard.fromJson(JsonMap json) => RecognitionCard(
    id: json['id']! as String,
    studentId: json['studentId']! as String,
    studentName: json['studentName']! as String,
    cohortName: json['cohortName']! as String,
    kind: _enumValue(CardKind.values, json['kind'], CardKind.praise),
    label: json['label']! as String,
    reason: json['reason']! as String,
    issuedById: json['issuedById']! as String,
    issuedByName: json['issuedByName']! as String,
    issuedAt: _date(json['issuedAt']),
  );
}

final class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
    required Iterable<String> readBy,
  }) : readBy = Set.unmodifiable(readBy);

  final String id;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;
  final Set<String> readBy;

  ChatMessage copyWith({Iterable<String>? readBy}) => ChatMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    body: body,
    sentAt: sentAt,
    readBy: readBy ?? this.readBy,
  );

  JsonMap toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'body': body,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'readBy': readBy.toList()..sort(),
  };

  factory ChatMessage.fromJson(JsonMap json) => ChatMessage(
    id: json['id']! as String,
    senderId: json['senderId']! as String,
    senderName: json['senderName']! as String,
    body: json['body']! as String,
    sentAt: _date(json['sentAt']),
    readBy: (json['readBy'] as List? ?? const []).whereType<String>(),
  );
}

final class MessageThread {
  MessageThread({
    required this.id,
    required this.title,
    required Iterable<String> participantIds,
    required Iterable<ChatMessage> messages,
    this.isPinned = false,
  }) : participantIds = Set.unmodifiable(participantIds),
       messages = List.unmodifiable(messages);

  final String id;
  final String title;
  final Set<String> participantIds;
  final List<ChatMessage> messages;
  final bool isPinned;

  DateTime? get lastActivity => messages.lastOrNull?.sentAt;

  int unreadCountFor(String userId) => messages
      .where(
        (message) =>
            message.senderId != userId && !message.readBy.contains(userId),
      )
      .length;

  MessageThread copyWith({Iterable<ChatMessage>? messages, bool? isPinned}) {
    return MessageThread(
      id: id,
      title: title,
      participantIds: participantIds,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'participantIds': participantIds.toList()..sort(),
    'messages': messages.map((message) => message.toJson()).toList(),
    'isPinned': isPinned,
  };

  factory MessageThread.fromJson(JsonMap json) => MessageThread(
    id: json['id']! as String,
    title: json['title']! as String,
    participantIds: (json['participantIds'] as List? ?? const [])
        .whereType<String>(),
    messages: _maps(json['messages']).map(ChatMessage.fromJson),
    isPinned: json['isPinned'] as bool? ?? false,
  );
}

enum NotificationCategory {
  task,
  attendance,
  card,
  message,
  survey,
  print,
  audit,
}

final class StaffNotification {
  const StaffNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
    this.isRead = false,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? route;
  final bool isRead;

  StaffNotification copyWith({bool? isRead}) => StaffNotification(
    id: id,
    category: category,
    title: title,
    body: body,
    createdAt: createdAt,
    route: route,
    isRead: isRead ?? this.isRead,
  );

  JsonMap toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'route': route,
    'isRead': isRead,
  };

  factory StaffNotification.fromJson(JsonMap json) => StaffNotification(
    id: json['id']! as String,
    category: _enumValue(
      NotificationCategory.values,
      json['category'],
      NotificationCategory.task,
    ),
    title: json['title']! as String,
    body: json['body']! as String,
    createdAt: _date(json['createdAt']),
    route: json['route'] as String?,
    isRead: json['isRead'] as bool? ?? false,
  );
}

enum SurveyQuestionKind {
  singleChoice,
  multiChoice,
  freeText,
  number,
  boolean,
  rating,
  date,
}

final class SurveyQuestion {
  SurveyQuestion({
    required this.id,
    required this.prompt,
    required this.kind,
    required Iterable<String> options,
    this.required = true,
  }) : options = List.unmodifiable(options);

  final String id;
  final String prompt;
  final SurveyQuestionKind kind;
  final List<String> options;
  final bool required;

  JsonMap toJson() => {
    'id': id,
    'prompt': prompt,
    'kind': kind.name,
    'options': options,
    'required': required,
  };

  factory SurveyQuestion.fromJson(JsonMap json) => SurveyQuestion(
    id: json['id']! as String,
    prompt: json['prompt']! as String,
    kind: _enumValue(
      SurveyQuestionKind.values,
      json['kind'],
      SurveyQuestionKind.freeText,
    ),
    options: (json['options'] as List? ?? const []).whereType<String>(),
    required: json['required'] as bool? ?? true,
  );
}

final class SurveyAssignment {
  SurveyAssignment({
    required this.id,
    required this.title,
    required this.summary,
    required this.dueAt,
    required Iterable<SurveyQuestion> questions,
    required Map<String, String> answers,
    this.submittedAt,
  }) : questions = List.unmodifiable(questions),
       answers = UnmodifiableMapView(Map.of(answers));

  final String id;
  final String title;
  final String summary;
  final DateTime dueAt;
  final List<SurveyQuestion> questions;
  final Map<String, String> answers;
  final DateTime? submittedAt;

  bool get isSubmitted => submittedAt != null;
  int get answeredCount => questions
      .where((question) => answers[question.id]?.trim().isNotEmpty ?? false)
      .length;
  double get progress =>
      questions.isEmpty ? 1 : answeredCount / questions.length;

  SurveyAssignment copyWith({
    Map<String, String>? answers,
    Object? submittedAt = _unset,
  }) {
    return SurveyAssignment(
      id: id,
      title: title,
      summary: summary,
      dueAt: dueAt,
      questions: questions,
      answers: answers ?? this.answers,
      submittedAt: identical(submittedAt, _unset)
          ? this.submittedAt
          : submittedAt as DateTime?,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'questions': questions.map((question) => question.toJson()).toList(),
    'answers': answers,
    'submittedAt': submittedAt?.toUtc().toIso8601String(),
  };

  factory SurveyAssignment.fromJson(JsonMap json) => SurveyAssignment(
    id: json['id']! as String,
    title: json['title']! as String,
    summary: json['summary'] as String? ?? '',
    dueAt: _date(json['dueAt']),
    questions: _maps(json['questions']).map(SurveyQuestion.fromJson),
    answers: (json['answers'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    ),
    submittedAt: json['submittedAt'] == null
        ? null
        : _date(json['submittedAt']),
  );
}

enum PrintJobStatus { queued, printing, completed, failed, cancelled }

final class PrintJob {
  const PrintJob({
    required this.id,
    required this.documentName,
    required this.printerId,
    required this.printerName,
    required this.requestedById,
    required this.requestedAt,
    required this.copies,
    required this.pageCount,
    required this.status,
    required this.progress,
    this.failureReason,
  });

  final String id;
  final String documentName;
  final String printerId;
  final String printerName;
  final String requestedById;
  final DateTime requestedAt;
  final int copies;
  final int pageCount;
  final PrintJobStatus status;
  final double progress;
  final String? failureReason;

  PrintJob copyWith({
    PrintJobStatus? status,
    double? progress,
    Object? failureReason = _unset,
  }) {
    return PrintJob(
      id: id,
      documentName: documentName,
      printerId: printerId,
      printerName: printerName,
      requestedById: requestedById,
      requestedAt: requestedAt,
      copies: copies,
      pageCount: pageCount,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      failureReason: identical(failureReason, _unset)
          ? this.failureReason
          : failureReason as String?,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'documentName': documentName,
    'printerId': printerId,
    'printerName': printerName,
    'requestedById': requestedById,
    'requestedAt': requestedAt.toUtc().toIso8601String(),
    'copies': copies,
    'pageCount': pageCount,
    'status': status.name,
    'progress': progress,
    'failureReason': failureReason,
  };

  factory PrintJob.fromJson(JsonMap json) => PrintJob(
    id: json['id']! as String,
    documentName: json['documentName']! as String,
    printerId: json['printerId']! as String,
    printerName: json['printerName']! as String,
    requestedById: json['requestedById']! as String,
    requestedAt: _date(json['requestedAt']),
    copies: json['copies']! as int,
    pageCount: json['pageCount']! as int,
    status: _enumValue(
      PrintJobStatus.values,
      json['status'],
      PrintJobStatus.queued,
    ),
    progress: (json['progress']! as num).toDouble(),
    failureReason: json['failureReason'] as String?,
  );
}

enum AuditSeverity { low, medium, high, critical }

enum AnomalyStatus { open, acknowledged, linked, resolved }

final class AuditAnomaly {
  const AuditAnomaly({
    required this.id,
    required this.title,
    required this.description,
    required this.entityLabel,
    required this.severity,
    required this.status,
    required this.detectedAt,
    this.acknowledgedById,
  });

  final String id;
  final String title;
  final String description;
  final String entityLabel;
  final AuditSeverity severity;
  final AnomalyStatus status;
  final DateTime detectedAt;
  final String? acknowledgedById;

  AuditAnomaly copyWith({
    AnomalyStatus? status,
    Object? acknowledgedById = _unset,
  }) {
    return AuditAnomaly(
      id: id,
      title: title,
      description: description,
      entityLabel: entityLabel,
      severity: severity,
      status: status ?? this.status,
      detectedAt: detectedAt,
      acknowledgedById: identical(acknowledgedById, _unset)
          ? this.acknowledgedById
          : acknowledgedById as String?,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'entityLabel': entityLabel,
    'severity': severity.name,
    'status': status.name,
    'detectedAt': detectedAt.toUtc().toIso8601String(),
    'acknowledgedById': acknowledgedById,
  };

  factory AuditAnomaly.fromJson(JsonMap json) => AuditAnomaly(
    id: json['id']! as String,
    title: json['title']! as String,
    description: json['description']! as String,
    entityLabel: json['entityLabel']! as String,
    severity: _enumValue(
      AuditSeverity.values,
      json['severity'],
      AuditSeverity.medium,
    ),
    status: _enumValue(
      AnomalyStatus.values,
      json['status'],
      AnomalyStatus.open,
    ),
    detectedAt: _date(json['detectedAt']),
    acknowledgedById: json['acknowledgedById'] as String?,
  );
}

enum AuditCaseStatus { open, investigating, resolved, dismissed }

final class AuditCase {
  AuditCase({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.openedById,
    required this.openedAt,
    required Iterable<String> anomalyIds,
    required Iterable<String> notes,
    this.resolvedAt,
  }) : anomalyIds = List.unmodifiable(anomalyIds),
       notes = List.unmodifiable(notes);

  final String id;
  final String title;
  final String description;
  final AuditSeverity severity;
  final AuditCaseStatus status;
  final String openedById;
  final DateTime openedAt;
  final List<String> anomalyIds;
  final List<String> notes;
  final DateTime? resolvedAt;

  AuditCase copyWith({
    AuditCaseStatus? status,
    Iterable<String>? notes,
    Object? resolvedAt = _unset,
  }) {
    return AuditCase(
      id: id,
      title: title,
      description: description,
      severity: severity,
      status: status ?? this.status,
      openedById: openedById,
      openedAt: openedAt,
      anomalyIds: anomalyIds,
      notes: notes ?? this.notes,
      resolvedAt: identical(resolvedAt, _unset)
          ? this.resolvedAt
          : resolvedAt as DateTime?,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'severity': severity.name,
    'status': status.name,
    'openedById': openedById,
    'openedAt': openedAt.toUtc().toIso8601String(),
    'anomalyIds': anomalyIds,
    'notes': notes,
    'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
  };

  factory AuditCase.fromJson(JsonMap json) => AuditCase(
    id: json['id']! as String,
    title: json['title']! as String,
    description: json['description']! as String,
    severity: _enumValue(
      AuditSeverity.values,
      json['severity'],
      AuditSeverity.medium,
    ),
    status: _enumValue(
      AuditCaseStatus.values,
      json['status'],
      AuditCaseStatus.open,
    ),
    openedById: json['openedById']! as String,
    openedAt: _date(json['openedAt']),
    anomalyIds: (json['anomalyIds'] as List? ?? const []).whereType<String>(),
    notes: (json['notes'] as List? ?? const []).whereType<String>(),
    resolvedAt: json['resolvedAt'] == null ? null : _date(json['resolvedAt']),
  );
}

final class AppSnapshot {
  AppSnapshot({
    required this.session,
    required this.settings,
    required Iterable<StaffTask> tasks,
    required Iterable<AttendanceSheet> attendanceSheets,
    required Iterable<RecognitionCard> cards,
    required Iterable<MessageThread> messageThreads,
    required Iterable<StaffNotification> notifications,
    required Iterable<SurveyAssignment> surveys,
    required Iterable<PrintJob> printJobs,
    required Iterable<AuditAnomaly> auditAnomalies,
    required Iterable<AuditCase> auditCases,
  }) : tasks = List.unmodifiable(tasks),
       attendanceSheets = List.unmodifiable(attendanceSheets),
       cards = List.unmodifiable(cards),
       messageThreads = List.unmodifiable(messageThreads),
       notifications = List.unmodifiable(notifications),
       surveys = List.unmodifiable(surveys),
       printJobs = List.unmodifiable(printJobs),
       auditAnomalies = List.unmodifiable(auditAnomalies),
       auditCases = List.unmodifiable(auditCases);

  final StaffSession? session;
  final AppSettings settings;
  final List<StaffTask> tasks;
  final List<AttendanceSheet> attendanceSheets;
  final List<RecognitionCard> cards;
  final List<MessageThread> messageThreads;
  final List<StaffNotification> notifications;
  final List<SurveyAssignment> surveys;
  final List<PrintJob> printJobs;
  final List<AuditAnomaly> auditAnomalies;
  final List<AuditCase> auditCases;

  JsonMap toJson() => {
    'schemaVersion': 1,
    'session': session?.toJson(),
    'settings': settings.toJson(),
    'tasks': tasks.map((value) => value.toJson()).toList(),
    'attendanceSheets': attendanceSheets
        .map((value) => value.toJson())
        .toList(),
    'cards': cards.map((value) => value.toJson()).toList(),
    'messageThreads': messageThreads.map((value) => value.toJson()).toList(),
    'notifications': notifications.map((value) => value.toJson()).toList(),
    'surveys': surveys.map((value) => value.toJson()).toList(),
    'printJobs': printJobs.map((value) => value.toJson()).toList(),
    'auditAnomalies': auditAnomalies.map((value) => value.toJson()).toList(),
    'auditCases': auditCases.map((value) => value.toJson()).toList(),
  };

  factory AppSnapshot.fromJson(JsonMap json) {
    final rawSession = json['session'];
    return AppSnapshot(
      session: rawSession is Map
          ? StaffSession.fromJson(Map<String, Object?>.from(rawSession))
          : null,
      settings: json['settings'] is Map
          ? AppSettings.fromJson(
              Map<String, Object?>.from(json['settings']! as Map),
            )
          : const AppSettings(),
      tasks: _maps(json['tasks']).map(StaffTask.fromJson),
      attendanceSheets: _maps(
        json['attendanceSheets'],
      ).map(AttendanceSheet.fromJson),
      cards: _maps(json['cards']).map(RecognitionCard.fromJson),
      messageThreads: _maps(json['messageThreads']).map(MessageThread.fromJson),
      notifications: _maps(
        json['notifications'],
      ).map(StaffNotification.fromJson),
      surveys: _maps(json['surveys']).map(SurveyAssignment.fromJson),
      printJobs: _maps(json['printJobs']).map(PrintJob.fromJson),
      auditAnomalies: _maps(json['auditAnomalies']).map(AuditAnomaly.fromJson),
      auditCases: _maps(json['auditCases']).map(AuditCase.fromJson),
    );
  }
}
