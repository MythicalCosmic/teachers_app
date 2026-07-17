import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/screens/notifications_screen.dart';
import 'package:starforge_staff/screens/settings_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host(AppState state, Widget screen) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp(
        theme: buildMaterialTheme(colors, dark: false),
        home: screen,
      ),
    ),
  );
}

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

void main() {
  testWidgets('Liquid Glass control writes through AppState', (tester) async {
    final state = (await tester.runAsync(_teacherState))!;

    await tester.pumpWidget(_host(state, const SettingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.scrollUntilVisible(
      find.text('Liquid Glass'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -90));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 160));
    await tester.pump();

    expect(state.settings.liquidGlass, isTrue);
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(state.settings.liquidGlass, isFalse);
  });

  testWidgets('mark all notifications updates the shared unread state', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;

    expect(state.unreadNotificationCount, greaterThan(0));
    await tester.pumpWidget(_host(state, const NotificationsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byTooltip('Hammasini o‘qilgan qilish'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(state.unreadNotificationCount, 0);
    expect(state.notifications.every((item) => item.isRead), isTrue);
  });
}
