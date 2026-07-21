import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/connectivity/backend_reachability.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';
import 'package:starforge_staff/widgets/sf_connectivity_gate.dart';

void main() {
  testWidgets('offline production state replaces all interactive content', (
    tester,
  ) async {
    final probe = _MutableProbe(false);
    final controller = _controller(probe);
    await controller.start();

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        locale: AppLocale.en,
        child: const Text('sensitive route content'),
      ),
    );

    expect(
      find.byKey(const Key('production-connectivity-gate')),
      findsOneWidget,
    );
    expect(find.text('Internet connection required'), findsOneWidget);
    expect(find.text('sensitive route content'), findsNothing);
    expect(find.byKey(const Key('connectivity-retry')), findsOneWidget);

    probe.reachable = true;
    await tester.tap(find.byKey(const Key('connectivity-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('production-connectivity-gate')), findsNothing);
    expect(find.text('sensitive route content'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('initial check has a clear localized loading surface', (
    tester,
  ) async {
    final probe = _PendingProbe();
    final controller = _controller(probe);
    final checking = controller.start();

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        locale: AppLocale.uz,
        child: const Text('app'),
      ),
    );

    expect(find.text('Xavfsiz aloqa tekshirilmoqda'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('app'), findsNothing);

    probe.complete(true);
    await checking;
    await tester.pumpAndSettle();
    expect(find.text('app'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('uses the Cupertino retry control on iPhone', (tester) async {
    final controller = _controller(_MutableProbe(false));
    await controller.start();

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        locale: AppLocale.en,
        platform: TargetPlatform.iOS,
        child: const Text('app'),
      ),
    );

    expect(find.byKey(const Key('connectivity-retry')), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    controller.dispose();
  });
}

BackendReachabilityController _controller(BackendReachabilityProbe probe) =>
    BackendReachabilityController(
      enabled: true,
      reachabilityProbe: probe,
      onlinePollInterval: const Duration(days: 1),
      offlinePollInterval: const Duration(days: 1),
    );

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.controller,
    required this.locale,
    required this.child,
    this.platform = TargetPlatform.android,
  });

  final BackendReachabilityController controller;
  final AppLocale locale;
  final Widget child;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final colors = sfColorsFor(SfPalette.daryo);
    return MaterialApp(
      theme: buildMaterialTheme(
        colors,
        dark: false,
      ).copyWith(platform: platform),
      home: SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        child: SfConnectivityGate(
          controller: controller,
          locale: locale,
          child: child,
        ),
      ),
    );
  }
}

final class _MutableProbe implements BackendReachabilityProbe {
  _MutableProbe(this.reachable);

  bool reachable;

  @override
  Future<bool> canReachBackend() async => reachable;

  @override
  void dispose() {}
}

final class _PendingProbe implements BackendReachabilityProbe {
  final _completer = Completer<bool>();

  @override
  Future<bool> canReachBackend() => _completer.future;

  void complete(bool value) => _completer.complete(value);

  @override
  void dispose() {}
}
