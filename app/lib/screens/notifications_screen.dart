import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../utils/formatters.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

enum _NotificationFilter { all, message, print, work }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  bool _matches(StaffNotification notification) => switch (_filter) {
    _NotificationFilter.all => true,
    _NotificationFilter.message =>
      notification.category == NotificationCategory.message,
    _NotificationFilter.print =>
      notification.category == NotificationCategory.print,
    _NotificationFilter.work =>
      notification.category == NotificationCategory.task ||
          notification.category == NotificationCategory.attendance ||
          notification.category == NotificationCategory.survey ||
          notification.category == NotificationCategory.audit,
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    final allowed = app.notifications
        .where((notification) {
          if (notification.category != NotificationCategory.audit) return true;
          return session?.can(StaffCapability.viewAuditWorkspace) ?? false;
        })
        .toList(growable: false);
    final visible = allowed.where(_matches).toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unread = allowed.where((notification) => !notification.isRead).length;

    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Bildirishnomalar',
            subtitle: '${allowed.length} ta · $unread ta yangi',
            leading: IconButton(
              tooltip: 'Ortga',
              onPressed: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : null,
              icon: const Icon(SfIcons.arrowL),
            ),
            actions: [
              IconButton(
                tooltip: 'Hammasini o‘qilgan qilish',
                onPressed: unread == 0
                    ? null
                    : () {
                        app.markAllNotificationsRead();
                        SfToast.show(
                          context,
                          message: 'Barcha bildirishnomalar o‘qildi',
                          tone: SfToastTone.success,
                          glassEnabled: app.settings.liquidGlass,
                          motionEnabled: !app.settings.reducedMotion,
                        );
                      },
                icon: const Icon(SfIcons.check),
              ),
            ],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SfSegmentedControl<_NotificationFilter>(
              expanded: true,
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              segments: const [
                SfSegment(value: _NotificationFilter.all, label: 'Hammasi'),
                SfSegment(value: _NotificationFilter.message, label: 'Xabar'),
                SfSegment(value: _NotificationFilter.print, label: 'Print'),
                SfSegment(value: _NotificationFilter.work, label: 'Ish'),
              ],
            ),
          ),
        ],
      ),
      body: visible.isEmpty
          ? SfEmptyState(
              title: 'Bildirishnoma yo‘q',
              message: 'Tanlangan bo‘limda yangi xabar topilmadi.',
              icon: SfIcons.bell,
              actionLabel: _filter == _NotificationFilter.all
                  ? null
                  : 'Filtrni tozalash',
              onAction: _filter == _NotificationFilter.all
                  ? null
                  : () => setState(() => _filter = _NotificationFilter.all),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = visible[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () {
                    if (!notification.isRead) {
                      app.markNotificationRead(notification.id);
                    }
                    final route = notification.route;
                    if (route != null && route.isNotEmpty) context.push(route);
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final StaffNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final style = switch (notification.category) {
      NotificationCategory.message => (c.accent, c.accentSoft, SfIcons.chat),
      NotificationCategory.print => (c.success, c.successSoft, SfIcons.printer),
      NotificationCategory.attendance => (
        c.primary,
        c.primarySoft,
        SfIcons.check,
      ),
      NotificationCategory.card => (c.warn, c.warnSoft, SfIcons.flag),
      NotificationCategory.survey => (c.ai, c.aiBg.first, Icons.poll_outlined),
      NotificationCategory.audit => (
        c.danger,
        c.dangerSoft,
        Icons.fact_check_outlined,
      ),
      NotificationCategory.task => (c.primary, c.primarySoft, SfIcons.check),
    };
    return Semantics(
      button: true,
      readOnly: notification.isRead,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SfSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.$2,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(style.$3, size: 19, color: style.$1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: SfType.ui(
                              size: 13.5,
                              weight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 5, left: 7),
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: SfType.ui(size: 12.5, color: c.muted, height: 1.4),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      SfFormatters.relativeUz(notification.createdAt),
                      style: SfType.mono(size: 10, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
