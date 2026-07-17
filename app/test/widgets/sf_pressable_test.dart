import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_button.dart';
import 'package:starforge_staff/widgets/sf_pressable.dart';

Widget _host(Widget child) {
  const palette = SfPalette.daryo;
  final colors = sfColorsFor(palette);
  return SfTheme(
    colors: colors,
    palette: palette,
    dark: false,
    child: MaterialApp(
      theme: buildMaterialTheme(colors, dark: false),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('SfPressable exposes enabled button semantics and activates', (
    tester,
  ) async {
    var activations = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        SfPressable(
          semanticLabel: 'Davom etish',
          onPressed: () => activations++,
          child: const SizedBox(width: 120, height: 44),
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Davom etish'));
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, isNot(Tristate.none));
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(find.byType(SfPressable));
    await tester.pumpAndSettle();
    expect(activations, 1);

    semantics.dispose();
  });

  testWidgets('SfPressable disabled state has no tap action', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const SfPressable(
          semanticLabel: 'O‘chirilgan',
          onPressed: null,
          child: SizedBox(width: 120, height: 44),
        ),
      ),
    );

    final data = tester
        .getSemantics(find.bySemanticsLabel('O‘chirilgan'))
        .getSemanticsData();
    expect(data.flagsCollection.isEnabled, isNot(Tristate.none));
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);

    semantics.dispose();
  });

  testWidgets('SfPressable press state is interruptible', (tester) async {
    SfPressableVisualState? visualState;
    await tester.pumpWidget(
      _host(
        SfPressable(
          onPressed: () {},
          builder: (context, state, child) {
            visualState = state;
            return const SizedBox(width: 120, height: 44);
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SfPressable)),
    );
    await tester.pump();
    expect(visualState?.pressed, isTrue);

    await gesture.cancel();
    await tester.pump();
    expect(visualState?.pressed, isFalse);
  });

  testWidgets('SfPressable activates from the keyboard', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      _host(
        SfPressable(
          autofocus: true,
          onPressed: () => activations++,
          child: const SizedBox(width: 120, height: 44),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);
  });

  testWidgets('SfButton is at least 44dp and null callback is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SfButton(
          key: Key('disabled-button'),
          label: 'Saqlash',
          onPressed: null,
          height: 20,
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('disabled-button'))).height,
      greaterThanOrEqualTo(44),
    );
    final pressable = tester.widget<SfPressable>(find.byType(SfPressable));
    expect(pressable.onPressed, isNull);
  });
}
