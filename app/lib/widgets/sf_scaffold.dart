import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import 'sf_shell_scope.dart';
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
  final bool safeBottom;
  final bool resizeToAvoidBottomInset;
  final bool dismissKeyboardOnDrag;
  final bool dismissKeyboardOnTap;
  final bool extendBody;
  final Color? bottomSafeAreaColor;

  const SfScaffold({
    super.key,
    this.top,
    required this.body,
    this.bottom,
    this.tab,
    this.onTabChanged,
    this.bodyColor,
    this.safeTop = true,
    this.safeBottom = true,
    this.resizeToAvoidBottomInset = true,
    this.dismissKeyboardOnDrag = true,
    this.dismissKeyboardOnTap = false,
    this.extendBody = false,
    this.bottomSafeAreaColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final embeddedNavigationSuppressed =
        SfShellScope.maybeOf(context)?.suppressEmbeddedNavigation ?? false;
    Widget content = SafeArea(
      top: safeTop,
      bottom: false,
      child: Column(
        children: [
          ?top,
          Expanded(
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                if (dismissKeyboardOnDrag && notification.dragDetails != null) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
                return false;
              },
              child: Container(color: bodyColor ?? c.bg, child: body),
            ),
          ),
          if (bottom != null)
            if (tab == null && safeBottom)
              ColoredBox(
                color: bottomSafeAreaColor ?? c.surface,
                child: SafeArea(top: false, child: bottom!),
              )
            else
              bottom!,
          if (tab != null && !embeddedNavigationSuppressed)
            SfTabBar(
              active: tab!,
              onChanged: onTabChanged,
              safeBottom: safeBottom,
            ),
        ],
      ),
    );

    if (dismissKeyboardOnTap) {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: bodyColor ?? c.bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      body: content,
    );
  }
}
