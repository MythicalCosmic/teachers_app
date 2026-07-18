import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starforge_staff/screens/ai/ai_chat_list_screen.dart';
import 'package:starforge_staff/screens/ai/ai_chat_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/ai', builder: (_, _) => const AiChatListScreen()),
    GoRoute(path: '/ai/chat', builder: (_, _) => const AiChatScreen()),
  ],
);

Widget _host(GoRouter router, {required Locale locale}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    child: MaterialApp.router(
      locale: locale,
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildMaterialTheme(colors, dark: false),
      routerConfig: router,
    ),
  );
}

Future<GoRouter> _pumpWorkspace(
  WidgetTester tester,
  String initialLocation, {
  Locale locale = const Locale('uz'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.reset);
  final router = _router(initialLocation);
  addTearDown(router.dispose);
  await tester.pumpWidget(_host(router, locale: locale));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('search filters groups and opens the selected group context', (
    tester,
  ) async {
    await _pumpWorkspace(tester, '/ai');

    expect(find.text('SERVER YO‘Q'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('ai-workspace-search-field')),
      'Trapetsiya',
    );
    await tester.pumpAndSettle();

    expect(find.text('10-V Geometriya'), findsOneWidget);
    expect(find.text('9-B Algebra'), findsNothing);
    await tester.tap(find.byKey(const Key('ai-group-10-v-geometriya')));
    await tester.pumpAndSettle();

    expect(find.text('10-V Geometriya'), findsOneWidget);
    expect(find.text('19 o‘quvchi · Trapetsiya va yuzalar'), findsOneWidget);
    expect(find.textContaining('serverga yuborilmaydi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'general suggestions open all-groups chat and submit themselves',
    (tester) async {
      await _pumpWorkspace(tester, '/ai');
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      final suggestion = find.byKey(const Key('ai-suggestion-0'));
      expect(suggestion, findsOneWidget);
      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      expect(find.text('Barcha guruhlar'), findsOneWidget);
      expect(
        find.text('Ushbu hafta eng yaxshi 5 o‘quvchini ko‘rsat'),
        findsOneWidget,
      );
      expect(find.textContaining('64 o‘quvchi'), findsWidgets);
      expect(find.text('QURILMADAGI DEMO'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quick prompts and free-form composer create local replies', (
    tester,
  ) async {
    await _pumpWorkspace(tester, '/ai/chat?group=9-b-algebra');

    await tester.tap(find.byKey(const Key('ai-quick-1')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('ai-thinking')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    expect(find.text('Kim qiynalmoqda?'), findsWidgets);
    expect(find.textContaining('Eshmatov Otabek'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('ai-composer')),
      'Bugungi reja qanday?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('ai-send')));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();

    expect(find.text('Bugungi reja qanday?'), findsOneWidget);
    expect(find.textContaining('haftalik demo xulosasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('more menu explains local demo and clears the conversation', (
    tester,
  ) async {
    await _pumpWorkspace(
      tester,
      '/ai/chat?group=9-b-algebra&prompt=Tozalanadigan%20savol',
    );
    expect(find.text('Tozalanadigan savol'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yordam'));
    await tester.pumpAndSettle();
    expect(find.text('Qurilmadagi AI haqida'), findsOneWidget);
    expect(
      find.textContaining('Savollar serverga yuborilmaydi'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('ai-close-help')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ai-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suhbatni tozalash'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-confirm-clear')));
    await tester.pumpAndSettle();

    expect(find.text('Tozalanadigan savol'), findsNothing);
    expect(find.textContaining('demo yordamchiman'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English locale translates interactive AI chrome and replies', (
    tester,
  ) async {
    await _pumpWorkspace(tester, '/ai', locale: const Locale('en'));

    expect(find.text('AI workspace'), findsOneWidget);
    expect(find.text('MY GROUPS'), findsOneWidget);
    expect(find.text('NO SERVER'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('AI ish maydoni'), findsNothing);
    expect(find.text('Bugun'), findsNothing);
    expect(find.text('Guruhlar'), findsNothing);
    expect(find.text('Vazifa'), findsNothing);

    await tester.tap(find.byKey(const Key('ai-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Search groups, topics, or suggestions…'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('ai-workspace-search-field')),
      'Trapezoids',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-group-10-v-geometriya')));
    await tester.pumpAndSettle();

    expect(find.text('10-V Geometry'), findsOneWidget);
    expect(find.text('19 students · Trapezoids and area'), findsOneWidget);
    expect(find.text('Weekly summary'), findsOneWidget);
    expect(
      find.text('Device-local demo · never sent to a server'),
      findsOneWidget,
    );
    expect(find.textContaining('o‘quvchi'), findsNothing);

    await tester.tap(find.byKey(const Key('ai-quick-1')));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
    expect(find.text('Who needs support?'), findsWidgets);
    expect(find.textContaining('may need more support'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai-more-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Clear conversation'), findsOneWidget);
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(find.text('About device-local AI'), findsOneWidget);
    expect(find.textContaining('never sent to a server'), findsWidgets);
    expect(find.text('Qurilmadagi AI haqida'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian locale explicitly falls back to English, not Uzbek', (
    tester,
  ) async {
    await _pumpWorkspace(tester, '/ai', locale: const Locale('ru'));

    expect(find.text('AI workspace'), findsOneWidget);
    expect(find.text('MY GROUPS'), findsOneWidget);
    expect(find.text('NO SERVER'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('AI ish maydoni'), findsNothing);
    expect(find.text('MENING GURUHLARIM'), findsNothing);
    expect(find.text('SERVER YO‘Q'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
