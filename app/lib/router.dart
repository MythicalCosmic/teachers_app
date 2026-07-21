import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app/app_scope.dart';
import 'app/app_state.dart';
import 'data/api/backend_services_api.dart';
import 'data/models.dart';
import 'features/operations/staff_operations_controller.dart';
import 'screens/ai/ai_chat_list_screen.dart';
import 'screens/ai/ai_chat_screen.dart';
import 'screens/assignments/assignments_screen.dart';
import 'screens/assignments/create_assignment_screen.dart';
import 'screens/assignments/grade_submission_screen.dart';
import 'screens/assignments/gradebook_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/forced_password_change_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/cards/cards_screen.dart';
import 'screens/cards/give_card_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/cohort_detail_screen.dart';
import 'screens/cohort_list_screen.dart';
import 'screens/content_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/groups/group_workspace_store.dart';
import 'screens/lesson_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/messaging_contact_profile_screen.dart';
import 'screens/new_message_screen.dart';
import 'screens/new_task_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/print/new_print_job_screen.dart';
import 'screens/print/print_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/search_screen.dart';
import 'screens/services/backend_audit_log_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/staff/audit_workspace_screens.dart';
import 'screens/staff/methodist_quality_screen.dart';
import 'screens/staff/reception_workspace_screen.dart';
import 'screens/staff/staff_more_hub_screen.dart';
import 'screens/staff/staff_operations_screen.dart';
import 'screens/staff/staff_shell_screen.dart';
import 'screens/staff/staff_today_screen.dart';
import 'screens/staff/staff_workspace_models.dart';
import 'screens/student_profile_screen.dart';
import 'screens/surveys/survey_form_screen.dart';
import 'screens/surveys/surveys_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/today_screen.dart';
import 'screens/today/today_data.dart';
import 'screens/today/today_metric_detail_screen.dart';
import 'theme/sf_theme.dart';
import 'widgets/sf_button.dart';
import 'widgets/sf_adaptive_dialog.dart';
import 'widgets/sf_icons.dart';
import 'widgets/sf_toast.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter(
  AppState app, {
  String initialLocation = '/home',
  GroupWorkspaceStore? groupStore,
}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
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
    GoRoute(
      path: '/password/change-required',
      pageBuilder: (context, state) =>
          _fadePage(state, const ForcedPasswordChangeScreen(), app),
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
    _route(
      '/today/lessons',
      const TodayMetricDetailScreen(kind: TodayMetricKind.lessons),
      app,
    ),
    _route(
      '/today/attendance',
      const TodayMetricDetailScreen(kind: TodayMetricKind.attendance),
      app,
    ),
    _route(
      '/today/performance',
      const TodayMetricDetailScreen(kind: TodayMetricKind.performance),
      app,
    ),
    GoRoute(
      path: '/lesson',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        LessonScreen(
          slotId: state.uri.queryParameters['slot'],
          groupId: state.uri.queryParameters['group'],
          groupLessonId: state.uri.queryParameters['lesson'],
        ),
        app,
      ),
    ),
    GoRoute(
      path: '/attendance',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        AttendanceScreen(
          cohortId: state.uri.queryParameters['cohort'],
          lessonId: state.uri.queryParameters['lesson'],
          lessonAt: _tryParseDateTime(state.uri.queryParameters['at']),
          lessonTitle: state.uri.queryParameters['title'],
          store: groupStore,
        ),
        app,
      ),
    ),
    GoRoute(
      path: '/cohort',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        CohortDetailScreen(
          groupId: state.uri.queryParameters['id'],
          initialTab: _cohortTab(state.uri.queryParameters['tab']),
        ),
        app,
      ),
    ),
    GoRoute(
      path: '/student',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        StudentProfileScreen(
          studentId: state.uri.queryParameters['id'],
          groupId: state.uri.queryParameters['group'],
        ),
        app,
      ),
    ),
    _route('/cards', const CardsScreen(), app),
    _route('/cards/give', const GiveCardScreen(), app),
    _route('/ai', const AiChatListScreen(), app),
    _route('/ai/chat', const AiChatScreen(), app),
    _route('/print', const PrintScreen(), app),
    _route('/print/new', const NewPrintJobScreen(), app),
    _route('/tasks/detail', const TaskDetailScreen(), app),
    _route('/tasks/new', const NewTaskScreen(), app),
    _route('/surveys', const SurveysScreen(), app),
    _route('/surveys/form', const SurveyFormScreen(), app),
    _route('/assignments', const AssignmentsScreen(), app),
    _route('/assignments/new', const CreateAssignmentScreen(), app),
    _route('/assignments/grade', const GradeSubmissionScreen(), app),
    _route('/assignments/gradebook', const GradebookScreen(), app),
    _route('/content', const ContentScreen(), app),
    _route('/messages', const MessagesScreen(), app),
    _route('/messages/chat', const ChatScreen(), app),
    _route('/messages/contact', const MessagingContactProfileScreen(), app),
    GoRoute(
      path: '/messages/new',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        NewMessageScreen(
          groupId: state.uri.queryParameters['group'],
          studentId: state.uri.queryParameters['student'],
        ),
        app,
      ),
    ),
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
          _detailPage(state, _receptionWorkspace(context), app),
    ),
    GoRoute(
      path: '/payments',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        const StaffOperationModuleScreen(moduleId: 'payments'),
        app,
      ),
    ),
    _route('/staff/operations', const StaffOperationsHubScreen(), app),
    GoRoute(
      path: '/staff/operations/:moduleId',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _detailPage(
        state,
        StaffOperationModuleScreen(
          moduleId: state.pathParameters['moduleId'] ?? '',
        ),
        app,
      ),
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
  if (!app.isInitialized) return null;
  final path = state.uri.path;
  final authRoute = path == '/login' || path == '/login/forgot';
  if (app.session == null) return authRoute ? null : '/login';
  final passwordChangeRequired = app.session!.mustChangePassword;
  if (passwordChangeRequired && path != '/password/change-required') {
    return '/password/change-required';
  }
  if (!passwordChangeRequired && path == '/password/change-required') {
    return app.settings.hasCompletedWelcome ? '/home' : '/welcome';
  }
  if (authRoute) {
    return app.settings.hasCompletedWelcome ? '/home' : '/welcome';
  }
  if (path == '/welcome' && app.settings.hasCompletedWelcome) return '/home';
  final operationId = _staffOperationModuleId(path);
  if (operationId != null && staffOperationModuleById(operationId) == null) {
    return '/staff/operations';
  }
  final required = _capabilityFor(path);
  if (required != null && !app.can(required)) return '/home';
  return null;
}

StaffCapability? _capabilityFor(String path) {
  if (path == '/schedule' || path.startsWith('/today/')) {
    return StaffCapability.viewToday;
  }
  if (path == '/lesson') return StaffCapability.teachLessons;
  if (path.startsWith('/attendance')) return StaffCapability.takeAttendance;
  if (path == '/cohort' || path == '/student') {
    return StaffCapability.viewCohorts;
  }
  if (path.startsWith('/cards')) return StaffCapability.issueCards;
  if (path.startsWith('/content')) return StaffCapability.viewContent;
  if (path.startsWith('/ai')) return StaffCapability.useAi;
  if (path.startsWith('/print')) return StaffCapability.submitPrintJobs;
  if (path.startsWith('/surveys')) return StaffCapability.answerSurveys;
  if (path.startsWith('/assignments')) return StaffCapability.teachLessons;
  if (path == '/tasks/new') return StaffCapability.createTasks;
  if (path == '/tasks/detail') return StaffCapability.updateOwnTasks;
  if (path.startsWith('/messages')) {
    return StaffCapability.useStaffMessaging;
  }
  if (path.startsWith('/staff/quality')) {
    return StaffCapability.viewQualityWorkspace;
  }
  if (path.startsWith('/staff/reception')) return StaffCapability.viewLeads;
  if (path.startsWith('/payments')) return StaffCapability.viewPaymentStatus;
  if (path == '/staff/operations') {
    return StaffCapability.viewStaffServices;
  }
  final operationId = _staffOperationModuleId(path);
  if (operationId != null) {
    return staffOperationModuleById(operationId)?.requiredCapability ??
        StaffCapability.viewStaffServices;
  }
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

String? _staffOperationModuleId(String path) {
  const prefix = '/staff/operations/';
  if (!path.startsWith(prefix)) return null;
  final encoded = path.substring(prefix.length);
  if (encoded.isEmpty || encoded.contains('/')) return null;
  try {
    return Uri.decodeComponent(encoded);
  } on FormatException {
    // Treat malformed percent-encoding as an unknown module so the redirect
    // policy sends it back to the safe services hub instead of throwing.
    return encoded;
  }
}

DateTime? _tryParseDateTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

int? _cohortTab(String? value) => switch (value) {
  'students' => 1,
  'attendance' => 2,
  'schedule' => 3,
  _ => null,
};

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
  Duration scaled(Duration value) => Duration(
    microseconds: (value.inMicroseconds * app.settings.motionIntensity).round(),
  );
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: reduce
        ? Duration.zero
        : scaled(const Duration(milliseconds: 420)),
    reverseTransitionDuration: reduce
        ? Duration.zero
        : scaled(const Duration(milliseconds: 300)),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduce) return child;
      final platform = Theme.of(context).platform;
      if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
        return CupertinoPageTransition(
          primaryRouteAnimation: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            alignment: Alignment.topCenter,
            child: child,
          ),
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
  final duration = Duration(
    microseconds: (220000 * app.settings.motionIntensity).round(),
  );
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: reduce ? Duration.zero : duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Widget _homeRoot(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
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
      refreshStore: staffTodayRefreshStore,
      onRefresh: staffTodayRefreshStore.refresh,
    ),
    StaffRole.auditor => _auditDashboard(context),
  };
}

Widget _workspaceRoot(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return switch (session.role) {
    StaffRole.teacher || StaffRole.assistant => const CohortListScreen(),
    StaffRole.methodist => _methodistWorkspace(context),
    StaffRole.reception =>
      app.can(StaffCapability.viewLeads)
          ? _receptionWorkspace(context)
          : _staffServicesWorkspace(context),
    StaffRole.auditor => _auditSignals(context),
  };
}

Widget _workRoot(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  final role = session.role;
  return switch (role) {
    StaffRole.teacher ||
    StaffRole.assistant ||
    StaffRole.methodist => const TasksScreen(),
    StaffRole.reception =>
      app.can(StaffCapability.viewLeads)
          ? _receptionWorkspace(context)
          : const TasksScreen(),
    StaffRole.auditor => _auditCases(context),
  };
}

Widget _staffServicesWorkspace(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return StaffOperationsHubScreen(
    role: session.role,
    canAccess: app.can,
    showBack: false,
  );
}

Widget _inboxRoot(BuildContext context) {
  final session = AppScope.of(context).session;
  if (session == null) return const SizedBox.shrink();
  final role = session.role;
  return role == StaffRole.auditor
      ? const NotificationsScreen()
      : const MessagesScreen();
}

Widget _moreRoot(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return StaffMoreHubScreen(
    role: session.role,
    displayName: session.displayName,
    branchName: session.branchName,
    unreadMessages: app.unreadMessageCount,
    unreadNotifications: app.unreadNotificationCount,
    canAccess: app.can,
    onOpenRoute: (route) => context.push(route),
    onSignOut: () => unawaited(_confirmSignOut(context, app)),
  );
}

Widget _methodistWorkspace(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return MethodistQualityScreen(
    role: session.role,
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

Widget _receptionWorkspace(BuildContext _) {
  return Builder(
    builder: (routeContext) {
      final session = AppScope.of(routeContext).session;
      if (session == null) return const SizedBox.shrink();
      return ReceptionWorkspaceScreen(
        role: session.role,
        canViewLeads: AppScope.of(routeContext).can(StaffCapability.viewLeads),
        canManageAdmissions: AppScope.of(
          routeContext,
        ).can(StaffCapability.manageAdmissions),
        store: receptionWorkspaceStore,
        onCreateLead: () => unawaited(
          _createReceptionLeadDialog(routeContext, receptionWorkspaceStore),
        ),
        onCall: (leadId) => unawaited(
          _showReceptionCallDialog(
            routeContext,
            receptionWorkspaceStore,
            leadId,
          ),
        ),
        onOpenLead: (leadId) => unawaited(
          _showReceptionLeadDetails(
            routeContext,
            receptionWorkspaceStore,
            leadId,
          ),
        ),
      );
    },
  );
}

Future<void> _createReceptionLeadDialog(
  BuildContext context,
  ReceptionWorkspaceStore store,
) async {
  final student = TextEditingController();
  final guardian = TextEditingController();
  final phone = TextEditingController();
  final course = TextEditingController();
  var valid = false;
  final draft = await showDialog<ReceptionLeadDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        void validate() => setDialogState(() {
          valid =
              student.text.trim().isNotEmpty &&
              guardian.text.trim().isNotEmpty &&
              phone.text.trim().isNotEmpty &&
              course.text.trim().isNotEmpty;
        });

        return AlertDialog(
          title: Text(
            _staffOperationalText(context, uz: 'Yangi lid', en: 'New lead'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('reception-lead-student'),
                  controller: student,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => validate(),
                  decoration: InputDecoration(
                    labelText: _staffOperationalText(
                      context,
                      uz: 'O\u2018quvchi ismi',
                      en: 'Student name',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('reception-lead-guardian'),
                  controller: guardian,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => validate(),
                  decoration: InputDecoration(
                    labelText: _staffOperationalText(
                      context,
                      uz: 'Ota-ona yoki vasiy',
                      en: 'Parent or guardian',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('reception-lead-phone'),
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => validate(),
                  decoration: InputDecoration(
                    labelText: _staffOperationalText(
                      context,
                      uz: 'Telefon raqami',
                      en: 'Phone number',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('reception-lead-course'),
                  controller: course,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => validate(),
                  decoration: InputDecoration(
                    labelText: _staffOperationalText(
                      context,
                      uz: 'Kurs yoki yo\u2018nalish',
                      en: 'Course or program',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                _staffOperationalText(
                  context,
                  uz: 'Bekor qilish',
                  en: 'Cancel',
                ),
              ),
            ),
            FilledButton(
              key: const ValueKey('reception-create-lead-submit'),
              onPressed: valid
                  ? () => Navigator.pop(
                      dialogContext,
                      ReceptionLeadDraft(
                        studentName: student.text,
                        guardianName: guardian.text,
                        phone: phone.text,
                        course: course.text,
                        source: _staffOperationalText(
                          context,
                          uz: 'Qo\u2018lda qo\u2018shildi',
                          en: 'Manual entry',
                        ),
                      ),
                    )
                  : null,
              child: Text(
                _staffOperationalText(
                  context,
                  uz: 'Lidni qo\u2018shish',
                  en: 'Add lead',
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  student.dispose();
  guardian.dispose();
  phone.dispose();
  course.dispose();
  if (draft == null) return;
  final created = await store.createLead(draft);
  if (!context.mounted) return;
  SfToast.show(
    context,
    title: _staffOperationalText(
      context,
      uz: 'Lid qo\u2018shildi',
      en: 'Lead added',
    ),
    message: '${created.studentName} · ${created.course}',
    tone: SfToastTone.success,
  );
}

enum _ReceptionCallAction { copy, record }

Future<void> _showReceptionCallDialog(
  BuildContext context,
  ReceptionWorkspaceStore store,
  String leadId,
) async {
  final lead = store.leads.where((item) => item.id == leadId).firstOrNull;
  if (lead == null) return;
  final action = await showDialog<_ReceptionCallAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(lead.studentName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _staffOperationalText(
              dialogContext,
              uz: 'Bog\u2018lanish raqami',
              en: 'Contact number',
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            lead.phone,
            key: const ValueKey('reception-call-phone'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, _ReceptionCallAction.copy),
          child: Text(
            _staffOperationalText(
              dialogContext,
              uz: 'Raqamni nusxalash',
              en: 'Copy number',
            ),
          ),
        ),
        FilledButton.icon(
          key: const ValueKey('reception-record-call'),
          onPressed: () =>
              Navigator.pop(dialogContext, _ReceptionCallAction.record),
          icon: const Icon(Icons.call_outlined),
          label: Text(
            _staffOperationalText(
              dialogContext,
              uz: 'Suhbatni qayd etish',
              en: 'Record conversation',
            ),
          ),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;
  if (action == _ReceptionCallAction.copy) {
    await Clipboard.setData(ClipboardData(text: lead.phone));
    if (!context.mounted) return;
    SfToast.show(
      context,
      title: _staffOperationalText(
        context,
        uz: 'Raqam nusxalandi',
        en: 'Number copied',
      ),
      message: lead.phone,
      tone: SfToastTone.success,
    );
    return;
  }
  await store.recordCall(leadId);
  if (!context.mounted) return;
  SfToast.show(
    context,
    title: _staffOperationalText(
      context,
      uz: 'Aloqa qayd etildi',
      en: 'Contact recorded',
    ),
    message: _staffOperationalText(
      context,
      uz: '${lead.studentName} bilan suhbat tarixi yangilandi.',
      en: '${lead.studentName}\u2019s contact history was updated.',
    ),
    tone: SfToastTone.success,
  );
}

Future<void> _showReceptionLeadDetails(
  BuildContext context,
  ReceptionWorkspaceStore store,
  String leadId,
) async {
  if (!store.leads.any((lead) => lead.id == leadId)) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: SfTheme.colorsOf(context).surface,
    builder: (sheetContext) => AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final lead = store.leads.where((item) => item.id == leadId).firstOrNull;
        if (lead == null) return const SizedBox.shrink();
        final next = lead.stage.next;
        return SafeArea(
          top: false,
          child: ListView(
            key: const ValueKey('reception-lead-details'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            children: [
              Text(
                lead.studentName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${_receptionStageText(context, lead.stage)} · ${lead.course}',
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(
                  _staffOperationalText(
                    context,
                    uz: 'Bog\u2018lanish shaxsi',
                    en: 'Contact person',
                  ),
                ),
                subtitle: Text(lead.guardianName),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined),
                title: Text(
                  _staffOperationalText(context, uz: 'Telefon', en: 'Phone'),
                ),
                subtitle: SelectableText(lead.phone),
                trailing: IconButton(
                  tooltip: _staffOperationalText(
                    context,
                    uz: 'Raqamni nusxalash',
                    en: 'Copy number',
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: lead.phone));
                    if (context.mounted) {
                      SfToast.show(
                        context,
                        message: _staffOperationalText(
                          context,
                          uz: 'Telefon raqami nusxalandi.',
                          en: 'Phone number copied.',
                        ),
                        tone: SfToastTone.success,
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.campaign_outlined),
                title: Text(
                  _staffOperationalText(context, uz: 'Manba', en: 'Source'),
                ),
                subtitle: Text(lead.source),
              ),
              if (lead.note != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notes_rounded),
                  title: Text(
                    _staffOperationalText(context, uz: 'Izoh', en: 'Note'),
                  ),
                  subtitle: Text(lead.note!),
                ),
              if (lead.lastContactAt != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_rounded),
                  title: Text(
                    _staffOperationalText(
                      context,
                      uz: 'So\u2018nggi aloqa',
                      en: 'Last contact',
                    ),
                  ),
                  subtitle: Text(lead.lastContactAt!.toLocal().toString()),
                ),
              if (next != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('reception-details-advance'),
                  onPressed: () => store.advanceLead(lead.id),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _staffOperationalText(
                      context,
                      uz: '${next.label} bosqichiga o\u2018tkazish',
                      en: 'Move to the next stage',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

String _staffOperationalText(
  BuildContext context, {
  required String uz,
  required String en,
}) => Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;

String _receptionStageText(BuildContext context, LeadStage stage) {
  if (Localizations.maybeLocaleOf(context)?.languageCode == 'uz') {
    return stage.label;
  }
  return switch (stage) {
    LeadStage.newLead => 'New',
    LeadStage.contacted => 'Contacted',
    LeadStage.trialBooked => 'Trial booked',
    LeadStage.tested => 'Tested',
    LeadStage.enrolled => 'Enrolled',
    LeadStage.lost => 'Closed',
  };
}

Widget _auditDashboard(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return AuditorDashboardScreen(
    role: session.role,
    anomalies: app.auditAnomalies,
    cases: app.auditCases,
    onOpenSignals: () => context.go('/workspace'),
    onOpenCases: () => context.go('/work'),
    onOpenAuditLog: () => context.push('/staff/audit/log'),
    onOpenSignal: (id) => context.push('/staff/audit/signal/$id'),
    refreshStore: auditWorkspaceRefreshStore,
    onRefresh: auditWorkspaceRefreshStore.refresh,
  );
}

Widget _auditSignals(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return AuditSignalsScreen(
    role: session.role,
    anomalies: app.auditAnomalies,
    onOpenSignal: (id) => context.push('/staff/audit/signal/$id'),
    onAcknowledge: app.acknowledgeAnomaly,
    refreshStore: auditWorkspaceRefreshStore,
    onRefresh: auditWorkspaceRefreshStore.refresh,
  );
}

Widget _auditSignalDetail(BuildContext context, String id) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  final item = app.auditAnomalies.where((value) => value.id == id).firstOrNull;
  if (item == null) {
    return const _MissingRecordScreen(message: 'Audit signali topilmadi.');
  }
  return AuditSignalDetailScreen(
    role: session.role,
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
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  return AuditCasesScreen(
    role: session.role,
    cases: app.auditCases,
    onOpenCase: (id) => context.push('/staff/audit/case/$id'),
    onCreateCase: () => unawaited(_createCaseDialog(context, app)),
  );
}

Widget _auditCaseDetail(BuildContext context, String id) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  final item = app.auditCases.where((value) => value.id == id).firstOrNull;
  if (item == null) {
    return const _MissingRecordScreen(message: 'Audit holati topilmadi.');
  }
  return AuditCaseDetailScreen(
    role: session.role,
    auditCase: item,
    onBack: () => context.pop(),
    onAddNote: app.addAuditCaseNote,
    onSetStatus: app.setAuditCaseStatus,
  );
}

Widget _auditLog(BuildContext context) {
  final app = AppScope.of(context);
  final session = app.session;
  if (session == null) return const SizedBox.shrink();
  final backend = app.backendApi;
  if (backend != null) {
    return BackendAuditLogScreen(
      api: BackendServicesApi.fromApi(backend),
      baseUrl: backend.connection?.baseUrl,
    );
  }
  final events = _auditEvents(app);
  return ImmutableAuditLogScreen(
    role: session.role,
    events: events,
    onExport: () async => buildAuditCsv(events),
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
  final approved = await showSfConfirmDialog(
    context,
    title: 'Hisobdan chiqasizmi?',
    message: 'Qurilmadagi lokal ish ma’lumotlari saqlanadi.',
    confirmLabel: 'Chiqish',
    destructive: true,
  );
  if (approved) await app.signOut();
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
