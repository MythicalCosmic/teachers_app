import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/data/models.dart';

void main() {
  group('StaffTask collaboration JSON persistence', () {
    test('tags, comments, and favorite survive a model round trip', () {
      final task = StaffTask(
        id: 'task-collaboration',
        title: 'Ochiq dars rejasini yakunlash',
        description: 'Metodist bilan yakuniy tekshiruv',
        status: TaskStatus.inReview,
        priority: TaskPriority.high,
        creatorId: 'staff-teacher-001',
        creatorName: 'Nigora Karimova',
        assigneeId: 'staff-teacher-001',
        assigneeName: 'Nigora Karimova',
        dueAt: DateTime.utc(2026, 7, 20, 15),
        createdAt: DateTime.utc(2026, 7, 18, 9),
        checklist: const [],
        tags: const ['Metodika', '9-B'],
        comments: [
          TaskComment(
            id: 'comment-1',
            authorId: 'staff-methodist-001',
            authorName: 'Ra’no Karimova',
            body: 'Baholash mezonlarini ham qo‘shing.',
            createdAt: DateTime.utc(2026, 7, 18, 10, 30),
          ),
        ],
        isFavorite: true,
      );

      final restored = StaffTask.fromJson(task.toJson());

      expect(restored.tags, ['Metodika', '9-B']);
      expect(restored.comments, hasLength(1));
      expect(restored.comments.single.authorName, 'Ra’no Karimova');
      expect(
        restored.comments.single.body,
        'Baholash mezonlarini ham qo‘shing.',
      );
      expect(
        restored.comments.single.createdAt,
        DateTime.utc(2026, 7, 18, 10, 30),
      );
      expect(restored.isFavorite, isTrue);
    });

    test('legacy task JSON migrates missing collaboration fields', () {
      final task = StaffTask.fromJson({
        'id': 'legacy-task',
        'title': 'Legacy vazifa',
        'description': '',
        'status': 'todo',
        'priority': 'medium',
        'creatorId': 'staff-teacher-001',
        'creatorName': 'Nigora Karimova',
        'assigneeId': 'staff-teacher-001',
        'assigneeName': 'Nigora Karimova',
        'dueAt': '2026-07-20T12:00:00.000Z',
        'createdAt': '2026-07-18T12:00:00.000Z',
        'checklist': const [],
      });

      expect(task.tags, isEmpty);
      expect(task.comments, isEmpty);
      expect(task.isFavorite, isFalse);
    });
  });

  group('AppState task collaboration methods', () {
    test(
      'tag, comment, and favorite mutations persist across restart',
      () async {
        final storage = MemoryAppStorage();
        final state = await AppState.bootstrap(
          storage: storage,
          clock: () => DateTime.utc(2026, 7, 18, 12),
        );
        await state.signIn(username: 'nigora.karimova', password: 'demo2026');
        final task = await state.createTask(
          title: 'Haftalik dars refleksiyasi',
          tags: const ['Refleksiya'],
        );

        await state.addTaskTag(task.id, '  Muhim  ');
        await state.addTaskTag(task.id, 'muhim');
        await state.removeTaskTag(task.id, 'Refleksiya');
        await state.addTaskComment(task.id, '  Reja metodistga yuborildi.  ');
        await state.toggleTaskFavorite(task.id);

        final changed = state.tasks.firstWhere((item) => item.id == task.id);
        expect(changed.tags, ['Muhim']);
        expect(changed.comments, hasLength(1));
        expect(changed.comments.single.authorId, state.session!.userId);
        expect(changed.comments.single.authorName, state.session!.displayName);
        expect(changed.comments.single.body, 'Reja metodistga yuborildi.');
        expect(
          changed.comments.single.createdAt,
          DateTime.utc(2026, 7, 18, 12),
        );
        expect(changed.isFavorite, isTrue);

        final restored = await AppState.bootstrap(storage: storage);
        final persisted = restored.tasks.firstWhere(
          (item) => item.id == task.id,
        );
        expect(persisted.tags, ['Muhim']);
        expect(persisted.comments, hasLength(1));
        expect(persisted.comments.single.body, 'Reja metodistga yuborildi.');
        expect(persisted.isFavorite, isTrue);
      },
    );

    test(
      'empty comments are rejected and favorite can be toggled back',
      () async {
        final state = await AppState.bootstrap(storage: MemoryAppStorage());
        await state.signIn(username: 'nigora.karimova', password: 'demo2026');
        final task = await state.createTask(title: 'Izoh tekshiruvi');

        await expectLater(
          state.addTaskComment(task.id, '   '),
          throwsArgumentError,
        );
        await state.toggleTaskFavorite(task.id);
        await state.toggleTaskFavorite(task.id);

        final unchanged = state.tasks.firstWhere((item) => item.id == task.id);
        expect(unchanged.comments, isEmpty);
        expect(unchanged.isFavorite, isFalse);
      },
    );

    test('checklist reorder persists across restart', () async {
      final storage = MemoryAppStorage();
      final state = await AppState.bootstrap(storage: storage);
      await state.signIn(username: 'nigora.karimova', password: 'demo2026');
      final task = await state.createTask(
        title: 'Dars sahifasini tayyorlash',
        checklist: const ['Reja', 'Material', 'Refleksiya'],
      );

      await state.reorderTaskChecklist(task.id, 0, 2);
      expect(
        state.tasks
            .firstWhere((item) => item.id == task.id)
            .checklist
            .map((item) => item.title),
        ['Material', 'Refleksiya', 'Reja'],
      );

      final restored = await AppState.bootstrap(storage: storage);
      expect(
        restored.tasks
            .firstWhere((item) => item.id == task.id)
            .checklist
            .map((item) => item.title),
        ['Material', 'Refleksiya', 'Reja'],
      );
    });

    test('staff can update only tasks they own or created', () async {
      final state = await AppState.bootstrap(storage: MemoryAppStorage());
      await state.signIn(username: 'sardor.aliyev', password: 'demo2026');

      final teacherTask = state.tasks.firstWhere(
        (task) => task.assigneeId == 'staff-teacher-001',
      );
      final originalStatus = teacherTask.status;
      expect(state.canUpdateTask(teacherTask), isFalse);
      await expectLater(
        state.setTaskStatus(teacherTask.id, TaskStatus.done),
        throwsStateError,
      );
      expect(
        state.tasks.firstWhere((task) => task.id == teacherTask.id).status,
        originalStatus,
      );
      await expectLater(
        state.createTask(
          title: 'Unauthorized assignment',
          assigneeId: 'staff-teacher-001',
          assigneeName: 'Nigora Karimova',
        ),
        throwsStateError,
      );

      final ownTask = await state.createTask(title: 'Assistant follow-up');
      expect(state.canUpdateTask(ownTask), isTrue);
      await state.setTaskStatus(ownTask.id, TaskStatus.inProgress);
      expect(
        state.tasks.firstWhere((task) => task.id == ownTask.id).status,
        TaskStatus.inProgress,
      );
    });
  });
}
