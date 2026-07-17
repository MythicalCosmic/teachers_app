import 'package:flutter/material.dart';

/// The StarForge 8-point star mark.
class SfStar extends StatelessWidget {
  final double size;
  final Color color;
  final Color? centerDot; // when non-null, draws a small bg-colored dot

  const SfStar({
    super.key,
    this.size = 24,
    this.color = const Color(0xFF1F1B16),
    this.centerDot,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(color: color, centerDot: centerDot),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final Color? centerDot;
  _StarPainter({required this.color, this.centerDot});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 8-point star polygon (matches the CSS clip-path coords / 100 * size)
    final points = const [
      [50, 0],
      [61, 35],
      [98, 35],
      [68, 57],
      [79, 91],
      [50, 70],
      [21, 91],
      [32, 57],
      [2, 35],
      [39, 35],
    ];
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = p[0] / 100 * w;
      final y = p[1] / 100 * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);

    if (centerDot != null) {
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * 0.07,
        Paint()..color = centerDot!,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.centerDot != centerDot;
}
