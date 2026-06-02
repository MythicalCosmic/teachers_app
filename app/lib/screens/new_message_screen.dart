import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';

class NewMessageScreen extends StatelessWidget {
  const NewMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final suggestions = [
      ('Akbarova Dilnoza', '9-B · Akmal ona'),
      ('Eshmatova Gulnora', '9-B · Otabek ona'),
      ('Karimova Rano', 'Direktor'),
      ('9-B ota-onalar', 'Guruh chat · 24 azo'),
    ];
    return SfScaffold(
      top: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Text('Bekor',
                    style: SfType.ui(size: 16, weight: FontWeight.w600, color: c.primary)),
              ),
              const Spacer(),
              Text('Yangi xabar',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
              const Spacer(),
              Text('Yuborish',
                  style: SfType.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: c.primary.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          Text('KIMGA', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(SfIcons.search, size: 18, color: c.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Ism, guruh yoki ota-onani izlang',
                      style: SfType.ui(size: 14, color: c.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('TAVSIYALAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (int i = 0; i < suggestions.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i < suggestions.length - 1
                          ? Border(bottom: BorderSide(color: c.border))
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SfAvatar(name: suggestions[i].$1, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(suggestions[i].$1,
                                  style: SfType.ui(
                                      size: 13.5,
                                      weight: FontWeight.w600,
                                      color: c.ink)),
                              Text(suggestions[i].$2,
                                  style: SfType.ui(size: 11, color: c.muted)),
                            ],
                          ),
                        ),
                        Icon(SfIcons.plus, size: 18, color: c.primary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('XABAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox(
              height: 140,
              child: Text('Xabaringizni yozing...',
                  style: SfType.ui(size: 14, color: c.muted)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              SfPill(label: '+ Bugungi dars haqida'),
              SfPill(label: '+ Davomat eslatma'),
              SfPill(label: '+ Uy ishi'),
              SfPill(label: '+ Ota-ona uchrashuvi'),
            ],
          ),
          const SizedBox(height: 18),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Yozish yordamchi'),
                const SizedBox(height: 8),
                Text(
                  'Qabul qiluvchini tanlang — sizning karta va davomat ma‘lumotlaringiz asosida AI 3 ta variant tayyorlab beradi.',
                  style: SfType.ui(size: 13, color: c.ink2, height: 1.4),
                ),
                const SizedBox(height: 10),
                SfButton(
                  kind: SfButtonKind.ink,
                  label: 'Tavsiya berish',
                  trailing: SfIcons.arrowR,
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
