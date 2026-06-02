import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import 'sf_tab_bar.dart';

/// Page scaffold: optional top widget (app bar), body, optional bottom (action
/// bar / tab bar). Background = `c.bg` by default.
class SfScaffold extends StatelessWidget {
  final Widget? top;
  final Widget body;
  final Widget? bottom;
  final SfTab? tab;
  final ValueChanged<SfTab>? onTabChanged;
  final Color? bodyColor;
  final bool safeTop;

  const SfScaffold({
    super.key,
    this.top,
    required this.body,
    this.bottom,
    this.tab,
    this.onTabChanged,
    this.bodyColor,
    this.safeTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: bodyColor ?? c.bg,
      body: SafeArea(
        top: safeTop,
        bottom: false,
        child: Column(
          children: [
            if (top != null) top!,
            Expanded(
              child: Container(
                color: bodyColor ?? c.bg,
                child: body,
              ),
            ),
            if (bottom != null) bottom!,
            if (tab != null) SfTabBar(active: tab!, onChanged: onTabChanged),
          ],
        ),
      ),
    );
  }
}
