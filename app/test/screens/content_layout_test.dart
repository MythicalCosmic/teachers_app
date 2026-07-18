import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/screens/content_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

Widget _app(AppState state) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: AppScope(
      notifier: state,
      child: MaterialApp(
        locale: const Locale('en'),
        theme: buildMaterialTheme(colors, dark: false),
        home: const ContentScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('folder cards fit a 393px iPhone without a clipped preview', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final state = (await tester.runAsync(_teacherState))!;
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    const names = ['Algebra · Daraja II', 'Geometriya', 'Olimpiada to‘plami'];
    final rects = names
        .map(
          (name) =>
              tester.getRect(find.byKey(ValueKey('content-folder-$name'))),
        )
        .toList(growable: false);

    expect(rects.map((rect) => rect.top).toSet(), hasLength(1));
    expect(
      rects.map((rect) => rect.width),
      everyElement(inInclusiveRange(110, 114)),
    );
    expect(rects.first.left, closeTo(18, 0.1));
    expect(rects.last.right, lessThanOrEqualTo(375.1));
    expect(rects[0].right, lessThan(rects[1].left));
    expect(rects[1].right, lessThan(rects[2].left));

    await tester.tap(find.byKey(const ValueKey('content-folder-Geometriya')));
    await tester.pumpAndSettle();
    expect(find.text('GEOMETRIYA'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
  });
}
