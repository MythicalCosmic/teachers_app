import 'package:flutter/material.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final groups = [
      ('Bugun', [
        _N('ai', 'AI', 'AI tavsiyasi',
            '9-B uchun ertangi darsda kvadrat tenglamalarni qisqa qaytarish tavsiya etiladi.',
            '08:42'),
        _N('primary', null, 'Davomat saqlandi', 'Algebra Mid · 21/22 belgilandi.', '10:05',
            icon: SfIcons.check),
        _N('success', null, 'Print tayyor',
            'Kvadrat tenglamalar · 24 nusxa · HP LaserJet · lobbi', '11:24',
            icon: SfIcons.printer),
        _N('accent', null, 'Ota-onadan xabar',
            'Akbarova D. (Akmal ona) sizga yozdi · 9-B', '11:14',
            icon: SfIcons.chat),
        _N('warn', null, 'Eshmatov Otabek · 3-Down karta',
            '9-B Algebra · ota-onaga avtomatik xabar yuborildi.', '11:42',
            icon: SfIcons.flag),
      ]),
      ('Kecha', [
        _N('success', null, 'Print tugadi',
            'Yulduz karta · 12 nusxa · A5 rangli · Xerox WC Pro', 'Du · 16:50',
            icon: SfIcons.printer),
        _N('ai', 'AI', 'Suhbat · 10-V',
            '"Trapetsiya mavzusi yaxshi tushunilgan. 11-misol uchun ekstra…"',
            'Du · 15:20'),
        _N('primary', null, 'O‘quvchidan savol',
            'Halimova Zilola sizga yozdi · uy ishi', 'Du · 14:08',
            icon: SfIcons.chat),
        _N('neutral', null, 'Haftalik hisobot',
            '14 May – 19 May · yuklab olishga tayyor.', 'Du · 09:00',
            icon: SfIcons.upload),
      ]),
    ];
    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Bildirishnomalar',
            subtitle: '9 ta · 4 ta yangi',
            actions: const [Icon(SfIcons.filter), SizedBox(width: 14), Icon(SfIcons.check)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                for (final entry in [
                  ('Hammasi', 9, true),
                  ('AI', 2, false),
                  ('Print', 2, false),
                  ('Xabar', 2, false),
                  ('Markaz', 1, false),
                ].asMap().entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.value.$3 ? c.ink : Colors.transparent,
                          border: entry.value.$3 ? null : Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${entry.value.$1} · ${entry.value.$2}',
                            style: SfType.ui(
                                size: 11,
                                weight: FontWeight.w600,
                                color: entry.value.$3 ? c.bg : c.muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 24),
        children: [
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Text(g.$1.toUpperCase(), style: SfType.eyebrow(color: c.muted)),
            ),
            for (final n in g.$2)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _NotifTile(n),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _N {
  final String tone;
  final String? aiText;
  final String title;
  final String body;
  final String t;
  final IconData? icon;
  _N(this.tone, this.aiText, this.title, this.body, this.t, {this.icon});
}

class _NotifTile extends StatelessWidget {
  final _N n;
  const _NotifTile(this.n);

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    Color bg, fg, border;
    switch (n.tone) {
      case 'ai':
        bg = c.aiBg.first;
        fg = c.ai;
        border = c.aiBorder;
        break;
      case 'primary':
        bg = c.primarySoft;
        fg = c.primaryInk;
        border = Colors.transparent;
        break;
      case 'accent':
        bg = c.accentSoft;
        fg = c.accentInk;
        border = Colors.transparent;
        break;
      case 'success':
        bg = c.successSoft;
        fg = c.success;
        border = Colors.transparent;
        break;
      case 'warn':
        bg = c.warnSoft;
        fg = c.warn;
        border = Colors.transparent;
        break;
      default:
        bg = c.surface2;
        fg = c.ink2;
        border = Colors.transparent;
    }
    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: n.aiText != null
                ? Text('Ai', style: SfType.display(size: 18, color: fg))
                : Icon(n.icon ?? SfIcons.bell, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          style: SfType.ui(
                              size: 13.5, weight: FontWeight.w700, color: c.ink)),
                    ),
                    Text(n.t, style: SfType.mono(size: 10, color: c.muted)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(n.body,
                    style: SfType.ui(size: 12.5, color: c.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
