import 'package:flutter/material.dart';
import 'sf_bottom_navigation.dart';
import 'sf_icons.dart';

enum SfTab { home, cohort, tasks, ai, print }

class SfTabBar extends StatelessWidget {
  final SfTab active;
  final ValueChanged<SfTab>? onChanged;
  final bool glassEnabled;
  final bool motionEnabled;
  final bool safeBottom;

  const SfTabBar({
    super.key,
    this.active = SfTab.home,
    this.onChanged,
    this.glassEnabled = true,
    this.motionEnabled = true,
    this.safeBottom = true,
  });

  static const _items = <_TabItem>[
    _TabItem(SfTab.home, 'Bugun', SfIcons.home),
    _TabItem(SfTab.cohort, 'Guruhlar', SfIcons.cohort),
    _TabItem(SfTab.tasks, 'Vazifa', SfIcons.check),
    _TabItem(SfTab.ai, 'AI', SfIcons.ai),
    _TabItem(SfTab.print, 'Print', SfIcons.printer),
  ];

  @override
  Widget build(BuildContext context) {
    return SfAdaptiveBottomNavigation(
      activeIndex: _items.indexWhere((item) => item.id == active),
      onDestinationSelected: onChanged == null
          ? null
          : (index) => onChanged!(_items[index].id),
      glassEnabled: glassEnabled,
      motionEnabled: motionEnabled,
      safeBottom: safeBottom,
      destinations: [
        for (final item in _items)
          SfBottomDestination(icon: Icon(item.icon), label: item.label),
      ],
    );
  }
}

class _TabItem {
  final SfTab id;
  final String label;
  final IconData icon;
  const _TabItem(this.id, this.label, this.icon);
}
