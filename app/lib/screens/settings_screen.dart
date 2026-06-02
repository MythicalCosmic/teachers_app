import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_wordmark.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final sections = [
      _Sec('Hisob', [
        _Item('Shaxsiy ma‘lumotlar', icon: SfIcons.user, value: 'Nigora Karimova'),
        _Item('Foydalanuvchi nomi', icon: SfIcons.shield, value: 'nigora.karimova', mono: true),
        _Item('Parolni o‘zgartirish', icon: SfIcons.edit),
        _Item('Til', icon: SfIcons.globe, value: 'O‘zbekcha'),
      ]),
      _Sec('Maxfiylik · Profil ulashish', [
        _Item('Profilim markaz uchun ko‘rinadi', toggle: true),
        _Item('Ismsiz so‘rovnomalarda ishtirok', toggle: true),
        _Item('AI sizning ma‘lumotlaringizdan o‘rganadi', toggle: false),
      ]),
      _Sec('Bildirishnomalar', [
        _Item('Push xabarlar', toggle: true),
        _Item('Dars boshlanishi · 15 daq oldin', toggle: true),
        _Item('Print tugaganda', toggle: true),
        _Item('AI tavsiyalari', toggle: true),
        _Item('Sokin soatlar · 22:00–07:00', value: 'Yoniq'),
      ]),
      _Sec('AI yordamchi', [
        _Item('Guruh haqida suhbat', toggle: true),
        _Item('Karta sabab taklifi', toggle: true),
        _Item('Ota-ona javob taklifi', toggle: false),
        _Item('Markaz limiti', value: '4 320 / 50 000 token', mono: true),
      ]),
      _Sec('Markaz', [
        _Item('Demo Akademiya', icon: SfIcons.shield, value: 'Yunusobod filiali'),
        _Item('Karta sozlamalari', icon: SfIcons.brand, value: 'Yulduz / Ogohlantirish'),
        _Item('Qurilmalar', icon: SfIcons.printer, value: '2 ta'),
        _Item('Maxfiylik va shartlar', icon: SfIcons.shield),
      ]),
    ];

    return SfScaffold(
      top: SfLargeAppBar(
        title: 'Profil',
        actions: const [Icon(SfIcons.settings)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Stack(
              children: [
                Positioned(
                    right: -30,
                    top: -30,
                    child: Opacity(opacity: 0.08, child: SfStar(size: 140, color: c.primary))),
                Column(
                  children: [
                    Row(
                      children: [
                        SfAvatar(name: 'Nigora Karimova', size: 64, color: c.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nigora Karimova',
                                  style: SfType.ui(
                                      size: 18,
                                      weight: FontWeight.w800,
                                      color: c.ink,
                                      letterSpacing: -0.36)),
                              const SizedBox(height: 2),
                              Text('Matematika ustozi · Yunusobod filiali',
                                  style: SfType.ui(size: 12, color: c.muted)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: const [
                                  SfPill(tone: SfPillTone.primary, label: '9-B'),
                                  SfPill(tone: SfPillTone.primary, label: 'Alg Mid'),
                                  SfPill(tone: SfPillTone.accent, label: '10-V'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: c.successSoft,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: c.success, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text('PROFIL ULASHILMOQDA',
                                        style: SfType.eyebrow(color: c.success)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final s in const [
                          ('3', 'Guruh'),
                          ('58', 'O‘quvchi'),
                          ('12', 'Dars/hafta'),
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: c.surface2,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Text(s.$1,
                                        style: SfType.mono(
                                            size: 18,
                                            weight: FontWeight.w700,
                                            color: c.ink,
                                            height: 1)),
                                    const SizedBox(height: 4),
                                    Text(s.$2.toUpperCase(),
                                        style: SfType.eyebrow(color: c.muted, size: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final sec in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text(sec.h.toUpperCase(), style: SfType.eyebrow(color: c.muted)),
            ),
            SfSurfaceCard(
              child: Column(
                children: [
                  for (int i = 0; i < sec.items.length; i++)
                    _ItemRow(sec.items[i], last: i == sec.items.length - 1),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          SfButton(
            kind: SfButtonKind.ghost,
            block: true,
            height: 50,
            label: 'Chiqish',
            leading: SfIcons.logout,
            overrideFg: c.danger,
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(height: 14),
          const Center(child: SfWordmark(size: 12)),
          const SizedBox(height: 4),
          Center(
              child: Text('v1.0.0 · build 2026.05.19',
                  style: SfType.mono(size: 10, color: c.muted))),
        ],
      ),
    );
  }
}

class _Sec {
  final String h;
  final List<_Item> items;
  _Sec(this.h, this.items);
}

class _Item {
  final String label;
  final IconData? icon;
  final String? value;
  final bool? toggle;
  final bool mono;
  _Item(this.label, {this.icon, this.value, this.toggle, this.mono = false});
}

class _ItemRow extends StatelessWidget {
  final _Item it;
  final bool last;
  const _ItemRow(this.it, {required this.last});
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: it.label == 'Shaxsiy ma‘lumotlar' ? () => context.go('/settings/edit') : null,
      child: Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (it.icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: Icon(it.icon, size: 16, color: c.ink2),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(it.label, style: SfType.ui(size: 13.5, color: c.ink))),
          if (it.value != null)
            Text(it.value!,
                style: it.mono
                    ? SfType.mono(size: 12, color: c.muted)
                    : SfType.ui(size: 12, color: c.muted)),
          if (it.toggle != null) _Toggle(value: it.toggle!),
          if (it.toggle == null && it.value == null) Icon(SfIcons.chevR, size: 16, color: c.muted),
        ],
      ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  const _Toggle({required this.value});
  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: value ? c.primary : c.surface3,
          borderRadius: BorderRadius.circular(999)),
      child: AnimatedAlign(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
              color: Color(0xFFFFFCF5),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)]),
        ),
      ),
    );
  }
}
