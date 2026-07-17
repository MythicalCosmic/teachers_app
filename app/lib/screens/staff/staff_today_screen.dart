import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_star.dart';
import 'staff_surface_widgets.dart';

class StaffTodayScreen extends StatelessWidget {
  const StaffTodayScreen({
    super.key,
    this.role = StaffRole.assistant,
    this.session,
    this.tasks = const [],
    this.attendanceSheets = const [],
    this.unreadMessages = 0,
    this.onCompleteTask,
    this.onOpenTask,
    this.onOpenPrimaryWorkspace,
    this.onOpenMessages,
    this.onRefresh,
  });

  final StaffRole role;
  final StaffSession? session;
  final List<StaffTask> tasks;
  final List<AttendanceSheet> attendanceSheets;
  final int unreadMessages;
  final Future<void> Function(String taskId)? onCompleteTask;
  final ValueChanged<String>? onOpenTask;
  final VoidCallback? onOpenPrimaryWorkspace;
  final VoidCallback? onOpenMessages;
  final Future<void> Function()? onRefresh;

  bool get _supported =>
      role == StaffRole.assistant ||
      role == StaffRole.methodist ||
      role == StaffRole.reception;

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const StaffPageScaffold(
        eyebrow: 'Bugun',
        title: 'Xodim paneli',
        subtitle: 'Bu ekran yordamchi, metodist va qabulxona oqimlari uchun',
        body: StaffEmptyState(
          title: 'Boshqa rol paneli',
          message:
              'Joriy rol uchun maxsus bosh ekran navigatsiya orqali ochiladi.',
          icon: SfIcons.cohort,
        ),
      );
    }
    final displayName =
        session?.displayName ??
        switch (role) {
          StaffRole.assistant => 'Sevara Olimova',
          StaffRole.methodist => 'Malika Yusupova',
          StaffRole.reception => 'Gulnora Saidova',
          _ => 'Xodim',
        };
    final branch = session?.branchName ?? 'Yunusobod';

    return StaffPageScaffold(
      eyebrow: '${role.uzLabel} · $branch',
      title: 'Bugun, ${displayName.split(' ').first}',
      subtitle: _subtitle,
      actions: [
        StaffIconButton(
          icon: SfIcons.chat,
          tooltip: 'Xabarlar',
          badge: unreadMessages,
          onPressed: onOpenMessages,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _RoleHero(role: role, onOpen: onOpenPrimaryWorkspace),
            const SizedBox(height: 12),
            _metrics(context),
            const SizedBox(height: 14),
            StaffHintCard(
              title: _hintTitle,
              message: _hintMessage,
              icon: _hintIcon,
            ),
            const SizedBox(height: 20),
            StaffSectionHeader(
              title: 'Navbatdagi ishlar',
              subtitle: tasks.isEmpty
                  ? 'Bugungi vazifalar tugadi'
                  : '${tasks.where((task) => task.status != TaskStatus.done).length} ta faol vazifa',
            ),
            const SizedBox(height: 10),
            if (tasks.where((task) => task.status != TaskStatus.done).isEmpty)
              const StaffEmptyState(
                title: 'Hammasi joyida',
                message:
                    'Yangi vazifa kelganda u shu yerda ustuvorlik va muddat bilan ko\u2018rinadi.',
                icon: SfIcons.check,
              )
            else
              SfSurfaceCard(
                child: Column(
                  children: [
                    for (final task
                        in tasks
                            .where((task) => task.status != TaskStatus.done)
                            .take(5)) ...[
                      _TodayTaskRow(
                        task: task,
                        onComplete: onCompleteTask,
                        onOpen: onOpenTask,
                      ),
                      if (task !=
                          tasks
                              .where((item) => item.status != TaskStatus.done)
                              .take(5)
                              .last)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get _subtitle => switch (role) {
    StaffRole.assistant =>
      'Darsga tayyorgarlik va davomat — keraksiz shovqinsiz',
    StaffRole.methodist => 'Sifat signallari va ustozlarga amaliy yordam',
    StaffRole.reception =>
      'Murojaatlarni o\u2018tkazib yubormang, qabul oqimini ravon tuting',
    _ => '',
  };

  String get _hintTitle => switch (role) {
    StaffRole.assistant => 'Darsdan 10 daqiqa oldin',
    StaffRole.methodist => 'Avval kontekst, keyin xulosa',
    StaffRole.reception => 'Tez javob — qulay boshlanish',
    _ => '',
  };

  String get _hintMessage => switch (role) {
    StaffRole.assistant =>
      'Ro\u2018yxat va materiallarni tekshiring. Yordamchi rolida moliyaviy maydonlar ko\u2018rsatilmaydi.',
    StaffRole.methodist =>
      'Signalni dars va guruh holati bilan tekshiring. Bu rolda moliyaviy ma\u2018lumotlar yashirilgan.',
    StaffRole.reception =>
      'Yangi lidga 15 daqiqa ichida qo\u2018ng\u2018iroq qilib, keyingi qadamni belgilang.',
    _ => '',
  };

  IconData get _hintIcon => switch (role) {
    StaffRole.assistant => SfIcons.cal,
    StaffRole.methodist => Icons.school_outlined,
    StaffRole.reception => Icons.phone_in_talk_outlined,
    _ => SfIcons.check,
  };

  Widget _metrics(BuildContext context) {
    final pendingAttendance = attendanceSheets
        .where((sheet) => !sheet.isSubmitted)
        .length;
    final activeTasks = tasks
        .where((task) => task.status != TaskStatus.done)
        .length;
    final urgentTasks = tasks
        .where(
          (task) =>
              task.status != TaskStatus.done &&
              task.priority == TaskPriority.urgent,
        )
        .length;
    final metrics = switch (role) {
      StaffRole.assistant => [
        StaffMetricCard(
          label: 'Bugungi dars',
          value: '${attendanceSheets.length}',
          detail: 'Biriktirilgan guruhlar',
          icon: SfIcons.book,
          tone: StaffMetricTone.primary,
        ),
        StaffMetricCard(
          label: 'Davomat kutmoqda',
          value: '$pendingAttendance',
          detail: 'Topshirish kerak',
          icon: SfIcons.check,
          tone: pendingAttendance > 0
              ? StaffMetricTone.warning
              : StaffMetricTone.success,
        ),
        StaffMetricCard(
          label: 'Faol vazifa',
          value: '$activeTasks',
          detail: 'Shaxsiy ish navbati',
          icon: SfIcons.doc,
          tone: StaffMetricTone.neutral,
        ),
      ],
      StaffRole.methodist => [
        StaffMetricCard(
          label: 'Sifat signali',
          value: '${(urgentTasks + 2).clamp(0, 99)}',
          detail: 'Ko\u2018rib chiqish kerak',
          icon: SfIcons.flag,
          tone: StaffMetricTone.warning,
        ),
        StaffMetricCard(
          label: 'Kuzatuv vazifasi',
          value: '$activeTasks',
          detail: 'Ustozlar bilan ishlash',
          icon: SfIcons.doc,
          tone: StaffMetricTone.primary,
        ),
        const StaffMetricCard(
          label: 'Barqaror guruh',
          value: '24',
          detail: 'Ijobiy yo\u2018nalishda',
          icon: Icons.trending_up,
          tone: StaffMetricTone.success,
        ),
      ],
      StaffRole.reception => [
        const StaffMetricCard(
          label: 'Yangi lid',
          value: '6',
          detail: 'Bugun javob kutmoqda',
          icon: SfIcons.plus,
          tone: StaffMetricTone.danger,
        ),
        const StaffMetricCard(
          label: 'Sinov darsi',
          value: '4',
          detail: 'Vaqti belgilangan',
          icon: SfIcons.cal,
          tone: StaffMetricTone.primary,
        ),
        const StaffMetricCard(
          label: 'Qabulga tayyor',
          value: '3',
          detail: 'Guruh tanlash kerak',
          icon: SfIcons.check,
          tone: StaffMetricTone.accent,
        ),
      ],
      _ => <Widget>[],
    };
    return StaffAdaptiveGrid(children: metrics);
  }
}

class _RoleHero extends StatelessWidget {
  const _RoleHero({required this.role, this.onOpen});

  final StaffRole role;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final (eyebrow, title, subtitle, action, icon) = switch (role) {
      StaffRole.assistant => (
        'KEYINGI · 14 DAQIQA',
        'Algebra · 9-B',
        '09:00–09:45 · 304-xona · 24 o\u2018quvchi',
        'Davomatni ochish',
        SfIcons.check,
      ),
      StaffRole.methodist => (
        'BUGUNGI E\u2018TIBOR',
        '2 ta sifat signali',
        'Ustoz bilan suhbat uchun kontekst tayyor',
        'Sifat maydoni',
        Icons.school_outlined,
      ),
      StaffRole.reception => (
        'BIRINCHI NAVBATDA',
        '6 lidga javob kerak',
        'Eng eski murojaat · 18 daqiqa oldin',
        'Lidlarni ochish',
        Icons.phone_in_talk_outlined,
      ),
      _ => ('BUGUN', 'Ish maydoni', '', 'Ochish', SfIcons.arrowR),
    };
    return Semantics(
      button: onOpen != null,
      label: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.primary, c.primaryHover]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -38,
              child: Opacity(
                opacity: 0.14,
                child: SfStar(size: 150, color: c.surface),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: SfType.eyebrow(
                    color: c.surface.withValues(alpha: 0.82),
                    size: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: SfType.ui(
                    size: 22,
                    weight: FontWeight.w800,
                    color: c.surface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: SfType.ui(
                    size: 12,
                    color: c.surface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                SfButton(
                  label: action,
                  leading: icon,
                  fontSize: 12.5,
                  overrideBg: c.surface,
                  overrideFg: c.primary,
                  onPressed: onOpen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTaskRow extends StatelessWidget {
  const _TodayTaskRow({required this.task, this.onComplete, this.onOpen});

  final StaffTask task;
  final Future<void> Function(String taskId)? onComplete;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final urgent =
        task.priority == TaskPriority.urgent ||
        task.priority == TaskPriority.high;
    return StaffStatusRow(
      icon: urgent ? SfIcons.flag : SfIcons.check,
      title: task.title,
      subtitle:
          '${task.creatorName} · ${task.completedSteps}/${task.checklist.length} qadam',
      tone: urgent ? StaffMetricTone.danger : StaffMetricTone.primary,
      onTap: onOpen == null ? null : () => onOpen!(task.id),
      trailing: IconButton(
        tooltip: 'Bajarildi deb belgilash',
        onPressed: onComplete == null ? null : () => onComplete!(task.id),
        icon: Icon(Icons.check_circle_outline, color: c.success),
      ),
    );
  }
}
