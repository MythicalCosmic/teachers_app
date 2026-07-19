import 'backend_core.dart';

/// Dashboard payload returned only for teacher-principal sessions.
final class BackendTeacherDashboard {
  const BackendTeacherDashboard({
    required this.groupsCount,
    required this.studentsCount,
    required this.levelGroups,
    required this.nextLessons,
    required this.upcomingExams,
    required this.expectedGraduations,
    required this.pendingRuleAcknowledgments,
    required this.pendingForms,
    this.nextMeeting,
  });

  final int groupsCount;
  final int studentsCount;
  final BackendJson levelGroups;
  final List<BackendDashboardLesson> nextLessons;
  final List<BackendJson> upcomingExams;
  final List<BackendJson> expectedGraduations;
  final int pendingRuleAcknowledgments;
  final List<BackendForm> pendingForms;
  final BackendJson? nextMeeting;

  factory BackendTeacherDashboard.fromJson(BackendJson json) =>
      BackendTeacherDashboard(
        groupsCount: backendInt(json['groups_count']),
        studentsCount: backendInt(json['students_count']),
        levelGroups: backendMap(json['level_groups']),
        nextLessons: [
          for (final item in backendMaps(json['next_lessons']))
            BackendDashboardLesson.fromJson(item),
        ],
        upcomingExams: backendMaps(json['upcoming_exams']),
        expectedGraduations: backendMaps(json['expected_graduations']),
        nextMeeting: json['next_meeting'] is Map
            ? backendMap(json['next_meeting'])
            : null,
        pendingRuleAcknowledgments: backendInt(
          json['pending_rule_acknowledgments'],
        ),
        pendingForms: [
          for (final item in backendMaps(json['pending_forms']))
            BackendForm.fromJson(item),
        ],
      );
}

final class BackendDashboardLesson {
  const BackendDashboardLesson({
    required this.id,
    required this.title,
    required this.cohort,
    required this.startsAt,
    required this.endsAt,
    required this.lessonType,
  });

  final int id;
  final String title;
  final String cohort;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String lessonType;

  factory BackendDashboardLesson.fromJson(BackendJson json) =>
      BackendDashboardLesson(
        id: backendInt(json['id']),
        title: backendString(json['title']),
        cohort: backendString(json['cohort']),
        startsAt: backendDate(json['starts_at']),
        endsAt: backendDate(json['ends_at']),
        lessonType: backendString(json['lesson_type']),
      );
}

final class BackendLesson {
  const BackendLesson({
    required this.id,
    required this.title,
    required this.status,
    required this.cohortName,
    required this.teacherName,
    required this.termName,
    required this.lessonTypeName,
    required this.startsAt,
    required this.endsAt,
    required this.detachedFromRule,
    required this.cancelReason,
    this.ruleId,
    this.termId,
    this.cohortId,
    this.teacherId,
    this.roomId,
    this.roomName,
    this.lessonTypeId,
  });

  final int id;
  final int? ruleId;
  final int? termId;
  final String termName;
  final int? cohortId;
  final String cohortName;
  final int? teacherId;
  final String teacherName;
  final int? roomId;
  final String? roomName;
  final int? lessonTypeId;
  final String lessonTypeName;
  final String title;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Raw server value is intentionally preserved so a newly deployed status
  /// remains renderable before the mobile binary knows about it.
  final String status;
  final bool detachedFromRule;
  final String cancelReason;

  bool get hasKnownStatus =>
      const {'scheduled', 'cancelled', 'completed'}.contains(status);

  factory BackendLesson.fromJson(BackendJson json) => BackendLesson(
    id: backendInt(json['id']),
    ruleId: backendNullableInt(json['rule']),
    termId: backendNullableInt(json['term']),
    termName: backendString(json['term_name']),
    cohortId: backendNullableInt(json['cohort']),
    cohortName: backendString(json['cohort_name']),
    teacherId: backendNullableInt(json['teacher']),
    teacherName: backendString(json['teacher_name']),
    roomId: backendNullableInt(json['room']),
    roomName: backendNullableString(json['room_name']),
    lessonTypeId: backendNullableInt(json['lesson_type']),
    lessonTypeName: backendString(json['lesson_type_name']),
    title: backendString(json['title']),
    startsAt: backendDate(json['starts_at']),
    endsAt: backendDate(json['ends_at']),
    status: backendString(json['status'], fallback: 'unknown'),
    detachedFromRule: backendBool(json['detached_from_rule']),
    cancelReason: backendString(json['cancel_reason']),
  );
}

final class BackendCohortTeacher {
  const BackendCohortTeacher({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.teacherTypeName,
    required this.teacherTypeSlug,
    required this.role,
    this.teacherTypeId,
  });

  final int id;
  final int teacherId;
  final String teacherName;
  final int? teacherTypeId;
  final String teacherTypeName;
  final String teacherTypeSlug;
  final String role;

  factory BackendCohortTeacher.fromJson(BackendJson json) =>
      BackendCohortTeacher(
        id: backendInt(json['id']),
        teacherId: backendInt(json['teacher']),
        teacherName: backendString(json['teacher_name']),
        teacherTypeId: backendNullableInt(json['teacher_type']),
        teacherTypeName: backendString(json['teacher_type_name']),
        teacherTypeSlug: backendString(
          json['teacher_type_slug'],
          fallback: 'unknown',
        ),
        role: backendString(json['role']),
      );
}

final class BackendCohort {
  const BackendCohort({
    required this.id,
    required this.name,
    required this.branchName,
    required this.departmentName,
    required this.level,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.primaryTeacherName,
    required this.defaultRoomName,
    required this.isArchived,
    required this.teachers,
    required this.createdAt,
    this.branchId,
    this.departmentId,
    this.primaryTeacherId,
    this.defaultRoomId,
  });

  final int id;
  final String name;
  final int? branchId;
  final String branchName;
  final int? departmentId;
  final String departmentName;
  final String level;
  final DateTime? startDate;
  final DateTime? endDate;
  final int capacity;
  final int? primaryTeacherId;
  final String primaryTeacherName;
  final int? defaultRoomId;
  final String defaultRoomName;
  final bool isArchived;
  final List<BackendCohortTeacher> teachers;
  final DateTime? createdAt;

  factory BackendCohort.fromJson(BackendJson json) => BackendCohort(
    id: backendInt(json['id']),
    name: backendString(json['name']),
    branchId: backendNullableInt(json['branch']),
    branchName: backendString(json['branch_name']),
    departmentId: backendNullableInt(json['department']),
    departmentName: backendString(json['department_name']),
    level: backendString(json['level']),
    startDate: backendDate(json['start_date']),
    endDate: backendDate(json['end_date']),
    capacity: backendInt(json['capacity']),
    primaryTeacherId: backendNullableInt(json['primary_teacher']),
    primaryTeacherName: backendString(json['primary_teacher_name']),
    defaultRoomId: backendNullableInt(json['default_room']),
    defaultRoomName: backendString(json['default_room_name']),
    isArchived: backendBool(json['is_archived']),
    teachers: [
      for (final item in backendMaps(json['teachers']))
        BackendCohortTeacher.fromJson(item),
    ],
    createdAt: backendDate(json['created_at']),
  );
}

final class BackendCohortMember {
  const BackendCohortMember({
    required this.id,
    required this.cohortId,
    required this.cohortName,
    required this.studentId,
    required this.studentName,
    required this.startDate,
    required this.movedReason,
    this.endDate,
  });

  final int id;
  final int cohortId;
  final String cohortName;
  final int studentId;
  final String studentName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String movedReason;

  factory BackendCohortMember.fromJson(BackendJson json) => BackendCohortMember(
    id: backendInt(json['id']),
    cohortId: backendInt(json['cohort']),
    cohortName: backendString(json['cohort_name']),
    studentId: backendInt(json['student']),
    studentName: backendString(json['student_name']),
    startDate: backendDate(json['start_date']),
    endDate: backendDate(json['end_date']),
    movedReason: backendString(json['moved_reason']),
  );
}

final class BackendAttendanceRecord {
  const BackendAttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.lessonId,
    required this.lessonTitle,
    required this.cohortId,
    required this.cohortName,
    required this.teacherId,
    required this.teacherName,
    required this.status,
    required this.note,
    required this.autoMarked,
    this.lessonStartsAt,
    this.arrivedAt,
    this.markedBy,
    this.markedAt,
    this.createdAt,
  });

  final int id;
  final int studentId;
  final String studentName;
  final int lessonId;
  final String lessonTitle;
  final DateTime? lessonStartsAt;
  final int cohortId;
  final String cohortName;
  final int teacherId;
  final String teacherName;
  final String status;
  final DateTime? arrivedAt;
  final String note;
  final int? markedBy;
  final DateTime? markedAt;
  final bool autoMarked;
  final DateTime? createdAt;

  bool get hasKnownStatus =>
      const {'present', 'absent', 'late', 'excused'}.contains(status);

  factory BackendAttendanceRecord.fromJson(BackendJson json) =>
      BackendAttendanceRecord(
        id: backendInt(json['id']),
        studentId: backendInt(json['student']),
        studentName: backendString(json['student_name']),
        lessonId: backendInt(json['lesson']),
        lessonTitle: backendString(json['lesson_title']),
        lessonStartsAt: backendDate(json['lesson_starts_at']),
        cohortId: backendInt(json['cohort']),
        cohortName: backendString(json['cohort_name']),
        teacherId: backendInt(json['teacher']),
        teacherName: backendString(json['teacher_name']),
        status: backendString(json['status'], fallback: 'unknown'),
        arrivedAt: backendDate(json['arrived_at']),
        note: backendString(json['note']),
        markedBy: backendNullableInt(json['marked_by']),
        markedAt: backendDate(json['marked_at']),
        autoMarked: backendBool(json['auto_marked']),
        createdAt: backendDate(json['created_at']),
      );
}

final class BackendAttendanceStudentStat {
  const BackendAttendanceStudentStat({
    required this.studentId,
    required this.studentCode,
    required this.name,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.total,
    required this.percentPresent,
  });

  final int studentId;
  final String studentCode;
  final String name;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int total;
  final double percentPresent;

  factory BackendAttendanceStudentStat.fromJson(BackendJson json) =>
      BackendAttendanceStudentStat(
        studentId: backendInt(json['student']),
        studentCode: backendString(json['student_code']),
        name: backendString(json['name']),
        present: backendInt(json['present']),
        absent: backendInt(json['absent']),
        late: backendInt(json['late']),
        excused: backendInt(json['excused']),
        total: backendInt(json['total']),
        percentPresent: backendDouble(json['percent_present']),
      );
}

final class BackendAttendanceDashboard {
  const BackendAttendanceDashboard({
    required this.cohortId,
    required this.rate,
    required this.students,
  });

  final int cohortId;
  final double rate;
  final List<BackendAttendanceStudentStat> students;

  factory BackendAttendanceDashboard.fromJson(BackendJson json) =>
      BackendAttendanceDashboard(
        cohortId: backendInt(json['cohort']),
        rate: backendDouble(json['rate']),
        students: [
          for (final item in backendMaps(json['students']))
            BackendAttendanceStudentStat.fromJson(item),
        ],
      );
}

final class BackendAttendanceMarkResult {
  const BackendAttendanceMarkResult({
    required this.created,
    required this.updated,
    required this.records,
  });

  final int created;
  final int updated;
  final List<BackendAttendanceRecord> records;

  factory BackendAttendanceMarkResult.fromJson(BackendJson json) =>
      BackendAttendanceMarkResult(
        created: backendInt(json['created']),
        updated: backendInt(json['updated']),
        records: [
          for (final item in backendMaps(json['records']))
            BackendAttendanceRecord.fromJson(item),
        ],
      );
}

final class BackendTask {
  const BackendTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.completedAt,
    required this.createdAt,
    this.assigneeId,
    this.departmentId,
    this.branchId,
    this.dueAt,
    this.createdBy,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int? assigneeId;
  final int? departmentId;
  final int? branchId;
  final DateTime? dueAt;
  final int? createdBy;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get hasKnownStatus => const {
    'open',
    'in_progress',
    'blocked',
    'done',
    'cancelled',
  }.contains(status);

  bool get hasKnownPriority =>
      const {'low', 'normal', 'high', 'urgent'}.contains(priority);

  factory BackendTask.fromJson(BackendJson json) => BackendTask(
    id: backendInt(json['id']),
    title: backendString(json['title']),
    description: backendString(json['description']),
    status: backendString(json['status'], fallback: 'unknown'),
    priority: backendString(json['priority'], fallback: 'unknown'),
    assigneeId: backendNullableInt(json['assignee']),
    departmentId: backendNullableInt(json['department']),
    branchId: backendNullableInt(json['branch']),
    dueAt: backendDate(json['due_at']),
    createdBy: backendNullableInt(json['created_by']),
    completedAt: backendDate(json['completed_at']),
    createdAt: backendDate(json['created_at']),
  );
}

final class BackendThreadParticipant {
  const BackendThreadParticipant({
    required this.userId,
    this.lastReadAt,
    this.addedAt,
  });

  final int userId;
  final DateTime? lastReadAt;
  final DateTime? addedAt;

  factory BackendThreadParticipant.fromJson(BackendJson json) =>
      BackendThreadParticipant(
        userId: backendInt(json['user']),
        lastReadAt: backendDate(json['last_read_at']),
        addedAt: backendDate(json['added_at']),
      );
}

final class BackendThread {
  const BackendThread({
    required this.id,
    required this.subject,
    required this.participants,
    required this.unreadCount,
    this.branchId,
    this.createdBy,
    this.lastMessageAt,
    this.createdAt,
  });

  final int id;
  final String subject;
  final int? branchId;
  final int? createdBy;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final List<BackendThreadParticipant> participants;
  final int unreadCount;

  factory BackendThread.fromJson(BackendJson json) => BackendThread(
    id: backendInt(json['id']),
    subject: backendString(json['subject']),
    branchId: backendNullableInt(json['branch']),
    createdBy: backendNullableInt(json['created_by']),
    lastMessageAt: backendDate(json['last_message_at']),
    createdAt: backendDate(json['created_at']),
    participants: [
      for (final item in backendMaps(json['participants']))
        BackendThreadParticipant.fromJson(item),
    ],
    unreadCount: backendInt(json['unread_count']),
  );
}

final class BackendMessage {
  const BackendMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.attachments,
    this.createdAt,
  });

  final int id;
  final int threadId;
  final int senderId;
  final String body;
  final List<String> attachments;
  final DateTime? createdAt;

  factory BackendMessage.fromJson(BackendJson json) => BackendMessage(
    id: backendInt(json['id']),
    threadId: backendInt(json['thread']),
    senderId: backendInt(json['sender']),
    body: backendString(json['body']),
    attachments: backendStrings(json['attachments']),
    createdAt: backendDate(json['created_at']),
  );
}

final class BackendAssignment {
  const BackendAssignment({
    required this.id,
    required this.cohortId,
    required this.cohortName,
    required this.title,
    required this.description,
    required this.attachments,
    required this.rubric,
    required this.maxScore,
    required this.maxResubmits,
    required this.status,
    this.dueAt,
    this.publishedAt,
    this.createdAt,
  });

  final int id;
  final int cohortId;
  final String cohortName;
  final String title;
  final String description;
  final DateTime? dueAt;
  final List<Object?> attachments;
  final Object? rubric;
  final String maxScore;
  final int maxResubmits;
  final String status;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  factory BackendAssignment.fromJson(BackendJson json) => BackendAssignment(
    id: backendInt(json['id']),
    cohortId: backendInt(json['cohort']),
    cohortName: backendString(json['cohort_name']),
    title: backendString(json['title']),
    description: backendString(json['description']),
    dueAt: backendDate(json['due_at']),
    attachments: backendList(json['attachments']),
    rubric: json['rubric'],
    maxScore: backendString(json['max_score']),
    maxResubmits: backendInt(json['max_resubmits']),
    status: backendString(json['status'], fallback: 'unknown'),
    publishedAt: backendDate(json['published_at']),
    createdAt: backendDate(json['created_at']),
  );
}

final class BackendSubmissionGrade {
  const BackendSubmissionGrade({
    required this.submissionId,
    required this.graded,
    required this.rubricScores,
    required this.feedback,
    required this.aiFeedback,
    this.score,
    this.gradedBy,
    this.gradedAt,
  });

  final int submissionId;
  final String? score;
  final bool graded;
  final List<Object?> rubricScores;
  final String feedback;
  final String aiFeedback;
  final int? gradedBy;
  final DateTime? gradedAt;

  factory BackendSubmissionGrade.fromJson(BackendJson json) =>
      BackendSubmissionGrade(
        submissionId: backendInt(json['submission']),
        score: backendNullableString(json['score']),
        graded: backendBool(json['graded']),
        rubricScores: backendList(json['rubric_scores']),
        feedback: backendString(json['feedback']),
        aiFeedback: backendString(json['ai_feedback']),
        gradedBy: backendNullableInt(json['graded_by']),
        gradedAt: backendDate(json['graded_at']),
      );
}

final class BackendSubmission {
  const BackendSubmission({
    required this.id,
    required this.assignmentId,
    required this.assignmentTitle,
    required this.studentId,
    required this.studentName,
    required this.text,
    required this.attachments,
    required this.isLate,
    required this.attemptNumber,
    required this.status,
    this.assignmentDueAt,
    this.submittedAt,
    this.grade,
  });

  final int id;
  final int assignmentId;
  final String assignmentTitle;
  final DateTime? assignmentDueAt;
  final int studentId;
  final String studentName;
  final String text;
  final List<Object?> attachments;
  final DateTime? submittedAt;
  final bool isLate;
  final int attemptNumber;
  final String status;
  final BackendSubmissionGrade? grade;

  factory BackendSubmission.fromJson(BackendJson json) => BackendSubmission(
    id: backendInt(json['id']),
    assignmentId: backendInt(json['assignment']),
    assignmentTitle: backendString(json['assignment_title']),
    assignmentDueAt: backendDate(json['assignment_due_at']),
    studentId: backendInt(json['student']),
    studentName: backendString(json['student_name']),
    text: backendString(json['text']),
    attachments: backendList(json['attachments']),
    submittedAt: backendDate(json['submitted_at']),
    isLate: backendBool(json['is_late']),
    attemptNumber: backendInt(json['attempt_number']),
    status: backendString(json['status'], fallback: 'unknown'),
    grade: json['grade'] is Map
        ? BackendSubmissionGrade.fromJson(backendMap(json['grade']))
        : null,
  );
}

final class BackendFormField {
  const BackendFormField({
    required this.id,
    required this.label,
    required this.fieldType,
    required this.required,
    required this.order,
    required this.options,
    required this.helpText,
  });

  final int id;
  final String label;
  final String fieldType;
  final bool required;
  final int order;
  final List<Object?> options;
  final String helpText;

  bool get hasKnownType => const {
    'text',
    'textarea',
    'number',
    'boolean',
    'single_choice',
    'multi_choice',
    'rating',
    'date',
  }.contains(fieldType);

  factory BackendFormField.fromJson(BackendJson json) => BackendFormField(
    id: backendInt(json['id']),
    label: backendString(json['label']),
    fieldType: backendString(json['field_type'], fallback: 'unknown'),
    required: backendBool(json['required']),
    order: backendInt(json['order']),
    options: backendList(json['options']),
    helpText: backendString(json['help_text']),
  );
}

final class BackendForm {
  const BackendForm({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.isAnonymous,
    required this.allowMultiple,
    required this.audienceRoles,
    required this.audienceUserIds,
    required this.fields,
    this.branchId,
    this.opensAt,
    this.closesAt,
    this.createdBy,
    this.publishedAt,
    this.closedAt,
    this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final bool isAnonymous;
  final bool allowMultiple;
  final int? branchId;
  final List<String> audienceRoles;
  final List<int> audienceUserIds;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final int? createdBy;
  final DateTime? publishedAt;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final List<BackendFormField> fields;

  factory BackendForm.fromJson(BackendJson json) => BackendForm(
    id: backendInt(json['id']),
    title: backendString(json['title']),
    description: backendString(json['description']),
    status: backendString(json['status'], fallback: 'unknown'),
    isAnonymous: backendBool(json['is_anonymous']),
    allowMultiple: backendBool(json['allow_multiple']),
    branchId: backendNullableInt(json['branch']),
    audienceRoles: backendStrings(json['audience_roles']),
    audienceUserIds: backendInts(json['audience_user_ids']),
    opensAt: backendDate(json['opens_at']),
    closesAt: backendDate(json['closes_at']),
    createdBy: backendNullableInt(json['created_by']),
    publishedAt: backendDate(json['published_at']),
    closedAt: backendDate(json['closed_at']),
    createdAt: backendDate(json['created_at']),
    fields: [
      for (final item in backendMaps(json['form_fields']))
        BackendFormField.fromJson(item),
    ],
  );
}

final class BackendFormResponse {
  const BackendFormResponse({
    required this.id,
    required this.formId,
    required this.answers,
    this.respondentId,
    this.createdAt,
  });

  final int id;
  final int formId;
  final int? respondentId;
  final DateTime? createdAt;
  final List<BackendJson> answers;

  factory BackendFormResponse.fromJson(BackendJson json) => BackendFormResponse(
    id: backendInt(json['id']),
    formId: backendInt(json['form']),
    respondentId: backendNullableInt(json['respondent']),
    createdAt: backendDate(json['created_at']),
    answers: backendMaps(json['answers']),
  );
}

final class BackendNotification {
  const BackendNotification({
    required this.id,
    required this.userId,
    required this.userName,
    required this.eventType,
    required this.title,
    required this.body,
    required this.data,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String userName;
  final String eventType;
  final String title;
  final String body;
  final BackendJson data;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory BackendNotification.fromJson(BackendJson json) => BackendNotification(
    id: backendInt(json['id']),
    userId: backendInt(json['user']),
    userName: backendString(json['user_name']),
    eventType: backendString(json['event_type'], fallback: 'unknown'),
    title: backendString(json['title']),
    body: backendString(json['body']),
    data: backendMap(json['data']),
    readAt: backendDate(json['read_at']),
    createdAt: backendDate(json['created_at']),
  );
}

final class BackendNotificationPreference {
  const BackendNotificationPreference({
    required this.eventType,
    required this.channel,
    required this.enabled,
  });

  final String eventType;
  final String channel;
  final bool enabled;

  BackendJson toJson() => {
    'event_type': eventType,
    'channel': channel,
    'enabled': enabled,
  };

  factory BackendNotificationPreference.fromJson(BackendJson json) =>
      BackendNotificationPreference(
        eventType: backendString(json['event_type'], fallback: 'unknown'),
        channel: backendString(json['channel'], fallback: 'unknown'),
        enabled: backendBool(json['enabled']),
      );
}

final class BackendContentLibrary {
  const BackendContentLibrary({
    required this.id,
    required this.name,
    required this.description,
    required this.visibility,
    required this.departmentName,
    required this.cohortName,
    required this.allowedRoles,
    required this.isActive,
    this.departmentId,
    this.cohortId,
  });

  final int id;
  final String name;
  final String description;
  final String visibility;
  final int? departmentId;
  final String departmentName;
  final int? cohortId;
  final String cohortName;
  final List<String> allowedRoles;
  final bool isActive;

  factory BackendContentLibrary.fromJson(BackendJson json) =>
      BackendContentLibrary(
        id: backendInt(json['id']),
        name: backendString(json['name']),
        description: backendString(json['description']),
        visibility: backendString(json['visibility'], fallback: 'unknown'),
        departmentId: backendNullableInt(json['department']),
        departmentName: backendString(json['department_name']),
        cohortId: backendNullableInt(json['cohort']),
        cohortName: backendString(json['cohort_name']),
        allowedRoles: backendStrings(json['allowed_roles']),
        isActive: backendBool(json['is_active']),
      );
}

/// Lightweight self-describing node for courses, modules, content lessons and
/// folders. [raw] preserves new fields from a newer backend.
final class BackendContentNode {
  const BackendContentNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.parentId,
    required this.parentLabel,
    required this.order,
    required this.raw,
  });

  final int id;
  final String kind;
  final String title;
  final int? parentId;
  final String parentLabel;
  final int order;
  final BackendJson raw;

  factory BackendContentNode.course(BackendJson json) => BackendContentNode(
    id: backendInt(json['id']),
    kind: 'course',
    title: backendString(json['title']),
    parentId: backendNullableInt(json['library']),
    parentLabel: backendString(json['library_name']),
    order: backendInt(json['order']),
    raw: Map.unmodifiable(json),
  );

  factory BackendContentNode.module(BackendJson json) => BackendContentNode(
    id: backendInt(json['id']),
    kind: 'module',
    title: backendString(json['title']),
    parentId: backendNullableInt(json['course']),
    parentLabel: backendString(json['course_title']),
    order: backendInt(json['order']),
    raw: Map.unmodifiable(json),
  );

  factory BackendContentNode.lesson(BackendJson json) => BackendContentNode(
    id: backendInt(json['id']),
    kind: 'lesson',
    title: backendString(json['title']),
    parentId: backendNullableInt(json['module']),
    parentLabel: backendString(json['module_title']),
    order: backendInt(json['order']),
    raw: Map.unmodifiable(json),
  );

  factory BackendContentNode.folder(BackendJson json) => BackendContentNode(
    id: backendInt(json['id']),
    kind: 'folder',
    title: backendString(json['name']),
    parentId: backendNullableInt(json['parent']),
    parentLabel: backendString(json['parent_name']),
    order: 0,
    raw: Map.unmodifiable(json),
  );
}

final class BackendContentFile {
  const BackendContentFile({
    required this.id,
    required this.lessonTitle,
    required this.folderName,
    required this.title,
    required this.contentType,
    required this.sizeBytes,
    required this.status,
    required this.rejectReason,
    required this.version,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.downloadCount,
    required this.uploadedByName,
    required this.approvedByTeacher,
    required this.approvedByManager,
    required this.isDownloadable,
    this.lessonId,
    this.folderId,
    this.previousVersionId,
    this.uploadedBy,
    this.createdAt,
  });

  final int id;
  final int? lessonId;
  final String lessonTitle;
  final int? folderId;
  final String folderName;
  final String title;
  final String contentType;
  final int sizeBytes;
  final String status;
  final String rejectReason;
  final int version;
  final int? previousVersionId;
  final String thumbnailUrl;
  final int viewCount;
  final int downloadCount;
  final int? uploadedBy;
  final String uploadedByName;
  final DateTime? createdAt;
  final bool approvedByTeacher;
  final bool approvedByManager;
  final bool isDownloadable;

  factory BackendContentFile.fromJson(BackendJson json) => BackendContentFile(
    id: backendInt(json['id']),
    lessonId: backendNullableInt(json['lesson']),
    lessonTitle: backendString(json['lesson_title']),
    folderId: backendNullableInt(json['folder']),
    folderName: backendString(json['folder_name']),
    title: backendString(json['title']),
    contentType: backendString(json['content_type']),
    sizeBytes: backendInt(json['size_bytes']),
    status: backendString(json['status'], fallback: 'unknown'),
    rejectReason: backendString(json['reject_reason']),
    version: backendInt(json['version']),
    previousVersionId: backendNullableInt(json['previous_version']),
    thumbnailUrl: backendString(json['thumbnail_url']),
    viewCount: backendInt(json['view_count']),
    downloadCount: backendInt(json['download_count']),
    uploadedBy: backendNullableInt(json['uploaded_by']),
    uploadedByName: backendString(json['uploaded_by_name']),
    createdAt: backendDate(json['created_at']),
    approvedByTeacher: backendBool(json['is_approved_teacher']),
    approvedByManager: backendBool(json['is_approved_manager']),
    isDownloadable: backendBool(json['is_downloadable']),
  );
}

final class BackendMaterial {
  const BackendMaterial({
    required this.id,
    required this.libraryId,
    required this.libraryName,
    required this.title,
    required this.topic,
    required this.body,
    required this.status,
    required this.createdByName,
    this.createdBy,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int libraryId;
  final String libraryName;
  final String title;
  final String topic;
  final String body;
  final String status;
  final int? createdBy;
  final String createdByName;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BackendMaterial.fromJson(BackendJson json) => BackendMaterial(
    id: backendInt(json['id']),
    libraryId: backendInt(json['library']),
    libraryName: backendString(json['library_name']),
    title: backendString(json['title']),
    topic: backendString(json['topic']),
    body: backendString(json['body']),
    status: backendString(json['status'], fallback: 'unknown'),
    createdBy: backendNullableInt(json['created_by']),
    createdByName: backendString(json['created_by_name']),
    publishedAt: backendDate(json['published_at']),
    createdAt: backendDate(json['created_at']),
    updatedAt: backendDate(json['updated_at']),
  );
}

final class BackendPrintJob {
  const BackendPrintJob({
    required this.id,
    required this.status,
    required this.source,
    required this.payloadKey,
    required this.pages,
    required this.copies,
    required this.color,
    required this.duplex,
    required this.attempts,
    required this.pagesPrinted,
    required this.lastError,
    this.branchId,
    this.printerId,
    this.agentId,
    this.sourceId,
    this.cohortId,
    this.requestedBy,
    this.nextAttemptAt,
    this.createdAt,
    this.claimedAt,
    this.finishedAt,
  });

  final int id;
  final int? branchId;
  final int? printerId;
  final int? agentId;
  final String status;
  final String source;
  final int? sourceId;
  final String payloadKey;
  final int pages;
  final int copies;
  final bool color;
  final bool duplex;
  final int? cohortId;
  final int? requestedBy;
  final int attempts;
  final DateTime? nextAttemptAt;
  final int pagesPrinted;
  final String lastError;
  final DateTime? createdAt;
  final DateTime? claimedAt;
  final DateTime? finishedAt;

  factory BackendPrintJob.fromJson(BackendJson json) => BackendPrintJob(
    id: backendInt(json['id']),
    branchId: backendNullableInt(json['branch']),
    printerId: backendNullableInt(json['printer']),
    agentId: backendNullableInt(json['agent']),
    status: backendString(json['status'], fallback: 'unknown'),
    source: backendString(json['source'], fallback: 'unknown'),
    sourceId: backendNullableInt(json['source_id']),
    payloadKey: backendString(json['payload_s3_key']),
    pages: backendInt(json['pages']),
    copies: backendInt(json['copies'], fallback: 1),
    color: backendBool(json['color']),
    duplex: backendBool(json['duplex']),
    cohortId: backendNullableInt(json['cohort_id']),
    requestedBy: backendNullableInt(json['requested_by']),
    attempts: backendInt(json['attempts']),
    nextAttemptAt: backendDate(json['next_attempt_at']),
    pagesPrinted: backendInt(json['pages_printed']),
    lastError: backendString(json['last_error']),
    createdAt: backendDate(json['created_at']),
    claimedAt: backendDate(json['claimed_at']),
    finishedAt: backendDate(json['finished_at']),
  );
}

final class BackendPrinter {
  const BackendPrinter({
    required this.id,
    required this.branchId,
    required this.name,
    required this.modelName,
    required this.capabilities,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int branchId;
  final String name;
  final String modelName;
  final BackendJson capabilities;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BackendPrinter.fromJson(BackendJson json) => BackendPrinter(
    id: backendInt(json['id']),
    branchId: backendInt(json['branch']),
    name: backendString(json['name']),
    modelName: backendString(json['model_name']),
    capabilities: backendMap(json['capabilities']),
    isActive: backendBool(json['is_active']),
    createdAt: backendDate(json['created_at']),
    updatedAt: backendDate(json['updated_at']),
  );
}

final class BackendAiRequest {
  const BackendAiRequest({
    required this.id,
    required this.feature,
    required this.status,
    required this.inputTokens,
    required this.outputTokens,
    required this.costMicrousd,
    this.createdAt,
    this.finishedAt,
    this.outputText,
  });

  final int id;
  final String feature;
  final String status;
  final int inputTokens;
  final int outputTokens;
  final int costMicrousd;
  final DateTime? createdAt;
  final DateTime? finishedAt;
  final String? outputText;

  factory BackendAiRequest.fromJson(BackendJson json) => BackendAiRequest(
    id: backendInt(json['id']),
    feature: backendString(json['feature'], fallback: 'unknown'),
    status: backendString(json['status'], fallback: 'unknown'),
    inputTokens: backendInt(json['input_tokens']),
    outputTokens: backendInt(json['output_tokens']),
    costMicrousd: backendInt(json['cost_microusd']),
    createdAt: backendDate(json['created_at']),
    finishedAt: backendDate(json['finished_at']),
    outputText: backendNullableString(json['output_text']),
  );
}

final class BackendAiBudget {
  const BackendAiBudget({
    required this.dailyTokenLimit,
    required this.monthlyTokenLimit,
    required this.tokensUsedToday,
    required this.tokensUsedMonth,
    required this.isEnabled,
  });

  final int dailyTokenLimit;
  final int monthlyTokenLimit;
  final int tokensUsedToday;
  final int tokensUsedMonth;
  final bool isEnabled;

  factory BackendAiBudget.fromJson(BackendJson json) => BackendAiBudget(
    dailyTokenLimit: backendInt(json['daily_token_limit']),
    monthlyTokenLimit: backendInt(json['monthly_token_limit']),
    tokensUsedToday: backendInt(json['tokens_used_today']),
    tokensUsedMonth: backendInt(json['tokens_used_month']),
    isEnabled: backendBool(json['is_enabled']),
  );
}

final class BackendAuditEntry {
  const BackendAuditEntry({
    required this.id,
    required this.actorUsername,
    required this.actorRepresentation,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.before,
    required this.after,
    required this.ip,
    required this.userAgent,
    this.actorId,
    this.createdAt,
  });

  final int id;
  final int? actorId;
  final String actorUsername;
  final String actorRepresentation;
  final String action;
  final String resourceType;
  final String resourceId;
  final BackendJson before;
  final BackendJson after;
  final String ip;
  final String userAgent;
  final DateTime? createdAt;

  factory BackendAuditEntry.fromJson(BackendJson json) => BackendAuditEntry(
    id: backendInt(json['id']),
    actorId: backendNullableInt(json['actor']),
    actorUsername: backendString(json['actor_username']),
    actorRepresentation: backendString(json['actor_repr']),
    action: backendString(json['action'], fallback: 'unknown'),
    resourceType: backendString(json['resource_type']),
    resourceId: backendString(json['resource_id']),
    before: backendMap(json['before']),
    after: backendMap(json['after']),
    ip: backendString(json['ip']),
    userAgent: backendString(json['user_agent']),
    createdAt: backendDate(json['created_at']),
  );
}

final class BackendQueuedRequest {
  const BackendQueuedRequest({required this.requestId, required this.status});

  final int requestId;
  final String status;

  factory BackendQueuedRequest.fromJson(BackendJson json) =>
      BackendQueuedRequest(
        requestId: backendInt(json['request_id']),
        status: backendString(json['status'], fallback: 'queued'),
      );
}
