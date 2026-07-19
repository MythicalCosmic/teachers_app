import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/backend_core.dart';
import '../../data/api/backend_models.dart';
import '../../data/api/backend_services_api.dart';
import '../../features/services/backend_services_controllers.dart';
import '../../router.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/formatters.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_service_unavailable.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../widgets/sf_toast.dart';

enum _AiBackendTab { requests, usage }

class BackendAiWorkspaceScreen extends StatefulWidget {
  const BackendAiWorkspaceScreen({super.key, required this.api});

  final BackendServicesApi api;

  @override
  State<BackendAiWorkspaceScreen> createState() =>
      _BackendAiWorkspaceScreenState();
}

class _BackendAiWorkspaceScreenState extends State<BackendAiWorkspaceScreen> {
  late final BackendAiController _controller;
  _AiBackendTab _tab = _AiBackendTab.requests;

  @override
  void initState() {
    super.initState();
    _controller = BackendAiController(widget.api)..refresh();
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
      tab: SfTab.ai,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      safeBottom: true,
      top: Column(
        children: [
          SfLargeAppBar(
            title: _t(context, uz: 'AI ish markazi', en: 'AI operations'),
            subtitle: _t(
              context,
              uz: 'Server so‘rovlari · chat emas',
              en: 'Server requests · not a general chat',
            ),
            leading: IconButton(
              tooltip: _t(context, uz: 'Ortga', en: 'Back'),
              onPressed: () => _back(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              IconButton(
                key: const Key('backend-ai-refresh'),
                tooltip: _t(context, uz: 'Yangilash', en: 'Refresh'),
                onPressed: _controller.refreshing ? null : _controller.refresh,
                icon: _controller.refreshing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                key: const Key('backend-ai-generate-exam'),
                tooltip: _t(
                  context,
                  uz: 'Imtihon yaratish',
                  en: 'Generate exam',
                ),
                onPressed:
                    _controller.isUnavailable ||
                        _controller.hasError ||
                        _controller.serviceDisabled
                    ? null
                    : () => _showExamGenerator(context),
                icon: const Icon(Icons.auto_awesome_rounded),
              ),
            ],
          ),
          Container(
            color: SfTheme.colorsOf(context).surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SfSegmentedControl<_AiBackendTab>(
              expanded: true,
              value: _tab,
              onChanged: (value) => setState(() => _tab = value),
              segments: [
                SfSegment(
                  value: _AiBackendTab.requests,
                  label: _t(context, uz: 'So‘rovlar', en: 'Requests'),
                  icon: Icons.receipt_long_outlined,
                ),
                SfSegment(
                  value: _AiBackendTab.usage,
                  label: _t(context, uz: 'Sarflanish', en: 'Usage'),
                  icon: Icons.insights_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _body(context),
    ),
  );

  Widget _body(BuildContext context) {
    if (_controller.isInitialLoading) {
      return SfLoadingState(
        label: _t(
          context,
          uz: 'AI hisobi yuklanmoqda…',
          en: 'Loading AI account…',
        ),
        message: _t(
          context,
          uz: 'Budjet, so‘rovlar va sarflanish olinmoqda',
          en: 'Fetching budget, requests, and usage',
        ),
      );
    }
    if (_controller.isUnavailable) {
      return SfServiceUnavailable(
        title: _t(
          context,
          uz: 'AI xizmati hozir mavjud emas',
          en: 'AI module unavailable',
        ),
        message: _t(
          context,
          uz: 'Server bu hisob uchun AI xizmatini ochmadi. Xizmat qayta yoqilmaguncha AI amallari xavfsiz bloklandi.',
          en: 'The server has not enabled AI for this account. AI actions are safely blocked until the service is restored.',
        ),
        statusLabel: 'AI · RESTRICTED',
        retryLabel: _t(context, uz: 'Qayta tekshirish', en: 'Check again'),
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }
    if (_controller.hasError) {
      return SfServiceUnavailable(
        title: _t(
          context,
          uz: 'AI xizmati vaqtincha ishlamayapti',
          en: 'AI service is temporarily unavailable',
        ),
        message:
            _controller.errorMessage ??
            _t(
              context,
              uz: 'Server holati tasdiqlanmaguncha barcha AI boshqaruvlari bloklandi.',
              en: 'All AI controls are blocked until the server state can be verified.',
            ),
        statusLabel: 'AI · SERVICE OFFLINE',
        retryLabel: _t(context, uz: 'Qayta urinish', en: 'Try again'),
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }
    if (_controller.serviceDisabled) {
      return SfServiceUnavailable(
        title: _t(
          context,
          uz: 'AI xizmati administrator tomonidan to‘xtatilgan',
          en: 'AI service has been paused by an administrator',
        ),
        message: _t(
          context,
          uz: 'Server budjeti AI o‘chirilganini ko‘rsatmoqda. Xizmat qayta yoqilmaguncha so‘rovlar va generatsiya bloklanadi.',
          en: 'The server budget reports that AI is disabled. Requests and generation remain blocked until the service is enabled again.',
        ),
        icon: Icons.pause_circle_outline_rounded,
        statusLabel: 'AI · PAUSED',
        retryLabel: _t(context, uz: 'Holatni yangilash', en: 'Refresh status'),
        onRetry: () => _controller.refresh(showSpinner: true),
      );
    }

    return AnimatedSwitcher(
      duration: SfMotion.resolve(context, SfMotion.standard),
      child: _tab == _AiBackendTab.requests
          ? _AiRequestsView(
              key: const ValueKey('ai-requests'),
              controller: _controller,
              onOpen: (request) =>
                  context.push('/ai/chat?request=${request.id}'),
              onGenerate: () => _showExamGenerator(context),
            )
          : _AiUsageView(
              key: const ValueKey('ai-usage'),
              controller: _controller,
            ),
    );
  }

  Future<void> _showExamGenerator(BuildContext context) async {
    final queued = await showModalBottomSheet<BackendQueuedRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _ExamGenerationSheet(controller: _controller),
    );
    if (!context.mounted || queued == null) return;
    SfToast.show(
      context,
      title: _t(context, uz: 'Imtihon navbatga qo‘shildi', en: 'Exam queued'),
      message: _t(
        context,
        uz: 'Server so‘rovi #${queued.requestId} · ${queued.status}',
        en: 'Server request #${queued.requestId} · ${queued.status}',
      ),
      tone: SfToastTone.success,
      actionLabel: _t(context, uz: 'Ochish', en: 'Open'),
      onAction: () => context.push('/ai/chat?request=${queued.requestId}'),
    );
  }
}

class BackendAiRequestDetailScreen extends StatefulWidget {
  const BackendAiRequestDetailScreen({
    super.key,
    required this.api,
    required this.requestId,
  });

  final BackendServicesApi api;
  final int? requestId;

  @override
  State<BackendAiRequestDetailScreen> createState() =>
      _BackendAiRequestDetailScreenState();
}

class _BackendAiRequestDetailScreenState
    extends State<BackendAiRequestDetailScreen> {
  BackendAiRequest? _request;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.requestId;
    if (id == null || id <= 0) {
      setState(() {
        _loading = false;
        _error = ArgumentError('A valid AI request ID is required.');
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = BackendAiController(widget.api);
    try {
      final request = await controller.requestDetail(id);
      if (!mounted) return;
      setState(() => _request = request);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      controller.dispose();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    return SfScaffold(
      top: SfNavBar(
        title: widget.requestId == null
            ? _t(context, uz: 'AI so‘rovi', en: 'AI request')
            : _t(
                context,
                uz: 'AI so‘rovi #${widget.requestId}',
                en: 'AI request #${widget.requestId}',
              ),
        leading: IconButton(
          tooltip: _t(context, uz: 'Ortga', en: 'Back'),
          onPressed: () => _back(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            key: const Key('backend-ai-detail-refresh'),
            tooltip: _t(context, uz: 'Yangilash', en: 'Refresh'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && request == null
          ? SfLoadingState(
              label: _t(
                context,
                uz: 'So‘rov yuklanmoqda…',
                en: 'Loading request…',
              ),
            )
          : _error != null && request == null
          ? SfServiceUnavailable(
              title: _t(
                context,
                uz: 'AI so‘rovi ochilmadi',
                en: 'AI request is unavailable',
              ),
              message: _t(
                context,
                uz: 'So‘rov holatini serverdan xavfsiz tasdiqlab bo‘lmadi. Tafsilotlar vaqtincha bloklandi.',
                en: 'The request state could not be safely verified with the server. Details are temporarily blocked.',
              ),
              statusLabel: 'AI · REQUEST BLOCKED',
              retryLabel: _t(context, uz: 'Qayta urinish', en: 'Try again'),
              onRetry: _load,
            )
          : RefreshIndicator.adaptive(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  if (_error != null) ...[
                    SfHintCard(
                      compact: true,
                      tone: SfHintTone.danger,
                      message: '$_error',
                      actionLabel: _t(
                        context,
                        uz: 'Qayta urinish',
                        en: 'Retry',
                      ),
                      onAction: _load,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (request != null) _AiRequestDetailCard(request: request),
                ],
              ),
            ),
    );
  }
}

class _AiRequestsView extends StatelessWidget {
  const _AiRequestsView({
    super.key,
    required this.controller,
    required this.onOpen,
    required this.onGenerate,
  });

  final BackendAiController controller;
  final ValueChanged<BackendAiRequest> onOpen;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => RefreshIndicator.adaptive(
    onRefresh: controller.refresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 28),
      children: [
        const SfHintCard(
          compact: true,
          icon: Icons.info_outline_rounded,
          title: 'Production AI contract',
          message:
              'The backend exposes asynchronous feature requests, budget, exam generation, and usage reporting. It does not expose a general-purpose chat endpoint, so this screen does not fabricate chat replies.',
        ),
        const SizedBox(height: 14),
        if (controller.budgetUnavailable)
          SfHintCard(
            tone: SfHintTone.warning,
            message: _t(
              context,
              uz: 'AI budjeti bu rol uchun ochilmadi.',
              en: 'AI budget is restricted for this role.',
            ),
          )
        else if (controller.budget != null)
          _BudgetCard(budget: controller.budget!),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SfSegmentedControl<String?>(
            value: controller.status,
            onChanged: (value) {
              controller.status = value;
              controller.refresh(showSpinner: true);
            },
            segments: [
              SfSegment(
                value: null,
                label: _t(context, uz: 'Hammasi', en: 'All'),
              ),
              const SfSegment(value: 'queued', label: 'Queued'),
              const SfSegment(value: 'running', label: 'Running'),
              const SfSegment(value: 'succeeded', label: 'Succeeded'),
              const SfSegment(value: 'failed', label: 'Failed'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _t(context, uz: 'Server so‘rovlari', en: 'Server requests'),
                style: SfType.ui(
                  size: 16,
                  weight: FontWeight.w800,
                  color: SfTheme.colorsOf(context).ink,
                ),
              ),
            ),
            SfButton(
              kind: SfButtonKind.soft,
              leading: Icons.quiz_outlined,
              label: _t(context, uz: 'Imtihon', en: 'Exam'),
              onPressed: onGenerate,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (controller.requests.isEmpty)
          SfEmptyState(
            compact: true,
            icon: Icons.auto_awesome_outlined,
            title: _t(context, uz: 'AI so‘rovi yo‘q', en: 'No AI requests'),
            message: _t(
              context,
              uz: 'Tanlangan holat bo‘yicha server so‘rovi yo‘q.',
              en: 'No server request matches this status.',
            ),
            actionLabel: _t(
              context,
              uz: 'Imtihon yaratish',
              en: 'Generate exam',
            ),
            onAction: onGenerate,
          )
        else
          for (final request in controller.requests) ...[
            _AiRequestCard(request: request, onPressed: () => onOpen(request)),
            const SizedBox(height: 11),
          ],
        if (controller.hasMoreRequests)
          SfButton(
            block: true,
            kind: SfButtonKind.ghost,
            label: _t(context, uz: 'Ko‘proq so‘rov', en: 'Load more requests'),
            onPressed: controller.loadingMore ? null : controller.loadMore,
          ),
        if (controller.hasError && controller.hasRenderableData) ...[
          const SizedBox(height: 12),
          SfHintCard(
            compact: true,
            tone: SfHintTone.danger,
            message: controller.errorMessage ?? 'Unknown error',
            actionLabel: _t(context, uz: 'Qayta urinish', en: 'Retry'),
            onAction: controller.refresh,
          ),
        ],
      ],
    ),
  );
}

class _AiUsageView extends StatelessWidget {
  const _AiUsageView({super.key, required this.controller});

  final BackendAiController controller;

  @override
  Widget build(BuildContext context) => RefreshIndicator.adaptive(
    onRefresh: controller.refresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        if (controller.budget != null) _BudgetCard(budget: controller.budget!),
        const SizedBox(height: 18),
        Text(
          _t(
            context,
            uz: 'Joriy oy · xususiyat bo‘yicha',
            en: 'Current month · by feature',
          ),
          style: SfType.ui(
            size: 16,
            weight: FontWeight.w800,
            color: SfTheme.colorsOf(context).ink,
          ),
        ),
        const SizedBox(height: 10),
        if (controller.usageUnavailable)
          SfErrorState(
            compact: true,
            title: _t(
              context,
              uz: 'Sarflanishga ruxsat yo‘q',
              en: 'Usage restricted',
            ),
          )
        else if (controller.usage.isEmpty)
          SfEmptyState(
            compact: true,
            icon: Icons.insights_outlined,
            title: _t(
              context,
              uz: 'Bu oyda sarf yo‘q',
              en: 'No usage this month',
            ),
          )
        else
          for (final row in controller.usage) ...[
            _UsageRow(row: row),
            const SizedBox(height: 10),
          ],
      ],
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});

  final BackendAiBudget budget;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: c.aiBg),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.auto_awesome_rounded, color: c.ai),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        context,
                        uz: 'Tenant AI budjeti',
                        en: 'Tenant AI budget',
                      ),
                      style: SfType.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      budget.isEnabled
                          ? _t(
                              context,
                              uz: 'Serverda yoqilgan',
                              en: 'Enabled on server',
                            )
                          : _t(
                              context,
                              uz: 'Serverda o‘chirilgan',
                              en: 'Disabled on server',
                            ),
                      style: SfType.ui(size: 11.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              SfPill(
                label: budget.isEnabled ? 'Enabled' : 'Disabled',
                tone: budget.isEnabled ? SfPillTone.success : SfPillTone.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BudgetLine(
            label: _t(context, uz: 'Bugun', en: 'Today'),
            used: budget.tokensUsedToday,
            limit: budget.dailyTokenLimit,
          ),
          const SizedBox(height: 13),
          _BudgetLine(
            label: _t(context, uz: 'Bu oy', en: 'This month'),
            used: budget.tokensUsedMonth,
            limit: budget.monthlyTokenLimit,
          ),
        ],
      ),
    );
  }
}

class _BudgetLine extends StatelessWidget {
  const _BudgetLine({
    required this.label,
    required this.used,
    required this.limit,
  });

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: SfType.ui(size: 12, color: c.ink2)),
            ),
            Text(
              '${_compact(used)} / ${_compact(limit)} tokens',
              style: SfType.mono(size: 10.5, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: progress > .9 ? c.danger : c.ai,
            backgroundColor: c.surface2,
          ),
        ),
      ],
    );
  }
}

class _AiRequestCard extends StatelessWidget {
  const _AiRequestCard({required this.request, required this.onPressed});

  final BackendAiRequest request;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _requestTone(request.status);
    return SfSurfaceCard(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tone.$2(c),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(tone.$1, color: tone.$3(c)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _featureLabel(request.feature),
                      style: SfType.ui(
                        size: 14.5,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${request.id} · ${_compact(request.inputTokens + request.outputTokens)} tokens · ${_cost(request.costMicrousd)}',
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                    if (request.createdAt != null)
                      Text(
                        '${SfFormatters.compactDateUz(request.createdAt!)} · ${SfFormatters.time(request.createdAt!)}',
                        style: SfType.ui(size: 10.5, color: c.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SfPill(label: request.status, tone: tone.$4),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right_rounded, color: c.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiRequestDetailCard extends StatelessWidget {
  const _AiRequestDetailCard({required this.request});

  final BackendAiRequest request;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _requestTone(request.status);
    final output = request.outputText?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SfSurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tone.$2(c),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(tone.$1, color: tone.$3(c)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _featureLabel(request.feature),
                          style: SfType.ui(
                            size: 17,
                            weight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          'Request #${request.id}',
                          style: SfType.mono(size: 11, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  SfPill(label: request.status, tone: tone.$4),
                ],
              ),
              const SizedBox(height: 17),
              _DetailLine(
                label: _t(context, uz: 'Kirish tokenlari', en: 'Input tokens'),
                value: '${request.inputTokens}',
              ),
              _DetailLine(
                label: _t(
                  context,
                  uz: 'Chiqish tokenlari',
                  en: 'Output tokens',
                ),
                value: '${request.outputTokens}',
              ),
              _DetailLine(
                label: _t(context, uz: 'Narx', en: 'Cost'),
                value: _cost(request.costMicrousd),
              ),
              _DetailLine(
                label: _t(context, uz: 'Yaratilgan', en: 'Created'),
                value: request.createdAt?.toLocal().toString() ?? '—',
              ),
              _DetailLine(
                label: _t(context, uz: 'Tugagan', en: 'Finished'),
                value: request.finishedAt?.toLocal().toString() ?? '—',
                divider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (output == null || output.isEmpty)
          SfHintCard(
            tone: request.status == 'succeeded'
                ? SfHintTone.info
                : SfHintTone.warning,
            title: _t(
              context,
              uz: 'Natija ko‘rinmaydi',
              en: 'Output not visible',
            ),
            message: request.status == 'succeeded'
                ? _t(
                    context,
                    uz: 'Collection javobi natijani bermaydi. Detail ham bo‘sh bo‘lsa, siz so‘rov egasi emassiz yoki ai:manage ruxsati yo‘q.',
                    en: 'Collection responses omit output. If detail is also empty, you are not the requester and do not hold ai:manage.',
                  )
                : _t(
                    context,
                    uz: 'So‘rov hali natija bermagan. Yuqoridan yangilang.',
                    en: 'This request has no result yet. Refresh from the top.',
                  ),
          )
        else
          SfSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.article_outlined, color: c.ai),
                    const SizedBox(width: 9),
                    Text(
                      _t(context, uz: 'Server natijasi', en: 'Server output'),
                      style: SfType.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                SelectableText(
                  output,
                  style: SfType.ui(size: 13, color: c.ink2, height: 1.55),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.row});

  final BackendJson row;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final input = backendInt(row['input_tokens']);
    final output = backendInt(row['output_tokens']);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _featureLabel(
                    backendString(row['feature'], fallback: 'unknown'),
                  ),
                  style: SfType.ui(
                    size: 14.5,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              SfPill(
                label: '${backendInt(row['requests'])} requests',
                tone: SfPillTone.ai,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _UsageMetric(
                  label: 'Input',
                  value: '${_compact(input)} tok',
                ),
              ),
              Expanded(
                child: _UsageMetric(
                  label: 'Output',
                  value: '${_compact(output)} tok',
                ),
              ),
              Expanded(
                child: _UsageMetric(
                  label: 'Cost',
                  value: _cost(backendInt(row['cost_microusd'])),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageMetric extends StatelessWidget {
  const _UsageMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SfType.ui(size: 10.5, color: c.muted)),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SfType.mono(size: 11, color: c.ink2),
        ),
      ],
    );
  }
}

class _ExamGenerationSheet extends StatefulWidget {
  const _ExamGenerationSheet({required this.controller});

  final BackendAiController controller;

  @override
  State<_ExamGenerationSheet> createState() => _ExamGenerationSheetState();
}

class _ExamGenerationSheetState extends State<_ExamGenerationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectId = TextEditingController();
  final _examType = TextEditingController(text: 'quiz');
  final _questionCount = TextEditingController(text: '10');
  String _difficulty = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectId.dispose();
    _examType.dispose();
    _questionCount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final queued = await widget.controller.generateExam(
        subjectId: int.parse(_subjectId.text.trim()),
        examType: _examType.text.trim(),
        questionCount: int.parse(_questionCount.text.trim()),
        difficulty: _difficulty,
      );
      if (mounted) Navigator.pop(context, queued);
    } catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        title: _t(
          context,
          uz: 'Generatsiya boshlanmadi',
          en: 'Generation not started',
        ),
        message: error.toString(),
        tone: SfToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(
                context,
                uz: 'AI imtihon generatsiyasi',
                en: 'AI exam generation',
              ),
              style: SfType.ui(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SfHintCard(
              compact: true,
              tone: SfHintTone.ai,
              message: _t(
                context,
                uz: 'Bu asinxron server so‘rovini yaratadi. Natija AI so‘rovlari ichida paydo bo‘ladi.',
                en: 'This creates an asynchronous server request. Its result appears in AI requests.',
              ),
            ),
            const SizedBox(height: 16),
            SfTextField(
              controller: _subjectId,
              label: _t(context, uz: 'Fan ID', en: 'Subject ID'),
              keyboardType: TextInputType.number,
              validator: _positive,
            ),
            const SizedBox(height: 12),
            SfTextField(
              controller: _examType,
              label: _t(context, uz: 'Imtihon turi', en: 'Exam type'),
              helper: 'For example: quiz, final, practice',
              maxLength: 32,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Exam type is required'
                  : null,
            ),
            const SizedBox(height: 12),
            SfTextField(
              controller: _questionCount,
              label: _t(context, uz: 'Savollar soni', en: 'Question count'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final count = int.tryParse(value?.trim() ?? '');
                return count == null || count < 1 || count > 200
                    ? 'Enter a value from 1 to 200'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            SfSegmentedControl<String>(
              expanded: true,
              value: _difficulty,
              onChanged: (value) => setState(() => _difficulty = value),
              segments: const [
                SfSegment(value: 'easy', label: 'Easy'),
                SfSegment(value: 'medium', label: 'Medium'),
                SfSegment(value: 'hard', label: 'Hard'),
              ],
            ),
            const SizedBox(height: 18),
            SfButton(
              key: const Key('backend-ai-submit-exam'),
              block: true,
              leading: Icons.auto_awesome_rounded,
              label: _submitting
                  ? _t(context, uz: 'Navbatga qo‘yilmoqda…', en: 'Queuing…')
                  : _t(
                      context,
                      uz: 'Server so‘rovini yaratish',
                      en: 'Create server request',
                    ),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: SfType.ui(size: 12, color: c.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: SfType.mono(size: 11.5, color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

(IconData, Color Function(SfColors), Color Function(SfColors), SfPillTone)
_requestTone(String status) => switch (status) {
  'succeeded' => (
    Icons.check_rounded,
    (c) => c.successSoft,
    (c) => c.success,
    SfPillTone.success,
  ),
  'failed' || 'denied_budget' => (
    Icons.error_outline_rounded,
    (c) => c.dangerSoft,
    (c) => c.danger,
    SfPillTone.danger,
  ),
  'running' => (
    Icons.sync_rounded,
    (c) => c.primarySoft,
    (c) => c.primary,
    SfPillTone.primary,
  ),
  _ => (
    Icons.schedule_rounded,
    (c) => c.warnSoft,
    (c) => c.warn,
    SfPillTone.warn,
  ),
};

String _featureLabel(String feature) => switch (feature) {
  'assignment_feedback' => 'Assignment feedback',
  'exam_generation' => 'Exam generation',
  'content_summary' => 'Content summary',
  'placement_generation' => 'Placement generation',
  'form_analysis' => 'Form analysis',
  'writing_marking' => 'Writing marking',
  'material_generation' => 'Material generation',
  'template_generation' => 'Message template generation',
  _ => feature.replaceAll('_', ' '),
};

String _compact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String _cost(int microusd) => '\$${(microusd / 1000000).toStringAsFixed(4)}';

String? _positive(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed <= 0 ? 'Enter a positive integer' : null;
}

String _t(BuildContext context, {required String uz, required String en}) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/more');
  }
}
