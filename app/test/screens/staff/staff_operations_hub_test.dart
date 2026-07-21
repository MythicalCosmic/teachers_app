import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/staff/staff_operations_screen.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  final colors = sfColorsFor(SfPalette.daryo);
  return SfTheme(
    colors: colors,
    palette: SfPalette.daryo,
    dark: false,
    reducedMotion: true,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildMaterialTheme(colors, dark: false),
      home: child,
    ),
  );
}

void main() {
  testWidgets(
    'staff services renders only capabilities granted to the account',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const allowed = {
        StaffCapability.acknowledgeStaffRules,
        StaffCapability.viewStaffMeetings,
      };
      await tester.pumpWidget(
        _host(
          StaffOperationsHubScreen(
            role: StaffRole.assistant,
            canAccess: allowed.contains,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('staff-services-overview')),
        findsOneWidget,
      );
      expect(find.text('2 services ready'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('staff-operation-module-rules')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('staff-operation-module-meetings')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('staff-operation-module-payments')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('staff-operation-module-reports')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('staff service search and category controls remain usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        StaffOperationsHubScreen(
          role: StaffRole.teacher,
          canAccess: (capability) => capability != StaffCapability.viewSales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('staff-services-search')),
      'meeting',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('staff-operation-module-meetings')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-operation-module-rules')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('staff-services-search')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('staff-service-filter-people')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('staff-operation-module-students')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('staff-operation-module-meetings')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
