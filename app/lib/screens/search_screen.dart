import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: Column(
        children: [
          SfNavBar(
            title: 'Izlash',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [Icon(SfIcons.arrowL, size: 18), SizedBox(width: 2), Text('Ortga')],
              ),
            ),
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(SfIcons.search, size: 18, color: c.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('O‘quvchi · guruh · material · vazifa',
                        style: SfType.ui(size: 14, color: c.muted)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: c.surface3, borderRadius: BorderRadius.circular(4)),
                    child: Text('⌘K',
                        style: SfType.mono(size: 10, color: c.muted)),
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
          Text('SO‘NGGI', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final r in [
                  ('Akbarov Akmal', '9-B Algebra · o‘quvchi'),
                  ('9-B Algebra', 'Guruh · 24 o‘quvchi'),
                  ('Kvadrat tenglama', 'Material · PDF'),
                ])
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SfAvatar(name: r.$1, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.$1,
                                  style: SfType.ui(
                                      size: 13.5, weight: FontWeight.w600, color: c.ink)),
                              Text(r.$2, style: SfType.ui(size: 11, color: c.muted)),
                            ],
                          ),
                        ),
                        Icon(SfIcons.chevR, size: 16, color: c.muted),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('TEZKOR FILTRLAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in const [
                'Bugun karta olganlar',
                'Kechikkanlar',
                'Topshirmaganlar',
                'AI tavsiyalari',
                'Yangi materiallar',
              ])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(f,
                      style: SfType.ui(size: 12, weight: FontWeight.w600, color: c.ink2)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
