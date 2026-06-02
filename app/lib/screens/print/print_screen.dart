import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../router.dart';

class PrintScreen extends StatelessWidget {
  const PrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final printers = [
      _P('HP LaserJet · M404n', 'Lobbi · 1-qavat', 'free', 'Hozir tayyor', 0, false, 'A4',
          c.success),
      _P('Xerox WorkCentre · Pro', '2-qavat dahliz', 'busy', '11:34 da bo‘shaydi', 2, true,
          'A4 · A3 · color', c.warn),
      _P('Brother · DCP-L', 'Direktor xonasi', 'locked', 'Faqat ma‘muriyat', 0, false, 'A4',
          c.muted),
    ];
    final myQueue = [
      _Q('Kvadrat tenglamalar · slayd', 'Kutubxona', 24, 'A4 · B/W', 'HP LaserJet', 'now', 64,
          'Tugaydi · 11:24'),
      _Q('Yulduz karta · 6 nusxa', 'AI generatsiya', 6, 'A5 · rang', 'Xerox WorkCentre', 'queued', 0,
          'Boshlanadi · 11:38'),
    ];

    return SfScaffold(
      tab: SfTab.print,
      onTabChanged: (t) => handleTab(context, SfTab.values.indexOf(t)),
      top: SfLargeAppBar(
        title: 'Chop etish',
        subtitle: 'Yunusobod filiali · 3 ta printer',
        actions: const [Icon(SfIcons.search), SizedBox(width: 14), Icon(SfIcons.plus)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('Mening navbatim',
                    style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink)),
                const Spacer(),
                Text('2 ta faol', style: SfType.ui(size: 11, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final j in myQueue) ...[
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 46,
                        height: 60,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(SfIcons.doc, size: 22, color: c.ink2),
                      ),
                      Positioned(
                        bottom: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                              color: c.ink, borderRadius: BorderRadius.circular(4)),
                          child: Text('×${j.copies}',
                              style: SfType.mono(
                                  size: 9, weight: FontWeight.w700, color: c.bg)),
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
                            Expanded(
                              child: Text(j.doc,
                                  overflow: TextOverflow.ellipsis,
                                  style: SfType.ui(
                                      size: 13.5,
                                      weight: FontWeight.w700,
                                      color: c.ink)),
                            ),
                            SfPill(
                                tone: j.state == 'now'
                                    ? SfPillTone.primary
                                    : SfPillTone.accent,
                                label: j.state == 'now' ? 'Chop bo‘ladi' : 'Navbatda'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${j.src} · ${j.size} · ${j.printer}',
                            style: SfType.ui(size: 11, color: c.muted)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: j.pct / 100,
                                  minHeight: 6,
                                  backgroundColor: c.surface2,
                                  valueColor: AlwaysStoppedAnimation(
                                      j.state == 'now' ? c.primary : c.accent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(j.state == 'now' ? '${j.pct}%' : j.eta.split(' · ').last,
                                style: SfType.mono(size: 11, color: c.muted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(j.eta, style: SfType.ui(size: 10.5, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('Printerlar',
                    style: SfType.ui(size: 13, weight: FontWeight.w700, color: c.ink)),
                const Spacer(),
                Text('Filial · 1-qavat', style: SfType.ui(size: 11, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final p in printers) ...[
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                                color: c.surface2,
                                borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Icon(SfIcons.printer, size: 22, color: p.acc),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: p.acc,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.surface, width: 2),
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
                                Flexible(
                                  child: Text(p.n,
                                      style: SfType.ui(
                                          size: 14,
                                          weight: FontWeight.w700,
                                          color: c.ink)),
                                ),
                                if (p.color) const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: SfPill(tone: SfPillTone.accent, label: 'Rangli')),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${p.loc} · ${p.sizes}',
                                style: SfType.ui(size: 11, color: c.muted)),
                          ],
                        ),
                      ),
                      SfPill(
                          tone: p.status == 'free'
                              ? SfPillTone.success
                              : p.status == 'busy'
                                  ? SfPillTone.accent
                                  : SfPillTone.neutral,
                          label: p.status == 'free'
                              ? 'Bo‘sh'
                              : p.status == 'busy'
                                  ? '${p.q} navbat'
                                  : 'Yopiq'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: c.surface2, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(SfIcons.clock, size: 14, color: p.acc),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.etaT,
                              style: SfType.ui(size: 11.5, color: c.ink2)),
                        ),
                        if (p.status != 'locked')
                          GestureDetector(
                            onTap: () => context.go('/print/new'),
                            child: Row(
                              children: [
                                Text('Yuborish',
                                    style: SfType.ui(
                                        size: 11.5,
                                        color: c.primary,
                                        weight: FontWeight.w600)),
                                Icon(SfIcons.arrowR, size: 12, color: c.primary),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
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
          height: 50,
          label: 'Yangi chop etish',
          leading: SfIcons.plus,
          onPressed: () => context.go('/print/new'),
        ),
      ),
    );
  }
}

class _P {
  final String n;
  final String loc;
  final String status;
  final String etaT;
  final int q;
  final bool color;
  final String sizes;
  final Color acc;
  _P(this.n, this.loc, this.status, this.etaT, this.q, this.color, this.sizes, this.acc);
}

class _Q {
  final String doc, src, size, printer, state, eta;
  final int copies, pct;
  _Q(this.doc, this.src, this.copies, this.size, this.printer, this.state, this.pct, this.eta);
}
