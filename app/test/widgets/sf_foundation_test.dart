import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_bottom_navigation.dart';
import 'package:starforge_staff/widgets/sf_glass_surface.dart';
import 'package:starforge_staff/widgets/sf_scaffold.dart';

Widget _host(Widget child, {MediaQueryData media = const MediaQueryData()}) {
  const palette = SfPalette.daryo;
  final colors = sfColorsFor(palette);
  return SfTheme(
    colors: colors,
    palette: palette,
    dark: false,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: false),
      home: MediaQuery(
        data: media,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('motion tokens collapse to zero for reduced motion', (
    tester,
  ) async {
    Duration? resolved;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            resolved = SfMotion.resolve(context, SfMotion.emphasized);
            return const SizedBox();
          },
        ),
        media: const MediaQueryData(disableAnimations: true),
      ),
    );

    expect(resolved, Duration.zero);
  });

  testWidgets('explicit motion flag also collapses animation', (tester) async {
    Duration? resolved;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            resolved = SfMotion.resolve(
              context,
              SfMotion.standard,
              enabled: false,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, Duration.zero);
  });

  testWidgets('glass surface avoids BackdropFilter when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SfGlassSurface(
          enabled: false,
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets(
    'glass surface can explicitly enable blur after capability check',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const SfGlassSurface(
            enabled: true,
            platformAdaptive: false,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );

  testWidgets('adaptive bottom navigation reports generic destination index', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.bottomCenter,
          child: SfAdaptiveBottomNavigation(
            activeIndex: 0,
            glassEnabled: false,
            onDestinationSelected: (index) => selected = index,
            destinations: const [
              SfBottomDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Bugun',
              ),
              SfBottomDestination(
                icon: Icon(Icons.group_outlined),
                label: 'Guruhlar',
              ),
            ],
          ),
        ),
        media: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
      ),
    );

    expect(find.byType(SafeArea), findsWidgets);
    await tester.tap(find.text('Guruhlar'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets(
    'scaffold protects a custom bottom action from the home indicator',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const SfScaffold(
            body: SizedBox.expand(),
            bottom: SizedBox(key: Key('bottom-action'), height: 44),
          ),
          media: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
        ),
      );

      expect(
        find.ancestor(
          of: find.byKey(const Key('bottom-action')),
          matching: find.byType(SafeArea),
        ),
        findsWidgets,
      );
    },
  );
}
