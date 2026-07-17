import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

enum _ProgressStatus { notSubmitted, submitted, feedbackNeeded, feedbackShared }

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  _ProgressStatus? _filter;

  static const _learners = [
    _Learner('Akbarov Akmal', _ProgressStatus.feedbackNeeded, 'Bugun · 09:42'),
    _Learner('Azizova Madina', _ProgressStatus.feedbackShared, 'Kecha · 18:10'),
    _Learner('Bakirov Sherzod', _ProgressStatus.submitted, 'Bugun · 08:54'),
    _Learner(
      'Davronova Sevinch',
      _ProgressStatus.feedbackShared,
      'Kecha · 16:22',
    ),
    _Learner('Eshmatov Otabek', _ProgressStatus.notSubmitted, 'Muddat ertaga'),
    _Learner(
      'Halimova Zilola',
      _ProgressStatus.feedbackNeeded,
      'Bugun · 10:05',
    ),
  ];

  Future<void> _remind(BuildContext context, _Learner learner) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eslatma yuborilsinmi?'),
            content: Text(
              '${learner.name}ga topshiriq muddati haqida xabar yuboriladi.',
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text('Bekor'),
              ),
              FilledButton(
                onPressed: () => dialogContext.pop(true),
                child: const Text('Yuborish'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      SfToast.show(
        context,
        title: 'Eslatma yuborildi',
        message: learner.name,
        tone: SfToastTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    if (!state.can(StaffCapability.teachLessons)) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Jarayon'),
        ),
        body: const SfEmptyState(
          title: 'Ruxsat mavjud emas',
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    final visible = _learners
        .where((learner) => _filter == null || learner.status == _filter)
        .toList();
    final completed = _learners
        .where((learner) => learner.status == _ProgressStatus.feedbackShared)
        .length;
    return SfScaffold(
      top: SfNavBar(
        title: 'Topshiriq jarayoni',
        subtitle: '$completed/${_learners.length} ta fikr yakunlangan',
        leading: IconButton(
          tooltip: 'Orqaga',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          const SfHintCard(
            title: 'Jarayon va fikr holati',
            message:
                'Bu ko‘rinish raqamli baho bermaydi. Kim topshirgani va kimga foydali fikr kerakligini ko‘rsatadi.',
            tone: SfHintTone.info,
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Hammasi'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 6),
                for (final status in _ProgressStatus.values) ...[
                  ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: _filter == status,
                    onSelected: (_) => setState(() => _filter = status),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const SfEmptyState(title: 'Bu holatda o‘quvchi yo‘q', compact: true)
          else
            for (final learner in visible) ...[
              SfSurfaceCard(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    SfAvatar(name: learner.name, size: 38),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            learner.name,
                            style: SfType.ui(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            learner.detail,
                            style: SfType.ui(size: 10.5, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          context,
                          learner.status,
                        ).withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(learner.status),
                        style: SfType.ui(
                          size: 10,
                          weight: FontWeight.w800,
                          color: _statusColor(context, learner.status),
                        ),
                      ),
                    ),
                    if (learner.status == _ProgressStatus.notSubmitted)
                      IconButton(
                        tooltip: 'Eslatma yuborish',
                        onPressed: () => _remind(context, learner),
                        icon: const Icon(Icons.notifications_active_outlined),
                      )
                    else
                      IconButton(
                        tooltip: 'Ishni ochish',
                        onPressed: () => context.push('/assignments/grade'),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _Learner {
  const _Learner(this.name, this.status, this.detail);
  final String name;
  final _ProgressStatus status;
  final String detail;
}

String _statusLabel(_ProgressStatus status) => switch (status) {
  _ProgressStatus.notSubmitted => 'Topshirmagan',
  _ProgressStatus.submitted => 'Topshirildi',
  _ProgressStatus.feedbackNeeded => 'Fikr kerak',
  _ProgressStatus.feedbackShared => 'Fikr yuborildi',
};

Color _statusColor(BuildContext context, _ProgressStatus status) {
  final c = SfTheme.colorsOf(context);
  return switch (status) {
    _ProgressStatus.notSubmitted => c.danger,
    _ProgressStatus.submitted => c.primary,
    _ProgressStatus.feedbackNeeded => c.warn,
    _ProgressStatus.feedbackShared => c.success,
  };
}
