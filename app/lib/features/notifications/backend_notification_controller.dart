import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/api/api_models.dart';
import '../../data/api/backend_models.dart';
import '../../data/api/backend_work_api.dart';
import '../../data/api/notification_realtime.dart';

/// Production notification feed with cursor pagination and realtime insertion.
final class BackendNotificationController extends ChangeNotifier {
  BackendNotificationController({
    required this._backend,
    required this._realtime,
  });

  final BackendWorkApi _backend;
  final NotificationRealtimeClient _realtime;
  final List<BackendNotification> _items = <BackendNotification>[];
  final List<BackendNotificationPreference> _preferences =
      <BackendNotificationPreference>[];
  final Set<int> _realtimeDuringRefresh = <int>{};
  final Set<int> _handledMessageNotificationIds = <int>{};

  StreamSubscription<RealtimeNotification>? _notificationSubscription;
  StreamSubscription<NotificationRealtimeStatus>? _statusSubscription;
  Future<void> Function()? onUnauthorized;
  Future<void> Function(String? threadId)? onMessageReceived;

  bool _started = false;
  bool _feedInitialized = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _preferencesLoading = false;
  bool _feedUnavailable = false;
  bool _preferencesUnavailable = false;
  String? _error;
  String? _nextCursor;
  int _unreadCount = 0;
  int _generation = 0;

  List<BackendNotification> get notifications => List.unmodifiable(_items);
  List<BackendNotificationPreference> get preferences =>
      List.unmodifiable(_preferences);
  bool get isRefreshing => _refreshing;
  bool get isStarted => _started;
  bool get hasLoadedFeed => _feedInitialized;
  bool get isLoadingMore => _loadingMore;
  bool get preferencesLoading => _preferencesLoading;
  bool get feedUnavailable => _feedUnavailable;
  bool get preferencesUnavailable => _preferencesUnavailable;
  bool get hasMore => _nextCursor != null && _nextCursor!.isNotEmpty;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  NotificationRealtimeStatus get realtimeStatus => _realtime.status;

  Future<void> start() async {
    await startRealtime();
    if (_feedInitialized) {
      await refresh();
      return;
    }
    _feedInitialized = true;
    await Future.wait<void>(<Future<void>>[refresh(), refreshPreferences()]);
  }

  /// Starts the token-authenticated WebSocket without forcing REST modules to
  /// load before their screen is needed.
  Future<void> startRealtime() async {
    if (_started) return;
    _started = true;
    ++_generation;
    _notificationSubscription ??= _realtime.notifications.listen(
      _handleRealtimeNotification,
    );
    _statusSubscription ??= _realtime.states.listen(_handleRealtimeStatus);
    try {
      await _realtime.start();
    } on StateError {
      // A disposed client only occurs while the owning AppState is shutting
      // down. REST remains the source of truth, so no UI error is needed.
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    final generation = _generation;
    _refreshing = true;
    _realtimeDuringRefresh.clear();
    _error = null;
    notifyListeners();
    try {
      final feedFuture = _backend.notifications();
      final countFuture = _backend.unreadNotificationCount();
      final feed = await feedFuture;
      final count = await countFuture;
      if (!_isCurrent(generation)) return;
      if (feed.isUnavailable) {
        _feedUnavailable = true;
        _error = feed.error?.message;
        return;
      }
      final page = feed.value!;
      final missedMessageThreads = _newMessageThreads(page.items);
      final concurrentRealtime = <BackendNotification>[
        for (final item in _items)
          if (_realtimeDuringRefresh.contains(item.id)) item,
      ];
      _items
        ..clear()
        ..addAll(page.items);
      for (final concurrent in concurrentRealtime) {
        final index = _items.indexWhere((item) => item.id == concurrent.id);
        if (index < 0) {
          _items.add(concurrent);
        } else {
          _items[index] = concurrent;
        }
      }
      _nextCursor = _cursorToken(page.next);
      _feedUnavailable = false;
      if (count.isUnavailable) {
        _unreadCount = _items.where((item) => item.readAt == null).length;
      } else {
        final serverIds = page.items.map((item) => item.id).toSet();
        final concurrentUnreadOutsidePage = concurrentRealtime
            .where(
              (item) => item.readAt == null && !serverIds.contains(item.id),
            )
            .length;
        _unreadCount = count.value! + concurrentUnreadOutsidePage;
      }
      _sortAndDedupe();
      _error = null;
      await _refreshMissedMessageThreads(missedMessageThreads);
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _error = error.message;
      await _handleApiError(error);
    } on Object {
      if (_isCurrent(generation)) {
        _error = 'Bildirishnomalarni yangilab bo\u2018lmadi.';
      }
    } finally {
      if (_isCurrent(generation)) {
        _refreshing = false;
        _realtimeDuringRefresh.clear();
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || cursor.isEmpty || _loadingMore) return;
    final generation = _generation;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _backend.notifications(cursor: cursor);
      if (!_isCurrent(generation)) return;
      if (result.isUnavailable) {
        _feedUnavailable = true;
        _error = result.error?.message;
        return;
      }
      final page = result.value!;
      _items.addAll(page.items);
      _nextCursor = _cursorToken(page.next);
      _sortAndDedupe();
      _feedUnavailable = false;
      _error = null;
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _error = error.message;
      await _handleApiError(error);
    } on Object {
      if (_isCurrent(generation)) {
        _error = 'Keyingi bildirishnomalarni yuklab bo\u2018lmadi.';
      }
    } finally {
      if (_isCurrent(generation)) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> markRead(int notificationId) async {
    final index = _items.indexWhere((item) => item.id == notificationId);
    if (index < 0 || _items[index].readAt != null) return;
    final generation = _generation;
    final original = _items[index];
    final optimisticReadAt = DateTime.now();
    _items[index] = _copyNotification(original, readAt: optimisticReadAt);
    _unreadCount = (_unreadCount - 1).clamp(0, 1 << 30);
    notifyListeners();
    try {
      final result = await _backend.markNotificationRead(notificationId);
      if (!_isCurrent(generation)) return;
      if (result.isUnavailable || result.value != true) {
        _rollbackRead(notificationId, optimisticReadAt: optimisticReadAt);
        _feedUnavailable = result.isUnavailable;
        _error =
            result.error?.message ??
            'Bildirishnoma o\u2018qilgan deb belgilanmadi.';
        notifyListeners();
      }
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _rollbackRead(notificationId, optimisticReadAt: optimisticReadAt);
      _error = error.message;
      notifyListeners();
      await _handleApiError(error);
    }
  }

  Future<void> markAllRead() async {
    final generation = _generation;
    final originallyUnreadIds = <int>{
      for (final item in _items)
        if (item.readAt == null) item.id,
    };
    final now = DateTime.now();
    for (var index = 0; index < _items.length; index++) {
      if (_items[index].readAt == null) {
        _items[index] = _copyNotification(_items[index], readAt: now);
      }
    }
    _unreadCount = 0;
    notifyListeners();
    try {
      final result = await _backend.markAllNotificationsRead();
      if (!_isCurrent(generation)) return;
      if (result.isUnavailable) {
        _rollbackMarkAll(originallyUnreadIds, optimisticReadAt: now);
        _feedUnavailable = true;
        _error = result.error?.message;
        notifyListeners();
      }
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _rollbackMarkAll(originallyUnreadIds, optimisticReadAt: now);
      _error = error.message;
      notifyListeners();
      await _handleApiError(error);
    }
  }

  Future<void> refreshPreferences() async {
    if (_preferencesLoading) return;
    final generation = _generation;
    _preferencesLoading = true;
    notifyListeners();
    try {
      final result = await _backend.notificationPreferences();
      if (!_isCurrent(generation)) return;
      if (result.isUnavailable) {
        _preferencesUnavailable = true;
        return;
      }
      _preferences
        ..clear()
        ..addAll(result.value!);
      _preferencesUnavailable = false;
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _error = error.message;
      await _handleApiError(error);
    } finally {
      if (_isCurrent(generation)) {
        _preferencesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setPreference(
    BackendNotificationPreference preference,
    bool enabled,
  ) async {
    final generation = _generation;
    final originals = List<BackendNotificationPreference>.from(_preferences);
    final index = _preferences.indexWhere(
      (item) =>
          item.eventType == preference.eventType &&
          item.channel == preference.channel,
    );
    final updated = BackendNotificationPreference(
      eventType: preference.eventType,
      channel: preference.channel,
      enabled: enabled,
    );
    if (index < 0) {
      _preferences.add(updated);
    } else {
      _preferences[index] = updated;
    }
    notifyListeners();
    try {
      final result = await _backend.updateNotificationPreferences(_preferences);
      if (!_isCurrent(generation)) return;
      if (result.isUnavailable) {
        _preferences
          ..clear()
          ..addAll(originals);
        _preferencesUnavailable = true;
        _error = result.error?.message;
      } else {
        _preferences
          ..clear()
          ..addAll(result.value!);
        _preferencesUnavailable = false;
        _error = null;
      }
      notifyListeners();
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) return;
      _preferences
        ..clear()
        ..addAll(originals);
      _error = error.message;
      notifyListeners();
      await _handleApiError(error);
    }
  }

  Future<void> pause() => _realtime.pause();

  Future<void> resume() async {
    if (!_started) return;
    try {
      await _realtime.resume();
    } on StateError {
      return;
    }
    await refresh();
  }

  Future<void> clearSession() async {
    ++_generation;
    _started = false;
    _feedInitialized = false;
    _refreshing = false;
    _loadingMore = false;
    _preferencesLoading = false;
    _items.clear();
    _preferences.clear();
    _nextCursor = null;
    _unreadCount = 0;
    _error = null;
    _feedUnavailable = false;
    _preferencesUnavailable = false;
    _realtimeDuringRefresh.clear();
    _handledMessageNotificationIds.clear();
    notifyListeners();
    try {
      await _realtime.pause();
    } on Object {
      // In-memory sensitive state is already cleared. A broken realtime
      // transport must not keep logout/session expiry from completing.
    }
  }

  void _handleRealtimeNotification(RealtimeNotification realtime) {
    final id = int.tryParse(realtime.id);
    if (!_started || id == null || id < 1) {
      if (_started) unawaited(refresh());
      return;
    }
    final existing = _items.indexWhere((item) => item.id == id);
    final notification = BackendNotification(
      id: id,
      userId: 0,
      userName: '',
      eventType: realtime.eventType,
      title: realtime.title,
      body: realtime.body,
      data: realtime.data,
      createdAt: realtime.createdAt ?? DateTime.now(),
    );
    if (existing >= 0) {
      _items[existing] = _copyNotification(
        notification,
        readAt: _items[existing].readAt,
      );
    } else {
      _items.insert(0, notification);
      _unreadCount++;
    }
    if (_refreshing) _realtimeDuringRefresh.add(id);
    _sortAndDedupe();
    notifyListeners();
    if (realtime.eventType == 'message.received') {
      final rawThreadId = realtime.data['thread_id'];
      final callback = onMessageReceived;
      if (callback != null && _markMessageNotificationHandled(id)) {
        unawaited(callback(rawThreadId == null ? null : '$rawThreadId'));
      }
    }
  }

  Set<String?> _newMessageThreads(Iterable<BackendNotification> values) {
    if (onMessageReceived == null) return const <String?>{};
    final threads = <String?>{};
    for (final item in values) {
      if (item.eventType != 'message.received' ||
          !_markMessageNotificationHandled(item.id)) {
        continue;
      }
      final rawThreadId = item.data['thread_id'];
      threads.add(rawThreadId == null ? null : '$rawThreadId');
    }
    return threads;
  }

  bool _markMessageNotificationHandled(int id) {
    if (!_handledMessageNotificationIds.add(id)) return false;
    if (_handledMessageNotificationIds.length > 1024) {
      _handledMessageNotificationIds.remove(
        _handledMessageNotificationIds.first,
      );
    }
    return true;
  }

  Future<void> _refreshMissedMessageThreads(Set<String?> threadIds) async {
    final callback = onMessageReceived;
    if (callback == null || threadIds.isEmpty) return;
    for (final threadId in threadIds) {
      try {
        await callback(threadId);
      } on Object {
        // The notification feed is still valid. Messaging owns its own retry
        // state when refreshing the referenced conversation fails.
      }
    }
  }

  void _handleRealtimeStatus(NotificationRealtimeStatus status) {
    notifyListeners();
    if (status == NotificationRealtimeStatus.authenticationRequired) {
      final callback = onUnauthorized;
      if (callback != null) unawaited(callback());
    }
  }

  void _sortAndDedupe() {
    final byId = <int, BackendNotification>{};
    for (final item in _items) {
      byId[item.id] = item;
    }
    _items
      ..clear()
      ..addAll(byId.values)
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
  }

  BackendNotification _copyNotification(
    BackendNotification value, {
    DateTime? readAt,
    bool clearReadAt = false,
  }) => BackendNotification(
    id: value.id,
    userId: value.userId,
    userName: value.userName,
    eventType: value.eventType,
    title: value.title,
    body: value.body,
    data: value.data,
    readAt: clearReadAt ? null : readAt ?? value.readAt,
    createdAt: value.createdAt,
  );

  void _rollbackRead(int notificationId, {required DateTime optimisticReadAt}) {
    final currentIndex = _items.indexWhere((item) => item.id == notificationId);
    if (currentIndex < 0 || _items[currentIndex].readAt != optimisticReadAt) {
      return;
    }
    _items[currentIndex] = _copyNotification(
      _items[currentIndex],
      clearReadAt: true,
    );
    _unreadCount++;
  }

  void _rollbackMarkAll(
    Set<int> originallyUnreadIds, {
    required DateTime optimisticReadAt,
  }) {
    var restored = 0;
    for (var index = 0; index < _items.length; index++) {
      final current = _items[index];
      if (!originallyUnreadIds.contains(current.id) ||
          current.readAt != optimisticReadAt) {
        continue;
      }
      _items[index] = _copyNotification(current, clearReadAt: true);
      restored++;
    }
    _unreadCount += restored;
  }

  String? _cursorToken(String? next) {
    if (next == null || next.isEmpty) return null;
    final uri = Uri.tryParse(next);
    return uri?.queryParameters['cursor'] ?? next;
  }

  bool _isCurrent(int generation) => _started && generation == _generation;

  Future<void> _handleApiError(ApiException error) async {
    if (error.statusCode == 401) await onUnauthorized?.call();
  }

  @override
  void dispose() {
    ++_generation;
    unawaited(_notificationSubscription?.cancel());
    unawaited(_statusSubscription?.cancel());
    unawaited(_realtime.dispose());
    super.dispose();
  }
}
