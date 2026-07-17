import 'package:flutter/material.dart';

/// StarForge EDU design tokens.
/// Warm editorial modern, Central Asian geometric undertone.
/// Mirrors the `--sf-*` CSS variables in `tokens.css`.

enum SfPalette { saroy, marvarid, samarqand, daryo }

class SfColors {
  // Base surface family
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color muted2;
  final Color border;
  final Color borderStrong;

  // Primary / accent
  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color primaryInk;

  final Color accent;
  final Color accentSoft;
  final Color accentInk;

  // Semantic
  final Color success;
  final Color successSoft;
  final Color warn;
  final Color warnSoft;
  final Color danger;
  final Color dangerSoft;

  // AI surface
  final Color ai;
  final List<Color> aiBg; // gradient stops
  final Color aiBorder;

  const SfColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.muted2,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.primaryInk,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.success,
    required this.successSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
    required this.ai,
    required this.aiBg,
    required this.aiBorder,
  });

  LinearGradient get aiGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: aiBg,
  );
}

// ───────────── PALETTE: SAROY (terracotta) ─────────────
const _saroyLight = SfColors(
  bg: Color(0xFFFBF6EC),
  surface: Color(0xFFFFFCF5),
  surface2: Color(0xFFF4EBD8),
  surface3: Color(0xFFEADFC4),
  ink: Color(0xFF1F1B16),
  ink2: Color(0xFF3A332A),
  muted: Color(0xFF847663),
  muted2: Color(0xFFB0A38B),
  border: Color(0xFFE5D9BE),
  borderStrong: Color(0xFFCFC0A0),
  primary: Color(0xFFB85535),
  primaryHover: Color(0xFFA04524),
  primarySoft: Color(0xFFF3D9CC),
  primaryInk: Color(0xFF5A2412),
  accent: Color(0xFFD89A2E),
  accentSoft: Color(0xFFF6E4B8),
  accentInk: Color(0xFF6B4810),
  success: Color(0xFF4F7B3B),
  successSoft: Color(0xFFDDEACA),
  warn: Color(0xFFC68423),
  warnSoft: Color(0xFFF6E4B8),
  danger: Color(0xFFB33A2A),
  dangerSoft: Color(0xFFF3D2CC),
  ai: Color(0xFF8B5A0F),
  aiBg: [Color(0xFFF9EAC4), Color(0xFFF6DCB0)],
  aiBorder: Color(0xFFE2BC72),
);

// ───────────── PALETTE: MARVARID (Pearl) ─────────────
const _marvaridLight = SfColors(
  bg: Color(0xFFF2F1ED),
  surface: Color(0xFFFBFAF6),
  surface2: Color(0xFFE8E5DC),
  surface3: Color(0xFFDDD9CD),
  ink: Color(0xFF1A1F22),
  ink2: Color(0xFF2F363B),
  muted: Color(0xFF6C7479),
  muted2: Color(0xFFA0A6AA),
  border: Color(0xFFDDDAD0),
  borderStrong: Color(0xFFBFBBA8),
  primary: Color(0xFF1F6B66),
  primaryHover: Color(0xFF155A56),
  primarySoft: Color(0xFFCFE3DF),
  primaryInk: Color(0xFF0B2E2C),
  accent: Color(0xFFC4892F),
  accentSoft: Color(0xFFF2E2BD),
  accentInk: Color(0xFF5C3E0F),
  success: Color(0xFF4F7B3B),
  successSoft: Color(0xFFDDEACA),
  warn: Color(0xFFC68423),
  warnSoft: Color(0xFFF2E2BD),
  danger: Color(0xFFB33A2A),
  dangerSoft: Color(0xFFF3D2CC),
  ai: Color(0xFF1F4A5B),
  aiBg: [Color(0xFFDCEAEE), Color(0xFFC7DDE3)],
  aiBorder: Color(0xFF8FB6BF),
);

// ───────────── PALETTE: SAMARQAND (Indigo) ─────────────
const _samarqandLight = SfColors(
  bg: Color(0xFFF4F1E8),
  surface: Color(0xFFFCFAF2),
  surface2: Color(0xFFECE6D3),
  surface3: Color(0xFFDED5BB),
  ink: Color(0xFF15182A),
  ink2: Color(0xFF262A40),
  muted: Color(0xFF6C6E7A),
  muted2: Color(0xFFA0A1AB),
  border: Color(0xFFDCD4BA),
  borderStrong: Color(0xFFBFB596),
  primary: Color(0xFF2A3D8F),
  primaryHover: Color(0xFF1F2F73),
  primarySoft: Color(0xFFD2D8EE),
  primaryInk: Color(0xFF121A45),
  accent: Color(0xFFD8A22A),
  accentSoft: Color(0xFFF4E1AA),
  accentInk: Color(0xFF5E4108),
  success: Color(0xFF4F7B3B),
  successSoft: Color(0xFFDDEACA),
  warn: Color(0xFFC68423),
  warnSoft: Color(0xFFF4E1AA),
  danger: Color(0xFFB33A2A),
  dangerSoft: Color(0xFFF3D2CC),
  ai: Color(0xFF3D2A8F),
  aiBg: [Color(0xFFE5DDF4), Color(0xFFD2C6EE)],
  aiBorder: Color(0xFFA793D6),
);

// ───────────── PALETTE: DARYO (Sage) — default ─────────────
const _daryoLight = SfColors(
  bg: Color(0xFFF1EFE6),
  surface: Color(0xFFFAF8EF),
  surface2: Color(0xFFE5E4D2),
  surface3: Color(0xFFD7D5BD),
  ink: Color(0xFF1A1E18),
  ink2: Color(0xFF2F352A),
  muted: Color(0xFF6F7264),
  muted2: Color(0xFFA2A593),
  border: Color(0xFFD9D6BD),
  borderStrong: Color(0xFFB7B399),
  primary: Color(0xFF4F6A3A),
  primaryHover: Color(0xFF3E5A29),
  primarySoft: Color(0xFFDBE5C7),
  primaryInk: Color(0xFF1F2C13),
  accent: Color(0xFFBA8C2C),
  accentSoft: Color(0xFFECDBA8),
  accentInk: Color(0xFF563E08),
  success: Color(0xFF4F7B3B),
  successSoft: Color(0xFFDDEACA),
  warn: Color(0xFFC68423),
  warnSoft: Color(0xFFECDBA8),
  danger: Color(0xFFB33A2A),
  dangerSoft: Color(0xFFF3D2CC),
  ai: Color(0xFF6A5128),
  aiBg: [Color(0xFFEDE2C2), Color(0xFFDECBA0)],
  aiBorder: Color(0xFFB49A5E),
);

// Dark base — applied to any palette
const _darkBase = SfColors(
  bg: Color(0xFF14110D),
  surface: Color(0xFF1D1914),
  surface2: Color(0xFF28231C),
  surface3: Color(0xFF332D24),
  ink: Color(0xFFF2EADA),
  ink2: Color(0xFFD8CFBC),
  muted: Color(0xFF9E927E),
  muted2: Color(0xFF6E6555),
  border: Color(0xFF3A3329),
  borderStrong: Color(0xFF4E4435),
  primary: Color(0xFFE58B6A),
  primaryHover: Color(0xFFED9C7F),
  primarySoft: Color(0xFF3A2418),
  primaryInk: Color(0xFFFCDCCA),
  accent: Color(0xFFEBBE5E),
  accentSoft: Color(0xFF3D2F12),
  accentInk: Color(0xFFFCE3A4),
  success: Color(0xFF7AAE5E),
  successSoft: Color(0xFF1F2E16),
  warn: Color(0xFFE5B05E),
  warnSoft: Color(0xFF3D2F12),
  danger: Color(0xFFE07A6A),
  dangerSoft: Color(0xFF3A1B14),
  ai: Color(0xFFF0CB7F),
  aiBg: [Color(0xFF2D241B), Color(0xFF3A2D1E)],
  aiBorder: Color(0xFF66502A),
);

SfColors sfColorsFor(SfPalette palette, {bool dark = false}) {
  if (!dark) {
    switch (palette) {
      case SfPalette.saroy:
        return _saroyLight;
      case SfPalette.marvarid:
        return _marvaridLight;
      case SfPalette.samarqand:
        return _samarqandLight;
      case SfPalette.daryo:
        return _daryoLight;
    }
  }
  // Dark variants override the primary trio per palette
  switch (palette) {
    case SfPalette.saroy:
      return _darkBase;
    case SfPalette.marvarid:
      return _darkBase.copyWith(
        primary: const Color(0xFF6FB6AE),
        primaryHover: const Color(0xFF84C7BF),
        primarySoft: const Color(0xFF18302E),
      );
    case SfPalette.samarqand:
      return _darkBase.copyWith(
        primary: const Color(0xFF8A9AE0),
        primaryHover: const Color(0xFF9DABE6),
        primarySoft: const Color(0xFF1A2147),
      );
    case SfPalette.daryo:
      return _darkBase.copyWith(
        primary: const Color(0xFF95B27A),
        primaryHover: const Color(0xFFA8C290),
        primarySoft: const Color(0xFF1E2A14),
      );
  }
}

extension SfColorsCopy on SfColors {
  SfColors copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primarySoft,
  }) => SfColors(
    bg: bg,
    surface: surface,
    surface2: surface2,
    surface3: surface3,
    ink: ink,
    ink2: ink2,
    muted: muted,
    muted2: muted2,
    border: border,
    borderStrong: borderStrong,
    primary: primary ?? this.primary,
    primaryHover: primaryHover ?? this.primaryHover,
    primarySoft: primarySoft ?? this.primarySoft,
    primaryInk: primaryInk,
    accent: accent,
    accentSoft: accentSoft,
    accentInk: accentInk,
    success: success,
    successSoft: successSoft,
    warn: warn,
    warnSoft: warnSoft,
    danger: danger,
    dangerSoft: dangerSoft,
    ai: ai,
    aiBg: aiBg,
    aiBorder: aiBorder,
  );
}

// Radii
class SfRadius {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(22);
  static const xl = Radius.circular(28);
  static const pill = Radius.circular(999);

  static final smAll = BorderRadius.all(sm);
  static final mdAll = BorderRadius.all(md);
  static final lgAll = BorderRadius.all(lg);
  static final xlAll = BorderRadius.all(xl);
  static final pillAll = BorderRadius.all(pill);
}

// Shadows
class SfShadows {
  static const sm = [
    BoxShadow(color: Color(0x0F361E0E), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: Color(0x14361E0E), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A361E0E), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x1F361E0E), blurRadius: 40, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x0F361E0E), blurRadius: 10, offset: Offset(0, 4)),
  ];
}
