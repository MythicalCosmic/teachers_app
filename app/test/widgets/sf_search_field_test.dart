import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_search_field.dart';

Widget _host(Widget child, {bool dark = false}) {
  const palette = SfPalette.daryo;
  final colors = sfColorsFor(palette, dark: dark);
  return SfTheme(
    colors: colors,
    palette: palette,
    dark: dark,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: dark),
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('search exposes semantics and a minimum 44dp touch target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const fieldKey = Key('accessible-search');

    await tester.pumpWidget(
      _host(
        const SfSearchField(
          key: fieldKey,
          hintText: 'Search services',
          semanticLabel: 'Search staff services',
        ),
      ),
    );

    expect(find.bySemanticsLabel('Search staff services'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(fieldKey)).height,
      greaterThanOrEqualTo(44),
    );

    semantics.dispose();
  });

  testWidgets('clear action follows controller changes and keeps focus', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        SfSearchField(
          controller: controller,
          hintText: 'Search groups',
          clearTooltip: 'Clear group search',
          onChanged: changes.add,
        ),
      ),
    );

    expect(find.byTooltip('Clear group search'), findsNothing);
    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pump();

    final clear = find.byTooltip('Clear group search');
    expect(clear, findsOneWidget);
    expect(tester.getSize(clear).height, greaterThanOrEqualTo(44));

    await tester.tap(clear);
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
    expect(changes, isNotEmpty);
    expect(changes.last, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );
  });

  testWidgets('focus has a visible animated treatment', (tester) async {
    await tester.pumpWidget(
      _host(const SfSearchField(hintText: 'Search students')),
    );

    AnimatedContainer visual() => tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(SfSearchField),
        matching: find.byType(AnimatedContainer),
      ),
    );

    expect((visual().decoration! as BoxDecoration).boxShadow, isEmpty);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect((visual().decoration! as BoxDecoration).boxShadow, isNotEmpty);

    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    final focused = decoration.focusedBorder! as OutlineInputBorder;
    expect(focused.borderSide.width, greaterThan(1));
  });

  testWidgets('dark theme uses the active StarForge surface palette', (
    tester,
  ) async {
    final colors = sfColorsFor(SfPalette.daryo, dark: true);
    await tester.pumpWidget(
      _host(const SfSearchField(hintText: 'Search records'), dark: true),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.filled, isTrue);
    expect(field.decoration?.fillColor, colors.surface2);
    expect(field.style?.color, colors.ink);
  });
}
