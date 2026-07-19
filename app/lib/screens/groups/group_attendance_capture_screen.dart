import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import 'group_l10n.dart';
import '../groups/group_workspace_store.dart';

class GroupAttendanceCaptureScreen extends StatefulWidget {
  const GroupAttendanceCaptureScreen({
    super.key,
    required this.groupId,
    this.store,
    this.lessonId,
    this.lessonAt,
    this.lessonTitle,
  });

  final String groupId;
  final GroupWorkspaceStore? store;
  final String? lessonId;
  final DateTime? lessonAt;
  final String? lessonTitle;

  @override
  State<GroupAttendanceCaptureScreen> createState() =>
      _GroupAttendanceCaptureScreenState();
}

class _GroupAttendanceCaptureScreenState
    extends State<GroupAttendanceCaptureScreen> {
  late final GroupWorkspaceStore _store;
  String _query = '';
  bool _submitting = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? groupWorkspaceStore;
    unawaited(_restore());
  }

  Future<void> _restore() async {
    await _store.restore();
    _store.beginAttendance(
      widget.groupId,
      lessonId: widget.lessonId,
      lessonAt: widget.lessonAt,
      lessonTitle: widget.lessonTitle,
    );
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _chooseLesson() async {
    final group = _store.group(widget.groupId);
    if (group.lessons.isEmpty) return;
    final selected = await showModalBottomSheet<GroupLesson>(
      context: context,
      showDragHandle: true,
      backgroundColor: SfTheme.colorsOf(context).surface,
      builder: (context) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                context.gt('lesson_type'),
                style: SfType.ui(
                  size: 17,
                  weight: FontWeight.w800,
                  color: SfTheme.colorsOf(context).ink,
                ),
              ),
            ),
            for (final lesson in group.lessons)
              ListTile(
                key: ValueKey('capture-lesson-${lesson.id}'),
                leading: const Icon(SfIcons.book),
                title: Text(lesson.topic),
                subtitle: Text(
                  '${_dateLabel(lesson.startsAt)} · ${_timeLabel(lesson.startsAt)} · ${lesson.room}-${context.gt('room')}',
                ),
                onTap: () => Navigator.pop(context, lesson),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    _store.updateDraftContext(
      widget.groupId,
      lessonId: selected.id,
      lessonTitle: selected.topic,
      lessonAt: selected.startsAt,
    );
  }

  Future<void> _chooseDate() async {
    final draft = _store.beginAttendance(widget.groupId);
    final now = _store.currentDateTime;
    final selected = await showDatePicker(
      context: context,
      initialDate: draft.lessonAt,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: context.gt('choose_date'),
    );
    if (selected == null) return;
    _store.updateDraftContext(
      widget.groupId,
      lessonId: draft.lessonId,
      lessonTitle: draft.lessonTitle,
      lessonAt: DateTime(
        selected.year,
        selected.month,
        selected.day,
        draft.lessonAt.hour,
        draft.lessonAt.minute,
      ),
    );
  }

  Future<void> _mark(GroupStudent student, AttendanceStatus status) async {
    String? note;
    if (status == AttendanceStatus.absent ||
        status == AttendanceStatus.excused) {
      note = await _reasonSheet(student, status);
      if (note == null) return;
    }
    _store.markDraft(widget.groupId, student.id, status, note: note);
  }

  Future<String?> _reasonSheet(
    GroupStudent student,
    AttendanceStatus status,
  ) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SfTheme.colorsOf(context).surface,
      builder: (context) {
        final c = SfTheme.colorsOf(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: SfType.ui(
                  size: 18,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status == AttendanceStatus.absent
                    ? context.gt('reason_absent')
                    : context.gt('reason_excused'),
                style: SfType.ui(size: 12.5, color: c.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('attendance-reason-field'),
                controller: controller,
                autofocus: true,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.gt('short_note'),
                  hintText: context.gt('note_example'),
                ),
              ),
              const SizedBox(height: 8),
              SfButton(
                block: true,
                label: context.gt('save_status'),
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) Navigator.pop(context, value);
                },
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _submit() async {
    final group = _store.group(widget.groupId);
    final draft = _store.beginAttendance(widget.groupId);
    if (!draft.isComplete || _submitting) return;
    final approved = await showSfConfirmDialog(
      context,
      title: context.gt('confirm_save'),
      message: context.gt(
        'confirm_save_body',
        values: {'group': group.name, 'count': draft.statuses.length},
      ),
      cancelLabel: context.gt('review'),
      confirmLabel: context.gt('save'),
    );
    if (!approved || !mounted) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final record = _store.submitAttendance(widget.groupId);
    await _store.flushPersistence();
    if (!mounted) return;
    setState(() => _submitting = false);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: SfTheme.colorsOf(context).surface,
      builder: (context) => _SuccessSheet(
        group: group,
        record: record,
        onDone: () => Navigator.pop(context),
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final group = _store.group(widget.groupId);
    if (!_ready) {
      return SfScaffold(
        top: SfNavBar(title: context.gt('take_attendance')),
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final draft = _store.beginAttendance(widget.groupId);
        final visible = group.students
            .where(
              (student) =>
                  student.name.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
        final counts = {
          for (final status in AttendanceStatus.values)
            status: draft.statuses.values
                .where((value) => value == status)
                .length,
        };
        return SfScaffold(
          dismissKeyboardOnTap: true,
          top: SfNavBar(
            title: context.gt('take_attendance'),
            subtitle: '${group.name} · ${_dateLabel(draft.lessonAt)}',
            leading: SfPressable(
              onPressed: context.pop,
              semanticLabel: context.gt('back_group'),
              child: const Icon(SfIcons.arrowL),
            ),
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('attendance-lesson-chooser'),
                      onPressed: _chooseLesson,
                      icon: const Icon(SfIcons.book, size: 17),
                      label: Text(
                        draft.lessonTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('attendance-date-chooser'),
                      onPressed: _chooseDate,
                      icon: const Icon(SfIcons.cal, size: 17),
                      label: Text(
                        '${_dateLabel(draft.lessonAt)} · ${_timeLabel(draft.lessonAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.primary, c.primaryHover],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _CaptureCount(
                          label: context.gt('present'),
                          value: counts[AttendanceStatus.present]!,
                        ),
                        _CaptureCount(
                          label: context.gt('absent'),
                          value: counts[AttendanceStatus.absent]!,
                        ),
                        _CaptureCount(
                          label: context.gt('late'),
                          value: counts[AttendanceStatus.late]!,
                        ),
                        _CaptureCount(
                          label: context.gt('excused'),
                          value: counts[AttendanceStatus.excused]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: draft.markedCount / draft.statuses.length,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.gt(
                              'marked_capture',
                              values: {
                                'marked': draft.markedCount,
                                'total': draft.statuses.length,
                              },
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SfType.mono(size: 10, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SfPressable(
                          onPressed: draft.isComplete
                              ? null
                              : () =>
                                    _store.markRemainingPresent(widget.groupId),
                          haptic: true,
                          child: Text(
                            context.gt('remaining_present'),
                            style: SfType.ui(
                              size: 11,
                              weight: FontWeight.w800,
                              color: draft.isComplete
                                  ? Colors.white38
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('capture-student-search'),
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: context.gt('search_student_short'),
                  prefixIcon: Icon(SfIcons.search, color: c.muted),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              for (final entry in visible.asMap().entries) ...[
                TweenAnimationBuilder<double>(
                  key: ValueKey(entry.value.id),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 190 + entry.key * 25),
                  curve: SfMotion.enter,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: _CaptureStudentCard(
                    student: entry.value,
                    status: draft.statuses[entry.value.id],
                    note: draft.notes[entry.value.id],
                    onChanged: (status) => _mark(entry.value, status),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
          bottom: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SfButton(
              key: const ValueKey('save-group-attendance'),
              block: true,
              label: _submitting
                  ? context.gt('saving_history')
                  : draft.isComplete
                  ? context.gt('save_attendance')
                  : context.gt(
                      'statuses_left',
                      values: {
                        'count': draft.statuses.length - draft.markedCount,
                      },
                    ),
              leading: draft.isComplete ? SfIcons.check : SfIcons.clock,
              onPressed: draft.isComplete && !_submitting ? _submit : null,
            ),
          ),
        );
      },
    );
  }
}

class _CaptureCount extends StatelessWidget {
  const _CaptureCount({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        AnimatedSwitcher(
          duration: SfMotion.resolve(context, SfMotion.quick),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            '$value',
            key: ValueKey(value),
            style: SfType.mono(
              size: 20,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          label.toUpperCase(),
          style: SfType.eyebrow(size: 8, color: Colors.white60),
        ),
      ],
    ),
  );
}

class _CaptureStudentCard extends StatelessWidget {
  const _CaptureStudentCard({
    required this.student,
    required this.status,
    required this.note,
    required this.onChanged,
  });

  final GroupStudent student;
  final AttendanceStatus? status;
  final String? note;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _tone(context, status);
    return AnimatedContainer(
      duration: SfMotion.resolve(context, SfMotion.quick),
      curve: SfMotion.enter,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status == null ? c.surface : tone.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == null ? c.border : tone.withValues(alpha: .28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SfAvatar(name: student.name, size: 37),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: SfType.ui(
                        size: 13,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      note ?? student.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 9.5,
                        color: note == null ? c.muted : tone,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: SfMotion.resolve(context, SfMotion.quick),
                child: status == null
                    ? Text(
                        context.gt('unmarked'),
                        key: const ValueKey('empty'),
                        style: SfType.ui(size: 9.5, color: c.muted),
                      )
                    : Container(
                        key: ValueKey(status),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _label(context, status!),
                          style: SfType.ui(
                            size: 9.5,
                            weight: FontWeight.w800,
                            color: tone,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final value in AttendanceStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: _StatusChoice(
                      status: value,
                      selected: status == value,
                      onPressed: () => onChanged(value),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.status,
    required this.selected,
    required this.onPressed,
  });

  final AttendanceStatus status;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _tone(context, status);
    return SfPressable(
      onPressed: onPressed,
      selected: selected,
      haptic: true,
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tone : c.surface2,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Icon(
              _icon(status),
              size: 15,
              color: selected ? Colors.white : tone,
            ),
            const SizedBox(height: 2),
            Text(
              _label(context, status),
              style: SfType.ui(
                size: 8.5,
                weight: FontWeight.w800,
                color: selected ? Colors.white : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.group,
    required this.record,
    required this.onDone,
  });

  final TeacherGroup group;
  final GroupAttendanceRecord record;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: SfMotion.emphasized,
              curve: SfMotion.emphasizedCurve,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: c.successSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(SfIcons.check, size: 34, color: c.success),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              context.gt('saved_history'),
              style: SfType.ui(size: 20, weight: FontWeight.w800, color: c.ink),
            ),
            const SizedBox(height: 5),
            Text(
              context.gt(
                'saved_summary',
                values: {
                  'group': group.name,
                  'students': record.statuses.length,
                  'rate': record.attendanceRate.round(),
                },
              ),
              textAlign: TextAlign.center,
              style: SfType.ui(size: 12.5, color: c.muted),
            ),
            const SizedBox(height: 18),
            SfButton(
              block: true,
              label: context.gt('back_group'),
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

String _label(BuildContext context, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.present => context.gt('present'),
      AttendanceStatus.absent => context.gt('absent'),
      AttendanceStatus.late => context.gt('late'),
      AttendanceStatus.excused => context.gt('excused'),
    };

IconData _icon(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => Icons.check_rounded,
  AttendanceStatus.absent => Icons.close_rounded,
  AttendanceStatus.late => Icons.schedule_rounded,
  AttendanceStatus.excused => Icons.description_outlined,
};

Color _tone(BuildContext context, AttendanceStatus? status) {
  final c = SfTheme.colorsOf(context);
  return switch (status) {
    AttendanceStatus.present => c.success,
    AttendanceStatus.absent => c.danger,
    AttendanceStatus.late => c.warn,
    AttendanceStatus.excused => c.muted,
    null => c.primary,
  };
}

String _dateLabel(DateTime value) =>
    '${value.day}.${value.month.toString().padLeft(2, '0')}.${value.year}';

String _timeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
