import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../router.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_ai_badge.dart';
import '../widgets/sf_ai_surface.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_tab_bar.dart';
import 'today/today_data.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selectedDate = staffToday;
  bool _aiExpanded = false;
  bool _aiDismissed = false;
  final Set<int> _completedAiSteps = {};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.maybeOf(context);
    final survey = app?.surveys.firstOrNull;
    final featuredLesson = featuredStaffLesson();
    final todaysLessons = lessonsFor(staffToday);
    return SfScaffold(
      tab: SfTab.home,
      onTabChanged: (tab) => handleTab(context, SfTab.values.indexOf(tab)),
      top: const _Header(),
      body: ListView(
        key: const PageStorageKey('teacher-today-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 44),
        children: [
          _Reveal(
            order: 0,
            child: _SurveyBanner(
              answered: survey?.answeredCount ?? 1,
              total: survey?.questions.length ?? 3,
              submitted: survey?.isSubmitted ?? false,
              onTap: () => context.push(
                survey?.isSubmitted == true ? '/surveys' : '/surveys/form',
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Reveal(
            order: 1,
            child: _NextLessonHero(
              lesson: featuredLesson,
              onOpen: () => context.push('/lesson?slot=${featuredLesson.id}'),
              onAttendance: () => context.push(
                '/attendance?cohort=${groupIdForLesson(featuredLesson)}',
              ),
              onMore: () => _showLessonPreview(context, featuredLesson),
            ),
          ),
          const SizedBox(height: 14),
          _Reveal(
            order: 2,
            child: _QuickStats(
              lessonCount: todaysLessons.length,
              liveCount: todaysLessons
                  .where((lesson) => lesson.progress == LessonProgress.live)
                  .length,
            ),
          ),
          const SizedBox(height: 16),
          _Reveal(
            order: 3,
            child: _AiPanel(
              expanded: _aiExpanded,
              dismissed: _aiDismissed,
              completedSteps: _completedAiSteps,
              onExpand: () => setState(() => _aiExpanded = !_aiExpanded),
              onDismiss: () => setState(() => _aiDismissed = true),
              onRestore: () => setState(() => _aiDismissed = false),
              onToggleStep: (index) => setState(() {
                if (!_completedAiSteps.add(index)) {
                  _completedAiSteps.remove(index);
                }
              }),
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeading(
            title: staffTr(context, 'Jadval', 'Schedule'),
            subtitle: staffDayTitle(context, _selectedDate),
            action: staffTr(context, 'To‘liq jadval', 'Full schedule'),
            onAction: () => context.push('/schedule'),
          ),
          const SizedBox(height: 10),
          _HomeDateStrip(
            selected: _selectedDate,
            onSelected: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: SfMotion.resolve(context, SfMotion.emphasized),
            switchInCurve: SfMotion.enter,
            switchOutCurve: SfMotion.exit,
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
            child: _ScheduleList(
              key: ValueKey(_selectedDate.day),
              date: _selectedDate,
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeading(
            title: staffTr(context, 'Sizning natijangiz', 'Your performance'),
            subtitle: staffMonthAndWeekLabel(context, staffToday),
            action: staffTr(context, 'Batafsil', 'Details'),
            onAction: () => context.push('/today/performance'),
          ),
          const SizedBox(height: 10),
          _TeacherPerformanceCard(
            onTap: () => context.push('/today/performance'),
          ),
          const SizedBox(height: 16),
          _PrintQueueCard(onTap: () => context.push('/print')),
        ],
      ),
    );
  }

  void _showLessonPreview(BuildContext context, TodayLessonData lesson) {
    final c = SfTheme.colorsOf(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffTr(context, 'Darsga tayyorgarlik', 'Lesson readiness'),
                style: SfType.ui(
                  size: 19,
                  weight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                staffTr(
                  context,
                  '${lesson.students} o‘quvchi · 3 material · rejaning 25% bajarilgan',
                  '${lesson.students} students · 3 materials · 25% of the plan complete',
                ),
                style: SfType.ui(size: 13, color: c.ink2),
              ),
              const SizedBox(height: 16),
              for (final item in [
                (
                  staffTr(
                    context,
                    'PDF va mashqlar tayyor',
                    'PDF and exercises are ready',
                  ),
                  Icons.task_alt_rounded,
                ),
                (
                  staffTr(
                    context,
                    '4 o‘quvchiga qo‘shimcha yordam kerak',
                    '4 students need extra support',
                  ),
                  Icons.groups_2_outlined,
                ),
                (
                  staffTr(
                    context,
                    '304-xona · proyektor band qilingan',
                    'Room 304 · projector reserved',
                  ),
                  Icons.meeting_room_outlined,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      Icon(item.$2, color: c.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$1,
                          style: SfType.ui(
                            size: 13,
                            weight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              SfButton(
                block: true,
                height: 50,
                label: staffTr(
                  context,
                  'Dars ish maydonini ochish',
                  'Open lesson workspace',
                ),
                trailing: SfIcons.arrowR,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/lesson?slot=${lesson.id}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          SfPressable(
            semanticLabel: staffTr(context, 'Profilni ochish', 'Open profile'),
            onPressed: () => context.push('/settings'),
            borderRadius: BorderRadius.circular(20),
            child: const SfAvatar(name: 'Nigora Karimova', size: 38),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffDayTitle(context, staffToday).toUpperCase(),
                  style: SfType.eyebrow(color: c.muted, size: 10),
                ),
                const SizedBox(height: 1),
                Text(
                  staffTr(
                    context,
                    'Xayrli tong, Nigora',
                    'Good morning, Nigora',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(
                    size: 16,
                    weight: FontWeight.w800,
                    color: c.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: SfIcons.bell,
            label: staffTr(context, 'Bildirishnomalar', 'Notifications'),
            showDot: true,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 6),
          _HeaderAction(
            icon: SfIcons.search,
            label: staffTr(context, 'Qidirish', 'Search'),
            onTap: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      semanticLabel: label,
      tooltip: label,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: c.ink),
          ),
          if (showDot)
            Positioned(
              top: 7,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface2, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SurveyBanner extends StatelessWidget {
  const _SurveyBanner({
    required this.answered,
    required this.total,
    required this.submitted,
    required this.onTap,
  });

  final int answered;
  final int total;
  final bool submitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = SfTheme.of(context);
    final c = theme.colors;
    final progress = total == 0 ? 0.0 : answered / total;
    final start = theme.dark
        ? Color.lerp(c.surface2, c.accent, 0.12)!
        : c.accentSoft;
    final end = theme.dark
        ? Color.lerp(c.surface, c.primary, 0.1)!
        : Color.lerp(c.surface, c.accentSoft, 0.58)!;
    return SfPressable(
      key: const Key('today-survey-banner'),
      semanticLabel: submitted
          ? staffTr(
              context,
              'Yuborilgan so‘rovnomalarni ko‘rish',
              'View submitted surveys',
            )
          : staffTr(context, 'So‘rovnomani davom ettirish', 'Continue survey'),
      onPressed: onTap,
      haptic: true,
      borderRadius: BorderRadius.circular(20),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start, end],
          ),
          border: Border.all(
            color: state.pressed ? c.accent : c.aiBorder,
            width: state.pressed ? 1.8 : 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: theme.dark ? 0.08 : 0.16),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -28,
              child: Opacity(
                opacity: theme.dark ? 0.08 : 0.14,
                child: SfStar(size: 112, color: c.accentInk),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: submitted ? 1 : progress,
                        strokeWidth: 4,
                        color: submitted ? c.success : c.primary,
                        backgroundColor: c.surface.withValues(alpha: 0.58),
                      ),
                      Icon(
                        submitted
                            ? Icons.task_alt_rounded
                            : Icons.fact_check_outlined,
                        size: 20,
                        color: submitted ? c.success : c.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submitted
                            ? staffTr(
                                context,
                                'SO‘ROVNOMA · YUBORILDI',
                                'SURVEY · SUBMITTED',
                              )
                            : staffTr(
                                context,
                                'SO‘ROVNOMA · 2 KUN QOLDI',
                                'SURVEY · 2 DAYS LEFT',
                              ),
                        style: SfType.eyebrow(
                          color: submitted ? c.success : c.primary,
                          size: 10,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        staffTr(
                          context,
                          'Haftalik dars tajribasi',
                          'Weekly teaching experience',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(
                          size: 14,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        submitted
                            ? staffTr(
                                context,
                                'Javoblaringiz qabul qilindi',
                                'Your answers were received',
                              )
                            : staffTr(
                                context,
                                '$answered/$total savol · taxminan 2 daqiqa',
                                '$answered/$total questions · about 2 minutes',
                              ),
                        style: SfType.ui(size: 11, color: c.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.ink,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(SfIcons.arrowR, size: 17, color: c.bg),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextLessonHero extends StatelessWidget {
  const _NextLessonHero({
    required this.lesson,
    required this.onOpen,
    required this.onAttendance,
    required this.onMore,
  });

  final TodayLessonData lesson;
  final VoidCallback onOpen;
  final VoidCallback onAttendance;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, Color.lerp(c.primaryHover, c.ink, 0.26)!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -38,
            child: Opacity(
              opacity: 0.12,
              child: const SfStar(size: 180, color: Color(0xFFFFFCF5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.15;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            compact
                                ? staffTr(
                                    context,
                                    'HOZIR · 14 DAQ',
                                    'NOW · 14 MIN',
                                  )
                                : staffTr(
                                    context,
                                    'HOZIR · 14 DAQIQA QOLDI',
                                    'NOW · 14 MINUTES LEFT',
                                  ),
                            style: SfType.eyebrow(
                              color: const Color(0xFFFFFCF5),
                              size: 9,
                            ),
                          ),
                        ),
                        Text(
                          lesson.timeRange,
                          style: SfType.mono(
                            size: 13,
                            weight: FontWeight.w700,
                            color: const Color(0xFFFFFCF5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),
                Text(
                  '${staffLessonSubject(context, lesson)} · ${staffLessonLevel(context, lesson)}',
                  style: SfType.ui(
                    size: 24,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFFFCF5),
                    letterSpacing: -0.55,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  staffLessonTopic(context, lesson),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFFFFFCF5).withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _HeroMeta(icon: SfIcons.cohort, label: lesson.cohort),
                    _HeroMeta(
                      icon: Icons.people_outline_rounded,
                      label: staffTr(
                        context,
                        '${lesson.students} o‘quvchi',
                        '${lesson.students} students',
                      ),
                    ),
                    _HeroMeta(
                      icon: Icons.meeting_room_outlined,
                      label: staffTr(
                        context,
                        '${lesson.room}-xona',
                        'Room ${lesson.room}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow =
                        constraints.maxWidth < 360 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.1;
                    final openButton = SfButton(
                      key: const ValueKey('today-open-lesson-action'),
                      block: true,
                      kind: SfButtonKind.primary,
                      label: staffTr(context, 'Darsni ochish', 'Open lesson'),
                      trailing: SfIcons.arrowR,
                      fontSize: 13,
                      height: 46,
                      overrideBg: const Color(0xFFFFFCF5),
                      overrideFg: c.primary,
                      onPressed: onOpen,
                    );
                    final attendanceButton = SfButton(
                      key: const ValueKey('today-attendance-action'),
                      block: true,
                      kind: SfButtonKind.ghost,
                      label: staffTr(context, 'Davomat', 'Attendance'),
                      leading: SfIcons.check,
                      fontSize: 13,
                      height: 46,
                      overrideFg: const Color(0xFFFFFCF5),
                      onPressed: onAttendance,
                    );
                    if (narrow) {
                      return Column(
                        children: [
                          openButton,
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: attendanceButton),
                              const SizedBox(width: 8),
                              _MoreLessonButton(onTap: onMore),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 3, child: openButton),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: attendanceButton),
                        const SizedBox(width: 8),
                        _MoreLessonButton(onTap: onMore),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFFFCF5)),
        const SizedBox(width: 5),
        Text(
          label,
          style: SfType.ui(
            size: 11,
            weight: FontWeight.w700,
            color: const Color(0xFFFFFCF5),
          ),
        ),
      ],
    ),
  );
}

class _MoreLessonButton extends StatelessWidget {
  const _MoreLessonButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SfPressable(
    semanticLabel: staffTr(context, 'Dars tafsilotlari', 'Lesson details'),
    onPressed: onTap,
    haptic: true,
    borderRadius: BorderRadius.circular(23),
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(SfIcons.more, size: 19, color: Color(0xFFFFFCF5)),
    ),
  );
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.lessonCount, required this.liveCount});

  final int lessonCount;
  final int liveCount;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final metrics = [
      (
        '$lessonCount',
        staffTr(context, 'Bugungi dars', 'Lessons today'),
        liveCount == 0
            ? staffTr(context, 'Hozir faol dars yo‘q', 'No lesson in progress')
            : staffTr(
                context,
                '$liveCount tasi davom etmoqda',
                '$liveCount in progress',
              ),
        Icons.calendar_view_day_rounded,
        c.primary,
        '/today/lessons',
      ),
      (
        '94%',
        staffTr(context, 'Davomat', 'Attendance'),
        staffTr(context, '+2.4% bu hafta', '+2.4% this week'),
        Icons.how_to_reg_rounded,
        c.success,
        '/today/attendance',
      ),
      (
        '#7',
        staffTr(context, 'O‘qituvchi reytingi', 'Teacher ranking'),
        staffTr(context, '148 o‘qituvchi ichida', 'Out of 148 teachers'),
        Icons.workspace_premium_outlined,
        c.accent,
        '/today/performance',
      ),
    ];
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final singleColumn = constraints.maxWidth < 330 || scale > 1.18;
        if (singleColumn) {
          return Column(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                if (index > 0) const SizedBox(height: gap),
                _metricCard(context, metrics[index], horizontal: true),
              ],
            ],
          );
        }

        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              SizedBox(
                height: 158,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _metricCard(context, metrics[0])),
                    const SizedBox(width: gap),
                    Expanded(child: _metricCard(context, metrics[1])),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              _metricCard(context, metrics[2], horizontal: true),
            ],
          );
        }

        return SizedBox(
          height: 152,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                if (index > 0) const SizedBox(width: gap),
                Expanded(child: _metricCard(context, metrics[index])),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context,
    (String, String, String, IconData, Color, String) metric, {
    bool horizontal = false,
  }) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      key: ValueKey('today-metric-${metric.$6}'),
      semanticLabel: staffTr(
        context,
        '${metric.$2} tafsilotlarini ochish',
        'Open ${metric.$2} details',
      ),
      onPressed: () => context.push(metric.$6),
      haptic: true,
      borderRadius: BorderRadius.circular(20),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        constraints: BoxConstraints(minHeight: horizontal ? 84 : 148),
        padding: EdgeInsets.all(horizontal ? 14 : 12),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface2 : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: state.hovered ? metric.$5 : c.border),
        ),
        child: horizontal
            ? Row(
                children: [
                  _MetricIcon(icon: metric.$4, color: metric.$5),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCopy(
                      value: metric.$1,
                      title: metric.$2,
                      caption: metric.$3,
                      color: metric.$5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(SfIcons.chevR, color: c.muted, size: 19),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MetricIcon(
                        icon: metric.$4,
                        color: metric.$5,
                        compact: true,
                      ),
                      const Spacer(),
                      Icon(SfIcons.chevR, color: c.muted, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MetricCopy(
                    value: metric.$1,
                    title: metric.$2,
                    caption: metric.$3,
                    color: metric.$5,
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({
    required this.icon,
    required this.color,
    this.compact = false,
  });
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 31 : 40,
    height: compact ? 31 : 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: compact ? 17 : 20, color: color),
  );
}

class _MetricCopy extends StatelessWidget {
  const _MetricCopy({
    required this.value,
    required this.title,
    required this.caption,
    required this.color,
  });
  final String value;
  final String title;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: SfType.mono(
            size: 22,
            weight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SfType.ui(
            size: 11,
            weight: FontWeight.w800,
            color: c.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SfType.ui(size: 9.5, color: c.muted, height: 1.25),
        ),
      ],
    );
  }
}

class _AiPanel extends StatelessWidget {
  const _AiPanel({
    required this.expanded,
    required this.dismissed,
    required this.completedSteps,
    required this.onExpand,
    required this.onDismiss,
    required this.onRestore,
    required this.onToggleStep,
  });

  final bool expanded;
  final bool dismissed;
  final Set<int> completedSteps;
  final VoidCallback onExpand;
  final VoidCallback onDismiss;
  final VoidCallback onRestore;
  final ValueChanged<int> onToggleStep;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    if (dismissed) {
      return SfSurfaceCard(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(SfIcons.ai, color: c.ai, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                staffTr(
                  context,
                  'AI tavsiyasi keyinroq uchun yashirildi',
                  'AI insight was saved for later',
                ),
                style: SfType.ui(size: 12, color: c.ink2),
              ),
            ),
            TextButton(
              onPressed: onRestore,
              child: Text(staffTr(context, 'Qaytarish', 'Restore')),
            ),
          ],
        ),
      );
    }
    return SfAiSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              SfAiBadge(
                key: const ValueKey('today-ai-badge'),
                label: staffTr(context, 'Bugungi insight', 'Today’s insight'),
                compact: true,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  staffTr(context, 'YUQORI AHAMIYAT', 'HIGH PRIORITY'),
                  style: SfType.eyebrow(color: c.danger, size: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            staffTr(
              context,
              'Otabekning ishtiroki pasaymoqda',
              'Otabek’s engagement is declining',
            ),
            style: SfType.ui(
              size: 18,
              weight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -0.32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            staffTr(
              context,
              'Oxirgi 7 kunda davomat 18% pasaydi va ikki marta tayyorgarliksiz keldi. Bugun kichik, xolis suhbat eng foydali qadam bo‘ladi.',
              'Attendance fell 18% over the last 7 days and he arrived unprepared twice. A short, neutral conversation today is the best next step.',
            ),
            style: SfType.ui(size: 13, color: c.ink2, height: 1.55),
          ),
          AnimatedSize(
            duration: SfMotion.resolve(context, SfMotion.emphasized),
            curve: SfMotion.enter,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.aiBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staffTr(
                              context,
                              '3 QADAMLI MIKRO-REJA',
                              '3-STEP MICRO PLAN',
                            ),
                            style: SfType.eyebrow(color: c.ai, size: 9),
                          ),
                          const SizedBox(height: 8),
                          for (final step in [
                            staffTr(
                              context,
                              'Darsdan keyin 3 daqiqalik suhbat',
                              'Hold a 3-minute conversation after class',
                            ),
                            staffTr(
                              context,
                              'Keyingi vazifani kichik bo‘laklarga ajratish',
                              'Break the next assignment into smaller steps',
                            ),
                            staffTr(
                              context,
                              'Juma kuni progressni qayta tekshirish',
                              'Review progress again on Friday',
                            ),
                          ].asMap().entries)
                            _AiStep(
                              index: step.key,
                              text: step.value,
                              completed: completedSteps.contains(step.key),
                              onTap: () => onToggleStep(step.key),
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SfButton(
                kind: SfButtonKind.ink,
                label: expanded
                    ? staffTr(context, 'Rejani yopish', 'Close plan')
                    : staffTr(
                        context,
                        'Amaliy rejani ko‘rish',
                        'View action plan',
                      ),
                trailing: expanded ? SfIcons.chevD : SfIcons.arrowR,
                fontSize: 12,
                onPressed: onExpand,
              ),
              SfButton(
                kind: SfButtonKind.ghost,
                label: staffTr(context, 'Keyinroq', 'Later'),
                fontSize: 12,
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiStep extends StatelessWidget {
  const _AiStep({
    required this.index,
    required this.text,
    required this.completed,
    required this.onTap,
  });
  final int index;
  final String text;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      key: Key('ai-step-$index'),
      semanticLabel: text,
      selected: completed,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: SfMotion.resolve(context, SfMotion.quick),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: completed ? c.success : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: completed ? c.success : c.borderStrong,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: SfMotion.resolve(context, SfMotion.quick),
                child: completed
                    ? const Icon(
                        SfIcons.check,
                        key: ValueKey(true),
                        size: 14,
                        color: Color(0xFFFFFCF5),
                      )
                    : const SizedBox(key: ValueKey(false)),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style:
                    SfType.ui(
                      size: 12,
                      weight: FontWeight.w600,
                      color: completed ? c.muted : c.ink,
                      height: 1.35,
                    ).copyWith(
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SfType.ui(
                  size: 17,
                  weight: FontWeight.w800,
                  color: c.ink,
                  letterSpacing: -0.22,
                ),
              ),
              const SizedBox(height: 1),
              Text(subtitle, style: SfType.ui(size: 11, color: c.muted)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          iconAlignment: IconAlignment.end,
          icon: Icon(SfIcons.chevR, size: 16, color: c.primary),
          label: Text(
            action,
            style: SfType.ui(
              size: 11,
              weight: FontWeight.w700,
              color: c.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeDateStrip extends StatefulWidget {
  const _HomeDateStrip({required this.selected, required this.onSelected});
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_HomeDateStrip> createState() => _HomeDateStripState();
}

class _HomeDateStripState extends State<_HomeDateStrip> {
  static const _tileWidth = 60.0;
  static const _gap = 7.0;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final selectedIndex = widget.selected.difference(staffWeekStart).inDays;
    final leadingIndex = (selectedIndex - 2).clamp(0, 6);
    _controller = ScrollController(
      initialScrollOffset: leadingIndex * (_tileWidth + _gap),
    );
    _scheduleReveal(animate: false);
  }

  @override
  void didUpdateWidget(covariant _HomeDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selected, widget.selected)) {
      _scheduleReveal(animate: true);
    }
  }

  void _scheduleReveal({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final selectedIndex = widget.selected
          .difference(staffWeekStart)
          .inDays
          .clamp(0, 6);
      final viewport = _controller.position.viewportDimension;
      final desired =
          selectedIndex * (_tileWidth + _gap) - (viewport - _tileWidth) / 2;
      final target = desired.clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      );
      if (animate) {
        _controller.animateTo(
          target,
          duration: SfMotion.resolve(context, SfMotion.standard),
          curve: SfMotion.enter,
        );
      } else {
        _controller.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SizedBox(
      height: 68,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, i) => SizedBox(
          width: _tileWidth,
          child: Builder(
            builder: (context) {
              final date = staffWeekStart.add(Duration(days: i));
              final active = DateUtils.isSameDay(date, widget.selected);
              final count = lessonsFor(date).length;
              return SfPressable(
                key: Key('today-date-${date.day}'),
                semanticLabel: staffTr(
                  context,
                  '${staffDayTitle(context, date)}, $count ta dars',
                  '${staffDayTitle(context, date)}, $count lessons',
                ),
                selected: active,
                haptic: true,
                onPressed: () => widget.onSelected(date),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: SfMotion.resolve(context, SfMotion.standard),
                  curve: SfMotion.enter,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? c.ink : c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? c.ink : c.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        staffWeekdayShort(context, date.weekday).toUpperCase(),
                        style: SfType.eyebrow(
                          color: active ? c.bg : c.muted,
                          size: 8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${date.day}',
                        style: SfType.mono(
                          size: 17,
                          weight: FontWeight.w800,
                          color: active ? c.bg : c.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: count == 0 ? 4 : 13,
                        height: 3,
                        decoration: BoxDecoration(
                          color: active
                              ? c.accent
                              : count == 0
                              ? c.borderStrong
                              : c.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final lessons = lessonsFor(date);
    if (lessons.isEmpty) {
      return SfSurfaceCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.successSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.spa_outlined, color: c.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffTr(
                      context,
                      'Dars rejalashtirilmagan',
                      'No lessons scheduled',
                    ),
                    style: SfType.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    staffTr(
                      context,
                      'Rejalashtirish yoki tayyorgarlik uchun ochiq kun.',
                      'An open day for planning or preparation.',
                    ),
                    style: SfType.ui(size: 11, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final entry in lessons.asMap().entries) ...[
          if (entry.key > 0) const SizedBox(height: 8),
          _ScheduleRow(lesson: entry.value),
        ],
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.lesson});
  final TodayLessonData lesson;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final live = lesson.progress == LessonProgress.live;
    final complete = lesson.progress == LessonProgress.completed;
    final tone = switch (lesson.tone) {
      1 => c.accent,
      2 => c.ink2,
      _ => c.primary,
    };
    return SfPressable(
      semanticLabel: staffTr(
        context,
        '${lesson.title}, ${lesson.timeRange}, batafsil ochish',
        '${staffLessonTitle(context, lesson)}, ${lesson.timeRange}, open details',
      ),
      onPressed: () => context.push('/lesson?slot=${lesson.id}'),
      haptic: true,
      borderRadius: BorderRadius.circular(18),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: state.pressed
              ? c.surface2
              : complete
              ? c.surface2.withValues(alpha: 0.5)
              : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: state.hovered ? tone : c.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.start,
                    style: SfType.mono(
                      size: 12,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(lesson.end, style: SfType.mono(size: 9, color: c.muted)),
                ],
              ),
            ),
            Container(
              width: 4,
              height: 46,
              decoration: BoxDecoration(
                color: complete ? c.borderStrong : tone,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffLessonTitle(context, lesson),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: complete ? c.muted : c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    staffTr(
                      context,
                      '${lesson.topic} · ${lesson.room}-xona',
                      '${staffLessonTopic(context, lesson)} · Room ${lesson.room}',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            if (live)
              SfPill(
                tone: SfPillTone.primary,
                label: staffTr(context, 'Hozir', 'Now'),
              )
            else if (complete)
              Icon(Icons.task_alt_rounded, size: 19, color: c.success)
            else
              Icon(SfIcons.chevR, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _TeacherPerformanceCard extends StatelessWidget {
  const _TeacherPerformanceCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      semanticLabel: staffTr(
        context,
        'O‘qituvchi natijasi va reytingini ochish',
        'Open teacher performance and ranking',
      ),
      haptic: true,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(24),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              state.pressed ? c.surface2 : c.surface,
              Color.lerp(c.surface, c.primarySoft, 0.42)!,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: c.ink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.ink.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#7',
                        style: SfType.mono(
                          size: 20,
                          weight: FontWeight.w800,
                          color: c.bg,
                          height: 1,
                        ),
                      ),
                      Text(
                        staffTr(context, 'REYTING', 'RANK'),
                        style: SfType.eyebrow(color: c.accent, size: 6.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffTr(
                          context,
                          'Kuchli o‘sish haftasi',
                          'A strong growth week',
                        ),
                        style: SfType.ui(
                          size: 16,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        staffTr(
                          context,
                          'Siz filialdagi o‘qituvchilarning eng yuqori 5% qismidasiz.',
                          'You are in the top 5% of teachers at your branch.',
                        ),
                        style: SfType.ui(size: 11, color: c.ink2, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Icon(SfIcons.chevR, color: c.primary),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PerformanceMeasure(
                    label: staffTr(context, 'Dars sifati', 'Lesson quality'),
                    value: 0.92,
                    valueLabel: '92',
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: _PerformanceMeasure(
                    label: staffTr(context, 'O‘sish', 'Growth'),
                    value: 0.86,
                    valueLabel: '+12%',
                    color: c.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      staffTr(
                        context,
                        'Eng kuchli signal: 9-B guruhi natijasi 8% o‘sdi.',
                        'Strongest signal: Group 9-B improved by 8%.',
                      ),
                      style: SfType.ui(
                        size: 11,
                        weight: FontWeight.w700,
                        color: c.ink,
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
}

class _PerformanceMeasure extends StatelessWidget {
  const _PerformanceMeasure({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.color,
  });
  final String label;
  final double value;
  final String valueLabel;
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
                  size: 10,
                  weight: FontWeight.w700,
                  color: c.muted,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: SfType.mono(
                size: 11,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: SfMotion.resolve(context, SfMotion.emphasized),
          curve: SfMotion.enter,
          builder: (context, animated, _) => LinearProgressIndicator(
            value: animated,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: c.surface3,
          ),
        ),
      ],
    );
  }
}

class _PrintQueueCard extends StatelessWidget {
  const _PrintQueueCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      semanticLabel: staffTr(
        context,
        'Print navbatini ochish, 2 ta ish',
        'Open print queue, 2 jobs',
      ),
      onPressed: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SfSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(SfIcons.printer, size: 21, color: c.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffTr(
                      context,
                      'Print navbati · 2 ta ish',
                      'Print queue · 2 jobs',
                    ),
                    style: SfType.ui(
                      size: 13,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    staffTr(
                      context,
                      'Kvadrat tenglamalar · 64% tayyor',
                      'Quadratic equations · 64% ready',
                    ),
                    style: SfType.ui(size: 10.5, color: c.muted),
                  ),
                ],
              ),
            ),
            Icon(SfIcons.chevR, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: SfMotion.resolve(
      context,
      Duration(milliseconds: 300 + order * 65),
    ),
    curve: SfMotion.enter,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
}
