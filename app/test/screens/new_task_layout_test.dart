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
import 'package:starforge_staff/widgets/sf_hint_card.dart';

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
    'template picker reflows and the bottom action never covers content',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = (await tester.runAsync(_signedInState))!;
      addTearDown(state.dispose);
      await tester.pumpWidget(
        _host(state, textScaler: const TextScaler.linear(1.35)),
      );
      await tester.pumpAndSettle();

      final blankRect = tester.getRect(
        find.byKey(const ValueKey('new-task-template-blank')),
      );
      final lessonRect = tester.getRect(
        find.byKey(const ValueKey('new-task-template-lesson')),
      );
      final assessmentRect = tester.getRect(
        find.byKey(const ValueKey('new-task-template-assessment')),
      );
      final followUpRect = tester.getRect(
        find.byKey(const ValueKey('new-task-template-followUp')),
      );
      expect(blankRect.top, lessonRect.top);
      expect(assessmentRect.top, followUpRect.top);
      expect(assessmentRect.top, greaterThan(blankRect.bottom));
      expect(followUpRect.right, lessThanOrEqualTo(304));
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      final hintRect = tester.getRect(find.byType(SfHintCard));
      final actionRect = tester.getRect(find.byType(SfButton));
      expect(hintRect.bottom, lessThanOrEqualTo(actionRect.top));
      expect(find.text('Create task page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
