import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/screens/new_task_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_button.dart';

Future<AppState> _signedInState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

Widget _host(AppState state, {TextScaler textScaler = TextScaler.noScaling}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: const NewTaskScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'all task templates fit the 393px viewport and remain functional',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = (await tester.runAsync(_signedInState))!;
      addTearDown(state.dispose);
      await tester.pumpWidget(_host(state));
      await tester.pumpAndSettle();

      const templateKeys = [
        'new-task-template-blank',
        'new-task-template-lesson',
        'new-task-template-assessment',
        'new-task-template-followUp',
      ];
      final templateRects = templateKeys
          .map((key) => tester.getRect(find.byKey(ValueKey(key))))
          .toList();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
      for (final rect in templateRects) {
        expect(rect.left, greaterThanOrEqualTo(16));
        expect(rect.right, lessThanOrEqualTo(377));
        expect(rect.height, 92);
      }
      expect(templateRects.map((rect) => rect.top).toSet(), hasLength(1));
      expect(templateRects.last.right, closeTo(377, 0.1));
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('new-task-template-lesson')));
      await tester.pumpAndSettle();

      expect(find.text('Plan the next lesson'), findsOneWidget);
      expect(find.text('Define the learning objective'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text form sections scroll fully above the distinct sticky action',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = (await tester.runAsync(_signedInState))!;
      addTearDown(state.dispose);
      await tester.pumpWidget(
        _host(state, textScaler: const TextScaler.linear(1.4)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('new-task-template-lesson')));
      await tester.pumpAndSettle();

      final scroll = find.byKey(const ValueKey('new-task-form-scroll'));
      final actionBar = find.byKey(
        const ValueKey('new-task-sticky-action-bar'),
      );
      final actionBarRect = tester.getRect(actionBar);
      final actionRect = tester.getRect(find.byType(SfButton));
      final actionContainer = tester.widget<Container>(actionBar);
      final actionDecoration = actionContainer.decoration! as BoxDecoration;

      expect(actionBarRect.left, 0);
      expect(actionBarRect.right, 393);
      expect(actionRect.left, greaterThanOrEqualTo(16));
      expect(actionRect.right, lessThanOrEqualTo(377));
      expect(actionDecoration.border, isNotNull);
      expect(actionDecoration.boxShadow, isNotEmpty);

      for (final key in [
        'new-task-properties-card',
        'new-task-checklist-card',
        'new-task-tags-card',
        'new-task-tip-card',
      ]) {
        final section = find.byKey(ValueKey(key));
        await tester.ensureVisible(section);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(section).bottom,
          lessThanOrEqualTo(tester.getRect(actionBar).top),
          reason: '$key should scroll completely above the sticky action',
        );
      }

      final list = tester.widget<ListView>(scroll);
      expect(list.padding, const EdgeInsets.fromLTRB(16, 10, 16, 22));
      expect(find.text('Create task page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
