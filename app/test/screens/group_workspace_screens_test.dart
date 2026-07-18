import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/screens/cohort_detail_screen.dart';
import 'package:starforge_staff/screens/cohort_list_screen.dart';
import 'package:starforge_staff/screens/groups/group_attendance_capture_screen.dart';
import 'package:starforge_staff/screens/groups/group_workspace_store.dart';
import 'package:starforge_staff/screens/student_profile_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_shell_scope.dart';

Widget _host(Widget child, {Locale locale = const Locale('uz')}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: buildMaterialTheme(colors, dark: false),
      home: SfShellScope(child: child),
    ),
  );
}

GroupWorkspaceStore _store() =>
    GroupWorkspaceStore.seeded(now: () => DateTime(2026, 7, 18, 10, 30));

void main() {
  void configurePhone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
  }

  testWidgets('group search and category controls update visible cards', (
    tester,
  ) async {
    configurePhone(tester);
    final store = _store();
    await tester.pumpWidget(_host(CohortListScreen(store: store)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('group-search-field')),
      '10-V',
    );
    await tester.pumpAndSettle();

    expect(find.text('10-V Geometriya'), findsOneWidget);
    expect(find.text('9-B Algebra'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('group-search-field')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('group-category-geometry')));
    await tester.pumpAndSettle();

    expect(find.text('10-V Geometriya'), findsOneWidget);
    expect(find.text('9-B Algebra'), findsNothing);
  });

  testWidgets(
    'group detail history presets and lesson filter are interactive',
    (tester) async {
      configurePhone(tester);
      final store = _store();
      await tester.pumpWidget(
        _host(CohortDetailScreen(store: store, groupId: 'cohort-9b-algebra')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('group-tab-2')));
      await tester.pumpAndSettle();
      expect(find.text('O‘quvchilar kesimida'), findsOneWidget);

      await tester.tap(find.text('7 kun'));
      await tester.pumpAndSettle();
      expect(find.text('oxirgi 2 dars'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('attendance-lesson-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nazorat ishi').last);
      await tester.pumpAndSettle();
      expect(find.text('Nazorat ishi'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('capture screen marks attendance and completes remaining rows', (
    tester,
  ) async {
    configurePhone(tester);
    final store = _store();
    const groupId = 'cohort-9b-algebra';
    final firstStudent = store.group(groupId).students.first;
    await tester.pumpWidget(
      _host(GroupAttendanceCaptureScreen(store: store, groupId: groupId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bor').first);
    await tester.pumpAndSettle();
    expect(store.draft(groupId)!.statuses[firstStudent.id]?.name, 'present');

    await tester.tap(find.text('Qolganlari bor'));
    await tester.pumpAndSettle();
    expect(store.draft(groupId)!.isComplete, isTrue);
    expect(find.byKey(const ValueKey('save-group-attendance')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture chooser changes the scheduled lesson context', (
    tester,
  ) async {
    configurePhone(tester);
    final store = _store();
    const groupId = 'cohort-9b-algebra';
    final lessons = store.group(groupId).lessons;
    await tester.pumpWidget(
      _host(GroupAttendanceCaptureScreen(store: store, groupId: groupId)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('attendance-date-chooser')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('attendance-lesson-chooser')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('capture-lesson-${lessons[1].id}')));
    await tester.pumpAndSettle();

    expect(store.draft(groupId)!.lessonId, lessons[1].id);
    expect(store.draft(groupId)!.lessonAt, lessons[1].startsAt);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group workspace remains comfortable on a narrow phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.reset);
    final store = _store();

    await tester.pumpWidget(_host(CohortListScreen(store: store)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _host(CohortDetailScreen(store: store, groupId: 'cohort-9b-algebra')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _host(
        GroupAttendanceCaptureScreen(
          store: store,
          groupId: 'cohort-9b-algebra',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('group detail actions and lesson rhythm stay clear on iPhone', (
    tester,
  ) async {
    configurePhone(tester);
    final store = _store();
    await tester.pumpWidget(
      _host(CohortDetailScreen(store: store, groupId: 'cohort-9b-algebra')),
    );
    await tester.pumpAndSettle();

    final attendance = find.byKey(const ValueKey('group-attendance-action'));
    final message = find.byKey(const ValueKey('group-message-action'));
    expect(attendance, findsOneWidget);
    expect(message, findsOneWidget);
    expect(
      (tester.getCenter(attendance).dy - tester.getCenter(message).dy).abs(),
      lessThan(1),
    );

    final firstBar = find.byKey(const ValueKey('rhythm-bar-0'));
    await tester.scrollUntilVisible(firstBar, 240);
    await tester.pumpAndSettle();
    await tester.tap(firstBar);
    await tester.pumpAndSettle();
    final selection = tester.widget<Text>(
      find.byKey(const ValueKey('rhythm-selection-0')),
    );
    expect(selection.data, contains('88%'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('English locale changes every major group workflow surface', (
    tester,
  ) async {
    configurePhone(tester);
    final store = _store();

    await tester.pumpWidget(
      _host(CohortListScreen(store: store), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Search groups or students'), findsOneWidget);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1800),
      2200,
    );
    await tester.pumpAndSettle();
    expect(find.text('GROUP INTELLIGENCE'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        CohortDetailScreen(store: store, groupId: 'cohort-9b-algebra'),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Lessons'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('group-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('Last month'), findsOneWidget);
    expect(find.text('By student'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        GroupAttendanceCaptureScreen(
          store: store,
          groupId: 'cohort-9b-algebra',
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Take attendance'), findsOneWidget);
    expect(find.text('Mark rest present'), findsOneWidget);
    expect(find.text('Search students'), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian locale changes group navigation and search', (
    tester,
  ) async {
    configurePhone(tester);
    final store = _store();
    await tester.pumpWidget(
      _host(CohortListScreen(store: store), locale: const Locale('ru')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Группы'), findsOneWidget);
    expect(find.text('Поиск группы или ученика'), findsOneWidget);
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1800),
      2200,
    );
    await tester.pumpAndSettle();
    expect(find.text('АНАЛИЗ ГРУПП'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'student profile resolves the selected group student dynamically',
    (tester) async {
      configurePhone(tester);
      final store = _store();
      final group = store.group('cohort-10v-geometry');
      final student = group.students.last;

      await tester.pumpWidget(
        _host(
          StudentProfileScreen(
            store: store,
            groupId: group.id,
            studentId: student.id,
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(student.name), findsWidgets);
      expect(find.text(group.name), findsWidgets);
      expect(
        find.byKey(const ValueKey('student-message-action')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('student-more-actions')));
      await tester.pumpAndSettle();
      expect(find.text('Contact details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
