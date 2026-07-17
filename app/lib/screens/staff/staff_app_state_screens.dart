import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../widgets/sf_icons.dart';
import 'audit_workspace_screens.dart';
import 'methodist_quality_screen.dart';
import 'reception_workspace_screen.dart';
import 'staff_more_hub_screen.dart';
import 'staff_surface_widgets.dart';
import 'staff_today_screen.dart';
import 'staff_workspace_models.dart';

/// AppScope-connected route surfaces. Presentation widgets remain separately
/// testable, while these wrappers are the production integration boundary.

class StaffTodayRouteScreen extends StatelessWidget {
  const StaffTodayRouteScreen({
    super.key,
    this.onOpenTask,
    this.onOpenPrimaryWorkspace,
    this.onOpenMessages,
  });

  final ValueChanged<String>? onOpenTask;
  final VoidCallback? onOpenPrimaryWorkspace;
  final VoidCallback? onOpenMessages;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return StaffTodayScreen(
      role: session.role,
      session: session,
      tasks: state.tasks,
      attendanceSheets: state.attendanceSheets,
      unreadMessages: state.unreadMessageCount,
      onCompleteTask: (id) => state.setTaskStatus(id, TaskStatus.done),
      onOpenTask: onOpenTask,
      onOpenPrimaryWorkspace: onOpenPrimaryWorkspace,
      onOpenMessages: onOpenMessages,
    );
  }
}

class MethodistQualityRouteScreen extends StatelessWidget {
  const MethodistQualityRouteScreen({super.key, this.onOpenTeacher});

  final ValueChanged<String>? onOpenTeacher;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return MethodistQualityScreen(
      role: session.role,
      attendanceSheets: state.attendanceSheets,
      cards: state.cards,
      tasks: state.tasks,
      onOpenTeacher: onOpenTeacher,
      onCreateFollowUp: (signal) {
        state.createTask(
          title: signal.title,
          description: '${signal.teacherName}: ${signal.subtitle}',
          priority: signal.tone == QualitySignalTone.urgent
              ? TaskPriority.high
              : TaskPriority.medium,
          checklist: const [
            'Kontekstni tekshirish',
            'Ustoz bilan suhbat',
            'Natijani qayd etish',
          ],
        );
      },
    );
  }
}

class ReceptionWorkspaceRouteScreen extends StatelessWidget {
  const ReceptionWorkspaceRouteScreen({
    super.key,
    this.store,
    this.onCall,
    this.onOpenLead,
    this.onCreateLead,
  });

  final ReceptionWorkspaceStore? store;
  final ValueChanged<String>? onCall;
  final ValueChanged<String>? onOpenLead;
  final VoidCallback? onCreateLead;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return ReceptionWorkspaceScreen(
      role: session.role,
      store: store,
      onCall: onCall,
      onOpenLead: onOpenLead,
      onCreateLead: onCreateLead,
    );
  }
}

class AuditorDashboardRouteScreen extends StatelessWidget {
  const AuditorDashboardRouteScreen({
    super.key,
    this.onOpenSignals,
    this.onOpenCases,
    this.onOpenAuditLog,
    this.onOpenSignal,
  });

  final VoidCallback? onOpenSignals;
  final VoidCallback? onOpenCases;
  final VoidCallback? onOpenAuditLog;
  final ValueChanged<String>? onOpenSignal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return AuditorDashboardScreen(
      role: session.role,
      anomalies: state.auditAnomalies,
      cases: state.auditCases,
      onOpenSignals: onOpenSignals,
      onOpenCases: onOpenCases,
      onOpenAuditLog: onOpenAuditLog,
      onOpenSignal: onOpenSignal,
    );
  }
}

class AuditSignalsRouteScreen extends StatelessWidget {
  const AuditSignalsRouteScreen({super.key, this.onOpenSignal});

  final ValueChanged<String>? onOpenSignal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return AuditSignalsScreen(
      role: session.role,
      anomalies: state.auditAnomalies,
      onOpenSignal: onOpenSignal,
      onAcknowledge: state.acknowledgeAnomaly,
    );
  }
}

class AuditSignalDetailRouteScreen extends StatelessWidget {
  const AuditSignalDetailRouteScreen({
    super.key,
    required this.anomalyId,
    this.onBack,
    this.onCaseCreated,
  });

  final String anomalyId;
  final VoidCallback? onBack;
  final ValueChanged<String>? onCaseCreated;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    final anomaly = _findById(
      state.auditAnomalies,
      anomalyId,
      (item) => item.id,
    );
    if (anomaly == null) {
      return const _MissingStaffRecord(label: 'Signal topilmadi');
    }
    return AuditSignalDetailScreen(
      role: session.role,
      anomaly: anomaly,
      onBack: onBack,
      onAcknowledge: state.acknowledgeAnomaly,
      onCreateCase: (item) async {
        final created = await state.createAuditCase(
          title: item.title,
          description: item.description,
          severity: item.severity,
          anomalyIds: [item.id],
        );
        onCaseCreated?.call(created.id);
      },
    );
  }
}

class AuditCasesRouteScreen extends StatelessWidget {
  const AuditCasesRouteScreen({super.key, this.onOpenCase, this.onCreateCase});

  final ValueChanged<String>? onOpenCase;
  final VoidCallback? onCreateCase;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return AuditCasesScreen(
      role: session.role,
      cases: state.auditCases,
      onOpenCase: onOpenCase,
      onCreateCase: onCreateCase,
    );
  }
}

class AuditCaseDetailRouteScreen extends StatelessWidget {
  const AuditCaseDetailRouteScreen({
    super.key,
    required this.caseId,
    this.onBack,
  });

  final String caseId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    final auditCase = _findById(state.auditCases, caseId, (item) => item.id);
    if (auditCase == null) {
      return const _MissingStaffRecord(label: 'Holat topilmadi');
    }
    return AuditCaseDetailScreen(
      role: session.role,
      auditCase: auditCase,
      onBack: onBack,
      onAddNote: state.addAuditCaseNote,
      onSetStatus: state.setAuditCaseStatus,
    );
  }
}

class ImmutableAuditLogRouteScreen extends StatelessWidget {
  const ImmutableAuditLogRouteScreen({super.key, this.onExport});

  final Future<void> Function()? onExport;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return ImmutableAuditLogScreen(
      role: session.role,
      events: _auditEvents(state.auditAnomalies, state.auditCases),
      onExport: onExport,
    );
  }
}

class StaffMoreHubRouteScreen extends StatelessWidget {
  const StaffMoreHubRouteScreen({
    super.key,
    this.onOpenRoute,
    this.onSignedOut,
  });

  final ValueChanged<String>? onOpenRoute;
  final VoidCallback? onSignedOut;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final session = state.session;
    if (session == null) return const _SignedOutStaffSurface();
    return StaffMoreHubScreen(
      role: session.role,
      displayName: session.displayName,
      branchName: session.branchName,
      unreadMessages: state.unreadMessageCount,
      unreadNotifications: state.unreadNotificationCount,
      onOpenRoute: onOpenRoute,
      onSignOut: () async {
        await state.signOut();
        onSignedOut?.call();
      },
    );
  }
}

T? _findById<T>(Iterable<T> items, String id, String Function(T) idOf) {
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

List<ImmutableAuditEventView> _auditEvents(
  List<AuditAnomaly> anomalies,
  List<AuditCase> cases,
) {
  final events = <ImmutableAuditEventView>[
    for (final anomaly in anomalies)
      ImmutableAuditEventView(
        id: 'signal-${anomaly.id}',
        actor: anomaly.acknowledgedById ?? 'Tizim detektori',
        action: anomaly.acknowledgedById == null
            ? 'Signal yaratildi'
            : 'Signal ko\u2018rib chiqildi',
        entity: anomaly.entityLabel,
        occurredAt: anomaly.detectedAt,
        integrityHash: _integrityHash(
          'signal:${anomaly.id}:${anomaly.status.name}',
        ),
      ),
    for (final auditCase in cases)
      ImmutableAuditEventView(
        id: 'case-${auditCase.id}',
        actor: auditCase.openedById,
        action: 'Audit holati · ${auditCase.status.name}',
        entity: auditCase.title,
        occurredAt: auditCase.resolvedAt ?? auditCase.openedAt,
        integrityHash: _integrityHash(
          'case:${auditCase.id}:${auditCase.status.name}:${auditCase.notes.length}',
        ),
      ),
  ];
  events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return events;
}

String _integrityHash(String value) {
  var hash = 0x811C9DC5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final hex = hash.toRadixString(16).padLeft(8, '0');
  return 'sf-v1-$hex-${value.length.toRadixString(16).padLeft(4, '0')}';
}

class _SignedOutStaffSurface extends StatelessWidget {
  const _SignedOutStaffSurface();
  @override
  Widget build(BuildContext context) => const StaffPageScaffold(
    eyebrow: 'Sessiya',
    title: 'Tizimga kiring',
    subtitle: 'Xodim ma\u2018lumotlari himoyalangan',
    body: StaffEmptyState(
      title: 'Faol sessiya yo\u2018q',
      message: 'Ish maydonini ochish uchun xodim hisobi bilan tizimga kiring.',
      icon: SfIcons.user,
    ),
  );
}

class _MissingStaffRecord extends StatelessWidget {
  const _MissingStaffRecord({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => StaffPageScaffold(
    eyebrow: 'Ma\u2018lumot',
    title: label,
    subtitle:
        'Yozuv o\u2018chirilgan yoki sizga ochilmagan bo\u2018lishi mumkin',
    body: const StaffEmptyState(
      title: 'Yozuv mavjud emas',
      message: 'Ro\u2018yxatga qaytib, ma\u2018lumotni yangilang.',
      icon: Icons.search_off_outlined,
    ),
  );
}
