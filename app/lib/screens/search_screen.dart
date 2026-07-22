import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_search_field.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

enum _SearchKind { all, task, message, notice, print, audit }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  _SearchKind _kind = _SearchKind.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final session = app.session;
    if (session == null) return const SizedBox.shrink();

    final records = _recordsFor(app, session);
    final query = _controller.text.trim().toLowerCase();
    final results = records
        .where((record) {
          final kindMatches = _kind == _SearchKind.all || record.kind == _kind;
          final queryMatches =
              query.isEmpty ||
              '${record.title} ${record.subtitle} ${record.keywords}'
                  .toLowerCase()
                  .contains(query);
          return kindMatches && queryMatches;
        })
        .toList(growable: false);

    return SfScaffold(
      top: Column(
        children: [
          SfNavBar(
            title: 'Izlash',
            leading: _BackButton(onPressed: () => _goBack(context)),
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: SfSearchField(
              controller: _controller,
              autofocus: true,
              hintText: 'Vazifa, suhbat yoki bildirishnoma',
              semanticLabel: 'Umumiy qidiruv',
              clearTooltip: 'Izlashni tozalash',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          SfHintCard(
            compact: true,
            title: '${session.role.uzLabel} qidiruvi',
            message:
                'Faqat sizga ruxsat berilgan xodimlar ma’lumotlari ko‘rsatiladi.',
          ),
          const SizedBox(height: 14),
          _FilterRow(
            selected: _kind,
            available: _availableKinds(session),
            onChanged: (value) => setState(() => _kind = value),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                query.isEmpty ? 'TEZKOR NATIJALAR' : 'NATIJALAR',
                style: SfType.eyebrow(color: c.muted),
              ),
              const Spacer(),
              Text(
                '${results.length} ta',
                style: SfType.ui(size: 11, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (results.isEmpty)
            SfSurfaceCard(
              child: SfEmptyState(
                compact: true,
                icon: SfIcons.search,
                title: 'Mos natija topilmadi',
                message: 'So‘zni qisqartiring yoki boshqa bo‘limni tanlang.',
                actionLabel: 'Filtrni tozalash',
                onAction: () {
                  _controller.clear();
                  setState(() => _kind = _SearchKind.all);
                },
              ),
            )
          else
            SfSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < results.length; index++)
                    _ResultTile(
                      record: results[index],
                      showDivider: index != results.length - 1,
                      onPressed: () => _open(context, results[index]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, _SearchRecord record) {
    if (record.route == null) {
      SfToast.show(context, title: record.title, message: record.subtitle);
      return;
    }
    context.push(record.route!);
  }

  List<_SearchRecord> _recordsFor(AppState app, StaffSession session) {
    final canManageTasks = session.can(StaffCapability.assignTasks);
    final tasks = app.tasks.where(
      (StaffTask task) =>
          canManageTasks ||
          task.assigneeId == session.userId ||
          task.creatorId == session.userId,
    );
    final records = <_SearchRecord>[
      for (final task in tasks)
        _SearchRecord(
          kind: _SearchKind.task,
          icon: SfIcons.check,
          title: task.title,
          subtitle: '${task.assigneeName} · ${_taskStatus(task.status)}',
          keywords: '${task.description} ${task.priority.name}',
          route: '/tasks/detail?id=${Uri.encodeQueryComponent(task.id)}',
        ),
      for (final notice in app.notifications.where(
        (StaffNotification notice) =>
            notice.category != NotificationCategory.audit ||
            session.can(StaffCapability.viewAuditWorkspace),
      ))
        _SearchRecord(
          kind: _SearchKind.notice,
          icon: SfIcons.bell,
          title: notice.title,
          subtitle: notice.body,
          keywords: notice.category.name,
          route: notice.route,
          unread: !notice.isRead,
        ),
    ];

    if (session.can(StaffCapability.useStaffMessaging)) {
      records.addAll([
        for (final thread in app.messageThreads.where(
          (MessageThread thread) =>
              thread.participantIds.contains(session.userId),
        ))
          _SearchRecord(
            kind: _SearchKind.message,
            icon: SfIcons.chat,
            title: thread.title,
            subtitle: thread.messages.lastOrNull?.body ?? 'Hali xabar yo‘q',
            keywords: thread.messages.map((message) => message.body).join(' '),
            route:
                '/messages/chat?thread=${Uri.encodeQueryComponent(thread.id)}',
            unread: thread.unreadCountFor(session.userId) > 0,
          ),
      ]);
    }

    if (session.can(StaffCapability.submitPrintJobs)) {
      final canManage = session.can(StaffCapability.managePrintQueue);
      records.addAll([
        for (final job in app.printJobs.where(
          (PrintJob job) => canManage || job.requestedById == session.userId,
        ))
          _SearchRecord(
            kind: _SearchKind.print,
            icon: SfIcons.printer,
            title: job.documentName,
            subtitle: '${job.printerName} · ${_printStatus(job.status)}',
            keywords: '${job.copies} nusxa ${job.pageCount} bet',
            route: '/print',
          ),
      ]);
    }

    if (session.can(StaffCapability.viewAuditWorkspace)) {
      records.addAll([
        for (final anomaly in app.auditAnomalies)
          _SearchRecord(
            kind: _SearchKind.audit,
            icon: SfIcons.shield,
            title: anomaly.title,
            subtitle: '${anomaly.entityLabel} · ${anomaly.status.name}',
            keywords: '${anomaly.description} ${anomaly.severity.name}',
            route: '/staff/audit/signal/${Uri.encodeComponent(anomaly.id)}',
          ),
        for (final auditCase in app.auditCases)
          _SearchRecord(
            kind: _SearchKind.audit,
            icon: SfIcons.flag,
            title: auditCase.title,
            subtitle: 'Audit holati · ${auditCase.status.name}',
            keywords: auditCase.description,
            route: '/staff/audit/case/${Uri.encodeComponent(auditCase.id)}',
          ),
      ]);
    }
    return records;
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.available,
    required this.onChanged,
  });

  final _SearchKind selected;
  final List<_SearchKind> available;
  final ValueChanged<_SearchKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: available.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final value = available[index];
          final active = value == selected;
          return SfPressable(
            onPressed: () => onChanged(value),
            semanticLabel: '${_kindLabel(value)} filtri',
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? c.ink : c.surface,
                border: Border.all(color: active ? c.ink : c.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _kindLabel(value),
                style: SfType.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? c.bg : c.ink2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.record,
    required this.showDivider,
    required this.onPressed,
  });

  final _SearchRecord record;
  final bool showDivider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      semanticLabel: '${record.title}. ${record.subtitle}',
      borderRadius: BorderRadius.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: c.border))
              : null,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SfAvatar(name: record.title, size: 38),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      border: Border.all(color: c.surface, width: 2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Icon(record.icon, size: 10, color: c.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 13.5,
                            weight: record.unread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                      ),
                      if (record.unread)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 11.5, color: c.muted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(SfIcons.chevR, size: 17, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onPressed,
      semanticLabel: 'Ortga',
      tooltip: 'Ortga',
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(SfIcons.arrowL, size: 18, color: c.primary),
            const SizedBox(width: 3),
            Text('Ortga', style: SfType.ui(size: 13, color: c.primary)),
          ],
        ),
      ),
    );
  }
}

class _SearchRecord {
  const _SearchRecord({
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.route,
    this.unread = false,
  });

  final _SearchKind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final String keywords;
  final String? route;
  final bool unread;
}

List<_SearchKind> _availableKinds(StaffSession session) => [
  _SearchKind.all,
  _SearchKind.task,
  if (session.can(StaffCapability.useStaffMessaging)) _SearchKind.message,
  _SearchKind.notice,
  if (session.can(StaffCapability.submitPrintJobs)) _SearchKind.print,
  if (session.can(StaffCapability.viewAuditWorkspace)) _SearchKind.audit,
];

String _kindLabel(_SearchKind value) => switch (value) {
  _SearchKind.all => 'Hammasi',
  _SearchKind.task => 'Vazifalar',
  _SearchKind.message => 'Suhbatlar',
  _SearchKind.notice => 'Bildirishnomalar',
  _SearchKind.print => 'Chop etish',
  _SearchKind.audit => 'Audit',
};

String _taskStatus(TaskStatus value) => switch (value) {
  TaskStatus.todo => 'Rejada',
  TaskStatus.inProgress => 'Jarayonda',
  TaskStatus.inReview => 'Tekshiruvda',
  TaskStatus.done => 'Bajarildi',
};

String _printStatus(PrintJobStatus value) => switch (value) {
  PrintJobStatus.queued => 'Navbatda',
  PrintJobStatus.printing => 'Chop etilmoqda',
  PrintJobStatus.completed => 'Tayyor',
  PrintJobStatus.failed => 'Xatolik',
  PrintJobStatus.cancelled => 'Bekor qilingan',
};

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/more');
  }
}
