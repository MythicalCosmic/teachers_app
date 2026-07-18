import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';

void main() {
  late AppState state;

  setUp(() async {
    state = await AppState.bootstrap(
      storage: MemoryAppStorage(),
      clock: () => DateTime.utc(2026, 5, 20, 12),
    );
    await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  });

  test('teacher completes and submits attendance exactly once', () async {
    final sheet = state.attendanceSheets.first;
    final missing = sheet.entries.where((entry) => entry.status == null);

    for (final entry in missing) {
      await state.markAttendance(
        sheetId: sheet.id,
        studentId: entry.studentId,
        status: AttendanceStatus.present,
      );
    }
    await state.submitAttendance(sheet.id);

    expect(state.attendanceSheets.first.isComplete, isTrue);
    expect(state.attendanceSheets.first.isSubmitted, isTrue);
    await expectLater(
      state.markAttendance(
        sheetId: sheet.id,
        studentId: sheet.entries.first.studentId,
        status: AttendanceStatus.absent,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('card issuing is role-gated and produces a receipt record', () async {
    final before = state.cards.length;
    final card = await state.issueCard(
      studentId: 'DEMO-2026-00042',
      studentName: 'Akbarov Akmal',
      cohortName: '9-B Algebra',
      kind: CardKind.praise,
      label: 'Yulduz karta',
      reason: 'Murakkab misolni mustaqil yechdi',
    );

    expect(state.cards.length, before + 1);
    expect(state.cards.first.id, card.id);

    await state.signOut();
    await state.signIn(username: 'sardor.aliyev', password: 'demo2026');
    expect(state.can(StaffCapability.issueCards), isFalse);
    await expectLater(
      state.issueCard(
        studentId: 'DEMO-2026-00042',
        studentName: 'Akbarov Akmal',
        cohortName: '9-B Algebra',
        kind: CardKind.praise,
        label: 'Yulduz karta',
        reason: 'Aniq va foydali sabab',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('task checklist and status remain interactive', () async {
    final task = await state.createTask(
      title: 'Sinov uchun vazifa',
      checklist: const ['Birinchi qadam', 'Ikkinchi qadam'],
    );

    await state.toggleTaskChecklistItem(task.id, task.checklist.first.id);
    await state.setTaskStatus(task.id, TaskStatus.inProgress);

    final updated = state.tasks.firstWhere((item) => item.id == task.id);
    expect(updated.completedSteps, 1);
    expect(updated.status, TaskStatus.inProgress);
  });

  test('survey progress persists before final immutable submission', () async {
    final survey = state.surveys.first;
    await state.answerSurvey(survey.id, 'survey-001-q2', 'Slaydlar');
    await state.answerSurvey(
      survey.id,
      'survey-001-q3',
      'Ko‘proq amaliy misollar ishlataman.',
    );
    await state.submitSurvey(survey.id);

    final submitted = state.surveys.firstWhere((item) => item.id == survey.id);
    expect(submitted.progress, 1);
    expect(submitted.isSubmitted, isTrue);
    await expectLater(
      state.answerSurvey(survey.id, 'survey-001-q3', 'O‘zgartirish'),
      throwsA(isA<StateError>()),
    );
  });

  test('clearing a survey draft removes the persisted answer', () async {
    final survey = state.surveys.first;
    const questionId = 'survey-001-q3';
    final originalCount = survey.answeredCount;

    await state.answerSurvey(survey.id, questionId, 'Draft reflection');
    expect(state.surveys.first.answers[questionId], 'Draft reflection');
    expect(state.surveys.first.answeredCount, originalCount + 1);

    await state.answerSurvey(survey.id, questionId, '   ');
    expect(state.surveys.first.answers, isNot(contains(questionId)));
    expect(state.surveys.first.answeredCount, originalCount);
  });
}
