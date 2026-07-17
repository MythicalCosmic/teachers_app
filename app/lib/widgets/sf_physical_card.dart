import 'package:flutter/material.dart';
import '../theme/sf_theme.dart';
import 'sf_star.dart';

enum SfCardKind { up, down }

enum SfCardSize { sm, md, lg }

/// Physical "Up Card" / "Down Card" — the central artefact of the cards system.
/// Card type names (`Yulduz karta`, `Ogohlantirish`) are configurable by center
/// admins, so we accept [typeName].
class SfPhysicalCard extends StatelessWidget {
  final SfCardKind kind;
  final SfCardSize size;
  final String recipient;
  final String? reason;
  final String issuer;
  final String when;
  final String? typeName;

  const SfPhysicalCard({
    super.key,
    required this.kind,
    this.size = SfCardSize.md,
    required this.recipient,
    this.reason,
    required this.issuer,
    required this.when,
    this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        typeName ?? (kind == SfCardKind.up ? 'Yulduz karta' : 'Ogohlantirish');
    final scale = switch (size) {
      SfCardSize.sm => 0.62,
      SfCardSize.md => 0.82,
      SfCardSize.lg => 1.0,
    };
    final isUp = kind == SfCardKind.up;
    final palette = isUp
        ? _Pal(
            stops: const [Color(0xFFF6E0AC), Color(0xFFE9C272)],
            border: const Color(0xFFC49A3A),
            accent: const Color(0xFF7A4F0E),
            ink: const Color(0xFF3A2406),
          )
        : _Pal(
            stops: const [Color(0xFFF0C9BE), Color(0xFFD88A75)],
            border: const Color(0xFFA14026),
            accent: const Color(0xFF5C1A0C),
            ink: const Color(0xFF2D0F08),
          );

    final w = 240 * scale;
    final h = 320 * scale;
    final radius = BorderRadius.circular(14 * scale);
    final pad = 14 * scale;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.stops,
        ),
        border: Border.all(color: palette.border),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0x2D361E0E),
            blurRadius: 20 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Decorative stars
            Positioned(
              right: -30 * scale,
              top: -30 * scale,
              child: Opacity(
                opacity: 0.18,
                child: SfStar(size: 140 * scale, color: palette.accent),
              ),
            ),
            Positioned(
              right: -20 * scale,
              bottom: -20 * scale,
              child: Opacity(
                opacity: 0.08,
                child: SfStar(size: 100 * scale, color: palette.accent),
              ),
            ),
            // Top inner highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 1, color: const Color(0x73FFFFFF)),
            ),
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUp ? '↑ UP CARD' : '↓ DOWN CARD',
                        style: SfType.ui(
                          size: 9 * scale,
                          weight: FontWeight.w700,
                          color: palette.accent,
                          letterSpacing: 0.16 * (9 * scale),
                        ),
                      ),
                      SfStar(size: 18 * scale, color: palette.accent),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    name,
                    style: SfType.display(
                      size: 22 * scale,
                      color: palette.ink,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 4 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x99FFFCF5),
                      borderRadius: BorderRadius.circular(6 * scale),
                    ),
                    child: Text(
                      recipient,
                      style: SfType.ui(
                        size: 10 * scale,
                        weight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (reason != null)
                    Container(
                      padding: EdgeInsets.only(left: 8 * scale),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: palette.accent, width: 2),
                        ),
                      ),
                      child: Text(
                        '"$reason"',
                        style: SfType.display(
                          size: 11 * scale,
                          color: palette.ink.withValues(alpha: 0.85),
                          style: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  SizedBox(height: 10 * scale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        issuer,
                        style: SfType.mono(
                          size: 9 * scale,
                          color: palette.accent,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        when,
                        style: SfType.mono(
                          size: 9 * scale,
                          color: palette.accent,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pal {
  final List<Color> stops;
  final Color border;
  final Color accent;
  final Color ink;
  _Pal({
    required this.stops,
    required this.border,
    required this.accent,
    required this.ink,
  });
}
