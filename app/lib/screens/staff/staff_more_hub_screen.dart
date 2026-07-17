import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
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
    this.onOpenRoute,
    this.onSignOut,
  });

  final StaffRole role;
  final String? displayName;
  final String branchName;
  final int unreadMessages;
  final int unreadNotifications;
  final ValueChanged<String>? onOpenRoute;
  final VoidCallback? onSignOut;

  static const _destinations = [
    StaffMoreDestination(
      route: '/content',
      label: 'Materiallar',
      description: 'Dars fayllari va umumiy kutubxona',
      icon: SfIcons.folder,
    ),
    StaffMoreDestination(
      route: '/messages',
      label: 'Xabarlar',
      description: 'Xodimlar va boshqaruv bilan aloqa',
      icon: SfIcons.chat,
      capability: StaffCapability.useStaffMessaging,
      tone: StaffMetricTone.primary,
    ),
    StaffMoreDestination(
      route: '/surveys',
      label: 'So\u2018rovnomalar',
      description: 'Topshirilishi kerak bo\u2018lgan so\u2018rovlar',
      icon: SfIcons.flag,
      capability: StaffCapability.answerSurveys,
    ),
    StaffMoreDestination(
      route: '/print',
      label: 'Print',
      description: 'Filial printerlari va navbat',
      icon: SfIcons.printer,
      capability: StaffCapability.submitPrintJobs,
    ),
    StaffMoreDestination(
      route: '/cards',
      label: 'Kartalar',
      description: 'Up / Down kartalar va tarix',
      icon: SfIcons.brand,
      capability: StaffCapability.issueCards,
      tone: StaffMetricTone.accent,
    ),
    StaffMoreDestination(
      route: '/staff/quality',
      label: 'Ta\u2018lim sifati',
      description: 'Ustoz va guruh signallari',
      icon: Icons.school_outlined,
      capability: StaffCapability.viewQualityWorkspace,
      tone: StaffMetricTone.warning,
    ),
    StaffMoreDestination(
      route: '/staff/reception',
      label: 'Lidlar va qabul',
      description: 'Murojaatdan guruhgacha bo\u2018lgan oqim',
      icon: Icons.phone_in_talk_outlined,
      capability: StaffCapability.viewLeads,
      tone: StaffMetricTone.primary,
    ),
    StaffMoreDestination(
      route: '/payments',
      label: 'To\u2018lov holati',
      description: 'Qabulxona uchun to\u2018lov statuslari',
      icon: Icons.payments_outlined,
      capability: StaffCapability.viewPaymentStatus,
      tone: StaffMetricTone.success,
    ),
    StaffMoreDestination(
      route: '/staff/audit',
      label: 'Audit markazi',
      description: 'Signallar, holatlar va nazorat',
      icon: SfIcons.shield,
      capability: StaffCapability.viewAuditWorkspace,
      tone: StaffMetricTone.danger,
    ),
    StaffMoreDestination(
      route: '/staff/audit/log',
      label: 'O\u2018zgarmas jurnal',
      description: 'Yaxlitlik zanjiri va eksport',
      icon: SfIcons.doc,
      capability: StaffCapability.viewImmutableAuditLog,
    ),
    StaffMoreDestination(
      route: '/settings',
      label: 'Sozlamalar',
      description: 'Ko\u2018rinish, til va qulaylik',
      icon: SfIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _destinations
        .where((item) => item.capability == null || role.can(item.capability!))
        .toList();
    return StaffPageScaffold(
      eyebrow: '${role.uzLabel} · $branchName',
      title: 'Ko\u2018proq',
      subtitle: 'Sizga tegishli ish maydonlari va sozlamalar',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ProfileSummary(
            role: role,
            name: displayName ?? role.uzLabel,
            branch: branchName,
          ),
          const SizedBox(height: 14),
          StaffHintCard(
            title: 'Rol bo\u2018yicha xavfsiz',
            message: _capabilityMessage,
            icon: SfIcons.shield,
          ),
          const SizedBox(height: 20),
          const StaffSectionHeader(
            title: 'Ish maydonlari',
            subtitle: 'Faqat joriy rolingizga ruxsat berilgan bo\u2018limlar',
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(SfIcons.logout, size: 18),
            label: const Text('Tizimdan chiqish'),
          ),
        ],
      ),
    );
  }

  String get _capabilityMessage {
    return switch (role) {
      StaffRole.teacher || StaffRole.assistant || StaffRole.methodist =>
        'Moliyaviy ma\u2018lumotlar bu rolda yashirilgan. Bu yerda rol almashtirish tugmasi yo\u2018q.',
      StaffRole.reception =>
        'Faqat qabul uchun kerakli to\u2018lov holati ochiladi; audit va rahbariyat bo\u2018limlari yashirin.',
      StaffRole.auditor =>
        'Manba yozuvlari faqat o\u2018qiladi. Holatlar va tekshiruv qaydlarini yozish mumkin.',
    };
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.role,
    required this.name,
    required this.branch,
  });
  final StaffRole role;
  final String name;
  final String branch;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
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
                  '$branch · ${role.uzLabel}',
                  style: SfType.ui(size: 11.5, color: c.muted),
                ),
              ],
            ),
          ),
          const SfPill(tone: SfPillTone.success, label: 'Faol'),
        ],
      ),
    );
  }
}

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
