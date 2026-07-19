import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../features/learning/learning_workspace_controller.dart';
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
import 'learning/production_learning_screens.dart';

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
    final app = AppScope.maybeOf(context);
    if (app?.isProduction == true) {
      final controller = learningWorkspaceFor(app!);
      if (controller != null) {
        return ProductionScheduleScreen(controller: controller);
      }
    }
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
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 380) return;
                _move(velocity < 0 ? 1 : -1);
              },
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
                    onRefresh: _refreshLocalSchedule,
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
                    onRefresh: _refreshLocalSchedule,
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
                    onRefresh: _refreshLocalSchedule,
                  ),
                },
              ),
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

  Future<void> _refreshLocalSchedule() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) setState(() {});
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(22),
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
                    (
                      _ScheduleView.day,
                      staffTr(context, 'Kun', 'Day'),
                      Icons.view_day_outlined,
                    ),
                    (
                      _ScheduleView.week,
                      staffTr(context, 'Hafta', 'Week'),
                      Icons.view_week_outlined,
                    ),
                    (
                      _ScheduleView.month,
                      staffTr(context, 'Oy', 'Month'),
                      Icons.calendar_month_outlined,
                    ),
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
                          duration: SfMotion.resolve(
                            context,
                            SfMotion.standard,
                          ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.$3,
                                size: 15,
                                color: view == item.$1 ? c.primary : c.muted,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  item.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SfType.ui(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: view == item.$1 ? c.ink : c.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
    required this.onRefresh,
  });
  final DateTime date;
  final String? selectedLessonId;
  final ValueChanged<String> onSelectLesson;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator.adaptive(
    onRefresh: onRefresh,
    child: _Agenda(
      date: date,
      selectedLessonId: selectedLessonId,
      onSelectLesson: onSelectLesson,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 28),
    ),
  );
}

class _WeekSchedule extends StatelessWidget {
  const _WeekSchedule({
    super.key,
    required this.selectedDate,
    required this.selectedLessonId,
    required this.onSelectDate,
    required this.onSelectLesson,
    required this.onRefresh,
  });
  final DateTime selectedDate;
  final String? selectedLessonId;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String> onSelectLesson;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
      ),
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
    return SfSurfaceCard(
      padding: const EdgeInsets.all(6),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        children: [
          for (var index = 0; index < 7; index++) ...[
            if (index > 0) const SizedBox(width: 3),
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = start.add(Duration(days: index));
                  final selectedDay = DateUtils.isSameDay(date, selected);
                  final today = DateUtils.isSameDay(date, staffToday);
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
                      constraints: const BoxConstraints(minHeight: 70),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedDay ? c.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selectedDay
                              ? c.primary
                              : today
                              ? c.primary.withValues(alpha: .48)
                              : Colors.transparent,
                          width: today && !selectedDay ? 1.4 : 1,
                        ),
                        boxShadow: selectedDay
                            ? [
                                BoxShadow(
                                  color: c.primary.withValues(alpha: .2),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            staffWeekdayShort(
                              context,
                              date.weekday,
                            ).toUpperCase(),
                            style: SfType.eyebrow(
                              color: selectedDay ? c.primaryInk : c.muted,
                              size: 7.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${date.day}',
                            style: SfType.mono(
                              size: 15,
                              weight: FontWeight.w800,
                              color: selectedDay ? c.primaryInk : c.ink,
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
                                    color: selectedDay
                                        ? c.primaryInk.withValues(alpha: .88)
                                        : c.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (count == 0)
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: selectedDay
                                        ? c.primaryInk.withValues(alpha: .7)
                                        : c.borderStrong,
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
      ),
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
    required this.onRefresh,
  });

  final DateTime selectedDate;
  final String? selectedLessonId;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String> onSelectLesson;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(selectedDate.year, selectedDate.month);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final monthLessonCount = List<int>.generate(
      daysInMonth,
      (index) => lessonsFor(
        DateTime(selectedDate.year, selectedDate.month, index + 1),
      ).length,
    ).fold(0, (sum, value) => sum + value);
    final c = SfTheme.colorsOf(context);

    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          SfSurfaceCard(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: c.primary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${staffMonthName(context, selectedDate.month)} ${selectedDate.year}',
                              style: SfType.ui(
                                size: 13,
                                weight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                            Text(
                              staffTr(
                                context,
                                '$monthLessonCount ta dars rejalashtirilgan',
                                '$monthLessonCount lessons scheduled',
                              ),
                              style: SfType.ui(size: 9.5, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          '${selectedDate.day}',
                          style: SfType.mono(
                            size: 11,
                            weight: FontWeight.w800,
                            color: c.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: .88,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final date = gridStart.add(Duration(days: index));
                    return _MonthDay(
                      date: date,
                      selected: DateUtils.isSameDay(date, selectedDate),
                      inDisplayedMonth: date.month == selectedDate.month,
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
      ),
    );
  }
}

class _MonthDay extends StatelessWidget {
  const _MonthDay({
    required this.date,
    required this.selected,
    required this.inDisplayedMonth,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool inDisplayedMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final count = lessonsFor(date).length;
    final today = DateUtils.isSameDay(date, staffToday);
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
              : count > 0 && inDisplayedMonth
              ? c.primarySoft.withValues(alpha: .56)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? c.primary
                : today
                ? c.primary.withValues(alpha: .58)
                : count > 0 && inDisplayedMonth
                ? c.primary.withValues(alpha: .16)
                : Colors.transparent,
            width: today && !selected ? 1.4 : 1,
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
                color: selected
                    ? c.primaryInk
                    : inDisplayedMonth
                    ? c.ink
                    : c.muted2,
              ),
            ),
            const SizedBox(height: 3),
            if (count > 0)
              Container(
                width: 12,
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? c.primaryInk.withValues(alpha: .86)
                      : inDisplayedMonth
                      ? c.primary
                      : c.muted2,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: padding,
      children: children,
    );
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
