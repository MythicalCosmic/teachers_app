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

  testWidgets('password recovery uses request and confirmation contracts', (
    tester,
  ) async {
    String? requestedIdentifier;
    String? requestedType;
    String? confirmedCode;
    await tester.pumpWidget(
      _theme(
        ForgotPasswordScreen(
          requestReset: (identifier, accountType) async {
            requestedIdentifier = identifier;
            requestedType = accountType;
          },
          confirmReset: (identifier, accountType, code, newPassword) async {
            confirmedCode = code;
            expect(identifier, requestedIdentifier);
            expect(accountType, requestedType);
            expect(newPassword, 'StrongPass2026!');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reset-identifier')),
      'teacher@starforge.uz',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(requestedIdentifier, 'teacher@starforge.uz');
    expect(requestedType, 'staff');
    expect(find.byKey(const ValueKey('reset-verify')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('reset-code')), '123456');
    await tester.enterText(
      find.byKey(const ValueKey('reset-new-password')),
      'StrongPass2026!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-confirm-password')),
      'StrongPass2026!',
    );
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(confirmedCode, '123456');
    expect(find.byKey(const ValueKey('reset-success')), findsOneWidget);
    expect(find.text('Password updated'), findsOneWidget);
  });
}
