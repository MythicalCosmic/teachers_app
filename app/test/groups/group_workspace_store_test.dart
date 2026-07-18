import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/screens/groups/group_workspace_store.dart';

DateTime _testNow() => DateTime(2026, 7, 18, 10, 30);

GroupWorkspaceStore _seeded({GroupWorkspacePersistence? persistence}) =>
    GroupWorkspaceStore.seeded(persistence: persistence, now: _testNow);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('group list search and filters', () {
    late GroupWorkspaceStore store;

    setUp(() => store = _seeded());

    test('searches by group and student, then clears cleanly', () {
      expect(store.visibleGroups, hasLength(5));

      store.setQuery('10-V');
      expect(store.visibleGroups.map((group) => group.id), [
        'cohort-10v-geometry',
      ]);

      store.setQuery('Latipova Shahnoza');
      expect(store.visibleGroups, isNotEmpty);
      expect(
        store.visibleGroups.every(
          (group) => group.students.any(
            (student) => student.name == 'Latipova Shahnoza',
          ),
        ),
        isTrue,
      );

      store.setQuery('');
      expect(store.visibleGroups, hasLength(5));
    });

    test('category, today and sort controls change the result', () {
      store.setCategory(GroupCategory.geometry);
      expect(store.visibleGroups, hasLength(1));
      expect(store.visibleGroups.single.subject, 'Geometriya');

      store.setCategory(GroupCategory.all);
      store.applyFilters(
        sort: GroupSort.name,
        minimumAttendance: 0,
        todayOnly: true,
      );
      expect(store.visibleGroups, hasLength(2));
      expect(store.visibleGroups.map((group) => group.name).toList(), [
        '9-A Algebra',
        '9-B Algebra',
      ]);

      store.setCategory(GroupCategory.archived);
      store.applyFilters(
        sort: GroupSort.nextLesson,
        minimumAttendance: 0,
        todayOnly: false,
      );
      expect(store.visibleGroups.single.archived, isTrue);
    });
  });

  group('group attendance capture', () {
    test('marks every student, submits and retains the new history record', () {
      final store = _seeded();
      const groupId = 'cohort-9b-algebra';
      final group = store.group(groupId);
      final previousHistory = store.history(groupId).length;
      final draft = store.beginAttendance(
        groupId,
        lessonAt: DateTime(2026, 7, 18, 11),
      );

      expect(draft.markedCount, 0);
      store.markDraft(
        groupId,
        group.students.first.id,
        AttendanceStatus.absent,
        note: 'Shifokor ma’lumotnomasi',
      );
      store.markDraft(groupId, group.students[1].id, AttendanceStatus.late);
      store.markRemainingPresent(groupId);

      expect(store.draft(groupId)!.isComplete, isTrue);
      final submitted = store.submitAttendance(groupId);

      expect(store.draft(groupId), isNull);
      expect(store.history(groupId), hasLength(previousHistory + 1));
      expect(
        submitted.statuses[group.students.first.id],
        AttendanceStatus.absent,
      );
      expect(
        submitted.notes[group.students.first.id],
        'Shifokor ma’lumotnomasi',
      );
      expect(submitted.statuses[group.students[1].id], AttendanceStatus.late);
    });

    test('refuses to submit an incomplete sheet', () {
      final store = _seeded();
      const groupId = 'cohort-9b-algebra';
      store.beginAttendance(groupId);

      expect(() => store.submitAttendance(groupId), throwsA(isA<StateError>()));
    });

    test('keeps two different lessons captured on the same day', () {
      final store = _seeded();
      const groupId = 'cohort-9b-algebra';
      final group = store.group(groupId);
      final lessons = group.lessons.take(2).toList();
      final day = DateTime(2026, 7, 18);

      store.beginAttendance(
        groupId,
        lessonId: lessons.first.id,
        lessonTitle: lessons.first.topic,
        lessonAt: DateTime(day.year, day.month, day.day, 9),
      );
      store.markRemainingPresent(groupId);
      final first = store.submitAttendance(groupId);

      store.beginAttendance(
        groupId,
        lessonId: lessons.last.id,
        lessonTitle: lessons.last.topic,
        lessonAt: DateTime(day.year, day.month, day.day, 14),
      );
      store.markRemainingPresent(groupId);
      final second = store.submitAttendance(groupId);

      final local = store
          .history(groupId, start: day, end: day)
          .where((record) => record.id.startsWith('local-'))
          .toList();
      expect(local, hasLength(2));
      expect(local.map((record) => record.lessonId), {
        first.lessonId,
        second.lessonId,
      });
    });
  });

  group('attendance history filters', () {
    test('filters by date presets and lesson type', () {
      final store = _seeded();
      const groupId = 'cohort-9b-algebra';
      final all = store.history(groupId);
      final latest = all.first.lessonAt;

      expect(all, hasLength(18));

      final sevenDays = store.history(
        groupId,
        start: GroupWorkspaceStore.windowStart(
          AttendanceWindow.sevenDays,
          now: latest,
        ),
        end: latest,
      );
      expect(sevenDays, hasLength(2));

      final lastMonth = store.history(
        groupId,
        start: GroupWorkspaceStore.windowStart(
          AttendanceWindow.thirtyDays,
          now: latest,
        ),
        end: latest,
      );
      expect(lastMonth.length, greaterThan(sevenDays.length));
      expect(lastMonth.length, lessThan(all.length));

      final assessments = store.history(groupId, lesson: 'Nazorat ishi');
      expect(assessments, isNotEmpty);
      expect(
        assessments.every((record) => record.lessonTitle == 'Nazorat ishi'),
        isTrue,
      );
    });

    test('uses inclusive custom start and end dates', () {
      final store = _seeded();
      const groupId = 'cohort-9b-algebra';
      final records = store.history(groupId);
      final target = records[4];

      final selected = store.history(
        groupId,
        start: target.lessonAt,
        end: target.lessonAt,
      );

      expect(selected, hasLength(1));
      expect(selected.single.id, target.id);
    });
  });

  group('attendance persistence', () {
    test('draft and submitted history survive a full store restart', () async {
      SharedPreferences.setMockInitialValues({});
      const persistence = SharedPreferencesGroupWorkspacePersistence();
      const groupId = 'cohort-9b-algebra';

      final firstRun = _seeded(persistence: persistence);
      await firstRun.restore();
      final students = firstRun.group(groupId).students;
      firstRun.beginAttendance(groupId, lessonAt: DateTime(2026, 7, 18, 11));
      firstRun.markDraft(
        groupId,
        students.first.id,
        AttendanceStatus.absent,
        note: 'Doctor note',
      );
      firstRun.markDraft(groupId, students[1].id, AttendanceStatus.late);
      await firstRun.flushPersistence();

      final afterDraftRestart = _seeded(persistence: persistence);
      await afterDraftRestart.restore();
      final restoredDraft = afterDraftRestart.draft(groupId)!;
      expect(
        restoredDraft.statuses[students.first.id],
        AttendanceStatus.absent,
      );
      expect(restoredDraft.notes[students.first.id], 'Doctor note');
      expect(restoredDraft.statuses[students[1].id], AttendanceStatus.late);

      afterDraftRestart.markRemainingPresent(groupId);
      final submitted = afterDraftRestart.submitAttendance(groupId);
      await afterDraftRestart.flushPersistence();

      final afterSubmitRestart = _seeded(persistence: persistence);
      await afterSubmitRestart.restore();
      expect(afterSubmitRestart.draft(groupId), isNull);
      expect(
        afterSubmitRestart.history(groupId).map((record) => record.id),
        contains(submitted.id),
      );
      final restoredRecord = afterSubmitRestart
          .history(groupId)
          .firstWhere((record) => record.id == submitted.id);
      expect(
        restoredRecord.statuses[students.first.id],
        AttendanceStatus.absent,
      );
      expect(restoredRecord.notes[students.first.id], 'Doctor note');
    });

    test('malformed or future cache falls back to seeded data', () async {
      const persistence = SharedPreferencesGroupWorkspacePersistence();

      SharedPreferences.setMockInitialValues({
        'starforge.group_workspace.v1': '{not-json',
      });
      final malformed = _seeded(persistence: persistence);
      await malformed.restore();
      expect(malformed.history('cohort-9b-algebra'), hasLength(18));
      expect(malformed.draft('cohort-9b-algebra'), isNull);

      SharedPreferences.setMockInitialValues({
        'starforge.group_workspace.v1':
            '{"version":99,"attendance":[],"drafts":[]}',
      });
      final futureVersion = _seeded(persistence: persistence);
      await futureVersion.restore();
      expect(futureVersion.history('cohort-9b-algebra'), hasLength(18));
      expect(futureVersion.draft('cohort-9b-algebra'), isNull);
    });
  });

  test(
    'today filters and default attendance follow the injected device date',
    () {
      final now = DateTime(2031, 2, 7, 8, 15);
      final store = GroupWorkspaceStore.seeded(now: () => now);

      store.applyFilters(
        sort: GroupSort.nextLesson,
        minimumAttendance: 0,
        todayOnly: true,
      );

      expect(store.visibleGroups, hasLength(2));
      expect(
        store.visibleGroups.every(
          (group) => DateUtils.isSameDay(group.nextLesson, now),
        ),
        isTrue,
      );
      expect(
        DateUtils.isSameDay(
          store.beginAttendance('cohort-9b-algebra').lessonAt,
          now,
        ),
        isTrue,
      );
    },
  );
}
