import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/backend_models.dart';
import '../../data/api/backend_services_api.dart';
import '../../features/services/backend_services_controllers.dart';
import '../../theme/sf_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';

class BackendAuditLogScreen extends StatefulWidget {
  const BackendAuditLogScreen({super.key, required this.api, this.baseUrl});

  final BackendServicesApi api;
  final String? baseUrl;

  @override
  State<BackendAuditLogScreen> createState() => _BackendAuditLogScreenState();
}

class _BackendAuditLogScreenState extends State<BackendAuditLogScreen> {
  late final BackendAuditController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BackendAuditController(widget.api)..refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => SfScaffold(
      safeBottom: true,
      top: SfLargeAppBar(
        title: _tr(
          context,
          uz: 'O‘zgarmas audit jurnali',
          en: 'Immutable audit log',
        ),
        subtitle: _tr(
          context,
          uz: '${_controller.entries.length} prod server yozuvi',
          en: '${_controller.entries.length} production server entries',
        ),
        leading: IconButton(
          tooltip: _tr(context, uz: 'Ortga', en: 'Back'),
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            key: const Key('backend-audit-export'),
            tooltip: _tr(context, uz: 'Eksport', en: 'Export'),
            onPressed: () => _showExport(context),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            key: const Key('backend-audit-filter'),
            tooltip: _tr(context, uz: 'Filtr', en: 'Filters'),
            onPressed: () => _showFilters(context),
            icon: Badge(
              isLabelVisible: _hasFilters,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          IconButton(
            key: const Key('backend-audit-refresh'),
            tooltip: _tr(context, uz: 'Yangilash', en: 'Refresh'),
            onPressed: _controller.refreshing ? null : _controller.refresh,
            icon: _controller.refreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _body(context),
    ),
  );

  bool get _hasFilters =>
      _controller.actorId != null ||
      (_controller.action?.isNotEmpty ?? false) ||
      (_controller.resourceType?.isNotEmpty ?? false) ||
      (_controller.resourceId?.isNotEmpty ?? false) ||
      _controller.from != null ||
      _controller.to != null;

  Widget _body(BuildContext context) {
    if (_controller.isInitialLoading) {
      return SfLoadingState(
        label: _tr(
          context,
          uz: 'Audit jurnali yuklanmoqda…',
          en: 'Loading audit log…',
        ),
        message: _tr(
          context,
          uz: 'Kursorli prod feed o‘qilmoqda',
          en: 'Reading the cursor-paginated production feed',
        ),
      );
    }
    if (_controller.isUnavailable) {
      return SfErrorState(
        title: _tr(
          context,
          uz: 'Audit jurnaliga ruxsat yo‘q',
          en: 'Audit log unavailable',
        ),
        message: _tr(
          context,
          uz: 'Server bu hisobga audit:read ruxsatini bermadi.',
          en: 'The server did not grant this account audit:read access.',
        ),
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }
    if (_controller.hasError && !_controller.hasRenderableData) {
      return SfErrorState(
        message: _controller.errorMessage,
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: _controller.refresh,
      child: ListView(
        key: const PageStorageKey('backend-audit-log'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 28),
        children: [
          SfHintCard(
            compact: true,
            icon: Icons.lock_clock_outlined,
            title: _tr(
              context,
              uz: 'Append-only server feed',
              en: 'Append-only server feed',
            ),
            message: _tr(
              context,
              uz: 'Bu lokal anomaliya yoki tekshiruv kartalari emas. Har bir satr to‘g‘ridan-to‘g‘ri /api/v1/audit/ dan olinadi; mobil ilova uni tahrirlamaydi.',
              en: 'These are not local anomaly or case cards. Every row comes directly from /api/v1/audit/ and the mobile app never edits it.',
            ),
          ),
          if (_hasFilters) ...[
            const SizedBox(height: 12),
            _ActiveFilters(
              controller: _controller,
              onClear: _controller.clearFilters,
            ),
          ],
          const SizedBox(height: 15),
          if (_controller.phase == BackendLoadPhase.empty)
            SfEmptyState(
              compact: true,
              icon: Icons.manage_search_rounded,
              title: _tr(
                context,
                uz: 'Audit yozuvi topilmadi',
                en: 'No audit entries found',
              ),
              message: _tr(
                context,
                uz: _hasFilters
                    ? 'Tanlangan server filtrlari hech narsa qaytarmadi.'
                    : 'Server bu tenant uchun audit yozuvi qaytarmadi.',
                en: _hasFilters
                    ? 'The selected server filters returned no entries.'
                    : 'The server returned no audit entries for this tenant.',
              ),
              actionLabel: _hasFilters
                  ? _tr(context, uz: 'Filtrni tozalash', en: 'Clear filters')
                  : _tr(context, uz: 'Yangilash', en: 'Refresh'),
              onAction: _hasFilters
                  ? _controller.clearFilters
                  : _controller.refresh,
            )
          else
            for (final entry in _controller.entries) ...[
              _AuditEntryCard(
                entry: entry,
                onPressed: () => _showDetail(context, entry),
              ),
              const SizedBox(height: 11),
            ],
          if (_controller.hasMore)
            SfButton(
              key: const Key('backend-audit-load-more'),
              block: true,
              kind: SfButtonKind.ghost,
              leading: Icons.expand_more_rounded,
              label: _controller.loadingMore
                  ? _tr(context, uz: 'Yuklanmoqda…', en: 'Loading…')
                  : _tr(context, uz: 'Keyingi kursor', en: 'Load next cursor'),
              onPressed: _controller.loadingMore ? null : _controller.loadMore,
            ),
          if (_controller.hasError && _controller.hasRenderableData) ...[
            const SizedBox(height: 12),
            SfHintCard(
              compact: true,
              tone: SfHintTone.danger,
              message: _controller.errorMessage ?? 'Unknown error',
              actionLabel: _tr(context, uz: 'Qayta urinish', en: 'Retry'),
              onAction: _controller.refresh,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    BackendAuditEntry preview,
  ) async {
    BackendAuditEntry entry = preview;
    Object? loadError;
    try {
      entry = await _controller.entryDetail(preview.id);
    } catch (error) {
      loadError = error;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .86,
        maxChildSize: .96,
        minChildSize: .55,
        builder: (context, scrollController) => _AuditDetail(
          entry: entry,
          loadError: loadError,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _AuditFilterSheet(controller: _controller),
    );
  }

  Future<void> _showExport(BuildContext context) async {
    final endpoint = _exportEndpoint();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr(
                sheetContext,
                uz: 'Audit CSV eksporti',
                en: 'Audit CSV export',
              ),
              style: SfType.ui(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SfHintCard(
              tone: SfHintTone.warning,
              title: _tr(
                sheetContext,
                uz: 'Serverda mavjud',
                en: 'Available on server',
              ),
              message: _tr(
                sheetContext,
                uz: 'Backend shu filtrlar bilan autentifikatsiyalangan CSV eksportini qo‘llaydi (50 000 qatorgacha). Hozirgi mobil transport faqat JSON o‘qiydi, shuning uchun ilova yolg‘on lokal CSV yaratmaydi yoki brauzerga token chiqarmaydi.',
                en: 'The backend supports an authenticated CSV export with these filters (up to 50,000 rows). The current mobile transport is JSON-only, so the app does not fabricate a local CSV or leak the bearer token to a browser.',
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              endpoint,
              style: SfType.mono(size: 11, height: 1.45),
            ),
            const SizedBox(height: 16),
            SfButton(
              key: const Key('backend-audit-copy-export-endpoint'),
              block: true,
              leading: Icons.copy_rounded,
              label: _tr(
                sheetContext,
                uz: 'Endpointni nusxalash',
                en: 'Copy endpoint',
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: endpoint));
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                SfToast.show(
                  context,
                  message: _tr(
                    context,
                    uz: 'Eksport endpointi nusxalandi',
                    en: 'Export endpoint copied',
                  ),
                  tone: SfToastTone.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _exportEndpoint() {
    final query = <String, String>{
      if (_controller.actorId != null) 'actor': '${_controller.actorId}',
      if (_controller.action case final value? when value.isNotEmpty)
        'action': value,
      if (_controller.resourceType case final value? when value.isNotEmpty)
        'resource_type': value,
      if (_controller.resourceId case final value? when value.isNotEmpty)
        'resource_id': value,
      if (_controller.from != null)
        'ts_from': _controller.from!.toUtc().toIso8601String(),
      if (_controller.to != null)
        'ts_to': _controller.to!.toUtc().toIso8601String(),
    };
    final base = widget.baseUrl?.replaceAll(RegExp(r'/+$'), '');
    final raw = base == null || base.isEmpty
        ? '/api/v1/audit/export/'
        : '$base/api/v1/audit/export/';
    return Uri.parse(raw).replace(queryParameters: query).toString();
  }
}

class _AuditEntryCard extends StatelessWidget {
  const _AuditEntryCard({required this.entry, required this.onPressed});

  final BackendAuditEntry entry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(_auditIcon(entry.action), color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.action,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SfType.ui(
                              size: 14.5,
                              weight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SfPill(label: '#${entry.id}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.resourceType}${entry.resourceId.isEmpty ? '' : ' · ${entry.resourceId}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(size: 11.5, color: c.ink2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _actor(entry),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                    if (entry.createdAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${SfFormatters.fullDateUz(entry.createdAt!)} · ${SfFormatters.time(entry.createdAt!)}',
                        style: SfType.mono(size: 10, color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right_rounded, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditDetail extends StatelessWidget {
  const _AuditDetail({
    required this.entry,
    required this.loadError,
    required this.scrollController,
  });

  final BackendAuditEntry entry;
  final Object? loadError;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    const encoder = JsonEncoder.withIndent('  ');
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        Text(
          entry.action,
          style: SfType.ui(size: 21, weight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 5),
        Text(
          '${entry.resourceType} · ${entry.resourceId} · #${entry.id}',
          style: SfType.mono(size: 11, color: c.muted),
        ),
        if (loadError != null) ...[
          const SizedBox(height: 12),
          SfHintCard(
            compact: true,
            tone: SfHintTone.warning,
            title: _tr(
              context,
              uz: 'Detail qayta o‘qilmadi',
              en: 'Detail refresh failed',
            ),
            message:
                '${_tr(context, uz: 'Ro‘yxat previewi ko‘rsatilmoqda', en: 'Showing the list preview')}: $loadError',
          ),
        ],
        const SizedBox(height: 15),
        SfSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _AuditMeta(
                label: _tr(context, uz: 'Aktyor', en: 'Actor'),
                value: _actor(entry),
              ),
              _AuditMeta(label: 'Actor ID', value: '${entry.actorId ?? '—'}'),
              _AuditMeta(label: 'IP', value: entry.ip.isEmpty ? '—' : entry.ip),
              _AuditMeta(
                label: _tr(context, uz: 'Vaqt', en: 'Timestamp'),
                value: entry.createdAt?.toLocal().toString() ?? '—',
              ),
              _AuditMeta(
                label: 'User agent',
                value: entry.userAgent.isEmpty ? '—' : entry.userAgent,
                divider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _JsonPanel(
          title: _tr(context, uz: 'Oldingi holat', en: 'Before'),
          value: encoder.convert(entry.before),
          empty: entry.before.isEmpty,
          tone: SfHintTone.warning,
        ),
        const SizedBox(height: 12),
        _JsonPanel(
          title: _tr(context, uz: 'Keyingi holat', en: 'After'),
          value: encoder.convert(entry.after),
          empty: entry.after.isEmpty,
          tone: SfHintTone.success,
        ),
      ],
    );
  }
}

class _JsonPanel extends StatelessWidget {
  const _JsonPanel({
    required this.title,
    required this.value,
    required this.empty,
    required this.tone,
  });

  final String title;
  final String value;
  final bool empty;
  final SfHintTone tone;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                empty ? Icons.remove_circle_outline : Icons.data_object_rounded,
                size: 19,
                color: tone == SfHintTone.success ? c.success : c.warn,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: SfType.ui(
                  size: 14,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          SelectableText(
            empty ? '{}' : value,
            style: SfType.mono(size: 11, color: c.ink2, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _AuditMeta extends StatelessWidget {
  const _AuditMeta({
    required this.label,
    required this.value,
    this.divider = true,
  });

  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: SfType.ui(size: 11, color: c.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: SfType.ui(size: 11.5, color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.controller, required this.onClear});

  final BackendAuditController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SfSurfaceCard(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (controller.actorId != null)
                SfPill(label: 'actor ${controller.actorId}'),
              if (controller.action?.isNotEmpty ?? false)
                SfPill(label: controller.action!),
              if (controller.resourceType?.isNotEmpty ?? false)
                SfPill(label: controller.resourceType!),
              if (controller.resourceId?.isNotEmpty ?? false)
                SfPill(label: 'id ${controller.resourceId}'),
              if (controller.from != null)
                SfPill(
                  label: 'from ${SfFormatters.compactDateUz(controller.from!)}',
                ),
              if (controller.to != null)
                SfPill(
                  label: 'to ${SfFormatters.compactDateUz(controller.to!)}',
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: _tr(context, uz: 'Tozalash', en: 'Clear'),
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _AuditFilterSheet extends StatefulWidget {
  const _AuditFilterSheet({required this.controller});

  final BackendAuditController controller;

  @override
  State<_AuditFilterSheet> createState() => _AuditFilterSheetState();
}

class _AuditFilterSheetState extends State<_AuditFilterSheet> {
  late final TextEditingController _actor;
  late final TextEditingController _action;
  late final TextEditingController _resourceType;
  late final TextEditingController _resourceId;
  DateTime? _from;
  DateTime? _to;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    final value = widget.controller;
    _actor = TextEditingController(text: value.actorId?.toString() ?? '');
    _action = TextEditingController(text: value.action ?? '');
    _resourceType = TextEditingController(text: value.resourceType ?? '');
    _resourceId = TextEditingController(text: value.resourceId ?? '');
    _from = value.from;
    _to = value.to;
  }

  @override
  void dispose() {
    _actor.dispose();
    _action.dispose();
    _resourceType.dispose();
    _resourceId.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool start}) async {
    final current = start ? _from : _to;
    final value = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (start) {
        _from = value;
      } else {
        _to = value
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));
      }
    });
  }

  Future<void> _apply() async {
    final actorText = _actor.text.trim();
    final actor = actorText.isEmpty ? null : int.tryParse(actorText);
    if (actorText.isNotEmpty && actor == null) {
      SfToast.show(
        context,
        message: _tr(
          context,
          uz: 'Actor ID butun son bo‘lishi kerak',
          en: 'Actor ID must be an integer',
        ),
        tone: SfToastTone.error,
      );
      return;
    }
    setState(() => _applying = true);
    await widget.controller.applyFilters(
      actor: actor,
      actionValue: _action.text,
      resourceTypeValue: _resourceType.text,
      resourceIdValue: _resourceId.text,
      fromValue: _from,
      toValue: _to,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(context, uz: 'Server filtrlari', en: 'Server filters'),
            style: SfType.ui(size: 20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 15),
          SfTextField(
            controller: _actor,
            label: 'Actor ID',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 11),
          SfTextField(
            controller: _action,
            label: _tr(context, uz: 'Aniq action', en: 'Exact action'),
            hint: 'task.updated',
          ),
          const SizedBox(height: 11),
          SfTextField(
            controller: _resourceType,
            label: 'Resource type',
            hint: 'tasks.task',
          ),
          const SizedBox(height: 11),
          SfTextField(controller: _resourceId, label: 'Resource ID'),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: SfButton(
                  kind: SfButtonKind.ghost,
                  leading: Icons.calendar_today_outlined,
                  label: _from == null
                      ? _tr(context, uz: 'Boshlanish', en: 'From date')
                      : SfFormatters.compactDateUz(_from!),
                  onPressed: () => _pick(start: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SfButton(
                  kind: SfButtonKind.ghost,
                  leading: Icons.event_outlined,
                  label: _to == null
                      ? _tr(context, uz: 'Tugash', en: 'To date')
                      : SfFormatters.compactDateUz(_to!),
                  onPressed: () => _pick(start: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: SfButton(
                  kind: SfButtonKind.ghost,
                  label: _tr(context, uz: 'Tozalash', en: 'Clear'),
                  onPressed: _applying
                      ? null
                      : () async {
                          await widget.controller.clearFilters();
                          if (context.mounted) Navigator.pop(context);
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SfButton(
                  key: const Key('backend-audit-apply-filters'),
                  label: _applying
                      ? _tr(context, uz: 'Qo‘llanmoqda…', en: 'Applying…')
                      : _tr(context, uz: 'Qo‘llash', en: 'Apply'),
                  onPressed: _applying ? null : _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

IconData _auditIcon(String action) {
  final value = action.toLowerCase();
  if (value.contains('delete')) return Icons.delete_outline_rounded;
  if (value.contains('create')) return Icons.add_circle_outline_rounded;
  if (value.contains('login') || value.contains('auth')) {
    return Icons.login_rounded;
  }
  if (value.contains('approve')) return Icons.verified_outlined;
  return Icons.history_rounded;
}

String _actor(BackendAuditEntry entry) {
  if (entry.actorRepresentation.isNotEmpty) return entry.actorRepresentation;
  if (entry.actorUsername.isNotEmpty) return entry.actorUsername;
  return entry.actorId == null ? 'System' : 'Actor #${entry.actorId}';
}

String _tr(BuildContext context, {required String uz, required String en}) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/staff/audit');
  }
}
