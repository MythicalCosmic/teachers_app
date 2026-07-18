import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/main.dart';

void main() {
  testWidgets('persisted English drives navigation, More and settings chrome', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final state = (await tester.runAsync(() async {
      final value = await AppState.bootstrap(storage: MemoryAppStorage());
      await value.signIn(username: 'nigora.karimova', password: 'demo2026');
      await value.updateSettings(
        value.settings.copyWith(
          locale: AppLocale.en,
          hasCompletedWelcome: true,
          reducedMotion: true,
        ),
      );
      return value;
    }))!;

    await tester.pumpWidget(StarForgeStaffApp(appState: state));
    await tester.pumpAndSettle();

    for (final label in ['Today', 'Groups', 'Tasks', 'Messages', 'More']) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    final settings = find.text('Settings');
    await tester.ensureVisible(settings);
    await tester.pumpAndSettle();
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(find.text('Design studio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('English'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('English'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await state.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
