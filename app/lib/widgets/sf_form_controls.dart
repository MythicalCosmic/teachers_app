import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import '../theme/tokens.dart';

/// A real, accessible form field that keeps the visual language of the design
/// prototype while delegating focus, keyboard, autofill and validation to
/// Flutter's native text-field implementation.
class SfTextField extends StatelessWidget {
  const SfTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int minLines;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      cursorColor: c.primary,
      style: SfType.ui(size: 15, color: c.ink, weight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 19),
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled ? c.surface : c.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: SfType.ui(size: 13, color: c.muted),
        hintStyle: SfType.ui(size: 14, color: c.muted),
        helperStyle: SfType.ui(size: 11, color: c.muted),
        errorStyle: SfType.ui(
          size: 11,
          color: c.danger,
          weight: FontWeight.w600,
        ),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: SfRadius.mdAll,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SfRadius.mdAll,
          borderSide: BorderSide(color: c.primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SfRadius.mdAll,
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SfRadius.mdAll,
          borderSide: BorderSide(color: c.danger, width: 1.7),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: SfRadius.mdAll,
          borderSide: BorderSide(color: c.border.withValues(alpha: 0.7)),
        ),
      ),
    );
    return semanticLabel == null
        ? field
        : Semantics(textField: true, label: semanticLabel, child: field);
  }
}

class SfSwitch extends StatelessWidget {
  const SfSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final control = Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: c.primary,
      activeThumbColor: const Color(0xFFFFFCF5),
      inactiveTrackColor: c.surface3,
      inactiveThumbColor: c.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: control,
    );
  }
}

class SfSwitchTile extends StatelessWidget {
  const SfSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      button: true,
      toggled: value,
      label: title,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: c.border))
                : null,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                Icon(leading, size: 19, color: c.ink2),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SfType.ui(size: 13.5, color: c.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: SfType.ui(size: 11, color: c.muted, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              SfSwitch(
                value: value,
                onChanged: onChanged,
                semanticLabel: title,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SfSegment<T> {
  const SfSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class SfSegmentedControl<T> extends StatelessWidget {
  const SfSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expanded = false,
  });

  final List<SfSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final children = segments
        .map((segment) {
          final selected = segment.value == value;
          final item = Semantics(
            button: true,
            selected: selected,
            label: segment.label,
            child: InkWell(
              onTap: () => onChanged(segment.value),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minHeight: 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? c.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(
                        segment.icon,
                        size: 16,
                        color: selected ? c.bg : c.muted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        segment.label,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(
                          size: 12,
                          weight: FontWeight.w700,
                          color: selected ? c.bg : c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return expanded ? Expanded(child: item) : item;
        })
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: children,
      ),
    );
  }
}
