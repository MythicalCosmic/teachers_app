import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/screens/lesson_screen.dart';
import 'package:starforge_staff/screens/schedule_screen.dart';
import 'package:starforge_staff/screens/surveys/survey_form_screen.dart';
import 'package:starforge_staff/screens/today/today_data.dart';
import 'package:starforge_staff/screens/today/today_metric_detail_screen.dart';
import 'package:starforge_staff/screens/today_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _themeHost(
  Widget child, {
  AppState? state,
  bool router = false,
  Locale locale = const Locale('uz'),
  bool dark = false,
}) {
  final colors = sfColorsFor(SfPalette.daryo, dark: dark);
  final themed = SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: dark,
    child: router
        ? MaterialApp.router(
            theme: buildMaterialTheme(colors, dark: dark),
            locale: locale,
            supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(path: '/', builder: (_, _) => child),
                GoRoute(
                  path: '/attendance',
                  builder: (_, routeState) => Text(
                    'Attendance ${routeState.uri.queryParameters['followUps'] ?? ''}',
                  ),
                ),
              ],
            ),
          )
        : MaterialApp(
            theme: buildMaterialTheme(colors, dark: dark),
            locale: locale,
            supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: child,
          ),
  );
  return state == null ? themed : AppScope(notifier: state, child: themed);
}

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

Future<void> _center(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: .5,
    duration: Duration.zero,
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() => debugSetStaffToday(DateTime(2026, 7, 14)));
  tearDown(() => debugSetStaffToday(null));

  testWidgets('all three survey questions accept answers and submit', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    await tester.pumpWidget(
      _themeHost(const SurveyFormScreen(), state: state, router: true),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('survey-survey-001-q1-rating-5')));
    final aiChoice = find.byKey(
      const Key('survey-survey-001-q2-choice-AI yordamchi'),
    );
    await _center(tester, aiChoice);
    await tester.tap(aiChoice);
    final textAnswer = find.byKey(const Key('survey-text-survey-001-q3'));
    await _center(tester, textAnswer);
    await tester.enterText(
      textAnswer,
      'Har darsda qisqa amaliy refleksiya qo‘shaman.',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('survey-submit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Javoblarni yuborish'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Yuborish'));
    await tester.pumpAndSettle();

    expect(state.surveys.first.isSubmitted, isTrue);
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 1400),
      3000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Javoblar qabul qilindi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survey stays legible and interactive in dark mode on iPhone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = (await tester.runAsync(_teacherState))!;
    await tester.pumpWidget(
      _themeHost(
        const SurveyFormScreen(),
        state: state,
        router: true,
        dark: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      Theme.of(tester.element(find.byType(SurveyFormScreen))).brightness,
      Brightness.dark,
    );
    expect(find.byKey(const Key('survey-submit-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('survey-survey-001-q1-rating-5')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule view and selected date update without dead controls', (
    tester,
  ) async {
    await tester.pumpWidget(_themeHost(const ScheduleScreen()));
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byKey(const Key('schedule-view-month')));
    await tester.pump(const Duration(milliseconds: 400));
    final nextLessonDate = staffToday.add(const Duration(days: 1));
    final monthDayKey = Key(
      'month-day-${nextLessonDate.year}-${nextLessonDate.month}-${nextLessonDate.day}',
    );
    expect(find.byKey(monthDayKey), findsOneWidget);

    final monthDay = find.byKey(monthDayKey);
    await _center(tester, monthDay);
    await tester.tap(monthDay);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView).first, const Offset(0, -460));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        staffDayTitle(
          tester.element(find.byType(ScheduleScreen)),
          nextLessonDate,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Viyet teoremasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lesson plan and timer controls mutate the workspace', (
    tester,
  ) async {
    await tester.pumpWidget(_themeHost(const LessonScreen(), router: true));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('1/5 bosqich · 20%'), findsOneWidget);
    final secondStep = find.byKey(const Key('lesson-plan-step-2'));
    await _center(tester, secondStep);
    await tester.tap(secondStep);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('2/5 bosqich · 40%'), findsOneWidget);

    final play = find.byIcon(Icons.play_arrow_rounded);
    await _center(tester, play);
    await tester.tap(play);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Jonli dars · taymer ishlamoqda'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.textContaining('TAYMER PAUZADA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metric trends and period controls are interactive', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themeHost(
        const TodayMetricDetailScreen(kind: TodayMetricKind.performance),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('metric-hero-value')), findsOneWidget);
    expect(find.text('#7'), findsOneWidget);
    await tester.tap(find.byKey(const Key('metric-period-2')));
    await tester.pumpAndSettle();
    expect(find.text('#5'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('trend-point-3')).last,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('trend-point-3')).last);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('80 ball'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance follow-ups persist as a task and reach workspace', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    final taskCount = state.tasks.length;
    await tester.pumpWidget(
      _themeHost(
        const TodayMetricDetailScreen(kind: TodayMetricKind.attendance),
        state: state,
        router: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final student = find.text('Otabek Eshmatov');
    await tester.scrollUntilVisible(
      student,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await _center(tester, student);
    await tester.tap(student);
    final continueButton = find.text('1 kuzatuv bilan davom etish');
    await tester.scrollUntilVisible(
      continueButton,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(state.tasks.length, taskCount + 1);
    expect(
      find.textContaining('Attendance student-otabek-eshmatov'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English locale covers the complete Today workstream chrome', (
    tester,
  ) async {
    const english = Locale('en');

    await tester.pumpWidget(_themeHost(const TodayScreen(), locale: english));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Weekly teaching experience'), findsOneWidget);
    expect(find.text('Lessons today'), findsOneWidget);

    await tester.pumpWidget(
      _themeHost(const ScheduleScreen(), locale: english),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);

    await tester.pumpWidget(
      _themeHost(const LessonScreen(), router: true, locale: english),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lesson plan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lesson tools'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Lesson tools'), findsOneWidget);

    final state = (await tester.runAsync(_teacherState))!;
    await tester.pumpWidget(
      _themeHost(
        const SurveyFormScreen(),
        state: state,
        router: true,
        locale: english,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Weekly survey'), findsOneWidget);
    expect(
      find.text('How effective were your lessons this week?'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _themeHost(
        const TodayMetricDetailScreen(kind: TodayMetricKind.performance),
        locale: english,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your performance'), findsOneWidget);
    expect(find.text('Performance trend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian locale localizes dates and lesson data safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      _themeHost(const TodayScreen(), locale: const Locale('ru')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('ВТОРНИК, 14 ИЮЛЯ'), findsWidgets);
    expect(find.text('Алгебра · Уровень II'), findsOneWidget);
    expect(find.text('Haftalik dars tajribasi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
