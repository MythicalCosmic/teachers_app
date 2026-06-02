import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final pending = [
      _S('Oylik o‘qituvchi qoniqishi', 'Karimova R. · Direktor', '22.05 · 23:59', '2 kun 14 soat',
          12, '~4 daqiqa', 33, true),
      _S('Karta tizimi · taklif va e‘tirozlar', 'Ahmedov B. · O‘quv ishlari',
          '26.05 · 18:00', '6 kun', 8, '~3 daqiqa', 0, false),
    ];
    final past = [
      ('Aprel · iss-prosess', 'Direktor', 'Topshirildi', '30.04', false),
      ('Yangi platforma qulayligi', 'Markaz', 'Topshirildi', '15.04', false),
      ('AI tavsiyalarining sifati', 'Metodist', 'O‘tkazib yuborilgan', '01.04', true),
    ];

    return SfScaffold(
      top: SfLargeAppBar(
        title: 'So‘rovnomalar',
        subtitle: 'Markaz tomonidan yuboriladi · anonim',
        actions: const [Icon(SfIcons.filter)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          Row(
            children: [
              Text('TOPSHIRISH KUTMOQDA', style: SfType.eyebrow(color: c.muted)),
              const Spacer(),
              Text('· 2 ta',
                  style: SfType.ui(
                      size: 11, color: c.danger, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          for (final s in pending) ...[
            GestureDetector(
              onTap: () => context.go('/surveys/form'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: s.urgent
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFCEFD0), Color(0xFFF6E0AC)],
                        )
                      : null,
                  color: s.urgent ? null : c.surface,
                  border: Border.all(
                      color: s.urgent ? c.accent : c.border,
                      width: s.urgent ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: s.urgent
                      ? [
                          BoxShadow(
                              color: c.accent.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8)),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    if (s.urgent)
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Opacity(
                            opacity: 0.18,
                            child: SfStar(size: 120, color: const Color(0xFF7A4F0E))),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (s.urgent) ...[
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: c.danger, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: s.urgent ? c.ink : c.surface2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(s.urgent ? '⏰ SHOSHILINCH' : 'YANGI',
                                  style: SfType.eyebrow(
                                      color: s.urgent ? c.bg : c.ink2)),
                            ),
                            const Spacer(),
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: s.remaining,
                                  style: SfType.mono(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: s.urgent ? c.danger : c.ink2)),
                              TextSpan(
                                  text: ' qoldi',
                                  style: SfType.ui(size: 11, color: c.muted)),
                            ])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(s.t,
                            style: SfType.ui(
                                size: 17,
                                weight: FontWeight.w700,
                                color: c.ink,
                                letterSpacing: -0.17,
                                height: 1.2)),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: '${s.issuer} · ', style: SfType.ui(size: 12, color: c.ink2)),
                          TextSpan(text: s.deadline, style: SfType.mono(size: 12, color: c.ink2)),
                        ])),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: const Color(0x99FFFCF5),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(TextSpan(children: [
                                      TextSpan(
                                          text: '${s.questions}',
                                          style: SfType.mono(
                                              size: 11,
                                              weight: FontWeight.w700,
                                              color: c.ink2)),
                                      TextSpan(
                                          text: ' savol · ${s.est}',
                                          style: SfType.mono(size: 11, color: c.ink2)),
                                    ])),
                                    if (s.progress > 0) ...[
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: s.progress / 100,
                                          minHeight: 4,
                                          backgroundColor: c.surface3,
                                          valueColor: AlwaysStoppedAnimation(c.accent),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SfButton(
                                kind: SfButtonKind.ink,
                                label: s.progress > 0 ? 'Davom etish' : 'Boshlash',
                                trailing: SfIcons.arrowR,
                                fontSize: 13,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text('TARIX', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final p in past)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.$5 ? c.surface2 : c.successSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            p.$5 ? SfIcons.x : SfIcons.check,
                            size: 18,
                            color: p.$5 ? c.muted : c.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.$1,
                                  style: SfType.ui(
                                      size: 13.5, weight: FontWeight.w600, color: c.ink)),
                              Text('${p.$2} · ${p.$3}',
                                  style: SfType.ui(size: 11, color: c.muted)),
                            ],
                          ),
                        ),
                        Text(p.$4, style: SfType.mono(size: 11, color: c.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SfAiSurface(
            borderRadius: BorderRadius.circular(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.aiBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.shield, size: 16, color: c.ai),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Anonimlik: ',
                        style: SfType.ui(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: c.ink2,
                            height: 1.4)),
                    TextSpan(
                        text:
                            'Sizning javoblaringiz markazda jamlanadi, lekin ismingiz ko‘rsatilmaydi. Profil ulashish sozlamasi orqali boshqarasiz.',
                        style: SfType.ui(size: 12.5, color: c.ink2, height: 1.4)),
                  ])),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _S {
  final String t;
  final String issuer;
  final String deadline;
  final String remaining;
  final int questions;
  final String est;
  final int progress;
  final bool urgent;
  _S(this.t, this.issuer, this.deadline, this.remaining, this.questions, this.est, this.progress,
      this.urgent);
}
