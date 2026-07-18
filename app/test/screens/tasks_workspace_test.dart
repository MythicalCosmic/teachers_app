import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/tasks/tasks_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _state() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

Widget _host(AppState state) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp(
        theme: buildMaterialTheme(colors, dark: false),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(393, 852)),
          child: TasksScreen(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('task workspace switches list, board and calendar smoothly', (
    tester,
  ) async {
    final state = (await tester.runAsync(_state))!;
    await tester.pumpWidget(_host(state));
    await tester.pumpAndSettle();

    expect(find.text('Task command center'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.calendar_view_week_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.calendar_view_week_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.view_kanban_outlined));
    await tester.pumpAndSettle();
    expect(find.text('To do'), findsWidgets);
    expect(find.byType(LongPressDraggable<StaffTask>), findsWidgets);
    final board = find.byWidgetPredicate(
      (widget) =>
          widget is ListView &&
          widget.scrollDirection == Axis.horizontal &&
          widget.controller != null,
      description: 'horizontal task board',
    );
    await tester.ensureVisible(board);
    await tester.pumpAndSettle();
    await tester.drag(board, const Offset(-900, 0));
    await tester.pumpAndSettle();
    expect(find.text('Olimpiada tayyorgarligi uchun reja'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('task search is functional at phone width', (tester) async {
    final state = (await tester.runAsync(_state))!;
    await tester.pumpWidget(_host(state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'not-a-real-task');
    await tester.pumpAndSettle();

    expect(find.text('No tasks in this view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
