import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';

class SfAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const SfAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.color,
  });

  static const _palette = <Color>[
    Color(0xFFB85535),
    Color(0xFFD89A2E),
    Color(0xFF4F7B3B),
    Color(0xFF2A6F9F),
    Color(0xFF7A4A82),
    Color(0xFFA55A24),
    Color(0xFF3F6E5C),
  ];

  Color get _stableColor {
    if (color != null) return color!;
    final hash = name.runes.fold<int>(0, (a, c) => a + c) % _palette.length;
    return _palette[hash];
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _stableColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: SfType.ui(
          size: size * 0.4,
          weight: FontWeight.w700,
          color: const Color(0xFFFFFCF5),
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
