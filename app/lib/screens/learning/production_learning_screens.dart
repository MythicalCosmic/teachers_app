import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/backend_learning_api.dart';
import '../../data/api/backend_models.dart';
import '../../data/models.dart';
import '../../features/learning/learning_workspace_controller.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';
import '../../widgets/sf_tab_bar.dart';
import '../../widgets/sf_toast.dart';

const _todayMotivations = <_TodayMotivationCopy>[
  _TodayMotivationCopy(
    uzTitle: 'Sizning xotirjamligingiz o\'rganishga joy yaratadi',
    uzBody:
        'Har bir puxta tayyorlangan daqiqa o\'quvchi uchun ishonchli qadamga aylanadi.',
    ruTitle: 'Ваше спокойствие создаёт пространство для знаний',
    ruBody:
        'Каждая минута вдумчивой подготовки становится уверенным шагом ученика.',
    enTitle: 'Your calm creates room for learning',
    enBody:
        'Every thoughtful minute of preparation becomes a confident step for a student.',
  ),
  _TodayMotivationCopy(
    uzTitle: 'Kichik tayyorgarlik katta ishonch beradi',
    uzBody:
        'Bugungi sokin vaqtni ertangi darsni yanada yengil va mazmunli qilish uchun ishlating.',
    ruTitle: 'Небольшая подготовка даёт большую уверенность',
    ruBody:
        'Используйте спокойное время сегодня, чтобы завтрашний урок стал легче и содержательнее.',
    enTitle: 'Small preparation builds big confidence',
    enBody:
        'Use today\'s quiet space to make tomorrow\'s lesson lighter and more meaningful.',
  ),
  _TodayMotivationCopy(
    uzTitle: 'Yaxshi ustoz sokin kunlarda ham o\'sadi',
    uzBody:
        'Dam olish, fikrlarni tartiblash va yangi g\'oya topish ham muhim ishning bir qismi.',
    ruTitle: 'Хороший педагог растёт даже в спокойные дни',
    ruBody:
        'Отдых, порядок в мыслях и новая идея — такая же важная часть вашей работы.',
    enTitle: 'Great teachers grow on quiet days too',
    enBody:
        'Rest, a clear mind, and one fresh idea are meaningful parts of the work too.',
  ),
  _TodayMotivationCopy(
    uzTitle: 'Bugungi e\'tiboringiz ertangi natijani yaratadi',
    uzBody:
        'Bir materialni yaxshilash yoki bir o\'quvchini eslashning o\'zi ham katta farq qiladi.',
    ruTitle: 'Сегодняшнее внимание создаёт завтрашний результат',
    ruBody:
        'Даже один улучшенный материал или внимание к одному ученику меняют многое.',
    enTitle: 'Today\'s care shapes tomorrow\'s progress',
    enBody:
        'Improving one resource or thinking about one learner can make a real difference.',
  ),
  _TodayMotivationCopy(
    uzTitle: 'Taqvim bo\'sh, lekin kun imkoniyatlarga to\'la',
    uzBody:
        'Shoshilmasdan rejalang, kuch to\'plang va keyingi darsga o\'zingizga xos iliqlik olib keling.',
    ruTitle: 'Расписание свободно, но день полон возможностей',
    ruBody:
        'Планируйте без спешки, восстановите силы и принесите своё тепло на следующий урок.',
    enTitle: 'The schedule is open, and the day is full of possibility',
    enBody:
        'Plan without rushing, recharge, and bring your own warmth into the next lesson.',
  ),
];

final Random _todayMotivationRandom = Random();
int? _lastTodayMotivationIndex;

int _resolveTodayMotivationIndex(int? override) {
  if (override != null) {
    return override.abs() % _todayMotivations.length;
  }
  var index = _todayMotivationRandom.nextInt(_todayMotivations.length);
  if (_todayMotivations.length > 1 && index == _lastTodayMotivationIndex) {
    index =
        (index +
            1 +
            _todayMotivationRandom.nextInt(_todayMotivations.length - 1)) %
        _todayMotivations.length;
  }
  _lastTodayMotivationIndex = index;
  return index;
}

@immutable
class _TodayMotivationCopy {
  const _TodayMotivationCopy({
    required this.uzTitle,
    required this.uzBody,
    required this.ruTitle,
    required this.ruBody,
    required this.enTitle,
    required this.enBody,
  });

  final String uzTitle;
  final String uzBody;
  final String ruTitle;
  final String ruBody;
  final String enTitle;
  final String enBody;
}

class ProductionTodayScreen extends StatefulWidget {
  const ProductionTodayScreen({
    super.key,
    required this.controller,
    this.motivationIndexOverride,
  });

  final LearningWorkspaceController controller;

  /// Keeps motivation-focused widget tests deterministic. Production callers
  /// leave this null so every newly-created home screen gets a fresh message.
  @visibleForTesting
  final int? motivationIndexOverride;

  @override
  State<ProductionTodayScreen> createState() => _ProductionTodayScreenState();
}

class _ProductionTodayScreenState extends State<ProductionTodayScreen> {
  late DateTime _selectedDate;
  late final int _motivationIndex;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _motivationIndex = _resolveTodayMotivationIndex(
      widget.motivationIndexOverride,
    );
    unawaited(widget.controller.refreshToday(_selectedDate, force: false));
  }

  @override
  void didUpdateWidget(covariant ProductionTodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      unawaited(widget.controller.refreshToday(_selectedDate, force: false));
    }
  }

  Future<void> _refresh() =>
      widget.controller.refreshToday(_selectedDate, force: true);

  void _selectDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    if (DateUtils.isSameDay(normalized, _selectedDate)) return;
    setState(() => _selectedDate = normalized);
    unawaited(
      widget.controller.loadLessons(
        LearningWorkspaceController.dayRange(normalized),
        force: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, app]),
      builder: (context, _) {
        final lessonResource = widget.controller.lessons(
          LearningWorkspaceController.dayRange(_selectedDate),
        );
        final dashboardResource = widget.controller.dashboard;
        final dashboard = dashboardResource.value;
        final dashboardLoading = dashboardResource.isLoading;
        final lessons = [...?lessonResource.value]
          ..sort((a, b) => _lessonTime(a).compareTo(_lessonTime(b)));
        final blocking = _blockingState(
          context,
          lessonResource,
          onRetry: _refresh,
          loadingMessage: _text(
            context,
            uz: 'Bugungi darslar xavfsiz serverdan olinmoqda.',
            ru: 'Сегодняшние уроки загружаются с защищённого сервера.',
            en: 'Today’s lessons are loading from the secure server.',
          ),
        );

        return SfScaffold(
          tab: SfTab.home,
          onTabChanged: (tab) => _openTab(context, tab),
          top: SfLargeAppBar(
            title: _text(
              context,
              uz: 'Bugungi ish maydoni',
              ru: 'Рабочее пространство',
              en: 'Today’s workspace',
            ),
            subtitle: [
              if (app.session?.displayName case final name?
                  when name.isNotEmpty)
                name,
              _longDate(context, DateTime.now()),
            ].join(' · '),
            actions: [
              SfPressable(
                semanticLabel: _text(
                  context,
                  uz: 'Jadvalni ochish',
                  ru: 'Открыть расписание',
                  en: 'Open schedule',
                ),
                onPressed: () => context.push('/schedule'),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(SfIcons.cal),
                ),
              ),
            ],
          ),
          body:
              blocking ??
              RefreshIndicator.adaptive(
                onRefresh: _refresh,
                child: ListView(
                  key: const PageStorageKey('production-today-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
                  children: [
                    _ConnectionStrip(
                      syncing:
                          app.isSyncing ||
                          lessonResource.isLoading ||
                          dashboardLoading,
                      center: app.centerName,
                      lastSyncedAt: app.lastSyncedAt,
                    ),
                    const SizedBox(height: 13),
                    _DashboardMetrics(
                      dashboard: dashboard,
                      loading: dashboardLoading,
                      lessonCount: lessons.length,
                      onGroups: () => context.go('/workspace'),
                    ),
                    const SizedBox(height: 12),
                    _TodayMotivationCard(
                      motivation: _todayMotivations[_motivationIndex],
                    ),
                    if (dashboardResource.isUnavailable ||
                        dashboardResource.isFailure) ...[
                      const SizedBox(height: 14),
                      _InlineModuleState(
                        resource: dashboardResource,
                        title: _text(
                          context,
                          uz: 'Ko‘rsatkichlar moduli mavjud emas',
                          ru: 'Модуль показателей недоступен',
                          en: 'Dashboard metrics unavailable',
                        ),
                        onRetry: () =>
                            widget.controller.loadDashboard(force: true),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _SectionLabel(
                      title: _text(
                        context,
                        uz: 'Sana bo‘yicha jadval',
                        ru: 'Расписание по дате',
                        en: 'Schedule by date',
                      ),
                      action: _text(
                        context,
                        uz: 'To‘liq jadval',
                        ru: 'Всё расписание',
                        en: 'Full schedule',
                      ),
                      onAction: () => context.push('/schedule'),
                    ),
                    const SizedBox(height: 10),
                    _ProductionDateStrip(
                      selected: _selectedDate,
                      onSelected: _selectDate,
                    ),
                    const SizedBox(height: 13),
                    AnimatedSwitcher(
                      duration: SfMotion.resolve(context, SfMotion.emphasized),
                      child: lessons.isEmpty
                          ? _EmptyLessonCard(
                              key: ValueKey(
                                'empty-${_selectedDate.toIso8601String()}',
                              ),
                              date: _selectedDate,
                            )
                          : Column(
                              key: ValueKey(
                                'lessons-${_selectedDate.toIso8601String()}',
                              ),
                              children: [
                                for (
                                  var index = 0;
                                  index < lessons.length;
                                  index++
                                ) ...[
                                  _ProductionLessonCard(
                                    lesson: lessons[index],
                                    prominent: index == 0,
                                  ),
                                  if (index != lessons.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(
                      title: _text(
                        context,
                        uz: 'Keyingi muhim ishlar',
                        ru: 'Следующие важные дела',
                        en: 'What needs attention',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AttentionCard(
                      dashboard: dashboard,
                      loading: dashboardLoading,
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }
}

enum ProductionScheduleView { day, week, month }

class ProductionScheduleScreen extends StatefulWidget {
  const ProductionScheduleScreen({super.key, required this.controller});

  final LearningWorkspaceController controller;

  @override
  State<ProductionScheduleScreen> createState() =>
      _ProductionScheduleScreenState();
}

class _ProductionScheduleScreenState extends State<ProductionScheduleScreen> {
  late DateTime _selectedDate;
  late final int _emptyMotivationIndex;
  ProductionScheduleView _view = ProductionScheduleView.week;
  String _status = 'all';
  int? _expandedLesson;

  LearningRange get _range => switch (_view) {
    ProductionScheduleView.day => LearningWorkspaceController.dayRange(
      _selectedDate,
    ),
    ProductionScheduleView.week => LearningWorkspaceController.weekRange(
      _selectedDate,
    ),
    ProductionScheduleView.month => LearningWorkspaceController.monthRange(
      _selectedDate,
    ),
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _emptyMotivationIndex = Random().nextInt(_scheduleMotivationCount);
    unawaited(widget.controller.loadLessons(_range));
  }

  Future<void> _refresh() => widget.controller.loadLessons(_range, force: true);

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _expandedLesson = null;
    });
    unawaited(widget.controller.loadLessons(_range));
  }

  void _changeView(ProductionScheduleView view) {
    if (_view == view) return;
    setState(() {
      _view = view;
      _expandedLesson = null;
    });
    unawaited(widget.controller.loadLessons(_range));
  }

  void _move(int direction) {
    final target = switch (_view) {
      ProductionScheduleView.day => _selectedDate.add(
        Duration(days: direction),
      ),
      ProductionScheduleView.week => _selectedDate.add(
        Duration(days: direction * 7),
      ),
      ProductionScheduleView.month => DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
        1,
      ),
    };
    _selectDate(target);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final resource = widget.controller.lessons(_range);
      final all = resource.value ?? const <BackendLesson>[];
      final selectedDayLessons = all.where((lesson) {
        final start = lesson.startsAt?.toLocal();
        return start != null && DateUtils.isSameDay(start, _selectedDate);
      }).toList()..sort((a, b) => _lessonTime(a).compareTo(_lessonTime(b)));
      final dayLessons = selectedDayLessons
          .where((lesson) => _status == 'all' || lesson.status == _status)
          .toList(growable: false);
      final statusCounts = <String, int>{
        'all': selectedDayLessons.length,
        for (final status in const ['scheduled', 'completed', 'cancelled'])
          status: selectedDayLessons
              .where((lesson) => lesson.status == status)
              .length,
      };
      final blocking = _blockingState(
        context,
        resource,
        onRetry: _refresh,
        loadingMessage: _text(
          context,
          uz: 'Jadval yuklanmoqda.',
          ru: 'Расписание загружается.',
          en: 'Your schedule is loading.',
        ),
      );
      return SfScaffold(
        top: SfNavBar(
          title: _text(context, uz: 'Jadval', ru: 'Расписание', en: 'Schedule'),
          subtitle: _monthYear(context, _selectedDate),
          leading: IconButton(
            tooltip: _text(context, uz: 'Orqaga', ru: 'Назад', en: 'Back'),
            onPressed: context.pop,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          actions: [
            TextButton(
              onPressed: () => _selectDate(DateTime.now()),
              child: Text(
                _text(context, uz: 'Bugun', ru: 'Сегодня', en: 'Today'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _ProductionScheduleControls(
              selectedDate: _selectedDate,
              view: _view,
              onPrevious: () => _move(-1),
              onNext: () => _move(1),
              onViewChanged: _changeView,
            ),
            Expanded(
              child:
                  blocking ??
                  RefreshIndicator.adaptive(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 30),
                      children: [
                        if (_view == ProductionScheduleView.month) ...[
                          _ScheduleMonthCalendar(
                            selected: _selectedDate,
                            lessons: all,
                            onSelected: _selectDate,
                          ),
                          const SizedBox(height: 12),
                        ] else if (_view == ProductionScheduleView.week) ...[
                          _ScheduleWeekStrip(
                            selected: _selectedDate,
                            lessons: all,
                            onSelected: _selectDate,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _StatusFilters(
                          selected: _status,
                          counts: statusCounts,
                          onSelected: (value) =>
                              setState(() => _status = value),
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel(
                          title: _longDate(context, _selectedDate),
                          subtitle: _text(
                            context,
                            uz: '${dayLessons.length} ta dars',
                            ru: '${dayLessons.length} уроков',
                            en: '${dayLessons.length} lessons',
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (selectedDayLessons.isEmpty)
                          _EmptyScheduleExperience(
                            key: ValueKey(
                              'production-empty-schedule-${_dateKey(_selectedDate)}',
                            ),
                            date: _selectedDate,
                            motivationIndex: _emptyMotivationIndex,
                            onOpenTasks: () => context.push('/tasks'),
                            onOpenGroups: () => context.push('/cohorts'),
                          )
                        else if (dayLessons.isEmpty)
                          _EmptyScheduleFilterResult(
                            status: _status,
                            onClear: () => setState(() => _status = 'all'),
                          )
                        else
                          for (
                            var index = 0;
                            index < dayLessons.length;
                            index++
                          ) ...[
                            _ProductionLessonCard(
                              lesson: dayLessons[index],
                              expanded: _expandedLesson == dayLessons[index].id,
                              onTap: () => setState(() {
                                _expandedLesson =
                                    _expandedLesson == dayLessons[index].id
                                    ? null
                                    : dayLessons[index].id;
                              }),
                            ),
                            if (index != dayLessons.length - 1)
                              const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
            ),
          ],
        ),
      );
    },
  );
}

class ProductionCohortListScreen extends StatefulWidget {
  const ProductionCohortListScreen({super.key, required this.controller});

  final LearningWorkspaceController controller;

  @override
  State<ProductionCohortListScreen> createState() =>
      _ProductionCohortListScreenState();
}

class _ProductionCohortListScreenState
    extends State<ProductionCohortListScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  bool? _archived = false;
  String _ordering = 'name';

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.loadCohorts());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = true}) => widget.controller.loadCohorts(
    search: _search.text,
    archived: _archived,
    ordering: _ordering,
    force: force,
  );

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(_load());
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final resource = widget.controller.cohorts;
      final cohorts = resource.value ?? const <BackendCohort>[];
      final blocking = _blockingState(
        context,
        resource,
        onRetry: _load,
        loadingMessage: _text(
          context,
          uz: 'Sizga biriktirilgan guruhlar yuklanmoqda.',
          ru: 'Загружаются назначенные вам группы.',
          en: 'Your assigned groups are loading.',
        ),
      );
      return SfScaffold(
        tab: SfTab.cohort,
        onTabChanged: (tab) => _openTab(context, tab),
        top: SfLargeAppBar(
          title: _text(context, uz: 'Guruhlar', ru: 'Группы', en: 'Groups'),
          subtitle: _text(
            context,
            uz: '${cohorts.length} ta natija · server bilan sinxron',
            ru: '${cohorts.length} результатов · синхронизировано',
            en: '${cohorts.length} results · synced with server',
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: _text(
                context,
                uz: 'Saralash',
                ru: 'Сортировка',
                en: 'Sort groups',
              ),
              initialValue: _ordering,
              onSelected: (value) {
                setState(() => _ordering = value);
                unawaited(_load());
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'name',
                  child: Text(
                    _text(
                      context,
                      uz: 'Nomi bo‘yicha',
                      ru: 'По имени',
                      en: 'Name',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: '-created_at',
                  child: Text(
                    _text(
                      context,
                      uz: 'Eng yangi',
                      ru: 'Сначала новые',
                      en: 'Newest',
                    ),
                  ),
                ),
              ],
              icon: const Icon(Icons.sort_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: SfTheme.colorsOf(context).surface,
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 13),
              child: Column(
                children: [
                  TextField(
                    key: const ValueKey('production-group-search'),
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: _text(
                        context,
                        uz: 'Guruh, daraja yoki bo‘limni qidiring',
                        ru: 'Поиск группы, уровня или отдела',
                        en: 'Search group, level or department',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                                unawaited(_load());
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<bool?>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(
                            _text(
                              context,
                              uz: 'Faol',
                              ru: 'Активные',
                              en: 'Active',
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: null,
                          label: Text(
                            _text(context, uz: 'Hammasi', ru: 'Все', en: 'All'),
                          ),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(
                            _text(
                              context,
                              uz: 'Arxiv',
                              ru: 'Архив',
                              en: 'Archived',
                            ),
                          ),
                        ),
                      ],
                      selected: {_archived},
                      onSelectionChanged: (value) {
                        setState(() => _archived = value.first);
                        unawaited(_load());
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  blocking ??
                  RefreshIndicator.adaptive(
                    onRefresh: _load,
                    child: cohorts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 420,
                                child: SfEmptyState(
                                  title: _text(
                                    context,
                                    uz: 'Guruh topilmadi',
                                    ru: 'Группы не найдены',
                                    en: 'No groups found',
                                  ),
                                  message: _text(
                                    context,
                                    uz: 'Qidiruv yoki arxiv filtrini o‘zgartiring.',
                                    ru: 'Измените поиск или фильтр архива.',
                                    en: 'Try changing the search or archive filter.',
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            key: const PageStorageKey(
                              'production-groups-scroll',
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                            itemCount: cohorts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 11),
                            itemBuilder: (context, index) =>
                                _ProductionCohortCard(
                                  cohort: cohorts[index],
                                  onTap: () => context.push(
                                    '/cohort?id=${cohorts[index].id}',
                                  ),
                                ),
                          ),
                  ),
            ),
          ],
        ),
      );
    },
  );
}

enum _AttendanceRangePreset { sevenDays, thirtyDays, term, custom }

class ProductionCohortDetailScreen extends StatefulWidget {
  const ProductionCohortDetailScreen({
    super.key,
    required this.controller,
    required this.groupId,
    this.initialTab,
  });

  final LearningWorkspaceController controller;
  final String? groupId;
  final int? initialTab;

  @override
  State<ProductionCohortDetailScreen> createState() =>
      _ProductionCohortDetailScreenState();
}

class _ProductionCohortDetailScreenState
    extends State<ProductionCohortDetailScreen> {
  late final int? _cohortId;
  final TextEditingController _memberSearch = TextEditingController();
  int _tab = 0;
  _AttendanceRangePreset _rangePreset = _AttendanceRangePreset.thirtyDays;
  DateTimeRange? _customRange;
  String _attendanceStatus = 'all';
  int? _lessonFilter;

  LearningRange get _range {
    final now = DateTime.now();
    if (_rangePreset == _AttendanceRangePreset.custom && _customRange != null) {
      return LearningRange(
        DateUtils.dateOnly(_customRange!.start),
        DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    }
    final start = switch (_rangePreset) {
      _AttendanceRangePreset.sevenDays => now.subtract(const Duration(days: 6)),
      _AttendanceRangePreset.thirtyDays => now.subtract(
        const Duration(days: 29),
      ),
      _AttendanceRangePreset.term => DateTime(now.year, 1, 1),
      _AttendanceRangePreset.custom => now.subtract(const Duration(days: 29)),
    };
    return LearningRange(
      DateUtils.dateOnly(start),
      DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  @override
  void initState() {
    super.initState();
    _cohortId = int.tryParse(widget.groupId?.trim() ?? '');
    _tab = widget.initialTab?.clamp(0, 3).toInt() ?? 0;
    if (_cohortId case final id?) {
      unawaited(widget.controller.loadCohort(id, range: _range));
    }
  }

  @override
  void dispose() {
    _memberSearch.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final id = _cohortId;
    if (id == null) return;
    await widget.controller.loadCohort(id, range: _range, force: true);
  }

  Future<void> _pickCustomRange() async {
    final current =
        _customRange ?? DateTimeRange(start: _range.from, end: _range.to);
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: current,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: _text(
        context,
        uz: 'Davomat oralig‘ini tanlang',
        ru: 'Выберите период посещаемости',
        en: 'Choose attendance range',
      ),
    );
    if (selected == null) return;
    setState(() {
      _customRange = selected;
      _rangePreset = _AttendanceRangePreset.custom;
    });
    await _refresh();
  }

  void _changeRange(_AttendanceRangePreset value) {
    if (value == _AttendanceRangePreset.custom) {
      unawaited(_pickCustomRange());
      return;
    }
    setState(() {
      _rangePreset = value;
      _customRange = null;
    });
    unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cohortId = _cohortId;
    if (cohortId == null || cohortId <= 0) {
      return _InvalidLearningRoute(
        title: _text(
          context,
          uz: 'Guruh tanlanmagan',
          ru: 'Группа не выбрана',
          en: 'No group selected',
        ),
        message: _text(
          context,
          uz: 'Guruhlar sahifasidan aniq guruhni tanlang.',
          ru: 'Выберите конкретную группу на странице групп.',
          en: 'Choose a specific group from the Groups page.',
        ),
      );
    }
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.cohortState(cohortId);
        final blocking = _blockingState(
          context,
          state.cohort,
          onRetry: _refresh,
          unavailableTitle: _text(
            context,
            uz: 'Guruh mavjud emas',
            ru: 'Группа недоступна',
            en: 'Group unavailable',
          ),
          loadingMessage: _text(
            context,
            uz: 'Guruh ma’lumotlari yuklanmoqda.',
            ru: 'Данные группы загружаются.',
            en: 'Group details are loading.',
          ),
        );
        final cohort = state.cohort.value;
        if (blocking != null || cohort == null) {
          return SfScaffold(
            top: SfNavBar(
              title: _text(context, uz: 'Guruh', ru: 'Группа', en: 'Group'),
              leading: IconButton(
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            body: blocking ?? const SizedBox.shrink(),
          );
        }
        final members = state.members.value ?? const <BackendCohortMember>[];
        return SfScaffold(
          top: SfNavBar(
            title: cohort.name,
            subtitle: _text(
              context,
              uz: '${members.length} o‘quvchi · ${cohort.defaultRoomName.isEmpty ? 'xona belgilanmagan' : cohort.defaultRoomName}',
              ru: '${members.length} учеников · ${cohort.defaultRoomName.isEmpty ? 'кабинет не указан' : cohort.defaultRoomName}',
              en: '${members.length} students · ${cohort.defaultRoomName.isEmpty ? 'no room assigned' : cohort.defaultRoomName}',
            ),
            leading: IconButton(
              tooltip: _text(context, uz: 'Orqaga', ru: 'Назад', en: 'Back'),
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              IconButton(
                tooltip: _text(
                  context,
                  uz: 'Yangilash',
                  ru: 'Обновить',
                  en: 'Refresh',
                ),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator.adaptive(
            onRefresh: _refresh,
            child: ListView(
              key: ValueKey('production-cohort-$cohortId-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
              children: [
                _ProductionCohortHero(
                  cohort: cohort,
                  members: members.length,
                  attendance: state.attendance.value?.rate,
                  onAttendance: () =>
                      context.push('/attendance?cohort=$cohortId'),
                ),
                const SizedBox(height: 15),
                _CohortTabs(
                  selected: _tab,
                  onSelected: (value) => setState(() => _tab = value),
                ),
                const SizedBox(height: 15),
                AnimatedSwitcher(
                  duration: SfMotion.resolve(context, SfMotion.standard),
                  child: switch (_tab) {
                    0 => _CohortOverview(
                      key: const ValueKey('production-cohort-overview'),
                      cohort: cohort,
                      state: state,
                    ),
                    1 => _CohortMembers(
                      key: const ValueKey('production-cohort-members'),
                      resource: state.members,
                      search: _memberSearch,
                      onSearchChanged: (_) => setState(() {}),
                    ),
                    2 => _CohortAttendance(
                      key: const ValueKey('production-cohort-attendance'),
                      state: state,
                      preset: _rangePreset,
                      onPresetChanged: _changeRange,
                      status: _attendanceStatus,
                      onStatusChanged: (value) =>
                          setState(() => _attendanceStatus = value),
                      lessonId: _lessonFilter,
                      onLessonChanged: (value) =>
                          setState(() => _lessonFilter = value),
                      onTakeAttendance: () =>
                          context.push('/attendance?cohort=$cohortId'),
                    ),
                    _ => _CohortSchedule(
                      key: const ValueKey('production-cohort-schedule'),
                      resource: state.lessons,
                    ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductionAttendanceScreen extends StatefulWidget {
  const ProductionAttendanceScreen({
    super.key,
    required this.controller,
    this.cohortId,
    this.lessonId,
  });

  final LearningWorkspaceController controller;
  final String? cohortId;
  final String? lessonId;

  @override
  State<ProductionAttendanceScreen> createState() =>
      _ProductionAttendanceScreenState();
}

class _ProductionAttendanceScreenState
    extends State<ProductionAttendanceScreen> {
  late final int? _cohortId;
  late int? _selectedLessonId;
  final TextEditingController _search = TextEditingController();
  final Map<int, AttendanceStatus> _statuses = {};
  final Map<int, String> _notes = {};
  final Map<int, DateTime> _serverArrivedAt = {};
  final Set<int> _cardedStudents = {};
  int? _hydratedLessonId;
  bool _submitting = false;
  String? _selectionError;

  late final LearningRange _range;

  @override
  void initState() {
    super.initState();
    _cohortId = int.tryParse(widget.cohortId?.trim() ?? '');
    _selectedLessonId = int.tryParse(widget.lessonId?.trim() ?? '');
    final now = DateTime.now();
    _range = LearningRange(
      DateUtils.dateOnly(now.subtract(const Duration(days: 90))),
      DateTime(now.year, now.month + 6, now.day, 23, 59, 59, 999),
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    final cohortId = _cohortId;
    if (cohortId == null || cohortId <= 0) return;
    final operations = <Future<void>>[
      widget.controller.loadCohort(cohortId, range: _range, force: force),
      widget.controller.loadRecognitionCatalog(
        cohortId: cohortId,
        force: force,
      ),
    ];
    final lessonId = _selectedLessonId;
    if (lessonId != null) {
      if (force) _hydratedLessonId = null;
      operations.add(widget.controller.loadLesson(lessonId, force: force));
      operations.add(
        widget.controller.loadLessonAttendance(lessonId, force: force),
      );
    }
    await Future.wait(operations);
    if (mounted) _hydrateFromServer();
  }

  Future<void> _selectLesson(int? lessonId) async {
    if (lessonId == _selectedLessonId) return;
    setState(() {
      _selectedLessonId = lessonId;
      _hydratedLessonId = null;
      _statuses.clear();
      _notes.clear();
      _serverArrivedAt.clear();
      _selectionError = null;
    });
    if (lessonId == null) return;
    await Future.wait([
      widget.controller.loadLesson(lessonId),
      widget.controller.loadLessonAttendance(lessonId),
    ]);
    if (mounted) _hydrateFromServer();
  }

  void _hydrateFromServer() {
    final lessonId = _selectedLessonId;
    if (lessonId == null || _hydratedLessonId == lessonId) return;
    final cohortId = _cohortId;
    final lesson = widget.controller.lesson(lessonId).value;
    if (lesson != null &&
        lesson.cohortId != null &&
        lesson.cohortId != cohortId) {
      setState(() {
        _selectionError = _text(
          context,
          uz: 'Tanlangan dars bu guruhga tegishli emas.',
          ru: 'Выбранный урок не относится к этой группе.',
          en: 'The selected lesson does not belong to this group.',
        );
        _hydratedLessonId = lessonId;
      });
      return;
    }
    final records = widget.controller.attendanceForLesson(lessonId).value;
    if (records == null) return;
    setState(() {
      _selectionError = null;
      _statuses.clear();
      _notes.clear();
      _serverArrivedAt.clear();
      for (final record in records) {
        final status = _attendanceStatusFromServer(record.status);
        if (status != null) _statuses[record.studentId] = status;
        if (record.note.isNotEmpty) _notes[record.studentId] = record.note;
        if (record.arrivedAt case final arrivedAt?) {
          _serverArrivedAt[record.studentId] = arrivedAt;
        }
      }
      _hydratedLessonId = lessonId;
    });
  }

  Future<void> _mark(
    BackendCohortMember member,
    AttendanceStatus status,
  ) async {
    String? note;
    if (status == AttendanceStatus.absent ||
        status == AttendanceStatus.excused) {
      note = await _attendanceNote(context, member.studentName, status);
      if (note == null) return;
    }
    setState(() {
      _statuses[member.studentId] = status;
      if (note == null || note.trim().isEmpty) {
        _notes.remove(member.studentId);
      } else {
        _notes[member.studentId] = note.trim();
      }
    });
  }

  Future<void> _submit(List<BackendCohortMember> members) async {
    final lessonId = _selectedLessonId;
    final cohortId = _cohortId;
    if (lessonId == null || cohortId == null || _submitting) return;
    if (members.any((member) => !_statuses.containsKey(member.studentId))) {
      SfToast.show(
        context,
        message: _text(
          context,
          uz: 'Avval barcha o‘quvchilarning holatini belgilang.',
          ru: 'Сначала отметьте всех учеников.',
          en: 'Mark every student before submitting.',
        ),
        tone: SfToastTone.error,
      );
      return;
    }
    final lesson = widget.controller.lesson(lessonId).value;
    final approved = await showSfConfirmDialog(
      context,
      title: _text(
        context,
        uz: 'Davomat yuborilsinmi?',
        ru: 'Отправить посещаемость?',
        en: 'Submit attendance?',
      ),
      message: _text(
        context,
        uz: '${members.length} o‘quvchi · ${lesson?.title ?? 'dars'}',
        ru: '${members.length} учеников · ${lesson?.title ?? 'урок'}',
        en: '${members.length} students · ${lesson?.title ?? 'lesson'}',
      ),
      cancelLabel: _text(
        context,
        uz: 'Tekshirish',
        ru: 'Проверить',
        en: 'Review',
      ),
      confirmLabel: _text(
        context,
        uz: 'Yuborish',
        ru: 'Отправить',
        en: 'Submit',
      ),
    );
    if (!approved || !mounted) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.controller.markAttendance(
        lessonId,
        [
          for (final member in members)
            BackendAttendanceEntry(
              studentId: member.studentId,
              status: _statuses[member.studentId]!.name,
              arrivedAt: _statuses[member.studentId] == AttendanceStatus.late
                  ? _serverArrivedAt[member.studentId]
                  : null,
              note: _notes[member.studentId] ?? '',
            ),
        ],
        cohortId: cohortId,
        refreshRange: _range,
      );
      if (!mounted) return;
      _hydratedLessonId = null;
      _hydrateFromServer();
      SfToast.show(
        context,
        title: _text(
          context,
          uz: 'Davomat saqlandi',
          ru: 'Посещаемость сохранена',
          en: 'Attendance saved',
        ),
        message: _text(
          context,
          uz: '${result.created} ta yaratildi · ${result.updated} ta yangilandi',
          ru: 'Создано: ${result.created} · обновлено: ${result.updated}',
          en: '${result.created} created · ${result.updated} updated',
        ),
        tone: SfToastTone.success,
      );
    } on Object catch (error) {
      if (!mounted) return;
      SfToast.show(context, message: error.toString(), tone: SfToastTone.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _giveCard(BackendCohortMember member) async {
    final lessonId = _selectedLessonId;
    final cohortId = _cohortId;
    if (lessonId == null || cohortId == null) return;
    final given = await _showStudentCardSheet(
      context,
      controller: widget.controller,
      member: member,
      lessonId: lessonId,
      cohortId: cohortId,
    );
    if (given && mounted) {
      setState(() => _cardedStudents.add(member.studentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cohortId = _cohortId;
    if (cohortId == null || cohortId <= 0) {
      return _InvalidLearningRoute(
        title: _text(
          context,
          uz: 'Davomat uchun guruh tanlang',
          ru: 'Выберите группу для посещаемости',
          en: 'Choose a group for attendance',
        ),
        message: _text(
          context,
          uz: 'Noto‘g‘ri guruhga belgi qo‘ymaslik uchun guruh avtomatik tanlanmaydi.',
          ru: 'Группа не выбирается автоматически, чтобы избежать ошибки.',
          en: 'A group is never selected automatically, preventing marks in the wrong group.',
        ),
      );
    }
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.cohortState(cohortId);
        final cohortBlocking = _blockingState(
          context,
          state.cohort,
          onRetry: () => _load(force: true),
          unavailableTitle: _text(
            context,
            uz: 'Guruh mavjud emas',
            ru: 'Группа недоступна',
            en: 'Group unavailable',
          ),
        );
        final cohort = state.cohort.value;
        final members = state.members.value ?? const <BackendCohortMember>[];
        final lessons = [...?state.lessons.value]
          ..sort((a, b) => _lessonTime(b).compareTo(_lessonTime(a)));
        final selectedLessonId = _selectedLessonId;
        final lessonResource = selectedLessonId == null
            ? const LearningResource<BackendLesson>.idle()
            : widget.controller.lesson(selectedLessonId);
        final attendanceResource = selectedLessonId == null
            ? const LearningResource<List<BackendAttendanceRecord>>.idle()
            : widget.controller.attendanceForLesson(selectedLessonId);
        if (selectedLessonId != null &&
            _hydratedLessonId != selectedLessonId &&
            lessonResource.value != null &&
            attendanceResource.value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _hydrateFromServer();
          });
        }
        final visible = members.where((member) {
          final query = _search.text.trim().toLowerCase();
          return query.isEmpty ||
              member.studentName.toLowerCase().contains(query);
        }).toList();
        final complete =
            members.isNotEmpty &&
            members.every((member) => _statuses.containsKey(member.studentId));

        return SfScaffold(
          top: SfNavBar(
            title: _text(
              context,
              uz: 'Davomat',
              ru: 'Посещаемость',
              en: 'Attendance',
            ),
            subtitle: cohort?.name,
            leading: IconButton(
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              IconButton(
                tooltip: _text(
                  context,
                  uz: 'Yangilash',
                  ru: 'Обновить',
                  en: 'Refresh',
                ),
                onPressed: () => _load(force: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body:
              cohortBlocking ??
              RefreshIndicator.adaptive(
                onRefresh: () => _load(force: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  children: [
                    _AttendanceLessonPicker(
                      lessons: lessons,
                      selected: selectedLessonId,
                      onSelected: _selectLesson,
                    ),
                    if (selectedLessonId == null) ...[
                      const SizedBox(height: 18),
                      SfEmptyState(
                        icon: Icons.event_available_outlined,
                        title: _text(
                          context,
                          uz: 'Aniq darsni tanlang',
                          ru: 'Выберите конкретный урок',
                          en: 'Select the exact lesson',
                        ),
                        message: _text(
                          context,
                          uz: 'Davomat faqat tanlangan guruhning haqiqiy darsiga yuboriladi.',
                          ru: 'Посещаемость отправляется только для выбранного урока этой группы.',
                          en: 'Attendance is submitted only for a real lesson in this group.',
                        ),
                      ),
                    ] else if (_selectionError != null) ...[
                      const SizedBox(height: 18),
                      SfErrorState(
                        title: _text(
                          context,
                          uz: 'Dars mos kelmadi',
                          ru: 'Урок не соответствует группе',
                          en: 'Lesson mismatch',
                        ),
                        message: _selectionError,
                      ),
                    ] else if (lessonResource.value == null &&
                        (lessonResource.isLoading ||
                            lessonResource.phase ==
                                LearningLoadPhase.idle)) ...[
                      const SizedBox(height: 18),
                      SfLoadingState(
                        label: _text(
                          context,
                          uz: 'Dars tekshirilmoqda…',
                          ru: 'Проверка урока…',
                          en: 'Verifying lesson…',
                        ),
                      ),
                    ] else if (lessonResource.isUnavailable ||
                        lessonResource.isFailure) ...[
                      const SizedBox(height: 18),
                      _InlineModuleState(
                        resource: lessonResource,
                        title: _text(
                          context,
                          uz: 'Darsni ochib bo‘lmadi',
                          ru: 'Не удалось открыть урок',
                          en: 'Lesson unavailable',
                        ),
                        onRetry: () => _load(force: true),
                      ),
                    ] else if (attendanceResource.isUnavailable ||
                        attendanceResource.isFailure) ...[
                      const SizedBox(height: 18),
                      _InlineModuleState(
                        resource: attendanceResource,
                        title: _text(
                          context,
                          uz: 'Davomat mavjud emas',
                          ru: 'Посещаемость недоступна',
                          en: 'Attendance unavailable',
                        ),
                        onRetry: () => _load(force: true),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      _AttendanceProgress(
                        members: members,
                        statuses: _statuses,
                        onMarkRemaining: () => setState(() {
                          for (final member in members) {
                            _statuses.putIfAbsent(
                              member.studentId,
                              () => AttendanceStatus.present,
                            );
                          }
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _text(
                            context,
                            uz: 'O‘quvchini qidiring',
                            ru: 'Найти ученика',
                            en: 'Search students',
                          ),
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.members.isUnavailable ||
                          state.members.isFailure)
                        _InlineModuleState(
                          resource: state.members,
                          title: _text(
                            context,
                            uz: 'O‘quvchilar mavjud emas',
                            ru: 'Ученики недоступны',
                            en: 'Students unavailable',
                          ),
                          onRetry: () => _load(force: true),
                        )
                      else if (members.isEmpty && state.members.isLoading)
                        SfLoadingState(
                          label: _text(
                            context,
                            uz: 'O‘quvchilar yuklanmoqda…',
                            ru: 'Загрузка учеников…',
                            en: 'Loading students…',
                          ),
                        )
                      else if (members.isEmpty)
                        SfEmptyState(
                          title: _text(
                            context,
                            uz: 'Guruhda faol o‘quvchi yo‘q',
                            ru: 'В группе нет активных учеников',
                            en: 'No active students in this group',
                          ),
                        )
                      else
                        for (
                          var index = 0;
                          index < visible.length;
                          index++
                        ) ...[
                          _AttendanceMemberRow(
                            member: visible[index],
                            status: _statuses[visible[index].studentId],
                            note: _notes[visible[index].studentId],
                            onSelected: (status) =>
                                _mark(visible[index], status),
                            cardGiven: _cardedStudents.contains(
                              visible[index].studentId,
                            ),
                            onGiveCard: () => _giveCard(visible[index]),
                          ),
                          if (index != visible.length - 1)
                            const SizedBox(height: 8),
                        ],
                    ],
                  ],
                ),
              ),
          bottom: selectedLessonId != null && _selectionError == null
              ? _AttendanceSubmitBar(
                  marked: _statuses.length,
                  total: members.length,
                  submitting: _submitting,
                  enabled: complete && !_submitting,
                  onSubmit: () => _submit(members),
                )
              : null,
        );
      },
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({
    required this.syncing,
    required this.center,
    required this.lastSyncedAt,
  });

  final bool syncing;
  final String center;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.success.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: SfMotion.resolve(context, SfMotion.quick),
            child: syncing
                ? SizedBox.square(
                    key: const ValueKey('learning-syncing'),
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.success,
                    ),
                  )
                : Icon(
                    Icons.cloud_done_outlined,
                    key: const ValueKey('learning-synced'),
                    size: 18,
                    color: c.success,
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              syncing
                  ? _text(
                      context,
                      uz: 'Server bilan yangilanmoqda…',
                      ru: 'Обновление с сервера…',
                      en: 'Refreshing from the server…',
                    )
                  : _text(
                      context,
                      uz: '${center.isEmpty ? 'StarForge EDU' : center} · ma’lumotlar dolzarb',
                      ru: '${center.isEmpty ? 'StarForge EDU' : center} · данные актуальны',
                      en: '${center.isEmpty ? 'StarForge EDU' : center} · data is current',
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(
                size: 11,
                weight: FontWeight.w700,
                color: c.ink2,
              ),
            ),
          ),
          if (!syncing && lastSyncedAt != null)
            Text(
              _time(lastSyncedAt!.toLocal()),
              style: SfType.mono(size: 10, color: c.muted),
            ),
        ],
      ),
    );
  }
}

class _TodayMotivationCard extends StatelessWidget {
  const _TodayMotivationCard({required this.motivation});

  final _TodayMotivationCopy motivation;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final title = _text(
      context,
      uz: motivation.uzTitle,
      ru: motivation.ruTitle,
      en: motivation.enTitle,
    );
    final body = _text(
      context,
      uz: motivation.uzBody,
      ru: motivation.ruBody,
      en: motivation.enBody,
    );
    return TweenAnimationBuilder<double>(
      duration: SfMotion.resolve(context, SfMotion.emphasized),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - progress)),
          child: child,
        ),
      ),
      child: Semantics(
        container: true,
        label: '$title. $body',
        child: Container(
          key: const ValueKey('production-today-motivation'),
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c.primarySoft,
                Color.alphaBlend(c.accent.withValues(alpha: .07), c.surface),
              ],
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: c.primary.withValues(alpha: .18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: .82),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: c.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        context,
                        uz: 'BUGUNGI ILHOM',
                        ru: 'ВДОХНОВЕНИЕ НА СЕГОДНЯ',
                        en: 'TODAY\'S ENCOURAGEMENT',
                      ),
                      style: SfType.eyebrow(size: 8.5, color: c.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: SfType.ui(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: SfType.ui(size: 10.5, height: 1.35, color: c.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({
    required this.dashboard,
    required this.loading,
    required this.lessonCount,
    required this.onGroups,
  });

  final BackendTeacherDashboard? dashboard;
  final bool loading;
  final int lessonCount;
  final VoidCallback onGroups;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final metrics = <(IconData, int?, String, Color)>[
      (
        Icons.groups_2_outlined,
        dashboard?.groupsCount,
        _text(context, uz: 'Guruh', ru: 'Группы', en: 'Groups'),
        c.primary,
      ),
      (
        Icons.school_outlined,
        dashboard?.studentsCount,
        _text(context, uz: 'O‘quvchi', ru: 'Ученики', en: 'Students'),
        c.accent,
      ),
      (
        Icons.event_note_outlined,
        lessonCount,
        _text(context, uz: 'Dars', ru: 'Уроки', en: 'Lessons'),
        c.success,
      ),
    ];
    String displayValue(int? value) =>
        value?.toString() ?? (loading ? '…' : '—');
    String displayStatus(int? value) {
      if (value == null) {
        return loading
            ? _text(context, uz: 'Yuklanmoqda', ru: 'Загрузка', en: 'Loading')
            : _text(
                context,
                uz: 'Mavjud emas',
                ru: 'Недоступно',
                en: 'Unavailable',
              );
      }
      return value == 0
          ? _text(context, uz: 'Bo‘sh', ru: 'Пусто', en: 'Empty')
          : _text(context, uz: 'Dolzarb', ru: 'Актуально', en: 'Current');
    }

    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: SfPressable(
              onPressed: index < 2 ? onGroups : () => context.push('/schedule'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                key: ValueKey('production-today-metric-$index'),
                constraints: const BoxConstraints(minHeight: 108),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    Icon(metrics[index].$1, size: 19, color: metrics[index].$4),
                    const SizedBox(height: 6),
                    Text(
                      displayValue(metrics[index].$2),
                      style: SfType.mono(
                        size: 20,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      metrics[index].$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(size: 9.5, color: c.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayStatus(metrics[index].$2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 8,
                        weight: FontWeight.w700,
                        color: metrics[index].$2 == 0 ? c.success : c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.dashboard, required this.loading});

  final BackendTeacherDashboard? dashboard;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final items = <(IconData, int?, String)>[
      (
        Icons.fact_check_outlined,
        dashboard?.pendingForms.length,
        _text(
          context,
          uz: 'Kutilayotgan shakllar',
          ru: 'Ожидающие формы',
          en: 'Pending forms',
        ),
      ),
      (
        Icons.rule_folder_outlined,
        dashboard?.pendingRuleAcknowledgments,
        _text(
          context,
          uz: 'Qoidalar tasdig‘i',
          ru: 'Подтверждения правил',
          en: 'Rule acknowledgements',
        ),
      ),
      (
        Icons.quiz_outlined,
        dashboard?.upcomingExams.length,
        _text(
          context,
          uz: 'Yaqin imtihonlar',
          ru: 'Ближайшие экзамены',
          en: 'Upcoming exams',
        ),
      ),
    ];
    final allEmpty = dashboard != null && items.every((item) => item.$2 == 0);
    final statusMessage = allEmpty
        ? _text(
            context,
            uz: 'Hammasi joyida — hozircha hech narsa kutilmayapti.',
            ru: 'Всё в порядке — сейчас ничего не ожидает.',
            en: 'All clear — nothing is waiting right now.',
          )
        : dashboard == null
        ? loading
              ? _text(
                  context,
                  uz: 'Ish maydoni tekshirilmoqda…',
                  ru: 'Проверяем рабочее пространство…',
                  en: 'Checking your workspace…',
                )
              : _text(
                  context,
                  uz: 'Hisoblar mavjud emas — yangilash uchun pastga torting.',
                  ru: 'Данные недоступны — потяните вниз, чтобы обновить.',
                  en: 'Counts are unavailable — pull down to try again.',
                )
        : null;
    return SfSurfaceCard(
      key: const ValueKey('production-today-attention-card'),
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(items[index].$1, size: 19, color: c.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    items[index].$3,
                    style: SfType.ui(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ),
                Text(
                  items[index].$2?.toString() ?? (loading ? '…' : '—'),
                  style: SfType.mono(
                    size: 15,
                    weight: FontWeight.w800,
                    color: switch (items[index].$2) {
                      final count? when count > 0 => c.warn,
                      0 => c.success,
                      _ => c.muted,
                    },
                  ),
                ),
              ],
            ),
            if (index != items.length - 1) Divider(height: 18, color: c.border),
          ],
          if (statusMessage != null) ...[
            Divider(height: 20, color: c.border),
            Container(
              key: const ValueKey('production-today-attention-status'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: allEmpty ? c.successSoft : c.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    allEmpty
                        ? Icons.check_circle_outline_rounded
                        : Icons.sync_rounded,
                    size: 17,
                    color: allEmpty ? c.success : c.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: SfType.ui(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: c.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

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
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: SfType.ui(size: 10.5, color: c.muted)),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
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

class _ProductionDateStrip extends StatelessWidget {
  const _ProductionDateStrip({
    required this.selected,
    required this.onSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(
      selected.subtract(Duration(days: selected.weekday - 1)),
    );
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final today = DateUtils.dateOnly(DateTime.now());
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final itemWidth = (constraints.maxWidth - gap * 6) / 7;
        return Semantics(
          label: _text(
            context,
            uz: 'Haftalik sana tanlash',
            ru: 'Выбор даты на неделю',
            en: 'Weekly date picker',
          ),
          child: Row(
            children: [
              for (var index = 0; index < 7; index++) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: itemWidth,
                  child: Builder(
                    builder: (context) {
                      final date = start.add(Duration(days: index));
                      final active = DateUtils.isSameDay(date, selected);
                      final isToday = DateUtils.isSameDay(date, today);
                      return SfPressable(
                        key: ValueKey(
                          'production-today-date-${date.toIso8601String()}',
                        ),
                        selected: active,
                        onPressed: () => onSelected(date),
                        borderRadius: BorderRadius.circular(15),
                        child: AnimatedContainer(
                          duration: SfMotion.resolve(context, SfMotion.quick),
                          height: 72,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? c.primary : c.surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: active
                                  ? c.primary
                                  : isToday
                                  ? c.primary.withValues(alpha: .55)
                                  : c.border,
                              width: isToday && !active ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekdayShort(context, date.weekday),
                                maxLines: 1,
                                style: SfType.eyebrow(
                                  size: itemWidth < 43 ? 6.5 : 7.5,
                                  color: active ? onPrimary : c.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: SfType.mono(
                                  size: itemWidth < 43 ? 14.5 : 17,
                                  weight: FontWeight.w800,
                                  color: active ? onPrimary : c.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: SfMotion.resolve(
                                  context,
                                  SfMotion.quick,
                                ),
                                width: isToday ? 12 : 4,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: active
                                      ? c.accent
                                      : isToday
                                      ? c.primary
                                      : Colors.transparent,
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
              ],
            ],
          ),
        );
      },
    );
  }
}

const _scheduleMotivationCount = 5;

class _EmptyScheduleExperience extends StatelessWidget {
  const _EmptyScheduleExperience({
    super.key,
    required this.date,
    required this.motivationIndex,
    required this.onOpenTasks,
    required this.onOpenGroups,
  });

  final DateTime date;
  final int motivationIndex;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenGroups;

  @override
  Widget build(BuildContext context) {
    final duration = SfMotion.resolve(context, SfMotion.standard);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: SfMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmptyLessonCard(date: date),
          const SizedBox(height: 12),
          const _EmptyScheduleSummary(),
          const SizedBox(height: 12),
          _ScheduleMotivationCard(index: motivationIndex),
          const SizedBox(height: 12),
          _EmptyScheduleNextSteps(
            onOpenTasks: onOpenTasks,
            onOpenGroups: onOpenGroups,
          ),
        ],
      ),
    );
  }
}

class _EmptyLessonCard extends StatelessWidget {
  const _EmptyLessonCard({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      key: const ValueKey('production-empty-lesson-card'),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.successSoft,
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.event_available_rounded, color: c.success),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text(
                          context,
                          uz: 'Bu sanada dars yo‘q',
                          ru: 'На эту дату уроков нет',
                          en: 'No lessons on this date',
                        ),
                        style: SfType.ui(
                          size: 14.5,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SfPill(
                      tone: SfPillTone.success,
                      label: _text(
                        context,
                        uz: '0 dars',
                        ru: '0 уроков',
                        en: '0 lessons',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _longDate(context, date),
                  style: SfType.ui(size: 11, color: c.muted),
                ),
                const SizedBox(height: 7),
                Text(
                  _text(
                    context,
                    uz: 'Bu sana uchun guruh, xona yoki dars vaqti biriktirilmagan.',
                    ru: 'На эту дату не назначены группа, кабинет или время урока.',
                    en: 'No group, room, or teaching time is assigned to this date.',
                  ),
                  style: SfType.ui(size: 11.5, color: c.ink2, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleSummary extends StatelessWidget {
  const _EmptyScheduleSummary();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final metrics = [
      (
        Icons.school_outlined,
        '0',
        _text(context, uz: 'Darslar', ru: 'Уроки', en: 'Lessons'),
      ),
      (
        Icons.timelapse_rounded,
        '0 min',
        _text(context, uz: 'Dars vaqti', ru: 'Учебное время', en: 'Teaching'),
      ),
      (
        Icons.meeting_room_outlined,
        '0',
        _text(context, uz: 'Xonalar', ru: 'Кабинеты', en: 'Rooms'),
      ),
    ];
    return SfSurfaceCard(
      key: const ValueKey('production-empty-schedule-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0)
              Container(
                width: 1,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: c.border,
              ),
            Expanded(
              child: Column(
                children: [
                  Icon(metrics[index].$1, size: 18, color: c.primary),
                  const SizedBox(height: 5),
                  Text(
                    metrics[index].$2,
                    style: SfType.mono(
                      size: 14,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metrics[index].$3,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 9.5, color: c.muted, height: 1.15),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleMotivationCard extends StatelessWidget {
  const _ScheduleMotivationCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      key: const ValueKey('production-schedule-motivation'),
      color: c.primarySoft,
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_awesome_rounded, color: c.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(
                    context,
                    uz: 'Bugungi eslatma',
                    ru: 'Мысль на сегодня',
                    en: 'A note for today',
                  ),
                  style: SfType.eyebrow(size: 9.5, color: c.primaryInk),
                ),
                const SizedBox(height: 5),
                Text(
                  _scheduleMotivation(context, index),
                  style: SfType.display(
                    size: 15,
                    weight: FontWeight.w700,
                    color: c.ink,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleNextSteps extends StatelessWidget {
  const _EmptyScheduleNextSteps({
    required this.onOpenTasks,
    required this.onOpenGroups,
  });

  final VoidCallback onOpenTasks;
  final VoidCallback onOpenGroups;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      key: const ValueKey('production-empty-schedule-actions'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(
              context,
              uz: 'Foydali keyingi qadamlar',
              ru: 'Полезные следующие шаги',
              en: 'Useful next steps',
            ),
            style: SfType.ui(size: 13.5, weight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 11),
          _EmptyScheduleAction(
            key: const ValueKey('production-empty-schedule-tasks'),
            icon: Icons.task_alt_rounded,
            title: _text(
              context,
              uz: 'Vazifalarni ko‘rib chiqing',
              ru: 'Проверьте задачи',
              en: 'Review your tasks',
            ),
            subtitle: _text(
              context,
              uz: 'Ustuvor ishlar va muddatlarni tekshiring.',
              ru: 'Проверьте приоритеты и ближайшие сроки.',
              en: 'Check priorities and upcoming due dates.',
            ),
            onTap: onOpenTasks,
          ),
          const SizedBox(height: 8),
          _EmptyScheduleAction(
            key: const ValueKey('production-empty-schedule-groups'),
            icon: Icons.groups_2_outlined,
            title: _text(
              context,
              uz: 'Guruhlarni tayyorlang',
              ru: 'Подготовьтесь к группам',
              en: 'Prepare for your groups',
            ),
            subtitle: _text(
              context,
              uz: 'Ro‘yxatlar, materiallar va keyingi mavzularni oching.',
              ru: 'Откройте списки, материалы и следующие темы.',
              en: 'Open rosters, materials, and upcoming topics.',
            ),
            onTap: onOpenGroups,
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleAction extends StatelessWidget {
  const _EmptyScheduleAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onTap,
      haptic: true,
      semanticLabel: title,
      borderRadius: BorderRadius.circular(17),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface3 : c.surface2,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: state.hovered ? c.borderStrong : c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: c.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SfType.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 10, color: c.muted, height: 1.25),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _EmptyScheduleFilterResult extends StatelessWidget {
  const _EmptyScheduleFilterResult({
    required this.status,
    required this.onClear,
  });

  final String status;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      key: const ValueKey('production-empty-schedule-filter'),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_rounded, color: c.muted, size: 31),
          const SizedBox(height: 9),
          Text(
            _text(
              context,
              uz: 'Bu holatda dars topilmadi',
              ru: 'Уроков с этим статусом нет',
              en: 'No lessons match this status',
            ),
            textAlign: TextAlign.center,
            style: SfType.ui(size: 14, weight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 4),
          Text(
            _lessonStatusLabel(context, status),
            style: SfType.ui(size: 11, color: c.muted),
          ),
          const SizedBox(height: 13),
          SfButton(
            kind: SfButtonKind.soft,
            leading: Icons.filter_alt_off_rounded,
            label: _text(
              context,
              uz: 'Barcha darslarni ko‘rsatish',
              ru: 'Показать все уроки',
              en: 'Show all lessons',
            ),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

String _scheduleMotivation(BuildContext context, int index) {
  final normalized = index % _scheduleMotivationCount;
  return switch (normalized) {
    0 => _text(
      context,
      uz: 'Bo‘sh jadval — yaxshi darsga puxta tayyorgarlik uchun joy.',
      ru: 'Свободное расписание — это время для спокойной подготовки к сильному уроку.',
      en: 'An open calendar leaves room to prepare a truly thoughtful lesson.',
    ),
    1 => _text(
      context,
      uz: 'Bugungi kichik tayyorgarlik ertangi katta natijani yaratadi.',
      ru: 'Небольшая подготовка сегодня создаёт большой результат завтра.',
      en: 'A small bit of preparation today can shape a great result tomorrow.',
    ),
    2 => _text(
      context,
      uz: 'Sokin kunlar ham ustozlik yo‘lining muhim qismidir.',
      ru: 'Спокойные дни — тоже важная часть пути учителя.',
      en: 'Quiet days are an important part of a teacher’s rhythm too.',
    ),
    3 => _text(
      context,
      uz: 'Bir yaxshi g‘oya keyingi darsni unutilmas qilishi mumkin.',
      ru: 'Одна хорошая идея может сделать следующий урок незабываемым.',
      en: 'One good idea can make the next lesson unforgettable.',
    ),
    _ => _text(
      context,
      uz: 'Dam olish ham, rejalash ham yaxshi ishning bir qismidir.',
      ru: 'Отдых и планирование — такие же части хорошей работы.',
      en: 'Rest and planning both belong in a day of meaningful work.',
    ),
  };
}

class _ProductionLessonCard extends StatelessWidget {
  const _ProductionLessonCard({
    required this.lesson,
    this.prominent = false,
    this.expanded = false,
    this.onTap,
  });

  final BackendLesson lesson;
  final bool prominent;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _lessonStatusColor(context, lesson.status);
    final showDetails = prominent || expanded;
    final start = lesson.startsAt?.toLocal();
    final end = lesson.endsAt?.toLocal();
    return SfPressable(
      key: ValueKey('production-lesson-${lesson.id}'),
      onPressed: onTap ?? () => _showLessonDetails(context, lesson),
      haptic: true,
      borderRadius: BorderRadius.circular(21),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.standard),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: showDetails ? tone.withValues(alpha: .075) : c.surface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: showDetails ? tone.withValues(alpha: .55) : c.border,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        start == null ? '—' : _time(start),
                        style: SfType.mono(
                          size: 11,
                          weight: FontWeight.w800,
                          color: tone,
                        ),
                      ),
                      if (end != null)
                        Text(
                          _time(end),
                          style: SfType.mono(size: 8.5, color: c.muted),
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
                        lesson.title.isEmpty
                            ? lesson.lessonTypeName
                            : lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(
                          size: 14.5,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lesson.cohortName.isEmpty
                            ? _text(
                                context,
                                uz: 'Guruh ko‘rsatilmagan',
                                ru: 'Группа не указана',
                                en: 'No group assigned',
                              )
                            : lesson.cohortName,
                        style: SfType.ui(size: 11, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SfPill(
                  label: _lessonStatusLabel(context, lesson.status),
                  tone: _lessonPillTone(lesson.status),
                ),
              ],
            ),
            AnimatedSize(
              duration: SfMotion.resolve(context, SfMotion.emphasized),
              child: showDetails
                  ? Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: Column(
                        children: [
                          Divider(height: 1, color: c.border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LessonDatum(
                                  icon: Icons.meeting_room_outlined,
                                  label: lesson.roomName ?? '—',
                                ),
                              ),
                              Expanded(
                                child: _LessonDatum(
                                  icon: Icons.layers_outlined,
                                  label: lesson.lessonTypeName.isEmpty
                                      ? '—'
                                      : lesson.lessonTypeName,
                                ),
                              ),
                              Expanded(
                                child: _LessonDatum(
                                  icon: Icons.person_outline_rounded,
                                  label: lesson.teacherName.isEmpty
                                      ? '—'
                                      : lesson.teacherName,
                                ),
                              ),
                            ],
                          ),
                          if (lesson.cohortId != null &&
                              lesson.status != 'cancelled') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: SfButton(
                                    kind: SfButtonKind.ghost,
                                    label: _text(
                                      context,
                                      uz: 'Guruh',
                                      ru: 'Группа',
                                      en: 'Group',
                                    ),
                                    onPressed: () => context.push(
                                      '/cohort?id=${lesson.cohortId}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SfButton(
                                    label: _text(
                                      context,
                                      uz: 'Davomat',
                                      ru: 'Посещаемость',
                                      en: 'Attendance',
                                    ),
                                    leading: Icons.fact_check_outlined,
                                    onPressed: () => context.push(
                                      _attendanceLocation(lesson),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _LessonDatum extends StatelessWidget {
  const _LessonDatum({required this.icon, required this.label});

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: SfType.ui(size: 9.5, weight: FontWeight.w700, color: c.ink2),
        ),
      ],
    );
  }
}

class _ProductionScheduleControls extends StatelessWidget {
  const _ProductionScheduleControls({
    required this.selectedDate,
    required this.view,
    required this.onPrevious,
    required this.onNext,
    required this.onViewChanged,
  });

  final DateTime selectedDate;
  final ProductionScheduleView view;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<ProductionScheduleView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _SquareAction(
                icon: Icons.chevron_left_rounded,
                label: _text(
                  context,
                  uz: 'Oldingi davr',
                  ru: 'Предыдущий период',
                  en: 'Previous period',
                ),
                onTap: onPrevious,
              ),
              Expanded(
                child: Text(
                  view == ProductionScheduleView.month
                      ? _monthYear(context, selectedDate)
                      : _longDate(context, selectedDate),
                  textAlign: TextAlign.center,
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              _SquareAction(
                icon: Icons.chevron_right_rounded,
                label: _text(
                  context,
                  uz: 'Keyingi davr',
                  ru: 'Следующий период',
                  en: 'Next period',
                ),
                onTap: onNext,
              ),
            ],
          ),
          const SizedBox(height: 9),
          SegmentedButton<ProductionScheduleView>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ProductionScheduleView.day,
                label: Text(_text(context, uz: 'Kun', ru: 'День', en: 'Day')),
              ),
              ButtonSegment(
                value: ProductionScheduleView.week,
                label: Text(
                  _text(context, uz: 'Hafta', ru: 'Неделя', en: 'Week'),
                ),
              ),
              ButtonSegment(
                value: ProductionScheduleView.month,
                label: Text(_text(context, uz: 'Oy', ru: 'Месяц', en: 'Month')),
              ),
            ],
            selected: {view},
            onSelectionChanged: (values) => onViewChanged(values.first),
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
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

class _ScheduleWeekStrip extends StatelessWidget {
  const _ScheduleWeekStrip({
    required this.selected,
    required this.lessons,
    required this.onSelected,
  });

  final DateTime selected;
  final List<BackendLesson> lessons;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(
      selected.subtract(Duration(days: selected.weekday - 1)),
    );
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Row(
      children: [
        for (var index = 0; index < 7; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(
            child: Builder(
              builder: (context) {
                final date = start.add(Duration(days: index));
                final active = DateUtils.isSameDay(date, selected);
                final count = lessons.where((lesson) {
                  final at = lesson.startsAt?.toLocal();
                  return at != null && DateUtils.isSameDay(at, date);
                }).length;
                return SfPressable(
                  key: ValueKey(
                    'production-schedule-date-${date.toIso8601String()}',
                  ),
                  selected: active,
                  onPressed: () => onSelected(date),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: SfMotion.resolve(context, SfMotion.quick),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? c.primary : c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: active ? c.primary : c.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weekdayShort(context, date.weekday),
                          style: SfType.eyebrow(
                            size: 7,
                            color: active ? onPrimary : c.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: SfType.mono(
                            size: 14,
                            weight: FontWeight.w800,
                            color: active ? onPrimary : c.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$count',
                          style: SfType.mono(
                            size: 8,
                            color: active ? c.accent : c.primary,
                          ),
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

class _ScheduleMonthCalendar extends StatelessWidget {
  const _ScheduleMonthCalendar({
    required this.selected,
    required this.lessons,
    required this.onSelected,
  });

  final DateTime selected;
  final List<BackendLesson> lessons;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final monthStart = DateTime(selected.year, selected.month);
    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - DateTime.monday),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final lessonCounts = <String, int>{};
    for (final lesson in lessons) {
      final date = lesson.startsAt?.toLocal();
      if (date == null) continue;
      final key = _dateKey(date);
      lessonCounts[key] = (lessonCounts[key] ?? 0) + 1;
    }

    return SfSurfaceCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                Expanded(
                  child: Text(
                    _weekdayShort(context, weekday),
                    textAlign: TextAlign.center,
                    style: SfType.eyebrow(size: 7.5, color: c.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < 6; row++) ...[
            if (row > 0) const SizedBox(height: 4),
            Row(
              children: [
                for (var column = 0; column < 7; column++) ...[
                  if (column > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final date = gridStart.add(
                          Duration(days: row * 7 + column),
                        );
                        final active = DateUtils.isSameDay(date, selected);
                        final isToday = DateUtils.isSameDay(date, today);
                        final inMonth = date.month == selected.month;
                        final count = lessonCounts[_dateKey(date)] ?? 0;
                        return SfPressable(
                          key: ValueKey(
                            'production-month-date-${_dateKey(date)}',
                          ),
                          selected: active,
                          semanticLabel:
                              '${_longDate(context, date)}, $count ${_text(context, uz: 'dars', ru: 'уроков', en: 'lessons')}',
                          onPressed: () => onSelected(date),
                          borderRadius: BorderRadius.circular(13),
                          child: AnimatedContainer(
                            duration: SfMotion.resolve(context, SfMotion.quick),
                            height: 52,
                            decoration: BoxDecoration(
                              color: active
                                  ? c.primary
                                  : isToday
                                  ? c.primarySoft.withValues(alpha: .62)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: active
                                    ? c.primary
                                    : isToday
                                    ? c.primary.withValues(alpha: .5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: SfType.mono(
                                    size: 13,
                                    weight: active || isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: active
                                        ? onPrimary
                                        : inMonth
                                        ? c.ink
                                        : c.muted2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (count > 0)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 15,
                                    ),
                                    height: 14,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? onPrimary.withValues(alpha: .2)
                                          : c.primarySoft,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$count',
                                      style: SfType.mono(
                                        size: 7.5,
                                        weight: FontWeight.w800,
                                        color: active ? onPrimary : c.primary,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 14),
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
          ],
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 7.0;
      final itemWidth = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final value in const [
            'all',
            'scheduled',
            'completed',
            'cancelled',
          ])
            SizedBox(
              width: itemWidth,
              child: ChoiceChip(
                key: ValueKey('production-schedule-filter-$value'),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
                visualDensity: const VisualDensity(vertical: -1),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '${value == 'all' ? _text(context, uz: 'Hammasi', ru: 'Все', en: 'All') : _lessonStatusLabel(context, value)}  ${counts[value] ?? 0}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: SfType.ui(
                      size: 11,
                      weight: selected == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ProductionCohortCard extends StatelessWidget {
  const _ProductionCohortCard({required this.cohort, required this.onTap});

  final BackendCohort cohort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return SfPressable(
      key: ValueKey('production-cohort-${cohort.id}'),
      onPressed: onTap,
      haptic: true,
      borderRadius: BorderRadius.circular(22),
      builder: (context, state, _) => AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: state.pressed ? c.surface2 : c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: state.hovered ? c.borderStrong : c.border),
          boxShadow: [
            BoxShadow(
              color: c.ink.withValues(alpha: state.pressed ? .02 : .05),
              blurRadius: state.pressed ? 4 : 16,
              offset: Offset(0, state.pressed ? 2 : 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.primary, c.primaryHover],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cohort.name.isEmpty
                        ? 'G'
                        : cohort.name.substring(0, 1).toUpperCase(),
                    style: SfType.display(size: 21, color: onPrimary),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cohort.name.isEmpty
                            ? _text(
                                context,
                                uz: 'Nomsiz guruh',
                                ru: 'Группа без имени',
                                en: 'Unnamed group',
                              )
                            : cohort.name,
                        style: SfType.ui(
                          size: 16,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          cohort.level,
                          cohort.departmentName,
                        ].where((value) => value.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(size: 11, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Icon(SfIcons.chevR, size: 20, color: c.muted),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _InfoChip(
                  icon: Icons.person_outline_rounded,
                  label: cohort.primaryTeacherName.isEmpty
                      ? _text(
                          context,
                          uz: 'O‘qituvchi belgilanmagan',
                          ru: 'Учитель не указан',
                          en: 'No teacher assigned',
                        )
                      : cohort.primaryTeacherName,
                ),
                _InfoChip(
                  icon: Icons.meeting_room_outlined,
                  label: cohort.defaultRoomName.isEmpty
                      ? '—'
                      : cohort.defaultRoomName,
                ),
                _InfoChip(
                  icon: Icons.groups_outlined,
                  label: _text(
                    context,
                    uz: '${cohort.capacity} o‘rin',
                    ru: '${cohort.capacity} мест',
                    en: '${cohort.capacity} seats',
                  ),
                ),
                if (cohort.isArchived)
                  _InfoChip(
                    icon: Icons.archive_outlined,
                    label: _text(
                      context,
                      uz: 'Arxiv',
                      ru: 'Архив',
                      en: 'Archived',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c.primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(
                size: 10,
                weight: FontWeight.w600,
                color: c.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductionCohortHero extends StatelessWidget {
  const _ProductionCohortHero({
    required this.cohort,
    required this.members,
    required this.attendance,
    required this.onAttendance,
  });

  final BackendCohort cohort;
  final int members;
  final double? attendance;
  final VoidCallback onAttendance;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primary, c.primaryHover],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: .23),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cohort.level.isEmpty
                          ? cohort.departmentName
                          : cohort.level,
                      style: SfType.eyebrow(
                        color: onPrimary.withValues(alpha: .78),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      cohort.name,
                      style: SfType.ui(
                        size: 22,
                        weight: FontWeight.w800,
                        color: onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SfPill(
                label: cohort.isArchived
                    ? _text(context, uz: 'Arxiv', ru: 'Архив', en: 'Archived')
                    : _text(context, uz: 'Faol', ru: 'Активна', en: 'Active'),
                tone: cohort.isArchived
                    ? SfPillTone.neutral
                    : SfPillTone.success,
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              _HeroMetric(
                value: '$members',
                label: _text(
                  context,
                  uz: 'o‘quvchi',
                  ru: 'учеников',
                  en: 'students',
                ),
              ),
              _HeroMetric(
                value: attendance == null ? '—' : '${attendance!.round()}%',
                label: _text(
                  context,
                  uz: 'davomat',
                  ru: 'посещаемость',
                  en: 'attendance',
                ),
              ),
              _HeroMetric(
                value: cohort.defaultRoomName.isEmpty
                    ? '—'
                    : cohort.defaultRoomName,
                label: _text(context, uz: 'xona', ru: 'кабинет', en: 'room'),
              ),
            ],
          ),
          if (!cohort.isArchived) ...[
            const SizedBox(height: 16),
            SfButton(
              block: true,
              kind: SfButtonKind.soft,
              label: _text(
                context,
                uz: 'Davomat olish',
                ru: 'Отметить посещаемость',
                en: 'Take attendance',
              ),
              leading: Icons.fact_check_outlined,
              onPressed: onAttendance,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SfType.mono(
              size: 18,
              weight: FontWeight.w800,
              color: onPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SfType.ui(
              size: 9.5,
              color: onPrimary.withValues(alpha: .74),
            ),
          ),
        ],
      ),
    );
  }
}

class _CohortTabs extends StatelessWidget {
  const _CohortTabs({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = [
      _text(context, uz: 'Umumiy', ru: 'Обзор', en: 'Overview'),
      _text(context, uz: 'O‘quvchilar', ru: 'Ученики', en: 'Students'),
      _text(context, uz: 'Davomat', ru: 'Посещаемость', en: 'Attendance'),
      _text(context, uz: 'Jadval', ru: 'Расписание', en: 'Schedule'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => ChoiceChip(
          key: ValueKey('production-cohort-tab-$index'),
          selected: selected == index,
          onSelected: (_) => onSelected(index),
          label: Text(labels[index]),
        ),
      ),
    );
  }
}

class _CohortOverview extends StatelessWidget {
  const _CohortOverview({super.key, required this.cohort, required this.state});

  final BackendCohort cohort;
  final CohortLearningState state;

  @override
  Widget build(BuildContext context) {
    final members = state.members.value?.length;
    final lessons = state.lessons.value?.length;
    final attendance = state.attendance.value?.rate;
    final now = DateTime.now();
    final upcoming = [...?state.lessons.value]
      ..removeWhere(
        (lesson) =>
            lesson.status == 'cancelled' ||
            lesson.startsAt == null ||
            lesson.startsAt!.toLocal().isBefore(now),
      )
      ..sort((a, b) => _lessonTime(a).compareTo(_lessonTime(b)));
    final nextLesson = upcoming.firstOrNull;
    final data = [
      (
        Icons.groups_outlined,
        members == null ? '—' : '$members',
        _text(
          context,
          uz: 'Faol o‘quvchi',
          ru: 'Активные ученики',
          en: 'Active students',
        ),
      ),
      (
        Icons.event_note_outlined,
        lessons == null ? '—' : '$lessons',
        _text(
          context,
          uz: 'Davrdagi dars',
          ru: 'Уроки за период',
          en: 'Lessons in range',
        ),
      ),
      (
        Icons.insights_outlined,
        attendance == null ? '—' : '${attendance.round()}%',
        _text(context, uz: 'Davomat', ru: 'Посещаемость', en: 'Attendance'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 0; index < data.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetric(
                  icon: data[index].$1,
                  value: data[index].$2,
                  label: data[index].$3,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 13),
        if (nextLesson != null) ...[
          _SectionLabel(
            title: _text(
              context,
              uz: 'Keyingi dars',
              ru: 'Следующий урок',
              en: 'Next lesson',
            ),
            subtitle: _shortDate(context, nextLesson.startsAt),
          ),
          const SizedBox(height: 9),
          _ProductionLessonCard(lesson: nextLesson, prominent: true),
          const SizedBox(height: 13),
        ],
        SfSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _DetailLine(
                icon: Icons.apartment_outlined,
                label: _text(context, uz: 'Filial', ru: 'Филиал', en: 'Branch'),
                value: cohort.branchName,
              ),
              _DetailLine(
                icon: Icons.account_tree_outlined,
                label: _text(
                  context,
                  uz: 'Bo‘lim',
                  ru: 'Отдел',
                  en: 'Department',
                ),
                value: cohort.departmentName,
              ),
              _DetailLine(
                icon: Icons.person_outline_rounded,
                label: _text(
                  context,
                  uz: 'Asosiy o‘qituvchi',
                  ru: 'Основной учитель',
                  en: 'Primary teacher',
                ),
                value: cohort.primaryTeacherName,
              ),
              _DetailLine(
                icon: Icons.meeting_room_outlined,
                label: _text(
                  context,
                  uz: 'Asosiy xona',
                  ru: 'Основной кабинет',
                  en: 'Default room',
                ),
                value: cohort.defaultRoomName,
                last: true,
              ),
            ],
          ),
        ),
        if (state.attendance.isUnavailable || state.attendance.isFailure) ...[
          const SizedBox(height: 12),
          _InlineModuleState(
            resource: state.attendance,
            title: _text(
              context,
              uz: 'Davomat tahlili mavjud emas',
              ru: 'Аналитика посещаемости недоступна',
              en: 'Attendance analytics unavailable',
            ),
          ),
        ],
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: c.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: SfType.mono(size: 18, weight: FontWeight.w800, color: c.ink),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SfType.ui(size: 8.5, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: SfType.ui(size: 11, color: c.muted)),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              style: SfType.ui(
                size: 11.5,
                weight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CohortMembers extends StatelessWidget {
  const _CohortMembers({
    super.key,
    required this.resource,
    required this.search,
    required this.onSearchChanged,
  });

  final LearningResource<List<BackendCohortMember>> resource;
  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final blocking = _blockingState(
      context,
      resource,
      unavailableTitle: _text(
        context,
        uz: 'O‘quvchilar moduli mavjud emas',
        ru: 'Модуль учеников недоступен',
        en: 'Student roster unavailable',
      ),
    );
    if (blocking != null) return SizedBox(height: 340, child: blocking);
    final query = search.text.trim().toLowerCase();
    final members = (resource.value ?? const <BackendCohortMember>[])
        .where(
          (member) =>
              query.isEmpty || member.studentName.toLowerCase().contains(query),
        )
        .toList();
    return Column(
      children: [
        TextField(
          key: const ValueKey('production-member-search'),
          controller: search,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: _text(
              context,
              uz: 'O‘quvchini qidiring',
              ru: 'Найти ученика',
              en: 'Search students',
            ),
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          SfEmptyState(
            compact: true,
            title: _text(
              context,
              uz: 'O‘quvchi topilmadi',
              ru: 'Ученик не найден',
              en: 'No student found',
            ),
          )
        else
          for (var index = 0; index < members.length; index++) ...[
            SfSurfaceCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SfAvatar(name: members[index].studentName, size: 40),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          members[index].studentName,
                          style: SfType.ui(
                            size: 13,
                            weight: FontWeight.w700,
                            color: SfTheme.colorsOf(context).ink,
                          ),
                        ),
                        Text(
                          '#${members[index].studentId}',
                          style: SfType.mono(
                            size: 9.5,
                            color: SfTheme.colorsOf(context).muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (members[index].endDate != null)
                    SfPill(
                      label: _text(
                        context,
                        uz: 'Yakunlangan',
                        ru: 'Завершён',
                        en: 'Ended',
                      ),
                    ),
                ],
              ),
            ),
            if (index != members.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _CohortAttendance extends StatelessWidget {
  const _CohortAttendance({
    super.key,
    required this.state,
    required this.preset,
    required this.onPresetChanged,
    required this.status,
    required this.onStatusChanged,
    required this.lessonId,
    required this.onLessonChanged,
    required this.onTakeAttendance,
  });

  final CohortLearningState state;
  final _AttendanceRangePreset preset;
  final ValueChanged<_AttendanceRangePreset> onPresetChanged;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final int? lessonId;
  final ValueChanged<int?> onLessonChanged;
  final VoidCallback onTakeAttendance;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.attendance.value;
    final history = state.history.value ?? const <BackendAttendanceRecord>[];
    final activeRange = state.range;
    final lessons = (state.lessons.value ?? const <BackendLesson>[]).where((
      lesson,
    ) {
      final at = lesson.startsAt?.toLocal();
      if (at == null || activeRange == null) return true;
      return !at.isBefore(activeRange.from) && !at.isAfter(activeRange.to);
    }).toList();
    final filtered = history.where((record) {
      if (status != 'all' && record.status != status) return false;
      if (lessonId != null && record.lessonId != lessonId) return false;
      return true;
    }).toList()..sort((a, b) => _recordTime(b).compareTo(_recordTime(a)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final value in _AttendanceRangePreset.values)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    selected: preset == value,
                    onSelected: (_) => onPresetChanged(value),
                    label: Text(_rangeLabel(context, value)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (dashboard != null)
          _AttendanceDashboardCard(dashboard: dashboard)
        else if (state.attendance.isUnavailable || state.attendance.isFailure)
          _InlineModuleState(
            resource: state.attendance,
            title: _text(
              context,
              uz: 'Davomat ko‘rsatkichlari mavjud emas',
              ru: 'Показатели посещаемости недоступны',
              en: 'Attendance metrics unavailable',
            ),
          )
        else
          SfLoadingState(
            compact: true,
            label: _text(
              context,
              uz: 'Davomat hisoblanmoqda…',
              ru: 'Расчёт посещаемости…',
              en: 'Calculating attendance…',
            ),
          ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final lessonField = DropdownButtonFormField<int?>(
              initialValue: lessons.any((lesson) => lesson.id == lessonId)
                  ? lessonId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _text(context, uz: 'Dars', ru: 'Урок', en: 'Lesson'),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    _text(context, uz: 'Hammasi', ru: 'Все', en: 'All lessons'),
                  ),
                ),
                for (final lesson in lessons)
                  DropdownMenuItem<int?>(
                    value: lesson.id,
                    child: Text(
                      lesson.title.isEmpty
                          ? lesson.lessonTypeName
                          : lesson.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onLessonChanged,
            );
            final statusField = DropdownButtonFormField<String>(
              initialValue: status,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _text(
                  context,
                  uz: 'Holat',
                  ru: 'Статус',
                  en: 'Status',
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    _text(
                      context,
                      uz: 'Hammasi',
                      ru: 'Все',
                      en: 'All statuses',
                    ),
                  ),
                ),
                for (final value in ['present', 'absent', 'late', 'excused'])
                  DropdownMenuItem(
                    value: value,
                    child: Text(_attendanceStatusLabel(context, value)),
                  ),
              ],
              onChanged: (value) => onStatusChanged(value ?? 'all'),
            );
            if (constraints.maxWidth < 520) {
              return Column(
                children: [lessonField, const SizedBox(height: 9), statusField],
              );
            }
            return Row(
              children: [
                Expanded(child: lessonField),
                const SizedBox(width: 9),
                Expanded(child: statusField),
              ],
            );
          },
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = _SectionLabel(
              title: _text(
                context,
                uz: 'Davomat tarixi',
                ru: 'История посещаемости',
                en: 'Attendance history',
              ),
              subtitle: _text(
                context,
                uz: '${filtered.length} ta yozuv',
                ru: '${filtered.length} записей',
                en: '${filtered.length} records',
              ),
            );
            final action = SfButton(
              label: _text(
                context,
                uz: 'Belgilash',
                ru: 'Отметить',
                en: 'Take attendance',
              ),
              leading: Icons.fact_check_outlined,
              onPressed: onTakeAttendance,
            );
            if (constraints.maxWidth < 380) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 9), action],
              );
            }
            return Row(
              children: [
                Expanded(child: heading),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        if (state.history.isUnavailable || state.history.isFailure)
          _InlineModuleState(
            resource: state.history,
            title: _text(
              context,
              uz: 'Davomat tarixi mavjud emas',
              ru: 'История недоступна',
              en: 'Attendance history unavailable',
            ),
          )
        else if (filtered.isEmpty)
          SfEmptyState(
            compact: true,
            title: _text(
              context,
              uz: 'Bu filtrda yozuv yo‘q',
              ru: 'По фильтру записей нет',
              en: 'No records match these filters',
            ),
          )
        else
          _AttendanceHistoryTable(records: filtered),
      ],
    );
  }
}

class _AttendanceDashboardCard extends StatelessWidget {
  const _AttendanceDashboardCard({required this.dashboard});

  final BackendAttendanceDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final sorted = [...dashboard.students]
      ..sort((a, b) => a.percentPresent.compareTo(b.percentPresent));
    final totals = [
      (
        status: 'present',
        value: dashboard.students.fold<int>(
          0,
          (sum, student) => sum + student.present,
        ),
      ),
      (
        status: 'absent',
        value: dashboard.students.fold<int>(
          0,
          (sum, student) => sum + student.absent,
        ),
      ),
      (
        status: 'late',
        value: dashboard.students.fold<int>(
          0,
          (sum, student) => sum + student.late,
        ),
      ),
      (
        status: 'excused',
        value: dashboard.students.fold<int>(
          0,
          (sum, student) => sum + student.excused,
        ),
      ),
    ];
    return SfSurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _rateColor(
                    context,
                    dashboard.rate,
                  ).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${dashboard.rate.round()}%',
                  style: SfType.mono(
                    size: 13,
                    weight: FontWeight.w800,
                    color: _rateColor(context, dashboard.rate),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        context,
                        uz: 'Guruh davomati',
                        ru: 'Посещаемость группы',
                        en: 'Group attendance',
                      ),
                      style: SfType.ui(
                        size: 14,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      _text(
                        context,
                        uz: '${dashboard.students.length} o‘quvchi bo‘yicha hisob',
                        ru: 'Расчёт по ${dashboard.students.length} ученикам',
                        en: 'Calculated across ${dashboard.students.length} students',
                      ),
                      style: SfType.ui(size: 10.5, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 7.0;
              final columns = constraints.maxWidth < 520 ? 2 : 4;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final total in totals)
                    SizedBox(
                      width: width,
                      child: _AttendanceTotalTile(
                        status: total.status,
                        value: total.value,
                      ),
                    ),
                ],
              );
            },
          ),
          if (sorted.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _text(
                context,
                uz: 'E’tibor talab qiladiganlar',
                ru: 'Требуют внимания',
                en: 'Needs attention',
              ),
              style: SfType.eyebrow(color: c.muted),
            ),
            const SizedBox(height: 8),
            for (final student in sorted.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: c.ink2,
                        ),
                      ),
                    ),
                    Text(
                      '${student.percentPresent.round()}%',
                      style: SfType.mono(
                        size: 11,
                        weight: FontWeight.w800,
                        color: _rateColor(context, student.percentPresent),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceTotalTile extends StatelessWidget {
  const _AttendanceTotalTile({required this.status, required this.value});

  final String status;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _attendanceStatusColor(context, status);
    final icon = switch (status) {
      'present' => Icons.check_circle_outline_rounded,
      'absent' => Icons.cancel_outlined,
      'late' => Icons.schedule_rounded,
      'excused' => Icons.verified_user_outlined,
      _ => Icons.circle_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .085),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: tone),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: SfType.mono(
                    size: 14,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(
                  _attendanceStatusLabel(context, status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(size: 8.5, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryTable extends StatelessWidget {
  const _AttendanceHistoryTable({required this.records});

  final List<BackendAttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final visible = records.take(80).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 680) {
          final c = SfTheme.colorsOf(context);
          return SfSurfaceCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(c.surface2),
                  horizontalMargin: 16,
                  columnSpacing: 28,
                  columns: [
                    DataColumn(
                      label: Text(
                        _text(
                          context,
                          uz: 'O‘quvchi',
                          ru: 'Ученик',
                          en: 'Student',
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        _text(context, uz: 'Dars', ru: 'Урок', en: 'Lesson'),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        _text(context, uz: 'Sana', ru: 'Дата', en: 'Date'),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        _text(context, uz: 'Holat', ru: 'Статус', en: 'Status'),
                      ),
                    ),
                  ],
                  rows: [
                    for (final record in visible)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                record.studentName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                record.lessonTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              _shortDate(
                                context,
                                record.lessonStartsAt ?? record.markedAt,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              _attendanceStatusLabel(context, record.status),
                              style: SfType.ui(
                                size: 11,
                                weight: FontWeight.w700,
                                color: _attendanceStatusColor(
                                  context,
                                  record.status,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              _AttendanceHistoryRecordCard(record: visible[index]),
              if (index != visible.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _AttendanceHistoryRecordCard extends StatelessWidget {
  const _AttendanceHistoryRecordCard({required this.record});

  final BackendAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _attendanceStatusColor(context, record.status);
    final at = record.lessonStartsAt ?? record.markedAt ?? record.createdAt;
    final icon = switch (record.status) {
      'present' => Icons.check_rounded,
      'absent' => Icons.close_rounded,
      'late' => Icons.schedule_rounded,
      'excused' => Icons.verified_user_outlined,
      _ => Icons.question_mark_rounded,
    };
    return Container(
      key: ValueKey('production-attendance-history-${record.id}'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: tone),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        _attendanceStatusLabel(context, record.status),
                        style: SfType.ui(
                          size: 8.5,
                          weight: FontWeight.w800,
                          color: tone,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  record.lessonTitle.isEmpty
                      ? _text(
                          context,
                          uz: 'Dars #${record.lessonId}',
                          ru: 'Урок #${record.lessonId}',
                          en: 'Lesson #${record.lessonId}',
                        )
                      : record.lessonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(size: 10.5, color: c.ink2),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _HistoryMeta(
                      icon: Icons.calendar_today_outlined,
                      label: _shortDate(context, at),
                    ),
                    if (at != null)
                      _HistoryMeta(
                        icon: Icons.schedule_rounded,
                        label: _time(at.toLocal()),
                      ),
                    if (record.autoMarked)
                      _HistoryMeta(
                        icon: Icons.auto_awesome_rounded,
                        label: _text(
                          context,
                          uz: 'Avtomatik',
                          ru: 'Автоматически',
                          en: 'Automatic',
                        ),
                      ),
                  ],
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    record.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 9.5, color: c.muted, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMeta extends StatelessWidget {
  const _HistoryMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c.muted),
        const SizedBox(width: 4),
        Text(label, style: SfType.ui(size: 8.5, color: c.muted)),
      ],
    );
  }
}

class _CohortSchedule extends StatelessWidget {
  const _CohortSchedule({super.key, required this.resource});

  final LearningResource<List<BackendLesson>> resource;

  @override
  Widget build(BuildContext context) {
    final blocking = _blockingState(
      context,
      resource,
      unavailableTitle: _text(
        context,
        uz: 'Jadval moduli mavjud emas',
        ru: 'Модуль расписания недоступен',
        en: 'Schedule module unavailable',
      ),
    );
    if (blocking != null) return SizedBox(height: 340, child: blocking);
    final lessons = [...?resource.value]
      ..sort((a, b) => _lessonTime(b).compareTo(_lessonTime(a)));
    if (lessons.isEmpty) {
      return SfEmptyState(
        compact: true,
        title: _text(
          context,
          uz: 'Bu davrda dars yo‘q',
          ru: 'В этом периоде уроков нет',
          en: 'No lessons in this range',
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < lessons.length; index++) ...[
          _ProductionLessonCard(lesson: lessons[index]),
          if (index != lessons.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _AttendanceLessonPicker extends StatelessWidget {
  const _AttendanceLessonPicker({
    required this.lessons,
    required this.selected,
    required this.onSelected,
  });

  final List<BackendLesson> lessons;
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final selectedExists =
        selected == null || lessons.any((lesson) => lesson.id == selected);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined, size: 20, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _text(
                    context,
                    uz: 'Darsni tanlang',
                    ru: 'Выберите урок',
                    en: 'Select lesson',
                  ),
                  style: SfType.ui(
                    size: 13,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            key: const ValueKey('production-attendance-lesson-picker'),
            initialValue: selectedExists ? selected : null,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: _text(
                context,
                uz: 'Aniq dars va vaqt',
                ru: 'Конкретный урок и время',
                en: 'Exact lesson and time',
              ),
            ),
            items: [
              for (final lesson in lessons)
                DropdownMenuItem<int?>(
                  value: lesson.id,
                  child: Text(
                    '${_shortDate(context, lesson.startsAt)} · ${lesson.startsAt == null ? '—' : _time(lesson.startsAt!.toLocal())} · ${lesson.title.isEmpty ? lesson.lessonTypeName : lesson.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onSelected,
          ),
          if (selected != null && !selectedExists) ...[
            const SizedBox(height: 8),
            Text(
              _text(
                context,
                uz: 'Havoladagi dars alohida tekshirilmoqda.',
                ru: 'Урок из ссылки проверяется отдельно.',
                en: 'The linked lesson is being verified separately.',
              ),
              style: SfType.ui(size: 10.5, color: c.warn),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttendanceProgress extends StatelessWidget {
  const _AttendanceProgress({
    required this.members,
    required this.statuses,
    required this.onMarkRemaining,
  });

  final List<BackendCohortMember> members;
  final Map<int, AttendanceStatus> statuses;
  final VoidCallback onMarkRemaining;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final total = members.length;
    final marked = members
        .where((member) => statuses.containsKey(member.studentId))
        .length;
    final progress = total == 0 ? 0.0 : marked / total;
    return SfSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _text(
                    context,
                    uz: '$marked / $total belgilandi',
                    ru: 'Отмечено $marked из $total',
                    en: '$marked of $total marked',
                  ),
                  style: SfType.ui(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: marked == total ? null : onMarkRemaining,
                icon: const Icon(Icons.done_all_rounded, size: 17),
                label: Text(
                  _text(
                    context,
                    uz: 'Qolganlari keldi',
                    ru: 'Остальные пришли',
                    en: 'Mark rest present',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            color: progress == 1 ? c.success : c.primary,
            backgroundColor: c.surface3,
          ),
        ],
      ),
    );
  }
}

class _AttendanceMemberRow extends StatelessWidget {
  const _AttendanceMemberRow({
    required this.member,
    required this.status,
    required this.note,
    required this.onSelected,
    required this.cardGiven,
    required this.onGiveCard,
  });

  final BackendCohortMember member;
  final AttendanceStatus? status;
  final String? note;
  final ValueChanged<AttendanceStatus> onSelected;
  final bool cardGiven;
  final VoidCallback onGiveCard;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = status == null
        ? c.primary
        : _attendanceEnumColor(context, status!);
    return AnimatedContainer(
      duration: SfMotion.resolve(context, SfMotion.standard),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: status == null ? c.surface : tone.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == null ? c.border : tone.withValues(alpha: .28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SfAvatar(name: member.studentName, size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 13.5,
                        weight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note?.isNotEmpty == true
                          ? note!
                          : _text(
                              context,
                              uz: 'Davomat holatini tanlang',
                              ru: 'Выберите статус посещаемости',
                              en: 'Choose attendance status',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SfType.ui(
                        size: 9.5,
                        color: note?.isNotEmpty == true ? tone : c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: _text(
                  context,
                  uz: 'Dars kartasini berish',
                  ru: 'Выдать карточку на уроке',
                  en: 'Give lesson card',
                ),
                child: SfPressable(
                  key: ValueKey('production-give-card-${member.studentId}'),
                  onPressed: onGiveCard,
                  haptic: true,
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: SfMotion.resolve(context, SfMotion.quick),
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cardGiven ? c.successSoft : c.primarySoft,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: (cardGiven ? c.success : c.primary).withValues(
                          alpha: .28,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: SfMotion.resolve(context, SfMotion.quick),
                          child: Icon(
                            cardGiven
                                ? Icons.check_circle_rounded
                                : Icons.auto_awesome_rounded,
                            key: ValueKey(cardGiven),
                            size: 17,
                            color: cardGiven ? c.success : c.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _text(context, uz: 'Karta', ru: 'Карта', en: 'Card'),
                          style: SfType.ui(
                            size: 10,
                            weight: FontWeight.w800,
                            color: cardGiven ? c.success : c.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 6.0;
              final columns = constraints.maxWidth < 300 ? 2 : 4;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final value in AttendanceStatus.values)
                    SizedBox(
                      width: width,
                      child: _AttendanceStatusButton(
                        value: value,
                        selected: status == value,
                        onPressed: () => onSelected(value),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatusButton extends StatelessWidget {
  const _AttendanceStatusButton({
    required this.value,
    required this.selected,
    required this.onPressed,
  });

  final AttendanceStatus value;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final tone = _attendanceEnumColor(context, value);
    final icon = switch (value) {
      AttendanceStatus.present => Icons.check_circle_outline_rounded,
      AttendanceStatus.absent => Icons.cancel_outlined,
      AttendanceStatus.late => Icons.schedule_rounded,
      AttendanceStatus.excused => Icons.verified_user_outlined,
    };
    return SfPressable(
      selected: selected,
      semanticLabel: _attendanceEnumLabel(context, value),
      onPressed: onPressed,
      haptic: true,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, SfMotion.quick),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? tone.withValues(alpha: .16) : c.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? tone.withValues(alpha: .52) : c.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? tone : c.muted),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _attendanceEnumLabel(context, value),
                maxLines: 1,
                style: SfType.ui(
                  size: 9.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? tone : c.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSubmitBar extends StatelessWidget {
  const _AttendanceSubmitBar({
    required this.marked,
    required this.total,
    required this.submitting,
    required this.enabled,
    required this.onSubmit,
  });

  final int marked;
  final int total;
  final bool submitting;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.ink.withValues(alpha: .07),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(
                    context,
                    uz: '$marked / $total tayyor',
                    ru: 'Готово $marked из $total',
                    en: '$marked of $total ready',
                  ),
                  style: SfType.mono(size: 11, color: c.muted),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : marked / total,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(5),
                  color: marked == total && total > 0 ? c.success : c.primary,
                  backgroundColor: c.surface3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SfButton(
            label: submitting
                ? _text(
                    context,
                    uz: 'Yuborilmoqda…',
                    ru: 'Отправка…',
                    en: 'Submitting…',
                  )
                : _text(context, uz: 'Yuborish', ru: 'Отправить', en: 'Submit'),
            trailing: submitting ? null : SfIcons.arrowR,
            onPressed: enabled ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _InlineModuleState extends StatelessWidget {
  const _InlineModuleState({
    required this.resource,
    required this.title,
    this.onRetry,
  });

  final LearningResource<Object?> resource;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final unavailable = resource.isUnavailable;
    final tone = unavailable ? c.warn : c.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: tone.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unavailable ? Icons.lock_outline_rounded : Icons.cloud_off_outlined,
            size: 21,
            color: tone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SfType.ui(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  resource.message ??
                      (unavailable
                          ? _text(
                              context,
                              uz: 'Bu modul hisobingiz uchun yoqilmagan.',
                              ru: 'Этот модуль не включён для вашей учётной записи.',
                              en: 'This module is not enabled for your account.',
                            )
                          : _text(
                              context,
                              uz: 'Serverga ulanishni tekshirib, qayta urinib ko‘ring.',
                              ru: 'Проверьте подключение и повторите попытку.',
                              en: 'Check the connection and try again.',
                            )),
                  style: SfType.ui(size: 10.5, color: c.ink2, height: 1.4),
                ),
              ],
            ),
          ),
          if (onRetry != null && !unavailable)
            IconButton(
              tooltip: _text(
                context,
                uz: 'Qayta urinish',
                ru: 'Повторить',
                en: 'Try again',
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              color: tone,
            ),
        ],
      ),
    );
  }
}

class _InvalidLearningRoute extends StatelessWidget {
  const _InvalidLearningRoute({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => SfScaffold(
    top: SfNavBar(
      title: title,
      leading: IconButton(
        onPressed: context.canPop()
            ? context.pop
            : () => context.go('/workspace'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
    ),
    body: SfErrorState(
      title: title,
      message: message,
      retryLabel: _text(
        context,
        uz: 'Guruhlarni ochish',
        ru: 'Открыть группы',
        en: 'Open groups',
      ),
      onRetry: () => context.go('/workspace'),
    ),
  );
}

Widget? _blockingState<T>(
  BuildContext context,
  LearningResource<T> resource, {
  VoidCallback? onRetry,
  String? unavailableTitle,
  String? loadingMessage,
}) {
  if (resource.value != null) return null;
  return switch (resource.phase) {
    LearningLoadPhase.idle ||
    LearningLoadPhase.waitingForSession ||
    LearningLoadPhase.loading => SfLoadingState(
      label: _text(
        context,
        uz: resource.phase == LearningLoadPhase.waitingForSession
            ? 'Xavfsiz sessiya tayyorlanmoqda…'
            : 'Yuklanmoqda…',
        ru: resource.phase == LearningLoadPhase.waitingForSession
            ? 'Подготовка защищённой сессии…'
            : 'Загрузка…',
        en: resource.phase == LearningLoadPhase.waitingForSession
            ? 'Preparing secure session…'
            : 'Loading…',
      ),
      message: loadingMessage,
    ),
    LearningLoadPhase.unavailable => SfEmptyState(
      icon: Icons.lock_outline_rounded,
      title:
          unavailableTitle ??
          _text(
            context,
            uz: 'Modul mavjud emas',
            ru: 'Модуль недоступен',
            en: 'Module unavailable',
          ),
      message:
          resource.message ??
          _text(
            context,
            uz: 'Bu bo‘lim hisobingiz yoki filialingiz uchun yoqilmagan.',
            ru: 'Этот раздел не включён для вашей учётной записи или филиала.',
            en: 'This section is not enabled for your account or branch.',
          ),
    ),
    LearningLoadPhase.failure => SfErrorState(
      title: _text(
        context,
        uz: 'Ma’lumotlarni olib bo‘lmadi',
        ru: 'Не удалось загрузить данные',
        en: 'Could not load data',
      ),
      message: resource.message,
      retryLabel: _text(
        context,
        uz: 'Qayta urinish',
        ru: 'Повторить',
        en: 'Try again',
      ),
      onRetry: onRetry,
    ),
    LearningLoadPhase.ready => null,
  };
}

Future<void> _showLessonDetails(
  BuildContext context,
  BackendLesson lesson,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: SfTheme.colorsOf(context).surface,
  builder: (sheetContext) {
    final c = SfTheme.colorsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lesson.title.isEmpty ? lesson.lessonTypeName : lesson.title,
                    style: SfType.ui(
                      size: 20,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                ),
                SfPill(
                  label: _lessonStatusLabel(context, lesson.status),
                  tone: _lessonPillTone(lesson.status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailLine(
              icon: Icons.groups_outlined,
              label: _text(context, uz: 'Guruh', ru: 'Группа', en: 'Group'),
              value: lesson.cohortName,
            ),
            _DetailLine(
              icon: Icons.schedule_rounded,
              label: _text(context, uz: 'Vaqt', ru: 'Время', en: 'Time'),
              value: lesson.startsAt == null
                  ? '—'
                  : '${_shortDate(context, lesson.startsAt)} · ${_time(lesson.startsAt!.toLocal())}–${lesson.endsAt == null ? '—' : _time(lesson.endsAt!.toLocal())}',
            ),
            _DetailLine(
              icon: Icons.meeting_room_outlined,
              label: _text(context, uz: 'Xona', ru: 'Кабинет', en: 'Room'),
              value: lesson.roomName ?? '',
            ),
            _DetailLine(
              icon: Icons.person_outline_rounded,
              label: _text(
                context,
                uz: 'O‘qituvchi',
                ru: 'Учитель',
                en: 'Teacher',
              ),
              value: lesson.teacherName,
              last: true,
            ),
            if (lesson.cohortId != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SfButton(
                      kind: SfButtonKind.ghost,
                      label: _text(
                        context,
                        uz: 'Guruhni ochish',
                        ru: 'Открыть группу',
                        en: 'Open group',
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.push('/cohort?id=${lesson.cohortId}');
                      },
                    ),
                  ),
                  if (lesson.status != 'cancelled') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SfButton(
                        label: _text(
                          context,
                          uz: 'Davomat',
                          ru: 'Посещаемость',
                          en: 'Attendance',
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          context.push(_attendanceLocation(lesson));
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  },
);

enum _StudentCardMode { recognition, correction }

class _LessonCardPreview extends StatelessWidget {
  const _LessonCardPreview({
    required this.mode,
    required this.recipient,
    required this.recognition,
    required this.points,
    required this.reason,
  });

  final _StudentCardMode mode;
  final String recipient;
  final BackendRecognitionType? recognition;
  final int points;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final positive = mode == _StudentCardMode.recognition;
    final tone = positive ? c.primary : c.danger;
    final title = positive
        ? recognition?.name ??
              _text(
                context,
                uz: 'Kartani tanlang',
                ru: 'Выберите карточку',
                en: 'Choose a card',
              )
        : _text(
            context,
            uz: '$points ball ogohlantirish',
            ru: 'Замечание · $points балл.',
            en: '$points-point correction',
          );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: positive
              ? [c.primarySoft, c.accentSoft]
              : [c.dangerSoft, c.warnSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: tone.withValues(alpha: .28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              positive ? Icons.star_rounded : Icons.shield_outlined,
              size: 126,
              color: tone.withValues(alpha: .09),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      positive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 17,
                      color: tone,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        positive
                            ? _text(
                                context,
                                uz: 'UP CARD · API KATALOGI',
                                ru: 'UP CARD · КАТАЛОГ API',
                                en: 'UP CARD · API CATALOG',
                              )
                            : _text(
                                context,
                                uz: 'DOWN CARD · AUDIT QAYDI',
                                ru: 'DOWN CARD · ЗАПИСЬ АУДИТА',
                                en: 'DOWN CARD · AUDITED RECORD',
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.eyebrow(size: 8, color: tone),
                      ),
                    ),
                    if (positive && recognition?.emoji.isNotEmpty == true)
                      Text(
                        recognition!.emoji,
                        style: const TextStyle(fontSize: 19),
                      ),
                  ],
                ),
                const SizedBox(height: 19),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.display(size: 21, color: c.ink, height: 1.05),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: tone),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        recipient,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: c.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(size: 9.5, color: c.muted, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _showStudentCardSheet(
  BuildContext context, {
  required LearningWorkspaceController controller,
  required BackendCohortMember member,
  required int lessonId,
  required int cohortId,
}) async {
  if (controller.recognitionCatalogFor(cohortId).phase ==
      LearningLoadPhase.idle) {
    unawaited(controller.loadRecognitionCatalog(cohortId: cohortId));
  }
  final noteController = TextEditingController();
  var mode = _StudentCardMode.recognition;
  BackendRecognitionType? selectedType;
  var points = 1;
  var submitting = false;
  String? errorMessage;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: SfTheme.colorsOf(context).surface,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => AnimatedBuilder(
        animation: controller,
        builder: (sheetContext, _) {
          final c = SfTheme.colorsOf(sheetContext);
          final catalogue = controller.recognitionCatalogFor(cohortId);
          final types = catalogue.value ?? const <BackendRecognitionType>[];
          if (selectedType != null &&
              !types.any((value) => value.id == selectedType!.id)) {
            selectedType = null;
          }
          return SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: SfMotion.resolve(sheetContext, SfMotion.quick),
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: FractionallySizedBox(
                heightFactor: .9,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.style_outlined, color: c.primary),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _text(
                                  sheetContext,
                                  uz: 'Dars kartasini bering',
                                  ru: 'Выдать карточку на уроке',
                                  en: 'Give a lesson card',
                                ),
                                style: SfType.ui(
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: c.ink,
                                ),
                              ),
                              Text(
                                '${member.studentName} · #$lessonId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SfType.ui(size: 10.5, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: _text(
                            sheetContext,
                            uz: 'Yopish',
                            ru: 'Закрыть',
                            en: 'Close',
                          ),
                          onPressed: submitting
                              ? null
                              : () => Navigator.pop(sheetContext, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_StudentCardMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: _StudentCardMode.recognition,
                            icon: const Icon(Icons.arrow_upward_rounded),
                            label: Text(
                              _text(
                                sheetContext,
                                uz: 'Ijobiy karta',
                                ru: 'Позитивная',
                                en: 'Up card',
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: _StudentCardMode.correction,
                            icon: const Icon(Icons.arrow_downward_rounded),
                            label: Text(
                              _text(
                                sheetContext,
                                uz: 'Ogohlantirish',
                                ru: 'Замечание',
                                en: 'Down card',
                              ),
                            ),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: submitting
                            ? null
                            : (values) => setSheetState(() {
                                mode = values.first;
                                errorMessage = null;
                                noteController.clear();
                              }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LessonCardPreview(
                      mode: mode,
                      recipient: member.studentName,
                      recognition: selectedType,
                      points: points,
                      reason: noteController.text.trim(),
                    ),
                    const SizedBox(height: 18),
                    if (mode == _StudentCardMode.recognition) ...[
                      Text(
                        _text(
                          sheetContext,
                          uz: 'Markaz kartalari',
                          ru: 'Карточки центра',
                          en: 'Center card types',
                        ),
                        style: SfType.eyebrow(color: c.muted),
                      ),
                      const SizedBox(height: 8),
                      if (catalogue.isLoading && types.isEmpty)
                        const LinearProgressIndicator()
                      else if (catalogue.isUnavailable || catalogue.isFailure)
                        _InlineModuleState(
                          resource: catalogue,
                          title: _text(
                            sheetContext,
                            uz: 'Ijobiy kartalar mavjud emas',
                            ru: 'Позитивные карточки недоступны',
                            en: 'Recognition cards unavailable',
                          ),
                          onRetry: () => controller.loadRecognitionCatalog(
                            cohortId: cohortId,
                            force: true,
                          ),
                        )
                      else if (types.isEmpty)
                        SfEmptyState(
                          compact: true,
                          title: _text(
                            sheetContext,
                            uz: 'Faol karta turi yo‘q',
                            ru: 'Нет активных типов карточек',
                            en: 'No active card types',
                          ),
                          message: _text(
                            sheetContext,
                            uz: 'Markaz katalogni API orqali sozlaydi.',
                            ru: 'Центр настраивает каталог через API.',
                            en: 'Your center configures this catalog on the server.',
                          ),
                        )
                      else
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final type in types)
                              ChoiceChip(
                                key: ValueKey(
                                  'production-recognition-${type.id}',
                                ),
                                selected: selectedType?.id == type.id,
                                onSelected: submitting
                                    ? null
                                    : (_) => setSheetState(() {
                                        selectedType = type;
                                        errorMessage = null;
                                      }),
                                avatar: Text(type.emoji),
                                label: Text(type.name),
                              ),
                          ],
                        ),
                      const SizedBox(height: 13),
                      TextField(
                        controller: noteController,
                        enabled: !submitting,
                        maxLength: 255,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          labelText: _text(
                            sheetContext,
                            uz: 'Nima uchun? (ixtiyoriy)',
                            ru: 'За что? (необязательно)',
                            en: 'What did they do? (optional)',
                          ),
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: c.dangerSoft.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: c.danger.withValues(alpha: .22),
                          ),
                        ),
                        child: Text(
                          _text(
                            sheetContext,
                            uz: 'Bu intizomiy qayd serverda audit izi bilan saqlanadi. Faqat aniq, xolis sabab yozing.',
                            ru: 'Это дисциплинарная запись с аудитом на сервере. Укажите точную и объективную причину.',
                            en: 'This is an audited server record. Use a specific, objective reason.',
                          ),
                          style: SfType.ui(
                            size: 10.5,
                            color: c.ink2,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        _text(
                          sheetContext,
                          uz: 'Ball',
                          ru: 'Баллы',
                          en: 'Points',
                        ),
                        style: SfType.eyebrow(color: c.muted),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        children: [
                          for (final value in [1, 2, 3])
                            ChoiceChip(
                              selected: points == value,
                              onSelected: submitting
                                  ? null
                                  : (_) => setSheetState(() => points = value),
                              label: Text('$value'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        key: const ValueKey('production-correction-reason'),
                        controller: noteController,
                        enabled: !submitting,
                        maxLength: 255,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setSheetState(() {
                          errorMessage = null;
                        }),
                        decoration: InputDecoration(
                          labelText: _text(
                            sheetContext,
                            uz: 'Aniq sabab',
                            ru: 'Точная причина',
                            en: 'Specific reason',
                          ),
                          prefixIcon: const Icon(Icons.gavel_outlined),
                        ),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        errorMessage!,
                        style: SfType.ui(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: c.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SfButton(
                      block: true,
                      label: submitting
                          ? _text(
                              sheetContext,
                              uz: 'Serverga yuborilmoqda…',
                              ru: 'Отправка на сервер…',
                              en: 'Sending to server…',
                            )
                          : mode == _StudentCardMode.recognition
                          ? _text(
                              sheetContext,
                              uz: 'Ijobiy kartani berish',
                              ru: 'Выдать позитивную карточку',
                              en: 'Give up card',
                            )
                          : _text(
                              sheetContext,
                              uz: 'Ogohlantirishni yozish',
                              ru: 'Записать замечание',
                              en: 'Record down card',
                            ),
                      leading: mode == _StudentCardMode.recognition
                          ? Icons.auto_awesome_rounded
                          : Icons.gavel_rounded,
                      onPressed: submitting
                          ? null
                          : () async {
                              final note = noteController.text.trim();
                              if (mode == _StudentCardMode.recognition &&
                                  selectedType == null) {
                                setSheetState(() {
                                  errorMessage = _text(
                                    sheetContext,
                                    uz: 'Avval markaz kartasini tanlang.',
                                    ru: 'Сначала выберите карточку центра.',
                                    en: 'Choose a center card first.',
                                  );
                                });
                                return;
                              }
                              if (mode == _StudentCardMode.correction &&
                                  note.isEmpty) {
                                setSheetState(() {
                                  errorMessage = _text(
                                    sheetContext,
                                    uz: 'Intizomiy qayd uchun sabab majburiy.',
                                    ru: 'Для дисциплинарной записи нужна причина.',
                                    en: 'A reason is required for a correction.',
                                  );
                                });
                                return;
                              }
                              final approved = await showSfConfirmDialog(
                                sheetContext,
                                title: mode == _StudentCardMode.recognition
                                    ? _text(
                                        sheetContext,
                                        uz: 'Kartani berasizmi?',
                                        ru: 'Выдать карточку?',
                                        en: 'Give this card?',
                                      )
                                    : _text(
                                        sheetContext,
                                        uz: 'Ogohlantirish yozilsinmi?',
                                        ru: 'Записать замечание?',
                                        en: 'Record this correction?',
                                      ),
                                message: mode == _StudentCardMode.recognition
                                    ? '${member.studentName} · ${selectedType!.emoji} ${selectedType!.name}'
                                    : '${member.studentName} · $points ${_text(sheetContext, uz: 'ball', ru: 'балл.', en: 'points')}',
                                destructive:
                                    mode == _StudentCardMode.correction,
                              );
                              if (!approved || !sheetContext.mounted) return;
                              setSheetState(() {
                                submitting = true;
                                errorMessage = null;
                              });
                              try {
                                if (mode == _StudentCardMode.recognition) {
                                  await controller.grantRecognition(
                                    achievementId: selectedType!.id,
                                    studentId: member.studentId,
                                    note: note,
                                  );
                                } else {
                                  await controller.issueCorrection(
                                    studentId: member.studentId,
                                    points: points,
                                    reason: note,
                                  );
                                }
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext, true);
                                SfToast.show(
                                  context,
                                  title: _text(
                                    context,
                                    uz: 'Serverda saqlandi',
                                    ru: 'Сохранено на сервере',
                                    en: 'Saved on server',
                                  ),
                                  message: member.studentName,
                                  tone: SfToastTone.success,
                                );
                              } on Object catch (error) {
                                if (!sheetContext.mounted) return;
                                setSheetState(() {
                                  submitting = false;
                                  errorMessage = error.toString();
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  // A modal future completes when pop begins, while its TextField can remain in
  // the reverse transition briefly. Dispose after that route is fully gone.
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
      noteController.dispose();
    }),
  );
  return result ?? false;
}

Future<String?> _attendanceNote(
  BuildContext context,
  String studentName,
  AttendanceStatus status,
) async {
  final controller = TextEditingController();
  final tone = _attendanceEnumColor(context, status);
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: SfTheme.colorsOf(context).surface,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final c = SfTheme.colorsOf(sheetContext);
        final suggestions = status == AttendanceStatus.excused
            ? [
                _text(
                  sheetContext,
                  uz: 'Tibbiy ma’lumotnoma',
                  ru: 'Медицинская справка',
                  en: 'Medical note',
                ),
                _text(
                  sheetContext,
                  uz: 'Rasmiy ruxsat',
                  ru: 'Официальное разрешение',
                  en: 'Official permission',
                ),
              ]
            : [
                _text(
                  sheetContext,
                  uz: 'Kasallik',
                  ru: 'Болезнь',
                  en: 'Illness',
                ),
                _text(
                  sheetContext,
                  uz: 'Oilaviy sabab',
                  ru: 'Семейная причина',
                  en: 'Family reason',
                ),
              ];
        return SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: SfMotion.resolve(sheetContext, SfMotion.quick),
            padding: EdgeInsets.fromLTRB(
              18,
              2,
              18,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        status == AttendanceStatus.absent
                            ? Icons.person_off_outlined
                            : Icons.verified_user_outlined,
                        color: tone,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SfType.ui(
                              size: 17,
                              weight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            _attendanceEnumLabel(sheetContext, status),
                            style: SfType.ui(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: tone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  status == AttendanceStatus.absent
                      ? _text(
                          sheetContext,
                          uz: 'Yo‘qlik sababini qisqa va xolis yozing.',
                          ru: 'Кратко и объективно укажите причину отсутствия.',
                          en: 'Add a short, objective absence reason.',
                        )
                      : _text(
                          sheetContext,
                          uz: 'Sababli holatni tasdiqlovchi izoh yozing.',
                          ru: 'Добавьте пояснение для уважительной причины.',
                          en: 'Add a note supporting the excused status.',
                        ),
                  style: SfType.ui(size: 11, color: c.muted, height: 1.4),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final suggestion in suggestions)
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          controller.text = suggestion;
                          controller.selection = TextSelection.collapsed(
                            offset: controller.text.length,
                          );
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 11),
                TextField(
                  key: const ValueKey('production-attendance-note'),
                  controller: controller,
                  autofocus: true,
                  maxLength: 200,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    labelText: _text(
                      sheetContext,
                      uz: 'Izoh',
                      ru: 'Комментарий',
                      en: 'Note',
                    ),
                    hintText: _text(
                      sheetContext,
                      uz: 'Qisqa va aniq izoh',
                      ru: 'Краткое пояснение',
                      en: 'Short, clear note',
                    ),
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SfButton(
                        block: true,
                        kind: SfButtonKind.ghost,
                        label: _text(
                          sheetContext,
                          uz: 'Bekor qilish',
                          ru: 'Отмена',
                          en: 'Cancel',
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SfButton(
                        block: true,
                        label: _text(
                          sheetContext,
                          uz: 'Holatni saqlash',
                          ru: 'Сохранить статус',
                          en: 'Save status',
                        ),
                        leading: Icons.check_rounded,
                        onPressed: controller.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(
                                sheetContext,
                                controller.text.trim(),
                              ),
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
  );
  controller.dispose();
  return result;
}

void _openTab(BuildContext context, SfTab tab) {
  final route = switch (tab) {
    SfTab.home => '/home',
    SfTab.cohort => '/workspace',
    SfTab.tasks => '/work',
    SfTab.ai || SfTab.print => '/more',
  };
  context.go(route);
}

String _attendanceLocation(BackendLesson lesson) => Uri(
  path: '/attendance',
  queryParameters: {
    'cohort': '${lesson.cohortId}',
    'lesson': '${lesson.id}',
    if (lesson.startsAt != null) 'at': lesson.startsAt!.toIso8601String(),
    if (lesson.title.isNotEmpty) 'title': lesson.title,
  },
).toString();

DateTime _lessonTime(BackendLesson lesson) =>
    lesson.startsAt?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime _recordTime(BackendAttendanceRecord record) =>
    (record.lessonStartsAt ?? record.markedAt ?? record.createdAt)?.toLocal() ??
    DateTime.fromMillisecondsSinceEpoch(0);

AttendanceStatus? _attendanceStatusFromServer(String value) => switch (value) {
  'present' => AttendanceStatus.present,
  'absent' => AttendanceStatus.absent,
  'late' => AttendanceStatus.late,
  'excused' => AttendanceStatus.excused,
  _ => null,
};

String _attendanceEnumLabel(BuildContext context, AttendanceStatus value) =>
    _attendanceStatusLabel(context, value.name);

Color _attendanceEnumColor(BuildContext context, AttendanceStatus value) =>
    _attendanceStatusColor(context, value.name);

String _attendanceStatusLabel(BuildContext context, String value) =>
    switch (value) {
      'present' => _text(context, uz: 'Bor', ru: 'Присутствует', en: 'Present'),
      'absent' => _text(context, uz: 'Yo‘q', ru: 'Отсутствует', en: 'Absent'),
      'late' => _text(context, uz: 'Kechikdi', ru: 'Опоздал', en: 'Late'),
      'excused' => _text(
        context,
        uz: 'Sababli',
        ru: 'Уважительная',
        en: 'Excused',
      ),
      _ => value.isEmpty ? '—' : value,
    };

Color _attendanceStatusColor(BuildContext context, String value) {
  final c = SfTheme.colorsOf(context);
  return switch (value) {
    'present' => c.success,
    'absent' => c.danger,
    'late' => c.warn,
    'excused' => c.muted,
    _ => c.primary,
  };
}

String _lessonStatusLabel(BuildContext context, String value) =>
    switch (value) {
      'scheduled' => _text(
        context,
        uz: 'Rejada',
        ru: 'Запланирован',
        en: 'Scheduled',
      ),
      'completed' => _text(
        context,
        uz: 'Yakunlangan',
        ru: 'Завершён',
        en: 'Completed',
      ),
      'cancelled' => _text(
        context,
        uz: 'Bekor qilingan',
        ru: 'Отменён',
        en: 'Cancelled',
      ),
      _ =>
        value.isEmpty
            ? _text(context, uz: 'Noma’lum', ru: 'Неизвестно', en: 'Unknown')
            : value,
    };

Color _lessonStatusColor(BuildContext context, String value) {
  final c = SfTheme.colorsOf(context);
  return switch (value) {
    'scheduled' => c.primary,
    'completed' => c.success,
    'cancelled' => c.danger,
    _ => c.muted,
  };
}

SfPillTone _lessonPillTone(String value) => switch (value) {
  'scheduled' => SfPillTone.primary,
  'completed' => SfPillTone.success,
  'cancelled' => SfPillTone.danger,
  _ => SfPillTone.neutral,
};

Color _rateColor(BuildContext context, double value) {
  final c = SfTheme.colorsOf(context);
  if (value >= 92) return c.success;
  if (value >= 82) return c.warn;
  return c.danger;
}

String _rangeLabel(BuildContext context, _AttendanceRangePreset value) =>
    switch (value) {
      _AttendanceRangePreset.sevenDays => _text(
        context,
        uz: '7 kun',
        ru: '7 дней',
        en: '7 days',
      ),
      _AttendanceRangePreset.thirtyDays => _text(
        context,
        uz: '30 kun',
        ru: '30 дней',
        en: '30 days',
      ),
      _AttendanceRangePreset.term => _text(
        context,
        uz: 'Semestr',
        ru: 'Семестр',
        en: 'Term',
      ),
      _AttendanceRangePreset.custom => _text(
        context,
        uz: 'Oraliq',
        ru: 'Период',
        en: 'Custom',
      ),
    };

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _dateKey(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _shortDate(BuildContext context, DateTime? value) {
  if (value == null) return '—';
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _longDate(BuildContext context, DateTime date) {
  final local = date.toLocal();
  return '${_weekdayLong(context, local.weekday)}, ${local.day} ${_monthName(context, local.month)}';
}

String _monthYear(BuildContext context, DateTime date) =>
    '${_monthName(context, date.month)} ${date.year}';

String _weekdayShort(BuildContext context, int weekday) {
  const uz = ['DU', 'SE', 'CH', 'PA', 'JU', 'SH', 'YA'];
  const ru = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  const en = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return switch (Localizations.localeOf(context).languageCode) {
    'ru' => ru[weekday - 1],
    'en' => en[weekday - 1],
    _ => uz[weekday - 1],
  };
}

String _weekdayLong(BuildContext context, int weekday) {
  const uz = [
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
  ];
  const ru = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
  const en = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return switch (Localizations.localeOf(context).languageCode) {
    'ru' => ru[weekday - 1],
    'en' => en[weekday - 1],
    _ => uz[weekday - 1],
  };
}

String _monthName(BuildContext context, int month) {
  const uz = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];
  const ru = [
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь',
  ];
  const en = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return switch (Localizations.localeOf(context).languageCode) {
    'ru' => ru[month - 1],
    'en' => en[month - 1],
    _ => uz[month - 1],
  };
}

String _text(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (Localizations.localeOf(context).languageCode) {
  'ru' => ru,
  'en' => en,
  _ => uz,
};
