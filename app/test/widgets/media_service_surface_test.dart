import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_adaptive_dialog.dart';
import 'package:starforge_staff/widgets/sf_card.dart';
import 'package:starforge_staff/widgets/sf_glass_surface.dart';
import 'package:starforge_staff/widgets/sf_media_player.dart';
import 'package:starforge_staff/widgets/sf_service_unavailable.dart';

void main() {
  test('media types map to truthful playback and print actions', () {
    expect(sfMediaKindForContentType('video/mp4'), SfMediaKind.video);
    expect(sfMediaKindForContentType(' audio/mpeg '), SfMediaKind.audio);
    expect(sfMediaKindForContentType('application/pdf'), isNull);
    expect(sfContentTypeCanPrint('application/pdf'), isTrue);
    expect(sfContentTypeCanPrint('video/mp4'), isFalse);
    expect(sfContentTypeCanPrint('audio/mpeg'), isFalse);
    expect(sfContentTypeCanPrint('image/png'), isFalse);
  });

  testWidgets('media retry resolves a fresh signed URL', (tester) async {
    var refreshes = 0;
    await tester.pumpWidget(
      _host(
        child: SfNetworkMediaPlayer(
          url: 'expired://first-link',
          title: 'Lesson recording',
          kind: SfMediaKind.video,
          autoplay: false,
          refreshUrl: () async {
            refreshes++;
            return 'expired://fresh-link-$refreshes';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('media-retry-fresh-url')), findsOneWidget);
    await tester.tap(find.byKey(const Key('media-retry-fresh-url')));
    await tester.pumpAndSettle();

    expect(refreshes, 1);
    expect(find.byKey(const Key('media-retry-fresh-url')), findsOneWidget);
  });

  testWidgets('unavailable service obscures controls and exposes retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        child: SfServiceUnavailable(
          title: 'AI service is temporarily unavailable',
          message: 'Controls are blocked until server state is verified.',
          statusLabel: 'AI · SERVICE OFFLINE',
          onRetry: () async => retries++,
          preview: TextButton(
            key: const Key('blocked-control'),
            onPressed: () => fail('A blocked control was activated.'),
            child: const Text('Generate'),
          ),
        ),
      ),
    );

    expect(find.text('AI · SERVICE OFFLINE'), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    await tester.tap(find.byKey(const Key('service-unavailable-retry')));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('confirmation is a Cupertino alert on iPhone', (tester) async {
    await tester.pumpWidget(
      _host(
        platform: TargetPlatform.iOS,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSfConfirmDialog(
              context,
              title: 'Save attendance?',
              message: 'This updates the server record.',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('disabling liquid glass removes blur but keeps a surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        platform: TargetPlatform.iOS,
        visualStyle: AppVisualStyle.liquidGlass,
        liquidGlass: false,
        child: const SfSurfaceCard(child: Text('Readable fallback')),
      ),
    );

    expect(find.text('Readable fallback'), findsOneWidget);
    expect(find.byType(SfGlassSurface), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}

Widget _host({
  required Widget child,
  TargetPlatform platform = TargetPlatform.android,
  AppVisualStyle visualStyle = AppVisualStyle.classic,
  bool liquidGlass = true,
}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    visualStyle: visualStyle,
    liquidGlass: liquidGlass,
    child: MaterialApp(
      theme: buildMaterialTheme(
        colors,
        dark: false,
      ).copyWith(platform: platform),
      home: Scaffold(body: child),
    ),
  );
}
