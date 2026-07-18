import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../router.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_tab_bar.dart';
import 'groups/group_l10n.dart';
import 'groups/group_workspace_store.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
    super.key,
    this.studentId,
    this.groupId,
    this.store,
  });

  final String? studentId;
  final String? groupId;
  final GroupWorkspaceStore? store;

  @override
  Widget build(BuildContext context) {
    final workspace = store ?? groupWorkspaceStore;
    final group = workspace.groupForStudent(
      studentId,
      preferredGroupId: groupId,
    );
    final student = workspace.student(studentId, groupId: group?.id);
    if (group == null || student == null) {
      return SfScaffold(
        top: SfNavBar(
          title: context.gt('student'),
          leading: IconButton(
            onPressed: context.pop,
            icon: const Icon(SfIcons.arrowL),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              _copy(
                context,
                'O‘quvchi ma’lumotlari topilmadi.',
                'Данные ученика не найдены.',
                'Student record was not found.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final history = workspace
        .history(group.id)
        .where((record) => record.statuses.containsKey(student.id))
        .toList(growable: false);
    final attendance = workspace.studentAttendanceRate(group.id, student.id);
    final absences = history
        .where((row) => row.statuses[student.id] == AttendanceStatus.absent)
        .length;
    final late = history
        .where((row) => row.statuses[student.id] == AttendanceStatus.late)
        .length;
    final colors = SfTheme.colorsOf(context);

    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: SfNavBar(
        title: context.gt('student'),
        subtitle: '${group.name} · ${student.id}',
        leading: SfPressable(
          key: const ValueKey('student-back-action'),
          onPressed: context.pop,
          semanticLabel: context.gt('back_group'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(SfIcons.arrowL, size: 18),
              const SizedBox(width: 4),
              Text(group.name),
            ],
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('student-message-action'),
            tooltip: _copy(context, 'Xabar yozish', 'Написать', 'Message'),
            onPressed: () => context.push(_messageLocation(group, student)),
            icon: const Icon(SfIcons.chat),
          ),
          PopupMenuButton<_StudentAction>(
            key: const ValueKey('student-more-actions'),
            tooltip: _copy(context, 'Amallar', 'Действия', 'Actions'),
            icon: const Icon(SfIcons.more),
            onSelected: (action) =>
                _handleAction(context, action, group, student),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _StudentAction.group,
                child: Text(
                  _copy(
                    context,
                    'Guruhni ochish',
                    'Открыть группу',
                    'Open group',
                  ),
                ),
              ),
              PopupMenuItem(
                value: _StudentAction.attendance,
                child: Text(
                  _copy(
                    context,
                    'Davomat olish',
                    'Отметить',
                    'Take attendance',
                  ),
                ),
              ),
              PopupMenuItem(
                value: _StudentAction.contact,
                child: Text(
                  _copy(
                    context,
                    'Aloqa ma’lumoti',
                    'Контакт',
                    'Contact details',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _StudentHero(group: group, student: student, attendance: attendance),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: SfIcons.chat,
                  label: _copy(context, 'Xabar', 'Сообщение', 'Message'),
                  onPressed: () =>
                      context.push(_messageLocation(group, student)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.how_to_reg_rounded,
                  label: context.gt('attendance'),
                  onPressed: () => context.push(
                    '/attendance?cohort=${Uri.encodeQueryComponent(group.id)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.star_outline_rounded,
                  label: _copy(context, 'Karta', 'Карта', 'Card'),
                  onPressed: () => context.push(
                    Uri(
                      path: '/cards/give',
                      queryParameters: {
                        'student': student.id,
                        'group': group.id,
                      },
                    ).toString(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionHeading(
            title: _copy(
              context,
              'Davomat tarixi',
              'История посещаемости',
              'Attendance history',
            ),
            caption: _copy(
              context,
              '${history.length} dars · $absences yo‘q · $late kech',
              '${history.length} уроков · $absences пропусков · $late опозданий',
              '${history.length} lessons · $absences absent · $late late',
            ),
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            child: Column(
              children: [
                for (final entry in history.take(6).toList().asMap().entries)
                  _AttendanceRow(
                    record: entry.value,
                    status: entry.value.statuses[student.id]!,
                    showDivider: entry.key < history.take(6).length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionHeading(
            title: _copy(
              context,
              'Karta ko‘rsatkichlari',
              'Карты и достижения',
              'Cards and recognition',
            ),
            caption: _copy(
              context,
              '${student.upCards + student.downCards} ta qayd',
              '${student.upCards + student.downCards} записей',
              '${student.upCards + student.downCards} records',
            ),
          ),
          const SizedBox(height: 8),
          SfSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                _CardMetric(
                  value: student.upCards,
                  label: _copy(context, 'Up karta', 'Up карты', 'Up cards'),
                  color: colors.success,
                ),
                const SizedBox(width: 10),
                _CardMetric(
                  value: student.downCards,
                  label: _copy(
                    context,
                    'Down karta',
                    'Down карты',
                    'Down cards',
                  ),
                  color: colors.danger,
                ),
                const SizedBox(width: 10),
                _CardMetric(
                  value: (student.upCards - student.downCards)
                      .clamp(0, 99)
                      .toInt(),
                  label: _copy(context, 'Balans', 'Баланс', 'Balance'),
                  color: colors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SfAiSurface(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SfAiBadge(
                  label: _copy(
                    context,
                    'O‘quvchi tahlili',
                    'Анализ ученика',
                    'Student insight',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  attendance >= 92
                      ? _copy(
                          context,
                          '${student.name} ${attendance.round()}% davomatni ushlab turibdi. ${student.upCards} ta ijobiy karta kuchli va barqaror ishtirokni ko‘rsatadi.',
                          '${student.name}: посещаемость ${attendance.round()}%. ${student.upCards} положительных карт показывают стабильную работу.',
                          '${student.name} is sustaining ${attendance.round()}% attendance. ${student.upCards} positive cards indicate reliable engagement.',
                        )
                      : _copy(
                          context,
                          '${student.name} bilan individual suhbat tavsiya etiladi: davomat ${attendance.round()}%, $absences ta qoldirilgan dars bor.',
                          'Рекомендуется личная беседа: посещаемость ${attendance.round()}%, пропусков — $absences.',
                          'Plan an individual check-in: attendance is ${attendance.round()}% with $absences missed lessons.',
                        ),
                  style: SfType.display(
                    size: 16,
                    color: colors.ink,
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SfSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                SfAvatar(name: student.name, size: 42),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _copy(context, 'Aloqa', 'Контакт', 'Contact'),
                        style: SfType.ui(
                          size: 12,
                          weight: FontWeight.w800,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        student.phone,
                        style: SfType.mono(size: 11, color: colors.primary),
                      ),
                    ],
                  ),
                ),
                SfButton(
                  kind: SfButtonKind.soft,
                  label: _copy(context, 'Ko‘rish', 'Открыть', 'View'),
                  onPressed: () => _showContact(context, student),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    _StudentAction action,
    TeacherGroup group,
    GroupStudent student,
  ) async {
    switch (action) {
      case _StudentAction.group:
        context.push('/cohort?id=${Uri.encodeQueryComponent(group.id)}');
      case _StudentAction.attendance:
        context.push(
          '/attendance?cohort=${Uri.encodeQueryComponent(group.id)}',
        );
      case _StudentAction.contact:
        await _showContact(context, student);
    }
  }
}

class _StudentHero extends StatelessWidget {
  const _StudentHero({
    required this.group,
    required this.student,
    required this.attendance,
  });

  final TeacherGroup group;
  final GroupStudent student;
  final double attendance;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              SfAvatar(name: student.name, size: 64, color: colors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      key: const ValueKey('student-profile-name'),
                      style: SfType.ui(
                        size: 20,
                        weight: FontWeight.w800,
                        color: colors.ink,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.id,
                      style: SfType.mono(size: 10.5, color: colors.muted),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SfPill(tone: SfPillTone.primary, label: group.name),
                        SfPill(tone: SfPillTone.accent, label: group.level),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroMetric(
                value: '${student.upCards}',
                label: _copy(context, 'Up karta', 'Up карты', 'Up cards'),
                color: colors.success,
              ),
              _HeroMetric(
                value: '${student.downCards}',
                label: _copy(context, 'Down karta', 'Down карты', 'Down cards'),
                color: colors.danger,
              ),
              _HeroMetric(
                value: '${attendance.round()}%',
                label: context.gt('attendance'),
                color: colors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: SfType.mono(
                size: 19,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.eyebrow(size: 8, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      haptic: true,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(
                size: 10,
                weight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SfType.ui(
              size: 14,
              weight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
        ),
        Text(caption, style: SfType.ui(size: 10, color: colors.muted)),
      ],
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.record,
    required this.status,
    required this.showDivider,
  });
  final GroupAttendanceRecord record;
  final AttendanceStatus status;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    final tone = switch (status) {
      AttendanceStatus.present => colors.success,
      AttendanceStatus.absent => colors.danger,
      AttendanceStatus.late => colors.warn,
      AttendanceStatus.excused => colors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.lessonTitle,
                  style: SfType.ui(
                    size: 12,
                    weight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                Text(
                  '${record.lessonAt.day}.${record.lessonAt.month.toString().padLeft(2, '0')}.${record.lessonAt.year} · ${record.lessonAt.hour.toString().padLeft(2, '0')}:${record.lessonAt.minute.toString().padLeft(2, '0')}',
                  style: SfType.mono(size: 9.5, color: colors.muted),
                ),
              ],
            ),
          ),
          SfPill(
            tone: status == AttendanceStatus.absent
                ? SfPillTone.danger
                : status == AttendanceStatus.late
                ? SfPillTone.warn
                : SfPillTone.success,
            label: _statusText(context, status),
          ),
        ],
      ),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: SfType.mono(
                size: 22,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(size: 9.5, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StudentAction { group, attendance, contact }

String _messageLocation(TeacherGroup group, GroupStudent student) => Uri(
  path: '/messages/new',
  queryParameters: {'group': group.id, 'student': student.id},
).toString();

Future<void> _showContact(BuildContext context, GroupStudent student) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SelectableText('${student.id}\n${student.phone}'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_copy(context, 'Tayyor', 'Готово', 'Done')),
          ),
        ],
      ),
    );

String _statusText(BuildContext context, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.present => context.gt('present'),
      AttendanceStatus.absent => context.gt('absent'),
      AttendanceStatus.late => context.gt('late'),
      AttendanceStatus.excused => context.gt('excused'),
    };

String _copy(BuildContext context, String uz, String ru, String en) =>
    switch (Localizations.localeOf(context).languageCode) {
      'en' => en,
      'ru' => ru,
      _ => uz,
    };
