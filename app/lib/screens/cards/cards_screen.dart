import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  CardKind? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final cards = state.cards
        .where((card) => _filter == null || card.kind == _filter)
        .toList(growable: false);
    final praise = state.cards
        .where((card) => card.kind == CardKind.praise)
        .length;
    final warnings = state.cards.length - praise;
    final canIssue = state.can(StaffCapability.issueCards);

    return SfScaffold(
      top: SfLargeAppBar(
        title: 'Kartalar',
        subtitle: '${state.cards.length} ta faol yozuv · $praise ijobiy',
        actions: [
          if (canIssue)
            IconButton(
              tooltip: 'Karta berish',
              onPressed: () => context.push('/cards/give'),
              icon: const Icon(SfIcons.plus),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            color: c.bg,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF6E0AC), Color(0xFFE9C272)],
                    ),
                    border: Border.all(color: const Color(0xFFC49A3A)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const SfStar(size: 22, color: Color(0xFF7A4F0E)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _Metric(value: praise, label: 'Ijobiy', color: c.success),
                      _Metric(
                        value: warnings,
                        label: 'Ogohlantirish',
                        color: c.danger,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!canIssue) ...[
            const SfHintCard(
              title: 'Faqat ko‘rish rejimi',
              message:
                  'Sizning rolingiz kartalarni ko‘ra oladi, ammo yangi karta bera olmaydi.',
              tone: SfHintTone.info,
              compact: true,
            ),
            const SizedBox(height: 12),
          ],
          SegmentedButton<CardKind?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Hammasi')),
              ButtonSegment(value: CardKind.praise, label: Text('Ijobiy')),
              ButtonSegment(
                value: CardKind.warning,
                label: Text('Ogohlantirish'),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) =>
                setState(() => _filter = selection.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 14),
          if (cards.isEmpty)
            _CardsEmptyExperience(
              filtered: state.cards.isNotEmpty,
              canIssue: canIssue,
              onClearFilter: _filter == null
                  ? null
                  : () => setState(() => _filter = null),
            )
          else
            for (final card in cards) ...[
              _CardRow(card: card),
              const SizedBox(height: 8),
            ],
        ],
      ),
      bottom: canIssue
          ? Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SfButton(
                kind: SfButtonKind.primary,
                block: true,
                height: 50,
                label: 'Karta berish',
                leading: SfIcons.plus,
                onPressed: () => context.push('/cards/give'),
              ),
            )
          : null,
    );
  }
}

class _CardsEmptyExperience extends StatelessWidget {
  const _CardsEmptyExperience({
    required this.filtered,
    required this.canIssue,
    required this.onClearFilter,
  });

  final bool filtered;
  final bool canIssue;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SfSurfaceCard(
          key: const Key('cards-rich-empty-state'),
          color: c.primarySoft,
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  filtered ? Icons.filter_alt_off_rounded : Icons.stars_rounded,
                  color: c.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filtered
                          ? 'Bu filtr hozircha bo‘sh'
                          : 'Bugun yangi sahifadan boshlanadi',
                      style: SfType.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      filtered
                          ? 'Barcha kartalarni qayta ko‘ring yoki boshqa turini tanlang.'
                          : canIssue
                          ? 'Aniq va samimiy e’tirof o‘quvchining keyingi yaxshi qadamini kuchaytiradi.'
                          : 'Markaz kartalari berilganda, ularning sababi va tarixi shu yerda xavfsiz ko‘rinadi.',
                      style: SfType.ui(size: 11.5, color: c.ink2, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onClearFilter != null) ...[
          const SizedBox(height: 10),
          SfButton(
            kind: SfButtonKind.ghost,
            block: true,
            label: 'Filtrni tozalash',
            leading: Icons.filter_alt_off_rounded,
            onPressed: onClearFilter,
          ),
        ],
        const SizedBox(height: 12),
        SfSurfaceCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _EmptyCardGuideRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Yaxshi ishni e’tirof eting',
                subtitle:
                    'Aqlli, faol va ijobiy qadamlarni aniq sabab bilan belgilang.',
                color: c.success,
              ),
              Divider(height: 22, color: c.border),
              _EmptyCardGuideRow(
                icon: Icons.trending_up_rounded,
                title: 'O‘sishni kuzating',
                subtitle:
                    'Kartalar paydo bo‘lgach, ijobiy va rivojlanish signallari ajratiladi.',
                color: c.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCardGuideRow extends StatelessWidget {
  const _EmptyCardGuideRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SfType.ui(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: SfType.ui(size: 10.5, color: c.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$value',
        style: SfType.mono(size: 24, weight: FontWeight.w800, color: color),
      ),
      Text(
        label,
        style: SfType.ui(size: 11, color: SfTheme.colorsOf(context).muted),
      ),
    ],
  );
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card});
  final RecognitionCard card;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final positive = card.kind == CardKind.praise;
    final accent = positive ? const Color(0xFF7A4F0E) : c.danger;
    return SfSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 58,
            decoration: BoxDecoration(
              color: positive ? const Color(0xFFF6E0AC) : c.dangerSoft,
              border: Border.all(color: accent.withValues(alpha: .5)),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              positive ? Icons.star_rounded : Icons.flag_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.studentName,
                        style: SfType.ui(
                          size: 13.5,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                    Text(
                      _compactDate(card.issuedAt),
                      style: SfType.mono(size: 10, color: c.muted),
                    ),
                  ],
                ),
                Text(
                  '${card.cohortName} · ${card.label}',
                  style: SfType.ui(
                    size: 11,
                    weight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.reason,
                    style: SfType.ui(size: 12, color: c.ink2, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _compactDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
