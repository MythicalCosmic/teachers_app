import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';

/// A consistent, accessible search control for StarForge list surfaces.
///
/// The field owns a controller and focus node when callers do not provide one,
/// keeps its clear action in sync with programmatic controller changes, and
/// exposes a visible focus treatment across every visual theme.
class SfSearchField extends StatefulWidget {
  const SfSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.semanticLabel,
    this.clearTooltip = 'Clear search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
    this.clearButtonKey,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final String clearTooltip;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;
  final Key? clearButtonKey;

  @override
  State<SfSearchField> createState() => _SfSearchFieldState();
}

class _SfSearchFieldState extends State<SfSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _ownsController;
  late bool _ownsFocusNode;

  bool get _focused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(SfSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController(widget.controller);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  void _attachController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
    _controller.addListener(_handleControllerChanged);
  }

  void _detachController() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
  }

  void _attachFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    if (_controller.text.isEmpty) return;
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _detachController();
    _detachFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final motion = SfTheme.of(
      context,
    ).duration(const Duration(milliseconds: 160));
    final fill = _focused
        ? Color.alphaBlend(c.primary.withValues(alpha: 0.07), c.surface2)
        : c.surface2;
    final radius = BorderRadius.circular(16);
    final label = widget.semanticLabel ?? widget.hintText;

    return Semantics(
      container: true,
      textField: true,
      enabled: widget.enabled,
      label: label,
      child: AnimatedContainer(
        duration: motion,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onTapOutside: (_) => _focusNode.unfocus(),
          cursorColor: c.primary,
          style: SfType.ui(size: 14, weight: FontWeight.w600, color: c.ink),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: SfType.ui(size: 13.5, color: c.muted),
            prefixIcon: ExcludeSemantics(
              child: Icon(Icons.search_rounded, size: 20, color: c.muted),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    key: widget.clearButtonKey,
                    tooltip: widget.clearTooltip,
                    onPressed: widget.enabled ? _clear : null,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: c.muted,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            filled: true,
            fillColor: widget.enabled ? fill : c.surface2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.primary, width: 1.8),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}
