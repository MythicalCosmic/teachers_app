import 'package:flutter/material.dart';

import '../data/models.dart';
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
    final sf = SfTheme.of(context);
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
              child: ColoredBox(color: Colors.transparent, child: body),
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

    final decoration = bodyColor != null
        ? BoxDecoration(color: bodyColor)
        : switch (sf.visualStyle) {
            AppVisualStyle.classic => BoxDecoration(color: c.bg),
            AppVisualStyle.glassmorphism => BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.bg,
                  c.primarySoft.withValues(alpha: sf.dark ? 0.32 : 0.54),
                  c.accentSoft.withValues(alpha: sf.dark ? 0.18 : 0.38),
                ],
              ),
            ),
            AppVisualStyle.liquidGlass => BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.72, -0.86),
                radius: 1.45,
                colors: [
                  c.primarySoft.withValues(alpha: sf.dark ? 0.42 : 0.72),
                  c.bg,
                  c.accentSoft.withValues(alpha: sf.dark ? 0.16 : 0.30),
                ],
              ),
            ),
            AppVisualStyle.claymorphism => BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.surface2, c.bg, c.surface3.withValues(alpha: .62)],
              ),
            ),
            AppVisualStyle.maximalism => BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.primarySoft,
                  c.bg,
                  c.accentSoft.withValues(alpha: .92),
                ],
                stops: const [0, .48, 1],
              ),
            ),
          };

    Widget decoratedContent = DecoratedBox(
      decoration: decoration,
      child: content,
    );
    if (bodyColor == null && sf.visualStyle == AppVisualStyle.maximalism) {
      decoratedContent = Stack(
        children: [
          Positioned.fill(child: DecoratedBox(decoration: decoration)),
          Positioned(
            right: -70,
            top: 80,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.ink.withValues(alpha: .08),
                    width: 28,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bodyColor ?? c.bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      body: decoratedContent,
    );
  }
}
