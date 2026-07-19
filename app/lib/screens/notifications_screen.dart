import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../data/api/backend_models.dart';
import '../data/api/notification_realtime.dart';
import '../data/models.dart';
import '../features/notifications/backend_notification_controller.dart';
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
  bool _productionStartRequested = false;

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
    final production = app.backendNotifications;
    if (production != null) {
      if (!production.hasLoadedFeed && !_productionStartRequested) {
        _productionStartRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await production.start();
        });
      }
      return ListenableBuilder(
        listenable: production,
        builder: (context, _) => _buildProduction(context, app, production),
      );
    }
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

  Widget _buildProduction(
    BuildContext context,
    AppState app,
    BackendNotificationController controller,
  ) {
    final c = SfTheme.colorsOf(context);
    final visible = controller.notifications
        .where(_matchesBackend)
        .toList(growable: false);
    final initialLoading =
        !controller.hasLoadedFeed ||
        (controller.isRefreshing && controller.notifications.isEmpty);
    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Bildirishnomalar',
            subtitle:
                '${controller.notifications.length} ta Â· ${controller.unreadCount} ta yangi',
            leading: IconButton(
              tooltip: 'Ortga',
              onPressed: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : null,
              icon: const Icon(SfIcons.arrowL),
            ),
            actions: [
              IconButton(
                tooltip: 'Bildirishnoma sozlamalari',
                onPressed: () =>
                    _showProductionPreferences(context, controller),
                icon: const Icon(Icons.tune_rounded),
              ),
              IconButton(
                tooltip: 'Hammasini o\u2018qilgan qilish',
                onPressed: controller.unreadCount == 0
                    ? null
                    : () async {
                        await controller.markAllRead();
                        if (!context.mounted) return;
                        SfToast.show(
                          context,
                          message: 'Barcha bildirishnomalar o\u2018qildi',
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
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Column(
              children: [
                SfSegmentedControl<_NotificationFilter>(
                  expanded: true,
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                  segments: const [
                    SfSegment(value: _NotificationFilter.all, label: 'Hammasi'),
                    SfSegment(
                      value: _NotificationFilter.message,
                      label: 'Xabar',
                    ),
                    SfSegment(value: _NotificationFilter.print, label: 'Print'),
                    SfSegment(value: _NotificationFilter.work, label: 'Ish'),
                  ],
                ),
                const SizedBox(height: 7),
                _RealtimeStatus(status: controller.realtimeStatus),
              ],
            ),
          ),
        ],
      ),
      body: initialLoading
          ? const SfLoadingState(
              label: 'Bildirishnomalar serverdan olinmoqda\u2026',
            )
          : controller.feedUnavailable && controller.notifications.isEmpty
          ? SfErrorState(
              title: 'Bildirishnomalar bu rol uchun mavjud emas',
              message: controller.error,
              onRetry: controller.refresh,
            )
          : controller.error != null && controller.notifications.isEmpty
          ? SfErrorState(
              title: 'Bildirishnomalar yuklanmadi',
              message: controller.error,
              onRetry: controller.refresh,
            )
          : visible.isEmpty
          ? SfEmptyState(
              title: 'Bildirishnoma yo\u2018q',
              message: 'Tanlangan bo\u2018limda server xabari topilmadi.',
              icon: SfIcons.bell,
              actionLabel: _filter == _NotificationFilter.all
                  ? 'Yangilash'
                  : 'Filtrni tozalash',
              onAction: _filter == _NotificationFilter.all
                  ? () => controller.refresh()
                  : () => setState(() => _filter = _NotificationFilter.all),
            )
          : RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                itemCount: visible.length + (controller.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == visible.length) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: controller.isLoadingMore
                            ? null
                            : controller.loadMore,
                        icon: controller.isLoadingMore
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more_rounded),
                        label: const Text('Oldingi bildirishnomalar'),
                      ),
                    );
                  }
                  final notification = visible[index];
                  return _BackendNotificationTile(
                    notification: notification,
                    onTap: () async {
                      if (notification.readAt == null) {
                        await controller.markRead(notification.id);
                      }
                      if (!context.mounted) return;
                      final route = _backendRoute(notification);
                      if (route != null) context.push(route);
                    },
                  );
                },
              ),
            ),
    );
  }

  bool _matchesBackend(BackendNotification notification) => switch (_filter) {
    _NotificationFilter.all => true,
    _NotificationFilter.message => notification.eventType.startsWith(
      'message.',
    ),
    _NotificationFilter.print => notification.eventType.startsWith('print.'),
    _NotificationFilter.work =>
      !notification.eventType.startsWith('message.') &&
          !notification.eventType.startsWith('print.'),
  };

  String? _backendRoute(BackendNotification notification) {
    final data = notification.data;
    if (notification.eventType == 'message.received') {
      final threadId = data['thread_id'];
      if (threadId != null) {
        return '/messages/chat?thread=${Uri.encodeQueryComponent('$threadId')}';
      }
    }
    final taskId = data['task_id'];
    if (taskId != null) return '/tasks/detail?id=$taskId';
    if (notification.eventType.startsWith('assignments.')) {
      return '/assignments';
    }
    if (notification.eventType.startsWith('schedule.') ||
        notification.eventType.startsWith('cover.')) {
      return '/schedule';
    }
    if (notification.eventType.startsWith('print.')) return '/print';
    final supplied = data['route'];
    if (supplied is! String) return null;
    const safePrefixes = <String>{
      '/messages',
      '/tasks',
      '/assignments',
      '/schedule',
      '/print',
      '/workspace',
      '/work',
    };
    return safePrefixes.any(supplied.startsWith) ? supplied : null;
  }

  Future<void> _showProductionPreferences(
    BuildContext context,
    BackendNotificationController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    'Bildirishnoma kanallari',
                    style: SfType.ui(size: 20, weight: FontWeight.w800),
                  ),
                ),
                if (controller.preferencesLoading &&
                    controller.preferences.isEmpty)
                  const Expanded(
                    child: SfLoadingState(label: 'Sozlamalar olinmoqda\u2026'),
                  )
                else if (controller.preferencesUnavailable)
                  Expanded(
                    child: SfErrorState(
                      title: 'Sozlamalar bu rol uchun mavjud emas',
                      onRetry: controller.refreshPreferences,
                    ),
                  )
                else if (controller.preferences.isEmpty)
                  const Expanded(
                    child: SfEmptyState(
                      title: 'Shaxsiy o\u2018zgartirish yo\u2018q',
                      message:
                          'Markazning standart bildirishnoma qoidalari ishlatilmoqda.',
                      icon: Icons.notifications_active_outlined,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.preferences.length,
                      itemBuilder: (context, index) {
                        final preference = controller.preferences[index];
                        return SwitchListTile.adaptive(
                          value: preference.enabled,
                          onChanged: (enabled) =>
                              controller.setPreference(preference, enabled),
                          title: Text(_eventLabel(preference.eventType)),
                          subtitle: Text(_channelLabel(preference.channel)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _eventLabel(String eventType) => eventType
      .split('.')
      .map((part) => part.replaceAll('_', ' '))
      .join(' Â· ');

  String _channelLabel(String channel) => switch (channel) {
    'in_app' => 'Ilova ichida',
    'push' => 'Push',
    'email' => 'Email',
    'sms' => 'SMS',
    _ => channel,
  };
}

class _RealtimeStatus extends StatelessWidget {
  const _RealtimeStatus({required this.status});

  final NotificationRealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final (label, color, icon) = switch (status) {
      NotificationRealtimeStatus.connected => (
        'Jonli yangilanish ulangan',
        c.success,
        Icons.wifi_rounded,
      ),
      NotificationRealtimeStatus.connecting => (
        'Jonli ulanish yaratilmoqda\u2026',
        c.warn,
        Icons.sync_rounded,
      ),
      NotificationRealtimeStatus.waitingToReconnect => (
        'Qayta ulanmoqda; REST yangilash ishlaydi',
        c.warn,
        Icons.sync_problem_rounded,
      ),
      NotificationRealtimeStatus.authenticationRequired => (
        'Sessiyani yangilash kerak',
        c.danger,
        Icons.lock_outline_rounded,
      ),
      NotificationRealtimeStatus.forbidden => (
        'Jonli kanal bu rol uchun yopiq',
        c.danger,
        Icons.shield_outlined,
      ),
      NotificationRealtimeStatus.paused => (
        'Jonli kanal pauzada',
        c.muted,
        Icons.pause_circle_outline_rounded,
      ),
      _ => ('REST yangilash faol', c.muted, Icons.cloud_outlined),
    };
    return Semantics(
      liveRegion: true,
      label: label,
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: SfType.ui(size: 10.5, color: color)),
          ),
        ],
      ),
    );
  }
}

class _BackendNotificationTile extends StatelessWidget {
  const _BackendNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final BackendNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final event = notification.eventType;
    final style = event.startsWith('message.')
        ? (c.accent, c.accentSoft, SfIcons.chat)
        : event.startsWith('print.')
        ? (c.success, c.successSoft, SfIcons.printer)
        : event.startsWith('attendance.')
        ? (c.primary, c.primarySoft, SfIcons.check)
        : event.startsWith('assignments.')
        ? (c.ai, c.aiBg.first, Icons.assignment_outlined)
        : event.startsWith('auth.') || event.startsWith('billing.')
        ? (c.danger, c.dangerSoft, Icons.security_rounded)
        : (c.warn, c.warnSoft, SfIcons.bell);
    final unread = notification.readAt == null;
    return Semantics(
      button: true,
      readOnly: !unread,
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
                              weight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (unread)
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
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        notification.body,
                        style: SfType.ui(
                          size: 12.5,
                          color: c.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.createdAt == null
                                ? notification.eventType
                                : SfFormatters.relativeUz(
                                    notification.createdAt!.toLocal(),
                                  ),
                            style: SfType.mono(size: 10, color: c.muted),
                          ),
                        ),
                        Text(
                          notification.eventType,
                          style: SfType.mono(size: 8.5, color: c.muted),
                        ),
                      ],
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
