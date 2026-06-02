import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';

/// Large title app bar matching the iOS-style large header used everywhere.
class SfLargeAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  const SfLargeAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (leading != null) leading!,
                const Spacer(),
                for (final a in actions) Padding(padding: const EdgeInsets.only(left: 8), child: a),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: SfType.ui(
              size: 28,
              weight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -0.84,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: SfType.ui(size: 13, color: c.muted, weight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact iOS-style nav bar — used as a sub-screen header.
class SfNavBar extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading; // typically the back chevron + label
  final List<Widget> actions;

  const SfNavBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 12, 8),
      decoration: BoxDecoration(color: c.surface),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: subtitle != null ? 56 : 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (title != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title!,
                      style: SfType.ui(
                        size: 17,
                        weight: FontWeight.w700,
                        color: c.ink,
                        letterSpacing: -0.17,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: SfType.ui(size: 11, color: c.muted),
                      ),
                  ],
                ),
              Row(
                children: [
                  if (leading != null)
                    DefaultTextStyle(
                      style: SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary),
                      child: IconTheme(
                        data: IconThemeData(color: c.primary, size: 18),
                        child: leading!,
                      ),
                    ),
                  const Spacer(),
                  for (final a in actions)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: IconTheme(
                        data: IconThemeData(color: c.primary, size: 22),
                        child: a,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
