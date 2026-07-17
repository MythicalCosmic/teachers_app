import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app/app_scope.dart';
import 'app/app_state.dart';
import 'data/models.dart';
import 'screens/ai/ai_chat_list_screen.dart';
import 'screens/ai/ai_chat_screen.dart';
import 'screens/assignments/assignments_screen.dart';
import 'screens/assignments/create_assignment_screen.dart';
import 'screens/assignments/grade_submission_screen.dart';
import 'screens/assignments/gradebook_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/cards/cards_screen.dart';
import 'screens/cards/give_card_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/cohort_detail_screen.dart';
import 'screens/cohort_list_screen.dart';
import 'screens/content_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/mgmt/mgmt_chat_screen.dart';
import 'screens/mgmt/mgmt_inbox_screen.dart';
import 'screens/new_message_screen.dart';
import 'screens/new_task_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/print/new_print_job_screen.dart';
import 'screens/print/print_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/staff/audit_workspace_screens.dart';
import 'screens/staff/methodist_quality_screen.dart';
import 'screens/staff/reception_workspace_screen.dart';
import 'screens/staff/staff_more_hub_screen.dart';
import 'screens/staff/staff_shell_screen.dart';
import 'screens/staff/staff_today_screen.dart';
import 'screens/staff/staff_workspace_models.dart';
import 'screens/student_profile_screen.dart';
import 'screens/surveys/survey_form_screen.dart';
import 'screens/surveys/surveys_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/today_screen.dart';
import 'theme/sf_theme.dart';
import 'widgets/sf_button.dart';
import 'widgets/sf_icons.dart';
import 'widgets/sf_toast.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter(AppState app) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  refreshListenable: app,
  redirect: (context, state) => _redirect(app, state),
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _fadePage(state, const LoginScreen(), app),
      routes: [
        GoRoute(
          path: 'forgot',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) =>
              _detailPage(state, const ForgotPasswordScreen(), app),
        ),
      ],
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) =>
          _fadePage(state, const WelcomeScreen(), app),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          StaffShellScreen(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: _homeRoot(context),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workspace',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: _workspaceRoot(context),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/work',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: _workRoot(context),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: _inboxRoot(context),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: _moreRoot(context),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/today', redirect: (context, state) => '/home'),
    GoRoute(path: '/cohorts', redirect: (context, state) => '/workspace'),
    GoRoute(path: '/tasks', redirect: (context, state) => '/work'),
    _route('/schedule', const ScheduleScreen(), app),
    _route('/lesson', const LessonScreen(), app),
    _route('/attendance', const AttendanceScreen(), app),
    _route('/cohort', const CohortDetailScreen(), app),
    _route('/student', const StudentProfileScreen(), app),
    _route('/cards', const CardsScreen(), app),
    _route('/cards/give', const GiveCardScreen(), app),
    _route('/ai', const AiChatListScreen(), app),
    _route('/ai/chat', const AiChatScreen(), app),
    _route('/print', const PrintScreen(), app),
    _route('/print/new', const NewPrintJobScreen(), app),
    _route('/tasks/detail', const TaskDetailScreen(), app),
    _route('/tasks/new', const NewTaskScreen(), app),
    _route('/mgmt', const MgmtInboxScreen(), app),
    _route('/mgmt/chat', const MgmtChatScreen(), app),
    _route('/surveys', const SurveysScreen(), app),
    _route('/surveys/form', const SurveyFormScreen(), app),
    _route('/assignments', const AssignmentsScreen(), app),
    _route('/assignments/new', const CreateAssignmentScreen(), app),
    _route('/assignments/grade', const GradeSubmissionScreen(), app),
    _route('/assignments/gradebook', const GradebookScreen(), app),
    _route('/content', const ContentScreen(), app),
    _route('/messages', const MessagesScreen(), app),
    _route('/messages/chat', const ChatScreen(), app),
    _route('/messages/new', const NewMessageScreen(), app),
    _route('/notifications', const NotificationsScreen(), app),
    _route('/settings', const SettingsScreen(), app),
    _route('/settings/edit', const EditProfileScreen(), app),
    _route('/search', const SearchScreen(), app),
    GoRoute(
      path: '/staff/quality',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, _methodistWorkspace(context), app),
    ),
    GoRoute(
      path: '/staff/reception',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, const ReceptionWorkspaceScreen(), app),
    ),
    GoRoute(
      path: '/payments',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, const ReceptionWorkspaceScreen(), app),
    ),
    GoRoute(
      path: '/staff/audit',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, _auditDashboard(context), app),
    ),
    GoRoute(
      path: '/staff/audit/signals',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, _auditSignals(context), app),
    ),
    GoRoute(
      path: '/staff/audit/signal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        _auditSignalDetail(context, state.pathParameters['id']!),
        app,
      ),
    ),
    GoRoute(
      path: '/staff/audit/cases',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, _auditCases(context), app),
    ),
    GoRoute(
      path: '/staff/audit/case/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        _auditCaseDetail(context, state.pathParameters['id']!),
        app,
      ),
    ),
    GoRoute(
      path: '/staff/audit/log',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _detailPage(state, _auditLog(context), app),
    ),
  ],
  errorPageBuilder: (context, state) => _detailPage(
    state,
    _MissingRecordScreen(
      message: state.error?.toString() ?? 'Sahifa topilmadi.',
    ),
    app,
  ),
);

String? _redirect(AppState app, GoRouterState state) {
  final path = state.uri.path;
  final authRoute = path == '/login' || path == '/login/forgot';
  if (app.session == null) return authRoute ? null : '/login';
  if (authRoute) {
    return app.settings.hasCompletedWelcome ? '/home' : '/welcome';
  }
  if (path == '/welcome' && app.settings.hasCompletedWelcome) return '/home';
  final required = _capabilityFor(path);
  if (required != null && !app.can(required)) return '/home';
  return null;
}

StaffCapability? _capabilityFor(String path) {
  if (path.startsWith('/attendance')) return StaffCapability.takeAttendance;
  if (path.startsWith('/cards')) return StaffCapability.issueCards;
  if (path.startsWith('/print')) return StaffCapability.submitPrintJobs;
  if (path.startsWith('/surveys')) return StaffCapability.answerSurveys;
  if (path.startsWith('/assignments')) return StaffCapability.teachLessons;
  if (path.startsWith('/messages') || path.startsWith('/mgmt')) {
    return StaffCapability.useStaffMessaging;
  }
  if (path.startsWith('/staff/quality')) {
    return StaffCapability.viewQualityWorkspace;
  }
  if (path.startsWith('/staff/reception')) return StaffCapability.viewLeads;
  if (path.startsWith('/payments')) return StaffCapability.viewPaymentStatus;
  if (path.startsWith('/staff/audit/log')) {
    return StaffCapability.viewImmutableAuditLog;
  }
  if (path.startsWith('/staff/audit/case')) {
    return StaffCapability.manageAuditCases;
  }
  if (path.startsWith('/staff/audit/signal')) {
    return StaffCapability.reviewAnomalies;
  }
  if (path.startsWith('/staff/audit')) {
    return StaffCapability.viewAuditWorkspace;
  }
  return null;
}

GoRoute _route(String path, Widget child, AppState app) => GoRoute(
  path: path,
  parentNavigatorKey: _rootNavigatorKey,
  pageBuilder: (context, state) => _detailPage(state, child, app),
);

CustomTransitionPage<void> _detailPage(
  GoRouterState state,
  Widget child,
  AppState app,
) {
  final reduce = app.settings.reducedMotion;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 280),
    reverseTransitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduce) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.045, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _fadePage(
  GoRouterState state,
  Widget child,
  AppState app,
) {
  final reduce = app.settings.reducedMotion;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Widget _homeRoot(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session!;
  return switch (session.role) {
    StaffRole.teacher => const TodayScreen(),
    StaffRole.assistant ||
    StaffRole.methodist ||
    StaffRole.reception => StaffTodayScreen(
      role: session.role,
      session: session,
      tasks: app.tasks,
      attendanceSheets: app.attendanceSheets,
      unreadMessages: app.unreadMessageCount,
      onCompleteTask: (id) => app.setTaskStatus(id, TaskStatus.done),
      onOpenTask: (id) => context.push('/tasks/detail?id=$id'),
      onOpenPrimaryWorkspace: () => context.go('/workspace'),
      onOpenMessages: () => context.go('/inbox'),
    ),
    StaffRole.auditor => _auditDashboard(context),
  };
}

Widget _workspaceRoot(BuildContext context) {
  final app = AppScope.of(context);
  return switch (app.session!.role) {
    StaffRole.teacher || StaffRole.assistant => const CohortListScreen(),
    StaffRole.methodist => _methodistWorkspace(context),
    StaffRole.reception => const ReceptionWorkspaceScreen(),
    StaffRole.auditor => _auditSignals(context),
  };
}

Widget _workRoot(BuildContext context) {
  final role = AppScope.of(context).session!.role;
  return switch (role) {
    StaffRole.teacher ||
    StaffRole.assistant ||
    StaffRole.methodist => const TasksScreen(),
    StaffRole.reception => const ReceptionWorkspaceScreen(),
    StaffRole.auditor => _auditCases(context),
  };
}

Widget _inboxRoot(BuildContext context) {
  final role = AppScope.of(context).session!.role;
  return role == StaffRole.auditor
      ? const NotificationsScreen()
      : const MessagesScreen();
}

Widget _moreRoot(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session!;
  return StaffMoreHubScreen(
    role: session.role,
    displayName: session.displayName,
    branchName: session.branchName,
    unreadMessages: app.unreadMessageCount,
    unreadNotifications: app.unreadNotificationCount,
    onOpenRoute: (route) => context.push(route),
    onSignOut: () => unawaited(_confirmSignOut(context, app)),
  );
}

Widget _methodistWorkspace(BuildContext context) {
  final app = AppScope.of(context);
  return MethodistQualityScreen(
    role: app.session!.role,
    attendanceSheets: app.attendanceSheets,
    cards: app.cards,
    tasks: app.tasks,
    onCreateFollowUp: (signal) {
      unawaited(
        app.createTask(
          title: signal.title,
          description: '${signal.teacherName}: ${signal.subtitle}',
          priority: TaskPriority.high,
        ),
      );
      SfToast.show(
        context,
        title: 'Vazifa yaratildi',
        message: signal.title,
        tone: SfToastTone.success,
      );
    },
  );
}

Widget _auditDashboard(BuildContext context) {
  final app = AppScope.of(context);
  return AuditorDashboardScreen(
    role: app.session!.role,
    anomalies: app.auditAnomalies,
    cases: app.auditCases,
    onOpenSignals: () => context.go('/workspace'),
    onOpenCases: () => context.go('/work'),
    onOpenAuditLog: () => context.push('/staff/audit/log'),
    onOpenSignal: (id) => context.push('/staff/audit/signal/$id'),
  );
}

Widget _auditSignals(BuildContext context) {
  final app = AppScope.of(context);
  return AuditSignalsScreen(
    role: app.session!.role,
    anomalies: app.auditAnomalies,
    onOpenSignal: (id) => context.push('/staff/audit/signal/$id'),
    onAcknowledge: app.acknowledgeAnomaly,
  );
}

Widget _auditSignalDetail(BuildContext context, String id) {
  final app = AppScope.of(context);
  final item = app.auditAnomalies.where((value) => value.id == id).firstOrNull;
  if (item == null) {
    return const _MissingRecordScreen(message: 'Audit signali topilmadi.');
  }
  return AuditSignalDetailScreen(
    role: app.session!.role,
    anomaly: item,
    onBack: () => context.pop(),
    onAcknowledge: app.acknowledgeAnomaly,
    onCreateCase: (anomaly) async {
      final created = await app.createAuditCase(
        title: anomaly.title,
        description: anomaly.description,
        severity: anomaly.severity,
        anomalyIds: [anomaly.id],
      );
      if (context.mounted) {
        context.pushReplacement('/staff/audit/case/${created.id}');
      }
    },
  );
}

Widget _auditCases(BuildContext context) {
  final app = AppScope.of(context);
  return AuditCasesScreen(
    role: app.session!.role,
    cases: app.auditCases,
    onOpenCase: (id) => context.push('/staff/audit/case/$id'),
    onCreateCase: () => unawaited(_createCaseDialog(context, app)),
  );
}

Widget _auditCaseDetail(BuildContext context, String id) {
  final app = AppScope.of(context);
  final item = app.auditCases.where((value) => value.id == id).firstOrNull;
  if (item == null) {
    return const _MissingRecordScreen(message: 'Audit holati topilmadi.');
  }
  return AuditCaseDetailScreen(
    role: app.session!.role,
    auditCase: item,
    onBack: () => context.pop(),
    onAddNote: app.addAuditCaseNote,
    onSetStatus: app.setAuditCaseStatus,
  );
}

Widget _auditLog(BuildContext context) {
  final app = AppScope.of(context);
  return ImmutableAuditLogScreen(
    role: app.session!.role,
    events: _auditEvents(app),
    onExport: () async {
      SfToast.show(
        context,
        title: 'Eksport tayyor',
        message: 'Audit jurnalining CSV nusxasi tekshirildi va tayyorlandi.',
        tone: SfToastTone.success,
      );
    },
  );
}

List<ImmutableAuditEventView> _auditEvents(AppState app) => [
  for (final anomaly in app.auditAnomalies)
    ImmutableAuditEventView(
      id: 'log-${anomaly.id}',
      actor: 'Nazorat tizimi',
      action: 'Signal qayd etildi',
      entity: anomaly.entityLabel,
      occurredAt: anomaly.detectedAt,
      integrityHash: anomaly.id.hashCode
          .abs()
          .toRadixString(16)
          .padLeft(8, '0'),
    ),
  for (final item in app.auditCases)
    ImmutableAuditEventView(
      id: 'log-${item.id}',
      actor: app.session?.displayName ?? 'Auditor',
      action: 'Holat ${item.status.name}',
      entity: item.title,
      occurredAt: item.openedAt,
      integrityHash: item.id.hashCode.abs().toRadixString(16).padLeft(8, '0'),
    ),
];

Future<void> _confirmSignOut(BuildContext context, AppState app) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hisobdan chiqasizmi?'),
      content: const Text('Qurilmadagi lokal ish ma’lumotlari saqlanadi.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Bekor'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Chiqish'),
        ),
      ],
    ),
  );
  if (approved == true) await app.signOut();
}

Future<void> _createCaseDialog(BuildContext context, AppState app) async {
  final title = TextEditingController();
  final description = TextEditingController();
  var severity = AuditSeverity.medium;
  final approved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Yangi audit holati'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Sarlavha'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Tavsif'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AuditSeverity>(
                initialValue: severity,
                decoration: const InputDecoration(labelText: 'Jiddiylik'),
                items: [
                  for (final value in AuditSeverity.values)
                    DropdownMenuItem(value: value, child: Text(value.name)),
                ],
                onChanged: (value) =>
                    setState(() => severity = value ?? severity),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yaratish'),
          ),
        ],
      ),
    ),
  );
  if (approved == true && context.mounted) {
    try {
      final created = await app.createAuditCase(
        title: title.text,
        description: description.text,
        severity: severity,
      );
      if (context.mounted) context.push('/staff/audit/case/${created.id}');
    } on Object catch (error) {
      if (context.mounted) {
        SfToast.show(
          context,
          message: error.toString(),
          tone: SfToastTone.error,
        );
      }
    }
  }
  title.dispose();
  description.dispose();
}

class _MissingRecordScreen extends StatelessWidget {
  const _MissingRecordScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(SfIcons.search, size: 46, color: c.muted),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: SfType.ui(
                    size: 16,
                    color: c.ink,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SfButton(
                  label: 'Bosh sahifa',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy helper kept for screens that still express a design-era tab enum.
void handleTab(BuildContext context, int tabIndex) {
  const routes = ['/home', '/workspace', '/work', '/more', '/more'];
  context.go(routes[tabIndex.clamp(0, routes.length - 1).toInt()]);
}
