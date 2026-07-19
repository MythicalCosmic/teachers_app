import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_bottom_navigation.dart';
import 'package:starforge_staff/widgets/sf_glass_surface.dart';

void main() {
  testWidgets(
    'bottom navigation fills phone width across asymmetric safe insets',
    (tester) async {
      const size = Size(852, 393);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final colors = sfColorsFor(SfPalette.daryo);
      await tester.pumpWidget(
        SfTheme(
          colors: colors,
          palette: SfPalette.daryo,
          dark: false,
          child: MaterialApp(
            theme: buildMaterialTheme(colors, dark: false),
            home: MediaQuery(
              data: const MediaQueryData(
                size: size,
                padding: EdgeInsets.only(right: 44, bottom: 34),
              ),
              child: Scaffold(
                bottomNavigationBar: SfAdaptiveBottomNavigation(
                  activeIndex: 0,
                  onDestinationSelected: (_) {},
                  destinations: const [
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
                      icon: Icon(Icons.chat_bubble_outline),
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

      final surface = tester.getRect(find.byType(SfGlassSurface));
      expect(surface.left, closeTo(8, .01));
      expect(surface.right, closeTo(size.width - 8, .01));
      expect(surface.width, closeTo(size.width - 16, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bottom navigation keeps comfortable phone tap targets', (
    tester,
  ) async {
    final colors = sfColorsFor(SfPalette.daryo);
    await tester.pumpWidget(
      SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        child: MaterialApp(
          theme: buildMaterialTheme(colors, dark: false),
          home: Scaffold(
            bottomNavigationBar: SfAdaptiveBottomNavigation(
              activeIndex: 0,
              onDestinationSelected: (_) {},
              destinations: const [
                SfBottomDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Today',
                ),
                SfBottomDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: 'Groups',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('Today')).height, greaterThan(10));
    expect(tester.getSize(find.byType(SfGlassSurface)).height, greaterThan(55));
    expect(tester.takeException(), isNull);
  });

  testWidgets('global effects switch disables explicitly requested nav blur', (
    tester,
  ) async {
    final colors = sfColorsFor(SfPalette.daryo);
    await tester.pumpWidget(
      SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        visualStyle: AppVisualStyle.liquidGlass,
        liquidGlass: false,
        child: MaterialApp(
          theme: buildMaterialTheme(colors, dark: false),
          home: Scaffold(
            bottomNavigationBar: SfAdaptiveBottomNavigation(
              activeIndex: 0,
              glassEnabled: true,
              platformAdaptiveGlass: false,
              onDestinationSelected: (_) {},
              destinations: const [
                SfBottomDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Today',
                ),
                SfBottomDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: 'Groups',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SfGlassSurface),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
