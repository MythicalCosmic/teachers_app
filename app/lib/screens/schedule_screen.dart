import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_tab_bar.dart';
import 'today/today_data.dart';

enum _ScheduleView { day, week, month }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = staffToday;
  _ScheduleView _view = _ScheduleView.week;
  String? _selectedLessonId = lessonsFor(staffToday).firstOrNull?.id;

  @override
  Widget build(BuildContext context) {
    return SfScaffold(
      tab: SfTab.cohort,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: SfNavBar(
        title: staffTr(context, 'Jadval', 'Schedule'),
        subtitle:
            '${staffMonthName(context, _selectedDate.month)} ${_selectedDate.year}',
        leading: IconButton(
          tooltip: staffTr(context, 'Orqaga', 'Back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _selectedDate = staffToday;
              _selectedLessonId = lessonsFor(staffToday).firstOrNull?.id;
            }),
            child: Text(staffTr(context, 'Bugun', 'Today')),
          ),
        ],
      ),
      body: Column(
        children: [
          _ScheduleControls(
            selectedDate: _selectedDate,
            view: _view,
            onPrevious: () => _move(-1),
            onNext: () => _move(1),
            onViewChanged: (view) => setState(() => _view = view),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: SfMotion.resolve(context, SfMotion.emphasized),
              switchInCurve: SfMotion.enter,
              switchOutCurve: SfMotion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: switch (_view) {
                _ScheduleView.day => _DaySchedule(
                  key: ValueKey(
                    'day-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                  ),
                  date: _selectedDate,
                  selectedLessonId: _selectedLessonId,
                  onSelectLesson: (id) =>
                      setState(() => _selectedLessonId = id),
                ),
                _ScheduleView.week => _WeekSchedule(
                  key: ValueKey(
                    'week-${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                  ),
                  selectedDate: _selectedDate,
                  selectedLessonId: _selectedLessonId,
                  onSelectDate: _selectDate,
                  onSelectLesson: (id) =>
                      setState(() => _selectedLessonId = id),
                ),
                _ScheduleView.month => _MonthSchedule(
                  key: ValueKey(
                    'month-${_selectedDate.year}-${_selectedDate.month}',
                  ),
                  selectedDate: _selectedDate,
                  selectedLessonId: _selectedLessonId,
                  onSelectDate: _selectDate,
                  onSelectLesson: (id) =>
                      setState(() => _selectedLessonId = id),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  void _move(int direction) {
    if (_view == _ScheduleView.month) {
      final targetMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
      );
      final targetDay = _selectedDate.day
          .clamp(
            1,
            DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month),
          )
          .toInt();
      _selectDate(DateTime(targetMonth.year, targetMonth.month, targetDay));
      return;
    }
    final days = _view == _ScheduleView.week ? 7 : 1;
    _selectDate(_selectedDate.add(Duration(days: direction * days)));
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedLessonId = lessonsFor(date).firstOrNull?.id;
    });
  }
}

class _ScheduleControls extends StatelessWidget {
  const _ScheduleControls({
    required this.selectedDate,
    required this.view,
    required this.onPrevious,
    required this.onNext,
    required this.onViewChanged,
  });

  final DateTime selectedDate;
  final _ScheduleView view;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<_ScheduleView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 13),
      child: Column(
        children: [
          Row(
            children: [
              _ArrowButton(
                icon: Icons.chevron_left_rounded,
                label: staffTr(context, 'Oldingi davr', 'Previous period'),
                onTap: onPrevious,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      view == _ScheduleView.month
                          ? staffMonthName(context, selectedDate.month)
                          : staffDayTitle(context, selectedDate),
                      textAlign: TextAlign.center,
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      view == _ScheduleView.week
                          ? staffTr(
                              context,
                              '${_isoWeekNumber(selectedDate)}-hafta · ${_weekLoad(selectedDate)} ta dars',
                              'Week ${_isoWeekNumber(selectedDate)} · ${_weekLoad(selectedDate)} lessons',
                              ru: 'Неделя ${_isoWeekNumber(selectedDate)} · ${_weekLoad(selectedDate)} уроков',
                            )
                          : staffTr(
                              context,
                              '${lessonsFor(selectedDate).length} ta dars',
                              '${lessonsFor(selectedDate).length} lessons',
                            ),
                      style: SfType.ui(size: 10, color: c.muted),
                    ),
                  ],
                ),
              ),
              _ArrowButton(
                icon: Icons.chevron_right_rounded,
                label: staffTr(context, 'Keyingi davr', 'Next period'),
                onTap: onNext,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                for (final item in [
                  (_ScheduleView.day, staffTr(context, 'Kun', 'Day')),
                  (_ScheduleView.week, staffTr(context, 'Hafta', 'Week')),
                  (_ScheduleView.month, staffTr(context, 'Oy', 'Month')),
                ])
                  Expanded(
                    child: SfPressable(
                      key: Key('schedule-view-${item.$1.name}'),
                      semanticLabel: staffTr(
                        context,
                        '${item.$2} ko‘rinishi',
                        '${item.$2} view',
                      ),
                      selected: view == item.$1,
                      onPressed: () => onViewChanged(item.$1),
                      borderRadius: BorderRadius.circular(11),
                      child: AnimatedContainer(
                        duration: SfMotion.resolve(context, SfMotion.standard),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: view == item.$1
                              ? c.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: view == item.$1
                              ? [
                                  BoxShadow(
                                    color: c.ink.withValues(alpha: .08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.$2,
                          style: SfType.ui(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: view == item.$1 ? c.ink : c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _weekLoad(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(
      7,
      (index) => lessonsFor(start.add(Duration(days: index))).length,
    ).fold(0, (sum, value) => sum + value);
  }

  int _isoWeekNumber(DateTime date) {
    final day = DateUtils.dateOnly(date);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final januaryFourth = DateTime(thursday.year, DateTime.january, 4);
    final weekOneThursday = januaryFourth.add(
      Duration(days: DateTime.thursday - januaryFourth.weekday),
    );
    return 1 + thursday.difference(weekOneThursday).inDays ~/ 7;
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      semanticLabel: label,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 21, color: c.ink),
      ),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule({
    super.key,
    required this.date,
    required this.selectedLessonId,
    required this.onSelectLesson,
  });
  final DateTime date;
  final String? selectedLessonId;
  final ValueChanged<String> onSelectLesson;

  @override
  Widget build(BuildContext context) => _Agenda(
    date: date,
    selectedLessonId: selectedLessonId,
    onSelectLesson: onSelectLesson,
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 28),
  );
}

class _WeekSchedule extends StatelessWidget {
  const _WeekSchedule({
    super.key,
    required this.selectedDate,
    required this.selectedLessonId,
    required this.onSelectDate,
    required this.onSelectLesson,
  });
  final DateTime selectedDate;
  final String? selectedLessonId;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String> onSelectLesson;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _WeekStrip(
          start: start,
          selected: selectedDate,
          onSelect: onSelectDate,
        ),
        const SizedBox(height: 14),
        _Agenda(
          date: selectedDate,
          selectedLessonId: selectedLessonId,
          onSelectLesson: onSelectLesson,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.start,
    required this.selected,
    required this.onSelect,
  });
  final DateTime start;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        for (var index = 0; index < 7; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(
            child: Builder(
              builder: (context) {
                final date = start.add(Duration(days: index));
                final selectedDay = DateUtils.isSameDay(date, selected);
                final count = lessonsFor(date).length;
                return SfPressable(
                  key: Key(
                    'schedule-date-${date.year}-${date.month}-${date.day}',
                  ),
                  semanticLabel: staffTr(
                    context,
                    '${staffDayTitle(context, date)}, $count ta dars',
                    '${staffDayTitle(context, date)}, $count lessons',
                  ),
                  selected: selectedDay,
                  haptic: true,
                  onPressed: () => onSelect(date),
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedContainer(
                    duration: SfMotion.resolve(context, SfMotion.standard),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selectedDay ? c.primary : c.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selectedDay ? c.primary : c.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          staffWeekdayShort(
                            context,
                            date.weekday,
                          ).toUpperCase(),
                          style: SfType.eyebrow(
                            color: selectedDay ? c.bg : c.muted,
                            size: 7.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: SfType.mono(
                            size: 15,
                            weight: FontWeight.w800,
                            color: selectedDay ? c.bg : c.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var dot = 0; dot < count.clamp(0, 3); dot++)
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedDay ? c.accent : c.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (count == 0)
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: selectedDay ? c.bg : c.borderStrong,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthSchedule extends StatelessWidget {
  const _MonthSchedule({
    super.key,
    required this.selectedDate,
    required this.selectedLessonId,
    required this.onSelectDate,
    required this.onSelectLesson,
  });
  final DateTime selectedDate;
  final String? selectedLessonId;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String> onSelectLesson;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(selectedDate.year, selectedDate.month);
    final count = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final leading = first.weekday - 1;
    final c = SfTheme.colorsOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        SfSurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  for (var weekday = 1; weekday <= 7; weekday++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          staffWeekdayShort(context, weekday).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: SfType.eyebrow(color: c.muted, size: 7.5),
                        ),
                      ),
                    ),
                ],
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: .82,
                ),
                itemCount: leading + count,
                itemBuilder: (context, index) {
                  if (index < leading) return const SizedBox.shrink();
                  final date = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    index - leading + 1,
                  );
                  return _MonthDay(
                    date: date,
                    selected: DateUtils.isSameDay(date, selectedDate),
                    onTap: () => onSelectDate(date),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Agenda(
          date: selectedDate,
          selectedLessonId: selectedLessonId,
          onSelectLesson: onSelectLesson,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _MonthDay extends StatelessWidget {
  const _MonthDay({
    required this.date,
    required this.selected,
    required this.onTap,
  });
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final count = lessonsFor(date).length;
    return SfPressable(
      key: Key('month-day-${date.year}-${date.month}-${date.day}'),
      semanticLabel: staffTr(
        context,
        '${date.day} ${staffMonthName(context, date.month)}, $count ta dars',
        '${staffMonthName(context, date.month)} ${date.day}, $count lessons',
      ),
      selected: selected,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        decoration: BoxDecoration(
          color: selected
              ? c.primary
              : count > 0
              ? c.primarySoft.withValues(alpha: .5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? c.primary
                : count > 0
                ? c.primary.withValues(alpha: .18)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: SfType.mono(
                size: 11,
                weight: FontWeight.w800,
                color: selected ? c.bg : c.ink,
              ),
            ),
            const SizedBox(height: 3),
            if (count > 0)
              Container(
                width: 12,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? c.accent : c.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({
    required this.date,
    required this.selectedLessonId,
    required this.onSelectLesson,
    required this.padding,
    this.shrinkWrap = false,
  });
  final DateTime date;
  final String? selectedLessonId;
  final ValueChanged<String> onSelectLesson;
  final EdgeInsets padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final lessons = lessonsFor(date);
    final c = SfTheme.colorsOf(context);
    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffDayTitle(context, date),
                  style: SfType.ui(
                    size: 16,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(
                  staffTr(
                    context,
                    '${lessons.length} ta dars · ${lessons.fold(0, (sum, lesson) => sum + lesson.students)} o‘quvchi kontakti',
                    '${lessons.length} lessons · ${lessons.fold(0, (sum, lesson) => sum + lesson.students)} student contacts',
                  ),
                  style: SfType.ui(size: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
          Icon(SfIcons.cal, color: c.primary, size: 20),
        ],
      ),
      const SizedBox(height: 11),
      if (lessons.isEmpty)
        SfSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.event_available_rounded, color: c.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  staffTr(
                    context,
                    'Bu sana uchun dars yo‘q. Tayyorgarlik yoki individual uchrashuv rejalashtirishingiz mumkin.',
                    'No lessons on this date. You can plan preparation or an individual meeting.',
                  ),
                  style: SfType.ui(size: 12, color: c.ink2, height: 1.4),
                ),
              ),
            ],
          ),
        )
      else
        for (final lesson in lessons) ...[
          _AgendaLessonCard(
            lesson: lesson,
            selected: lesson.id == selectedLessonId,
            onTap: () => onSelectLesson(lesson.id),
          ),
          const SizedBox(height: 9),
        ],
    ];
    if (shrinkWrap) return Column(children: children);
    return ListView(padding: padding, children: children);
  }
}

class _AgendaLessonCard extends StatelessWidget {
  const _AgendaLessonCard({
    required this.lesson,
    required this.selected,
    required this.onTap,
  });
  final TodayLessonData lesson;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = switch (lesson.tone) {
      1 => c.accent,
      2 => c.ink2,
      _ => c.primary,
    };
    return SfPressable(
      key: Key('schedule-lesson-${lesson.id}'),
      semanticLabel:
          '${staffLessonTitle(context, lesson)}, ${lesson.timeRange}',
      selected: selected,
      haptic: true,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.standard),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: .1) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tone : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lesson.start,
                        style: SfType.mono(
                          size: 10,
                          weight: FontWeight.w800,
                          color: tone,
                        ),
                      ),
                      Text(
                        lesson.end,
                        style: SfType.mono(size: 8, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffLessonTitle(context, lesson),
                        style: SfType.ui(
                          size: 14,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staffLessonTopic(context, lesson),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(size: 10.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: selected ? .25 : 0,
                  duration: SfMotion.resolve(context, SfMotion.quick),
                  child: Icon(SfIcons.chevR, size: 19, color: tone),
                ),
              ],
            ),
            AnimatedSize(
              duration: SfMotion.resolve(context, SfMotion.emphasized),
              curve: SfMotion.enter,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: Column(
                        children: [
                          Container(height: 1, color: c.border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LessonMeta(
                                  icon: SfIcons.cohort,
                                  label: staffTr(
                                    context,
                                    '${lesson.students} o‘quvchi',
                                    '${lesson.students} students',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _LessonMeta(
                                  icon: Icons.meeting_room_outlined,
                                  label: staffTr(
                                    context,
                                    '${lesson.room}-xona',
                                    'Room ${lesson.room}',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _LessonMeta(
                                  icon: Icons.layers_outlined,
                                  label: staffLessonLevel(context, lesson),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SfButton(
                            block: true,
                            height: 46,
                            label: staffTr(
                              context,
                              'Dars ish maydonini ochish',
                              'Open lesson workspace',
                            ),
                            trailing: SfIcons.arrowR,
                            onPressed: () =>
                                context.push('/lesson?slot=${lesson.id}'),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      children: [
        Icon(icon, size: 17, color: c.primary),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: SfType.ui(size: 9, weight: FontWeight.w700, color: c.ink2),
        ),
      ],
    );
  }
}
