import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/backend_core.dart';
import '../../features/operations/staff_operations_controller.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class StaffOperationsHubScreen extends StatelessWidget {
  const StaffOperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: SfNavBar(
        title: _copy(context, 'Xodimlar xizmatlari', 'Staff services'),
        subtitle: _copy(
          context,
          'Server ruxsati bo‘yicha ochiladi',
          'Opened according to server permission',
        ),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primarySoft, c.ai.withValues(alpha: .12)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.aiBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: c.primary),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _copy(
                      context,
                      'Har bir bo‘lim mustaqil tekshiriladi. Ruxsatsiz ma’lumot yashirin qoladi va boshqa sahifalar ishlashda davom etadi.',
                      'Each module is checked independently. Restricted data stays hidden and does not interrupt the rest of the app.',
                    ),
                    style: SfType.ui(size: 12, color: c.ink2, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final module in staffOperationModules) ...[
            SfPressable(
              onPressed: () => context.push('/staff/operations/${module.id}'),
              borderRadius: BorderRadius.circular(18),
              child: SfSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _operationIcon(module.id),
                        color: c.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.title,
                            style: SfType.ui(
                              size: 14,
                              weight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            module.description,
                            style: SfType.ui(
                              size: 11,
                              color: c.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class StaffOperationModuleScreen extends StatefulWidget {
  const StaffOperationModuleScreen({
    super.key,
    required this.moduleId,
    this.controller,
  });

  final String moduleId;
  final StaffOperationsController? controller;

  @override
  State<StaffOperationModuleScreen> createState() =>
      _StaffOperationModuleScreenState();
}

class _StaffOperationModuleScreenState
    extends State<StaffOperationModuleScreen> {
  final _search = TextEditingController();
  StaffOperationsController? _controller;
  bool _ownsController = false;

  StaffOperationModule? get _module =>
      staffOperationModuleById(widget.moduleId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    if (widget.controller != null) {
      _controller = widget.controller;
      return;
    }
    final app = AppScope.of(context);
    final api = app.backendApi;
    final module = _module;
    if (api == null || module == null) return;
    _controller = StaffOperationsController(api: api, module: module);
    _ownsController = true;
    unawaited(_controller!.refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    final controller = _controller;
    if (module == null) {
      return const SfScaffold(
        top: SfNavBar(title: 'Staff service', leading: BackButton()),
        body: SfErrorState(title: 'Unknown staff service'),
      );
    }
    if (controller == null) {
      return SfScaffold(
        top: SfNavBar(title: module.title, leading: const BackButton()),
        body: SfEmptyState(
          title: _copy(
            context,
            'Server seansi kerak',
            'Server session required',
          ),
          icon: Icons.lock_outline_rounded,
        ),
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final query = _search.text.trim().toLowerCase();
        final records = controller.records
            .where(
              (record) => query.isEmpty || _searchText(record).contains(query),
            )
            .toList(growable: false);
        return SfScaffold(
          top: SfNavBar(
            title: module.title,
            subtitle: controller.loading
                ? _copy(context, 'Yangilanmoqda…', 'Refreshing…')
                : '${records.length} records',
            leading: const BackButton(),
            actions: [
              IconButton(
                tooltip: _copy(context, 'Yangilash', 'Refresh'),
                onPressed: controller.loading
                    ? null
                    : () => unawaited(controller.refresh()),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: _body(context, controller, records),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    StaffOperationsController controller,
    List<BackendJson> records,
  ) {
    final app = AppScope.of(context);
    if (controller.loading && controller.records.isEmpty) {
      return SfLoadingState(
        label: _copy(context, 'Ma’lumot yuklanmoqda…', 'Loading records…'),
        motionEnabled: !app.settings.reducedMotion,
      );
    }
    if (controller.error != null && controller.records.isEmpty) {
      return controller.available
          ? SfErrorState(
              title: _copy(
                context,
                'Xizmatni yuklab bo‘lmadi',
                'The service could not be loaded',
              ),
              message: controller.error,
              onRetry: controller.refresh,
            )
          : SfEmptyState(
              title: _copy(
                context,
                'Bu xizmat rolingizga ochilmagan',
                'This service is unavailable for your role',
              ),
              message: controller.error,
              icon: Icons.admin_panel_settings_outlined,
              actionLabel: _copy(context, 'Qayta tekshirish', 'Check again'),
              onAction: controller.refresh,
            );
    }
    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _copy(context, 'Yozuvlarni qidiring', 'Search records'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (records.isEmpty)
            SizedBox(
              height: 300,
              child: SfEmptyState(
                title: _copy(context, 'Yozuv topilmadi', 'No records found'),
                message: _search.text.isEmpty
                    ? _copy(
                        context,
                        'Server hozircha bu bo‘lim uchun yozuv qaytarmadi.',
                        'The server returned no records for this module.',
                      )
                    : _copy(
                        context,
                        'Qidiruv so‘zini o‘zgartiring.',
                        'Try another search term.',
                      ),
              ),
            )
          else
            for (final record in records) ...[
              _OperationRecordCard(
                record: record,
                onPressed: () => _showRecord(context, controller, record),
              ),
              const SizedBox(height: 9),
            ],
          if (controller.hasNext)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: controller.loadingMore
                    ? null
                    : () => unawaited(controller.loadMore()),
                icon: controller.loadingMore
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(_copy(context, 'Ko‘proq', 'Load more')),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRecord(
    BuildContext context,
    StaffOperationsController controller,
    BackendJson record,
  ) async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .45,
        maxChildSize: .94,
        builder: (context, scroll) {
          final actions = controller.actionsFor(record);
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              Text(
                _recordTitle(record),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              for (final entry in _visibleEntries(record))
                _DetailRow(label: _humanize(entry.key), value: entry.value),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in actions)
                      action.destructive
                          ? OutlinedButton.icon(
                              onPressed: () => _runAction(
                                sheetContext,
                                controller,
                                record,
                                action,
                              ),
                              icon: const Icon(Icons.close_rounded),
                              label: Text(action.label),
                            )
                          : FilledButton.icon(
                              onPressed: () => _runAction(
                                sheetContext,
                                controller,
                                record,
                                action,
                              ),
                              icon: const Icon(Icons.check_rounded),
                              label: Text(action.label),
                            ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _copy(
                  context,
                  'Amal bajarilganda server ruxsati va joriy holat qayta tekshiriladi.',
                  'The server re-checks your permission and the current record state for every action.',
                ),
                style: SfType.ui(
                  size: 10.5,
                  color: SfTheme.colorsOf(context).muted,
                ),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || !app.isInitialized) return;
  }

  Future<void> _runAction(
    BuildContext sheetContext,
    StaffOperationsController controller,
    BackendJson record,
    StaffRecordAction action,
  ) async {
    final approved = await showSfConfirmDialog(
      sheetContext,
      title: action.label,
      message: _copy(
        sheetContext,
        'Bu amal serverga yuboriladi va qaytarib bo‘lmasligi mumkin.',
        'This action is sent to the server and may not be reversible.',
      ),
      confirmLabel: action.label,
      destructive: action.destructive,
    );
    if (!approved || !mounted) return;
    try {
      await controller.perform(record, action);
      if (!mounted || !sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      SfToast.show(
        context,
        message: _copy(context, 'Server yangilandi', 'Server updated'),
        tone: SfToastTone.success,
      );
    } on Object catch (error) {
      if (sheetContext.mounted) {
        SfToast.show(sheetContext, message: '$error', tone: SfToastTone.error);
      }
    }
  }
}

IconData _operationIcon(String moduleId) => switch (moduleId) {
  'rules' => Icons.rule_outlined,
  'cover' => Icons.event_repeat_outlined,
  'meetings' => Icons.groups_outlined,
  'approvals' => Icons.approval_outlined,
  'achievements' => Icons.emoji_events_outlined,
  'rewards' => Icons.redeem_outlined,
  'loans' => Icons.account_balance_wallet_outlined,
  'procurement' => Icons.shopping_bag_outlined,
  'exams' => Icons.quiz_outlined,
  'grades' => Icons.grading_outlined,
  'warnings' => Icons.warning_amber_rounded,
  'honor-roll' => Icons.workspace_premium_outlined,
  'students' => Icons.school_outlined,
  'teachers' => Icons.co_present_outlined,
  'payments' => Icons.payments_outlined,
  'reports' => Icons.analytics_outlined,
  'risk' => Icons.psychology_outlined,
  'placement' => Icons.move_up_outlined,
  'campaigns' => Icons.campaign_outlined,
  'sales' => Icons.point_of_sale_outlined,
  'card-scans' => Icons.nfc_outlined,
  _ => Icons.dashboard_customize_outlined,
};

class _OperationRecordCard extends StatelessWidget {
  const _OperationRecordCard({required this.record, required this.onPressed});

  final BackendJson record;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final entries = _visibleEntries(record).take(3).toList();
    return SfPressable(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _recordTitle(record),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.muted),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${_humanize(entry.key)}: ${_displayValue(entry.value)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 10.5, color: c.muted),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: SfType.ui(size: 11, color: c.muted)),
          ),
          Expanded(
            child: SelectableText(
              _displayValue(value),
              style: SfType.ui(size: 12, color: c.ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

Iterable<MapEntry<String, Object?>> _visibleEntries(BackendJson record) =>
    record.entries.where(
      (entry) =>
          entry.key != 'id' &&
          !_secretKey.hasMatch(entry.key) &&
          entry.value != null &&
          _displayValue(entry.value).isNotEmpty,
    );

final _secretKey = RegExp(
  r'(password|secret|token|credential|private_key)',
  caseSensitive: false,
);

String _recordTitle(BackendJson record) {
  for (final key in const [
    'title',
    'name',
    'label',
    'student_name',
    'teacher_name',
    'full_name',
    'kind',
    'status',
  ]) {
    final value = backendString(record[key]);
    if (value.isNotEmpty) return value;
  }
  final id = backendString(record['id']);
  return id.isEmpty ? 'Server record' : 'Record #$id';
}

String _searchText(BackendJson record) => record.entries
    .where((entry) => !_secretKey.hasMatch(entry.key))
    .map((entry) => _displayValue(entry.value).toLowerCase())
    .join(' ');

String _displayValue(Object? value) {
  if (value == null) return '';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) {
    return value.map(_displayValue).where((item) => item.isNotEmpty).join(', ');
  }
  if (value is Map) {
    final map = backendMap(value);
    return map.entries
        .where((entry) => !_secretKey.hasMatch(entry.key))
        .take(6)
        .map(
          (entry) => '${_humanize(entry.key)}: ${_displayValue(entry.value)}',
        )
        .join(' · ');
  }
  final text = value.toString();
  final date = DateTime.tryParse(text);
  if (date != null && text.contains('-')) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return text;
}

String _humanize(String key) {
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String _copy(BuildContext context, String uz, String en) {
  final code = Localizations.localeOf(context).languageCode;
  return code == 'en' ? en : uz;
}
