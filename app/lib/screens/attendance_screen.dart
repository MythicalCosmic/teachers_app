import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';
import 'groups/group_attendance_capture_screen.dart';
import 'groups/group_l10n.dart';
import 'groups/group_workspace_store.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({
    super.key,
    this.cohortId,
    this.lessonId,
    this.lessonAt,
    this.lessonTitle,
    this.store,
  });

  final String? cohortId;
  final String? lessonId;
  final DateTime? lessonAt;
  final String? lessonTitle;
  final GroupWorkspaceStore? store;

  @override
  Widget build(BuildContext context) {
    final selectedCohortId = cohortId;
    if (selectedCohortId != null && selectedCohortId.trim().isNotEmpty) {
      return GroupAttendanceCaptureScreen(
        groupId: selectedCohortId,
        lessonId: lessonId,
        lessonAt: lessonAt,
        lessonTitle: lessonTitle,
        store: store,
      );
    }
    final state = AppScope.of(context);
    if (state.attendanceSheets.isEmpty) {
      return Scaffold(
        body: SfEmptyState(
          title: context.gt('empty_sheet'),
          message: context.gt('empty_sheet_message'),
        ),
      );
    }
    final sheet = state.attendanceSheets.first;
    final canEdit =
        state.can(StaffCapability.takeAttendance) && !sheet.isSubmitted;
    return SfScaffold(
      top: _AttendanceHeader(sheet: sheet),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          SfHintCard(
            title: sheet.isSubmitted
                ? context.gt('submitted')
                : context.gt('quick_mark'),
            message: sheet.isSubmitted
                ? context.gt('sheet_locked')
                : canEdit
                ? context.gt('mark_instructions')
                : context.gt('no_permission'),
            tone: sheet.isSubmitted
                ? SfHintTone.success
                : canEdit
                ? SfHintTone.info
                : SfHintTone.danger,
          ),
          const SizedBox(height: 12),
          for (final entry in sheet.entries) ...[
            _AttendanceRow(sheet: sheet, entry: entry, enabled: canEdit),
            const SizedBox(height: 7),
          ],
        ],
      ),
      bottom: _AttendanceFooter(sheet: sheet, enabled: canEdit),
    );
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.sheet});

  final AttendanceSheet sheet;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final counts = {
      for (final status in AttendanceStatus.values)
        status: sheet.entries.where((entry) => entry.status == status).length,
    };
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: context.gt('back'),
                  onPressed: context.pop,
                  icon: Icon(SfIcons.arrowL, color: c.primary),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${sheet.cohortName} · ${sheet.lessonName}',
                      style: SfType.ui(size: 11, color: c.muted),
                    ),
                    Text(
                      context.gt('attendance'),
                      style: SfType.ui(
                        size: 15,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Row(
            children: [
              _Count(
                label: context.gt('present'),
                value: counts[AttendanceStatus.present]!,
                color: c.success,
              ),
              _Count(
                label: context.gt('absent'),
                value: counts[AttendanceStatus.absent]!,
                color: c.danger,
              ),
              _Count(
                label: context.gt('late'),
                value: counts[AttendanceStatus.late]!,
                color: c.warn,
              ),
              _Count(
                label: context.gt('excused'),
                value: counts[AttendanceStatus.excused]!,
                color: c.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: SfType.mono(
                size: 20,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: SfType.eyebrow(color: c.muted, size: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.sheet,
    required this.entry,
    required this.enabled,
  });

  final AttendanceSheet sheet;
  final AttendanceEntry entry;
  final bool enabled;

  Future<void> _select(BuildContext context, AttendanceStatus status) async {
    final appState = AppScope.of(context);
    String? note;
    if (status == AttendanceStatus.absent ||
        status == AttendanceStatus.excused) {
      note = await _askReason(context, status);
      if (note == null) return;
    } else if (status == AttendanceStatus.late) {
      note = context.gt('late_note');
    }
    final previous = entry.status;
    final previousNote = entry.note;
    try {
      await appState.markAttendance(
        sheetId: sheet.id,
        studentId: entry.studentId,
        status: status,
        note: note,
      );
      if (!context.mounted) return;
      SfToast.show(
        context,
        title: entry.studentName,
        message: context.gt(
          'marked_status',
          values: {'status': _statusLabel(context, status)},
        ),
        tone: SfToastTone.success,
        actionLabel: previous == null ? null : context.gt('undo'),
        onAction: previous == null
            ? null
            : () => AppScope.of(context).markAttendance(
                sheetId: sheet.id,
                studentId: entry.studentId,
                status: previous,
                note: previousNote,
              ),
      );
    } on Object catch (error) {
      if (context.mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    }
  }

  Future<String?> _askReason(
    BuildContext context,
    AttendanceStatus status,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          status == AttendanceStatus.absent
              ? context.gt('absence_reason')
              : context.gt('excused_reason'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(hintText: context.gt('short_reason')),
        ),
        actions: [
          TextButton(
            onPressed: dialogContext.pop,
            child: Text(context.gt('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                dialogContext.pop(controller.text.trim());
              }
            },
            child: Text(context.gt('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _statusColor(context, entry.status);
    return Semantics(
      label:
          '${entry.studentName}, ${entry.status == null ? context.gt('unmarked') : _statusLabel(context, entry.status!)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
        decoration: BoxDecoration(
          color: entry.status == null ? c.surface : tone.withValues(alpha: .09),
          border: Border.all(
            color: entry.status == null
                ? c.border
                : tone.withValues(alpha: .25),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SfAvatar(name: entry.studentName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.studentName,
                    style: SfType.ui(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    entry.note ?? entry.studentId,
                    style: SfType.mono(
                      size: 10,
                      color: entry.note == null ? c.muted : tone,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              PopupMenuButton<AttendanceStatus>(
                tooltip: context.gt('select_status'),
                initialValue: entry.status,
                onSelected: (value) => _select(context, value),
                itemBuilder: (_) => [
                  for (final status in AttendanceStatus.values)
                    PopupMenuItem(
                      value: status,
                      child: Text(_statusLabel(context, status)),
                    ),
                ],
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 76,
                    minHeight: 44,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.status == null
                        ? context.gt('choose')
                        : _statusLabel(context, entry.status!),
                    style: SfType.ui(
                      size: 11,
                      weight: FontWeight.w800,
                      color: tone,
                    ),
                  ),
                ),
              )
            else
              Text(
                entry.status == null
                    ? '—'
                    : _statusLabel(context, entry.status!),
                style: SfType.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  color: tone,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceFooter extends StatelessWidget {
  const _AttendanceFooter({required this.sheet, required this.enabled});
  final AttendanceSheet sheet;
  final bool enabled;

  Future<void> _submit(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.gt('confirm_send')),
            content: Text(context.gt('confirm_send_body')),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: Text(context.gt('cancel')),
              ),
              FilledButton(
                onPressed: () => dialogContext.pop(true),
                child: Text(context.gt('send')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    try {
      await AppScope.of(context).submitAttendance(sheet.id);
      if (!context.mounted) return;
      SfToast.show(
        context,
        title: context.gt('accepted'),
        message: context.gt(
          'sent_summary',
          values: {'group': sheet.cohortName, 'count': sheet.entries.length},
        ),
        tone: SfToastTone.success,
      );
    } on Object catch (error) {
      if (context.mounted) {
        SfToast.show(context, message: '$error', tone: SfToastTone.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final marked = sheet.entries.where((entry) => entry.status != null).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.gt(
                    'marked_progress',
                    values: {'marked': marked, 'total': sheet.entries.length},
                  ),
                  style: SfType.mono(size: 11, color: c.muted),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: marked / sheet.entries.length,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(5),
                  color: c.primary,
                  backgroundColor: c.surface3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SfButton(
            kind: SfButtonKind.primary,
            label: sheet.isSubmitted ? context.gt('sent') : context.gt('send'),
            trailing: sheet.isSubmitted ? SfIcons.check : SfIcons.arrowR,
            onPressed: enabled && sheet.isComplete
                ? () => _submit(context)
                : null,
          ),
        ],
      ),
    );
  }
}

String _statusLabel(BuildContext context, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.present => context.gt('present'),
      AttendanceStatus.absent => context.gt('absent'),
      AttendanceStatus.late => context.gt('late'),
      AttendanceStatus.excused => context.gt('excused'),
    };

Color _statusColor(BuildContext context, AttendanceStatus? status) {
  final c = SfTheme.colorsOf(context);
  return switch (status) {
    AttendanceStatus.present => c.success,
    AttendanceStatus.absent => c.danger,
    AttendanceStatus.late => c.warn,
    AttendanceStatus.excused => c.muted,
    null => c.primary,
  };
}
