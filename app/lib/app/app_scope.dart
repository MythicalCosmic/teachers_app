import 'package:flutter/widgets.dart';

import 'app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child})
    : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context.');
    return scope!.notifier!;
  }

  static AppState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
}
