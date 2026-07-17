import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/app_state.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_bottom_navigation.dart';
import '../../widgets/sf_shell_scope.dart';

/// Persistent five-position navigation shared by every permitted staff role.
/// The destinations stay spatially stable while their labels and capabilities
/// adapt to the authenticated profile.
class StaffShellScreen extends StatelessWidget {
  const StaffShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final role = app.session?.role ?? StaffRole.teacher;
        final destinations = _destinationsFor(role);
        return PopScope(
          canPop: navigationShell.currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && navigationShell.currentIndex != 0) {
              navigationShell.goBranch(0);
            }
          },
          child: Scaffold(
            backgroundColor: SfTheme.colorsOf(context).bg,
            resizeToAvoidBottomInset: true,
            body: SfShellScope(child: navigationShell),
            bottomNavigationBar: SfAdaptiveBottomNavigation(
              destinations: [
                for (var index = 0; index < destinations.length; index++)
                  SfBottomDestination(
                    icon: Icon(destinations[index].icon),
                    selectedIcon: Icon(destinations[index].selectedIcon),
                    label: destinations[index].label,
                    semanticLabel: destinations[index].semanticLabel,
                    badge: _badgeFor(context, app, role, index),
                  ),
              ],
              activeIndex: navigationShell.currentIndex,
              glassEnabled: app.settings.liquidGlass,
              motionEnabled: !app.settings.reducedMotion,
              hapticsEnabled: app.settings.haptics,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget? _badgeFor(
    BuildContext context,
    AppState app,
    StaffRole role,
    int index,
  ) {
    final count = index == 3
        ? (role == StaffRole.auditor
              ? app.unreadNotificationCount
              : app.unreadMessageCount)
        : 0;
    if (count <= 0) return null;
    final c = SfTheme.colorsOf(context);
    return Semantics(
      label: '$count ta o‘qilmagan',
      child: Container(
        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: c.danger,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.surface, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: SfType.mono(
            size: 8.5,
            weight: FontWeight.w800,
            color: const Color(0xFFFFFCF5),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon,
    this.semanticLabel,
  );

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String semanticLabel;
}

List<_Destination> _destinationsFor(StaffRole role) {
  final labels = switch (role) {
    StaffRole.teacher => const [
      'Bugun',
      'Guruhlar',
      'Vazifalar',
      'Xabarlar',
      'Boshqa',
    ],
    StaffRole.assistant => const [
      'Bugun',
      'Guruhlar',
      'Vazifalar',
      'Xabarlar',
      'Boshqa',
    ],
    StaffRole.methodist => const [
      'Bugun',
      'Sifat',
      'Vazifalar',
      'Xabarlar',
      'Boshqa',
    ],
    StaffRole.reception => const [
      'Bugun',
      'Lidlar',
      'Qabul',
      'Xabarlar',
      'Boshqa',
    ],
    StaffRole.auditor => const [
      'Audit',
      'Signallar',
      'Holatlar',
      'Ogohlant.',
      'Boshqa',
    ],
  };
  return [
    _Destination(
      labels[0],
      Icons.home_outlined,
      Icons.home_rounded,
      '${labels[0]} sahifasi',
    ),
    _Destination(
      labels[1],
      role == StaffRole.auditor
          ? Icons.monitor_heart_outlined
          : Icons.dashboard_customize_outlined,
      role == StaffRole.auditor
          ? Icons.monitor_heart_rounded
          : Icons.dashboard_customize_rounded,
      '${labels[1]} ish maydoni',
    ),
    _Destination(
      labels[2],
      role == StaffRole.auditor
          ? Icons.inventory_2_outlined
          : Icons.task_alt_outlined,
      role == StaffRole.auditor
          ? Icons.inventory_2_rounded
          : Icons.task_alt_rounded,
      labels[2],
    ),
    _Destination(
      labels[3],
      role == StaffRole.auditor
          ? Icons.notifications_outlined
          : Icons.chat_bubble_outline,
      role == StaffRole.auditor
          ? Icons.notifications_rounded
          : Icons.chat_bubble_rounded,
      labels[3],
    ),
    _Destination(
      labels[4],
      Icons.grid_view_outlined,
      Icons.grid_view_rounded,
      'Boshqa imkoniyatlar',
    ),
  ];
}
