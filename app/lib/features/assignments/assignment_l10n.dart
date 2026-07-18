import 'package:flutter/widgets.dart';

import 'assignment_models.dart';

class AssignmentL10n {
  const AssignmentL10n._(this._uzbek);

  final bool _uzbek;

  factory AssignmentL10n.of(BuildContext context) =>
      AssignmentL10n._(Localizations.localeOf(context).languageCode == 'uz');

  /// Russian intentionally uses English until reviewed Russian copy exists.
  String text(String uz, String en) => _uzbek ? uz : en;

  String assignmentTitle(StaffAssignment assignment) {
    if (_uzbek) return assignment.title;
    return switch (assignment.id) {
      'assignment-quadratic-9b' => 'Quadratic equations',
      'assignment-functions-9a' => 'Function graphs',
      'assignment-geometry-10v' => 'Written work · Geometry',
      'assignment-olympiad-11b' => 'Olympiad exercises',
      _ => assignment.title,
    };
  }

  String assignmentInstructions(StaffAssignment assignment) {
    if (_uzbek) return assignment.instructions;
    return switch (assignment.id) {
      'assignment-quadratic-9b' =>
        'Solve exercises 1–12 and explain every solution step.',
      'assignment-functions-9a' =>
        'Explain the graph properties in writing and provide a conclusion.',
      'assignment-geometry-10v' =>
        'Label the diagram clearly and submit a photo of the completed work.',
      'assignment-olympiad-11b' =>
        'Submit solutions to three selected problems in one PDF file.',
      _ => assignment.instructions,
    };
  }

  String cohortName(String value) {
    if (_uzbek) return value;
    return value
        .replaceAll('Geometriya', 'Geometry')
        .replaceAll('Tayyorlov', 'Preparation');
  }

  String responseLabel(AssignmentResponseType type) => switch (type) {
    AssignmentResponseType.text => text('Matnli javob', 'Text response'),
    AssignmentResponseType.document => text(
      'Hujjat yuklash',
      'Document upload',
    ),
    AssignmentResponseType.photo => text('Rasm yuklash', 'Photo upload'),
  };

  String responseHeading(AssignmentResponseType type) => switch (type) {
    AssignmentResponseType.text => text('MATNLI JAVOB', 'TEXT RESPONSE'),
    AssignmentResponseType.document => text(
      'HUJJATLI JAVOB',
      'DOCUMENT RESPONSE',
    ),
    AssignmentResponseType.photo => text('RASMLI JAVOB', 'PHOTO RESPONSE'),
  };

  String statusLabel(AssignmentSubmissionStatus status) => switch (status) {
    AssignmentSubmissionStatus.notSubmitted => text(
      'Topshirmagan',
      'Not submitted',
    ),
    AssignmentSubmissionStatus.submitted => text('Topshirildi', 'Submitted'),
    AssignmentSubmissionStatus.feedbackNeeded => text(
      'Fikr kerak',
      'Needs feedback',
    ),
    AssignmentSubmissionStatus.feedbackShared => text(
      'Yakunlangan',
      'Completed',
    ),
    AssignmentSubmissionStatus.revisionRequested => text(
      'Tuzatish',
      'Revision',
    ),
    AssignmentSubmissionStatus.conferenceRequested => text(
      'Suhbat',
      'Conference',
    ),
  };

  String stepLabel(AssignmentFeedbackStep value) => switch (value) {
    AssignmentFeedbackStep.ready => text('Tayyor', 'Ready'),
    AssignmentFeedbackStep.revise => text('Tuzatish kerak', 'Revision needed'),
    AssignmentFeedbackStep.conference => text(
      'Qisqa suhbat',
      'Short conference',
    ),
  };

  String submissionResponse(
    StaffAssignment assignment,
    AssignmentSubmission submission,
  ) {
    if (_uzbek || submission.responseText.isEmpty) {
      return submission.responseText;
    }
    return switch (assignment.id) {
      'assignment-quadratic-9b'
          when submission.studentId == 'student-akmal-akbarov' =>
        'I used the discriminant method. The sign change in exercise 4 is explained on the attached worksheet.',
      'assignment-quadratic-9b' =>
        'The solutions and verification steps are included in the response.',
      'assignment-functions-9a' =>
        'The increasing and decreasing intervals of the graph are explained in writing.',
      'assignment-geometry-10v' =>
        'The diagram and solution steps are described in the attachment metadata.',
      'assignment-olympiad-11b' =>
        'Solutions to three Olympiad problems are included.',
      _ => submission.responseText,
    };
  }

  String attachmentSummary(AssignmentAttachment attachment) {
    if (_uzbek) return attachment.summary;
    if (attachment.mediaType == 'application/pdf') {
      return attachment.pageCount == null
          ? 'PDF worksheet metadata.'
          : '${attachment.pageCount}-page scanned worksheet.';
    }
    if (attachment.mediaType.startsWith('image/')) {
      return 'Demo diagram photo metadata.';
    }
    return 'Demo attachment metadata.';
  }
}
