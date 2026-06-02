import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/new_message_screen.dart';
import 'screens/today_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/cohort_list_screen.dart';
import 'screens/cohort_detail_screen.dart';
import 'screens/student_profile_screen.dart';
import 'screens/cards/cards_screen.dart';
import 'screens/cards/give_card_screen.dart';
import 'screens/ai/ai_chat_list_screen.dart';
import 'screens/ai/ai_chat_screen.dart';
import 'screens/print/print_screen.dart';
import 'screens/print/new_print_job_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/mgmt/mgmt_inbox_screen.dart';
import 'screens/mgmt/mgmt_chat_screen.dart';
import 'screens/surveys/surveys_screen.dart';
import 'screens/surveys/survey_form_screen.dart';
import 'screens/assignments/assignments_screen.dart';
import 'screens/assignments/create_assignment_screen.dart';
import 'screens/assignments/grade_submission_screen.dart';
import 'screens/assignments/gradebook_screen.dart';
import 'screens/content_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/new_task_screen.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
        GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
        GoRoute(path: '/lesson', builder: (_, __) => const LessonScreen()),
        GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
        GoRoute(path: '/cohorts', builder: (_, __) => const CohortListScreen()),
        GoRoute(path: '/cohort', builder: (_, __) => const CohortDetailScreen()),
        GoRoute(path: '/student', builder: (_, __) => const StudentProfileScreen()),
        GoRoute(path: '/cards', builder: (_, __) => const CardsScreen()),
        GoRoute(path: '/cards/give', builder: (_, __) => const GiveCardScreen()),
        GoRoute(path: '/ai', builder: (_, __) => const AiChatListScreen()),
        GoRoute(path: '/ai/chat', builder: (_, __) => const AiChatScreen()),
        GoRoute(path: '/print', builder: (_, __) => const PrintScreen()),
        GoRoute(path: '/print/new', builder: (_, __) => const NewPrintJobScreen()),
        GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
        GoRoute(path: '/tasks/detail', builder: (_, __) => const TaskDetailScreen()),
        GoRoute(path: '/tasks/new', builder: (_, __) => const NewTaskScreen()),
        GoRoute(path: '/mgmt', builder: (_, __) => const MgmtInboxScreen()),
        GoRoute(path: '/mgmt/chat', builder: (_, __) => const MgmtChatScreen()),
        GoRoute(path: '/surveys', builder: (_, __) => const SurveysScreen()),
        GoRoute(path: '/surveys/form', builder: (_, __) => const SurveyFormScreen()),
        GoRoute(path: '/assignments', builder: (_, __) => const AssignmentsScreen()),
        GoRoute(path: '/assignments/new', builder: (_, __) => const CreateAssignmentScreen()),
        GoRoute(path: '/assignments/grade', builder: (_, __) => const GradeSubmissionScreen()),
        GoRoute(path: '/assignments/gradebook', builder: (_, __) => const GradebookScreen()),
        GoRoute(path: '/content', builder: (_, __) => const ContentScreen()),
        GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        GoRoute(path: '/messages/chat', builder: (_, __) => const ChatScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/login/forgot', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/messages/new', builder: (_, __) => const NewMessageScreen()),
        GoRoute(path: '/settings/edit', builder: (_, __) => const EditProfileScreen()),
      ],
      errorBuilder: (ctx, st) => Scaffold(
        body: Center(child: Text('Topilmadi: ${st.uri}')),
      ),
    );

/// Helper that maps the bottom tab to its destination route.
void handleTab(BuildContext context, int tabIndex) {
  const routes = ['/today', '/cohorts', '/tasks', '/ai', '/print'];
  context.go(routes[tabIndex]);
}
