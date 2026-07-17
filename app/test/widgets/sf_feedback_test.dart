import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_state_view.dart';
import 'package:starforge_staff/widgets/sf_toast.dart';

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
  testWidgets('error state exposes retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        SfErrorState(
          message: 'Internet aloqasini tekshiring.',
          onRetry: () => retries++,
        ),
      ),
    );

    await tester.tap(find.text('Qayta urinish'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('loading state becomes static when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SfLoadingState(),
        media: const MediaQueryData(disableAnimations: true),
      ),
    );

    final progress = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(progress.value, isNotNull);
  });

  testWidgets('toast displays feedback and runs its action', (tester) async {
    var actions = 0;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SfToast.show(
              context,
              message: 'Davomat saqlandi',
              actionLabel: 'Ko‘rish',
              onAction: () => actions++,
              glassEnabled: false,
              motionEnabled: false,
            ),
            child: const Text('Show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Davomat saqlandi'), findsOneWidget);

    await tester.tap(find.text('Ko‘rish'));
    await tester.pumpAndSettle();
    expect(actions, 1);
  });
}
