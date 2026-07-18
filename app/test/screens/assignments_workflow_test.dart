import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/features/assignments/assignment_controller.dart';
import 'package:starforge_staff/features/assignments/assignment_models.dart';
import 'package:starforge_staff/features/assignments/assignment_storage.dart';
import 'package:starforge_staff/screens/assignments/assignments_screen.dart';
import 'package:starforge_staff/screens/assignments/create_assignment_screen.dart';
import 'package:starforge_staff/screens/assignments/grade_submission_screen.dart';
import 'package:starforge_staff/screens/assignments/gradebook_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AssignmentController> _controller() async {
  final controller = AssignmentController(
    storage: MemoryAssignmentStorage(),
    clock: () => DateTime(2026, 7, 18, 12),
  );
  controller.initialize(ownerId: 'teacher-test');
  await controller.restored;
  return controller;
}

GoRouter _router(
  AssignmentController controller, {
  String initialLocation = '/assignments',
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/assignments',
      builder: (_, _) => AssignmentsScreen(controller: controller),
    ),
    GoRoute(
      path: '/assignments/new',
      builder: (_, _) => CreateAssignmentScreen(controller: controller),
    ),
    GoRoute(
      path: '/assignments/gradebook',
      builder: (_, _) => GradebookScreen(controller: controller),
    ),
    GoRoute(
      path: '/assignments/grade',
      builder: (_, _) => GradeSubmissionScreen(controller: controller),
    ),
  ],
);

Widget _host(GoRouter router, {Locale locale = const Locale('uz')}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp.router(
      theme: buildMaterialTheme(colors, dark: false),
      locale: locale,
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('assignment and student ids flow through grade routes', (
    tester,
  ) async {
    final controller = await _controller();
    final router = _router(controller);
    addTearDown(router.dispose);
    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    final assignmentCard = find.byKey(
      const Key('assignment-open-assignment-functions-9a'),
    );
    await tester.scrollUntilVisible(
      assignmentCard,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(assignmentCard);
    await tester.pumpAndSettle();
    expect(find.text('Funksiyalar grafigi'), findsOneWidget);
    expect(find.text('Halimova Zarina'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('gradebook-open-student-zarina-halimova')),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Halimova Zarina · 9-A Algebra'),
      findsOneWidget,
    );
    expect(find.text('MATNLI JAVOB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reminder action persists and changes the learner row', (
    tester,
  ) async {
    final controller = await _controller();
    final router = _router(
      controller,
      initialLocation:
          '/assignments/gradebook?assignmentId=assignment-quadratic-9b',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    final remind = find.byKey(
      const Key('gradebook-remind-student-otabek-eshmatov'),
    );
    await tester.scrollUntilVisible(
      remind,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(remind);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();

    final submission = controller.submissionById(
      'assignment-quadratic-9b',
      'student-otabek-eshmatov',
    );
    expect(submission?.reminderSentAt, isNotNull);
    expect(
      find.byKey(const Key('gradebook-remind-student-otabek-eshmatov')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a text assignment adds it to the persisted workspace', (
    tester,
  ) async {
    final controller = await _controller();
    final router = _router(controller);
    addTearDown(router.dispose);
    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yangi topshiriq').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('assignment-title-field')),
      'Haftalik refleksiya',
    );
    await tester.enterText(
      find.byKey(const Key('assignment-instructions-field')),
      'Hafta davomida o‘rgangan usulingizni matnda tushuntiring.',
    );
    await tester.scrollUntilVisible(
      find.text('Matn'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Matn'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('assignment-publish-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'E’lon qilish'));
    await tester.pumpAndSettle();

    final created = controller.assignments.first;
    expect(created.title, 'Haftalik refleksiya');
    expect(created.responseType, AssignmentResponseType.text);
    expect(find.text('Haftalik refleksiya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attachment disclosure and feedback grade are functional', (
    tester,
  ) async {
    final controller = await _controller();
    final router = _router(
      controller,
      initialLocation:
          '/assignments/grade?assignmentId=assignment-quadratic-9b&studentId=student-akmal-akbarov',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_host(router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assignment-attachment-metadata')));
    await tester.pumpAndSettle();
    expect(find.text('Demo biriktirma'), findsOneWidget);
    expect(find.text('application/pdf'), findsOneWidget);
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();

    final feedback = find.byKey(const Key('assignment-feedback-field'));
    await tester.scrollUntilVisible(
      feedback,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tuzatish'));
    await tester.enterText(
      feedback,
      'Yechim yaxshi, ammo to‘rtinchi misoldagi ishorani qayta tekshiring.',
    );
    final save = find.byKey(const Key('assignment-save-feedback'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();

    final saved = controller.submissionById(
      'assignment-quadratic-9b',
      'student-akmal-akbarov',
    );
    expect(saved?.feedbackStep, AssignmentFeedbackStep.revise);
    expect(saved?.status, AssignmentSubmissionStatus.revisionRequested);
    expect(saved?.grade, 85);
    expect(saved?.feedback, contains('qayta tekshiring'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('English locale renders assignment workflow copy in English', (
    tester,
  ) async {
    final controller = await _controller();
    final router = _router(controller);
    addTearDown(router.dispose);
    await tester.pumpWidget(_host(router, locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('Quadratic equations'), findsOneWidget);
    expect(find.text('Topshiriqlar'), findsNothing);

    await tester.tap(
      find.byKey(const Key('assignment-open-assignment-quadratic-9b')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Needs feedback'), findsWidgets);
    expect(find.textContaining('Document upload'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
