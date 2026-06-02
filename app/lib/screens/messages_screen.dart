import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final threads = [
      _Th('Akbarova Dilnoza', '9-B · Akmal ona', 'Rahmat, ustoz! Ertaga albatta...', '14:42',
          unread: 0, online: true),
      _Th('9-B ota-onalar', 'Guruh chat · 24 azo', 'Nigora opa: Ertangi darsda...', '12:18',
          unread: 3, group: true),
      _Th('Azizova Sevara', '9-B · Madina ona', 'Yozma ish bo‘yicha...', 'Du', unread: 1),
      _Th('Eshmatova Gulnora', '9-B · Otabek ona', 'Bolam bugun darsga kela ol...', 'Du', unread: 2),
      _Th('Karimova Rano', 'Direktor', 'Ertangi yig‘ilish 14:00 da', '16 May', unread: 0, pin: true),
      _Th('Bakirova Zarnigor', '9-B · Sherzod ona', 'Yaxshi, biz keldik', '15 May', unread: 0),
    ];
    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Xabarlar',
            subtitle: '6 ta yangi',
            actions: [
              const Icon(SfIcons.search),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.go('/messages/new'),
                child: const Icon(SfIcons.edit),
              ),
            ],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                for (final entry in [
                  ('Hammasi', 4, true),
                  ('Ota-onalar', 4, false),
                  ('Hamkasblar', 1, false),
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
                        child: Text(
                            entry.value.$2 > 0
                                ? '${entry.value.$1} · ${entry.value.$2}'
                                : entry.value.$1,
                            style: SfType.ui(
                                size: 12,
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
              onTap: () => context.go('/messages/chat'),
              child: Container(
                decoration: BoxDecoration(
                  color: th.unread > 0 ? c.surface : Colors.transparent,
                  border: Border(bottom: BorderSide(color: c.border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        if (th.group)
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                                color: c.primary, borderRadius: BorderRadius.circular(14)),
                            alignment: Alignment.center,
                            child: const SfStar(size: 22, color: Color(0xFFFFFCF5)),
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
                            ],
                          ),
                          Text(th.sub, style: SfType.ui(size: 10.5, color: c.muted)),
                          const SizedBox(height: 4),
                          Text(th.last,
                              overflow: TextOverflow.ellipsis,
                              style: SfType.ui(
                                  size: 12.5,
                                  weight: th.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  color: th.unread > 0 ? c.ink2 : c.muted)),
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
                                color: c.primary, borderRadius: BorderRadius.circular(10)),
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
    );
  }
}

class _Th {
  final String n, sub, last, t;
  final int unread;
  final bool online;
  final bool group;
  final bool pin;
  _Th(this.n, this.sub, this.last, this.t,
      {required this.unread, this.online = false, this.group = false, this.pin = false});
}
