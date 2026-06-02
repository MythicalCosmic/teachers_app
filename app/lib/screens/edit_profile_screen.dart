import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/sf_theme.dart';
import '../theme/tokens.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

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
              Text('Profilni tahrirlash',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.ink)),
              const Spacer(),
              Text('Saqlash',
                  style: SfType.ui(size: 15, weight: FontWeight.w700, color: c.primary)),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SfAvatar(name: 'Nigora Karimova', size: 96, color: c.primary),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 6),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(SfIcons.edit, size: 16, color: c.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _field(c, 'ISM', 'Nigora'),
          const SizedBox(height: 12),
          _field(c, 'FAMILIYA', 'Karimova'),
          const SizedBox(height: 12),
          _field(c, 'OTASINING ISMI', 'Akmal qizi'),
          const SizedBox(height: 12),
          _field(c, 'KASB / LAVOZIM', 'Matematika ustozi'),
          const SizedBox(height: 18),
          Text('ALOQA', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                _row(c, 'Telefon', '+998 90 222 11 33', last: false),
                _row(c, 'Pochta', 'nigora.k@demo.starforge.uz', last: false),
                _row(c, 'Tug‘ilgan kun', '14 mart, 1989', last: true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('FAN YO‘NALISHI', style: SfType.eyebrow(color: c.muted)),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in const ['Algebra', 'Geometriya', 'DTM tayyorlov'])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s,
                            style: SfType.ui(
                                size: 12, weight: FontWeight.w700, color: c.primaryInk)),
                        const SizedBox(width: 4),
                        Icon(SfIcons.x, size: 14, color: c.primaryInk),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: c.surface2, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(SfIcons.plus, size: 14, color: c.muted),
                      const SizedBox(width: 4),
                      Text('Qo‘shish',
                          style: SfType.ui(
                              size: 12, weight: FontWeight.w600, color: c.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(SfColors c, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SfType.eyebrow(color: c.muted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: SfType.ui(size: 15, color: c.ink)),
        ),
      ],
    );
  }

  Widget _row(SfColors c, String label, String value, {required bool last}) {
    return Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: SfType.ui(size: 13.5, color: c.ink))),
          Text(value, style: SfType.ui(size: 13, color: c.muted)),
          const SizedBox(width: 6),
          Icon(SfIcons.chevR, size: 16, color: c.muted),
        ],
      ),
    );
  }
}
