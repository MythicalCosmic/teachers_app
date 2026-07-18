import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/router.dart';
import 'package:starforge_staff/screens/groups/group_workspace_store.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  await state.updateSettings(
    state.settings.copyWith(
      hasCompletedWelcome: true,
      locale: AppLocale.en,
      reducedMotion: true,
    ),
  );
  return state;
}

Widget _host(AppState state, GoRouter router) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      reducedMotion: true,
      child: MaterialApp.router(
        locale: const Locale('en'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _pumpRoute(
  WidgetTester tester,
  String location, {
  GroupWorkspaceStore? groupStore,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
  final state = (await tester.runAsync(_teacherState))!;
  final router = buildRouter(
    state,
    initialLocation: location,
    groupStore: groupStore,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(_host(state, router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('lesson route preserves its group and scheduled lesson', (
    tester,
  ) async {
    await _pumpRoute(
      tester,
      '/lesson?group=cohort-10v-geometry&lesson=10v-lesson-2',
    );
    expect(find.textContaining('Funksiya'), findsWidgets);
    expect(find.textContaining('10-V'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance route keeps the selected lesson identity', (
    tester,
  ) async {
    final store = GroupWorkspaceStore.seeded();
    await _pumpRoute(
      tester,
      '/attendance?cohort=cohort-10v-geometry&lesson=10v-lesson-2&title=Funksiya%20grafigi',
      groupStore: store,
    );
    expect(store.draft('cohort-10v-geometry')?.lessonId, '10v-lesson-2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('student route keeps the selected group context', (tester) async {
    final group = groupWorkspaceStore.group('cohort-10v-geometry');
    final student = group.students.last;
    await _pumpRoute(
      tester,
      Uri(
        path: '/student',
        queryParameters: {'id': student.id, 'group': group.id},
      ).toString(),
    );
    expect(find.text(student.name), findsWidgets);
    expect(find.text(group.name), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new message route shows linked student and group context', (
    tester,
  ) async {
    final group = groupWorkspaceStore.group('cohort-10v-geometry');
    final student = group.students.last;
    await _pumpRoute(
      tester,
      Uri(
        path: '/messages/new',
        queryParameters: {'group': group.id, 'student': student.id},
      ).toString(),
    );
    expect(find.byKey(const ValueKey('message-group-context')), findsOneWidget);
    expect(find.text(student.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
