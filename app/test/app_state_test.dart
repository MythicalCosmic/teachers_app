import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';

void main() {
  group('AppState session and persistence', () {
    test(
      'clean install starts signed out and restores a remembered session',
      () async {
        final storage = MemoryAppStorage();
        final state = await AppState.bootstrap(storage: storage);

        expect(state.session, isNull);
        await state.signIn(username: 'nigora.karimova', password: 'demo2026');
        expect(state.session?.role, StaffRole.teacher);

        final restored = await AppState.bootstrap(storage: storage);
        expect(restored.session?.userId, state.session?.userId);
      },
    );

    test('unremembered session remains in memory only', () async {
      final storage = MemoryAppStorage();
      final state = await AppState.bootstrap(storage: storage);
      await state.signIn(
        username: 'sardor.aliyev',
        password: 'demo2026',
        persistSession: false,
      );

      expect(state.session?.role, StaffRole.assistant);
      expect((await AppState.bootstrap(storage: storage)).session, isNull);
    });

    test('invalid credentials do not create a session', () async {
      final state = await AppState.bootstrap(storage: MemoryAppStorage());
      await expectLater(
        state.signIn(username: 'nigora.karimova', password: 'wrong-password'),
        throwsA(isA<AuthenticationException>()),
      );
      expect(state.session, isNull);
    });
  });

  group('AppState workflows and permissions', () {
    test('teacher can create and complete a persisted task', () async {
      final storage = MemoryAppStorage();
      final state = await AppState.bootstrap(
        storage: storage,
        clock: () => DateTime.utc(2026, 7, 17, 12),
      );
      await state.signIn(username: 'nigora.karimova', password: 'demo2026');

      final task = await state.createTask(
        title: 'Yangi dars rejasini tayyorlash',
        checklist: const ['Maqsad', 'Mashqlar'],
      );
      await state.toggleTaskChecklistItem(task.id, task.checklist.first.id);
      await state.setTaskStatus(task.id, TaskStatus.done);

      expect(state.tasks.first.status, TaskStatus.done);
      expect(state.tasks.first.completedSteps, 1);
      expect(
        (await AppState.bootstrap(storage: storage)).tasks.first.status,
        TaskStatus.done,
      );
    });

    test('assistant cannot issue a recognition card', () async {
      final state = await AppState.bootstrap(storage: MemoryAppStorage());
      await state.signIn(username: 'sardor.aliyev', password: 'demo2026');

      expect(state.can(StaffCapability.issueCards), isFalse);
      await expectLater(
        state.issueCard(
          studentId: 'student-1',
          studentName: 'Akmal Akbarov',
          cohortName: '9-B',
          kind: CardKind.praise,
          label: 'Yulduz',
          reason: 'Mustaqil yechim',
        ),
        throwsStateError,
      );
    });

    test('auditor can acknowledge a signal and manage a case', () async {
      final state = await AppState.bootstrap(
        storage: MemoryAppStorage(),
        clock: () => DateTime.utc(2026, 7, 17, 12),
      );
      await state.signIn(username: 'aziz.audit', password: 'demo2026');
      final signal = state.auditAnomalies.first;

      await state.acknowledgeAnomaly(signal.id);
      final auditCase = await state.createAuditCase(
        title: 'Davomat signalini tekshirish',
        description: signal.description,
        severity: signal.severity,
        anomalyIds: [signal.id],
      );
      await state.addAuditCaseNote(auditCase.id, 'Manba yozuvi tekshirildi.');
      await state.setAuditCaseStatus(auditCase.id, AuditCaseStatus.resolved);

      expect(state.auditAnomalies.first.status, AnomalyStatus.linked);
      expect(state.auditCases.first.status, AuditCaseStatus.resolved);
      expect(
        state.auditCases.first.notes,
        contains('Manba yozuvi tekshirildi.'),
      );
    });
  });
}
