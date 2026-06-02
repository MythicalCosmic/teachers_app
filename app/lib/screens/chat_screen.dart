import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
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
              const SfAvatar(name: 'Akbarova Dilnoza', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akbarova Dilnoza',
                        style: SfType.ui(size: 14, weight: FontWeight.w700, color: c.ink)),
                    Row(
                      children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: c.success, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('onlayn · Akmal ona · 9-B',
                            style: SfType.ui(size: 10.5, color: c.success)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(SfIcons.more, size: 22, color: c.primary),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        children: [
          Center(child: Text('BUGUN', style: SfType.eyebrow(color: c.muted))),
          const SizedBox(height: 10),
          _Incoming(
              'Assalomu alaykum, Nigora opa. Akmal bugun darsda nima yangilik qildi?', '09:42'),
          const SizedBox(height: 10),
          _Outgoing(
              'Va alaykum assalom! Akmal bugun yaxshi ishladi — kvadrat tenglamani mustaqil yechib berdi. Faqat 2-misolda formuladagi kichik xato bo‘ldi, biz birga ko‘rib chiqdik.',
              '09:48'),
          const SizedBox(height: 12),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SfAiBadge(label: 'Javob taklifi', compact: true),
                    const Spacer(),
                    Text('uz · 3 variant', style: SfType.ui(size: 10, color: c.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final t in const [
                  'Bugungi mavzu — kvadrat tenglamalar, Akmal yaxshi ishladi.',
                  'Akmalning bugungi natijasi · 4 baho. Uy ishini topshirsa, qoldirgan misolni qaytaramiz.',
                  'Akmal hozir o‘rta darajada. Qisqa konsultatsiya yordam beradi.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.aiBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child:
                                  Text(t, style: SfType.ui(size: 12.5, color: c.ink2, height: 1.4))),
                          Icon(SfIcons.arrowR, size: 14, color: c.ai),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Incoming('Rahmat, ustoz! Ertaga albatta mashqlarni qilamiz.', '14:42'),
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
                decoration: BoxDecoration(
                    color: c.surface2, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    Expanded(child: Text('Yozish...', style: SfType.ui(size: 13, color: c.muted))),
                    const SfAiBadge(label: '↺', compact: true),
                  ],
                ),
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
        const SfAvatar(name: 'Akbarova Dilnoza', size: 28),
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
