import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';

class MgmtChatScreen extends StatelessWidget {
  const MgmtChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Icon(SfIcons.arrowL, size: 18, color: c.primary),
              ),
              const SizedBox(width: 10),
              const SfAvatar(name: 'Karimova Rano', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Karimova Rano',
                            style: SfType.ui(
                                size: 14, weight: FontWeight.w700, color: c.ink)),
                        const SizedBox(width: 6),
                        const SfPill(tone: SfPillTone.primary, label: 'Direktor'),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: c.success, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('onlayn · Demo Akademiya',
                            style: SfType.ui(size: 10.5, color: c.success)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(SfIcons.more, size: 22, color: c.ink2),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        children: [
          Center(child: Text('BUGUN', style: SfType.eyebrow(color: c.muted))),
          const SizedBox(height: 10),
          _Incoming('Salom Nigora opa. Mayning yakuniy hisobotini 23 gacha topshirsangiz bo‘ladimi?',
              '11:08'),
          const SizedBox(height: 10),
          _Outgoing(
              'Albatta. Bugun ertalab Up/Down kartalar va davomatni tahlil qilib, yopiq hisobotni jo‘nataman.',
              '11:14'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.accent),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.flag, size: 16, color: c.accentInk),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOPSHIRIQ · DIREKTORDAN',
                          style: SfType.eyebrow(color: c.muted)),
                      const SizedBox(height: 4),
                      Text('May hisoboti',
                          style: SfType.ui(
                              size: 13, weight: FontWeight.w700, color: c.ink)),
                      const SizedBox(height: 2),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Muddat: ', style: SfType.ui(size: 11, color: c.muted)),
                        TextSpan(
                            text: '23.05 · 18:00',
                            style: SfType.mono(
                                size: 11, weight: FontWeight.w700, color: c.danger)),
                      ])),
                      const SizedBox(height: 8),
                      SfButton(
                        kind: SfButtonKind.soft,
                        label: 'Vazifaga o‘tish',
                        leading: SfIcons.arrowR,
                        fontSize: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        onPressed: () => context.go('/tasks/detail'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Incoming('Rahmat. Yana bitta — ertaga 14:00 da yig‘ilish, oddiy holat bo‘yicha.',
              '14:08'),
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(SfIcons.attach, size: 18, color: c.ink2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration:
                    BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(22)),
                child: Text('Direktorga yozish...',
                    style: SfType.ui(size: 13, color: c.muted)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Icon(SfIcons.send, size: 18, color: Color(0xFFFFFCF5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Incoming extends StatelessWidget {
  final String text, t;
  const _Incoming(this.text, this.t);
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SfAvatar(name: 'Karimova Rano', size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: SfType.ui(size: 13.5, color: c.ink, height: 1.4)),
                const SizedBox(height: 6),
                Text(t, style: SfType.ui(size: 9.5, color: c.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Outgoing extends StatelessWidget {
  final String text, t;
  const _Outgoing(this.text, this.t);
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text,
                  style: SfType.ui(
                      size: 13.5, color: const Color(0xFFFFFCF5), height: 1.4)),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t,
                      style: SfType.ui(
                          size: 9.5,
                          color: const Color(0xFFFFFCF5).withValues(alpha: 0.8))),
                  const SizedBox(width: 4),
                  const Icon(SfIcons.check, size: 12, color: Color(0xFFFFFCF5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
