import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/models.dart';
import 'package:starforge_staff/features/messaging/messaging_controller.dart';
import 'package:starforge_staff/features/messaging/messaging_models.dart';
import 'package:starforge_staff/features/messaging/messaging_storage.dart';
import 'package:starforge_staff/features/messaging/messaging_widgets.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

MessageThread _sourceThread() => MessageThread(
  id: 'thread-1',
  title: 'Metodika jamoasi',
  participantIds: const {'staff-teacher-001', 'staff-methodist-001'},
  messages: [
    ChatMessage(
      id: 'legacy-1',
      senderId: 'staff-methodist-001',
      senderName: 'Ra’no Karimova',
      body: 'Ochiq dars rejasi tayyormi?',
      sentAt: DateTime(2026, 7, 18, 9),
      readBy: const {'staff-methodist-001'},
    ),
  ],
);

Future<MessagingController> _controller() async {
  final controller = MessagingController(clock: () => DateTime(2026, 7, 18));
  controller.initialize(
    userId: 'staff-teacher-001',
    userName: 'Nigora Karimova',
    sourceThreads: [_sourceThread()],
  );
  await controller.restored;
  return controller;
}

class _DelayedReadStorage implements MessagingStorage {
  _DelayedReadStorage(this.value);

  final String? value;
  final Completer<String?> _read = Completer<String?>();
  final List<String> writes = [];

  void completeRead() => _read.complete(value);

  @override
  Future<String?> read(String userId) => _read.future;

  @override
  Future<void> write(String userId, String value) async {
    writes.add(value);
  }
}

void main() {
  group('MessagingController', () {
    test(
      'archive, read, pin, mute, folders, delete and undo mutate state',
      () async {
        final controller = await _controller();
        const id = 'thread-1';

        expect(controller.unreadCount, 1);
        controller.markRead([id]);
        controller.togglePinned([id]);
        controller.toggleMuted([id]);
        final folder = controller.createFolder('9-B');
        controller.setFolder(id, folder.id, included: true);

        final updated = controller.threadById(id)!;
        expect(updated.isRead, isTrue);
        expect(updated.isPinned, isTrue);
        expect(updated.isMuted, isTrue);
        expect(updated.folderIds, contains(folder.id));
        expect(controller.visibleThreads(folderId: folder.id), hasLength(1));

        controller.setArchived([id], true);
        expect(controller.visibleThreads(), isEmpty);
        expect(controller.visibleThreads(archived: true), hasLength(1));

        final deleted = controller.deleteThreads([id]);
        expect(controller.threads, isEmpty);
        controller.restoreThreads(deleted);
        expect(controller.threadById(id), isNotNull);
      },
    );

    test('text, image, video, voice and reactions are functional', () async {
      final controller = await _controller();

      final text = await controller.sendText('thread-1', 'Salom!');
      final image = await controller.sendImage('thread-1', label: 'Dars.jpg');
      await controller.sendVideo(
        'thread-1',
        label: 'Lavha.mp4',
        duration: const Duration(seconds: 59),
      );
      await controller.sendVoice(
        'thread-1',
        duration: const Duration(seconds: 4),
      );
      controller.react('thread-1', text.id, '👍');

      final thread = controller.threadById('thread-1')!;
      expect(thread.messages, hasLength(5));
      expect(thread.messages[1].delivery, MessagingDelivery.delivered);
      expect(text.delivery, MessagingDelivery.delivered);
      expect(image.isDemoMedia, isTrue);
      expect(thread.messages[1].reactions['👍'], 1);
      expect(thread.messages.last.kind, MessagingKind.voice);
      expect(
        () => controller.sendVideo(
          'thread-1',
          label: 'Uzun.mp4',
          duration: const Duration(seconds: 61),
        ),
        throwsArgumentError,
      );
    });

    test(
      'new direct conversation and searchable content are real state',
      () async {
        final controller = await _controller();
        final contact = controller.contacts.firstWhere(
          (item) => item.id == 'staff-assistant-001',
        );
        final thread = controller.createOrOpenDirectThread(contact.id);
        await controller.sendText(thread.id, 'Laboratoriya tayyor');

        expect(controller.visibleThreads(query: 'laboratoriya'), hasLength(1));
        expect(controller.createOrOpenDirectThread(contact.id).id, thread.id);
      },
    );

    test(
      'conversation organization and created chats survive restart',
      () async {
        final storage = MemoryMessagingStorage();
        final first = MessagingController(
          storage: storage,
          clock: () => DateTime(2026, 7, 18, 12),
        );
        first.initialize(
          userId: 'staff-teacher-001',
          userName: 'Nigora Karimova',
          sourceThreads: [_sourceThread()],
        );
        await first.restored;

        final folder = first.createFolder('9-B ishlar');
        first.setFolder('thread-1', folder.id, included: true);
        first.setArchived(['thread-1'], true);
        first.togglePinned(['thread-1']);
        first.toggleMuted(['thread-1']);
        final assistant = first.createOrOpenDirectThread('staff-assistant-001');
        await first.sendText(assistant.id, 'Yangi suhbat saqlansin');
        final deleted = first.createOrOpenDirectThread('staff-reception-001');
        first.deleteThreads([deleted.id]);
        await first.flushPersistence();

        final restarted = MessagingController(
          storage: storage,
          clock: () => DateTime(2026, 7, 18, 13),
        );
        restarted.initialize(
          userId: 'staff-teacher-001',
          userName: 'Nigora Karimova',
          sourceThreads: [_sourceThread()],
        );
        await restarted.restored;

        final organized = restarted.threadById('thread-1')!;
        expect(organized.isArchived, isTrue);
        expect(organized.isPinned, isTrue);
        expect(organized.isMuted, isTrue);
        expect(organized.folderIds, contains(folder.id));
        expect(
          restarted.folders.map((item) => item.name),
          contains('9-B ishlar'),
        );
        expect(
          restarted.threadById(assistant.id)?.messages.last.body,
          'Yangi suhbat saqlansin',
        );
        expect(restarted.threadById(deleted.id), isNull);
      },
    );

    test('corrupt persisted data falls back to seeded conversations', () async {
      final storage = MemoryMessagingStorage({
        'staff-teacher-001': '{not valid json',
      });
      final controller = MessagingController(storage: storage);
      controller.initialize(
        userId: 'staff-teacher-001',
        userName: 'Nigora Karimova',
        sourceThreads: [_sourceThread()],
      );

      await controller.restored;
      await controller.flushPersistence();

      expect(controller.threadById('thread-1'), isNotNull);
      expect(storage.values['staff-teacher-001'], contains('"version":1'));
    });

    test(
      'blocks mutations until delayed restore completes without overwriting',
      () async {
        final originalStorage = MemoryMessagingStorage();
        final original = MessagingController(storage: originalStorage);
        original.initialize(
          userId: 'staff-teacher-001',
          userName: 'Nigora Karimova',
          sourceThreads: [_sourceThread()],
        );
        await original.restored;
        original.toggleMuted(['thread-1']);
        final folder = original.createFolder('Persisted folder');
        original.setFolder('thread-1', folder.id, included: true);
        await original.flushPersistence();

        final delayed = _DelayedReadStorage(
          originalStorage.values['staff-teacher-001'],
        );
        final restarted = MessagingController(storage: delayed);
        restarted.initialize(
          userId: 'staff-teacher-001',
          userName: 'Nigora Karimova',
          sourceThreads: [_sourceThread()],
        );

        expect(restarted.isRestoring, isTrue);
        expect(() => restarted.markRead(['thread-1']), throwsStateError);
        expect(delayed.writes, isEmpty);

        delayed.completeRead();
        await restarted.restored;

        expect(restarted.isRestoring, isFalse);
        expect(restarted.threadById('thread-1')?.isMuted, isTrue);
        expect(
          restarted.threadById('thread-1')?.folderIds,
          contains(folder.id),
        );
      },
    );
  });

  testWidgets('waveform exposes progress semantics and adapts to width', (
    tester,
  ) async {
    final colors = sfColorsFor(SfPalette.daryo);
    await tester.pumpWidget(
      SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        child: MaterialApp(
          locale: const Locale('uz'),
          supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildMaterialTheme(colors, dark: false),
          home: const Scaffold(
            body: SizedBox(
              width: 180,
              child: MessagingWaveform(progress: 0.5, barCount: 12),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Ovoz ijrosi 50 foiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
