import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_physical_card.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class GiveCardScreen extends StatelessWidget {
  const GiveCardScreen({super.key});

  static const _types = <_T>[
    _T('star', 'Yulduz karta', 'Asosiy musbat', true, true),
    _T('active', 'Aktivlik', 'Darsda ishtirok', true, false),
    _T('helper', 'Yordamchi', 'Sinfdosh yordami', true, false),
    _T('tidy', 'Toza ish', 'Daftar / vazifa', true, false),
    _T('warn', 'Ogohlantirish', 'Asosiy salbiy', false, false),
    _T('late', 'Mas‘uliyatsizlik', 'Uy ishi · kechikish', false, false),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Text('Bekor',
                    style: SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary)),
              ),
              const Spacer(),
              Text('Karta berish',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
              const Spacer(),
              Text('Saqlash',
                  style: SfType.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: c.primary.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          Text('QABUL QILUVCHI', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SfAvatar(name: 'Akbarov Akmal', size: 40, color: c.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Akbarov Akmal',
                          style: SfType.ui(size: 14, weight: FontWeight.w700, color: c.ink)),
                      Text('9-B Algebra · 14 yosh',
                          style: SfType.ui(size: 11, color: c.muted)),
                    ],
                  ),
                ),
                Text('O‘zgartirish',
                    style:
                        SfType.ui(size: 12, color: c.primary, weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('KARTA TURI', style: SfType.eyebrow(color: c.muted)),
              const Spacer(),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Markaz ', style: SfType.ui(size: 11, color: c.muted)),
                TextSpan(
                    text: 'v2.3',
                    style: SfType.mono(size: 11, color: c.ink2)),
              ])),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.3,
            children: [for (final t in _types) _TypeTile(t)],
          ),
          const SizedBox(height: 18),
          Text('SABAB · IXTIYORIY', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Mustaqil yechim · 3-misol',
                      style: SfType.ui(size: 14, color: c.ink, height: 1.5)),
                  TextSpan(
                      text: '|',
                      style: SfType.ui(size: 14, color: c.primary)),
                ])),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in const ['Aktivlik', 'Tezkor javob', 'Toza daftar', 'Yordam'])
                      SfPill(label: '+ $s'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SfAiSurface(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Sabab taklifi', compact: true),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Bugungi darsda Akmalning 3-mashqdagi yechimi ',
                      style: SfType.ui(size: 12.5, color: c.ink2, height: 1.4)),
                  TextSpan(
                      text: 'algebraik fikrlash',
                      style:
                          SfType.ui(size: 12.5, weight: FontWeight.w700, color: c.ink2)),
                  TextSpan(
                      text: ' kuchli ekanini ko‘rsatdi.',
                      style: SfType.ui(size: 12.5, color: c.ink2, height: 1.4)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('KO‘RINISH', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 10),
          const Center(
            child: SfPhysicalCard(
              kind: SfCardKind.up,
              size: SfCardSize.lg,
              recipient: 'Akbarov Akmal',
              reason: 'Mustaqil yechim · 3-misol',
              issuer: 'N. Karimova',
              when: '19.05 · 09:42',
              typeName: 'Yulduz karta',
            ),
          ),
          const SizedBox(height: 18),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final o in [
                  ('Ota-onaga xabar yuborish', true),
                  ('Chop etish (Print)', false),
                  ('Sinf chatida e‘lon qilish', false),
                ])
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(o.$1, style: SfType.ui(size: 13.5, color: c.ink)),
                        ),
                        _Toggle(value: o.$2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            SfButton(
              kind: SfButtonKind.ghost,
              child: const Icon(SfIcons.printer, size: 18),
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SfButton(
                kind: SfButtonKind.primary,
                label: 'Karta berish',
                height: 50,
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _T {
  final String id;
  final String n;
  final String s;
  final bool up;
  final bool active;
  const _T(this.id, this.n, this.s, this.up, this.active);
}

class _TypeTile extends StatelessWidget {
  final _T t;
  const _TypeTile(this.t);
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final on = t.active;
    final isUp = t.up;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: on
            ? (isUp ? const Color(0xFFF6E0AC) : const Color(0xFFF0C9BE))
            : c.surface,
        border: Border.all(
          color: on
              ? (isUp ? const Color(0xFFC49A3A) : const Color(0xFFA14026))
              : c.border,
          width: on ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 36,
                decoration: BoxDecoration(
                  color: isUp ? const Color(0xFFE9C272) : const Color(0xFFD88A75),
                  border: Border.all(
                      color: isUp ? const Color(0xFFA47B22) : const Color(0xFFA14026)),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: SfStar(
                    size: 14,
                    color: isUp ? const Color(0xFF5C3E08) : const Color(0xFF5C1A0C)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.n,
                        style: SfType.ui(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: on
                                ? (isUp
                                    ? const Color(0xFF5C3E08)
                                    : const Color(0xFF5C1A0C))
                                : c.ink,
                            height: 1.15)),
                    const SizedBox(height: 2),
                    Text(t.s,
                        style: SfType.ui(
                            size: 10,
                            color: on
                                ? (isUp
                                    ? const Color(0xFF7A4F0E)
                                    : const Color(0xFF9A4628))
                                : c.muted)),
                  ],
                ),
              ),
            ],
          ),
          if (on)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isUp ? const Color(0xFF7A4F0E) : const Color(0xFF5C1A0C),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(SfIcons.check, size: 12, color: Color(0xFFFFFCF5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  const _Toggle({required this.value});
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? c.primary : c.surface3,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFCF5),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}
