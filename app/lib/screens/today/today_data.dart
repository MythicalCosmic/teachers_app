import 'package:flutter/material.dart';

enum TodayMetricKind { lessons, attendance, performance }

enum LessonProgress { upcoming, live, completed }

@immutable
class TodayLessonData {
  const TodayLessonData({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.subject,
    required this.level,
    required this.cohort,
    required this.room,
    required this.students,
    required this.topic,
    required this.progress,
    required this.tone,
  });

  final String id;
  final DateTime date;
  final String start;
  final String end;
  final String subject;
  final String level;
  final String cohort;
  final String room;
  final int students;
  final String topic;
  final LessonProgress progress;
  final int tone;

  String get timeRange => '$start–$end';
  String get title => '$subject · $cohort';

  TodayLessonData copyWith({DateTime? date, LessonProgress? progress}) =>
      TodayLessonData(
        id: id,
        date: date ?? this.date,
        start: start,
        end: end,
        subject: subject,
        level: level,
        cohort: cohort,
        room: room,
        students: students,
        topic: topic,
        progress: progress ?? this.progress,
        tone: tone,
      );
}

final DateTime _templateWeekStart = DateTime(2026, 5, 18);
DateTime _staffReferenceDate = DateUtils.dateOnly(DateTime.now());

/// The device date captured for this app launch.
///
/// Keeping one reference date avoids the dashboard changing underneath a
/// teacher if the app remains open across midnight. A fresh launch picks up the
/// new day, while tests can set a deterministic reference without changing the
/// production clock.
DateTime get staffToday => _staffReferenceDate;

DateTime get staffWeekStart =>
    staffToday.subtract(Duration(days: staffToday.weekday - DateTime.monday));

void debugSetStaffToday(DateTime? value) {
  _staffReferenceDate = DateUtils.dateOnly(value ?? DateTime.now());
}

final List<TodayLessonData> _staffLessonTemplate = [
  TodayLessonData(
    id: 'alg-9b-mon',
    date: DateTime(2026, 5, 18),
    start: '09:00',
    end: '09:45',
    subject: 'Algebra',
    level: 'Daraja II',
    cohort: '9-B',
    room: '304',
    students: 24,
    topic: 'Kvadrat tenglamalarni yechish',
    progress: LessonProgress.completed,
    tone: 0,
  ),
  TodayLessonData(
    id: 'geom-10v-mon',
    date: DateTime(2026, 5, 18),
    start: '11:30',
    end: '12:15',
    subject: 'Geometriya',
    level: 'Daraja I',
    cohort: '10-V',
    room: '301',
    students: 22,
    topic: 'Aylana va urinma',
    progress: LessonProgress.completed,
    tone: 1,
  ),
  TodayLessonData(
    id: 'alg-9b-tue',
    date: DateTime(2026, 5, 19),
    start: '09:00',
    end: '09:45',
    subject: 'Algebra',
    level: 'Daraja II',
    cohort: '9-B',
    room: '304',
    students: 24,
    topic: 'Kvadrat tenglamalarni yechish',
    progress: LessonProgress.live,
    tone: 0,
  ),
  TodayLessonData(
    id: 'alg-9a-tue',
    date: DateTime(2026, 5, 19),
    start: '10:00',
    end: '10:45',
    subject: 'Algebra',
    level: 'Daraja I',
    cohort: '9-A',
    room: '304',
    students: 25,
    topic: 'Diskriminant va ildizlar',
    progress: LessonProgress.upcoming,
    tone: 0,
  ),
  TodayLessonData(
    id: 'geom-10v-tue',
    date: DateTime(2026, 5, 19),
    start: '11:30',
    end: '12:15',
    subject: 'Geometriya',
    level: 'Daraja II',
    cohort: '10-V',
    room: '301',
    students: 22,
    topic: 'Koordinata tekisligida aylana',
    progress: LessonProgress.upcoming,
    tone: 1,
  ),
  TodayLessonData(
    id: 'prep-11b-tue',
    date: DateTime(2026, 5, 19),
    start: '15:00',
    end: '15:45',
    subject: 'Tayyorlov',
    level: 'Olimpiada',
    cohort: '11-B',
    room: '210',
    students: 18,
    topic: 'Nostandart tengsizliklar',
    progress: LessonProgress.upcoming,
    tone: 2,
  ),
  TodayLessonData(
    id: 'alg-9b-wed',
    date: DateTime(2026, 5, 20),
    start: '10:00',
    end: '10:45',
    subject: 'Algebra',
    level: 'Daraja II',
    cohort: '9-B',
    room: '304',
    students: 24,
    topic: 'Viyet teoremasi',
    progress: LessonProgress.upcoming,
    tone: 0,
  ),
  TodayLessonData(
    id: 'prep-11b-wed',
    date: DateTime(2026, 5, 20),
    start: '14:00',
    end: '14:45',
    subject: 'Tayyorlov',
    level: 'Olimpiada',
    cohort: '11-B',
    room: '210',
    students: 18,
    topic: 'Mantiqiy masalalar',
    progress: LessonProgress.upcoming,
    tone: 2,
  ),
  TodayLessonData(
    id: 'alg-9a-thu',
    date: DateTime(2026, 5, 21),
    start: '09:00',
    end: '09:45',
    subject: 'Algebra',
    level: 'Daraja I',
    cohort: '9-A',
    room: '304',
    students: 25,
    topic: 'Tenglamalar sistemasi',
    progress: LessonProgress.upcoming,
    tone: 0,
  ),
  TodayLessonData(
    id: 'geom-10v-thu',
    date: DateTime(2026, 5, 21),
    start: '11:30',
    end: '12:15',
    subject: 'Geometriya',
    level: 'Daraja II',
    cohort: '10-V',
    room: '301',
    students: 22,
    topic: 'Fazoviy shakllar',
    progress: LessonProgress.upcoming,
    tone: 1,
  ),
  TodayLessonData(
    id: 'alg-9b-fri',
    date: DateTime(2026, 5, 22),
    start: '10:00',
    end: '10:45',
    subject: 'Algebra',
    level: 'Daraja II',
    cohort: '9-B',
    room: '304',
    students: 24,
    topic: 'Haftalik mustahkamlash',
    progress: LessonProgress.upcoming,
    tone: 0,
  ),
  TodayLessonData(
    id: 'consult-sat',
    date: DateTime(2026, 5, 23),
    start: '10:00',
    end: '11:30',
    subject: 'Konsultatsiya',
    level: 'Ochiq',
    cohort: '9–11',
    room: '210',
    students: 12,
    topic: 'Individual savol-javob',
    progress: LessonProgress.upcoming,
    tone: 2,
  ),
];

/// Demo lessons rebased onto the current device week while preserving their
/// weekday, time, progress and identifiers.
List<TodayLessonData> get staffLessonPlan {
  final weekStart = staffWeekStart;
  final rebased = _staffLessonTemplate
      .map((lesson) {
        final dayOffset = lesson.date.difference(_templateWeekStart).inDays;
        return lesson.copyWith(date: weekStart.add(Duration(days: dayOffset)));
      })
      .toList(growable: false);
  final liveIndex = rebased.indexWhere(
    (lesson) => DateUtils.isSameDay(lesson.date, staffToday),
  );
  return List.unmodifiable([
    for (final entry in rebased.asMap().entries)
      entry.value.copyWith(
        progress: entry.value.date.isBefore(staffToday)
            ? LessonProgress.completed
            : entry.value.date.isAfter(staffToday)
            ? LessonProgress.upcoming
            : entry.key == liveIndex
            ? LessonProgress.live
            : LessonProgress.upcoming,
      ),
  ]);
}

List<TodayLessonData> lessonsFor(DateTime date) => staffLessonPlan
    .where((lesson) => DateUtils.isSameDay(lesson.date, date))
    .toList(growable: false);

TodayLessonData lessonById(String? id) => staffLessonPlan.firstWhere(
  (lesson) => lesson.id == id,
  orElse: featuredStaffLesson,
);

TodayLessonData featuredStaffLesson() {
  final plan = staffLessonPlan;
  return plan.firstWhere(
    (lesson) => lesson.progress == LessonProgress.live,
    orElse: () => plan.firstWhere(
      (lesson) => lesson.progress == LessonProgress.upcoming,
      orElse: () => plan.last,
    ),
  );
}

String groupIdForLesson(TodayLessonData lesson) => switch (lesson.cohort) {
  '9-B' => 'cohort-9b-algebra',
  '9-A' => 'cohort-9a-algebra',
  '10-V' => 'cohort-10v-geometry',
  '11-B' || '9–11' => 'cohort-11b-exam',
  _ => 'cohort-9b-algebra',
};

const weekdayShortUz = ['Du', 'Se', 'Cho', 'Pa', 'Ju', 'Sha', 'Ya'];
const weekdayLongUz = [
  'Dushanba',
  'Seshanba',
  'Chorshanba',
  'Payshanba',
  'Juma',
  'Shanba',
  'Yakshanba',
];
const monthUz = [
  '',
  'Yanvar',
  'Fevral',
  'Mart',
  'Aprel',
  'May',
  'Iyun',
  'Iyul',
  'Avgust',
  'Sentabr',
  'Oktabr',
  'Noyabr',
  'Dekabr',
];

String dayTitle(DateTime date) =>
    '${weekdayLongUz[date.weekday - 1]}, ${date.day} ${monthUz[date.month]}';

String staffLanguageCode(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

bool staffIsEnglish(BuildContext context) => staffLanguageCode(context) == 'en';

bool staffIsRussian(BuildContext context) => staffLanguageCode(context) == 'ru';

/// Localizes teacher-workspace copy without forcing every call site to carry a
/// three-language tuple. Russian copy can be supplied where available; until a
/// string is translated, English is used as the safe fallback instead of
/// silently showing Uzbek under the Russian setting.
String staffTr(BuildContext context, String uz, String en, {String? ru}) =>
    switch (staffLanguageCode(context)) {
      'ru' => ru ?? en,
      'en' => en,
      _ => uz,
    };

const weekdayShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayLongEn = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const monthEn = [
  '',
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

const weekdayShortRu = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const weekdayLongRu = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье',
];
const monthRu = [
  '',
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String staffDayTitle(
  BuildContext context,
  DateTime date,
) => switch (staffLanguageCode(context)) {
  'ru' =>
    '${weekdayLongRu[date.weekday - 1]}, ${date.day} ${monthRu[date.month]}',
  'en' =>
    '${weekdayLongEn[date.weekday - 1]}, ${monthEn[date.month]} ${date.day}',
  _ => dayTitle(date),
};

String staffMonthName(BuildContext context, int month) =>
    switch (staffLanguageCode(context)) {
      'ru' => monthRu[month],
      'en' => monthEn[month],
      _ => monthUz[month],
    };

String staffWeekdayShort(BuildContext context, int weekday) =>
    switch (staffLanguageCode(context)) {
      'ru' => weekdayShortRu[weekday - 1],
      'en' => weekdayShortEn[weekday - 1],
      _ => weekdayShortUz[weekday - 1],
    };

int staffIsoWeekNumber(DateTime date) {
  final day = DateUtils.dateOnly(date);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final januaryFourth = DateTime(thursday.year, DateTime.january, 4);
  final weekOneThursday = januaryFourth.add(
    Duration(days: DateTime.thursday - januaryFourth.weekday),
  );
  return 1 + thursday.difference(weekOneThursday).inDays ~/ 7;
}

String staffMonthAndWeekLabel(BuildContext context, DateTime date) => staffTr(
  context,
  '${monthUz[date.month]} · ${staffIsoWeekNumber(date)}-hafta',
  '${monthEn[date.month]} · Week ${staffIsoWeekNumber(date)}',
  ru: '${monthRu[date.month]} · Неделя ${staffIsoWeekNumber(date)}',
);

String staffLessonSubject(BuildContext context, TodayLessonData lesson) =>
    staffTr(
      context,
      lesson.subject,
      switch (lesson.subject) {
        'Geometriya' => 'Geometry',
        'Tayyorlov' => 'Preparation',
        'Konsultatsiya' => 'Consultation',
        _ => lesson.subject,
      },
      ru: switch (lesson.subject) {
        'Algebra' => 'Алгебра',
        'Geometriya' => 'Геометрия',
        'Tayyorlov' => 'Подготовка',
        'Konsultatsiya' => 'Консультация',
        _ => lesson.subject,
      },
    );

String staffLessonLevel(BuildContext context, TodayLessonData lesson) =>
    staffTr(
      context,
      lesson.level,
      switch (lesson.level) {
        'Daraja I' => 'Level I',
        'Daraja II' => 'Level II',
        'Olimpiada' => 'Olympiad',
        'Ochiq' => 'Open',
        _ => lesson.level,
      },
      ru: switch (lesson.level) {
        'Daraja I' => 'Уровень I',
        'Daraja II' => 'Уровень II',
        'Olimpiada' => 'Олимпиада',
        'Ochiq' => 'Открытый',
        _ => lesson.level,
      },
    );

String staffLessonTopic(BuildContext context, TodayLessonData lesson) =>
    staffTr(
      context,
      lesson.topic,
      switch (lesson.id) {
        'alg-9b-mon' || 'alg-9b-tue' => 'Solving quadratic equations',
        'geom-10v-mon' => 'Circles and tangents',
        'alg-9a-tue' => 'Discriminants and roots',
        'geom-10v-tue' => 'Circles on the coordinate plane',
        'prep-11b-tue' => 'Non-standard inequalities',
        'alg-9b-wed' => 'Vieta’s formulas',
        'prep-11b-wed' => 'Logic problems',
        'alg-9a-thu' => 'Systems of equations',
        'geom-10v-thu' => 'Solid geometry',
        'alg-9b-fri' => 'Weekly consolidation',
        'consult-sat' => 'Individual questions and coaching',
        _ => lesson.topic,
      },
      ru: switch (lesson.id) {
        'alg-9b-mon' || 'alg-9b-tue' => 'Решение квадратных уравнений',
        'geom-10v-mon' => 'Окружности и касательные',
        'alg-9a-tue' => 'Дискриминант и корни',
        'geom-10v-tue' => 'Окружность на координатной плоскости',
        'prep-11b-tue' => 'Нестандартные неравенства',
        'alg-9b-wed' => 'Формулы Виета',
        'prep-11b-wed' => 'Логические задачи',
        'alg-9a-thu' => 'Системы уравнений',
        'geom-10v-thu' => 'Стереометрия',
        'alg-9b-fri' => 'Недельное закрепление',
        'consult-sat' => 'Индивидуальные вопросы и консультация',
        _ => lesson.topic,
      },
    );

String staffLessonTitle(BuildContext context, TodayLessonData lesson) =>
    '${staffLessonSubject(context, lesson)} · ${lesson.cohort}';
