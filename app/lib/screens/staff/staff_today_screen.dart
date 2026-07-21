import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_star.dart';
import 'staff_surface_widgets.dart';
import 'staff_workspace_models.dart';

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
    this.refreshStore,
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
  final StaffWorkspaceRefreshStore? refreshStore;

  bool get _supported =>
      role == StaffRole.assistant ||
      role == StaffRole.methodist ||
      role == StaffRole.reception;

  bool get _canViewLeads =>
      session?.can(StaffCapability.viewLeads) ??
      role.can(StaffCapability.viewLeads);

  @override
  Widget build(BuildContext context) {
    final store = refreshStore;
    if (store == null) return _buildScreen(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
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
    final roleLabel = role == StaffRole.reception && !_canViewLeads
        ? 'Xodim'
        : role.uzLabel;

    return StaffPageScaffold(
      eyebrow: '$roleLabel · $branch',
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
      body: _TodayRefreshableBody(
        onRefresh: onRefresh ?? refreshStore?.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (refreshStore != null) ...[
              _TodayRefreshStatus(store: refreshStore!),
              const SizedBox(height: 10),
            ],
            _RoleHero(
              role: role,
              canViewLeads: _canViewLeads,
              activeTasks: tasks
                  .where((task) => task.status != TaskStatus.done)
                  .length,
              urgentTasks: tasks
                  .where(
                    (task) =>
                        task.status != TaskStatus.done &&
                        (task.priority == TaskPriority.high ||
                            task.priority == TaskPriority.urgent),
                  )
                  .length,
              attendanceCount: attendanceSheets.length,
              pendingAttendance: attendanceSheets
                  .where((sheet) => !sheet.isSubmitted)
                  .length,
              unreadMessages: unreadMessages,
              onOpen: onOpenPrimaryWorkspace,
            ),
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
      _canViewLeads
          ? 'Murojaatlarni o\u2018tkazib yubormang, qabul oqimini ravon tuting'
          : 'Ruxsat etilgan xizmatlar va kundalik ishlar bir joyda',
    _ => '',
  };

  String get _hintTitle => switch (role) {
    StaffRole.assistant => 'Darsdan 10 daqiqa oldin',
    StaffRole.methodist => 'Avval kontekst, keyin xulosa',
    StaffRole.reception =>
      _canViewLeads ? 'Tez javob — qulay boshlanish' : 'Muhim ishlar bir joyda',
    _ => '',
  };

  String get _hintMessage => switch (role) {
    StaffRole.assistant =>
      'Ro\u2018yxat va materiallarni tekshiring. Yordamchi rolida moliyaviy maydonlar ko\u2018rsatilmaydi.',
    StaffRole.methodist =>
      'Signalni dars va guruh holati bilan tekshiring. Bu rolda moliyaviy ma\u2018lumotlar yashirilgan.',
    StaffRole.reception =>
      _canViewLeads
          ? 'Yangi lidga 15 daqiqa ichida qo\u2018ng\u2018iroq qilib, keyingi qadamni belgilang.'
          : 'Hisobingizga ochiq xizmatlarni tanlang va navbatdagi vazifani davom ettiring.',
    _ => '',
  };

  IconData get _hintIcon => switch (role) {
    StaffRole.assistant => SfIcons.cal,
    StaffRole.methodist => Icons.school_outlined,
    StaffRole.reception =>
      _canViewLeads ? Icons.phone_in_talk_outlined : Icons.grid_view_rounded,
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
              (task.priority == TaskPriority.high ||
                  task.priority == TaskPriority.urgent),
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
          label: 'Ustuvor vazifa',
          value: '$urgentTasks',
          detail: urgentTasks == 0
              ? 'Hammasi joyida'
              : 'Ko\u2018rib chiqish kerak',
          icon: SfIcons.flag,
          tone: urgentTasks == 0
              ? StaffMetricTone.success
              : StaffMetricTone.warning,
        ),
        StaffMetricCard(
          label: 'Kuzatuv vazifasi',
          value: '$activeTasks',
          detail: 'Ustozlar bilan ishlash',
          icon: SfIcons.doc,
          tone: StaffMetricTone.primary,
        ),
        StaffMetricCard(
          label: 'Yangi xabar',
          value: '$unreadMessages',
          detail: unreadMessages == 0
              ? 'Xabarlar o\u2018qilgan'
              : 'Javob kutmoqda',
          icon: SfIcons.chat,
          tone: unreadMessages == 0
              ? StaffMetricTone.success
              : StaffMetricTone.accent,
        ),
      ],
      StaffRole.reception => [
        StaffMetricCard(
          label: 'Faol vazifa',
          value: '$activeTasks',
          detail: activeTasks == 0 ? 'Navbat toza' : 'Ish navbatida',
          icon: SfIcons.doc,
          tone: activeTasks == 0
              ? StaffMetricTone.success
              : StaffMetricTone.primary,
        ),
        StaffMetricCard(
          label: 'Ustuvor vazifa',
          value: '$urgentTasks',
          detail: urgentTasks == 0
              ? 'Shoshilinch ish yo\u2018q'
              : 'Tez javob kerak',
          icon: SfIcons.flag,
          tone: urgentTasks == 0
              ? StaffMetricTone.success
              : StaffMetricTone.danger,
        ),
        StaffMetricCard(
          label: 'Yangi xabar',
          value: '$unreadMessages',
          detail: unreadMessages == 0
              ? 'Xabarlar o\u2018qilgan'
              : 'Javob kutmoqda',
          icon: SfIcons.chat,
          tone: unreadMessages == 0
              ? StaffMetricTone.success
              : StaffMetricTone.accent,
        ),
      ],
      _ => <Widget>[],
    };
    return StaffAdaptiveGrid(children: metrics);
  }
}

class _TodayRefreshableBody extends StatelessWidget {
  const _TodayRefreshableBody({required this.onRefresh, required this.child});

  final Future<void> Function()? onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final refresh = onRefresh;
    return refresh == null
        ? child
        : RefreshIndicator(onRefresh: refresh, child: child);
  }
}

class _TodayRefreshStatus extends StatelessWidget {
  const _TodayRefreshStatus({required this.store});

  final StaffWorkspaceRefreshStore store;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: staffMotionDuration(context),
        child: Text(
          store.refreshing
              ? _todayText(
                  context,
                  uz: 'Ma\u2018lumotlar yangilanmoqda…',
                  en: 'Refreshing data…',
                )
              : '${_todayText(context, uz: 'Yangilandi', en: 'Updated')} · ${_todayRefreshTime(store.lastUpdatedAt)} · #${store.revision}',
          key: ValueKey(
            'staff-today-refresh-${store.revision}-${store.refreshing}',
          ),
          style: SfType.mono(
            size: 10.5,
            color: store.refreshing ? c.primary : c.muted,
          ),
        ),
      ),
    );
  }
}

String _todayRefreshTime(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String _todayText(
  BuildContext context, {
  required String uz,
  required String en,
}) => Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;

class _RoleHero extends StatelessWidget {
  const _RoleHero({
    required this.role,
    required this.canViewLeads,
    required this.activeTasks,
    required this.urgentTasks,
    required this.attendanceCount,
    required this.pendingAttendance,
    required this.unreadMessages,
    this.onOpen,
  });

  final StaffRole role;
  final bool canViewLeads;
  final int activeTasks;
  final int urgentTasks;
  final int attendanceCount;
  final int pendingAttendance;
  final int unreadMessages;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final (eyebrow, title, subtitle, action, icon) = switch (role) {
      StaffRole.assistant => (
        pendingAttendance == 0 ? 'BUGUN TAYYOR' : 'DAVOMAT KUTMOQDA',
        pendingAttendance == 0
            ? 'Bugungi ishlar nazoratda'
            : '$pendingAttendance ta davomat varaqasi',
        attendanceCount == 0
            ? 'Hozircha biriktirilgan dars yo\u2018q'
            : '$attendanceCount ta biriktirilgan dars · $activeTasks ta faol vazifa',
        pendingAttendance == 0 ? 'Guruhlarni ochish' : 'Davomatni ochish',
        pendingAttendance == 0 ? SfIcons.cohort : SfIcons.check,
      ),
      StaffRole.methodist => (
        urgentTasks == 0 ? 'BUGUN NAZORATDA' : 'BUGUNGI E\u2018TIBOR',
        urgentTasks == 0
            ? 'Ustuvor signal yo\u2018q'
            : '$urgentTasks ta ustuvor vazifa',
        activeTasks == 0
            ? 'Yangi vazifa kelganda shu yerda ko\u2018rinadi'
            : '$activeTasks ta faol vazifa · $unreadMessages ta yangi xabar',
        'Sifat maydoni',
        Icons.school_outlined,
      ),
      StaffRole.reception when canViewLeads => (
        urgentTasks == 0 ? 'QABUL ISH MAYDONI' : 'BIRINCHI NAVBATDA',
        urgentTasks == 0 ? 'Navbat tartibda' : '$urgentTasks ta ustuvor vazifa',
        '$activeTasks ta faol vazifa · $unreadMessages ta yangi xabar',
        'Lidlarni ochish',
        Icons.phone_in_talk_outlined,
      ),
      StaffRole.reception => (
        urgentTasks == 0 ? 'XODIM XIZMATLARI' : 'BIRINCHI NAVBATDA',
        urgentTasks == 0
            ? 'Ruxsat etilgan vositalar tayyor'
            : '$urgentTasks ta ustuvor vazifa',
        '$activeTasks ta faol vazifa · $unreadMessages ta yangi xabar',
        'Xizmatlarni ochish',
        Icons.grid_view_rounded,
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
