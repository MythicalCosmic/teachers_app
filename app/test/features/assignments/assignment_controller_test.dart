import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/features/assignments/assignment_controller.dart';
import 'package:starforge_staff/features/assignments/assignment_models.dart';
import 'package:starforge_staff/features/assignments/assignment_storage.dart';

void main() {
  final now = DateTime(2026, 7, 18, 12);

  test('create assignment and response type survive restoration', () async {
    final storage = MemoryAssignmentStorage();
    final controller = AssignmentController(storage: storage, clock: () => now);
    controller.initialize(ownerId: 'teacher-1');
    await controller.restored;

    final created = await controller.createAssignment(
      title: 'Mustaqil tahlil',
      instructions: 'Grafikni matnda tahlil qilib, aniq xulosa yozing.',
      cohortId: 'cohort-9a-algebra',
      responseType: AssignmentResponseType.text,
      dueAt: now.add(const Duration(days: 4)),
    );
    await controller.flushPersistence();

    final restored = AssignmentController(storage: storage, clock: () => now);
    restored.initialize(ownerId: 'teacher-1');
    await restored.restored;
    final assignment = restored.assignmentById(created.id);

    expect(assignment, isNotNull);
    expect(assignment!.responseType, AssignmentResponseType.text);
    expect(assignment.instructions, contains('aniq xulosa'));
    expect(restored.submissionsFor(created.id), hasLength(5));
    expect(
      restored.submissionsFor(created.id),
      everyElement(
        isA<AssignmentSubmission>().having(
          (item) => item.status,
          'status',
          AssignmentSubmissionStatus.notSubmitted,
        ),
      ),
    );
  });

  test('reminder timestamp persists for the real student id', () async {
    final storage = MemoryAssignmentStorage();
    final controller = AssignmentController(storage: storage, clock: () => now);
    controller.initialize(ownerId: 'teacher-1');
    await controller.restored;

    await controller.sendReminder(
      assignmentId: 'assignment-quadratic-9b',
      studentId: 'student-otabek-eshmatov',
    );

    final restored = AssignmentController(storage: storage, clock: () => now);
    restored.initialize(ownerId: 'teacher-1');
    await restored.restored;
    final submission = restored.submissionById(
      'assignment-quadratic-9b',
      'student-otabek-eshmatov',
    );

    expect(submission?.reminderSentAt, now);
    expect(submission?.status, AssignmentSubmissionStatus.notSubmitted);
  });

  test('feedback, next-step status, and grade persist together', () async {
    final storage = MemoryAssignmentStorage();
    final controller = AssignmentController(storage: storage, clock: () => now);
    controller.initialize(ownerId: 'teacher-1');
    await controller.restored;

    await controller.saveFeedback(
      assignmentId: 'assignment-quadratic-9b',
      studentId: 'student-akmal-akbarov',
      feedback:
          'Yechim kuchli, ammo to‘rtinchi misol ishorasini qayta tekshiring.',
      step: AssignmentFeedbackStep.revise,
      grade: 82,
    );

    final restored = AssignmentController(storage: storage, clock: () => now);
    restored.initialize(ownerId: 'teacher-1');
    await restored.restored;
    final submission = restored.submissionById(
      'assignment-quadratic-9b',
      'student-akmal-akbarov',
    );

    expect(submission?.status, AssignmentSubmissionStatus.revisionRequested);
    expect(submission?.feedbackStep, AssignmentFeedbackStep.revise);
    expect(submission?.grade, 82);
    expect(submission?.feedback, contains('qayta tekshiring'));
    expect(submission?.feedbackSentAt, now);
  });

  test(
    'demo attachment is honest metadata without bundled file bytes',
    () async {
      final controller = AssignmentController(
        storage: MemoryAssignmentStorage(),
        clock: () => now,
      );
      controller.initialize(ownerId: 'teacher-1');
      await controller.restored;
      final submission = controller.submissionById(
        'assignment-quadratic-9b',
        'student-akmal-akbarov',
      );

      expect(submission?.attachment?.fileName, endsWith('.pdf'));
      expect(submission?.attachment?.byteSize, greaterThan(0));
      expect(submission?.attachment?.demoMetadataOnly, isTrue);
    },
  );

  test('mutations are guarded until restoration completes', () async {
    final storage = _DelayedStorage();
    final controller = AssignmentController(storage: storage, clock: () => now);
    controller.initialize(ownerId: 'teacher-1');

    expect(controller.isRestoring, isTrue);
    await expectLater(
      controller.createAssignment(
        title: 'Guarded assignment',
        instructions: 'This write must wait for restoration.',
        cohortId: 'cohort-9b-algebra',
        responseType: AssignmentResponseType.document,
        dueAt: now.add(const Duration(days: 2)),
      ),
      throwsA(isA<StateError>()),
    );

    storage.completeRead();
    await controller.restored;
    expect(controller.isRestoring, isFalse);
  });
}

class _DelayedStorage implements AssignmentStorage {
  final Completer<String?> _read = Completer<String?>();
  String? value;

  void completeRead() => _read.complete(value);

  @override
  Future<String?> read(String ownerId) => _read.future;

  @override
  Future<void> write(String ownerId, String value) async {
    this.value = value;
  }
}
