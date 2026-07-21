import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/app_state.dart';
import '../../data/models.dart';
import '../../l10n/sf_l10n.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_bottom_navigation.dart';
import '../../widgets/sf_shell_scope.dart';

/// Persistent five-position navigation shared by every permitted staff role.
/// The destinations stay spatially stable while their labels and capabilities
/// adapt to the authenticated profile.
class StaffShellScreen extends StatefulWidget {
  const StaffShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<StaffShellScreen> createState() => _StaffShellScreenState();
}

class _StaffShellScreenState extends State<StaffShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pageMotion = AnimationController(
    vsync: this,
    value: 1,
  );
  double _direction = 1;

  @override
  void dispose() {
    _pageMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final role = app.session?.role ?? StaffRole.teacher;
        final destinations = _destinationsFor(
          context,
          role,
          canViewLeads: app.can(StaffCapability.viewLeads),
        );
        final motionEnabled = !app.settings.reducedMotion;
        _pageMotion.duration = SfTheme.of(
          context,
        ).duration(const Duration(milliseconds: 360));
        return PopScope(
          canPop: widget.navigationShell.currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && widget.navigationShell.currentIndex != 0) {
              _openBranch(0, motionEnabled: motionEnabled);
            }
          },
          child: Scaffold(
            backgroundColor: SfTheme.colorsOf(context).bg,
            resizeToAvoidBottomInset: true,
            body: AnimatedBuilder(
              animation: _pageMotion,
              child: SfShellScope(child: widget.navigationShell),
              builder: (context, child) {
                final value = Curves.easeOutCubic.transform(_pageMotion.value);
                return Opacity(
                  opacity: 0.68 + (0.32 * value),
                  child: Transform.translate(
                    offset: Offset(_direction * (1 - value) * 18, 0),
                    child: Transform.scale(
                      scale: 0.988 + (0.012 * value),
                      alignment: Alignment.center,
                      child: child,
                    ),
                  ),
                );
              },
            ),
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
              activeIndex: widget.navigationShell.currentIndex,
              glassEnabled: SfTheme.of(context).usesGlass,
              motionEnabled: motionEnabled,
              hapticsEnabled: app.settings.haptics,
              onDestinationSelected: (index) {
                _openBranch(index, motionEnabled: motionEnabled);
              },
            ),
          ),
        );
      },
    );
  }

  void _openBranch(int index, {required bool motionEnabled}) {
    final current = widget.navigationShell.currentIndex;
    if (index != current && motionEnabled) {
      _direction = index > current ? 1 : -1;
      _pageMotion.forward(from: 0);
    }
    widget.navigationShell.goBranch(index, initialLocation: index == current);
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
      label: _shellCopy(
        context,
        uz: '$count ta o‘qilmagan',
        ru: '$count непрочитанных',
        en: '$count unread',
      ),
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

List<_Destination> _destinationsFor(
  BuildContext context,
  StaffRole role, {
  required bool canViewLeads,
}) {
  final servicesLabel = _shellCopy(
    context,
    uz: 'Xizmatlar',
    ru: 'Сервисы',
    en: 'Services',
  );
  final servicesOnlyReception = role == StaffRole.reception && !canViewLeads;
  final labels = switch (role) {
    StaffRole.teacher => [
      context.tr('today'),
      context.tr('groups'),
      context.tr('tasks'),
      context.tr('messages'),
      context.tr('more'),
    ],
    StaffRole.assistant => [
      context.tr('today'),
      context.tr('groups'),
      context.tr('tasks'),
      context.tr('messages'),
      context.tr('more'),
    ],
    StaffRole.methodist => [
      context.tr('today'),
      context.tr('quality'),
      context.tr('tasks'),
      context.tr('messages'),
      context.tr('more'),
    ],
    StaffRole.reception => [
      context.tr('today'),
      canViewLeads ? context.tr('leads') : servicesLabel,
      canViewLeads ? context.tr('reception') : context.tr('tasks'),
      context.tr('messages'),
      context.tr('more'),
    ],
    StaffRole.auditor => [
      context.tr('audit'),
      context.tr('signals'),
      context.tr('cases'),
      context.tr('alerts'),
      context.tr('more'),
    ],
  };
  return [
    _Destination(
      labels[0],
      Icons.home_outlined,
      Icons.home_rounded,
      _shellCopy(
        context,
        uz: '${labels[0]} sahifasi',
        ru: 'Страница «${labels[0]}»',
        en: '${labels[0]} page',
      ),
    ),
    _Destination(
      labels[1],
      servicesOnlyReception
          ? Icons.grid_view_outlined
          : role == StaffRole.auditor
          ? Icons.monitor_heart_outlined
          : Icons.dashboard_customize_outlined,
      servicesOnlyReception
          ? Icons.grid_view_rounded
          : role == StaffRole.auditor
          ? Icons.monitor_heart_rounded
          : Icons.dashboard_customize_rounded,
      _shellCopy(
        context,
        uz: '${labels[1]} ish maydoni',
        ru: 'Раздел «${labels[1]}»',
        en: '${labels[1]} workspace',
      ),
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
      _shellCopy(
        context,
        uz: 'Boshqa imkoniyatlar',
        ru: 'Другие возможности',
        en: 'More options',
      ),
    ),
  ];
}

String _shellCopy(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (Localizations.localeOf(context).languageCode) {
  'ru' => ru,
  'en' => en,
  _ => uz,
};
