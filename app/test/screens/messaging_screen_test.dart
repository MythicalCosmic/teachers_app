import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/features/messaging/messaging_models.dart';
import 'package:starforge_staff/screens/chat_screen.dart';
import 'package:starforge_staff/screens/messaging_contact_profile_screen.dart';
import 'package:starforge_staff/screens/messages_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Future<AppState> _teacherState() async {
  final state = await AppState.bootstrap(storage: MemoryAppStorage());
  await state.signIn(username: 'nigora.karimova', password: 'demo2026');
  return state;
}

Widget _host(AppState state) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp(
        locale: Locale(state.settings.locale.name),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        home: const MessagesScreen(),
      ),
    ),
  );
}

Widget _routerHost(AppState state, GoRouter router) {
  final colors = sfColorsFor(SfPalette.daryo);
  return AppScope(
    notifier: state,
    child: SfTheme(
      colors: colors,
      palette: SfPalette.daryo,
      dark: false,
      child: MaterialApp.router(
        locale: Locale(state.settings.locale.name),
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildMaterialTheme(colors, dark: false),
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _settleMessaging(WidgetTester tester) async {
  await tester.pump();
  if (MessagingController.shared.isRestoring) {
    await tester.runAsync(() => MessagingController.shared.restored);
  }
  await tester.pumpAndSettle();
}

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets(
    'conversation search and multi-select actions change repository',
    (tester) async {
      final state = (await tester.runAsync(_teacherState))!;
      await tester.pumpWidget(_host(state));
      await _settleMessaging(tester);

      expect(find.text('Metodika jamoasi'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        'mavjud bo‘lmagan matn',
      );
      await tester.pump();
      expect(find.text('Natija topilmadi'), findsOneWidget);

      await tester.tap(find.byTooltip('Qidiruvni tozalash'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Metodika jamoasi'));
      await tester.pumpAndSettle();
      expect(find.text('1 ta tanlandi'), findsOneWidget);

      await tester.tap(find.byTooltip('O‘qilgan qilish'));
      await tester.pumpAndSettle();
      expect(
        MessagingController.shared.threadById('thread-methodist')?.isRead,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('persisted English locale translates messaging controls', (
    tester,
  ) async {
    final state = (await tester.runAsync(_teacherState))!;
    await state.setLocale(AppLocale.en);
    await tester.pumpWidget(_host(state));
    await _settleMessaging(tester);

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Important'), findsOneWidget);
    expect(find.text('Search name, username, or message'), findsOneWidget);

    await tester.longPress(find.text('Metodika jamoasi'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byTooltip('Archive'), findsOneWidget);
    expect(find.byTooltip('Mark as read'), findsOneWidget);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Pin / unpin'), findsOneWidget);
    expect(find.text('Mute / unmute'), findsOneWidget);
    expect(find.text('Add to folder'), findsOneWidget);
    expect(find.text('Delete conversations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat sends text, image and voice with animated composer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = (await tester.runAsync(_teacherState))!;
    await state.setLocale(AppLocale.en);
    final router = GoRouter(
      initialLocation: '/messages/chat?thread=thread-methodist',
      routes: [
        GoRoute(path: '/messages/chat', builder: (_, _) => const ChatScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerHost(state, router));
    await _settleMessaging(tester);

    expect(find.text('Write a message…'), findsOneWidget);
    expect(find.byTooltip('Search conversation'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '😀 Tayyor');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      MessagingController.shared
          .threadById('thread-methodist')!
          .messages
          .last
          .body,
      '😀 Tayyor',
    );

    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classroom board photo'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      MessagingController.shared
          .threadById('thread-methodist')!
          .messages
          .last
          .kind,
      MessagingKind.image,
    );
    expect(find.text('DEMO MEDIA'), findsWidgets);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const ValueKey('recording')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      MessagingController.shared
          .threadById('thread-methodist')!
          .messages
          .last
          .kind,
      MessagingKind.voice,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('contact profile exposes real mute, call and share actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final state = (await tester.runAsync(_teacherState))!;
    await state.setLocale(AppLocale.en);
    final router = GoRouter(
      initialLocation: '/messages/contact?thread=thread-methodist',
      routes: [
        GoRoute(
          path: '/messages/contact',
          builder: (_, _) => const MessagingContactProfileScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerHost(state, router));
    await _settleMessaging(tester);

    expect(find.text('@rano.karimova'), findsOneWidget);
    expect(find.text('+998 95 380 41 52'), findsOneWidget);
    expect(find.text('Staff profile'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Mute'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.notifications_off_rounded));
    await tester.pumpAndSettle();
    expect(
      MessagingController.shared.threadById('thread-methodist')!.isMuted,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.call_rounded));
    await tester.pump(const Duration(seconds: 1));
    expect(MessagingController.shared.activeCallThreadId, 'thread-methodist');
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
    expect(find.text('Microphone muted'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(find.text('Speaker off'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_end_rounded));
    await tester.pumpAndSettle();
    expect(MessagingController.shared.activeCallThreadId, isNull);

    await tester.scrollUntilVisible(
      find.text('Share contact'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final shareTile = find.widgetWithText(ListTile, 'Share contact');
    await tester.ensureVisible(shareTile);
    await tester.pump();
    await tester.tap(shareTile);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Contact details copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
