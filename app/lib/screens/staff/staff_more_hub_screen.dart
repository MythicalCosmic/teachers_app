import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../features/operations/staff_operations_controller.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_pressable.dart';
import 'staff_surface_widgets.dart';

final class StaffMoreDestination {
  const StaffMoreDestination({
    required this.route,
    required this.label,
    required this.description,
    required this.icon,
    this.capability,
    this.tone = StaffMetricTone.neutral,
  });

  final String route;
  final String label;
  final String description;
  final IconData icon;
  final StaffCapability? capability;
  final StaffMetricTone tone;
}

class StaffMoreHubScreen extends StatelessWidget {
  const StaffMoreHubScreen({
    super.key,
    required this.role,
    this.displayName,
    this.branchName = 'Yunusobod',
    this.unreadMessages = 0,
    this.unreadNotifications = 0,
    this.canAccess,
    this.onOpenRoute,
    this.onSignOut,
  });

  final StaffRole role;
  final String? displayName;
  final String branchName;
  final int unreadMessages;
  final int unreadNotifications;
  final bool Function(StaffCapability capability)? canAccess;
  final ValueChanged<String>? onOpenRoute;
  final VoidCallback? onSignOut;

  List<StaffMoreDestination> _destinations(BuildContext context) => [
    StaffMoreDestination(
      route: '/staff/operations',
      label: _copy(
        context,
        uz: 'Xodim xizmatlari',
        ru: 'Сервисы сотрудников',
        en: 'Staff services',
      ),
      description: _copy(
        context,
        uz: 'Ruxsat etilgan ish jarayonlari va markaz vositalari',
        ru: 'Доступные рабочие процессы и инструменты центра',
        en: 'Your permitted workflows and center tools',
      ),
      icon: Icons.dashboard_customize_outlined,
      capability: StaffCapability.viewStaffServices,
      tone: StaffMetricTone.primary,
    ),
    StaffMoreDestination(
      route: '/content',
      label: _copy(
        context,
        uz: 'Materiallar',
        ru: 'Материалы',
        en: 'Materials',
      ),
      description: _copy(
        context,
        uz: 'Dars fayllari va umumiy kutubxona',
        ru: 'Файлы уроков и общая библиотека',
        en: 'Lesson files and the shared library',
      ),
      icon: SfIcons.folder,
      capability: StaffCapability.viewContent,
    ),
    StaffMoreDestination(
      route: '/ai',
      label: 'StarForge AI',
      description: _copy(
        context,
        uz: 'Imtihon loyihalari va AI so‘rovlari',
        ru: 'Черновики экзаменов и AI-запросы',
        en: 'Exam drafts and AI request history',
      ),
      icon: SfIcons.ai,
      capability: StaffCapability.useAi,
      tone: StaffMetricTone.accent,
    ),
    StaffMoreDestination(
      route: '/messages',
      label: _copy(context, uz: 'Xabarlar', ru: 'Сообщения', en: 'Messages'),
      description: _copy(
        context,
        uz: 'Xodimlar va boshqaruv bilan aloqa',
        ru: 'Связь с сотрудниками',
        en: 'Conversations with other staff',
      ),
      icon: SfIcons.chat,
      capability: StaffCapability.useStaffMessaging,
      tone: StaffMetricTone.primary,
    ),
    StaffMoreDestination(
      route: '/surveys',
      label: _copy(context, uz: 'So‘rovnomalar', ru: 'Опросы', en: 'Surveys'),
      description: _copy(
        context,
        uz: 'Topshirilishi kerak bo‘lgan so‘rovlar',
        ru: 'Опросы, ожидающие ответа',
        en: 'Surveys waiting for your response',
      ),
      icon: SfIcons.flag,
      capability: StaffCapability.answerSurveys,
    ),
    StaffMoreDestination(
      route: '/print',
      label: 'Print',
      description: _copy(
        context,
        uz: 'Filial printerlari va navbat',
        ru: 'Принтеры филиала и очередь',
        en: 'Branch printers and queue',
      ),
      icon: SfIcons.printer,
      capability: StaffCapability.submitPrintJobs,
    ),
    StaffMoreDestination(
      route: '/cards',
      label: _copy(context, uz: 'E’tirof', ru: 'Признание', en: 'Recognition'),
      description: _copy(
        context,
        uz: 'O‘quvchi e’tirofi va tarix',
        ru: 'Награды учеников и история',
        en: 'Student recognition and history',
      ),
      icon: SfIcons.brand,
      capability: StaffCapability.issueCards,
      tone: StaffMetricTone.accent,
    ),
    StaffMoreDestination(
      route: '/staff/quality',
      label: _copy(
        context,
        uz: 'Ta’lim sifati',
        ru: 'Качество обучения',
        en: 'Teaching quality',
      ),
      description: _copy(
        context,
        uz: 'Ustoz va guruh signallari',
        ru: 'Сигналы преподавателей и групп',
        en: 'Teacher and group quality signals',
      ),
      icon: Icons.school_outlined,
      capability: StaffCapability.viewQualityWorkspace,
      tone: StaffMetricTone.warning,
    ),
    StaffMoreDestination(
      route: '/staff/reception',
      label: _copy(
        context,
        uz: 'Lidlar va qabul',
        ru: 'Лиды и приём',
        en: 'Leads and reception',
      ),
      description: _copy(
        context,
        uz: 'Murojaatdan guruhgacha bo‘lgan oqim',
        ru: 'Путь от обращения до группы',
        en: 'The flow from inquiry to group',
      ),
      icon: Icons.phone_in_talk_outlined,
      capability: StaffCapability.viewLeads,
      tone: StaffMetricTone.primary,
    ),
    StaffMoreDestination(
      route: '/payments',
      label: _copy(
        context,
        uz: 'To‘lov holati',
        ru: 'Статус оплаты',
        en: 'Payment status',
      ),
      description: _copy(
        context,
        uz: 'Qabulxona uchun to‘lov statuslari',
        ru: 'Статусы оплаты для приёмной',
        en: 'Payment status for reception staff',
      ),
      icon: Icons.payments_outlined,
      capability: StaffCapability.viewPaymentStatus,
      tone: StaffMetricTone.success,
    ),
    StaffMoreDestination(
      route: '/staff/audit',
      label: _copy(
        context,
        uz: 'Audit markazi',
        ru: 'Центр аудита',
        en: 'Audit center',
      ),
      description: _copy(
        context,
        uz: 'Signallar, holatlar va nazorat',
        ru: 'Сигналы, кейсы и контроль',
        en: 'Signals, cases and controls',
      ),
      icon: SfIcons.shield,
      capability: StaffCapability.viewAuditWorkspace,
      tone: StaffMetricTone.danger,
    ),
    StaffMoreDestination(
      route: '/staff/audit/log',
      label: _copy(
        context,
        uz: 'O‘zgarmas jurnal',
        ru: 'Неизменяемый журнал',
        en: 'Immutable log',
      ),
      description: _copy(
        context,
        uz: 'Yaxlitlik zanjiri va eksport',
        ru: 'Цепочка целостности и экспорт',
        en: 'Integrity chain and export',
      ),
      icon: SfIcons.doc,
      capability: StaffCapability.viewImmutableAuditLog,
    ),
    StaffMoreDestination(
      route: '/settings',
      label: _copy(context, uz: 'Sozlamalar', ru: 'Настройки', en: 'Settings'),
      description: _copy(
        context,
        uz: 'Ko‘rinish, til va qulaylik',
        ru: 'Оформление, язык и комфорт',
        en: 'Appearance, language and comfort',
      ),
      icon: SfIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.maybeOf(context);
    bool can(StaffCapability capability) =>
        canAccess?.call(capability) ??
        app?.can(capability) ??
        role.can(capability);
    final allVisible = _destinations(context)
        .where((item) => item.capability == null || can(item.capability!))
        .toList();
    final staffServices = allVisible
        .where((item) => item.route == '/staff/operations')
        .firstOrNull;
    final visible = allVisible
        .where((item) => item.route != '/staff/operations')
        .toList(growable: false);
    final serviceCount = staffOperationModules
        .where((module) => can(module.requiredCapability))
        .length;
    return StaffPageScaffold(
      eyebrow: '${_roleLabel(context, role)} · $branchName',
      title: _copy(context, uz: 'Ko‘proq', ru: 'Ещё', en: 'More'),
      subtitle: _copy(
        context,
        uz: 'Sizga tegishli ish maydonlari va sozlamalar',
        ru: 'Ваши рабочие пространства и настройки',
        en: 'Your staff workspaces and personal settings',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ProfileSummary(
            role: role,
            name: displayName ?? role.uzLabel,
            branch: branchName,
            onTap: onOpenRoute == null
                ? null
                : () => onOpenRoute!('/settings/edit'),
          ),
          const SizedBox(height: 14),
          if (staffServices != null) ...[
            _StaffServicesHero(
              destination: staffServices,
              serviceCount: serviceCount,
              onTap: onOpenRoute == null
                  ? null
                  : () => onOpenRoute!(staffServices.route),
            ),
            const SizedBox(height: 20),
          ],
          StaffSectionHeader(
            title: _copy(
              context,
              uz: 'Boshqa ish maydonlari',
              ru: 'Другие рабочие пространства',
              en: 'Other workspaces',
            ),
            subtitle: _copy(
              context,
              uz: 'Faqat joriy rolingizga ruxsat berilgan bo‘limlar',
              ru: 'Только разрешённые для вашей роли разделы',
              en: 'Only areas permitted for your current role',
            ),
          ),
          const SizedBox(height: 10),
          SfSurfaceCard(
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _MoreRow(
                    destination: visible[i],
                    badge: visible[i].route == '/messages'
                        ? unreadMessages
                        : visible[i].route == '/notifications'
                        ? unreadNotifications
                        : 0,
                    onTap: onOpenRoute == null
                        ? null
                        : () => onOpenRoute!(visible[i].route),
                  ),
                  if (i < visible.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          StaffHintCard(
            title: _copy(
              context,
              uz: 'Rol bo‘yicha xavfsiz',
              ru: 'Безопасно для роли',
              en: 'Role-safe by design',
            ),
            message: _capabilityMessage(context),
            icon: SfIcons.shield,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(SfIcons.logout, size: 18),
            label: Text(
              _copy(
                context,
                uz: 'Tizimdan chiqish',
                ru: 'Выйти',
                en: 'Sign out',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capabilityMessage(BuildContext context) {
    return switch (role) {
      StaffRole.teacher || StaffRole.assistant || StaffRole.methodist => _copy(
        context,
        uz: 'Moliyaviy ma’lumotlar bu rolda yashirilgan. Bu yerda rol almashtirish tugmasi yo‘q.',
        ru: 'Финансовые данные скрыты для этой роли. Переключателя роли здесь нет.',
        en: 'Financial data is hidden for this role, and there is no role switcher.',
      ),
      StaffRole.reception => _copy(
        context,
        uz: 'Faqat qabul uchun kerakli to‘lov holati ochiladi; audit bo‘limlari yashirin.',
        ru: 'Открыты только нужные приёмной статусы оплаты; аудит скрыт.',
        en: 'Only reception payment status is available; audit areas stay hidden.',
      ),
      StaffRole.auditor => _copy(
        context,
        uz: 'Manba yozuvlari faqat o‘qiladi. Holatlar va tekshiruv qaydlarini yozish mumkin.',
        ru: 'Исходные записи доступны только для чтения; кейсы и заметки можно добавлять.',
        en: 'Source records are read-only; cases and review notes can be added.',
      ),
    };
  }
}

class _StaffServicesHero extends StatelessWidget {
  const _StaffServicesHero({
    required this.destination,
    required this.serviceCount,
    this.onTap,
  });

  final StaffMoreDestination destination;
  final int serviceCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return SfPressable(
      key: const ValueKey('staff-services-featured'),
      semanticLabel: _copy(
        context,
        uz: '${destination.label}. $serviceCount ta ruxsat etilgan xizmat. Ochish.',
        ru: '${destination.label}. Доступно сервисов: $serviceCount. Открыть.',
        en: '${destination.label}. $serviceCount permitted services. Open.',
      ),
      onPressed: onTap,
      haptic: true,
      borderRadius: BorderRadius.circular(25),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 17, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              state.pressed ? c.primaryHover : c.primary,
              Color.alphaBlend(c.ai.withValues(alpha: .36), c.primary),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: state.pressed ? .10 : .22),
              blurRadius: state.pressed ? 10 : 22,
              offset: Offset(0, state.pressed ? 4 : 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -45,
              child: Icon(
                Icons.dashboard_customize_rounded,
                size: 154,
                color: onPrimary.withValues(alpha: .08),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: onPrimary.withValues(alpha: .18),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(destination.icon, color: onPrimary, size: 23),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            size: 13,
                            color: onPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _copy(
                              context,
                              uz: '$serviceCount TA OCHIQ',
                              ru: 'ДОСТУПНО: $serviceCount',
                              en: '$serviceCount OPEN',
                            ),
                            style: SfType.eyebrow(size: 8.5, color: onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  _copy(
                    context,
                    uz: 'ASOSIY ISH MARKAZI',
                    ru: 'ГЛАВНЫЙ РАБОЧИЙ ЦЕНТР',
                    en: 'PRIMARY WORK CENTER',
                  ),
                  style: SfType.eyebrow(
                    size: 9,
                    color: onPrimary.withValues(alpha: .76),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  style: SfType.ui(
                    size: 21,
                    weight: FontWeight.w900,
                    color: onPrimary,
                    letterSpacing: -.45,
                  ),
                ),
                const SizedBox(height: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 310),
                  child: Text(
                    destination.description,
                    style: SfType.ui(
                      size: 11.5,
                      height: 1.38,
                      color: onPrimary.withValues(alpha: .83),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
                  decoration: BoxDecoration(
                    color: onPrimary.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: onPrimary.withValues(alpha: .13)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 17,
                        color: onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _copy(
                            context,
                            uz: 'Faqat sizga ruxsat berilgan vositalar',
                            ru: 'Только разрешённые вам инструменты',
                            en: 'Only tools permitted for your account',
                          ),
                          style: SfType.ui(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: onPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.role,
    required this.name,
    required this.branch,
    this.onTap,
  });
  final StaffRole role;
  final String name;
  final String branch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onTap,
      semanticLabel: _copy(
        context,
        uz: 'Profilni ochish',
        ru: 'Открыть профиль',
        en: 'Open profile',
      ),
      borderRadius: BorderRadius.circular(22),
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: SfType.ui(
                  size: 18,
                  weight: FontWeight.w800,
                  color: c.surface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: SfType.ui(
                      size: 15,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$branch · ${_roleLabel(context, role)}',
                    style: SfType.ui(size: 11.5, color: c.muted),
                  ),
                ],
              ),
            ),
            SfPill(
              tone: SfPillTone.success,
              label: _copy(context, uz: 'Faol', ru: 'Активен', en: 'Active'),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(BuildContext context, StaffRole role) =>
    Localizations.localeOf(context).languageCode == 'en'
    ? role.label
    : role.uzLabel;

String _copy(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (Localizations.localeOf(context).languageCode) {
  'ru' => ru,
  'en' => en,
  _ => uz,
};

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.destination, required this.badge, this.onTap});
  final StaffMoreDestination destination;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StaffStatusRow(
      icon: destination.icon,
      title: destination.label,
      subtitle: destination.description,
      tone: destination.tone,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0) ...[
            SfPill(tone: SfPillTone.danger, label: '$badge'),
            const SizedBox(width: 4),
          ],
          const Icon(SfIcons.chevR, size: 18),
        ],
      ),
    );
  }
}
