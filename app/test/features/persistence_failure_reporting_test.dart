import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_staff/app/app_state.dart';
import 'package:starforge_staff/data/app_storage.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/features/messaging/messaging_storage.dart';
import 'package:starforge_staff/main.dart';
import 'package:starforge_staff/screens/groups/group_workspace_store.dart';

class _FailingAppStorage implements AppStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> remove(String key) async => throw StateError('disk unavailable');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('disk unavailable');
}

class _FailingMessagingStorage implements MessagingStorage {
  @override
  Future<String?> read(String userId) async => null;

  @override
  Future<void> write(String userId, String value) async =>
      throw StateError('message disk unavailable');
}

class _FailingGroupStorage implements GroupWorkspacePersistence {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String payload) async =>
      throw StateError('attendance disk unavailable');
}

void main() {
  testWidgets('app persistence failure is visible and dismissible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = (await tester.runAsync(
      () => AppState.bootstrap(storage: _FailingAppStorage()),
    ))!;
    await tester.runAsync(
      () => state.signIn(username: 'nigora.karimova', password: 'demo2026'),
    );
    expect(state.persistenceError, isNotNull);

    await tester.pumpWidget(StarForgeStaffApp(appState: state));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.text('Qayta urinish'), findsOneWidget);

    await tester.tap(find.byKey(const Key('persistence-error-dismiss')));
    await tester.pump();
    expect(state.persistenceError, isNull);
    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
  });

  test('messaging persistence failure remains observable', () async {
    final controller = MessagingController(storage: _FailingMessagingStorage());
    controller.initialize(
      userId: 'staff-teacher-001',
      userName: 'Nigora Karimova',
      sourceThreads: const [],
    );
    await controller.restored;
    controller.toggleMuted([controller.threads.first.id]);
    await controller.flushPersistence();
    expect(controller.persistenceError, contains('could not be saved'));
    controller.clearPersistenceError();
    expect(controller.persistenceError, isNull);
  });

  test('group attendance persistence failure remains observable', () async {
    final store = GroupWorkspaceStore.seeded(
      persistence: _FailingGroupStorage(),
      now: () => DateTime(2026, 7, 18, 10),
    );
    await store.restore();
    final group = store.groups.first;
    store.beginAttendance(group.id);
    store.markRemainingPresent(group.id);
    await store.flushPersistence();
    expect(store.persistenceError, contains('could not be saved'));
    store.clearPersistenceError();
    expect(store.persistenceError, isNull);
  });
}
