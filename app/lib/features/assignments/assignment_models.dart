import 'package:flutter/foundation.dart';

enum AssignmentResponseType { text, document, photo }

enum AssignmentSubmissionStatus {
  notSubmitted,
  submitted,
  feedbackNeeded,
  feedbackShared,
  revisionRequested,
  conferenceRequested,
}

enum AssignmentFeedbackStep { ready, revise, conference }

enum AssignmentProgressState { collecting, needsFeedback, complete }

@immutable
class AssignmentStudent {
  const AssignmentStudent({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory AssignmentStudent.fromJson(Map<String, Object?> json) =>
      AssignmentStudent(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

@immutable
class AssignmentCohort {
  const AssignmentCohort({
    required this.id,
    required this.name,
    required this.students,
  });

  final String id;
  final String name;
  final List<AssignmentStudent> students;
}

@immutable
class AssignmentAttachment {
  const AssignmentAttachment({
    required this.fileName,
    required this.mediaType,
    required this.byteSize,
    required this.summary,
    this.pageCount,
    this.demoMetadataOnly = true,
  });

  final String fileName;
  final String mediaType;
  final int byteSize;
  final String summary;
  final int? pageCount;

  /// Demo data intentionally contains metadata, not downloadable file bytes.
  final bool demoMetadataOnly;

  String get formattedSize {
    if (byteSize >= 1024 * 1024) {
      return '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(byteSize / 1024).round()} KB';
  }

  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'mediaType': mediaType,
    'byteSize': byteSize,
    'summary': summary,
    'pageCount': pageCount,
    'demoMetadataOnly': demoMetadataOnly,
  };

  factory AssignmentAttachment.fromJson(Map<String, Object?> json) =>
      AssignmentAttachment(
        fileName: json['fileName'] as String? ?? '',
        mediaType: json['mediaType'] as String? ?? 'application/octet-stream',
        byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
        summary: json['summary'] as String? ?? '',
        pageCount: (json['pageCount'] as num?)?.toInt(),
        demoMetadataOnly: json['demoMetadataOnly'] as bool? ?? true,
      );
}

@immutable
class StaffAssignment {
  const StaffAssignment({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.instructions,
    required this.cohortId,
    required this.cohortName,
    required this.responseType,
    required this.dueAt,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String instructions;
  final String cohortId;
  final String cohortName;
  final AssignmentResponseType responseType;
  final DateTime dueAt;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'instructions': instructions,
    'cohortId': cohortId,
    'cohortName': cohortName,
    'responseType': responseType.name,
    'dueAt': dueAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory StaffAssignment.fromJson(Map<String, Object?> json) =>
      StaffAssignment(
        id: json['id'] as String? ?? '',
        ownerId: json['ownerId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        cohortId: json['cohortId'] as String? ?? '',
        cohortName: json['cohortName'] as String? ?? '',
        responseType: _enumByName(
          AssignmentResponseType.values,
          json['responseType'],
          AssignmentResponseType.text,
        ),
        dueAt: _date(json['dueAt']) ?? DateTime.now(),
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
      );
}

@immutable
class AssignmentSubmission {
  const AssignmentSubmission({
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.submittedAt,
    this.responseText = '',
    this.attachment,
    this.reminderSentAt,
    this.feedback = '',
    this.feedbackStep,
    this.feedbackSentAt,
    this.grade,
    this.serverId,
  });

  final String assignmentId;
  final String studentId;
  final String studentName;
  final AssignmentSubmissionStatus status;
  final DateTime? submittedAt;
  final String responseText;
  final AssignmentAttachment? attachment;
  final DateTime? reminderSentAt;
  final String feedback;
  final AssignmentFeedbackStep? feedbackStep;
  final DateTime? feedbackSentAt;
  final int? grade;
  final int? serverId;

  bool get isSubmitted => status != AssignmentSubmissionStatus.notSubmitted;
  bool get needsFeedback =>
      status == AssignmentSubmissionStatus.submitted ||
      status == AssignmentSubmissionStatus.feedbackNeeded;
  bool get hasFeedback => feedbackSentAt != null && feedback.isNotEmpty;

  AssignmentSubmission copyWith({
    AssignmentSubmissionStatus? status,
    DateTime? reminderSentAt,
    String? feedback,
    AssignmentFeedbackStep? feedbackStep,
    DateTime? feedbackSentAt,
    int? grade,
  }) => AssignmentSubmission(
    assignmentId: assignmentId,
    studentId: studentId,
    studentName: studentName,
    status: status ?? this.status,
    submittedAt: submittedAt,
    responseText: responseText,
    attachment: attachment,
    reminderSentAt: reminderSentAt ?? this.reminderSentAt,
    feedback: feedback ?? this.feedback,
    feedbackStep: feedbackStep ?? this.feedbackStep,
    feedbackSentAt: feedbackSentAt ?? this.feedbackSentAt,
    grade: grade ?? this.grade,
    serverId: serverId,
  );

  Map<String, Object?> toJson() => {
    'assignmentId': assignmentId,
    'studentId': studentId,
    'studentName': studentName,
    'status': status.name,
    'submittedAt': submittedAt?.toIso8601String(),
    'responseText': responseText,
    'attachment': attachment?.toJson(),
    'reminderSentAt': reminderSentAt?.toIso8601String(),
    'feedback': feedback,
    'feedbackStep': feedbackStep?.name,
    'feedbackSentAt': feedbackSentAt?.toIso8601String(),
    'grade': grade,
    'serverId': serverId,
  };

  factory AssignmentSubmission.fromJson(Map<String, Object?> json) {
    final attachment = json['attachment'];
    return AssignmentSubmission(
      assignmentId: json['assignmentId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      status: _enumByName(
        AssignmentSubmissionStatus.values,
        json['status'],
        AssignmentSubmissionStatus.notSubmitted,
      ),
      submittedAt: _date(json['submittedAt']),
      responseText: json['responseText'] as String? ?? '',
      attachment: attachment is Map
          ? AssignmentAttachment.fromJson(Map<String, Object?>.from(attachment))
          : null,
      reminderSentAt: _date(json['reminderSentAt']),
      feedback: json['feedback'] as String? ?? '',
      feedbackStep: json['feedbackStep'] == null
          ? null
          : _enumByName(
              AssignmentFeedbackStep.values,
              json['feedbackStep'],
              AssignmentFeedbackStep.ready,
            ),
      feedbackSentAt: _date(json['feedbackSentAt']),
      grade: (json['grade'] as num?)?.toInt(),
      serverId: (json['serverId'] as num?)?.toInt(),
    );
  }
}

@immutable
class AssignmentWorkspaceSnapshot {
  const AssignmentWorkspaceSnapshot({
    required this.assignments,
    required this.submissions,
  });

  final List<StaffAssignment> assignments;
  final List<AssignmentSubmission> submissions;

  Map<String, Object?> toJson() => {
    'version': 1,
    'assignments': assignments.map((item) => item.toJson()).toList(),
    'submissions': submissions.map((item) => item.toJson()).toList(),
  };

  factory AssignmentWorkspaceSnapshot.fromJson(Map<String, Object?> json) =>
      AssignmentWorkspaceSnapshot(
        assignments: _maps(json['assignments'])
            .map(StaffAssignment.fromJson)
            .where((item) => item.id.isNotEmpty)
            .toList(),
        submissions: _maps(json['submissions'])
            .map(AssignmentSubmission.fromJson)
            .where(
              (item) =>
                  item.assignmentId.isNotEmpty && item.studentId.isNotEmpty,
            )
            .toList(),
      );
}

List<Map<String, Object?>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList()
    : const [];

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  return values.where((item) => item.name == name).firstOrNull ?? fallback;
}
