import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import 'sf_icons.dart';

enum SfTab { home, cohort, tasks, ai, print }

class SfTabBar extends StatelessWidget {
  final SfTab active;
  final ValueChanged<SfTab>? onChanged;

  const SfTabBar({super.key, this.active = SfTab.home, this.onChanged});

  static const _items = <_TabItem>[
    _TabItem(SfTab.home, 'Bugun', SfIcons.home),
    _TabItem(SfTab.cohort, 'Guruhlar', SfIcons.cohort),
    _TabItem(SfTab.tasks, 'Vazifa', SfIcons.check),
    _TabItem(SfTab.ai, 'AI', SfIcons.ai),
    _TabItem(SfTab.print, 'Print', SfIcons.printer),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final t in _items)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged?.call(t.id),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (t.id == active)
                            Container(
                              width: 38,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          Icon(t.icon, size: 22, color: t.id == active ? c.primary : c.muted),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.label,
                        style: SfType.ui(
                          size: 10.5,
                          weight: t.id == active ? FontWeight.w700 : FontWeight.w500,
                          color: t.id == active ? c.primary : c.muted,
                          letterSpacing: -0.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final SfTab id;
  final String label;
  final IconData icon;
  const _TabItem(this.id, this.label, this.icon);
}
