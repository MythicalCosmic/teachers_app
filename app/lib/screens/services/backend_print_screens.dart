import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../widgets/sf_toast.dart';

class BackendPrintScreen extends StatefulWidget {
  const BackendPrintScreen({super.key, required this.api});

  final BackendServicesApi api;

  @override
  State<BackendPrintScreen> createState() => _BackendPrintScreenState();
}

class _BackendPrintScreenState extends State<BackendPrintScreen> {
  late final BackendPrintController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BackendPrintController(widget.api)..refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _newJob() async {
    final created = await context.push<bool>('/print/new');
    if (created == true && mounted) await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => SfScaffold(
      tab: SfTab.print,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: Column(
        children: [
          SfLargeAppBar(
            title: _text(context, uz: 'Print navbati', en: 'Print queue'),
            subtitle: _text(
              context,
              uz: '${_controller.jobs.length} server ishi · ${_controller.printers.length} faol printer',
              en: '${_controller.jobs.length} server jobs · ${_controller.printers.length} active printers',
            ),
            actions: [
              IconButton(
                key: const Key('backend-print-refresh'),
                tooltip: _text(context, uz: 'Yangilash', en: 'Refresh'),
                onPressed: _controller.refreshing ? null : _controller.refresh,
                icon: _controller.refreshing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                key: const Key('backend-print-new-job'),
                tooltip: _text(context, uz: 'Yangi ish', en: 'New job'),
                onPressed: _newJob,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          Container(
            color: SfTheme.colorsOf(context).surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SfSegmentedControl<String?>(
                value: _controller.status,
                onChanged: _controller.setStatus,
                segments: [
                  SfSegment(
                    value: null,
                    label: _text(context, uz: 'Hammasi', en: 'All'),
                  ),
                  const SfSegment(value: 'queued', label: 'Queued'),
                  const SfSegment(value: 'printing', label: 'Printing'),
                  const SfSegment(value: 'done', label: 'Done'),
                  const SfSegment(value: 'failed', label: 'Failed'),
                ],
              ),
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
        label: _text(
          context,
          uz: 'Print navbati yuklanmoqda…',
          en: 'Loading print queue…',
        ),
      );
    }
    if (_controller.isUnavailable) {
      return SfErrorState(
        title: _text(
          context,
          uz: 'Print moduliga ruxsat yo‘q',
          en: 'Print module unavailable',
        ),
        message: _text(
          context,
          uz: 'Server bu xodim hisobiga print ishlarini ko‘rsatishga ruxsat bermadi.',
          en: 'The server did not grant this staff account access to print jobs.',
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
        key: const PageStorageKey('backend-print-queue'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 28),
        children: [
          const SfHintCard(
            compact: true,
            icon: Icons.print_outlined,
            title: 'Agent-owned queue',
            message:
                'The branch print agent owns claim, retry, progress, and completion. This app only creates and observes jobs because the staff API has no cancel or retry action.',
          ),
          const SizedBox(height: 14),
          _QueueSummary(jobs: _controller.jobs),
          const SizedBox(height: 18),
          _Heading(
            title: _text(context, uz: 'Faol printerlar', en: 'Active printers'),
            count: _controller.printers.length,
          ),
          const SizedBox(height: 9),
          if (_controller.printersUnavailable)
            SfHintCard(
              compact: true,
              tone: SfHintTone.warning,
              message: _text(
                context,
                uz: 'Printer katalogi bu rolda ochilmadi.',
                en: 'The printer catalog is restricted for this role.',
              ),
            )
          else if (_controller.printers.isEmpty)
            SfEmptyState(
              compact: true,
              icon: Icons.print_disabled_outlined,
              title: _text(
                context,
                uz: 'Faol printer yo‘q',
                en: 'No active printers',
              ),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _controller.printers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _PrinterCard(printer: _controller.printers[index]),
              ),
            ),
          const SizedBox(height: 20),
          _Heading(
            title: _text(context, uz: 'Server ishlari', en: 'Server jobs'),
            count: _controller.jobs.length,
          ),
          const SizedBox(height: 10),
          if (_controller.jobs.isEmpty)
            SfEmptyState(
              compact: true,
              icon: Icons.inbox_outlined,
              title: _text(context, uz: 'Ish topilmadi', en: 'No print jobs'),
              message: _text(
                context,
                uz: 'Tanlangan holat bo‘yicha server ishi yo‘q.',
                en: 'No server job matches the selected status.',
              ),
              actionLabel: _text(context, uz: 'Yangi ish', en: 'New job'),
              onAction: _newJob,
            )
          else
            for (final job in _controller.jobs) ...[
              _PrintJobCard(job: job),
              const SizedBox(height: 11),
            ],
          if (_controller.hasMoreJobs)
            SfButton(
              block: true,
              kind: SfButtonKind.ghost,
              label: _text(context, uz: 'Ko‘proq ish', en: 'Load more jobs'),
              onPressed: _controller.loadingMore ? null : _controller.loadMore,
            ),
          if (_controller.hasError && _controller.hasRenderableData) ...[
            const SizedBox(height: 12),
            SfHintCard(
              compact: true,
              tone: SfHintTone.danger,
              message: _controller.errorMessage ?? 'Unknown error',
              actionLabel: _text(context, uz: 'Qayta urinish', en: 'Retry'),
              onAction: _controller.refresh,
            ),
          ],
        ],
      ),
    );
  }
}

class BackendNewPrintJobScreen extends StatefulWidget {
  const BackendNewPrintJobScreen({super.key, required this.api});

  final BackendServicesApi api;

  @override
  State<BackendNewPrintJobScreen> createState() =>
      _BackendNewPrintJobScreenState();
}

class _BackendNewPrintJobScreenState extends State<BackendNewPrintJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceId = TextEditingController();
  final _payloadKey = TextEditingController();
  final _branchId = TextEditingController();
  final _pages = TextEditingController(text: '1');
  final _copies = TextEditingController(text: '1');
  final _cohortId = TextEditingController();
  String _source = 'assignment';
  bool _color = false;
  bool _duplex = false;
  bool _submitting = false;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final query = GoRouterState.of(context).uri.queryParameters;
    final payloadKey = query['payload_key']?.trim();
    if (payloadKey != null && payloadKey.isNotEmpty) {
      _payloadKey.text = payloadKey;
    }
    final source = query['source'];
    if (const {
      'assignment',
      'transcript',
      'report',
      'receipt',
    }.contains(source)) {
      _source = source!;
    }
    _sourceId.text = query['source_id'] ?? '';
    _branchId.text = query['branch'] ?? '';
  }

  @override
  void dispose() {
    _sourceId.dispose();
    _payloadKey.dispose();
    _branchId.dispose();
    _pages.dispose();
    _copies.dispose();
    _cohortId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final controller = BackendPrintController(widget.api);
    try {
      final job = await controller.createJob(
        source: _source,
        sourceId: int.parse(_sourceId.text.trim()),
        payloadKey: _payloadKey.text.trim(),
        branchId: int.parse(_branchId.text.trim()),
        pages: int.parse(_pages.text.trim()),
        copies: int.parse(_copies.text.trim()),
        color: _color,
        duplex: _duplex,
        cohortId: _optionalInt(_cohortId.text),
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: _text(
          context,
          uz: 'Print ishi yaratildi',
          en: 'Print job created',
        ),
        message: '#${job.id} · ${job.status}',
        tone: SfToastTone.success,
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        title: _text(
          context,
          uz: 'Server rad etdi',
          en: 'Server rejected the job',
        ),
        message: error.toString(),
        tone: SfToastTone.error,
      );
    } finally {
      controller.dispose();
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SfScaffold(
    dismissKeyboardOnTap: true,
    top: SfNavBar(
      title: _text(context, uz: 'Yangi print ishi', en: 'New print job'),
      leading: TextButton(
        onPressed: () => context.pop(false),
        child: Text(_text(context, uz: 'Bekor', en: 'Cancel')),
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          SfHintCard(
            tone: SfHintTone.warning,
            title: _text(
              context,
              uz: 'Server hujjati talab qilinadi',
              en: 'Server document required',
            ),
            message: _text(
              context,
              uz: 'Bu forma lokal faylni yuklamaydi. payload S3 key allaqachon shu tenantga tegishli server obyektiga ishora qilishi va hisob source obyektini o‘qiy olishi kerak.',
              en: 'This form does not upload a local file. The payload S3 key must already point to an object owned by this tenant, and your account must be allowed to read the source record.',
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _source,
            decoration: InputDecoration(
              labelText: _text(context, uz: 'Manba turi', en: 'Source type'),
            ),
            items: const [
              DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
              DropdownMenuItem(value: 'transcript', child: Text('Transcript')),
              DropdownMenuItem(value: 'report', child: Text('Report')),
              DropdownMenuItem(value: 'receipt', child: Text('Receipt')),
            ],
            onChanged: (value) => setState(() => _source = value!),
          ),
          const SizedBox(height: 12),
          SfTextField(
            controller: _sourceId,
            label: _text(context, uz: 'Manba ID', en: 'Source ID'),
            keyboardType: TextInputType.number,
            validator: _positiveInt,
          ),
          const SizedBox(height: 12),
          SfTextField(
            controller: _payloadKey,
            label: 'payload_s3_key',
            helper: _text(
              context,
              uz: 'Prod storage ichidagi aniq obyekt kaliti',
              en: 'Exact object key in production storage',
            ),
            minLines: 2,
            maxLines: 3,
            validator: (value) => value == null || value.trim().isEmpty
                ? _text(
                    context,
                    uz: 'Kalitni kiriting',
                    en: 'Enter an object key',
                  )
                : null,
          ),
          const SizedBox(height: 12),
          SfTextField(
            controller: _branchId,
            label: _text(context, uz: 'Filial ID', en: 'Branch ID'),
            keyboardType: TextInputType.number,
            validator: _positiveInt,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SfTextField(
                  controller: _pages,
                  label: _text(context, uz: 'Sahifa', en: 'Pages'),
                  keyboardType: TextInputType.number,
                  validator: _positiveInt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SfTextField(
                  controller: _copies,
                  label: _text(context, uz: 'Nusxa', en: 'Copies'),
                  keyboardType: TextInputType.number,
                  validator: _positiveInt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SfTextField(
            controller: _cohortId,
            label: _text(
              context,
              uz: 'Guruh ID (ixtiyoriy)',
              en: 'Cohort ID (optional)',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return _positiveInt(value);
            },
          ),
          const SizedBox(height: 15),
          SfSurfaceCard(
            child: Column(
              children: [
                SfSwitchTile(
                  title: _text(context, uz: 'Rangli', en: 'Color'),
                  subtitle: _text(
                    context,
                    uz: 'Printer agenti qo‘llasa rangli chiqaradi',
                    en: 'Uses color if the branch agent supports it',
                  ),
                  value: _color,
                  onChanged: (value) => setState(() => _color = value),
                ),
                SfSwitchTile(
                  title: _text(context, uz: 'Ikki tomonlama', en: 'Duplex'),
                  value: _duplex,
                  onChanged: (value) => setState(() => _duplex = value),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SfButton(
            key: const Key('backend-print-submit'),
            block: true,
            leading: Icons.print_rounded,
            label: _submitting
                ? _text(context, uz: 'Navbatga qo‘yilmoqda…', en: 'Queuing…')
                : _text(
                    context,
                    uz: 'Server navbatiga qo‘shish',
                    en: 'Add to server queue',
                  ),
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    ),
  );
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({required this.jobs});

  final List<BackendPrintJob> jobs;

  @override
  Widget build(BuildContext context) {
    final values = <(String, int, IconData, SfPillTone)>[
      (
        _text(context, uz: 'Kutmoqda', en: 'Queued'),
        jobs.where((item) => item.status == 'queued').length,
        Icons.schedule_rounded,
        SfPillTone.warn,
      ),
      (
        _text(context, uz: 'Jarayonda', en: 'Active'),
        jobs
            .where(
              (item) => item.status == 'picked' || item.status == 'printing',
            )
            .length,
        Icons.print_rounded,
        SfPillTone.primary,
      ),
      (
        _text(context, uz: 'Tayyor', en: 'Done'),
        jobs.where((item) => item.status == 'done').length,
        Icons.check_circle_outline_rounded,
        SfPillTone.success,
      ),
      (
        _text(context, uz: 'Xato', en: 'Failed'),
        jobs.where((item) => item.status == 'failed').length,
        Icons.error_outline_rounded,
        SfPillTone.danger,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in values)
              SizedBox(
                width: itemWidth,
                child: _Metric(value: value),
              ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value});

  final (String, int, IconData, SfPillTone) value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(value.$3, color: c.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${value.$2}',
                  style: SfType.ui(
                    size: 21,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(value.$1, style: SfType.ui(size: 11, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrinterCard extends StatelessWidget {
  const _PrinterCard({required this.printer});

  final BackendPrinter printer;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      width: 220,
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: c.successSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.print_rounded, color: c.success),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    '${printer.modelName.isEmpty ? 'Printer' : printer.modelName} · branch ${printer.branchId}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintJobCard extends StatelessWidget {
  const _PrintJobCard({required this.job});

  final BackendPrintJob job;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _jobTone(job.status);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: tone.$2(c),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(tone.$1, color: tone.$3(c)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_sourceLabel(job.source)} #${job.sourceId ?? '—'}',
                      style: SfType.ui(
                        size: 14.5,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Job #${job.id} · branch ${job.branchId ?? '—'} · ${job.pages} × ${job.copies}',
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                  ],
                ),
              ),
              SfPill(label: job.status, tone: tone.$4),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: job.pages <= 0
                  ? null
                  : (job.pagesPrinted / (job.pages * job.copies)).clamp(0, 1),
              color: tone.$3(c),
              backgroundColor: c.surface2,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              SfPill(label: job.color ? 'Color' : 'Mono'),
              SfPill(label: job.duplex ? 'Duplex' : 'Single side'),
              SfPill(label: '${job.pagesPrinted} printed'),
              SfPill(label: '${job.attempts} attempts'),
            ],
          ),
          if (job.lastError.isNotEmpty) ...[
            const SizedBox(height: 11),
            SfHintCard(
              compact: true,
              tone: SfHintTone.danger,
              title: _text(context, uz: 'Agent xatosi', en: 'Agent error'),
              message: job.lastError,
            ),
          ],
          const SizedBox(height: 9),
          Text(
            job.createdAt == null
                ? job.payloadKey
                : '${SfFormatters.fullDateUz(job.createdAt!)} · ${SfFormatters.time(job.createdAt!)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SfType.mono(size: 10.5, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SfType.ui(size: 15, weight: FontWeight.w800, color: c.ink),
          ),
        ),
        Text('$count', style: SfType.mono(size: 11, color: c.muted)),
      ],
    );
  }
}

(IconData, Color Function(SfColors), Color Function(SfColors), SfPillTone)
_jobTone(String status) => switch (status) {
  'done' => (
    Icons.check_rounded,
    (c) => c.successSoft,
    (c) => c.success,
    SfPillTone.success,
  ),
  'failed' => (
    Icons.error_outline_rounded,
    (c) => c.dangerSoft,
    (c) => c.danger,
    SfPillTone.danger,
  ),
  'printing' || 'picked' => (
    Icons.print_rounded,
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

String _sourceLabel(String value) => switch (value) {
  'assignment' => 'Assignment',
  'transcript' => 'Transcript',
  'report' => 'Report',
  'receipt' => 'Receipt',
  _ => value,
};

String? _positiveInt(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed <= 0 ? 'Enter a positive integer' : null;
}

int? _optionalInt(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : int.parse(trimmed);
}

String _text(BuildContext context, {required String uz, required String en}) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'uz' ? uz : en;
