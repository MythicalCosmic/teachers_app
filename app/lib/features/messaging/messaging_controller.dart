import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/api/api_models.dart';
import '../../data/api/backend_core.dart';
import '../../data/api/backend_models.dart';
import '../../data/api/backend_work_api.dart';
import '../../data/models.dart' as legacy;
import 'messaging_models.dart';
import 'messaging_storage.dart';

/// Messaging state shared by the demo workspace and production server adapter.
///
/// In production, threads/messages/read state and attachments come from the
/// backend. Archive, pin, mute, folders, local reactions and call previews stay
/// deliberately device-local because the server exposes no such mutations.
class MessagingController extends ChangeNotifier {
  MessagingController({
    DateTime Function()? clock,
    MessagingStorage? storage,
    this._backend,
    http.Client Function()? uploadClientFactory,
  }) : _clock = clock ?? DateTime.now,
       _storage = storage ?? MemoryMessagingStorage(),
       _uploadClientFactory = uploadClientFactory ?? http.Client.new;

  static final MessagingController shared = MessagingController(
    storage: SharedPreferencesMessagingStorage(),
  );

  final DateTime Function() _clock;
  final MessagingStorage _storage;
  final BackendWorkApi? _backend;
  final http.Client Function() _uploadClientFactory;
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
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _backendUnavailable = false;
  String? _backendError;
  final Map<String, int> _olderMessagePage = <String, int>{};
  final Set<String> _loadedRemoteThreads = <String>{};
  final Set<String> _hiddenRemoteThreadIds = <String>{};
  int _remoteGeneration = 0;
  http.Client? _activeUploadClient;
  double? _uploadProgress;
  String? _uploadingThreadId;
  Future<void> Function()? onUnauthorized;
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
  bool get isProduction => _backend != null;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get backendUnavailable => _backendUnavailable;
  String? get backendError => _backendError;
  double? get uploadProgress => _uploadProgress;
  String? get uploadingThreadId => _uploadingThreadId;

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
    _contacts.clear();
    if (!isProduction) {
      _contacts.addAll(_seedContacts.where((contact) => contact.id != userId));
    }
    _olderMessagePage.clear();
    _loadedRemoteThreads.clear();
    _hiddenRemoteThreadIds.clear();
    _backendError = null;
    _backendUnavailable = false;
    final generation = ++_remoteGeneration;

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

    if (_threads.isEmpty && !isProduction) {
      _createWelcomeThread();
    }
    // Initialization is synchronous, so callers can read the seeded state in
    // the same frame. Do not notify here: messaging screens initialize while
    // resolving their current session during build, and a synchronous
    // notification would ask an already-mounted ListenableBuilder to rebuild
    // while the framework is still building its parent. The asynchronous
    // restore below, and every subsequent user mutation, continue to notify.
    _restored = _restore(userId, _stateVersion).then((_) async {
      if (!isProduction ||
          _sessionUserId != userId ||
          generation != _remoteGeneration) {
        return;
      }
      await refreshThreads();
      await refreshDirectory();
    });
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

  /// Refreshes the production thread index while preserving device-only
  /// organization (archive, pin, mute and folders).
  Future<void> refreshThreads({bool silent = false}) async {
    final backend = _backend;
    if (backend == null || _sessionUserId == null || _isRefreshing) return;
    final generation = _remoteGeneration;
    _isRefreshing = true;
    _backendError = null;
    if (!silent) notifyListeners();
    try {
      final result = await backend.threads();
      if (!_isCurrentRemoteGeneration(generation)) return;
      if (result.isUnavailable) {
        _backendUnavailable = true;
        _backendError = result.error?.message;
        return;
      }
      final page = result.value!;
      final existing = {for (final thread in _threads) thread.id: thread};
      final next = <MessagingThread>[];
      final contacts = <String, MessagingContact>{
        for (final contact in _contacts)
          if (contact.id != currentUserId) contact.id: contact,
      };
      for (final remote in page.items) {
        final id = '${remote.id}';
        if (_hiddenRemoteThreadIds.contains(id)) continue;
        final mapped = _threadFromBackend(remote, overlay: existing[id]);
        next.add(mapped);
        for (final participant in remote.participants) {
          final participantId = '${participant.userId}';
          if (participantId == currentUserId) continue;
          contacts[participantId] = _contactForRemoteParticipant(
            participant.userId,
            threadTitle: mapped.title,
          );
        }
      }
      _threads
        ..clear()
        ..addAll(next);
      _contacts
        ..clear()
        ..addAll(contacts.values);
      _backendUnavailable = false;
      _backendError = null;
      _changed();
    } on ApiException catch (error) {
      if (!_isCurrentRemoteGeneration(generation)) return;
      _backendError = error.message;
      await _handleApiError(error);
    } on Object {
      if (_isCurrentRemoteGeneration(generation)) {
        _backendError = 'Suhbatlarni yangilab bo\u2018lmadi.';
      }
    } finally {
      if (_isCurrentRemoteGeneration(generation)) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Loads the newest server page once, then keeps older pages available for
  /// pull/scroll pagination. The backend orders each page oldest-first.
  Future<void> loadThreadMessages(
    String threadId, {
    bool refresh = false,
  }) async {
    final backend = _backend;
    if (backend == null || _sessionUserId == null) return;
    if (!refresh && _loadedRemoteThreads.contains(threadId)) return;
    final numericId = int.tryParse(threadId);
    if (numericId == null) return;
    final generation = _remoteGeneration;
    _backendError = null;
    notifyListeners();
    try {
      var result = await backend.messages(numericId);
      if (!_isCurrentRemoteGeneration(generation)) return;
      if (result.isUnavailable) {
        _backendUnavailable = true;
        _backendError = result.error?.message;
        return;
      }
      var page = result.value!;
      if (page.pages > 1) {
        result = await backend.messages(numericId, page: page.pages);
        if (!_isCurrentRemoteGeneration(generation)) return;
        if (result.isUnavailable) {
          _backendUnavailable = true;
          _backendError = result.error?.message;
          return;
        }
        page = result.value!;
      }
      _replaceRemoteMessages(
        threadId,
        page.items,
        prepend: false,
        preservePending: true,
      );
      _olderMessagePage[threadId] = page.page - 1;
      _loadedRemoteThreads.add(threadId);
      _backendUnavailable = false;
      _backendError = null;
    } on ApiException catch (error) {
      if (!_isCurrentRemoteGeneration(generation)) return;
      _backendError = error.message;
      await _handleApiError(error);
    } on Object {
      if (_isCurrentRemoteGeneration(generation)) {
        _backendError = 'Xabarlar tarixini yuklab bo\u2018lmadi.';
      }
    } finally {
      if (_isCurrentRemoteGeneration(generation)) notifyListeners();
    }
  }

  /// Loads the staff directory when the signed-in role has `users:read`.
  /// A scoped 403 is expected for some teachers; their existing participants
  /// remain available without turning the entire messaging module into error.
  Future<void> refreshDirectory() async {
    final backend = _backend;
    if (backend == null || _sessionUserId == null) return;
    final generation = _remoteGeneration;
    try {
      final response = await backend.transport.get(
        '/api/v1/users/',
        query: const <String, Object?>{'page_size': 100, 'is_active': true},
      );
      if (!_isCurrentRemoteGeneration(generation)) return;
      final next = <MessagingContact>[];
      for (final user in backendMaps(response.data)) {
        final id = '${backendInt(user['id'])}';
        if (id == '0' || id == currentUserId) continue;
        final memberships = backendMaps(user['role_memberships']);
        final slugs = <String>{
          for (final membership in memberships)
            backendString(
              membership['account_type_slug'],
              fallback: backendString(membership['legacy_role']),
            ).toLowerCase(),
        }..removeWhere((value) => value.isEmpty);
        const blocked = <String>{
          'student',
          'parent',
          'ceo',
          'owner',
          'director',
          'manager',
        };
        if (slugs.any(
          (slug) => blocked.any((fragment) => slug.contains(fragment)),
        )) {
          continue;
        }
        if (!backendBool(user['is_staff']) && slugs.isEmpty) continue;
        final fullName = backendString(user['full_name']);
        final username = backendString(user['username']);
        next.add(
          MessagingContact(
            id: id,
            name: fullName.isNotEmpty
                ? fullName
                : username.isNotEmpty
                ? username
                : 'Xodim #$id',
            username: username.isEmpty ? '' : '@$username',
            phone: backendString(user['phone']),
            role: slugs.isEmpty ? 'Xodim' : slugs.first,
            bio: backendString(user['email']),
            isOnline:
                backendDate(
                  user['last_seen_at'],
                )?.isAfter(_clock().subtract(const Duration(minutes: 5))) ??
                false,
          ),
        );
      }
      if (next.isEmpty) return;
      final byId = <String, MessagingContact>{
        for (final contact in _contacts) contact.id: contact,
        for (final contact in next) contact.id: contact,
      };
      _contacts
        ..clear()
        ..addAll(byId.values);
      notifyListeners();
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) return;
      await _handleApiError(error);
    } on Object {
      // The directory is optional; existing server participants remain usable.
    }
  }

  bool hasOlderMessages(String threadId) =>
      isProduction && (_olderMessagePage[threadId] ?? 0) > 0;

  bool isThreadLoaded(String threadId) =>
      !isProduction || _loadedRemoteThreads.contains(threadId);

  Future<void> loadOlderMessages(String threadId) async {
    final backend = _backend;
    final numericId = int.tryParse(threadId);
    final pageNumber = _olderMessagePage[threadId] ?? 0;
    if (backend == null ||
        numericId == null ||
        pageNumber < 1 ||
        _isLoadingMore) {
      return;
    }
    final generation = _remoteGeneration;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final result = await backend.messages(numericId, page: pageNumber);
      if (!_isCurrentRemoteGeneration(generation)) return;
      if (result.isUnavailable) {
        _backendUnavailable = true;
        _backendError = result.error?.message;
        return;
      }
      final page = result.value!;
      _replaceRemoteMessages(threadId, page.items, prepend: true);
      _olderMessagePage[threadId] = page.page - 1;
      _backendUnavailable = false;
      _backendError = null;
    } on ApiException catch (error) {
      if (!_isCurrentRemoteGeneration(generation)) return;
      _backendError = error.message;
      await _handleApiError(error);
    } on Object {
      if (_isCurrentRemoteGeneration(generation)) {
        _backendError = 'Oldingi xabarlarni yuklab bo\u2018lmadi.';
      }
    } finally {
      if (_isCurrentRemoteGeneration(generation)) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
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
    final targets = ids.toList(growable: false);
    _updateMany(targets, (thread) => thread.copyWith(isRead: read));
    if (_backend != null && read) {
      for (final id in targets) {
        unawaited(_markRemoteRead(id));
      }
    }
  }

  List<MessagingThread> deleteThreads(Iterable<String> ids) {
    _ensureReady();
    final targets = ids.toSet();
    final deleted = _threads
        .where((thread) => targets.contains(thread.id))
        .toList(growable: false);
    if (isProduction) _hiddenRemoteThreadIds.addAll(targets);
    _threads.removeWhere((thread) => targets.contains(thread.id));
    _changed();
    return deleted;
  }

  void restoreThreads(Iterable<MessagingThread> deleted) {
    _ensureReady();
    for (final thread in deleted) {
      _hiddenRemoteThreadIds.remove(thread.id);
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

  Future<MessagingThread> createOrOpenDirectThreadAsync(
    String contactId,
  ) async {
    final backend = _backend;
    if (backend == null) return createOrOpenDirectThread(contactId);
    final existing = _threads.where(
      (thread) => !thread.isGroup && thread.contact.id == contactId,
    );
    if (existing.isNotEmpty) return existing.first;
    final participantId = int.tryParse(contactId);
    if (participantId == null) {
      throw ArgumentError('Xodim server identifikatori noto\u2018g\u2018ri.');
    }
    final generation = _remoteGeneration;
    try {
      final result = await backend.createThread(
        participantIds: <int>[participantId],
      );
      if (!_isCurrentRemoteGeneration(generation)) {
        throw StateError('Messaging session changed.');
      }
      if (result.isUnavailable) {
        _backendUnavailable = true;
        _backendError = result.error?.message;
        notifyListeners();
        throw ArgumentError(
          result.error?.message ?? 'Yangi suhbat ochishga ruxsat yo\u2018q.',
        );
      }
      final mapped = _threadFromBackend(result.value!);
      _threads.add(mapped);
      _backendUnavailable = false;
      _backendError = null;
      _changed();
      return mapped;
    } on ApiException catch (error) {
      _backendError = error.message;
      await _handleApiError(error);
      throw ArgumentError(error.message);
    }
  }

  Future<MessagingMessage> sendText(String threadId, String rawBody) async {
    final body = rawBody.trim();
    if (_backend != null && body.isNotEmpty) {
      return _sendRemote(threadId, body: body);
    }
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

  Future<MessagingMessage> sendAttachment({
    required String threadId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
    required MessagingKind kind,
    Duration? duration,
    String body = '',
  }) async {
    if (_backend == null) {
      throw ArgumentError('Fayl yuborish faqat server suhbatida ishlaydi.');
    }
    if (bytes.isEmpty) throw ArgumentError('Tanlangan fayl bo\u2018sh.');
    if (kind == MessagingKind.video &&
        (duration == null || duration > const Duration(minutes: 1))) {
      throw ArgumentError('Video 1 daqiqadan oshmasligi kerak.');
    }
    if (kind == MessagingKind.voice &&
        (duration == null ||
            duration < const Duration(milliseconds: 500) ||
            duration > const Duration(minutes: 1))) {
      throw ArgumentError(
        'Ovozli xabar 0.5 soniyadan 1 daqiqagacha bo\u2018lishi kerak.',
      );
    }
    if (_activeUploadClient != null) {
      throw ArgumentError('Boshqa fayl yuklanmoqda. Avval uni yakunlang.');
    }
    final numericId = int.tryParse(threadId);
    if (numericId == null) throw ArgumentError('Suhbat topilmadi.');
    final provisional = MessagingMessage(
      id: _nextId('upload'),
      senderId: currentUserId,
      senderName: currentUserName,
      sentAt: _clock(),
      body: body.trim(),
      kind: kind,
      mediaLabel: filename,
      mediaDuration: duration,
      delivery: MessagingDelivery.sending,
    );
    _appendPendingMessage(threadId, provisional);
    final generation = _remoteGeneration;
    final client = _uploadClientFactory();
    _activeUploadClient = client;
    _uploadingThreadId = threadId;
    _uploadProgress = 0.08;
    notifyListeners();
    try {
      final grantResult = await _backend.messageUploadGrant(
        filename: filename,
        sizeBytes: bytes.length,
        contentType: contentType,
      );
      if (!_isCurrentRemoteGeneration(generation)) {
        throw StateError('Messaging session changed.');
      }
      final grant = _availableOrThrow(
        grantResult,
        fallback: 'Bu rol uchun fayl yuborish mavjud emas.',
      );
      _uploadProgress = 0.24;
      notifyListeners();
      await _uploadGrantedAttachment(
        client: client,
        grant: grant,
        filename: filename,
        bytes: bytes,
      );
      _uploadProgress = 0.78;
      notifyListeners();
      final sentResult = await _backend.sendMessage(
        numericId,
        body: body.trim(),
        attachments: <String>[grant.key],
      );
      final sent = _availableOrThrow(
        sentResult,
        fallback: 'Bu suhbatga xabar yuborishga ruxsat yo\u2018q.',
      );
      final mapped = _messageFromBackend(sent);
      _updateMessage(threadId, provisional.id, (_) => mapped);
      _uploadProgress = 1;
      unawaited(refreshThreads(silent: true));
      return mapped;
    } on ApiException catch (error) {
      _removePendingMessage(threadId, provisional.id);
      await _handleApiError(error);
      throw ArgumentError(error.message);
    } on Object catch (error) {
      _removePendingMessage(threadId, provisional.id);
      if (error is ArgumentError) rethrow;
      throw ArgumentError(
        'Fayl yuborilmadi. Ulanishni tekshirib qayta urinib ko\u2018ring.',
      );
    } finally {
      client.close();
      if (identical(_activeUploadClient, client)) {
        _activeUploadClient = null;
        _uploadingThreadId = null;
        _uploadProgress = null;
        notifyListeners();
      }
    }
  }

  void cancelAttachmentUpload() {
    final client = _activeUploadClient;
    if (client == null) return;
    client.close();
    _activeUploadClient = null;
    _uploadingThreadId = null;
    _uploadProgress = null;
    notifyListeners();
  }

  Future<String> attachmentDownloadUrl(
    String threadId,
    String attachmentKey,
  ) async {
    final backend = _backend;
    final numericId = int.tryParse(threadId);
    if (backend == null || numericId == null || attachmentKey.isEmpty) {
      throw ArgumentError('Fayl manzili mavjud emas.');
    }
    try {
      final result = await backend.messageAttachmentDownloadUrl(
        numericId,
        attachmentKey,
      );
      return _availableOrThrow(
        result,
        fallback: 'Bu faylni ochishga ruxsat yo\u2018q.',
      );
    } on ApiException catch (error) {
      await _handleApiError(error);
      throw ArgumentError(error.message);
    }
  }

  Future<void> refreshForRealtime({String? threadId}) async {
    await refreshThreads(silent: true);
    if (threadId != null && _loadedRemoteThreads.contains(threadId)) {
      await loadThreadMessages(threadId, refresh: true);
    }
  }

  void clearRemoteSession() {
    if (!isProduction) return;
    cancelAttachmentUpload();
    ++_remoteGeneration;
    _sessionUserId = null;
    _initialized = false;
    _threads.clear();
    _contacts.clear();
    _loadedRemoteThreads.clear();
    _olderMessagePage.clear();
    _backendError = null;
    _backendUnavailable = false;
    notifyListeners();
  }

  Future<MessagingMessage> _sendRemote(
    String threadId, {
    required String body,
  }) async {
    final numericId = int.tryParse(threadId);
    if (numericId == null) throw ArgumentError('Suhbat topilmadi.');
    final provisional = MessagingMessage(
      id: _nextId('pending'),
      senderId: currentUserId,
      senderName: currentUserName,
      body: body,
      sentAt: _clock(),
      delivery: MessagingDelivery.sending,
    );
    _appendPendingMessage(threadId, provisional);
    final generation = _remoteGeneration;
    try {
      final result = await _backend!.sendMessage(numericId, body: body);
      if (!_isCurrentRemoteGeneration(generation)) return provisional;
      final sent = _availableOrThrow(
        result,
        fallback: 'Bu suhbatga xabar yuborishga ruxsat yo\u2018q.',
      );
      final mapped = _messageFromBackend(sent);
      _updateMessage(threadId, provisional.id, (_) => mapped);
      unawaited(refreshThreads(silent: true));
      return mapped;
    } on ApiException catch (error) {
      _removePendingMessage(threadId, provisional.id);
      await _handleApiError(error);
      throw ArgumentError(error.message);
    } on Object catch (error) {
      _removePendingMessage(threadId, provisional.id);
      if (error is ArgumentError) rethrow;
      throw ArgumentError(
        'Xabar yuborilmadi. Ulanishni tekshirib qayta urinib ko\u2018ring.',
      );
    }
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

  void _appendPendingMessage(String threadId, MessagingMessage provisional) {
    _updateThread(
      threadId,
      (thread) => thread.copyWith(
        messages: <MessagingMessage>[...thread.messages, provisional],
        isRead: true,
        isArchived: false,
      ),
    );
  }

  void _removePendingMessage(String threadId, String messageId) {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) return;
    _threads[index] = _threads[index].copyWith(
      messages: _threads[index].messages
          .where((message) => message.id != messageId)
          .toList(growable: false),
    );
    _changed();
  }

  Future<void> _uploadGrantedAttachment({
    required http.Client client,
    required BackendUploadGrant grant,
    required String filename,
    required Uint8List bytes,
  }) async {
    final uri = Uri.tryParse(grant.url);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const ApiException(
        message: 'Server xavfsiz fayl manzilini qaytarmadi.',
        code: 'invalid_upload_grant',
      );
    }
    final method = grant.method.trim().toUpperCase();
    late final http.StreamedResponse response;
    if (method == 'POST') {
      final request = http.MultipartRequest('POST', uri);
      for (final entry in grant.fields.entries) {
        request.fields[entry.key] = '${entry.value ?? ''}';
      }
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      response = await client.send(request);
    } else if (method == 'PUT') {
      final request = http.Request('PUT', uri)..bodyBytes = bytes;
      for (final entry in grant.fields.entries) {
        request.headers[entry.key] = '${entry.value ?? ''}';
      }
      response = await client.send(request);
    } else {
      throw const ApiException(
        message: 'Server noma\u2019lum yuklash usulini qaytardi.',
        code: 'invalid_upload_grant',
      );
    }
    await response.stream.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException(
        message: 'Fayl omboriga yuklash tugallanmadi.',
        code: 'attachment_upload_failed',
        isNetworkError: true,
      );
    }
  }

  MessagingThread _threadFromBackend(
    BackendThread value, {
    MessagingThread? overlay,
  }) {
    final participantIds = <String>{
      for (final participant in value.participants) '${participant.userId}',
    };
    final others = value.participants
        .where((participant) => '${participant.userId}' != currentUserId)
        .toList(growable: false);
    final title = value.subject.trim().isNotEmpty
        ? value.subject.trim()
        : others.length == 1
        ? 'Xodim #${others.first.userId}'
        : 'Suhbat #${value.id}';
    final contact =
        overlay?.contact ??
        (others.isEmpty
            ? MessagingContact(
                id: '${value.createdBy ?? value.id}',
                name: title,
                username: '',
                phone: '',
                role: 'Xodim',
              )
            : _contactForRemoteParticipant(
                others.first.userId,
                threadTitle: title,
              ));
    return MessagingThread(
      id: '${value.id}',
      title: title,
      contact: contact,
      participantIds: participantIds,
      messages: overlay?.messages ?? const <MessagingMessage>[],
      isGroup: others.length > 1,
      isPinned: overlay?.isPinned ?? false,
      isMuted: overlay?.isMuted ?? false,
      isArchived: overlay?.isArchived ?? false,
      isRead: value.unreadCount == 0,
      folderIds: overlay?.folderIds ?? const <String>{},
    );
  }

  MessagingContact _contactForRemoteParticipant(
    int userId, {
    required String threadTitle,
  }) {
    final id = '$userId';
    final existing = _contacts.where((contact) => contact.id == id).firstOrNull;
    if (existing != null) return existing;
    final directName = threadTitle.startsWith('Suhbat #')
        ? 'Xodim #$userId'
        : threadTitle;
    return MessagingContact(
      id: id,
      name: directName,
      username: '@user$userId',
      phone: '',
      role: 'Xodim',
      bio: 'Server profilida mavjud bo\u2018lgan suhbat ishtirokchisi.',
    );
  }

  MessagingMessage _messageFromBackend(BackendMessage value) {
    final attachment = value.attachments.firstOrNull;
    final kind = attachment == null
        ? MessagingKind.text
        : _kindForAttachment(attachment);
    return MessagingMessage(
      id: '${value.id}',
      senderId: '${value.senderId}',
      senderName: '${value.senderId}' == currentUserId
          ? currentUserName
          : 'Xodim #${value.senderId}',
      sentAt: (value.createdAt ?? _clock()).toLocal(),
      body: value.body,
      kind: kind,
      mediaLabel: attachment == null ? null : _attachmentFilename(attachment),
      mediaDuration: kind == MessagingKind.voice && attachment != null
          ? _voiceDurationFromFilename(_attachmentFilename(attachment))
          : null,
      attachmentKeys: List<String>.unmodifiable(value.attachments),
      delivery: MessagingDelivery.delivered,
    );
  }

  void _replaceRemoteMessages(
    String threadId,
    List<BackendMessage> values, {
    required bool prepend,
    bool preservePending = false,
  }) {
    final index = _threads.indexWhere((thread) => thread.id == threadId);
    if (index < 0) return;
    final current = _threads[index].messages;
    final currentById = <String, MessagingMessage>{
      for (final message in current) message.id: message,
    };
    final mapped = values
        .map((value) {
          final remote = _messageFromBackend(value);
          return remote.copyWith(reactions: currentById[remote.id]?.reactions);
        })
        .toList(growable: false);
    final pending = preservePending
        ? current
              .where(
                (message) =>
                    message.id.startsWith('pending-') ||
                    message.id.startsWith('upload-') ||
                    message.isDemoMedia,
              )
              .toList(growable: false)
        : const <MessagingMessage>[];
    final combined = prepend
        ? <MessagingMessage>[...mapped, ...current]
        : <MessagingMessage>[...mapped, ...pending];
    final deduplicated = <String, MessagingMessage>{};
    for (final message in combined) {
      deduplicated[message.id] = message;
    }
    _threads[index] = _threads[index].copyWith(
      messages: deduplicated.values.toList(growable: false),
    );
    _changed();
  }

  MessagingKind _kindForAttachment(String key) {
    final extension = _attachmentFilename(key).split('.').last.toLowerCase();
    if (const <String>{
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
    }.contains(extension)) {
      return MessagingKind.image;
    }
    if (const <String>{'mp4', 'mov', 'm4v', 'webm'}.contains(extension)) {
      return MessagingKind.video;
    }
    if (const <String>{
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'opus',
    }.contains(extension)) {
      return MessagingKind.voice;
    }
    return MessagingKind.image;
  }

  Duration? _voiceDurationFromFilename(String filename) {
    final match = RegExp(r'_(\d{1,5})ms(?:\.[^.]+)?$').firstMatch(filename);
    final milliseconds = int.tryParse(match?.group(1) ?? '');
    if (milliseconds == null || milliseconds < 1 || milliseconds > 60000) {
      return null;
    }
    return Duration(milliseconds: milliseconds);
  }

  String _attachmentFilename(String key) {
    final raw = key.split('/').last;
    return Uri.decodeComponent(raw);
  }

  T _availableOrThrow<T>(
    BackendModuleResult<T> result, {
    required String fallback,
  }) {
    if (result.isUnavailable || result.value == null) {
      _backendUnavailable = true;
      _backendError = result.error?.message ?? fallback;
      throw ArgumentError(_backendError!);
    }
    _backendUnavailable = false;
    _backendError = null;
    return result.value as T;
  }

  Future<void> _markRemoteRead(String threadId) async {
    final numericId = int.tryParse(threadId);
    if (_backend == null || numericId == null) return;
    try {
      final result = await _backend.markThreadRead(numericId);
      if (result.isUnavailable) {
        _backendUnavailable = true;
        _backendError = result.error?.message;
        notifyListeners();
      }
    } on ApiException catch (error) {
      _backendError = error.message;
      await _handleApiError(error);
      notifyListeners();
    }
  }

  bool _isCurrentRemoteGeneration(int generation) =>
      _sessionUserId != null && generation == _remoteGeneration;

  Future<void> _handleApiError(ApiException error) async {
    if (error.statusCode != 401) return;
    await onUnauthorized?.call();
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
      _hiddenRemoteThreadIds
        ..clear()
        ..addAll(_strings(map['hiddenRemoteThreadIds']));
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
      if (isProduction)
        'hiddenRemoteThreadIds': _hiddenRemoteThreadIds.toList(),
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
    'attachmentKeys': message.attachmentKeys,
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
      attachmentKeys: _strings(json['attachmentKeys']).toList(),
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

  @override
  void dispose() {
    ++_remoteGeneration;
    _activeUploadClient?.close();
    _activeUploadClient = null;
    super.dispose();
  }
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
