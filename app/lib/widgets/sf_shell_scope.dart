import 'package:flutter/widgets.dart';

/// Marks screens rendered inside the persistent role-aware application shell.
/// Legacy screens can keep their embedded tab declaration while [SfScaffold]
/// suppresses it when the shell already owns navigation.
class SfShellScope extends InheritedWidget {
  const SfShellScope({
    super.key,
    this.suppressEmbeddedNavigation = true,
    required super.child,
  });

  final bool suppressEmbeddedNavigation;

  static SfShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SfShellScope>();

  @override
  bool updateShouldNotify(SfShellScope oldWidget) =>
      suppressEmbeddedNavigation != oldWidget.suppressEmbeddedNavigation;
}
