import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../features/messaging/messaging_controller.dart';
import '../features/messaging/messaging_l10n.dart';
import '../features/messaging/messaging_models.dart';
import '../features/messaging/messaging_widgets.dart';
import '../features/messaging/voice_note_capture.dart';
import '../theme/sf_theme.dart';
import '../utils/formatters.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_adaptive_dialog.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_search_field.dart';
import '../widgets/sf_star.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.managementMode = false, this.voiceCapture});

  final bool managementMode;
  final VoiceNoteCapture? voiceCapture;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composer = TextEditingController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final Set<String> _selectedMessages = {};
  final Stopwatch _recordingWatch = Stopwatch();
  final ImagePicker _imagePicker = ImagePicker();
  late final VoiceNoteCapture _voiceCapture;
  Timer? _recordingTimer;
  Duration _recorded = Duration.zero;
  bool _showEmoji = false;
  bool _searchMode = false;
  bool _searchRouteConsumed = false;
  bool _sending = false;
  bool _recordingStarting = false;
  bool _showJumpToLatest = false;
  bool _dateFilterLoading = false;
  DateTime? _selectedDate;
  List<MessagingMessage>? _dateMessages;
  String? _timelineThreadId;
  int _timelineMessageCount = 0;
  String? _markedReadThread;
  String? _requestedRemoteThread;
  MessagingController? _activeController;

  MessagingController get _controller =>
      _activeController ?? MessagingController.shared;

  @override
  void initState() {
    super.initState();
    _voiceCapture = widget.voiceCapture ?? Mp3VoiceNoteCapture();
    _scroll.addListener(_handleTimelineScroll);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingWatch.stop();
    unawaited(_voiceCapture.dispose());
    _composer.dispose();
    _search.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  MessagingThread? _thread(BuildContext context) {
    final requested = GoRouterState.of(context).uri.queryParameters['thread'];
    if (requested != null && requested.trim().isNotEmpty) {
      return _controller.threadById(requested);
    }
    return _controller.threads.firstOrNull;
  }

  void _markRead(MessagingThread thread) {
    if (_markedReadThread == thread.id) return;
    _markedReadThread = thread.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.markRead([thread.id]);
    });
  }

  void _ensureRemoteMessages(MessagingThread thread) {
    if (!_controller.isProduction ||
        _controller.isThreadLoaded(thread.id) ||
        _requestedRemoteThread == thread.id) {
      return;
    }
    _requestedRemoteThread = thread.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _controller.loadThreadMessages(thread.id);
      if (mounted) _scrollToEnd();
    });
  }

  Future<void> _sendText(MessagingThread thread) async {
    if (_sending || _composer.text.trim().isEmpty) return;
    final text = _composer.text;
    _composer.clear();
    setState(() {
      _sending = true;
      _showEmoji = false;
    });
    try {
      await _controller.sendText(thread.id, text);
      if (!mounted) return;
      _focus.requestFocus();
      _scrollToEnd();
    } on ArgumentError catch (error) {
      if (mounted) _showError(MessagingL10n.of(context).error(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final duration = SfMotion.resolve(
        context,
        const Duration(milliseconds: 380),
        enabled: !AppScope.of(context).settings.reducedMotion,
      );
      if (duration == Duration.zero) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleTimelineScroll() {
    if (!_scroll.hasClients) return;
    final distance = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    final show = distance > 180;
    if (show == _showJumpToLatest || !mounted) return;
    setState(() => _showJumpToLatest = show);
  }

  void _syncTimeline(MessagingThread thread) {
    final changedThread = _timelineThreadId != thread.id;
    final addedMessage = thread.messages.length > _timelineMessageCount;
    final shouldFollowLatest =
        changedThread ||
        (addedMessage && !_showJumpToLatest && _selectedDate == null);
    if (changedThread) {
      _timelineThreadId = thread.id;
      _selectedDate = null;
      _dateMessages = null;
      _dateFilterLoading = false;
      _showJumpToLatest = false;
    }
    _timelineMessageCount = thread.messages.length;
    if (shouldFollowLatest) _scrollToEnd();
  }

  Future<void> _pickTimelineDate(MessagingThread thread) async {
    if (_dateFilterLoading ||
        (!_controller.isProduction && thread.messages.isEmpty)) {
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late final DateTime first;
    late final DateTime last;
    if (_controller.isProduction) {
      // The normal timeline only contains its newest page. Do not make that
      // partial page the calendar's artificial history boundary.
      first = DateTime(2000, 1, 1);
      last = today;
    } else {
      final dates = thread.messages.map((message) => message.sentAt.toLocal());
      first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      last = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    }
    final preferred =
        _selectedDate ?? (_controller.isProduction ? today : last);
    final initial = preferred.isBefore(first)
        ? first
        : preferred.isAfter(last)
        ? last
        : preferred;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(last.year, last.month, last.day),
      helpText: _timelineCopy(
        context,
        uz: 'Xabarlar sanasini tanlang',
        ru: '\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0434\u0430\u0442\u0443 \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0439',
        en: 'Choose message date',
      ),
    );
    if (picked == null || !mounted) return;
    if (!_controller.isProduction) {
      setState(() {
        _selectedDate = picked;
        _dateMessages = thread.messages
            .where((message) => _sameDay(message.sentAt, picked))
            .toList(growable: false);
      });
      _jumpToTimelineStart();
      return;
    }

    setState(() => _dateFilterLoading = true);
    try {
      final messages = await _controller.loadMessagesForLocalDay(
        thread.id,
        picked,
      );
      if (!mounted || _timelineThreadId != thread.id) return;
      setState(() {
        _selectedDate = picked;
        _dateMessages = messages;
        _dateFilterLoading = false;
      });
      _jumpToTimelineStart();
    } on Object catch (error) {
      if (!mounted || _timelineThreadId != thread.id) return;
      setState(() => _dateFilterLoading = false);
      _showError(MessagingL10n.of(context).error(error));
    }
  }

  void _jumpToTimelineStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.minScrollExtent);
    });
  }

  Future<void> _clearTimelineDate() async {
    if (_dateFilterLoading) return;
    final thread = _thread(context);
    if (_controller.isProduction && thread != null) {
      setState(() => _dateFilterLoading = true);
      try {
        await _controller.loadThreadMessages(thread.id, refresh: true);
        if (!mounted || _timelineThreadId != thread.id) return;
        if (_controller.backendUnavailable ||
            _controller.backendError != null) {
          throw ArgumentError(
            _controller.backendError ??
                _timelineCopy(
                  context,
                  uz: 'Eng yangi xabarlarni yuklab bo\u2018lmadi.',
                  ru: '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u043d\u043e\u0432\u0435\u0439\u0448\u0438\u0435 \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u044f.',
                  en: 'Could not load the latest messages.',
                ),
          );
        }
      } on Object catch (error) {
        if (!mounted || _timelineThreadId != thread.id) return;
        setState(() => _dateFilterLoading = false);
        _showError(MessagingL10n.of(context).error(error));
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedDate = null;
      _dateMessages = null;
      _dateFilterLoading = false;
    });
    _scrollToEnd();
  }

  Future<void> _refreshTimeline(MessagingThread thread) async {
    final selected = _selectedDate;
    if (selected == null) {
      if (_controller.isProduction) {
        await _controller.loadThreadMessages(thread.id, refresh: true);
        if (mounted &&
            (_controller.backendUnavailable ||
                _controller.backendError != null)) {
          _showError(
            _controller.backendError ??
                _timelineCopy(
                  context,
                  uz: 'Xabarlarni yangilab bo\u2018lmadi.',
                  ru: '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u044f.',
                  en: 'Could not refresh messages.',
                ),
          );
        }
      }
      return;
    }
    if (!_controller.isProduction) {
      if (!mounted) return;
      setState(() {
        _dateMessages = thread.messages
            .where((message) => _sameDay(message.sentAt, selected))
            .toList(growable: false);
      });
      return;
    }
    if (_dateFilterLoading) return;
    setState(() => _dateFilterLoading = true);
    try {
      final messages = await _controller.loadMessagesForLocalDay(
        thread.id,
        selected,
      );
      if (!mounted ||
          _timelineThreadId != thread.id ||
          _selectedDate != selected) {
        return;
      }
      setState(() => _dateMessages = messages);
    } on Object catch (error) {
      if (mounted && _timelineThreadId == thread.id) {
        _showError(MessagingL10n.of(context).error(error));
      }
    } finally {
      if (mounted &&
          _timelineThreadId == thread.id &&
          _selectedDate == selected) {
        setState(() => _dateFilterLoading = false);
      }
    }
  }

  Future<void> _startRecording() async {
    if (_recordingStarting || _recordingWatch.isRunning) return;
    final m = MessagingL10n.of(context);
    setState(() => _recordingStarting = true);
    try {
      if (_controller.isProduction) {
        await _voiceCapture.start();
      } else {
        SfToast.show(
          context,
          title: m.text('voice_message'),
          message: m.text('voice_demo_notice'),
          tone: SfToastTone.warning,
        );
      }
      if (!mounted) {
        if (_controller.isProduction) await _voiceCapture.cancel();
        return;
      }
      HapticFeedback.mediumImpact();
      _focus.unfocus();
      _recordingWatch
        ..reset()
        ..start();
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() => _recorded += const Duration(milliseconds: 100));
        if (_recorded >= const Duration(minutes: 1)) {
          unawaited(_finishRecording());
        }
      });
      setState(() {
        _recorded = Duration.zero;
        _showEmoji = false;
      });
    } on VoiceCaptureException catch (error) {
      if (mounted) _showError(_voiceCaptureError(m, error));
    } on Object {
      if (mounted) _showError(m.text('voice_capture_failed'));
    } finally {
      if (mounted) setState(() => _recordingStarting = false);
    }
  }

  Future<void> _finishRecording() async {
    final thread = _thread(context);
    if (thread == null || !_recordingWatch.isRunning) return;
    final stopwatchDuration = _recordingWatch.elapsed;
    _recordingWatch.stop();
    _recordingTimer?.cancel();
    final duration = stopwatchDuration > _recorded
        ? stopwatchDuration
        : _recorded;
    setState(() => _recorded = Duration.zero);
    if (duration < const Duration(milliseconds: 500)) {
      if (_controller.isProduction) await _voiceCapture.cancel();
      if (mounted) {
        _showError(MessagingL10n.of(context).text('voice_too_short'));
      }
      return;
    }
    setState(() => _sending = true);
    try {
      if (_controller.isProduction) {
        final voice = await _voiceCapture.stop(duration);
        await _controller.sendAttachment(
          threadId: thread.id,
          filename: voice.filename,
          contentType: voice.contentType,
          bytes: voice.bytes,
          kind: MessagingKind.voice,
          duration: voice.duration,
        );
      } else {
        await _controller.sendVoice(thread.id, duration: duration);
      }
      if (mounted) _scrollToEnd();
    } on ArgumentError catch (error) {
      if (mounted) _showError(MessagingL10n.of(context).error(error));
    } on VoiceCaptureException catch (error) {
      if (mounted) {
        _showError(_voiceCaptureError(MessagingL10n.of(context), error));
      }
    } on Object {
      if (mounted) {
        _showError(MessagingL10n.of(context).text('voice_send_failed'));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _cancelRecording() {
    _recordingWatch
      ..stop()
      ..reset();
    _recordingTimer?.cancel();
    if (_controller.isProduction) unawaited(_voiceCapture.cancel());
    setState(() => _recorded = Duration.zero);
  }

  String _voiceCaptureError(
    MessagingL10n messages,
    VoiceCaptureException error,
  ) => switch (error.failure) {
    VoiceCaptureFailure.permissionDenied => messages.text(
      'voice_permission_denied',
    ),
    VoiceCaptureFailure.unsupported => messages.text('voice_unsupported'),
    VoiceCaptureFailure.captureFailed => messages.text('voice_capture_failed'),
  };

  void _toggleMessage(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMessages.contains(id)
          ? _selectedMessages.remove(id)
          : _selectedMessages.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    _activeController = app.messagingController;
    final m = MessagingL10n.of(context);
    final session = app.session;
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return SfScaffold(body: SfErrorState(title: m.text('permission_denied')));
    }
    _controller.initialize(
      userId: session.userId,
      userName: session.displayName,
      sourceThreads: app.messageThreads,
      storageScope: app.messagingStorageScope,
    );

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isRestoring) return _restoringMessages(context);
        if (!_searchRouteConsumed &&
            GoRouterState.of(context).uri.queryParameters['search'] == '1') {
          _searchMode = true;
          _searchRouteConsumed = true;
        }
        final thread = _thread(context);
        if (thread == null) return _missingChat(context);
        _ensureRemoteMessages(thread);
        _markRead(thread);
        _syncTimeline(thread);
        final normalized = _search.text.trim().toLowerCase();
        final timelineMessages = _selectedDate == null
            ? thread.messages
            : (_dateMessages ?? const <MessagingMessage>[]);
        final searchedMessages = normalized.isEmpty
            ? timelineMessages
            : timelineMessages
                  .where(
                    (message) =>
                        message.preview.toLowerCase().contains(normalized),
                  )
                  .toList(growable: false);
        final messages = searchedMessages;
        final showOlderMessages =
            _selectedDate == null && _controller.hasOlderMessages(thread.id);

        return SfScaffold(
          dismissKeyboardOnTap: false,
          resizeToAvoidBottomInset: true,
          top: _buildHeader(context, thread),
          body: Stack(
            children: [
              const Positioned.fill(child: _ChatStarBackdrop()),
              if (_controller.isProduction &&
                  !_controller.isThreadLoaded(thread.id) &&
                  thread.messages.isEmpty)
                const SfLoadingState(
                  label: 'Xabarlar serverdan olinmoqda\u2026',
                )
              else if (_controller.isProduction &&
                  thread.messages.isEmpty &&
                  _controller.backendError != null)
                SfErrorState(
                  title: 'Xabarlar yuklanmadi',
                  message: _controller.backendError,
                  onRetry: () =>
                      _controller.loadThreadMessages(thread.id, refresh: true),
                )
              else if (thread.messages.isEmpty)
                SfEmptyState(
                  title: m.text('start_chat'),
                  message: m.text('send_first_message'),
                  icon: SfIcons.chat,
                )
              else if (messages.isEmpty)
                SfEmptyState(
                  title: m.text('message_not_found'),
                  message: _selectedDate == null
                      ? m.text('change_search')
                      : _timelineCopy(
                          context,
                          uz: 'Bu sanada xabar yo\u2018q. Boshqa sanani tanlang yoki filtrni tozalang.',
                          ru: '\u0412 \u044d\u0442\u0443 \u0434\u0430\u0442\u0443 \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0439 \u043d\u0435\u0442. \u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0434\u0440\u0443\u0433\u0443\u044e \u0434\u0430\u0442\u0443 \u0438\u043b\u0438 \u0441\u0431\u0440\u043e\u0441\u044c\u0442\u0435 \u0444\u0438\u043b\u044c\u0442\u0440.',
                          en: 'No messages on this date. Choose another date or clear the filter.',
                        ),
                  icon: SfIcons.search,
                )
              else
                RefreshIndicator(
                  onRefresh: () => _refreshTimeline(thread),
                  child: ListView.builder(
                    key: const ValueKey('chat-timeline'),
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      _selectedDate == null ? 12 : 64,
                      12,
                      22,
                    ),
                    itemCount: messages.length + (showOlderMessages ? 1 : 0),
                    itemBuilder: (context, rawIndex) {
                      final hasOlder = showOlderMessages;
                      if (hasOlder && rawIndex == 0) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextButton.icon(
                              onPressed: _controller.isLoadingMore
                                  ? null
                                  : () => _controller.loadOlderMessages(
                                      thread.id,
                                    ),
                              icon: _controller.isLoadingMore
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.history_rounded),
                              label: const Text('Oldingi xabarlarni yuklash'),
                            ),
                          ),
                        );
                      }
                      final index = rawIndex - (hasOlder ? 1 : 0);
                      final message = messages[index];
                      final mine =
                          message.senderId == _controller.currentUserId;
                      final previous = index == 0 ? null : messages[index - 1];
                      final showDay =
                          previous == null ||
                          !_sameDay(previous.sentAt, message.sentAt);
                      return Column(
                        children: [
                          if (showDay) _DayDivider(date: message.sentAt),
                          _MessageEntrance(
                            key: ValueKey(message.id),
                            enabled: !app.settings.reducedMotion,
                            child: _MessageBubble(
                              message: message,
                              mine: mine,
                              selected: _selectedMessages.contains(message.id),
                              onTap: _selectedMessages.isEmpty
                                  ? () => _openMedia(context, thread, message)
                                  : () => _toggleMessage(message.id),
                              onLongPress: () => _toggleMessage(message.id),
                              resolveVoiceSource:
                                  message.kind == MessagingKind.voice &&
                                      !message.isDemoMedia &&
                                      message.attachmentKeys.isNotEmpty
                                  ? () => _voiceSourceUri(thread, message)
                                  : null,
                              resolveMediaSource:
                                  !message.isDemoMedia &&
                                      message.attachmentKeys.isNotEmpty
                                  ? () => _attachmentSourceUri(thread, message)
                                  : null,
                              onReact: (emoji) => _controller.react(
                                thread.id,
                                message.id,
                                emoji,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                        ],
                      );
                    },
                  ),
                ),
              if (_selectedDate != null)
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: _ActiveDateFilter(
                    date: _selectedDate!,
                    loading: _dateFilterLoading,
                    onClear: () => unawaited(_clearTimelineDate()),
                  ),
                ),
              Positioned(
                right: 14,
                bottom: _selectedMessages.isNotEmpty ? 76 : 14,
                child: AnimatedSwitcher(
                  duration: SfMotion.resolve(
                    context,
                    const Duration(milliseconds: 180),
                    enabled: !app.settings.reducedMotion,
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child:
                      !_dateFilterLoading &&
                          _showJumpToLatest &&
                          messages.isNotEmpty
                      ? _JumpToLatestButton(
                          key: const ValueKey('chat-jump-to-latest'),
                          onPressed: _selectedDate == null
                              ? _scrollToEnd
                              : () => unawaited(_clearTimelineDate()),
                        )
                      : const SizedBox.shrink(key: ValueKey('chat-at-latest')),
                ),
              ),
              if (_selectedMessages.isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _MessageActionBar(
                    count: _selectedMessages.length,
                    onReact: (emoji) {
                      for (final id in _selectedMessages) {
                        _controller.react(thread.id, id, emoji);
                      }
                      setState(_selectedMessages.clear);
                    },
                    onCopy: () => _copySelected(thread),
                    onDelete: () => unawaited(_deleteSelectedMessages(thread)),
                    onClose: () => setState(_selectedMessages.clear),
                  ),
                ),
            ],
          ),
          bottom: _selectedMessages.isNotEmpty
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.uploadingThreadId == thread.id)
                      _AttachmentUploadProgress(
                        value: _controller.uploadProgress,
                        onCancel: _controller.cancelAttachmentUpload,
                      ),
                    _Composer(
                      controller: _composer,
                      focusNode: _focus,
                      showEmoji: _showEmoji,
                      sending: _sending,
                      recordingStarting: _recordingStarting,
                      recording: _recordingWatch.isRunning,
                      recorded: _recorded,
                      onChanged: (_) => setState(() {}),
                      onSend: () => _sendText(thread),
                      onAttach: () => _showAttachments(context, thread),
                      onEmojiToggle: () => setState(() {
                        _showEmoji = !_showEmoji;
                        if (_showEmoji) _focus.unfocus();
                      }),
                      onEmoji: (emoji) {
                        final selection = _composer.selection;
                        final offset = selection.isValid
                            ? selection.baseOffset
                            : _composer.text.length;
                        _composer.text = _composer.text.replaceRange(
                          offset,
                          offset,
                          emoji,
                        );
                        _composer.selection = TextSelection.collapsed(
                          offset: offset + emoji.length,
                        );
                        setState(() {});
                      },
                      onRecordStart: () => unawaited(_startRecording()),
                      onRecordFinish: _finishRecording,
                      onRecordCancel: _cancelRecording,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MessagingThread thread) {
    final m = MessagingL10n.of(context);
    if (_searchMode) {
      return _ChatSearchHeader(
        controller: _search,
        onChanged: (_) => setState(() {}),
        onClose: () => setState(() {
          _searchMode = false;
          _search.clear();
        }),
      );
    }
    return _ChatHeader(
      thread: thread,
      subtitle: _controller.isProduction
          ? 'Server suhbati · bildirishnomalar sinxronlangan'
          : thread.contact.isOnline
          ? m.text('online_now')
          : thread.isMuted
          ? m.text('notifications_muted')
          : widget.managementMode
          ? m.text('staff_coordination')
          : m.text('staff_chat'),
      onBack: () => context.pop(),
      onSearch: () => setState(() => _searchMode = true),
      calendarLoading: _dateFilterLoading,
      onCalendar:
          _dateFilterLoading ||
              (!_controller.isProduction && thread.messages.isEmpty)
          ? null
          : () => unawaited(_pickTimelineDate(thread)),
      onProfile: () => context.push(
        '/messages/contact?thread=${Uri.encodeQueryComponent(thread.id)}',
      ),
    );
  }

  Widget _missingChat(BuildContext context) {
    final m = MessagingL10n.of(context);
    return SfScaffold(
      top: SfNavBar(
        title: m.text('chat'),
        leading: IconButton(
          tooltip: m.text('back'),
          onPressed: () => context.pop(),
          icon: const Icon(SfIcons.arrowL),
        ),
      ),
      body: SfEmptyState(title: m.text('chat_not_found'), icon: SfIcons.chat),
    );
  }

  Future<void> _showAttachments(
    BuildContext context,
    MessagingThread thread,
  ) async {
    final m = MessagingL10n.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  m.text('attach'),
                  style: SfType.ui(size: 20, weight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(m.text('attachment_help')),
                const SizedBox(height: 14),
                _AttachmentOption(
                  icon: Icons.photo_library_rounded,
                  title: m.text('board_photo'),
                  subtitle: m.text('image_size'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (_controller.isProduction) {
                      await _pickAndSendImage(thread);
                    } else {
                      await _controller.sendImage(
                        thread.id,
                        label: m.text('board_photo_file'),
                      );
                      if (mounted) _showDemoMediaSaved(m);
                    }
                    if (mounted) _scrollToEnd();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.play_circle_fill_rounded,
                  title: m.text('lesson_clip'),
                  subtitle: m.text('video_allowed'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (_controller.isProduction) {
                      await _pickAndSendVideo(thread);
                    } else {
                      await _controller.sendVideo(
                        thread.id,
                        label: m.text('lesson_clip_file'),
                        duration: const Duration(seconds: 48),
                      );
                      if (mounted) _showDemoMediaSaved(m);
                    }
                    if (mounted) _scrollToEnd();
                  },
                ),
                if (!_controller.isProduction)
                  _AttachmentOption(
                    icon: Icons.warning_amber_rounded,
                    title: m.text('seminar_recording'),
                    subtitle: m.text('video_over_limit'),
                    danger: true,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await _controller.sendVideo(
                          thread.id,
                          label: m.text('seminar_file'),
                          duration: const Duration(seconds: 74),
                        );
                      } on ArgumentError catch (error) {
                        if (mounted) _showError(m.error(error));
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(MessagingThread thread) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 94,
      );
      if (file == null || !mounted) return;
      final byteLength = await file.length();
      if (byteLength > MessagingController.maxAttachmentBytes) {
        throw ArgumentError('Fayl hajmi 25 MB dan oshmasligi kerak.');
      }
      final bytes = await file.readAsBytes();
      await _controller.sendAttachment(
        threadId: thread.id,
        filename: file.name,
        contentType: file.mimeType ?? _contentTypeFor(file.name, image: true),
        bytes: bytes,
        kind: MessagingKind.image,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        message: 'Rasm server suhbatiga yuborildi.',
        tone: SfToastTone.success,
      );
    } on ArgumentError catch (error) {
      if (mounted) _showError(MessagingL10n.of(context).error(error));
    } on PlatformException {
      if (mounted) _showError('Rasm tanlashga ruxsat berilmadi.');
    } on Object {
      if (mounted) _showError('Rasmni tayyorlab bo\u2018lmadi.');
    }
  }

  Future<void> _pickAndSendVideo(MessagingThread thread) async {
    VideoPlayerController? inspector;
    try {
      final file = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      if (file == null || !mounted) return;
      final byteLength = await file.length();
      if (byteLength > MessagingController.maxAttachmentBytes) {
        throw ArgumentError('Fayl hajmi 25 MB dan oshmasligi kerak.');
      }
      inspector = VideoPlayerController.file(File(file.path));
      await inspector.initialize();
      final duration = inspector.value.duration;
      if (duration <= Duration.zero || duration > const Duration(minutes: 1)) {
        throw ArgumentError('Video 1 daqiqadan oshmasligi kerak.');
      }
      final bytes = await file.readAsBytes();
      await _controller.sendAttachment(
        threadId: thread.id,
        filename: file.name,
        contentType: file.mimeType ?? _contentTypeFor(file.name, video: true),
        bytes: bytes,
        kind: MessagingKind.video,
        duration: duration,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        message: 'Video server suhbatiga yuborildi.',
        tone: SfToastTone.success,
      );
    } on ArgumentError catch (error) {
      if (mounted) _showError(MessagingL10n.of(context).error(error));
    } on PlatformException {
      if (mounted) _showError('Video tanlashga ruxsat berilmadi.');
    } on Object {
      if (mounted) _showError('Videoni tekshirib yoki yuborib bo\u2018lmadi.');
    } finally {
      await inspector?.dispose();
    }
  }

  String _contentTypeFor(
    String filename, {
    bool image = false,
    bool video = false,
  }) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      'mov' => 'video/quicktime',
      'm4v' => 'video/x-m4v',
      'webm' => 'video/webm',
      'mp4' => 'video/mp4',
      _ when image => 'image/jpeg',
      _ when video => 'video/mp4',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _copySelected(MessagingThread thread) async {
    final m = MessagingL10n.of(context);
    final text = thread.messages
        .where((message) => _selectedMessages.contains(message.id))
        .map((message) => '${message.senderName}: ${m.preview(message)}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(_selectedMessages.clear);
    SfToast.show(
      context,
      message: m.text('messages_copied'),
      tone: SfToastTone.success,
    );
  }

  Future<void> _deleteSelectedMessages(MessagingThread thread) async {
    final m = MessagingL10n.of(context);
    final ids = Set<String>.of(_selectedMessages);
    if (ids.isEmpty) return;
    final approved = await showSfConfirmDialog(
      context,
      title: m.text('delete_messages_question'),
      message: m.text(
        _controller.isProduction
            ? 'delete_messages_device_description'
            : 'delete_messages_description',
        {'count': ids.length},
      ),
      cancelLabel: m.text('cancel'),
      confirmLabel: m.text('delete'),
      destructive: true,
    );
    if (!approved || !mounted) return;
    _controller.deleteMessages(thread.id, ids);
    setState(_selectedMessages.clear);
    SfToast.show(
      context,
      message: m.text('messages_deleted', {'count': ids.length}),
      tone: SfToastTone.success,
    );
  }

  Future<void> _openMedia(
    BuildContext context,
    MessagingThread thread,
    MessagingMessage message,
  ) async {
    final m = MessagingL10n.of(context);
    if (message.kind == MessagingKind.voice &&
        !message.isDemoMedia &&
        message.attachmentKeys.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog.fullscreen(
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: m.text('close'),
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _VoicePlayer(
                      message: message,
                      wide: true,
                      resolveSource: () => _voiceSourceUri(thread, message),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    if (!message.isDemoMedia && message.attachmentKeys.isNotEmpty) {
      try {
        final url = await _controller.attachmentDownloadUrl(
          thread.id,
          message.attachmentKeys.first,
        );
        if (!context.mounted) return;
        final uri = Uri.parse(url);
        final extension = (message.mediaLabel ?? '')
            .split('.')
            .last
            .toLowerCase();
        final image = const <String>{
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'heic',
        }.contains(extension);
        if (!image) {
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!opened && context.mounted) {
            _showError('Faylni ochadigan ilova topilmadi.');
          }
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog.fullscreen(
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: m.text('close'),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Center(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          // Bound native image decoding. A malicious or simply
                          // enormous image must not allocate its full pixel
                          // buffer just to fit a phone-sized viewer.
                          cacheWidth: 2048,
                          cacheHeight: 2048,
                          filterQuality: FilterQuality.high,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const CircularProgressIndicator(),
                          errorBuilder: (_, _, _) => const SfErrorState(
                            title: 'Rasm ochilmadi',
                            message: 'Havola tugagan bo\u2018lishi mumkin.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } on ArgumentError catch (error) {
        if (context.mounted) _showError(m.error(error));
      } on Object {
        if (context.mounted) _showError('Faylni xavfsiz ochib bo\u2018lmadi.');
      }
      return;
    }
    if (message.kind == MessagingKind.text) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: m.text('close'),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isDemoMedia) ...[
                          const _DemoMediaBadge(),
                          const SizedBox(height: 16),
                        ],
                        if (message.kind == MessagingKind.voice)
                          _VoicePlayer(message: message, wide: true)
                        else if (message.kind == MessagingKind.image)
                          Icon(
                            Icons.image_rounded,
                            size: 96,
                            color: SfTheme.colorsOf(context).primary,
                          )
                        else ...[
                          Icon(Icons.play_circle_fill_rounded, size: 96),
                          const SizedBox(height: 18),
                          Text(
                            message.mediaLabel ?? m.preview(message),
                            textAlign: TextAlign.center,
                            style: SfType.ui(size: 20, weight: FontWeight.w800),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uri?> _voiceSourceUri(
    MessagingThread thread,
    MessagingMessage message,
  ) async {
    if (message.attachmentKeys.isEmpty) return null;
    try {
      final url = await _controller.attachmentDownloadUrl(
        thread.id,
        message.attachmentKeys.first,
      );
      return Uri.tryParse(url);
    } on ArgumentError catch (error) {
      if (mounted) _showError(MessagingL10n.of(context).error(error));
      return null;
    } on Object {
      if (mounted) {
        _showError(MessagingL10n.of(context).text('voice_play_failed'));
      }
      return null;
    }
  }

  Future<Uri?> _attachmentSourceUri(
    MessagingThread thread,
    MessagingMessage message,
  ) async {
    if (message.attachmentKeys.isEmpty) return null;
    try {
      final url = await _controller.attachmentDownloadUrl(
        thread.id,
        message.attachmentKeys.first,
      );
      return Uri.tryParse(url);
    } on Object {
      // Inline media owns its quiet error/retry state. Avoid surfacing signed
      // URLs in logs or repeatedly opening a toast while the timeline rebuilds.
      return null;
    }
  }

  void _showError(String message) {
    SfToast.show(context, message: message, tone: SfToastTone.error);
  }

  void _showDemoMediaSaved(MessagingL10n m) {
    SfToast.show(
      context,
      title: m.text('demo_media_badge'),
      message: m.text('demo_media_sent'),
      tone: SfToastTone.info,
    );
  }

  Widget _restoringMessages(BuildContext context) {
    final m = MessagingL10n.of(context);
    return SfScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(m.text('restoring_messages')),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}

String _timelineCopy(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (Localizations.maybeLocaleOf(context)?.languageCode) {
  'ru' => ru,
  'en' => en,
  _ => uz,
};

class _ChatStarBackdrop extends StatelessWidget {
  const _ChatStarBackdrop();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return IgnorePointer(
      key: const ValueKey('chat-star-background'),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              right: -82,
              top: -54,
              child: Opacity(
                opacity: 0.065,
                child: SfStar(size: 280, color: c.primary),
              ),
            ),
            Positioned(
              left: -58,
              bottom: 32,
              child: Opacity(
                opacity: 0.045,
                child: SfStar(size: 205, color: c.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveDateFilter extends StatelessWidget {
  const _ActiveDateFilter({
    required this.date,
    required this.loading,
    required this.onClear,
  });

  final DateTime date;
  final bool loading;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final label = MaterialLocalizations.of(context).formatMediumDate(date);
    return Center(
      child: Material(
        key: const ValueKey('chat-active-date-filter'),
        color: c.surface.withValues(alpha: 0.96),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: loading ? null : onClear,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 5, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_rounded, size: 16, color: c.primary),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: SfType.ui(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(width: 4),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.primary,
                      ),
                    ),
                  )
                else
                  IconButton(
                    key: const ValueKey('chat-clear-date-filter'),
                    tooltip: _timelineCopy(
                      context,
                      uz: 'Sana filtrini tozalash',
                      ru: '\u0421\u0431\u0440\u043e\u0441\u0438\u0442\u044c \u0444\u0438\u043b\u044c\u0442\u0440 \u0434\u0430\u0442\u044b',
                      en: 'Clear date filter',
                    ),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Material(
      color: c.surface,
      elevation: 7,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: CircleBorder(side: BorderSide(color: c.border)),
      child: IconButton(
        tooltip: _timelineCopy(
          context,
          uz: 'Eng yangi xabarga o\u2018tish',
          ru: '\u041a \u043f\u043e\u0441\u043b\u0435\u0434\u043d\u0435\u043c\u0443 \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u044e',
          en: 'Jump to latest message',
        ),
        onPressed: onPressed,
        color: c.primary,
        icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.thread,
    required this.subtitle,
    required this.onBack,
    required this.onSearch,
    required this.calendarLoading,
    required this.onCalendar,
    required this.onProfile,
  });

  final MessagingThread thread;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final bool calendarLoading;
  final VoidCallback? onCalendar;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return ColoredBox(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              IconButton(
                tooltip: m.text('back'),
                onPressed: onBack,
                icon: const Icon(SfIcons.arrowL),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onProfile,
                child: Hero(
                  tag: 'message-contact-${thread.contact.id}',
                  child: SfAvatar(name: thread.title, size: 38),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onProfile,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 14.5,
                            weight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(
                            size: 10.5,
                            color: thread.contact.isOnline
                                ? c.success
                                : c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: m.text('search_in_chat'),
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                key: const ValueKey('chat-date-filter-button'),
                tooltip: _timelineCopy(
                  context,
                  uz: 'Sana bo\u2018yicha xabarlar',
                  ru: '\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u044f \u043f\u043e \u0434\u0430\u0442\u0435',
                  en: 'Messages by date',
                ),
                onPressed: onCalendar,
                icon: calendarLoading
                    ? SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: c.primary,
                          semanticsLabel: _timelineCopy(
                            context,
                            uz: 'Sana xabarlari yuklanmoqda',
                            ru: '\u0417\u0430\u0433\u0440\u0443\u0436\u0430\u044e\u0442\u0441\u044f \u0441\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u044f \u0437\u0430 \u0434\u0430\u0442\u0443',
                            en: 'Loading messages for date',
                          ),
                        ),
                      )
                    : const Icon(Icons.calendar_month_rounded),
              ),
              IconButton(
                tooltip: m.text('profile'),
                onPressed: onProfile,
                icon: const Icon(Icons.more_vert_rounded),
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatSearchHeader extends StatelessWidget {
  const _ChatSearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return ColoredBox(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              IconButton(
                tooltip: m.text('close_search'),
                onPressed: onClose,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: SfSearchField(
                  key: const ValueKey('chat-message-search'),
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  hintText: m.text('search_in_chat'),
                  semanticLabel: m.text('search_in_chat'),
                  clearTooltip: m.text('clear_search'),
                  clearButtonKey: const ValueKey('chat-message-search-clear'),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.sending,
    required this.recordingStarting,
    required this.recording,
    required this.recorded,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.onEmojiToggle,
    required this.onEmoji,
    required this.onRecordStart,
    required this.onRecordFinish,
    required this.onRecordCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final bool sending;
  final bool recordingStarting;
  final bool recording;
  final Duration recorded;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onEmojiToggle;
  final ValueChanged<String> onEmoji;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordFinish;
  final VoidCallback onRecordCancel;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: SfMotion.resolve(
              context,
              const Duration(milliseconds: 220),
            ),
            child: recording
                ? Padding(
                    key: const ValueKey('recording'),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: m.text('cancel_recording'),
                          onPressed: onRecordCancel,
                          icon: Icon(Icons.delete_outline, color: c.danger),
                        ),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          messagingDuration(recorded),
                          style: SfType.mono(weight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MessagingWaveform(
                            progress: (recorded.inMilliseconds / 60000).clamp(
                              0,
                              1,
                            ),
                            barCount: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: onRecordFinish,
                          icon: const Icon(Icons.send_rounded),
                          label: Text(m.text('send')),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    key: const ValueKey('composer'),
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: m.text('emoji'),
                          onPressed: onEmojiToggle,
                          icon: Icon(
                            showEmoji
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                          ),
                        ),
                        Expanded(
                          child: SfTextField(
                            controller: controller,
                            focusNode: focusNode,
                            hint: m.text('write_message'),
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            onChanged: onChanged,
                            suffix: IconButton(
                              tooltip: m.text('attach_media'),
                              onPressed: onAttach,
                              icon: const Icon(Icons.attach_file_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedSwitcher(
                          duration: SfMotion.resolve(
                            context,
                            const Duration(milliseconds: 180),
                          ),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: controller.text.trim().isNotEmpty || sending
                              ? IconButton.filled(
                                  key: const ValueKey('send'),
                                  tooltip: m.text('send'),
                                  onPressed: sending ? null : onSend,
                                  icon: sending
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_upward_rounded),
                                )
                              : IconButton.filledTonal(
                                  key: const ValueKey('voice'),
                                  tooltip: m.text('record_voice'),
                                  onPressed: recordingStarting
                                      ? null
                                      : onRecordStart,
                                  icon: recordingStarting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.mic_rounded),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
          AnimatedSize(
            duration: SfMotion.resolve(
              context,
              const Duration(milliseconds: 220),
            ),
            curve: Curves.easeOutCubic,
            child: showEmoji && !recording
                ? _EmojiPicker(onEmoji: onEmoji)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.onEmoji});

  final ValueChanged<String> onEmoji;

  static const emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😂',
    '🤣',
    '🥹',
    '😊',
    '🙂',
    '😉',
    '😍',
    '🤩',
    '🥰',
    '😘',
    '😎',
    '🤓',
    '🧐',
    '🤔',
    '🫡',
    '😴',
    '😢',
    '😭',
    '😮',
    '😅',
    '😬',
    '🙃',
    '😇',
    '🥳',
    '👍',
    '👎',
    '👌',
    '✌️',
    '🤞',
    '👏',
    '🙏',
    '💪',
    '👋',
    '🤟',
    '🫶',
    '✅',
    '❌',
    '⚠️',
    '💯',
    '🔥',
    '💡',
    '📚',
    '📖',
    '✏️',
    '📌',
    '📅',
    '⏰',
    '⭐',
    '🎉',
    '🎊',
    '🏆',
    '🥇',
    '🎯',
    '❤️',
    '💙',
    '💚',
    '💛',
    '💜',
    '🤍',
    '🤝',
    '👀',
    '🙌',
    '📝',
    '💬',
    '📣',
    '🔔',
    '🚀',
    '✨',
    '🌟',
    '☀️',
    '🌙',
    '☕',
    '🍎',
    '🎓',
    '🏫',
  ];

  @override
  Widget build(BuildContext context) {
    final m = MessagingL10n.of(context);
    return SizedBox(
      height: 208,
      child: GridView.count(
        crossAxisCount: 8,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        children: [
          for (final emoji in emojis)
            Semantics(
              button: true,
              label: '${m.text('emoji')} $emoji',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onEmoji(emoji),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageEntrance extends StatefulWidget {
  const _MessageEntrance({
    super.key,
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  State<_MessageEntrance> createState() => _MessageEntranceState();
}

class _MessageEntranceState extends State<_MessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: widget.enabled
        ? const Duration(milliseconds: 320)
        : Duration.zero,
  )..forward();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: _animation, curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic),
          ),
      child: widget.child,
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onReact,
    this.resolveVoiceSource,
    this.resolveMediaSource,
  });

  final MessagingMessage message;
  final bool mine;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<String> onReact;
  final Future<Uri?> Function()? resolveVoiceSource;
  final Future<Uri?> Function()? resolveMediaSource;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final semanticPreview = message.kind == MessagingKind.image
        ? message.body.trim().isEmpty
              ? m.text('image')
              : '${m.text('image')}. ${message.body.trim()}'
        : m.preview(message);
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.76).clamp(
      220.0,
      390.0,
    );
    return Semantics(
      label:
          '${message.senderName}. $semanticPreview. ${SfFormatters.time(message.sentAt)}',
      selected: selected,
      child: Align(
        key: ValueKey('chat-message-${mine ? 'mine' : 'theirs'}-${message.id}'),
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: SfMotion.resolve(
              context,
              const Duration(milliseconds: 160),
            ),
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.all(
              message.kind == MessagingKind.text ? 11 : 7,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? c.accentSoft
                  : mine
                  ? c.primary
                  : c.surface,
              border: Border.all(
                color: selected
                    ? c.accent
                    : mine
                    ? c.primary
                    : c.border,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 5),
                bottomRight: Radius.circular(mine ? 5 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!mine)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(3, 1, 3, 5),
                    child: Text(
                      message.senderName,
                      style: SfType.ui(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: selected ? c.accentInk : c.primary,
                      ),
                    ),
                  ),
                _MessageContent(
                  message: message,
                  mine: mine && !selected,
                  resolveVoiceSource: resolveVoiceSource,
                  resolveMediaSource: resolveMediaSource,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 5, 3, 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        SfFormatters.time(message.sentAt),
                        style: SfType.mono(
                          size: 8.5,
                          color: mine && !selected
                              ? c.surface.withValues(alpha: 0.72)
                              : c.muted,
                        ),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 4),
                        _DeliveryIcon(
                          delivery: message.delivery,
                          color: selected
                              ? c.muted
                              : c.surface.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ),
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final entry in message.reactions.entries)
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text('${entry.key} ${entry.value}'),
                            onPressed: () => onReact(entry.key),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.mine,
    this.resolveVoiceSource,
    this.resolveMediaSource,
  });

  final MessagingMessage message;
  final bool mine;
  final Future<Uri?> Function()? resolveVoiceSource;
  final Future<Uri?> Function()? resolveMediaSource;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final foreground = mine ? c.surface : c.ink;
    switch (message.kind) {
      case MessagingKind.text:
        return Text(
          message.body,
          style: SfType.ui(size: 13.5, color: foreground, height: 1.42),
        );
      case MessagingKind.image:
        return _DemoMediaFrame(
          isDemo: message.isDemoMedia,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InlineImage(
                messageId: message.id,
                resolveSource: resolveMediaSource,
              ),
              if (message.body.trim().isNotEmpty) ...[
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    message.body.trim(),
                    style: SfType.ui(
                      size: 13.5,
                      color: foreground,
                      height: 1.42,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case MessagingKind.video:
        return _DemoMediaFrame(
          isDemo: message.isDemoMedia,
          child: Container(
            width: 230,
            height: 145,
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 54,
                  color: c.surface,
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 9,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.isDemoMedia
                              ? (message.mediaLabel ?? m.text('video'))
                              : m.text('video'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.ui(size: 11, color: c.surface),
                        ),
                      ),
                      Text(
                        messagingDuration(
                          message.mediaDuration ?? Duration.zero,
                        ),
                        style: SfType.mono(size: 9, color: c.surface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case MessagingKind.voice:
        return _DemoMediaFrame(
          isDemo: message.isDemoMedia,
          child: _VoicePlayer(
            message: message,
            mine: mine,
            resolveSource: resolveVoiceSource,
          ),
        );
    }
  }
}

class _InlineImage extends StatefulWidget {
  const _InlineImage({required this.messageId, this.resolveSource});

  final String messageId;
  final Future<Uri?> Function()? resolveSource;

  @override
  State<_InlineImage> createState() => _InlineImageState();
}

class _InlineImageState extends State<_InlineImage> {
  Future<Uri?>? _source;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _InlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId ||
        (oldWidget.resolveSource == null) != (widget.resolveSource == null)) {
      _reload();
    }
  }

  void _reload() {
    _source = widget.resolveSource?.call();
  }

  void _retry() => setState(_reload);

  @override
  Widget build(BuildContext context) {
    final resolver = widget.resolveSource;
    if (resolver == null) return const _InlineImagePlaceholder();
    return FutureBuilder<Uri?>(
      future: _source,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _InlineImagePlaceholder(loading: true);
        }
        final uri = snapshot.data;
        if (snapshot.hasError ||
            uri == null ||
            (uri.scheme != 'https' && uri.scheme != 'http')) {
          return _InlineImageError(onRetry: _retry);
        }
        return ClipRRect(
          key: ValueKey('chat-inline-image-${widget.messageId}'),
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            uri.toString(),
            width: 220,
            height: 148,
            fit: BoxFit.cover,
            // Three physical pixels per logical pixel keeps thumbnails crisp
            // without decoding enormous uploads at their source dimensions.
            cacheWidth: 660,
            cacheHeight: 444,
            filterQuality: FilterQuality.medium,
            frameBuilder: (context, child, frame, synchronouslyLoaded) =>
                synchronouslyLoaded || frame != null
                ? child
                : const _InlineImagePlaceholder(loading: true),
            errorBuilder: (_, _, _) => _InlineImageError(onRetry: _retry),
          ),
        );
      },
    );
  }
}

class _InlineImagePlaceholder extends StatelessWidget {
  const _InlineImagePlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      key: ValueKey(loading ? 'chat-image-loading' : 'chat-image-preview'),
      width: 220,
      height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.accentSoft, c.primarySoft],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: c.primary,
              ),
            )
          : Icon(Icons.image_rounded, size: 46, color: c.primary),
    );
  }
}

class _InlineImageError extends StatelessWidget {
  const _InlineImageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      key: const ValueKey('chat-image-error'),
      width: 220,
      height: 148,
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: IconButton.filledTonal(
        tooltip: _timelineCopy(
          context,
          uz: 'Rasmni qayta yuklash',
          ru: '\u041f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0443 \u0438\u0437\u043e\u0431\u0440\u0430\u0436\u0435\u043d\u0438\u044f',
          en: 'Retry image',
        ),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

class _DemoMediaFrame extends StatelessWidget {
  const _DemoMediaFrame({required this.isDemo, required this.child});

  final bool isDemo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (isDemo) ...[const _DemoMediaBadge(), const SizedBox(height: 6)],
      child,
    ],
  );
}

class _DemoMediaBadge extends StatelessWidget {
  const _DemoMediaBadge();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.warnSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.warn.withValues(alpha: .35)),
      ),
      child: Text(
        m.text('demo_media_badge'),
        style: SfType.eyebrow(color: c.warn, size: 8.5),
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({
    required this.message,
    this.mine = false,
    this.wide = false,
    this.resolveSource,
  });

  final MessagingMessage message;
  final bool mine;
  final bool wide;
  final Future<Uri?> Function()? resolveSource;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  Timer? _timer;
  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  double _progress = 0;
  Duration _position = Duration.zero;
  Duration? _remoteDuration;
  bool _loading = false;
  bool _remotePlaying = false;
  bool _sourceLoaded = false;
  bool _playbackFailed = false;

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.resolveSource != null) {
      await _toggleRemote();
      return;
    }
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      setState(() {});
      return;
    }
    final duration = widget.message.mediaDuration ?? const Duration(seconds: 1);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 100 / duration.inMilliseconds.clamp(100, 60000);
        if (_progress >= 1) {
          _progress = 0;
          timer.cancel();
        }
      });
    });
    setState(() {});
  }

  Future<void> _toggleRemote() async {
    if (_loading) return;
    final active = _player;
    if (active?.playing ?? false) {
      await active!.pause();
      return;
    }
    setState(() {
      _loading = true;
      _playbackFailed = false;
    });
    try {
      final player = active ?? _createPlayer();
      if (!_sourceLoaded) {
        final uri = await widget.resolveSource!.call();
        if (uri == null) {
          throw StateError('Voice attachment URL is unavailable.');
        }
        _remoteDuration = await player.setUrl(uri.toString());
        _sourceLoaded = true;
      }
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.play();
    } on Object {
      if (mounted) setState(() => _playbackFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    _player = player;
    _positionSubscription = player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
        final duration = _remoteDuration ?? widget.message.mediaDuration;
        _progress = duration == null || duration.inMilliseconds == 0
            ? 0
            : (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
      });
    });
    _durationSubscription = player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      setState(() => _remoteDuration = duration);
    });
    _stateSubscription = player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _remotePlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _progress = 0;
          _position = Duration.zero;
        }
      });
    });
    return player;
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final remote = widget.resolveSource != null;
    final playing = remote ? _remotePlaying : (_timer?.isActive ?? false);
    final duration = remote
        ? (_remoteDuration ?? widget.message.mediaDuration)
        : widget.message.mediaDuration;
    return SizedBox(
      width: widget.wide ? 330 : 225,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: playing ? m.text('stop') : m.text('listen'),
            onPressed: _loading ? null : () => unawaited(_toggle()),
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _playbackFailed
                        ? Icons.refresh_rounded
                        : playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MessagingWaveform(progress: _progress, barCount: 22),
                Text(
                  remote && playing
                      ? '${messagingDuration(_position)} / ${messagingDuration(duration ?? Duration.zero)}'
                      : messagingDuration(duration ?? Duration.zero),
                  style: SfType.mono(
                    size: 9,
                    color: widget.mine ? c.surface : c.muted,
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

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({required this.delivery, required this.color});

  final MessagingDelivery delivery;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
    switch (delivery) {
      MessagingDelivery.sending => Icons.schedule_rounded,
      MessagingDelivery.sent => Icons.check_rounded,
      MessagingDelivery.delivered ||
      MessagingDelivery.read => Icons.done_all_rounded,
    },
    size: 13,
    color: delivery == MessagingDelivery.read
        ? SfTheme.colorsOf(context).accent
        : color,
  );
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final label = day == today
        ? _timelineCopy(
            context,
            uz: 'Bugun',
            ru: '\u0421\u0435\u0433\u043e\u0434\u043d\u044f',
            en: 'Today',
          )
        : day == today.subtract(const Duration(days: 1))
        ? _timelineCopy(
            context,
            uz: 'Kecha',
            ru: '\u0412\u0447\u0435\u0440\u0430',
            en: 'Yesterday',
          )
        : MaterialLocalizations.of(context).formatMediumDate(local);
    return Padding(
      key: ValueKey('chat-day-${local.year}-${local.month}-${local.day}'),
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.92),
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Text(
              label,
              style: SfType.ui(
                size: 10,
                weight: FontWeight.w800,
                color: c.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageActionBar extends StatelessWidget {
  const _MessageActionBar({
    required this.count,
    required this.onReact,
    required this.onCopy,
    required this.onDelete,
    required this.onClose,
  });

  final int count;
  final ValueChanged<String> onReact;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return Material(
      elevation: 8,
      color: c.surface,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: m.text('close'),
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
            Text('$count', style: SfType.mono(weight: FontWeight.w800)),
            const Spacer(),
            for (final emoji in const ['👍', '❤️', '🔥'])
              IconButton(
                tooltip: m.text('reaction', {'emoji': emoji}),
                onPressed: () => onReact(emoji),
                icon: Text(emoji, style: const TextStyle(fontSize: 19)),
              ),
            IconButton(
              tooltip: m.text('copy'),
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: m.text('delete'),
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: c.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentUploadProgress extends StatelessWidget {
  const _AttachmentUploadProgress({
    required this.value,
    required this.onCancel,
  });

  final double? value;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      liveRegion: true,
      label: 'Fayl serverga yuklanmoqda',
      child: ColoredBox(
        color: c.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fayl himoyalangan serverga yuklanmoqda\u2026',
                      style: SfType.ui(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: value,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Yuklashni bekor qilish',
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: danger ? c.dangerSoft : c.primarySoft,
        foregroundColor: danger ? c.danger : c.primary,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
