import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_toast.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../router.dart';

enum _PrintFilter { all, active, problem }

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  _PrintFilter _filter = _PrintFilter.all;

  bool _matches(PrintJob job) => switch (_filter) {
    _PrintFilter.all => true,
    _PrintFilter.active =>
      job.status == PrintJobStatus.queued ||
          job.status == PrintJobStatus.printing,
    _PrintFilter.problem =>
      job.status == PrintJobStatus.failed ||
          job.status == PrintJobStatus.cancelled,
  };

  Future<void> _perform(
    Future<void> Function() action,
    String successMessage,
  ) async {
    final app = AppScope.of(context);
    try {
      await action();
      if (!mounted) return;
      SfToast.show(
        context,
        message: successMessage,
        tone: SfToastTone.success,
        glassEnabled: app.settings.liquidGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
    } on Object catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        message: error.toString(),
        tone: SfToastTone.error,
        glassEnabled: app.settings.liquidGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null || !session.can(StaffCapability.submitPrintJobs)) {
      return const SfScaffold(
        body: SfErrorState(title: 'Print xizmatiga ruxsat yo‘q'),
      );
    }
    final managesQueue = session.can(StaffCapability.managePrintQueue);
    final jobs =
        app.printJobs
            .where((job) {
              final visible =
                  managesQueue || job.requestedById == session.userId;
              return visible && _matches(job);
            })
            .toList(growable: false)
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    return SfScaffold(
      tab: SfTab.print,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: Column(
        children: [
          SfLargeAppBar(
            title: managesQueue ? 'Print navbati' : 'Print',
            subtitle: managesQueue
                ? 'Filialdagi barcha ishlar'
                : 'Mening chop etishlarim',
            actions: [
              IconButton(
                tooltip: 'Yangi chop etish',
                onPressed: () => context.push('/print/new'),
                icon: const Icon(SfIcons.plus),
              ),
            ],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SfSegmentedControl<_PrintFilter>(
              expanded: true,
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              segments: const [
                SfSegment(value: _PrintFilter.all, label: 'Hammasi'),
                SfSegment(value: _PrintFilter.active, label: 'Jarayonda'),
                SfSegment(value: _PrintFilter.problem, label: 'Muammo'),
              ],
            ),
          ),
        ],
      ),
      body: jobs.isEmpty
          ? SfEmptyState(
              title: 'Print ishi yo‘q',
              message: _filter == _PrintFilter.all
                  ? 'Birinchi materialni navbatga qo‘shing.'
                  : 'Bu filtrga mos ish topilmadi.',
              icon: SfIcons.printer,
              actionLabel: _filter == _PrintFilter.all
                  ? 'Yangi chop etish'
                  : 'Filtrni tozalash',
              onAction: _filter == _PrintFilter.all
                  ? () => context.push('/print/new')
                  : () => setState(() => _filter = _PrintFilter.all),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                SfHintCard(
                  compact: true,
                  tone: managesQueue ? SfHintTone.warning : SfHintTone.info,
                  title: managesQueue ? 'Navbat boshqaruvi' : 'Shaxsiy navbat',
                  message: managesQueue
                      ? 'Siz barcha xodimlar ishlarini yakunlash yoki qayta yuborishingiz mumkin.'
                      : 'Faqat o‘zingiz yuborgan ishlarni boshqarasiz.',
                ),
                const SizedBox(height: 12),
                for (final job in jobs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PrintJobCard(
                      job: job,
                      managesQueue: managesQueue,
                      isMine: job.requestedById == session.userId,
                      onCancel: () => _perform(
                        () => app.cancelPrintJob(job.id),
                        'Print ishi bekor qilindi',
                      ),
                      onRetry: () => _perform(
                        () => app.retryPrintJob(job.id),
                        'Print ishi qayta navbatga qo‘shildi',
                      ),
                      onComplete: () => _perform(
                        () => app.updatePrintJob(
                          job.id,
                          status: PrintJobStatus.completed,
                          progress: 1,
                        ),
                        'Print ishi yakunlandi',
                      ),
                    ),
                  ),
              ],
            ),
      bottom: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: SfButton(
          block: true,
          height: 48,
          label: 'Yangi chop etish',
          leading: SfIcons.plus,
          haptic: app.settings.haptics,
          motionEnabled: !app.settings.reducedMotion,
          onPressed: () => context.push('/print/new'),
        ),
      ),
    );
  }
}

class _PrintJobCard extends StatelessWidget {
  const _PrintJobCard({
    required this.job,
    required this.managesQueue,
    required this.isMine,
    required this.onCancel,
    required this.onRetry,
    required this.onComplete,
  });

  final PrintJob job;
  final bool managesQueue;
  final bool isMine;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final status = switch (job.status) {
      PrintJobStatus.queued => ('Navbatda', SfPillTone.neutral, c.muted),
      PrintJobStatus.printing => (
        'Chop etilmoqda',
        SfPillTone.primary,
        c.primary,
      ),
      PrintJobStatus.completed => ('Tayyor', SfPillTone.success, c.success),
      PrintJobStatus.failed => ('Xato', SfPillTone.danger, c.danger),
      PrintJobStatus.cancelled => ('Bekor qilingan', SfPillTone.warn, c.warn),
    };
    final canCancel =
        (isMine || managesQueue) &&
        (job.status == PrintJobStatus.queued ||
            job.status == PrintJobStatus.printing);
    final canRetry =
        (isMine || managesQueue) &&
        (job.status == PrintJobStatus.failed ||
            job.status == PrintJobStatus.cancelled);

    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(SfIcons.printer, color: status.$3, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.documentName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${job.copies} nusxa · ${job.pageCount} bet · ${job.printerName}',
                      style: SfType.ui(size: 11.5, color: c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SfPill(tone: status.$2, label: status.$1),
            ],
          ),
          if (job.status == PrintJobStatus.printing ||
              job.status == PrintJobStatus.queued) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: job.status == PrintJobStatus.queued ? 0 : job.progress,
                minHeight: 5,
                backgroundColor: c.surface3,
                color: c.primary,
              ),
            ),
          ],
          if (job.failureReason != null) ...[
            const SizedBox(height: 9),
            Text(
              job.failureReason!,
              style: SfType.ui(size: 11.5, color: c.danger),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  SfFormatters.relativeUz(job.requestedAt),
                  style: SfType.mono(size: 9.5, color: c.muted),
                ),
              ),
              if (canCancel)
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Bekor qilish'),
                ),
              if (canRetry)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Qayta yuborish'),
                ),
              if (managesQueue && job.status == PrintJobStatus.printing)
                TextButton(
                  onPressed: onComplete,
                  child: const Text('Yakunlash'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
