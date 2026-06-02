import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class MgmtInboxScreen extends StatelessWidget {
  const MgmtInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final threads = [
      _Th('Karimova Rano', 'Direktor', 'Ertangi yig‘ilish 14:00 da o‘tadi.', '14:08', 1,
          pin: true, online: true),
      _Th('Ahmedov Botir', 'O‘quv ishlari bo‘yicha',
          'Yangi karta sozlamalari haqida o‘qib chiqing.', '12:42', 0),
      _Th('Yusupova Nargiza', 'Metodist · Matematika',
          'Mavzular ro‘yxati yangilandi.', 'Du · 16:20', 2),
      _Th('Markaz e‘lonlari', 'Avtomatik · barchaga',
          'May oyi xulosalari · 23.05 gacha topshiring.', 'Du · 10:00', 0,
          channel: true),
      _Th('Tursunov Sherzod', 'Filial menejeri',
          'Yunusobod filialida printer almashtirildi.', '17 May', 0),
    ];

    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Boshqaruv',
            subtitle: 'Markaz va filial bilan to‘g‘ridan-to‘g‘ri',
            actions: const [Icon(SfIcons.search), SizedBox(width: 12), Icon(SfIcons.edit)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                for (final entry in [
                  ('Hammasi', 5, true),
                  ('Direktor', 1, false),
                  ('Metodist', 1, false),
                  ('Markaz', 1, false),
                ].asMap().entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
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
        children: [
          for (final th in threads)
            GestureDetector(
              onTap: () => context.go('/mgmt/chat'),
              child: Container(
                color: th.unread > 0 ? c.surface : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.border)),
                  color: th.unread > 0 ? c.surface : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        if (th.channel)
                          Container(
                            width: 46,
                            height: 46,
                            decoration:
                                BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(14)),
                            alignment: Alignment.center,
                            child: SfStar(size: 22, color: c.accent),
                          )
                        else
                          SfAvatar(name: th.n, size: 46),
                        if (th.online)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: c.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.bg, width: 2.5),
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
                          Row(
                            children: [
                              Text(th.n,
                                  style: SfType.ui(
                                      size: 14,
                                      weight: th.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                                      color: c.ink)),
                              if (th.pin) ...[
                                const SizedBox(width: 6),
                                Icon(SfIcons.pin, size: 12, color: c.accent),
                              ],
                              if (th.r.contains('Direktor')) ...[
                                const SizedBox(width: 6),
                                const SfPill(tone: SfPillTone.primary, label: 'Direktor'),
                              ],
                            ],
                          ),
                          Text(th.r, style: SfType.ui(size: 10.5, color: c.muted)),
                          const SizedBox(height: 4),
                          Text(
                            th.last,
                            overflow: TextOverflow.ellipsis,
                            style: SfType.ui(
                              size: 12.5,
                              weight: th.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                              color: th.unread > 0 ? c.ink2 : c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(th.t, style: SfType.mono(size: 10, color: c.muted)),
                        const SizedBox(height: 6),
                        if (th.unread > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                                color: c.primary,
                                borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Text('${th.unread}',
                                style: SfType.ui(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFFFFCF5))),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 48,
          label: 'Yangi xabar',
          leading: SfIcons.edit,
        ),
      ),
    );
  }
}

class _Th {
  final String n, r, last, t;
  final int unread;
  final bool pin;
  final bool online;
  final bool channel;
  _Th(this.n, this.r, this.last, this.t, this.unread,
      {this.pin = false, this.online = false, this.channel = false});
}
