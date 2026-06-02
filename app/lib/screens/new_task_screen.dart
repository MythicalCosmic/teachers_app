import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';

class NewTaskScreen extends StatelessWidget {
  const NewTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
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
              Text('Yangi vazifa',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
              const Spacer(),
              Text('Yaratish',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.primary)),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Text('SARLAVHA', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Text('Vazifa sarlavhasini yozing...',
                style: SfType.ui(size: 16, color: c.muted)),
          ),
          const SizedBox(height: 18),
          Text('TAFSILOTLAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 100,
              child: Text('Sub-vazifalar va batafsil tavsifni qo‘shing.',
                  style: SfType.ui(size: 13, color: c.muted, height: 1.5)),
            ),
          ),
          const SizedBox(height: 18),
          Text('SOZLAMALAR', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final s in [
                  ('Loyiha', 'Hisobot', SfIcons.brand),
                  ('Prioritet', 'P2', SfIcons.flag),
                  ('Muddat', 'Bu hafta', SfIcons.cal),
                  ('Eslatma', 'Sozlanmagan', SfIcons.bell),
                ])
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(s.$3, size: 16, color: c.ink2),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.$1, style: SfType.ui(size: 13.5, color: c.ink))),
                        Text(s.$2, style: SfType.ui(size: 13, color: c.muted)),
                        const SizedBox(width: 6),
                        Icon(SfIcons.chevR, size: 14, color: c.muted),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('TAG', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              SfPill(label: '+ Markaz'),
              SfPill(label: '+ Yarim oy'),
              SfPill(label: '+ Mat'),
              SfPill(label: '+ Shaxsiy'),
            ],
          ),
          const SizedBox(height: 18),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Sub-vazifa generatori'),
                const SizedBox(height: 8),
                Text(
                  'Sarlavhani yozing — AI sizning ish uslubingiz asosida tavsiya etilgan sub-vazifalar ro‘yxatini tayyorlab beradi.',
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
