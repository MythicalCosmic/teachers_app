import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/main.dart';

const _iPhoneLogicalSize = Size(393, 852);

Future<AppState> _stateFor(String? username) async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  if (username != null) {
    await state.signIn(username: username, password: 'demo2026');
  }
  await state.updateSettings(
    state.settings.copyWith(
      themeMode: AppThemeMode.light,
      palette: AppPalette.daryo,
      hasCompletedWelcome: username != null,
      liquidGlass: true,
      reducedMotion: true,
      haptics: false,
      coachMarks: true,
    ),
  );
  return state;
}

void _configureIPhoneView(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _iPhoneLogicalSize;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _pumpApp(WidgetTester tester, AppState state) async {
  await tester.pumpWidget(StarForgeStaffApp(appState: state));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  String? tabLabel,
}) async {
  if (tabLabel != null) {
    await tester.tap(find.text(tabLabel).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  await expectLater(
    find.byType(Scaffold).first,
    matchesGoldenFile('visual_baselines/$name.png'),
  );
}

void main() {
  testWidgets('login visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor(null)))!;
    await _pumpApp(tester, state);
    await _capture(tester, 'login');
  });

  testWidgets('teacher home visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('nigora.karimova')))!;
    await _pumpApp(tester, state);
    await _capture(tester, 'teacher_home');
  });

  testWidgets('methodist quality visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('rano.karimova')))!;
    await _pumpApp(tester, state);
    await _capture(tester, 'methodist_quality', tabLabel: 'Sifat');
  });

  testWidgets('reception leads visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('malika.qodirova')))!;
    await _pumpApp(tester, state);
    await _capture(tester, 'reception_leads', tabLabel: 'Lidlar');
  });

  testWidgets('auditor dashboard visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('aziz.audit')))!;
    await _pumpApp(tester, state);
    await _capture(tester, 'auditor_dashboard');
  });
}
