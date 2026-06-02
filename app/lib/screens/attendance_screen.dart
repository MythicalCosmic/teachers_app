import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  static const _students = <_Student>[
    _Student('Akbarov Akmal', 'DEMO-2026-00042', 'present', null),
    _Student('Azizova Madina', 'DEMO-2026-00043', 'present', null),
    _Student('Bakirov Sherzod', 'DEMO-2026-00044', 'late', '8 daq'),
    _Student('Davronova Sevinch', 'DEMO-2026-00045', 'present', null),
    _Student('Eshmatov Otabek', 'DEMO-2026-00046', 'absent', 'Kasal'),
    _Student('Fayzullayev Diyor', 'DEMO-2026-00047', 'present', null),
    _Student('G‘aniyev Jasur', 'DEMO-2026-00048', 'present', null),
    _Student('Halimova Zilola', 'DEMO-2026-00049', 'excused', 'Olimpiada'),
    _Student('Ibragimov Sardor', 'DEMO-2026-00050', 'present', null),
    _Student('Jo‘rayeva Nilufar', 'DEMO-2026-00051', 'present', null),
    _Student('Karimov Rustam', 'DEMO-2026-00052', null, null),
    _Student('Latipova Shahnoza', 'DEMO-2026-00053', null, null),
  ];

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: _Top(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Text('👈', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Maslahat: ',
                          style: SfType.ui(
                              size: 12, weight: FontWeight.w700, color: c.ink2, height: 1.35)),
                      TextSpan(
                          text:
                              'chapga suring — yo‘q · o‘ngga suring — bor · uzun bosing — sababli/kech.',
                          style: SfType.ui(size: 12, color: c.ink2, height: 1.35)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final s in _students) ...[
            _StudentRow(s),
            const SizedBox(height: 6),
          ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('10 / 12 belgilangan', style: SfType.mono(size: 11, color: c.muted)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 10 / 12,
                      minHeight: 4,
                      backgroundColor: c.surface3,
                      valueColor: AlwaysStoppedAnimation(c.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SfButton(
              kind: SfButtonKind.primary,
              label: 'Saqlash',
              trailing: SfIcons.arrowR,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Top extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
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
                  child: Row(
                    children: [
                      Icon(SfIcons.x, size: 18, color: c.primary),
                      const SizedBox(width: 4),
                      Text('Bekor',
                          style:
                              SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Text('9-B · Algebra', style: SfType.ui(size: 11, color: c.muted)),
                    Text('Davomat',
                        style: SfType.ui(
                            size: 15, weight: FontWeight.w700, color: c.ink, letterSpacing: -0.15)),
                  ],
                ),
                const Spacer(),
                Text('Saqlash',
                    style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.primary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                for (final s in [
                  (8, 'Bor', c.success),
                  (1, 'Yo‘q', c.danger),
                  (1, 'Kech', c.warn),
                  (1, 'Sababli', c.muted),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                            color: c.surface2, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text('${s.$1}',
                                style: SfType.mono(
                                    size: 22, weight: FontWeight.w700, color: s.$3, height: 1)),
                            const SizedBox(height: 2),
                            Text(s.$2.toUpperCase(),
                                style: SfType.eyebrow(color: c.muted, size: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Student {
  final String name;
  final String id;
  final String? state;
  final String? note;
  const _Student(this.name, this.id, this.state, this.note);
}

class _StudentRow extends StatelessWidget {
  final _Student s;
  const _StudentRow(this.s);

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    Color bg = c.surface;
    Color fg = c.ink;
    Color dot = c.muted;
    String? label;
    if (s.state != null) {
      switch (s.state) {
        case 'present':
          bg = c.successSoft;
          fg = c.success;
          dot = c.success;
          label = 'Bor';
          break;
        case 'absent':
          bg = c.dangerSoft;
          fg = c.danger;
          dot = c.danger;
          label = 'Yo‘q';
          break;
        case 'late':
          bg = c.warnSoft;
          fg = c.warn;
          dot = c.warn;
          label = 'Kechikdi';
          break;
        case 'excused':
          bg = c.surface3;
          fg = c.ink2;
          dot = c.muted;
          label = 'Sababli';
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: s.state == null ? c.border : Colors.transparent),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SfAvatar(name: s.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: SfType.ui(size: 14, weight: FontWeight.w600, color: c.ink)),
                Text.rich(TextSpan(children: [
                  TextSpan(text: s.id, style: SfType.mono(size: 10, color: c.muted)),
                  if (s.note != null)
                    TextSpan(
                        text: ' · ${s.note}',
                        style: SfType.mono(
                            size: 10, color: fg, weight: FontWeight.w600)),
                ])),
              ],
            ),
          ),
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration:
                  BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(label,
                      style: SfType.ui(size: 11, weight: FontWeight.w700, color: fg)),
                ],
              ),
            )
          else
            Row(
              children: [
                _OutlineAction(icon: SfIcons.check, color: c.success),
                const SizedBox(width: 6),
                _OutlineAction(icon: SfIcons.x, color: c.danger),
              ],
            ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _OutlineAction({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
