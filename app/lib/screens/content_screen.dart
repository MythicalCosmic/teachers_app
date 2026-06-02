import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final folders = [
      ('Algebra · Daraja II', 24, c.primary),
      ('Geometriya', 18, c.accent),
      ('Olimpiada to‘plami', 42, c.ink2),
    ];
    final files = [
      ('Kvadrat tenglama · 03', SfIcons.pdf, '2.1 MB · 8 bet', c.danger, 'AI xulosa tayyor'),
      ('Funksiyalar grafigi', SfIcons.video, '6:42 · MP4', c.accent, null),
      ('Diskriminant · slayd', SfIcons.doc, 'PPTX · 16 slayd', c.primary, null),
      ('Tenglamalar to‘plami', SfIcons.pdf, '880 KB · 12 bet', c.danger, null),
      ('Matematik induktsiya', SfIcons.doc, 'DOCX · 4 bet', c.primary, null),
    ];
    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Materiallar',
            subtitle: 'Kutubxona · 84 fayl',
            actions: const [Icon(SfIcons.search), SizedBox(width: 14), Icon(SfIcons.upload)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in ['Hammasi', 'PDF', 'Video', 'Slayd', 'Mening', 'Markaz']
                      .asMap()
                      .entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: e.key == 0 ? c.ink : Colors.transparent,
                          border: e.key == 0 ? null : Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(e.value,
                            style: SfType.ui(
                                size: 12,
                                weight: FontWeight.w600,
                                color: e.key == 0 ? c.bg : c.muted)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          Text('PAPKALAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in folders)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 160,
                      child: SfSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: f.$3, borderRadius: BorderRadius.circular(11)),
                              alignment: Alignment.center,
                              child:
                                  const Icon(SfIcons.folder, size: 20, color: Color(0xFFFFFCF5)),
                            ),
                            const SizedBox(height: 10),
                            Text(f.$1,
                                style: SfType.ui(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: c.ink,
                                    height: 1.2)),
                            const SizedBox(height: 2),
                            Text('${f.$2} fayl', style: SfType.ui(size: 10, color: c.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('SO‘NGGI FAYLLAR', style: SfType.eyebrow(color: c.muted)),
              const Spacer(),
              Text('Saralash', style: SfType.ui(size: 11, color: c.primary)),
            ],
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final f in files)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 44,
                          decoration: BoxDecoration(
                              color: f.$4, borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Icon(f.$2, size: 20, color: const Color(0xFFFFFCF5)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SfType.ui(
                                      size: 14, weight: FontWeight.w600, color: c.ink)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(f.$3, style: SfType.ui(size: 10.5, color: c.muted)),
                                  if (f.$5 != null) ...[
                                    const SizedBox(width: 6),
                                    const SfPill(tone: SfPillTone.ai, label: 'AI'),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(SfIcons.download, size: 18, color: c.ink2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.borderStrong, width: 1.5, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: c.primarySoft, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.upload, size: 22, color: c.primary),
                ),
                const SizedBox(height: 10),
                Text('Fayl yuklash',
                    style: SfType.ui(size: 14, weight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 2),
                Text('PDF, MP4, PPTX, DOCX · 200 MB gacha',
                    style: SfType.ui(size: 11, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
