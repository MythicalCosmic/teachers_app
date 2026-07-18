import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/models.dart' as legacy;
import 'messaging_models.dart';
import 'messaging_storage.dart';

/// Device-local messaging domain used until the realtime staff messaging API
/// is connected. Every visible action mutates this repository, updates every
/// messaging screen, and persists organizational state across app restarts.
class MessagingController extends ChangeNotifier {
  MessagingController({DateTime Function()? clock, MessagingStorage? storage})
    : _clock = clock ?? DateTime.now,
      _storage = storage ?? MemoryMessagingStorage();

  static final MessagingController shared = MessagingController(
    storage: SharedPreferencesMessagingStorage(),
  );

  final DateTime Function() _clock;
  final MessagingStorage _storage;
  final List<MessagingThread> _threads = [];
  final List<MessagingContact> _contacts = [];
  final List<MessagingFolder> _folders = [
    const MessagingFolder(id: 'folder-work', name: 'Ish'),
    const MessagingFolder(id: 'folder-important', name: 'Muhim'),
  ];

  String? _sessionUserId;
  bool _initialized = false;
  bool _isRestoring = false;
  String _currentUserName = 'Siz';
  String? _activeCallThreadId;
  DateTime? _callStartedAt;
  int _sequence = 0;
  int _stateVersion = 0;
  String? _persistenceError;
  Future<void> _restored = Future<void>.value();
  Future<void> _writeQueue = Future<void>.value();

  String get currentUserId => _sessionUserId ?? 'current-user';
  String get currentUserName => _currentUserName;
  List<MessagingThread> get threads => List.unmodifiable(_threads);
  List<MessagingContact> get contacts => List.unmodifiable(_contacts);
  List<MessagingFolder> get folders => List.unmodifiable(_folders);
  String? get activeCallThreadId => _activeCallThreadId;
  DateTime? get callStartedAt => _callStartedAt;
  Future<void> get restored => _restored;
  bool get isRestoring => _isRestoring;
  String? get persistenceError => _persistenceError;

  Future<void> flushPersistence() async {
    await _restored;
    await _writeQueue;
  }

  Future<void> retryPersistence() async {
    _queuePersist();
    await _writeQueue;
  }

  void clearPersistenceError() {
    if (_persistenceError == null) return;
    _persistenceError = null;
    notifyListeners();
  }

  int get unreadCount =>
      _threads.where((thread) => !thread.isArchived && !thread.isRead).length;
  int get archivedCount => _threads.where((thread) => thread.isArchived).length;

  void initialize({
    required String userId,
    required String userName,
    required Iterable<legacy.MessageThread> sourceThreads,
  }) {
    if (_initialized && _sessionUserId == userId) return;
    _initialized = true;
    _isRestoring = true;
    _sessionUserId = userId;
    _currentUserName = userName;
    _stateVersion = 0;
    _threads.clear();
    _folders
      ..clear()
      ..addAll(_defaultFolders);
    _contacts
      ..clear()
      ..addAll(_seedContacts.where((contact) => contact.id != userId));

    for (final source in sourceThreads) {
      if (!source.participantIds.contains(userId)) continue;
      final otherId = source.participantIds.firstWhere(
        (id) => id != userId,
        orElse: () => 'staff-methodist-001',
      );
      final contact = _contactFor(otherId, fallbackName: source.title);
      _threads.add(
        MessagingThread(
          id: source.id,
          title: source.title,
          contact: contact,
          participantIds: source.participantIds,
          isGroup:
              source.title.toLowerCase().contains('jamoa') ||
              source.title.contains('9-B'),
          isPinned: source.isPinned,
          isRead: source.unreadCountFor(userId) == 0,
          folderIds: source.isPinned ? const {'folder-important'} : const {},
          messages: [
            for (final message in source.messages)
              MessagingMessage(
                id: message.id,
                senderId: message.senderId,
                senderName: message.senderName,
                body: message.body,
                sentAt: message.sentAt.toLocal(),
                delivery: message.readBy.length > 1
                    ? MessagingDelivery.read
                    : MessagingDelivery.delivered,
              ),
          ],
        ),
      );
    }

    if (_threads.isEmpty) {
      _createWelcomeThread();
    }
    // Initialization is synchronous, so callers can read the seeded state in
    // the same frame. Do not notify here: messaging screens initialize while
    // resolving their current session during build, and a synchronous
    // notification would ask an already-mounted ListenableBuilder to rebuild
    // while the framework is still building its parent. The asynchronous
    // restore below, and every subsequent user mutation, continue to notify.
    _restored = _restore(userId, _stateVersion);
  }

  MessagingThread? threadById(String? id) {
    if (id == null) return null;
    return _threads.where((thread) => thread.id == id).firstOrNull;
  }

  MessagingContact? contactById(String? id) {
    if (id == null) return null;
    return _contacts.where((contact) => contact.id == id).firstOrNull;
  }

  List<MessagingThread> visibleThreads({
    String query = '',
    String? folderId,
    bool archived = false,
  }) {
    final normalized = query.trim().toLowerCase();
    final result = _threads.where((thread) {
      if (thread.isArchived != archived) return false;
      if (folderId != null && !thread.folderIds.contains(folderId)) {
        return false;
      }
      if (normalized.isEmpty) return true;
      return thread.title.toLowerCase().contains(normalized) ||
          thread.contact.username.toLowerCase().contains(normalized) ||
          thread.messages.any(
            (message) => message.preview.toLowerCase().contains(normalized),
          );
    }).toList();
    result.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return (b.lastActivity ?? DateTime(0)).compareTo(
        a.lastActivity ?? DateTime(0),
      );
    });
    return result;
  }

  MessagingFolder createFolder(String rawName) {
    _ensureReady();
    final name = rawName.trim();
    if (name.isEmpty) throw ArgumentError('Jild nomini kiriting.');
    if (_folders.any(
      (folder) => folder.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw ArgumentError('Bu nomdagi jild allaqachon mavjud.');
    }
    final folder = MessagingFolder(id: _nextId('folder'), name: name);
    _folders.add(folder);
    _changed();
    return folder;
  }

  void setFolder(String threadId, String folderId, {required bool included}) {
    _updateThread(threadId, (thread) {
      final ids = {...thread.folderIds};
      included ? ids.add(folderId) : ids.remove(folderId);
      return thread.copyWith(folderIds: ids);
    });
  }

  void setArchived(Iterable<String> ids, bool archived) {
    _updateMany(ids, (thread) => thread.copyWith(isArchived: archived));
  }

  void togglePinned(Iterable<String> ids) {
    _updateMany(ids, (thread) => thread.copyWith(isPinned: !thread.isPinned));
  }

  void toggleMuted(Iterable<String> ids) {
    _updateMany(ids, (thread) => thread.copyWith(isMuted: !thread.isMuted));
  }

  void markRead(Iterable<String> ids, {bool read = true}) {
    _updateMany(ids, (thread) => thread.copyWith(isRead: read));
  }

  List<MessagingThread> deleteThreads(Iterable<String> ids) {
    _ensureReady();
    final targets = ids.toSet();
    final deleted = _threads
        .where((thread) => targets.contains(thread.id))
        .toList(growable: false);
    _threads.removeWhere((thread) => targets.contains(thread.id));
    _changed();
    return deleted;
  }

  void restoreThreads(Iterable<MessagingThread> deleted) {
    _ensureReady();
    for (final thread in deleted) {
      if (!_threads.any((value) => value.id == thread.id)) _threads.add(thread);
    }
    _changed();
  }

  MessagingThread createOrOpenDirectThread(String contactId) {
    _ensureReady();
    final existing = _threads.where(
      (thread) => !thread.isGroup && thread.contact.id == contactId,
    );
    if (existing.isNotEmpty) return existing.first;
    final contact = contactById(contactId);
    if (contact == null) throw ArgumentError('Xodim topilmadi.');
    final thread = MessagingThread(
      id: _nextId('thread'),
      title: contact.name,
      contact: contact,
      participantIds: {currentUserId, contact.id},
      messages: const [],
    );
    _threads.add(thread);
    _changed();
    return thread;
  }

  Future<MessagingMessage> sendText(String threadId, String rawBody) async {
    final body = rawBody.trim();
    if (body.isEmpty) throw ArgumentError('Xabar matni bo‘sh bo‘lmasin.');
    return _send(
      threadId,
      MessagingMessage(
        id: _nextId('message'),
        senderId: currentUserId,
        senderName: currentUserName,
        body: body,
        sentAt: _clock(),
        delivery: MessagingDelivery.sending,
      ),
    );
  }

  Future<MessagingMessage> sendImage(
    String threadId, {
    required String label,
    bool isDemo = true,
  }) => _send(
    threadId,
    MessagingMessage(
      id: _nextId('image'),
      senderId: currentUserId,
      senderName: currentUserName,
      sentAt: _clock(),
      kind: MessagingKind.image,
      mediaLabel: label,
      isDemoMedia: isDemo,
      delivery: MessagingDelivery.sending,
    ),
  );

  Future<MessagingMessage> sendVideo(
    String threadId, {
    required String label,
    required Duration duration,
    bool isDemo = true,
  }) {
    if (duration > const Duration(minutes: 1)) {
      throw ArgumentError('Video 1 daqiqadan oshmasligi kerak.');
    }
    return _send(
      threadId,
      MessagingMessage(
        id: _nextId('video'),
        senderId: currentUserId,
        senderName: currentUserName,
        sentAt: _clock(),
        kind: MessagingKind.video,
        mediaLabel: label,
        mediaDuration: duration,
        isDemoMedia: isDemo,
        delivery: MessagingDelivery.sending,
      ),
    );
  }

  Future<MessagingMessage> sendVoice(
    String threadId, {
    required Duration duration,
    bool isDemo = true,
  }) {
    if (duration < const Duration(milliseconds: 500)) {
      throw ArgumentError('Ovozli xabar juda qisqa.');
    }
    return _send(
      threadId,
      MessagingMessage(
        id: _nextId('voice'),
        senderId: currentUserId,
        senderName: currentUserName,
        sentAt: _clock(),
        kind: MessagingKind.voice,
        mediaDuration: duration,
        isDemoMedia: isDemo,
        delivery: MessagingDelivery.sending,
      ),
    );
  }

  void react(String threadId, String messageId, String emoji) {
    _updateMessage(threadId, messageId, (message) {
      final reactions = {...message.reactions};
      reactions.update(emoji, (value) => value + 1, ifAbsent: () => 1);
      return message.copyWith(reactions: reactions);
    });
  }

  void deleteMessages(String threadId, Iterable<String> messageIds) {
    final ids = messageIds.toSet();
    _updateThread(
      threadId,
      (thread) => thread.copyWith(
        messages: thread.messages
            .where((message) => !ids.contains(message.id))
            .toList(),
      ),
    );
  }

  void startCall(String threadId) {
    _ensureReady();
    _activeCallThreadId = threadId;
    _callStartedAt = _clock();
    notifyListeners();
  }

  void endCall() {
    _ensureReady();
    _activeCallThreadId = null;
    _callStartedAt = null;
    notifyListeners();
  }

  Future<MessagingMessage> _send(
    String threadId,
    MessagingMessage message,
  ) async {
    final sessionUserId = _sessionUserId;
    _updateThread(
      threadId,
      (thread) => thread.copyWith(
        messages: [...thread.messages, message],
        isRead: true,
        isArchived: false,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (_sessionUserId != sessionUserId || threadById(threadId) == null) {
      return message;
    }
    final delivered = message.copyWith(delivery: MessagingDelivery.delivered);
    _updateMessage(threadId, message.id, (_) => delivered);
    return delivered;
  }

  void _updateMessage(
    String threadId,
    String messageId,
    MessagingMessage Function(MessagingMessage) transform,
  ) {
    _updateThread(threadId, (thread) {
      final messages = [
        for (final message in thread.messages)
          if (message.id == messageId) transform(message) else message,
      ];
      return thread.copyWith(messages: messages);
    });
  }

  void _updateThread(
    String threadId,
    MessagingThread Function(MessagingThread) transform,
  ) {
    _ensureReady();
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) throw ArgumentError('Suhbat topilmadi.');
    _threads[index] = transform(_threads[index]);
    _changed();
  }

  void _updateMany(
    Iterable<String> ids,
    MessagingThread Function(MessagingThread) transform,
  ) {
    _ensureReady();
    final targets = ids.toSet();
    var changed = false;
    for (var index = 0; index < _threads.length; index++) {
      if (!targets.contains(_threads[index].id)) continue;
      _threads[index] = transform(_threads[index]);
      changed = true;
    }
    if (changed) _changed();
  }

  void _changed() {
    _stateVersion++;
    notifyListeners();
    _queuePersist();
  }

  Future<void> _restore(String userId, int versionAtStart) async {
    try {
      final raw = await _storage.read(userId);
      if (_sessionUserId != userId) return;
      if (raw == null || raw.isEmpty) {
        _queuePersist();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map || _stateVersion != versionAtStart) return;
      final map = Map<String, Object?>.from(decoded);
      final storedFolders = _objectMaps(
        map['folders'],
      ).map(_folderFromJson).whereType<MessagingFolder>().toList();
      final storedThreads = _objectMaps(
        map['threads'],
      ).map(_threadFromJson).whereType<MessagingThread>().toList();
      _folders
        ..clear()
        ..addAll(storedFolders.isEmpty ? _defaultFolders : storedFolders);
      _threads
        ..clear()
        ..addAll(storedThreads);
      notifyListeners();
    } on Object {
      // Corrupt or obsolete feature data should never prevent the staff app
      // from opening. Keep the fresh seeded state and replace the bad value.
      _persistenceError =
          'Saved conversations could not be read. Fresh local demo data is shown.';
      _queuePersist();
    } finally {
      if (_sessionUserId == userId) {
        _isRestoring = false;
        notifyListeners();
      }
    }
  }

  void _ensureReady() {
    if (_isRestoring) {
      throw StateError('Messaging is still restoring saved conversations.');
    }
  }

  void _queuePersist() {
    final userId = _sessionUserId;
    if (userId == null) return;
    final snapshot = jsonEncode({
      'version': 1,
      'folders': _folders.map(_folderToJson).toList(),
      'threads': _threads.map(_threadToJson).toList(),
    });
    _writeQueue = _writeQueue.then((_) async {
      try {
        await _storage.write(userId, snapshot);
        if (_sessionUserId == userId && _persistenceError != null) {
          _persistenceError = null;
          notifyListeners();
        }
      } on Object catch (error) {
        if (_sessionUserId != userId) return;
        _persistenceError =
            'Messages could not be saved on this device: $error';
        notifyListeners();
      }
    });
  }

  Map<String, Object?> _folderToJson(MessagingFolder folder) => {
    'id': folder.id,
    'name': folder.name,
  };

  MessagingFolder? _folderFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String || id.isEmpty || name.isEmpty) {
      return null;
    }
    return MessagingFolder(id: id, name: name);
  }

  Map<String, Object?> _contactToJson(MessagingContact contact) => {
    'id': contact.id,
    'name': contact.name,
    'username': contact.username,
    'phone': contact.phone,
    'role': contact.role,
    'bio': contact.bio,
    'isOnline': contact.isOnline,
  };

  MessagingContact? _contactFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    return MessagingContact(
      id: id,
      name: name,
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, Object?> _messageToJson(MessagingMessage message) => {
    'id': message.id,
    'senderId': message.senderId,
    'senderName': message.senderName,
    'sentAt': message.sentAt.toUtc().toIso8601String(),
    'body': message.body,
    'kind': message.kind.name,
    'mediaLabel': message.mediaLabel,
    'mediaDurationMs': message.mediaDuration?.inMilliseconds,
    'isDemoMedia': message.isDemoMedia,
    'delivery': message.delivery.name,
    'reactions': message.reactions,
  };

  MessagingMessage? _messageFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final senderId = json['senderId'];
    final senderName = json['senderName'];
    final sentAt = DateTime.tryParse(json['sentAt'] as String? ?? '');
    if (id is! String ||
        senderId is! String ||
        senderName is! String ||
        sentAt == null) {
      return null;
    }
    final durationMs = (json['mediaDurationMs'] as num?)?.toInt();
    final rawReactions = json['reactions'];
    final reactions = <String, int>{};
    if (rawReactions is Map) {
      for (final entry in rawReactions.entries) {
        if (entry.key is String && entry.value is num) {
          reactions[entry.key as String] = (entry.value as num).toInt();
        }
      }
    }
    return MessagingMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      sentAt: sentAt.toLocal(),
      body: json['body'] as String? ?? '',
      kind: _enumValue(MessagingKind.values, json['kind'], MessagingKind.text),
      mediaLabel: json['mediaLabel'] as String?,
      mediaDuration: durationMs == null
          ? null
          : Duration(milliseconds: durationMs),
      isDemoMedia: json['isDemoMedia'] as bool? ?? false,
      delivery: _enumValue(
        MessagingDelivery.values,
        json['delivery'],
        MessagingDelivery.delivered,
      ),
      reactions: reactions,
    );
  }

  Map<String, Object?> _threadToJson(MessagingThread thread) => {
    'id': thread.id,
    'title': thread.title,
    'contact': _contactToJson(thread.contact),
    'participantIds': thread.participantIds.toList(),
    'messages': thread.messages.map(_messageToJson).toList(),
    'isGroup': thread.isGroup,
    'isPinned': thread.isPinned,
    'isMuted': thread.isMuted,
    'isArchived': thread.isArchived,
    'isRead': thread.isRead,
    'folderIds': thread.folderIds.toList(),
  };

  MessagingThread? _threadFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final contactMap = json['contact'];
    final contact = contactMap is Map
        ? _contactFromJson(Map<String, Object?>.from(contactMap))
        : null;
    if (id is! String || title is! String || contact == null) return null;
    return MessagingThread(
      id: id,
      title: title,
      contact: contact,
      participantIds: _strings(json['participantIds']).toSet(),
      messages: _objectMaps(
        json['messages'],
      ).map(_messageFromJson).whereType<MessagingMessage>().toList(),
      isGroup: json['isGroup'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? true,
      folderIds: _strings(json['folderIds']).toSet(),
    );
  }

  Iterable<Map<String, Object?>> _objectMaps(Object? value) sync* {
    if (value is! Iterable) return;
    for (final item in value) {
      if (item is Map) yield Map<String, Object?>.from(item);
    }
  }

  Iterable<String> _strings(Object? value) sync* {
    if (value is! Iterable) return;
    for (final item in value) {
      if (item is String) yield item;
    }
  }

  T _enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  MessagingContact _contactFor(String id, {required String fallbackName}) {
    return _contacts.where((contact) => contact.id == id).firstOrNull ??
        MessagingContact(
          id: id,
          name: fallbackName,
          username: '@${id.replaceAll('staff-', '')}',
          phone: '+998 90 000 00 00',
          role: 'Xodim',
        );
  }

  void _createWelcomeThread() {
    final contact = _contacts.first;
    _threads.add(
      MessagingThread(
        id: 'thread-welcome',
        title: contact.name,
        contact: contact,
        participantIds: {currentUserId, contact.id},
        isRead: false,
        messages: [
          MessagingMessage(
            id: 'message-welcome',
            senderId: contact.id,
            senderName: contact.name,
            body: 'Assalomu alaykum! Jamoaviy ishga tayyormisiz?',
            sentAt: _clock().subtract(const Duration(minutes: 12)),
          ),
        ],
      ),
    );
  }

  String _nextId(String prefix) =>
      '$prefix-${_clock().microsecondsSinceEpoch}-${_sequence++}';
}

const _defaultFolders = <MessagingFolder>[
  MessagingFolder(id: 'folder-work', name: 'Ish'),
  MessagingFolder(id: 'folder-important', name: 'Muhim'),
];

const _seedContacts = <MessagingContact>[
  MessagingContact(
    id: 'staff-teacher-001',
    name: 'Nigora Karimova',
    username: '@nigora.karimova',
    phone: '+998 90 742 18 06',
    role: 'Matematika o‘qituvchisi',
    bio: 'Har bir dars — yangi imkoniyat.',
    isOnline: true,
  ),
  MessagingContact(
    id: 'staff-assistant-001',
    name: 'Sardor Aliyev',
    username: '@sardor.aliyev',
    phone: '+998 93 614 22 17',
    role: 'O‘qituvchi yordamchisi',
    bio: '9-B guruhi va laboratoriya mashg‘ulotlari.',
    isOnline: true,
  ),
  MessagingContact(
    id: 'staff-methodist-001',
    name: 'Ra’no Karimova',
    username: '@rano.karimova',
    phone: '+998 95 380 41 52',
    role: 'Metodist',
    bio: 'Dars sifati va o‘qituvchi rivoji.',
  ),
  MessagingContact(
    id: 'staff-reception-001',
    name: 'Malika Qodirova',
    username: '@malika.qodirova',
    phone: '+998 99 248 70 31',
    role: 'Qabul bo‘limi mutaxassisi',
    isOnline: true,
  ),
  MessagingContact(
    id: 'staff-auditor-001',
    name: 'Aziz Audit',
    username: '@aziz.audit',
    phone: '+998 97 800 16 04',
    role: 'Ichki auditor',
    bio: 'Shaffof jarayonlar, aniq dalillar.',
  ),
];
