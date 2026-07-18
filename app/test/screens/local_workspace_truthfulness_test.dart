import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/screens/auth/forgot_password_screen.dart';
import 'package:starforge_staff/screens/content_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

Widget _theme(Widget child, {AppState? state}) {
  final colors = sfColorsFor(SfPalette.daryo);
  final themed = SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp(
      locale: const Locale('en'),
      theme: buildMaterialTheme(colors, dark: false),
      home: child,
    ),
  );
  return state == null ? themed : AppScope(notifier: state, child: themed);
}

void main() {
  testWidgets('material cards and offline bookmarks persist honestly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = (await tester.runAsync(_teacherState))!;

    await tester.pumpWidget(_theme(const ContentScreen(), state: state));
    await tester.pumpAndSettle();
    expect(find.text('Materials'), findsOneWidget);
    expect(find.textContaining('Binary file transfer'), findsOneWidget);

    await tester.tap(find.byTooltip('Add material card'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Quadratic reflection guide');
    await tester.enterText(fields.at(1), 'Use after the exit ticket.');
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(find.text('Quadratic reflection guide'), findsOneWidget);

    await tester.ensureVisible(find.text('Quadratic reflection guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quadratic reflection guide'));
    await tester.pumpAndSettle();
    expect(find.text('Local card'), findsOneWidget);
    expect(find.textContaining('File transfer'), findsOneWidget);
    await tester.ensureVisible(find.text('Bookmark offline'));
    await tester.tap(find.text('Bookmark offline'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('starforge.content_workspace.v1');
    expect(raw, isNotNull);
    final json = Map<String, dynamic>.from(jsonDecode(raw!) as Map);
    expect(json['localResources'], hasLength(1));
    expect(json['offlineBookmarks'], hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_theme(const ContentScreen(), state: state));
    await tester.pumpAndSettle();
    expect(find.text('Quadratic reflection guide'), findsOneWidget);
  });

  testWidgets('password recovery prepares a local request without fake send', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_theme(const ForgotPasswordScreen()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('verified administrator channel'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'nigora.karimova');
    await tester.tap(find.text('Prepare request'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request prepared'), findsOneWidget);
    expect(
      find.textContaining('not connected to the identity server'),
      findsOneWidget,
    );
    expect(find.textContaining('was sent'), findsNothing);
    expect(find.text('Copy request again'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('starforge.pending_recovery_request.v1');
    expect(raw, isNotNull);
    expect(raw, contains('nigora.karimova'));
  });
}
