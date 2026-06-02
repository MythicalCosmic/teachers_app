import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class NewPrintJobScreen extends StatelessWidget {
  const NewPrintJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Bekor',
                        style: SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary)),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('2-bosqich · 3', style: SfType.ui(size: 11, color: c.muted)),
                      Text('Yangi chop etish',
                          style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Row(
              children: [
                for (int i = 1; i <= 3; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= 2 ? c.primary : c.surface2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          Text('MATERIAL MANBAI', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    border: Border.all(color: c.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(SfIcons.folder, size: 22, color: c.primary),
                          const SizedBox(height: 6),
                          Text('Kutubxonadan',
                              style: SfType.ui(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: c.primaryInk)),
                          const SizedBox(height: 4),
                          Text('84 fayl',
                              style: SfType.ui(
                                  size: 10.5,
                                  color: c.primaryInk.withValues(alpha: 0.7))),
                        ],
                      ),
                      Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(SfIcons.check, size: 16, color: c.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(SfIcons.upload, size: 22, color: c.muted),
                      const SizedBox(height: 6),
                      Text('Yuklash',
                          style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink)),
                      const SizedBox(height: 4),
                      Text('PDF · DOCX · JPG', style: SfType.ui(size: 10.5, color: c.muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                      color: c.danger, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: const Icon(SfIcons.pdf, size: 20, color: Color(0xFFFFFCF5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kvadrat tenglama · slayd',
                          style: SfType.ui(size: 13.5, weight: FontWeight.w700, color: c.ink)),
                      const SizedBox(height: 2),
                      Text('PDF · 2.1 MB · 8 bet',
                          style: SfType.mono(size: 10.5, color: c.muted)),
                    ],
                  ),
                ),
                Text('O‘zgartirish',
                    style:
                        SfType.ui(size: 11, color: c.primary, weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('KO‘RINISH · 8 BET', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 10),
          Container(
            height: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: c.surface2, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 5; i++) ...[
                  _PagePreview(focus: i == 2),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SfSurfaceCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NUSXA', style: SfType.eyebrow(color: c.muted, size: 10)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: c.surface2,
                                borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: const Text('−',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('24',
                                textAlign: TextAlign.center,
                                style: SfType.mono(
                                    size: 22, weight: FontWeight.w700, color: c.ink)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: c.primary, borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: const Text('+',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, color: Color(0xFFFFFCF5))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SfSurfaceCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FORMAT', style: SfType.eyebrow(color: c.muted, size: 10)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (final entry in ['A4', 'A5', 'A3'].asMap().entries)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: entry.key == 0 ? c.ink : Colors.transparent,
                                  border: entry.key == 0
                                      ? null
                                      : Border.all(color: c.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(entry.value,
                                    style: SfType.ui(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: entry.key == 0 ? c.bg : c.muted)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('QACHON TAYYOR BO‘LSIN', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final o in [
                  ('Hozir', '~3 daqiqada', false),
                  ('Bugun darsdan oldin', '08:45 ga', true),
                  ('Belgilangan vaqt', 'Tanlash', false),
                ])
                  Container(
                    decoration: BoxDecoration(
                      color: o.$3 ? c.primarySoft : Colors.transparent,
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: o.$3 ? c.primary : Colors.transparent,
                            border: Border.all(
                                color: o.$3 ? c.primary : c.borderStrong, width: 2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: o.$3
                              ? Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFFFFCF5),
                                      shape: BoxShape.circle))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(o.$1,
                              style: SfType.ui(
                                  size: 13.5,
                                  weight: o.$3 ? FontWeight.w700 : FontWeight.w500,
                                  color: c.ink)),
                        ),
                        Text(o.$2, style: SfType.ui(size: 12, color: c.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YAKUNIY',
                          style: SfType.eyebrow(
                              color: c.bg.withValues(alpha: 0.7))),
                      const SizedBox(height: 4),
                      Text('24 × 8 = 192 sahifa',
                          style: SfType.mono(
                              size: 18, weight: FontWeight.w700, color: c.bg)),
                      const SizedBox(height: 2),
                      Text('A4 · Qora-oq · 2 tomonlama · HP LaserJet',
                          style: SfType.ui(
                              size: 11, color: c.bg.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                SfStar(size: 36, color: c.accent),
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
            SizedBox(
              width: 80,
              child: SfButton(
                  kind: SfButtonKind.soft, label: 'Orqaga', onPressed: () => context.pop()),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SfButton(
                kind: SfButtonKind.primary,
                label: 'Navbatga qo‘shish',
                trailing: SfIcons.arrowR,
                onPressed: () => context.go('/print'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
  final bool focus;
  const _PagePreview({required this.focus});
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Transform.translate(
      offset: Offset(0, focus ? -4 : 0),
      child: Opacity(
        opacity: focus ? 1 : 0.7,
        child: Container(
          width: focus ? 120 : 76,
          height: focus ? 168 : 110,
          padding: EdgeInsets.all(focus ? 10 : 6),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(focus ? 8 : 6),
            boxShadow: focus
                ? const [BoxShadow(color: Color(0x2D361E0E), blurRadius: 32, offset: Offset(0, 12))]
                : const [BoxShadow(color: Color(0x10361E0E), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: focus ? 6 : 4,
                  width: 90,
                  decoration: BoxDecoration(
                      color: c.primary, borderRadius: BorderRadius.circular(2))),
              SizedBox(height: focus ? 8 : 5),
              Container(height: focus ? 3 : 2, color: c.borderStrong),
              const SizedBox(height: 3),
              Container(height: focus ? 3 : 2, width: 60, color: c.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}
