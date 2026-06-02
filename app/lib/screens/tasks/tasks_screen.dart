import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../router.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tasks = [
      _T('P1', 'doing', 'Bajarilmoqda', 'primary',
          'May oyi yakuniy hisobotini topshirish', 'Hisobot', c.primary,
          'Karimova R.', 'Erta · 18:00', subs: '2/4', mgmt: true, urgent: true),
      _T('P2', 'todo', 'Boshlanmagan', 'neutral',
          'Kvadrat tenglamalar · slaydlarni yangilash', 'Materiallar', c.accent,
          'Men', 'Pen · 23:59', subs: '0/3'),
      _T('P2', 'doing', 'Bajarilmoqda', 'primary',
          'So‘rovnoma · AI sifat baholash', 'So‘rovnoma', c.ai,
          'Metodist', '22.05', subs: '1/1', mgmt: true),
      _T('P3', 'review', 'Tekshirishda', 'accent',
          'Olimpiada tayyorgarligi · 11-B uchun reja', 'Tayyorlov', c.ink2,
          'Yusupova N.', '25.05', mgmt: true),
      _T('P3', 'done', 'Tugatildi', 'success',
          'Yangi karta nomlarini ko‘rib chiqish', 'Markaz', c.success,
          'Direktor', '18.05', mgmt: true),
    ];

    return SfScaffold(
      tab: SfTab.tasks,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Vazifalar',
            subtitle: '3 ta bugun · 2 ta direktordan',
            actions: const [Icon(SfIcons.filter), SizedBox(width: 14), Icon(SfIcons.plus)],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                for (final entry in [
                  ('Hammasi', 12, true),
                  ('Mendan', 7, false),
                  ('Boshqaruv', 5, false),
                  ('Tugatildi', 8, false),
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
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('BUGUN · 3 TA', style: SfType.eyebrow(color: c.muted)),
                const Spacer(),
                _SegBtn(['List', 'Board']),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final t in tasks) ...[
            GestureDetector(
              onTap: () => context.go('/tasks/detail'),
              child: _TaskCard(t),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          SfAiSurface(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SfAiBadge(label: 'Vazifa yordamchi'),
                const SizedBox(height: 8),
                Text(
                  'May hisobotini yozish uchun ish boshlasangiz, AI o‘tkan oygi davomat va kartalardan jamlama tayyorlab beraman.',
                  style: SfType.ui(size: 13, color: c.ink2, height: 1.4),
                ),
                const SizedBox(height: 10),
                SfButton(
                  kind: SfButtonKind.ink,
                  label: 'Boshlash',
                  trailing: SfIcons.arrowR,
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ],
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
          label: 'Yangi vazifa',
          leading: SfIcons.plus,
          onPressed: () => context.go('/tasks/new'),
        ),
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final List<String> labels;
  const _SegBtn(this.labels);
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        for (final entry in labels.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: entry.key == 0 ? c.ink : Colors.transparent,
                border: entry.key == 0 ? null : Border.all(color: c.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(entry.value,
                  style: SfType.ui(
                      size: 11,
                      weight: FontWeight.w600,
                      color: entry.key == 0 ? c.bg : c.muted)),
            ),
          ),
      ],
    );
  }
}

class _T {
  final String pri;
  final String state;
  final String stateName;
  final String stateTone;
  final String t;
  final String proj;
  final Color projColor;
  final String assigner;
  final String deadline;
  final String? subs;
  final bool mgmt;
  final bool urgent;
  _T(this.pri, this.state, this.stateName, this.stateTone, this.t, this.proj,
      this.projColor, this.assigner, this.deadline,
      {this.subs, this.mgmt = false, this.urgent = false});
}

class _TaskCard extends StatelessWidget {
  final _T t;
  const _TaskCard(this.t);

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    Color sb, sf;
    switch (t.stateTone) {
      case 'primary':
        sb = c.primarySoft;
        sf = c.primaryInk;
        break;
      case 'accent':
        sb = c.accentSoft;
        sf = c.accentInk;
        break;
      case 'success':
        sb = c.successSoft;
        sf = c.success;
        break;
      default:
        sb = c.surface2;
        sf = c.muted;
    }
    return Opacity(
      opacity: t.state == 'done' ? 0.65 : 1,
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned(
              left: -14,
              top: 14,
              bottom: 14,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: t.urgent ? c.danger : t.projColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: t.state == 'done' ? c.success : Colors.transparent,
                          border: t.state == 'done'
                              ? null
                              : Border.all(color: c.borderStrong, width: 1.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: t.state == 'done'
                            ? const Icon(SfIcons.check, size: 12, color: Color(0xFFFFFCF5))
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: sb, borderRadius: BorderRadius.circular(4)),
                        child: Text(t.stateName.toUpperCase(),
                            style: SfType.eyebrow(color: sf, size: 10)),
                      ),
                      if (t.mgmt)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: c.ink, borderRadius: BorderRadius.circular(4)),
                          child: Text('BOSHQARUV',
                              style: SfType.eyebrow(color: c.bg, size: 10)),
                        ),
                      Text(t.pri,
                          style: SfType.mono(
                              size: 10,
                              weight: FontWeight.w700,
                              color: t.pri == 'P1'
                                  ? c.danger
                                  : t.pri == 'P2'
                                      ? c.warn
                                      : c.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.t,
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w600,
                      color: t.state == 'done' ? c.muted : c.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: t.projColor, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Text(t.proj, style: SfType.ui(size: 11, color: c.muted)),
                      if (t.subs != null) ...[
                        const SizedBox(width: 12),
                        Text('${t.subs!} subt',
                            style: SfType.mono(size: 11, color: c.muted)),
                      ],
                      const Spacer(),
                      Text(t.deadline,
                          style: SfType.mono(
                              size: 11,
                              weight: t.urgent ? FontWeight.w700 : FontWeight.w500,
                              color: t.urgent
                                  ? c.danger
                                  : t.state == 'done'
                                      ? c.muted
                                      : c.ink2)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
