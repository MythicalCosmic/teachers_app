import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/main.dart';
import 'package:starforge_staff/screens/today/today_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _iPhoneLogicalSize = Size(393, 852);

Future<AppState> _stateFor(
  String? username, {
  AppThemeMode themeMode = AppThemeMode.light,
}) async {
  debugSetStaffToday(DateTime(2026, 7, 18));
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  if (username != null) {
    await state.signIn(username: username, password: 'demo2026');
  }
  await state.updateSettings(
    state.settings.copyWith(
      themeMode: themeMode,
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
  if (name == 'teacher_messages') {
    await tester.runAsync(() => MessagingController.shared.restored);
    await tester.pump();
  }
  await expectLater(
    find.byType(Scaffold).first,
    matchesGoldenFile('visual_baselines/$name.png'),
  );
}

void main() {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});

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

  testWidgets('teacher workspace visual baselines', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('nigora.karimova')))!;
    await _pumpApp(tester, state);

    await _capture(tester, 'teacher_groups', tabLabel: 'Guruhlar');
    await _capture(tester, 'teacher_tasks', tabLabel: 'Vazifalar');
    await _capture(tester, 'teacher_messages', tabLabel: 'Xabarlar');
    await _capture(tester, 'teacher_more', tabLabel: 'Boshqa');

    final settings = find.text('Sozlamalar');
    await tester.ensureVisible(settings);
    await tester.pump();
    await tester.tap(settings);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'teacher_settings');
  });

  testWidgets('highlighted teacher surfaces visual baselines', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('nigora.karimova')))!;
    await _pumpApp(tester, state);

    await tester.tap(find.text('Guruhlar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('cohort-9b-algebra')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'teacher_group_detail');

    final rhythm = find.byKey(const ValueKey('rhythm-bar-0'));
    await tester.scrollUntilVisible(rhythm, 240);
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'teacher_group_rhythm');
  });

  testWidgets('highlighted Today details visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('nigora.karimova')))!;
    await _pumpApp(tester, state);

    final saturday = find.byKey(const ValueKey('today-date-18'));
    await tester.scrollUntilVisible(
      saturday,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'teacher_today_details');
  });

  testWidgets('materials visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('nigora.karimova')))!;
    await _pumpApp(tester, state);

    await tester.tap(find.text('Boshqa').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Materiallar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'teacher_materials');
  });

  testWidgets('new task visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(() => _stateFor('nigora.karimova')))!;
    await _pumpApp(tester, state);

    await tester.tap(find.text('Vazifalar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Yangi vazifa').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'teacher_new_task');
  });

  testWidgets('dark survey visual baseline', (tester) async {
    _configureIPhoneView(tester);
    final state = (await tester.runAsync(
      () => _stateFor('nigora.karimova', themeMode: AppThemeMode.dark),
    ))!;
    await _pumpApp(tester, state);
    await tester.tap(find.byKey(const Key('today-survey-banner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(Scaffold).last,
      matchesGoldenFile('visual_baselines/dark_survey.png'),
    );
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
