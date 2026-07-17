import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/sf_motion.dart';

/// The visual interaction state exposed by [SfPressable.builder].
@immutable
class SfPressableVisualState {
  final bool enabled;
  final bool pressed;
  final bool hovered;
  final bool focused;
  final bool? selected;

  const SfPressableVisualState({
    required this.enabled,
    required this.pressed,
    required this.hovered,
    required this.focused,
    this.selected,
  });
}

typedef SfPressableBuilder =
    Widget Function(
      BuildContext context,
      SfPressableVisualState state,
      Widget? child,
    );

/// A low-cost, accessible press primitive used by StarForge controls.
///
/// It provides an interruptible transform-based press animation, keyboard and
/// focus support, optional haptics, hover state, and correct disabled
/// semantics. It deliberately does not impose a Material splash so callers can
/// use it for glass, physical-card, and conventional button surfaces alike.
class SfPressable extends StatefulWidget {
  final Widget? child;
  final SfPressableBuilder? builder;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool haptic;
  final bool motionEnabled;
  final double pressedScale;
  final BorderRadiusGeometry borderRadius;
  final HitTestBehavior behavior;
  final String? semanticLabel;
  final String? tooltip;
  final bool? selected;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool showFocusRing;
  final Color? focusColor;
  final ValueChanged<bool>? onFocusChange;

  const SfPressable({
    super.key,
    this.child,
    this.builder,
    required this.onPressed,
    this.enabled = true,
    this.haptic = false,
    this.motionEnabled = true,
    this.pressedScale = 0.985,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
    this.tooltip,
    this.selected,
    this.focusNode,
    this.autofocus = false,
    this.showFocusRing = true,
    this.focusColor,
    this.onFocusChange,
  }) : assert(child != null || builder != null),
       assert(pressedScale > 0 && pressedScale <= 1);

  @override
  State<SfPressable> createState() => _SfPressableState();
}

class _SfPressableState extends State<SfPressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.enabled && widget.onPressed != null;

  @override
  void didUpdateWidget(SfPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && (_pressed || _hovered)) {
      _pressed = false;
      _hovered = false;
    }
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (!mounted || _focused == value) return;
    setState(() => _focused = value);
    widget.onFocusChange?.call(value);
  }

  void _activate() {
    if (!_enabled) return;
    if (widget.haptic) {
      HapticFeedback.selectionClick();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final duration = SfMotion.resolve(
      context,
      SfMotion.press,
      enabled: widget.motionEnabled,
    );
    final state = SfPressableVisualState(
      enabled: enabled,
      pressed: enabled && _pressed,
      hovered: enabled && _hovered,
      focused: enabled && _focused,
      selected: widget.selected,
    );
    final visual =
        widget.builder?.call(context, state, widget.child) ?? widget.child!;
    final radius = widget.borderRadius.resolve(Directionality.of(context));

    Widget result = Stack(
      clipBehavior: Clip.none,
      children: [
        visual,
        if (widget.showFocusRing && state.focused)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: duration,
                curve: SfMotion.enter,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color:
                        widget.focusColor ??
                        Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    result = AnimatedScale(
      scale: state.pressed ? widget.pressedScale : 1,
      duration: duration,
      curve: state.pressed ? SfMotion.exit : SfMotion.enter,
      child: result,
    );

    result = GestureDetector(
      behavior: widget.behavior,
      excludeFromSemantics: true,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled ? _activate : null,
      child: result,
    );

    result = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: _setHovered,
        onShowFocusHighlight: _setFocused,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: result,
      ),
    );

    result = Semantics(
      container: true,
      button: true,
      enabled: enabled,
      focusable: enabled,
      focused: enabled && _focused,
      label: widget.semanticLabel,
      selected: widget.selected,
      excludeSemantics: widget.semanticLabel != null,
      onTap: enabled ? _activate : null,
      child: result,
    );

    final tooltip = widget.tooltip;
    if (tooltip != null && tooltip.trim().isNotEmpty) {
      result = Tooltip(message: tooltip, child: result);
    }
    return result;
  }
}
