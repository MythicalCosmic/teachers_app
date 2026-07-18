import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_ai_surface.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_toast.dart';
import 'today_data.dart';

class TodayMetricDetailScreen extends StatefulWidget {
  const TodayMetricDetailScreen({super.key, required this.kind});

  final TodayMetricKind kind;

  @override
  State<TodayMetricDetailScreen> createState() =>
      _TodayMetricDetailScreenState();
}

class _TodayMetricDetailScreenState extends State<TodayMetricDetailScreen> {
  int _period = 1;
  int _selectedPoint = 5;
  int _selectedCohort = 0;
  final Set<int> _followUps = {};
  bool _openingAttendance = false;

  String _title(BuildContext context) => switch (widget.kind) {
    TodayMetricKind.lessons => staffTr(
      context,
      'Bugungi darslar',
      'Lessons today',
    ),
    TodayMetricKind.attendance => staffTr(
      context,
      'Davomat tahlili',
      'Attendance insights',
    ),
    TodayMetricKind.performance => staffTr(
      context,
      'Sizning natijangiz',
      'Your performance',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return SfScaffold(
      top: SfNavBar(
        title: _title(context),
        subtitle: switch (widget.kind) {
          TodayMetricKind.lessons => staffDayTitle(context, staffToday),
          TodayMetricKind.attendance => staffTr(
            context,
            'Real vaqt · barcha guruhlar',
            'Live · all groups',
            ru: 'В реальном времени · все группы',
          ),
          TodayMetricKind.performance => staffMonthAndWeekLabel(
            context,
            staffToday,
          ),
        },
        leading: IconButton(
          tooltip: staffTr(context, 'Orqaga', 'Back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          _PeriodSelector(
            selected: _period,
            onSelected: (value) => setState(() {
              _period = value;
              _selectedPoint = 6;
            }),
          ),
          const SizedBox(height: 15),
          AnimatedSwitcher(
            duration: SfMotion.resolve(context, SfMotion.emphasized),
            switchInCurve: SfMotion.enter,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.035, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey('${widget.kind.name}-$_period'),
              child: switch (widget.kind) {
                TodayMetricKind.lessons => _lessons(context),
                TodayMetricKind.attendance => _attendance(context),
                TodayMetricKind.performance => _performance(context),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessons(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final todayLessons = lessonsFor(staffToday);
    final lessons = _period == 0 ? todayLessons : staffLessonPlan;
    final multiplier = _period == 2 ? 4 : 1;
    final lessonCount = lessons.length * multiplier;
    final totalMinutes =
        lessons.fold<int>(0, (sum, lesson) => sum + _lessonMinutes(lesson)) *
        multiplier;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final durationLabel = minutes == 0
        ? staffTr(
            context,
            '$hours soat sof dars vaqti',
            '$hours hours of teaching time',
          )
        : staffTr(
            context,
            '$hours soat $minutes daqiqa sof dars vaqti',
            '$hours hours $minutes minutes of teaching time',
          );
    final trendValues = switch (_period) {
      0 => const [.74, .81, .77, .86, .9, .88, .93],
      1 => const [.76, .84, .79, .91, .88, .94, .92],
      _ => const [.69, .74, .8, .78, .86, .9, .94],
    };
    final trendLabels = switch (_period) {
      0 => [
        for (var offset = 6; offset >= 0; offset--)
          staffWeekdayShort(
            context,
            staffToday.subtract(Duration(days: offset)).weekday,
          ),
      ],
      1 => [
        for (var weekday = 1; weekday <= 7; weekday++)
          staffWeekdayShort(context, weekday),
      ],
      _ => const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7'],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricHero(
          icon: Icons.calendar_view_day_rounded,
          eyebrow: switch (_period) {
            0 => staffTr(context, 'BUGUNGI YUKLAMA', 'TODAY’S LOAD'),
            1 => staffTr(context, 'HAFTALIK YUKLAMA', 'WEEKLY LOAD'),
            _ => staffTr(context, 'OYLIK PROGNOZ', 'MONTHLY FORECAST'),
          },
          value: staffTr(context, '$lessonCount dars', '$lessonCount lessons'),
          title: durationLabel,
          message: switch (_period) {
            0 when todayLessons.isEmpty => staffTr(
              context,
              'Bugun dars yo‘q · haftalik reja tayyor',
              'No lessons today · the weekly plan is ready',
            ),
            0 => staffTr(
              context,
              '${todayLessons.where((lesson) => lesson.progress == LessonProgress.live).length} dars davom etmoqda · kun rejasi real vaqt rejimida',
              '${todayLessons.where((lesson) => lesson.progress == LessonProgress.live).length} lesson in progress · live day plan',
            ),
            1 => staffTr(
              context,
              '${staffLessonPlan.map((lesson) => lesson.cohort).toSet().length} guruh · ${staffLessonPlan.map((lesson) => lesson.room).toSet().length} xona · to‘liq hafta',
              '${staffLessonPlan.map((lesson) => lesson.cohort).toSet().length} groups · ${staffLessonPlan.map((lesson) => lesson.room).toSet().length} rooms · full week',
            ),
            _ => staffTr(
              context,
              'Joriy haftalik ritm asosidagi 4 haftalik prognoz',
              'Four-week forecast based on the current teaching rhythm',
            ),
          },
          accent: c.primary,
          trailing: _Ring(
            value: switch (_period) {
              0 => .68,
              1 => .82,
              _ => .91,
            },
            label: switch (_period) {
              0 => '68%',
              1 => '82%',
              _ => '91%',
            },
            color: c.primary,
          ),
        ),
        const SizedBox(height: 15),
        _SectionLabel(
          title: switch (_period) {
            0 => staffTr(context, 'Kun oqimi', 'Day flow'),
            1 => staffTr(context, 'Hafta darslari', 'Weekly lessons'),
            _ => staffTr(context, 'Namunaviy hafta', 'Representative week'),
          },
          caption: lessons.isEmpty
              ? staffTr(context, 'Rejada dars yo‘q', 'No lessons scheduled')
              : staffTr(
                  context,
                  'Har bir darsni to‘liq tafsilotlar bilan oching',
                  'Open any lesson for full details',
                ),
        ),
        const SizedBox(height: 8),
        SfSurfaceCard(
          child: lessons.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_rounded, color: c.success),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          staffTr(
                            context,
                            'Bugungi bo‘sh vaqtni tayyorgarlik va individual yordam uchun ishlating.',
                            'Use today’s open time for preparation and individual support.',
                          ),
                          style: SfType.ui(
                            size: 12,
                            color: c.ink2,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final entry in lessons.asMap().entries)
                      _LessonDrillRow(
                        lesson: entry.value,
                        last: entry.key == lessons.length - 1,
                        onTap: () =>
                            context.push('/lesson?slot=${entry.value.id}'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _InteractiveTrend(
          title: staffTr(context, 'Dars energiyasi', 'Lesson energy'),
          caption: switch (_period) {
            0 => staffTr(context, 'So‘nggi 7 kun', 'Last 7 days'),
            1 => staffTr(context, 'Joriy hafta', 'Current week'),
            _ => staffTr(context, 'So‘nggi 7 hafta', 'Last 7 weeks'),
          },
          values: trendValues,
          labels: trendLabels,
          selected: _selectedPoint,
          onSelected: (value) => setState(() => _selectedPoint = value),
          detail: staffTr(
            context,
            '${trendLabels[_selectedPoint]} · ${(trendValues[_selectedPoint] * 100).round()}% faol ishtirok · guruhli mashqlar eng kuchli natija berdi',
            '${trendLabels[_selectedPoint]} · ${(trendValues[_selectedPoint] * 100).round()}% active engagement · group exercises performed best',
          ),
          color: c.primary,
        ),
        const SizedBox(height: 15),
        SfButton(
          block: true,
          height: 50,
          label: staffTr(
            context,
            'To‘liq jadvalni boshqarish',
            'Manage full schedule',
          ),
          leading: SfIcons.cal,
          onPressed: () => context.push('/schedule'),
        ),
      ],
    );
  }

  Widget _attendance(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final cohorts = [staffTr(context, 'Barchasi', 'All'), '9-B', '9-A', '10-V'];
    final attendanceByPeriod = switch (_period) {
      0 => const [93, 96, 89, 92],
      1 => const [94, 96, 91, 93],
      _ => const [95, 97, 92, 94],
    };
    final attendance = attendanceByPeriod[_selectedCohort];
    final trendValues = switch (_period) {
      0 => const [.86, .9, .91, .89, .94, .92, .93],
      1 => const [.88, .91, .89, .94, .93, .96, .94],
      _ => const [.9, .91, .92, .94, .93, .95, .96],
    };
    final trendDates = [
      for (var offset = 6; offset >= 0; offset--)
        (_period == 1
            ? staffWeekStart.add(Duration(days: 6 - offset))
            : staffToday.subtract(Duration(days: offset))),
    ];
    final trendLabels = _period == 2
        ? const ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7']
        : [for (final date in trendDates) '${date.day}'];
    final selectedRate = (trendValues[_selectedPoint] * 100).round();
    final selectedDetailLabel = _period == 2
        ? staffTr(
            context,
            '${staffMonthName(context, staffToday.month)} · ${trendLabels[_selectedPoint]}',
            '${staffMonthName(context, staffToday.month)} · ${trendLabels[_selectedPoint]}',
          )
        : staffDayTitle(context, trendDates[_selectedPoint]);
    final followUps = _followUpCandidates(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricHero(
          icon: Icons.how_to_reg_rounded,
          eyebrow: staffTr(context, 'DAVOMAT SIFATI', 'ATTENDANCE QUALITY'),
          value: '$attendance%',
          title: _selectedCohort == 0
              ? staffTr(
                  context,
                  'Barcha guruhlar bo‘yicha',
                  'Across all groups',
                )
              : staffTr(
                  context,
                  '${cohorts[_selectedCohort]} guruhi',
                  'Group ${cohorts[_selectedCohort]}',
                ),
          message: staffTr(
            context,
            switch (_period) {
              0 => 'Bugungi signal · 3 o‘quvchi kuzatuvga tayyor',
              1 =>
                '+2.4% o‘tgan haftaga nisbatan · 3 signal tekshirishga tayyor',
              _ => '+1.8% o‘tgan oyga nisbatan · barqaror o‘sish',
            },
            switch (_period) {
              0 => 'Today’s signal · 3 students ready for follow-up',
              1 => '+2.4% versus last week · 3 signals ready for review',
              _ => '+1.8% versus last month · steady improvement',
            },
          ),
          accent: c.success,
          trailing: _Ring(
            value: attendance / 100,
            label: '$attendance',
            color: c.success,
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cohorts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) => _ChoicePill(
              label: cohorts[index],
              selected: _selectedCohort == index,
              onTap: () => setState(() => _selectedCohort = index),
            ),
          ),
        ),
        const SizedBox(height: 13),
        _InteractiveTrend(
          title: switch (_period) {
            0 => staffTr(context, 'Bugungi tendensiya', 'Today’s trend'),
            1 => staffTr(context, 'Haftalik tendensiya', 'Weekly trend'),
            _ => staffTr(context, 'Oylik tendensiya', 'Monthly trend'),
          },
          caption: staffTr(
            context,
            'Kunlik kelish foizi',
            'Daily attendance rate',
          ),
          values: trendValues,
          labels: trendLabels,
          selected: _selectedPoint,
          onSelected: (value) => setState(() => _selectedPoint = value),
          detail: staffTr(
            context,
            '$selectedDetailLabel · $selectedRate% · ${_selectedPoint == 2 ? '2 kechikish qayd etildi' : 'barqaror davr'}',
            '$selectedDetailLabel · $selectedRate% · ${_selectedPoint == 2 ? '2 late arrivals recorded' : 'stable period'}',
          ),
          color: c.success,
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          title: staffTr(
            context,
            'E’tibor talab qiladiganlar',
            'Needs attention',
          ),
          caption: staffTr(
            context,
            'Kuzatuv rejasiga bir tegishda qo‘shing',
            'Add to the follow-up plan with one tap',
          ),
        ),
        const SizedBox(height: 8),
        SfSurfaceCard(
          child: Column(
            children: [
              for (final entry in followUps.asMap().entries)
                _FollowUpRow(
                  name: entry.value.name,
                  detail: entry.value.detail,
                  delta: entry.value.delta,
                  selected: _followUps.contains(entry.key),
                  last: entry.key == followUps.length - 1,
                  onTap: () => setState(() {
                    if (!_followUps.add(entry.key)) {
                      _followUps.remove(entry.key);
                    }
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SfButton(
          block: true,
          height: 50,
          label: _openingAttendance
              ? staffTr(context, 'Kuzatuv saqlanmoqda…', 'Saving follow-up…')
              : _followUps.isEmpty
              ? staffTr(
                  context,
                  'Davomat ish maydonini ochish',
                  'Open attendance workspace',
                )
              : staffTr(
                  context,
                  '${_followUps.length} kuzatuv bilan davom etish',
                  'Continue with ${_followUps.length} follow-ups',
                ),
          leading: SfIcons.check,
          onPressed: _openingAttendance ? null : _openAttendance,
        ),
      ],
    );
  }

  Widget _performance(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final rank = const [9, 7, 5][_period];
    final placesGained = const [1, 3, 5][_period];
    final trendValues = switch (_period) {
      0 => const [.74, .79, .81, .84, .86, .89, .9],
      1 => const [.71, .76, .78, .82, .86, .89, .92],
      _ => const [.68, .71, .76, .8, .82, .88, .92],
    };
    final trendLabels = switch (_period) {
      0 => const ['08', '09', '10', '11', '12', '14', '16'],
      1 => [
        for (var weekday = 1; weekday <= 7; weekday++)
          staffWeekdayShort(context, weekday),
      ],
      _ => [
        for (var offset = 6; offset >= 0; offset--)
          _shortMonth(context, _monthOffset(staffToday, -offset)),
      ],
    };
    final skillLift = const [0.0, .01, .02][_period];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricHero(
          icon: Icons.workspace_premium_outlined,
          eyebrow: staffTr(context, 'FILIAL REYTINGI', 'BRANCH RANKING'),
          value: '#$rank',
          title: staffTr(
            context,
            '148 o‘qituvchi ichida',
            'Out of 148 teachers',
          ),
          message: staffTr(
            context,
            switch (_period) {
              0 => 'Bugun $placesGained pog‘ona ko‘tarildingiz · yuqori 7%',
              1 => 'Bu hafta $placesGained pog‘ona ko‘tarildingiz · yuqori 5%',
              _ => 'Bu oy $placesGained pog‘ona ko‘tarildingiz · yuqori 4%',
            },
            switch (_period) {
              0 => 'Up $placesGained place today · top 7%',
              1 => 'Up $placesGained places this week · top 5%',
              _ => 'Up $placesGained places this month · top 4%',
            },
          ),
          accent: c.accent,
          trailing: _Ring(
            value: switch (_period) {
              0 => .93,
              1 => .95,
              _ => .96,
            },
            label: switch (_period) {
              0 => 'TOP\n7%',
              1 => 'TOP\n5%',
              _ => 'TOP\n4%',
            },
            color: c.accent,
          ),
        ),
        const SizedBox(height: 15),
        _InteractiveTrend(
          title: staffTr(context, 'Natija dinamikasi', 'Performance trend'),
          caption: staffTr(
            context,
            'StarForge performance indeksi',
            'StarForge performance index',
          ),
          values: trendValues,
          labels: trendLabels,
          selected: _selectedPoint,
          onSelected: (value) => setState(() => _selectedPoint = value),
          detail: staffTr(
            context,
            '${(trendValues[_selectedPoint] * 100).round()} ball · eng katta o‘sish: o‘quvchi progressi',
            '${(trendValues[_selectedPoint] * 100).round()} points · largest gain: student progress',
          ),
          color: c.accent,
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          title: staffTr(context, 'Natija tarkibi', 'Performance breakdown'),
          caption: staffTr(
            context,
            'Baholash mezonlari va filial medianasi',
            'Scoring criteria and branch median',
          ),
        ),
        const SizedBox(height: 8),
        SfSurfaceCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _SkillBar(
                label: staffTr(context, 'Dars sifati', 'Lesson quality'),
                value: .90 + skillLift,
                benchmark: .81,
                color: c.primary,
              ),
              const SizedBox(height: 14),
              _SkillBar(
                label: staffTr(context, 'O‘quvchi o‘sishi', 'Student growth'),
                value: .86 + skillLift,
                benchmark: .76,
                color: c.success,
              ),
              const SizedBox(height: 14),
              _SkillBar(
                label: staffTr(
                  context,
                  'Davomat barqarorligi',
                  'Attendance stability',
                ),
                value: .92 + skillLift,
                benchmark: .86,
                color: c.accent,
              ),
              const SizedBox(height: 14),
              _SkillBar(
                label: staffTr(context, 'Vazifalar aniqligi', 'Task clarity'),
                value: .82 + skillLift,
                benchmark: .79,
                color: c.ink2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SfAiSurface(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SfAiBadge(
                label: staffTr(
                  context,
                  'Shaxsiy rivojlanish insighti',
                  'Personal growth insight',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                staffTr(
                  context,
                  'Sizning kuchli tomoningiz — murakkab mavzuni kichik, tushunarli bosqichlarga ajratish.',
                  'Your strength is breaking complex topics into small, understandable steps.',
                ),
                style: SfType.ui(
                  size: 16,
                  weight: FontWeight.w800,
                  color: c.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                staffTr(
                  context,
                  'Keyingi o‘sish nuqtasi: 9-A guruhida individual qayta aloqa chastotasini haftasiga ikki martaga oshirish.',
                  'Next growth point: increase individual feedback in Group 9-A to twice a week.',
                ),
                style: SfType.ui(size: 12, color: c.ink2, height: 1.5),
              ),
              const SizedBox(height: 13),
              SfButton(
                kind: SfButtonKind.ink,
                label: staffTr(
                  context,
                  'Rivojlanish vazifalarini ochish',
                  'Open growth tasks',
                ),
                trailing: SfIcons.arrowR,
                fontSize: 12,
                onPressed: () => context.push('/tasks'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _lessonMinutes(TodayLessonData lesson) {
    int minutes(String value) {
      final parts = value.split(':');
      return int.parse(parts.first) * 60 + int.parse(parts.last);
    }

    return minutes(lesson.end) - minutes(lesson.start);
  }

  List<({String id, String name, String detail, String delta})>
  _followUpCandidates(BuildContext context) => [
    (
      id: 'student-otabek-eshmatov',
      name: 'Otabek Eshmatov',
      detail: staffTr(
        context,
        '9-B · 3 darsdan 2 tasi qoldirilgan',
        '9-B · missed 2 of 3 lessons',
      ),
      delta: '18%',
    ),
    (
      id: 'student-zarina-halimova',
      name: 'Zarina Halimova',
      detail: staffTr(context, '9-A · 3 marta kechikkan', '9-A · late 3 times'),
      delta: '9%',
    ),
    (
      id: 'student-akmal-akbarov',
      name: 'Akmal Akbarov',
      detail: staffTr(
        context,
        '10-V · izoh talab qilinadi',
        '10-V · explanation required',
      ),
      delta: '6%',
    ),
  ];

  Future<void> _openAttendance() async {
    if (_followUps.isEmpty) {
      context.push('/attendance');
      return;
    }

    final candidates = _followUpCandidates(context);
    final selected = [
      for (final index in _followUps)
        if (index >= 0 && index < candidates.length) candidates[index],
    ];
    setState(() => _openingAttendance = true);
    try {
      final app = AppScope.maybeOf(context);
      if (app != null) {
        await app.createTask(
          title: staffTr(
            context,
            'Davomat kuzatuvi: ${selected.map((item) => item.name).join(', ')}',
            'Attendance follow-up: ${selected.map((item) => item.name).join(', ')}',
          ),
          description: staffTr(
            context,
            'Tanlangan o‘quvchilar bilan davomat sabablarini aniqlang va keyingi dars uchun kelish rejasini tasdiqlang.',
            'Review attendance reasons with the selected students and confirm an arrival plan for the next lesson.',
          ),
          dueAt: staffToday.add(const Duration(days: 1)),
          checklist: [
            for (final item in selected)
              staffTr(
                context,
                '${item.name} bilan bog‘lanish',
                'Contact ${item.name}',
              ),
          ],
          tags: const ['attendance', 'follow-up'],
        );
      }
      if (!mounted) return;
      SfToast.show(
        context,
        title: staffTr(context, 'Kuzatuv tayyor', 'Follow-up ready'),
        message: staffTr(
          context,
          '${selected.length} o‘quvchi vazifaga qo‘shildi.',
          '${selected.length} students were added to a task.',
        ),
        tone: SfToastTone.success,
      );
      final route = Uri(
        path: '/attendance',
        queryParameters: {
          'followUps': selected.map((item) => item.id).join(','),
        },
      ).toString();
      context.push(route);
    } catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        title: staffTr(context, 'Saqlanmadi', 'Could not save'),
        message: error.toString(),
        tone: SfToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _openingAttendance = false);
    }
  }

  DateTime _monthOffset(DateTime date, int offset) =>
      DateTime(date.year, date.month + offset, 1);

  String _shortMonth(BuildContext context, DateTime date) {
    final name = staffMonthName(context, date.month);
    return name.length <= 3 ? name : name.substring(0, 3);
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final item in [
            staffTr(context, 'Bugun', 'Today'),
            staffTr(context, 'Hafta', 'Week'),
            staffTr(context, 'Oy', 'Month'),
          ].asMap().entries)
            Expanded(
              child: SfPressable(
                key: Key('metric-period-${item.key}'),
                semanticLabel: item.value,
                selected: selected == item.key,
                onPressed: () => onSelected(item.key),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: SfMotion.resolve(context, SfMotion.standard),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == item.key
                        ? c.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected == item.key
                        ? [
                            BoxShadow(
                              color: c.ink.withValues(alpha: 0.08),
                              blurRadius: 9,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.value,
                    style: SfType.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: selected == item.key ? c.ink : c.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricHero extends StatelessWidget {
  const _MetricHero({
    required this.icon,
    required this.eyebrow,
    required this.value,
    required this.title,
    required this.message,
    required this.accent,
    required this.trailing,
  });
  final IconData icon;
  final String eyebrow;
  final String value;
  final String title;
  final String message;
  final Color accent;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, Color.lerp(c.surface, accent, .13)!],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 17, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      eyebrow,
                      style: SfType.eyebrow(color: accent, size: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  key: const Key('metric-hero-value'),
                  value,
                  style: SfType.mono(
                    size: 31,
                    weight: FontWeight.w800,
                    color: c.ink,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: SfType.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: SfType.ui(size: 10.5, color: c.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.label, required this.color});
  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: SfMotion.resolve(context, SfMotion.emphasized),
            curve: SfMotion.enter,
            builder: (context, animated, _) => CircularProgressIndicator(
              value: animated,
              strokeWidth: 7,
              color: color,
              backgroundColor: c.surface3,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: SfType.mono(
              size: label.contains('\n') ? 12 : 14,
              weight: FontWeight.w800,
              color: c.ink,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SfType.ui(size: 15, weight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 2),
        Text(caption, style: SfType.ui(size: 10.5, color: c.muted)),
      ],
    );
  }
}

class _LessonDrillRow extends StatelessWidget {
  const _LessonDrillRow({
    required this.lesson,
    required this.last,
    required this.onTap,
  });
  final TodayLessonData lesson;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final live = lesson.progress == LessonProgress.live;
    final color = switch (lesson.tone) {
      1 => c.accent,
      2 => c.ink2,
      _ => c.primary,
    };
    return SfPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                lesson.start,
                style: SfType.mono(
                  size: 10,
                  weight: FontWeight.w800,
                  color: color,
                ),
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
                      size: 13,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    staffTr(
                      context,
                      '${lesson.topic} · ${lesson.room}-xona',
                      '${staffLessonTopic(context, lesson)} · Room ${lesson.room}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 10, color: c.muted),
                  ),
                ],
              ),
            ),
            if (live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'HOZIR',
                  style: SfType.eyebrow(color: c.bg, size: 8),
                ),
              )
            else
              Icon(SfIcons.chevR, color: c.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InteractiveTrend extends StatelessWidget {
  const _InteractiveTrend({
    required this.title,
    required this.caption,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.detail,
    required this.color,
  });
  final String title;
  final String caption;
  final List<double> values;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SfType.ui(size: 14, weight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 2),
          Text(caption, style: SfType.ui(size: 10, color: c.muted)),
          const SizedBox(height: 17),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in values.asMap().entries)
                  Expanded(
                    child: SfPressable(
                      key: Key('trend-point-${entry.key}'),
                      semanticLabel:
                          '${labels[entry.key]} ${entry.value * 100}%',
                      selected: selected == entry.key,
                      onPressed: () => onSelected(entry.key),
                      borderRadius: BorderRadius.circular(8),
                      pressedScale: .94,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: SfMotion.resolve(
                              context,
                              SfMotion.emphasized,
                            ),
                            curve: SfMotion.enter,
                            width: 18,
                            height: 72 * entry.value,
                            decoration: BoxDecoration(
                              color: selected == entry.key
                                  ? color
                                  : color.withValues(alpha: .28),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            labels[entry.key],
                            maxLines: 1,
                            style: SfType.ui(
                              size: 8.5,
                              weight: selected == entry.key
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected == entry.key ? c.ink : c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: SfMotion.resolve(context, SfMotion.standard),
            child: Container(
              key: ValueKey('$selected-$detail'),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                detail,
                style: SfType.ui(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onTap,
      selected: selected,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.ink : c.border),
        ),
        child: Text(
          label,
          style: SfType.ui(
            size: 11,
            weight: FontWeight.w700,
            color: selected ? c.bg : c.ink2,
          ),
        ),
      ),
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  const _FollowUpRow({
    required this.name,
    required this.detail,
    required this.delta,
    required this.selected,
    required this.last,
    required this.onTap,
  });
  final String name;
  final String detail;
  final String delta;
  final bool selected;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onTap,
      selected: selected,
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? c.primarySoft.withValues(alpha: .45) : null,
          border: last ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: SfMotion.resolve(context, SfMotion.quick),
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: selected ? c.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? c.primary : c.borderStrong,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(
                      SfIcons.check,
                      size: 15,
                      color: Color(0xFFFFFCF5),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: SfType.ui(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(detail, style: SfType.ui(size: 10, color: c.muted)),
                ],
              ),
            ),
            Text(
              '−$delta',
              style: SfType.mono(
                size: 11,
                weight: FontWeight.w800,
                color: c.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({
    required this.label,
    required this.value,
    required this.benchmark,
    required this.color,
  });
  final String label;
  final double value;
  final double benchmark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SfType.ui(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}',
              style: SfType.mono(
                size: 12,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: SfMotion.resolve(context, SfMotion.emphasized),
                builder: (context, animated, _) => LinearProgressIndicator(
                  value: animated,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  backgroundColor: c.surface3,
                ),
              ),
              Positioned(
                left: constraints.maxWidth * benchmark - 1,
                top: -2,
                child: Container(
                  width: 2,
                  height: 12,
                  color: c.ink.withValues(alpha: .5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          staffTr(
            context,
            'Filial medianasi ${(benchmark * 100).round()}',
            'Branch median ${(benchmark * 100).round()}',
          ),
          style: SfType.ui(size: 8.5, color: c.muted),
        ),
      ],
    );
  }
}
