import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_physical_card.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_tab_bar.dart';
import '../router.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      tab: SfTab.home,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: _Header(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          _SurveyBanner(onTap: () => context.push('/surveys/form')),
          const SizedBox(height: 14),
          _NextLessonHero(onAttendance: () => context.push('/attendance')),
          const SizedBox(height: 16),
          _QuickStats(),
          const SizedBox(height: 16),
          _AiPanel(),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Bugungi jadval',
                style: SfType.ui(
                  size: 16,
                  weight: FontWeight.w700,
                  color: c.ink,
                  letterSpacing: -0.16,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/schedule'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hammasi',
                      style: SfType.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    Icon(SfIcons.chevR, size: 12, color: c.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ScheduleList(),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'So‘nggi kartalar',
                style: SfType.ui(
                  size: 16,
                  weight: FontWeight.w700,
                  color: c.ink,
                  letterSpacing: -0.16,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/cards'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '10 ta',
                      style: SfType.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    Icon(SfIcons.chevR, size: 12, color: c.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                SfPhysicalCard(
                  kind: SfCardKind.up,
                  recipient: 'Akbarov A.',
                  reason: 'Mustaqil yechim · 3-misol',
                  issuer: 'N. Karimova',
                  when: '09:42',
                  typeName: 'Yulduz karta',
                ),
                SizedBox(width: 10),
                SfPhysicalCard(
                  kind: SfCardKind.up,
                  recipient: 'Halimova Z.',
                  reason: 'Aktivlik · sinfdosh yordami',
                  issuer: 'N. Karimova',
                  when: '09:38',
                  typeName: 'Aktivlik',
                ),
                SizedBox(width: 10),
                SfPhysicalCard(
                  kind: SfCardKind.down,
                  recipient: 'Eshmatov O.',
                  reason: 'Uy ishi tayyor emas (2-marta)',
                  issuer: 'N. Karimova',
                  when: '09:12',
                  typeName: 'Ogohlantirish',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => context.push('/print'),
            child: SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          SfIcons.printer,
                          size: 22,
                          color: c.primary,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '2',
                            style: SfType.mono(
                              size: 10,
                              weight: FontWeight.w700,
                              color: const Color(0xFFFFFCF5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Print navbatim · 2 ta',
                          style: SfType.ui(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Kvadrat tenglamalar · ',
                                style: SfType.ui(size: 11, color: c.muted),
                              ),
                              TextSpan(
                                text: '64% tugadi',
                                style: SfType.ui(
                                  size: 11,
                                  color: c.success,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(SfIcons.chevR, size: 16, color: c.ink2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: const SfAvatar(name: 'Nigora Karimova', size: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seshanba · 19 May',
                  style: SfType.ui(size: 12, color: c.muted),
                ),
                Text(
                  'Bugun, Nigora opa',
                  style: SfType.ui(
                    size: 16,
                    weight: FontWeight.w700,
                    color: c.ink,
                    letterSpacing: -0.16,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.bell, size: 20, color: c.ink),
                ),
                Positioned(
                  top: 7,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface2, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(SfIcons.search, size: 20, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurveyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SurveyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCEFD0), Color(0xFFF6E0AC)],
          ),
          border: Border.all(color: c.accent, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.18,
                child: SfStar(size: 100, color: const Color(0xFF7A4F0E)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.danger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'So‘rovnoma · 2 kun 14 soat qoldi'.toUpperCase(),
                        style: SfType.eyebrow(color: c.danger, size: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Oylik o‘qituvchi qoniqishi',
                        style: SfType.ui(
                          size: 14,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12 savol · ~4 daq · 33% tugatildi',
                        style: SfType.ui(size: 11, color: c.ink2),
                      ),
                    ],
                  ),
                ),
                SfButton(
                  kind: SfButtonKind.ink,
                  label: 'Davom',
                  trailing: SfIcons.arrowR,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  onPressed: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextLessonHero extends StatelessWidget {
  final VoidCallback onAttendance;
  const _NextLessonHero({required this.onAttendance});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return GestureDetector(
      onTap: () => context.push('/lesson'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primary, c.primaryHover],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.18,
                child: const SfStar(size: 160, color: Color(0xFFFFFCF5)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keyingi dars · 14 daqiqa'.toUpperCase(),
                            style: SfType.ui(
                              size: 11,
                              weight: FontWeight.w600,
                              color: const Color(
                                0xFFFFFCF5,
                              ).withValues(alpha: 0.85),
                              letterSpacing: 0.14 * 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Algebra · Daraja II',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFFCF5),
                              letterSpacing: -0.48,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Guruh '),
                                TextSpan(
                                  text: '9-B',
                                  style: SfType.ui(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFFFFCF5),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' · 24 o‘quvchi · 304-xona',
                                ),
                              ],
                            ),
                            style: SfType.ui(
                              size: 14,
                              color: const Color(
                                0xFFFFFCF5,
                              ).withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '09:00',
                          style: SfType.mono(
                            size: 22,
                            weight: FontWeight.w600,
                            color: const Color(0xFFFFFCF5),
                          ),
                        ),
                        Text(
                          '– 09:45',
                          style: SfType.ui(
                            size: 11,
                            color: const Color(
                              0xFFFFFCF5,
                            ).withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SfButton(
                        kind: SfButtonKind.primary,
                        label: 'Davomat olish',
                        leading: SfIcons.check,
                        height: 42,
                        fontSize: 14,
                        overrideBg: const Color(0xFFFFFCF5),
                        overrideFg: c.primary,
                        onPressed: onAttendance,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: const Color(0x66FFFCF5)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        SfIcons.more,
                        size: 18,
                        color: Color(0xFFFFFCF5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final items = [
      ('4', '/ 5', 'Bugungi dars', c.ink, false),
      ('94', '%', 'Davomat', c.success, false),
      ('↑8 ↓2', 'bugun', 'Kartalar', c.accentInk, true),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Preserve the three-up rhythm on regular phones. Compact screens and
        // accessibility text get two columns so values never become cramped.
        final compact = constraints.maxWidth < 330 || textScale > 1.15;
        final columns = compact ? 2 : 3;
        const gap = 8.0;
        final cardWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in items)
              SizedBox(
                width: cardWidth,
                child: SfSurfaceCard(
                  padding: EdgeInsets.all(cardWidth < 104 ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 3,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            s.$1,
                            style: SfType.mono(
                              size: s.$5 ? 16 : 22,
                              weight: FontWeight.w700,
                              color: s.$4,
                              height: 1,
                            ),
                          ),
                          Text(
                            s.$2,
                            style: SfType.ui(
                              size: 10,
                              weight: FontWeight.w600,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.$3.toUpperCase(),
                        style: SfType.eyebrow(color: c.muted, size: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AiPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SfAiSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 280 || textScale > 1.15;
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  SfAiBadge(
                    label: compact ? null : 'Ko‘rib chiqing',
                    compact: compact,
                  ),
                  if (compact)
                    Text(
                      'KO‘RIB CHIQING',
                      style: SfType.eyebrow(color: c.ai, size: 10),
                    ),
                  Text('3 dona', style: SfType.ui(size: 11, color: c.muted)),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            '"Otabekka oxirgi haftada 2 ta Down karta berildi va davomati pasaymoqda. Ota bilan suhbat tavsiya etiladi."',
            style: SfType.display(size: 19, color: c.ink, height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SfButton(
                kind: SfButtonKind.ink,
                label: 'Tavsiyani ko‘rish',
                trailing: SfIcons.arrowR,
                fontSize: 13,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              SfButton(
                kind: SfButtonKind.ghost,
                label: 'Keyinroq',
                fontSize: 13,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final rows = [
      ('09:00', 'Algebra · 9-B', '304', 'now', '14m'),
      ('10:00', 'Algebra · 9-A', '304', 'next', ''),
      ('11:30', 'Geometriya · 10-V', '301', '', ''),
      ('14:00', 'Bo‘sh oraliq', 'Tushlik', 'gap', ''),
      ('15:00', 'Tayyorlov · 11-B', '210', '', ''),
    ];
    return SfSurfaceCard(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                color: rows[i].$4 == 'gap' ? c.surface2 : Colors.transparent,
                border: i < rows.length - 1
                    ? Border(bottom: BorderSide(color: c.border))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Opacity(
                opacity: rows[i].$4 == 'gap' ? 0.75 : 1,
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: Text(
                        rows[i].$1,
                        style: SfType.mono(
                          size: 13,
                          weight: FontWeight.w600,
                          color: c.ink2,
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rows[i].$4 == 'now'
                            ? c.primary
                            : rows[i].$4 == 'gap'
                            ? c.borderStrong
                            : c.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i].$2,
                            style: SfType.ui(
                              size: 14,
                              weight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            'Xona ${rows[i].$3}',
                            style: SfType.ui(size: 11.5, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    if (rows[i].$4 == 'now')
                      SfPill(
                        tone: SfPillTone.primary,
                        label: 'Hozir · ${rows[i].$5}',
                      ),
                    if (rows[i].$4 == 'next')
                      const SfPill(tone: SfPillTone.accent, label: 'Keyingi'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
