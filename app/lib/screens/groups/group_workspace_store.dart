import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';

enum GroupCategory { all, algebra, geometry, examPrep, archived }

enum GroupSort { nextLesson, attendance, name }

enum AttendanceWindow { sevenDays, thirtyDays, term, custom }

@immutable
class GroupStudent {
  const GroupStudent({
    required this.id,
    required this.name,
    required this.phone,
    required this.upCards,
    required this.downCards,
  });

  final String id;
  final String name;
  final String phone;
  final int upCards;
  final int downCards;
}

@immutable
class GroupLesson {
  const GroupLesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.startsAt,
    required this.room,
  });

  final String id;
  final String title;
  final String topic;
  final DateTime startsAt;
  final String room;
}

@immutable
class GroupAttendanceRecord {
  GroupAttendanceRecord({
    required this.id,
    required this.groupId,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonAt,
    required Map<String, AttendanceStatus> statuses,
    Map<String, String> notes = const {},
  }) : statuses = Map.unmodifiable(statuses),
       notes = Map.unmodifiable(notes);

  final String id;
  final String groupId;
  final String lessonId;
  final String lessonTitle;
  final DateTime lessonAt;
  final Map<String, AttendanceStatus> statuses;
  final Map<String, String> notes;

  int count(AttendanceStatus status) =>
      statuses.values.where((value) => value == status).length;

  double get attendanceRate {
    if (statuses.isEmpty) return 0;
    final attended =
        count(AttendanceStatus.present) +
        count(AttendanceStatus.late) +
        count(AttendanceStatus.excused);
    return attended / statuses.length * 100;
  }
}

@immutable
class TeacherGroup {
  TeacherGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.level,
    required this.room,
    required this.teacher,
    required this.nextLesson,
    required this.category,
    required Iterable<GroupStudent> students,
    required Iterable<GroupLesson> lessons,
    required Iterable<double> trend,
    this.archived = false,
  }) : students = List.unmodifiable(students),
       lessons = List.unmodifiable(lessons),
       trend = List.unmodifiable(trend);

  final String id;
  final String name;
  final String subject;
  final String level;
  final String room;
  final String teacher;
  final DateTime nextLesson;
  final GroupCategory category;
  final List<GroupStudent> students;
  final List<GroupLesson> lessons;
  final List<double> trend;
  final bool archived;
}

@immutable
class GroupAttendanceDraft {
  GroupAttendanceDraft({
    required this.groupId,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonAt,
    required Map<String, AttendanceStatus?> statuses,
    Map<String, String> notes = const {},
  }) : statuses = Map.unmodifiable(statuses),
       notes = Map.unmodifiable(notes);

  final String groupId;
  final String lessonId;
  final String lessonTitle;
  final DateTime lessonAt;
  final Map<String, AttendanceStatus?> statuses;
  final Map<String, String> notes;

  int get markedCount => statuses.values.whereType<AttendanceStatus>().length;
  bool get isComplete => markedCount == statuses.length;

  GroupAttendanceDraft copyWith({
    String? lessonId,
    String? lessonTitle,
    DateTime? lessonAt,
    Map<String, AttendanceStatus?>? statuses,
    Map<String, String>? notes,
  }) => GroupAttendanceDraft(
    groupId: groupId,
    lessonId: lessonId ?? this.lessonId,
    lessonTitle: lessonTitle ?? this.lessonTitle,
    lessonAt: lessonAt ?? this.lessonAt,
    statuses: statuses ?? this.statuses,
    notes: notes ?? this.notes,
  );
}

/// Session-local group workspace data.
///
/// It intentionally lives outside AppState until the backend cohort contract is
/// available. The singleton keeps filters, drafts and newly submitted attendance
/// alive while navigating around the installed demo app.
class GroupWorkspaceStore extends ChangeNotifier {
  GroupWorkspaceStore({
    required Iterable<TeacherGroup> groups,
    required Iterable<GroupAttendanceRecord> attendance,
    this._persistence,
    DateTime Function()? now,
  }) : _groups = List.unmodifiable(groups),
       _attendance = List.of(attendance),
       _clock = now ?? DateTime.now;

  factory GroupWorkspaceStore.seeded({
    GroupWorkspacePersistence? persistence,
    DateTime Function()? now,
  }) {
    final clock = now ?? DateTime.now;
    final anchor = clock();
    final groups = _seedGroups(anchor);
    return GroupWorkspaceStore(
      groups: groups,
      attendance: _seedAttendance(groups, anchor),
      persistence: persistence,
      now: clock,
    );
  }

  final List<TeacherGroup> _groups;
  final List<GroupAttendanceRecord> _attendance;
  final Map<String, GroupAttendanceDraft> _drafts = {};
  final GroupWorkspacePersistence? _persistence;
  final DateTime Function() _clock;
  Future<void> _pendingWrite = Future<void>.value();
  Future<void>? _restoreOperation;
  String? _persistenceError;

  String _query = '';
  GroupCategory _category = GroupCategory.all;
  GroupSort _sort = GroupSort.nextLesson;
  int _minimumAttendance = 0;
  bool _todayOnly = false;

  String get query => _query;
  GroupCategory get category => _category;
  GroupSort get sort => _sort;
  int get minimumAttendance => _minimumAttendance;
  bool get todayOnly => _todayOnly;
  List<TeacherGroup> get groups => _groups;
  DateTime get currentDateTime => _clock();
  String? get persistenceError => _persistenceError;

  Future<void> retryPersistence() async {
    _queuePersist();
    await _pendingWrite;
  }

  void clearPersistenceError() {
    if (_persistenceError == null) return;
    _persistenceError = null;
    notifyListeners();
  }

  TeacherGroup group(String id) => _groups.firstWhere(
    (group) => group.id == id,
    orElse: () => throw StateError('Requested group was not found: $id'),
  );

  TeacherGroup? tryGroup(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  GroupLesson? lesson(String groupId, String? lessonId) {
    if (lessonId == null || lessonId.trim().isEmpty) return null;
    final cohort = tryGroup(groupId);
    if (cohort == null) return null;
    for (final lesson in cohort.lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  GroupStudent? student(String? studentId, {String? groupId}) {
    if (studentId == null || studentId.trim().isEmpty) return null;
    final preferred = tryGroup(groupId);
    if (preferred != null) {
      for (final student in preferred.students) {
        if (student.id == studentId) return student;
      }
    }
    for (final group in _groups) {
      for (final student in group.students) {
        if (student.id == studentId) return student;
      }
    }
    return null;
  }

  TeacherGroup? groupForStudent(String? studentId, {String? preferredGroupId}) {
    if (studentId == null || studentId.trim().isEmpty) return null;
    final preferred = tryGroup(preferredGroupId);
    if (preferred != null &&
        preferred.students.any((item) => item.id == studentId)) {
      return preferred;
    }
    for (final group in _groups) {
      if (group.students.any((item) => item.id == studentId)) return group;
    }
    return null;
  }

  void setQuery(String value) {
    final normalized = value.trimLeft();
    if (_query == normalized) return;
    _query = normalized;
    notifyListeners();
  }

  void setCategory(GroupCategory value) {
    if (_category == value) return;
    _category = value;
    notifyListeners();
  }

  void applyFilters({
    required GroupSort sort,
    required int minimumAttendance,
    required bool todayOnly,
  }) {
    _sort = sort;
    _minimumAttendance = minimumAttendance;
    _todayOnly = todayOnly;
    notifyListeners();
  }

  void clearFilters() {
    _minimumAttendance = 0;
    _todayOnly = false;
    _sort = GroupSort.nextLesson;
    notifyListeners();
  }

  List<TeacherGroup> get visibleGroups {
    final needle = _query.trim().toLowerCase();
    final result = _groups.where((group) {
      final categoryMatches = switch (_category) {
        GroupCategory.all => !group.archived,
        GroupCategory.archived => group.archived,
        _ => !group.archived && group.category == _category,
      };
      if (!categoryMatches) return false;
      if (attendanceRate(group.id) < _minimumAttendance) return false;
      if (_todayOnly && !_sameDay(group.nextLesson, _clock())) return false;
      if (needle.isEmpty) return true;
      return group.name.toLowerCase().contains(needle) ||
          group.subject.toLowerCase().contains(needle) ||
          group.level.toLowerCase().contains(needle) ||
          group.students.any(
            (student) => student.name.toLowerCase().contains(needle),
          );
    }).toList();
    switch (_sort) {
      case GroupSort.nextLesson:
        result.sort((a, b) => a.nextLesson.compareTo(b.nextLesson));
      case GroupSort.attendance:
        result.sort(
          (a, b) => attendanceRate(b.id).compareTo(attendanceRate(a.id)),
        );
      case GroupSort.name:
        result.sort((a, b) => a.name.compareTo(b.name));
    }
    return result;
  }

  List<GroupAttendanceRecord> history(
    String groupId, {
    DateTime? start,
    DateTime? end,
    String? lesson,
  }) {
    final normalizedLesson = lesson?.trim().toLowerCase();
    final result = _attendance.where((record) {
      if (record.groupId != groupId) return false;
      if (start != null && record.lessonAt.isBefore(_startOfDay(start))) {
        return false;
      }
      if (end != null && record.lessonAt.isAfter(_endOfDay(end))) return false;
      if (normalizedLesson != null &&
          normalizedLesson.isNotEmpty &&
          normalizedLesson != 'hammasi' &&
          record.lessonTitle.toLowerCase() != normalizedLesson) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.lessonAt.compareTo(a.lessonAt));
    return List.unmodifiable(result);
  }

  double attendanceRate(String groupId, {DateTime? start, DateTime? end}) {
    final records = history(groupId, start: start, end: end);
    if (records.isEmpty) return 0;
    final total = records.fold<int>(0, (sum, row) => sum + row.statuses.length);
    final missed = records.fold<int>(
      0,
      (sum, row) => sum + row.count(AttendanceStatus.absent),
    );
    return (total - missed) / total * 100;
  }

  double studentAttendanceRate(
    String groupId,
    String studentId, {
    DateTime? start,
    DateTime? end,
    String? lesson,
  }) {
    final rows = history(
      groupId,
      start: start,
      end: end,
      lesson: lesson,
    ).where((row) => row.statuses.containsKey(studentId)).toList();
    if (rows.isEmpty) return 0;
    final missed = rows
        .where((row) => row.statuses[studentId] == AttendanceStatus.absent)
        .length;
    return (rows.length - missed) / rows.length * 100;
  }

  GroupAttendanceDraft beginAttendance(
    String groupId, {
    String? lessonId,
    DateTime? lessonAt,
    String? lessonTitle,
  }) {
    final existing = _drafts[groupId];
    if (existing != null) return existing;
    final cohort = group(groupId);
    final selectedLesson =
        lesson(groupId, lessonId) ??
        _closestLesson(cohort, lessonAt ?? _clock());
    final selectedAt = lessonAt ?? selectedLesson?.startsAt ?? _clock();
    final draft = GroupAttendanceDraft(
      groupId: groupId,
      lessonId:
          lessonId ??
          selectedLesson?.id ??
          _customLessonId(groupId, selectedAt),
      lessonTitle: lessonTitle ?? selectedLesson?.topic ?? cohort.subject,
      lessonAt: selectedAt,
      statuses: {for (final student in cohort.students) student.id: null},
    );
    _drafts[groupId] = draft;
    _queuePersist();
    return draft;
  }

  GroupAttendanceDraft? draft(String groupId) => _drafts[groupId];

  void updateDraftContext(
    String groupId, {
    required String lessonId,
    required String lessonTitle,
    required DateTime lessonAt,
  }) {
    final current = beginAttendance(groupId);
    if (current.lessonId == lessonId &&
        current.lessonTitle == lessonTitle &&
        current.lessonAt == lessonAt) {
      return;
    }
    _drafts[groupId] = current.copyWith(
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      lessonAt: lessonAt,
    );
    _queuePersist();
    notifyListeners();
  }

  void markDraft(
    String groupId,
    String studentId,
    AttendanceStatus status, {
    String? note,
  }) {
    final current = beginAttendance(groupId);
    if (!current.statuses.containsKey(studentId)) {
      throw StateError('O‘quvchi bu guruhda topilmadi.');
    }
    final statuses = Map<String, AttendanceStatus?>.of(current.statuses)
      ..[studentId] = status;
    final notes = Map<String, String>.of(current.notes);
    if (note == null || note.trim().isEmpty) {
      notes.remove(studentId);
    } else {
      notes[studentId] = note.trim();
    }
    _drafts[groupId] = current.copyWith(statuses: statuses, notes: notes);
    _queuePersist();
    notifyListeners();
  }

  void markRemainingPresent(String groupId) {
    final current = beginAttendance(groupId);
    final statuses = Map<String, AttendanceStatus?>.of(current.statuses);
    for (final entry in statuses.entries) {
      if (entry.value == null) statuses[entry.key] = AttendanceStatus.present;
    }
    _drafts[groupId] = current.copyWith(statuses: statuses);
    _queuePersist();
    notifyListeners();
  }

  GroupAttendanceRecord submitAttendance(String groupId) {
    final current = beginAttendance(groupId);
    if (!current.isComplete) {
      throw StateError('Barcha o‘quvchilar holatini belgilang.');
    }
    final record = GroupAttendanceRecord(
      id: 'local-$groupId-${current.lessonId}-${current.lessonAt.microsecondsSinceEpoch}',
      groupId: groupId,
      lessonId: current.lessonId,
      lessonTitle: current.lessonTitle,
      lessonAt: current.lessonAt,
      statuses: current.statuses.map((key, value) => MapEntry(key, value!)),
      notes: current.notes,
    );
    _attendance.removeWhere(
      (item) => item.groupId == groupId && item.lessonId == record.lessonId,
    );
    _attendance.add(record);
    _drafts.remove(groupId);
    _queuePersist();
    notifyListeners();
    return record;
  }

  GroupLesson? _closestLesson(TeacherGroup group, DateTime anchor) {
    if (group.lessons.isEmpty) return null;
    final sorted = [...group.lessons]
      ..sort((a, b) {
        final aDistance = a.startsAt.difference(anchor).abs();
        final bDistance = b.startsAt.difference(anchor).abs();
        return aDistance.compareTo(bDistance);
      });
    return sorted.first;
  }

  /// Restores locally-created history and in-progress drafts.
  ///
  /// Corrupt or newer payloads deliberately fall back to the deterministic
  /// seed data so a bad local cache can never prevent the workspace opening.
  Future<void> restore() {
    final existing = _restoreOperation;
    if (existing != null) return existing;
    final operation = _restoreFromDisk();
    _restoreOperation = operation;
    return operation;
  }

  Future<void> _restoreFromDisk() async {
    final persistence = _persistence;
    if (persistence == null) return;
    try {
      final raw = await persistence.read();
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final version = decoded['version'];
      if (version != null && version is! int) return;
      if (version is int && version > _groupStorageVersion) return;

      final attendanceJson = decoded['attendance'] ?? decoded['records'];
      if (attendanceJson is List) {
        for (final value in attendanceJson) {
          final record = _attendanceRecordFromJson(value);
          if (record == null || !_groups.any((g) => g.id == record.groupId)) {
            continue;
          }
          _attendance.removeWhere((item) => item.id == record.id);
          _attendance.add(record);
        }
      }

      final draftsJson = decoded['drafts'];
      if (draftsJson is List) {
        for (final value in draftsJson) {
          final draft = _attendanceDraftFromJson(value);
          if (draft == null || !_groups.any((g) => g.id == draft.groupId)) {
            continue;
          }
          final studentIds = group(
            draft.groupId,
          ).students.map((student) => student.id).toSet();
          if (!draft.statuses.keys.every(studentIds.contains)) continue;
          _drafts.putIfAbsent(draft.groupId, () => draft);
        }
      }
      notifyListeners();
    } on Object catch (error) {
      // Seeded data is the migration/default fallback for malformed caches.
      _persistenceError =
          'Saved attendance could not be read. Seeded data is shown: $error';
      notifyListeners();
    }
  }

  void _queuePersist() {
    final persistence = _persistence;
    if (persistence == null) return;
    final restore = _restoreOperation ?? Future<void>.value();
    _pendingWrite = _pendingWrite.then((_) => restore).then((_) async {
      try {
        await persistence.write(_encodePersistence());
        if (_persistenceError != null) {
          _persistenceError = null;
          notifyListeners();
        }
      } on Object catch (error) {
        _persistenceError =
            'Attendance changes could not be saved on this device: $error';
        notifyListeners();
      }
    });
  }

  String _encodePersistence() => jsonEncode({
    'version': _groupStorageVersion,
    'attendance': _attendance
        .where((record) => record.id.startsWith('local-'))
        .map(_attendanceRecordToJson)
        .toList(),
    'drafts': _drafts.values.map(_attendanceDraftToJson).toList(),
  });

  /// Completes after all queued local writes have reached device storage.
  Future<void> flushPersistence() => _pendingWrite;

  static DateTime windowStart(AttendanceWindow window, {DateTime? now}) {
    final anchor = now ?? DateTime.now();
    return switch (window) {
      AttendanceWindow.sevenDays => anchor.subtract(const Duration(days: 6)),
      AttendanceWindow.thirtyDays => anchor.subtract(const Duration(days: 29)),
      AttendanceWindow.term => DateTime(anchor.year, 1, 1),
      AttendanceWindow.custom => anchor,
    };
  }
}

final groupWorkspaceStore = _createGroupWorkspaceStore();

GroupWorkspaceStore _createGroupWorkspaceStore() {
  final store = GroupWorkspaceStore.seeded(
    persistence: SharedPreferencesGroupWorkspacePersistence(),
  );
  unawaited(store.restore());
  return store;
}

abstract interface class GroupWorkspacePersistence {
  Future<String?> read();
  Future<void> write(String payload);
}

class SharedPreferencesGroupWorkspacePersistence
    implements GroupWorkspacePersistence {
  const SharedPreferencesGroupWorkspacePersistence();

  @override
  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_groupStorageKey);
  }

  @override
  Future<void> write(String payload) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_groupStorageKey, payload);
    if (!saved) throw StateError('Could not persist group attendance.');
  }
}

const _groupStorageVersion = 2;
const _groupStorageKey = 'starforge.group_workspace.v1';

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _customLessonId(String groupId, DateTime lessonAt) =>
    '$groupId-custom-${lessonAt.microsecondsSinceEpoch}';

Map<String, Object?> _attendanceRecordToJson(GroupAttendanceRecord record) => {
  'id': record.id,
  'groupId': record.groupId,
  'lessonId': record.lessonId,
  'lessonTitle': record.lessonTitle,
  'lessonAt': record.lessonAt.toUtc().toIso8601String(),
  'statuses': record.statuses.map(
    (studentId, status) => MapEntry(studentId, status.name),
  ),
  'notes': record.notes,
};

GroupAttendanceRecord? _attendanceRecordFromJson(Object? value) {
  if (value is! Map) return null;
  try {
    final json = Map<String, dynamic>.from(value);
    final statusesJson = Map<String, dynamic>.from(json['statuses'] as Map);
    final notesJson = json['notes'] is Map
        ? Map<String, dynamic>.from(json['notes'] as Map)
        : const <String, dynamic>{};
    final id = json['id'] as String;
    final groupId = json['groupId'] as String;
    return GroupAttendanceRecord(
      id: id,
      groupId: groupId,
      lessonId: json['lessonId'] as String? ?? 'legacy-$id',
      lessonTitle: json['lessonTitle'] as String,
      lessonAt: DateTime.parse(json['lessonAt'] as String).toLocal(),
      statuses: statusesJson.map(
        (studentId, status) => MapEntry(
          studentId,
          AttendanceStatus.values.byName(status as String),
        ),
      ),
      notes: notesJson.map(
        (studentId, note) => MapEntry(studentId, note as String),
      ),
    );
  } on Object {
    return null;
  }
}

Map<String, Object?> _attendanceDraftToJson(GroupAttendanceDraft draft) => {
  'groupId': draft.groupId,
  'lessonId': draft.lessonId,
  'lessonTitle': draft.lessonTitle,
  'lessonAt': draft.lessonAt.toUtc().toIso8601String(),
  'statuses': draft.statuses.map(
    (studentId, status) => MapEntry(studentId, status?.name),
  ),
  'notes': draft.notes,
};

GroupAttendanceDraft? _attendanceDraftFromJson(Object? value) {
  if (value is! Map) return null;
  try {
    final json = Map<String, dynamic>.from(value);
    final statusesJson = Map<String, dynamic>.from(json['statuses'] as Map);
    final notesJson = json['notes'] is Map
        ? Map<String, dynamic>.from(json['notes'] as Map)
        : const <String, dynamic>{};
    final groupId = json['groupId'] as String;
    final lessonAt = DateTime.parse(json['lessonAt'] as String).toLocal();
    return GroupAttendanceDraft(
      groupId: groupId,
      lessonId:
          json['lessonId'] as String? ?? _customLessonId(groupId, lessonAt),
      lessonTitle: json['lessonTitle'] as String,
      lessonAt: lessonAt,
      statuses: statusesJson.map(
        (studentId, status) => MapEntry(
          studentId,
          status == null
              ? null
              : AttendanceStatus.values.byName(status as String),
        ),
      ),
      notes: notesJson.map(
        (studentId, note) => MapEntry(studentId, note as String),
      ),
    );
  } on Object {
    return null;
  }
}

List<TeacherGroup> _seedGroups(DateTime now) {
  final anchor = DateTime(now.year, now.month, now.day, 10, 30);
  final sharedStudents = <GroupStudent>[
    const GroupStudent(
      id: 'DEMO-2026-00042',
      name: 'Akbarov Akmal',
      phone: '+998 90 120 42 42',
      upCards: 8,
      downCards: 0,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00043',
      name: 'Azizova Madina',
      phone: '+998 90 120 43 43',
      upCards: 6,
      downCards: 0,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00044',
      name: 'Bakirov Sherzod',
      phone: '+998 90 120 44 44',
      upCards: 2,
      downCards: 2,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00045',
      name: 'Davronova Sevinch',
      phone: '+998 90 120 45 45',
      upCards: 4,
      downCards: 0,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00046',
      name: 'Eshmatov Otabek',
      phone: '+998 90 120 46 46',
      upCards: 1,
      downCards: 4,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00047',
      name: 'Fayzullayev Diyor',
      phone: '+998 90 120 47 47',
      upCards: 5,
      downCards: 1,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00048',
      name: 'G‘aniyev Jasur',
      phone: '+998 90 120 48 48',
      upCards: 3,
      downCards: 1,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00049',
      name: 'Halimova Zilola',
      phone: '+998 90 120 49 49',
      upCards: 7,
      downCards: 0,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00050',
      name: 'Ibragimov Sardor',
      phone: '+998 90 120 50 50',
      upCards: 3,
      downCards: 0,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00051',
      name: 'Jo‘rayeva Nilufar',
      phone: '+998 90 120 51 51',
      upCards: 6,
      downCards: 0,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00052',
      name: 'Karimov Rustam',
      phone: '+998 90 120 52 52',
      upCards: 2,
      downCards: 1,
    ),
    const GroupStudent(
      id: 'DEMO-2026-00053',
      name: 'Latipova Shahnoza',
      phone: '+998 90 120 53 53',
      upCards: 4,
      downCards: 0,
    ),
  ];

  List<GroupStudent> rotated(int shift, int count) => [
    for (var i = 0; i < count; i++)
      sharedStudents[(i + shift) % sharedStudents.length],
  ];

  List<GroupLesson> lessons(String prefix, String subject, int hour) => [
    for (var i = 0; i < 5; i++)
      GroupLesson(
        id: '$prefix-lesson-$i',
        title: subject,
        topic: const [
          'Tenglamalar sistemasi',
          'Mustaqil ish va tahlil',
          'Funksiya grafigi',
          'Nazorat ishi',
          'Xatolar ustida ishlash',
        ][i],
        startsAt: anchor.add(Duration(days: i * 2, hours: hour - 10)),
        room: '${304 + i % 2}',
      ),
  ];

  return [
    TeacherGroup(
      id: 'cohort-9b-algebra',
      name: '9-B Algebra',
      subject: 'Algebra',
      level: 'Daraja II',
      room: '304',
      teacher: 'Nigora Karimova',
      nextLesson: DateTime(anchor.year, anchor.month, anchor.day, 11),
      category: GroupCategory.algebra,
      students: rotated(0, 12),
      lessons: lessons('9b', 'Algebra', 11),
      trend: const [88, 92, 90, 95, 93, 96, 94, 97],
    ),
    TeacherGroup(
      id: 'cohort-9a-algebra',
      name: '9-A Algebra',
      subject: 'Algebra',
      level: 'Daraja II',
      room: '302',
      teacher: 'Nigora Karimova',
      nextLesson: DateTime(anchor.year, anchor.month, anchor.day, 13, 30),
      category: GroupCategory.algebra,
      students: rotated(2, 10),
      lessons: lessons('9a', 'Algebra', 13),
      trend: const [86, 89, 92, 91, 90, 94, 93, 92],
    ),
    TeacherGroup(
      id: 'cohort-10v-geometry',
      name: '10-V Geometriya',
      subject: 'Geometriya',
      level: 'Daraja III',
      room: '208',
      teacher: 'Nigora Karimova',
      nextLesson: DateTime(anchor.year, anchor.month, anchor.day + 1, 9),
      category: GroupCategory.geometry,
      students: rotated(4, 9),
      lessons: lessons('10v', 'Geometriya', 9),
      trend: const [94, 92, 91, 89, 87, 88, 86, 88],
    ),
    TeacherGroup(
      id: 'cohort-11b-exam',
      name: '11-B Tayyorlov',
      subject: 'DTM tayyorlov',
      level: 'Imtihon',
      room: '401',
      teacher: 'Nigora Karimova',
      nextLesson: DateTime(anchor.year, anchor.month, anchor.day + 2, 15),
      category: GroupCategory.examPrep,
      students: rotated(1, 8),
      lessons: lessons('11b', 'DTM tayyorlov', 15),
      trend: const [91, 93, 96, 95, 97, 96, 98, 97],
    ),
    TeacherGroup(
      id: 'cohort-8a-algebra',
      name: '8-A Algebra',
      subject: 'Algebra',
      level: 'Daraja I',
      room: '205',
      teacher: 'Nigora Karimova',
      nextLesson: DateTime(anchor.year, anchor.month, anchor.day + 3, 8, 30),
      category: GroupCategory.algebra,
      students: rotated(3, 11),
      lessons: lessons('8a', 'Algebra', 8),
      trend: const [84, 86, 85, 88, 90, 89, 91, 90],
    ),
    TeacherGroup(
      id: 'cohort-7g-archive',
      name: '7-G Algebra',
      subject: 'Algebra',
      level: 'Yakunlangan',
      room: '—',
      teacher: 'Nigora Karimova',
      nextLesson: anchor.subtract(const Duration(days: 51, minutes: 30)),
      category: GroupCategory.algebra,
      students: rotated(0, 8),
      lessons: const [],
      trend: const [91, 92, 94, 93, 95, 96, 96, 97],
      archived: true,
    ),
  ];
}

List<GroupAttendanceRecord> _seedAttendance(
  List<TeacherGroup> groups,
  DateTime now,
) {
  final result = <GroupAttendanceRecord>[];
  for (final group in groups) {
    for (var lesson = 0; lesson < 18; lesson++) {
      final at = now.subtract(Duration(days: lesson * 4 + 1));
      final statuses = <String, AttendanceStatus>{};
      for (var student = 0; student < group.students.length; student++) {
        final signal = (lesson * 3 + student * 5 + group.name.length) % 23;
        statuses[group.students[student].id] = signal == 0 || signal == 7
            ? AttendanceStatus.absent
            : signal == 3
            ? AttendanceStatus.late
            : signal == 11
            ? AttendanceStatus.excused
            : AttendanceStatus.present;
      }
      result.add(
        GroupAttendanceRecord(
          id: '${group.id}-history-$lesson',
          groupId: group.id,
          lessonId: '${group.id}-history-lesson-$lesson',
          lessonTitle: lesson % 5 == 3 ? 'Nazorat ishi' : group.subject,
          lessonAt: DateTime(at.year, at.month, at.day, 10 + lesson % 4),
          statuses: statuses,
        ),
      );
    }
  }
  return result;
}
