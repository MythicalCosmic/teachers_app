import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/operations/staff_operations_controller.dart';

void main() {
  StaffOperationModule module(String id) => staffOperationModuleById(id)!;
  StaffSession remote(String slug, {StaffRole role = StaffRole.assistant}) =>
      StaffSession(
        userId: '1',
        displayName: 'Staff',
        role: role,
        branchId: '1',
        branchName: 'Center',
        email: 'staff@example.com',
        accountTypeSlug: slug,
        isRemote: true,
      );

  test('every staff service declares one capability and a unique id', () {
    expect(
      staffOperationModules.map((item) => item.id).toSet().length,
      staffOperationModules.length,
    );
    expect(
      staffOperationModules.every(
        (item) => item.requiredCapability != StaffCapability.viewStaffServices,
      ),
      isTrue,
    );
  });

  test('sensitive staff services are absent for roles without capability', () {
    for (final id in const [
      'payments',
      'risk',
      'procurement',
      'campaigns',
      'sales',
      'card-scans',
    ]) {
      expect(
        module(id).isVisibleFor(StaffRole.assistant),
        isFalse,
        reason: '$id must not be offered to an assistant',
      );
    }

    expect(module('payments').isVisibleFor(StaffRole.teacher), isFalse);
    expect(module('payments').isVisibleFor(StaffRole.methodist), isFalse);
    expect(module('payments').isVisibleFor(StaffRole.auditor), isFalse);
    expect(module('payments').isVisibleFor(StaffRole.reception), isTrue);
  });

  test('academic and risk services follow their declared capabilities', () {
    for (final id in const ['exams', 'grades', 'warnings', 'honor-roll']) {
      expect(module(id).isVisibleFor(StaffRole.teacher), isTrue);
      expect(module(id).isVisibleFor(StaffRole.methodist), isTrue);
      expect(module(id).isVisibleFor(StaffRole.reception), isFalse);
    }

    expect(module('risk').isVisibleFor(StaffRole.teacher), isTrue);
    expect(module('risk').isVisibleFor(StaffRole.methodist), isTrue);
    expect(module('risk').isVisibleFor(StaffRole.reception), isTrue);
    expect(module('risk').isVisibleFor(StaffRole.auditor), isTrue);
  });

  test('all roles retain only universal self-service entries', () {
    for (final role in StaffRole.values) {
      expect(module('rules').isVisibleFor(role), isTrue);
      expect(module('meetings').isVisibleFor(role), isTrue);
    }
  });

  test('remote reception workspace does not imply finance permission', () {
    StaffSession session(String slug) =>
        remote(slug, role: StaffRole.reception);

    expect(
      session('registrar').can(StaffCapability.viewPaymentStatus),
      isFalse,
    );
    expect(
      session('admissions_assistant').can(StaffCapability.viewPaymentStatus),
      isFalse,
    );
    expect(session('cashier').can(StaffCapability.viewPaymentStatus), isFalse);
    expect(
      session('accountant').can(StaffCapability.viewPaymentStatus),
      isTrue,
    );
    expect(
      session('cashier').can(StaffCapability.viewStudentRiskSignals),
      isFalse,
    );
    expect(
      session('accountant').can(StaffCapability.viewStudentRiskSignals),
      isFalse,
    );
    expect(
      session('registrar').can(StaffCapability.viewStudentRiskSignals),
      isTrue,
    );
    expect(session('cashier').can(StaffCapability.viewSales), isTrue);
    expect(session('registrar').can(StaffCapability.viewCardScans), isTrue);
    expect(session('accountant').can(StaffCapability.viewCardScans), isFalse);
  });

  test('base content grants follow backend publication policy', () {
    expect(StaffRole.teacher.can(StaffCapability.publishContent), isFalse);
    expect(StaffRole.teacher.can(StaffCapability.generateContent), isTrue);
    expect(StaffRole.methodist.can(StaffCapability.publishContent), isTrue);
    expect(StaffRole.methodist.can(StaffCapability.generateContent), isFalse);
  });

  test(
    'read-only system staff keep own tasks but not task or form creation',
    () {
      for (final entry in const {
        'accountant': StaffRole.reception,
        'cashier': StaffRole.reception,
        'librarian': StaffRole.assistant,
        'security': StaffRole.assistant,
        'it': StaffRole.assistant,
        'support': StaffRole.assistant,
        'finance_officer': StaffRole.reception,
        'payment_specialist': StaffRole.reception,
      }.entries) {
        final session = remote(entry.key, role: entry.value);
        expect(
          session.can(StaffCapability.createTasks),
          isFalse,
          reason: entry.key,
        );
        expect(
          session.can(StaffCapability.assignTasks),
          isFalse,
          reason: entry.key,
        );
        expect(
          session.can(StaffCapability.answerSurveys),
          isFalse,
          reason: entry.key,
        );
        expect(
          session.can(StaffCapability.updateOwnTasks),
          isTrue,
          reason: entry.key,
        );
      }
    },
  );

  test('system account types expose only their backend-backed workspaces', () {
    final accountant = remote('accountant', role: StaffRole.reception);
    expect(accountant.can(StaffCapability.viewReports), isTrue);
    expect(accountant.can(StaffCapability.takeAttendance), isFalse);
    expect(accountant.can(StaffCapability.useStaffMessaging), isFalse);
    expect(accountant.can(StaffCapability.submitPrintJobs), isFalse);

    final librarian = remote('senior_librarian');
    expect(librarian.can(StaffCapability.viewStudentDirectory), isTrue);
    expect(librarian.can(StaffCapability.viewContent), isTrue);
    expect(librarian.can(StaffCapability.manageContent), isTrue);
    expect(librarian.can(StaffCapability.generateContent), isTrue);
    expect(librarian.can(StaffCapability.viewAchievements), isFalse);
    expect(librarian.can(StaffCapability.takeAttendance), isFalse);
    expect(librarian.can(StaffCapability.useStaffMessaging), isFalse);

    final security = remote('security_guard');
    expect(security.can(StaffCapability.takeAttendance), isTrue);
    expect(security.can(StaffCapability.viewCardScans), isTrue);
    expect(security.can(StaffCapability.viewCohorts), isFalse);
    expect(security.can(StaffCapability.viewContent), isFalse);
    expect(security.can(StaffCapability.viewAchievements), isFalse);

    for (final slug in const ['it', 'support_agent']) {
      final session = remote(slug);
      expect(session.can(StaffCapability.viewCohorts), isFalse);
      expect(session.can(StaffCapability.takeAttendance), isFalse);
      expect(session.can(StaffCapability.viewContent), isFalse);
      expect(session.can(StaffCapability.useStaffMessaging), isFalse);
      expect(session.can(StaffCapability.submitPrintJobs), isFalse);
    }
  });

  test('registrar and unknown custom identities fail closed', () {
    final registrar = remote('registrar', role: StaffRole.reception);
    expect(registrar.can(StaffCapability.takeAttendance), isFalse);
    expect(registrar.can(StaffCapability.viewLeads), isTrue);

    final audit = remote('compliance_auditor', role: StaffRole.auditor);
    expect(audit.can(StaffCapability.viewAuditWorkspace), isTrue);
    expect(audit.can(StaffCapability.viewReports), isFalse);
    expect(audit.can(StaffCapability.viewStudentRiskSignals), isFalse);
    expect(audit.can(StaffCapability.createTasks), isFalse);
    expect(audit.can(StaffCapability.assignTasks), isFalse);
    expect(audit.can(StaffCapability.updateOwnTasks), isTrue);
    expect(audit.can(StaffCapability.answerSurveys), isFalse);
    expect(audit.can(StaffCapability.useStaffMessaging), isFalse);
    expect(audit.can(StaffCapability.submitPrintJobs), isFalse);

    final custom = remote('custom_front_desk');
    expect(custom.can(StaffCapability.viewStaffServices), isTrue);
    expect(custom.can(StaffCapability.acknowledgeStaffRules), isTrue);
    expect(custom.can(StaffCapability.createTasks), isFalse);
    expect(custom.can(StaffCapability.takeAttendance), isFalse);
    expect(custom.can(StaffCapability.viewContent), isFalse);
    expect(custom.can(StaffCapability.useStaffMessaging), isFalse);
  });
}
