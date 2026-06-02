import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';

class GradebookScreen extends StatelessWidget {
  const GradebookScreen({super.key});

  static const _exams = ['M1', 'M2', 'M3', 'YI', 'M4', 'M5', 'M6', 'F'];
  static const _students = <_Stu>[
    _Stu('Akbarov A.', 4.8, [5, 5, 4, 5, 5, 4, 5, 5]),
    _Stu('Azizova M.', 4.6, [5, 4, 5, 5, 4, 5, 4, 5]),
    _Stu('Bakirov S.', 3.8, [4, 3, 4, 4, 3, 4, 4, 4]),
    _Stu('Davronova S.', 4.2, [4, 5, 4, 4, 4, 4, 5, 4]),
    _Stu('Eshmatov O.', 3.1, [3, 2, 3, 3, 0, 4, 3, 3]),
    _Stu('Fayzullayev D.', 4.4, [4, 5, 4, 5, 4, 4, 5, 4]),
    _Stu('G‘aniyev J.', 3.9, [4, 4, 3, 4, 4, 4, 4, 4]),
    _Stu('Halimova Z.', 4.7, [5, 5, 5, 4, 5, 5, 4, 5]),
    _Stu('Ibragimov S.', 4.0, [4, 4, 4, 4, 4, 4, 4, 4]),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Column(
        children: [
          SfNavBar(
            title: 'Baholar',
            subtitle: 'II chorak · Algebra',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [Icon(SfIcons.arrowL, size: 18), SizedBox(width: 2), Text('9-B')],
              ),
            ),
            actions: const [Icon(SfIcons.upload), SizedBox(width: 12), Icon(SfIcons.more)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                for (final entry in ['I', 'II', 'III', 'IV'].asMap().entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.key == 1 ? c.ink : Colors.transparent,
                          border: entry.key == 1 ? null : Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${entry.value} chorak',
                            style: SfType.ui(
                                size: 12,
                                weight: FontWeight.w700,
                                color: entry.key == 1 ? c.bg : c.muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                SizedBox(
                    width: 100,
                    child: Text('O‘QUVCHI', style: SfType.eyebrow(color: c.muted, size: 10))),
                for (final e in _exams)
                  Expanded(
                      child: Text(e,
                          textAlign: TextAlign.center,
                          style: SfType.eyebrow(color: c.muted, size: 10))),
                SizedBox(
                    width: 38,
                    child: Text('O‘RT',
                        textAlign: TextAlign.center,
                        style: SfType.eyebrow(color: c.ink2, size: 10))),
              ],
            ),
          ),
          for (int i = 0; i < _students.length; i++)
            Container(
              color: i.isOdd ? Colors.transparent : c.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(_students[i].n,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(size: 12, weight: FontWeight.w600, color: c.ink)),
                  ),
                  for (final g in _students[i].grades)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: _cellColor(g, c).$1,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(g == 0 ? '·' : '$g',
                              style: SfType.mono(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _cellColor(g, c).$2)),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 38,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                          color: c.ink, borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text('${_students[i].avg}',
                          style: SfType.mono(
                              size: 12, weight: FontWeight.w700, color: c.bg)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SfAiSurface(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SfAiBadge(label: 'Tahlil'),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Eshmatov Otabek',
                        style: SfType.ui(
                            size: 13, weight: FontWeight.w700, color: c.ink2, height: 1.4)),
                    TextSpan(
                        text:
                            'ning 4-yarim-yillik imtihonida baho yo‘q. Davomati ham 72%. Yo‘qlama sababli bo‘lishi mumkin.',
                        style: SfType.ui(size: 13, color: c.ink2, height: 1.4)),
                  ])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _cellColor(int g, dynamic c) {
    if (g == 0) return (c.surface3, c.muted);
    if (g == 5) return (c.successSoft, c.success);
    if (g == 4) return (c.accentSoft, c.accentInk);
    if (g == 3) return (c.warnSoft, c.warn);
    return (c.dangerSoft, c.danger);
  }
}

class _Stu {
  final String n;
  final double avg;
  final List<int> grades;
  const _Stu(this.n, this.avg, this.grades);
}
