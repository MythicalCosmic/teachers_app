import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_scope.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_adaptive_dialog.dart';
import 'package:starforge_staff/widgets/sf_app_bar.dart';
import 'package:starforge_staff/widgets/sf_card.dart';
import 'package:starforge_staff/widgets/sf_bottom_navigation.dart';
import 'package:starforge_staff/widgets/sf_glass_surface.dart';
import 'package:starforge_staff/widgets/sf_pressable.dart';
import 'package:starforge_staff/widgets/sf_scaffold.dart';
import 'package:starforge_staff/widgets/sf_toast.dart';

Widget _host({
  required Widget child,
  AppVisualStyle style = AppVisualStyle.classic,
  bool dark = false,
  double textScale = 1,
  Size size = const Size(393, 852),
}) {
  final colors = sfColorsFor(SfPalette.daryo, dark: dark);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: dark,
    visualStyle: style,
    liquidGlass: true,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: dark),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  for (final style in AppVisualStyle.values) {
    testWidgets('${style.name} renders the shared surface without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          style: style,
          child: const SfScaffold(
            body: Center(
              child: SfSurfaceCard(
                padding: EdgeInsets.all(18),
                child: Text('Adaptive surface'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Adaptive surface'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('toast appears in the top half and action remains functional', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      _host(
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => SfToast.show(
                context,
                title: 'Saved',
                message: 'Top-right feedback',
                actionLabel: 'Open',
                onAction: () => actions++,
                motionEnabled: false,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    final center = tester.getCenter(find.text('Top-right feedback'));
    expect(center.dy, lessThan(260));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(actions, 1);
  });

  testWidgets('navigation glass pill does not absorb the iPhone safe inset', (
    tester,
  ) async {
    final colors = sfColorsFor(SfPalette.daryo);
    await tester.pumpWidget(
      SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        liquidGlass: true,
        child: MaterialApp(
          theme: buildMaterialTheme(colors, dark: false),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(bottom: 34),
            ),
            child: Scaffold(
              bottomNavigationBar: SfAdaptiveBottomNavigation(
                activeIndex: 0,
                onDestinationSelected: null,
                destinations: [
                  SfBottomDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Today',
                  ),
                  SfBottomDestination(
                    icon: Icon(Icons.groups_outlined),
                    label: 'Groups',
                  ),
                  SfBottomDestination(
                    icon: Icon(Icons.task_alt_outlined),
                    label: 'Tasks',
                  ),
                  SfBottomDestination(
                    icon: Icon(Icons.chat_outlined),
                    label: 'Messages',
                  ),
                  SfBottomDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final glassSize = tester.getSize(find.byType(SfGlassSurface));
    expect(glassSize.height, lessThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation bar reflows for large dynamic type', (tester) async {
    await tester.pumpWidget(
      _host(
        size: const Size(320, 844),
        textScale: 3,
        child: Scaffold(
          body: SfNavBar(
            title: 'A deliberately long workspace title',
            subtitle: 'Accessible navigation subtitle',
            leading: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('A deliberately long workspace title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adaptive confirmation uses localized default labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSfConfirmDialog(
                context,
                title: 'Confirm action',
                message: 'This can be cancelled safely.',
              ),
              child: const Text('Open dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('press feedback obeys the persisted haptics toggle', (
    tester,
  ) async {
    final state = (await tester.runAsync(() async {
      final state = await AppState.bootstrap(storage: MemoryAppStorage());
      await state.signIn(username: 'nigora.karimova', password: 'demo2026');
      await state.setHaptics(false);
      return state;
    }))!;
    var vibrations = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') vibrations++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        notifier: state,
        child: _host(
          child: Scaffold(
            body: SfPressable(
              onPressed: () {},
              haptic: true,
              child: const Text('Press me'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Press me'));
    await tester.pump();
    expect(vibrations, 0);

    await tester.runAsync(() => state.setHaptics(true));
    await tester.pump();
    await tester.tap(find.text('Press me'));
    await tester.pump();
    expect(vibrations, 1);
  });
}
