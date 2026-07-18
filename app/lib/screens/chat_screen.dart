import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../features/messaging/messaging_controller.dart';
import '../features/messaging/messaging_l10n.dart';
import '../features/messaging/messaging_models.dart';
import '../features/messaging/messaging_widgets.dart';
import '../theme/sf_theme.dart';
import '../utils/formatters.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.managementMode = false});

  final bool managementMode;

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
  Timer? _recordingTimer;
  Duration _recorded = Duration.zero;
  bool _showEmoji = false;
  bool _searchMode = false;
  bool _searchRouteConsumed = false;
  bool _sending = false;
  String? _markedReadThread;

  MessagingController get _controller => MessagingController.shared;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingWatch.stop();
    _composer.dispose();
    _search.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  MessagingThread? _thread(BuildContext context) {
    final requested = GoRouterState.of(context).uri.queryParameters['thread'];
    return _controller.threadById(requested) ?? _controller.threads.firstOrNull;
  }

  void _markRead(MessagingThread thread) {
    if (_markedReadThread == thread.id) return;
    _markedReadThread = thread.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.markRead([thread.id]);
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

  void _startRecording() {
    final m = MessagingL10n.of(context);
    SfToast.show(
      context,
      title: m.text('voice_message'),
      message: m.text('voice_demo_notice'),
      tone: SfToastTone.warning,
    );
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    _recordingWatch
      ..reset()
      ..start();
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _recorded += const Duration(milliseconds: 100));
      if (_recorded >= const Duration(minutes: 1)) _finishRecording();
    });
    setState(() {
      _recorded = Duration.zero;
      _showEmoji = false;
    });
  }

  Future<void> _finishRecording() async {
    final thread = _thread(context);
    if (thread == null || !_recordingWatch.isRunning) return;
    _recordingWatch.stop();
    _recordingTimer?.cancel();
    final duration = _recorded;
    setState(() => _recorded = Duration.zero);
    try {
      await _controller.sendVoice(thread.id, duration: duration);
      if (mounted) _scrollToEnd();
    } on ArgumentError catch (error) {
      if (mounted) _showError(MessagingL10n.of(context).error(error));
    }
  }

  void _cancelRecording() {
    _recordingWatch
      ..stop()
      ..reset();
    _recordingTimer?.cancel();
    setState(() => _recorded = Duration.zero);
  }

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
    final m = MessagingL10n.of(context);
    final session = app.session;
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return SfScaffold(body: SfErrorState(title: m.text('permission_denied')));
    }
    _controller.initialize(
      userId: session.userId,
      userName: session.displayName,
      sourceThreads: app.messageThreads,
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
        _markRead(thread);
        final normalized = _search.text.trim().toLowerCase();
        final messages = normalized.isEmpty
            ? thread.messages
            : thread.messages
                  .where(
                    (message) =>
                        message.preview.toLowerCase().contains(normalized),
                  )
                  .toList(growable: false);

        return SfScaffold(
          dismissKeyboardOnTap: false,
          resizeToAvoidBottomInset: true,
          top: _buildHeader(context, thread),
          body: Stack(
            children: [
              if (thread.messages.isEmpty)
                SfEmptyState(
                  title: m.text('start_chat'),
                  message: m.text('send_first_message'),
                  icon: SfIcons.chat,
                )
              else if (messages.isEmpty)
                SfEmptyState(
                  title: m.text('message_not_found'),
                  message: m.text('change_search'),
                  icon: SfIcons.search,
                )
              else
                ListView.builder(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 22),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message.senderId == session.userId;
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
                                ? () => _openMedia(context, message)
                                : () => _toggleMessage(message.id),
                            onLongPress: () => _toggleMessage(message.id),
                            onReact: (emoji) =>
                                _controller.react(thread.id, message.id, emoji),
                          ),
                        ),
                        const SizedBox(height: 9),
                      ],
                    );
                  },
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
                    onDelete: () {
                      _controller.deleteMessages(thread.id, _selectedMessages);
                      setState(_selectedMessages.clear);
                    },
                    onClose: () => setState(_selectedMessages.clear),
                  ),
                ),
            ],
          ),
          bottom: _selectedMessages.isNotEmpty
              ? const SizedBox.shrink()
              : _Composer(
                  controller: _composer,
                  focusNode: _focus,
                  showEmoji: _showEmoji,
                  sending: _sending,
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
                  onRecordStart: _startRecording,
                  onRecordFinish: _finishRecording,
                  onRecordCancel: _cancelRecording,
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
      subtitle: thread.contact.isOnline
          ? m.text('online_now')
          : thread.isMuted
          ? m.text('notifications_muted')
          : widget.managementMode
          ? m.text('staff_coordination')
          : m.text('staff_chat'),
      onBack: () => context.pop(),
      onSearch: () => setState(() => _searchMode = true),
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
                    await _controller.sendImage(
                      thread.id,
                      label: m.text('board_photo_file'),
                    );
                    if (mounted) {
                      _showDemoMediaSaved(m);
                      _scrollToEnd();
                    }
                  },
                ),
                _AttachmentOption(
                  icon: Icons.play_circle_fill_rounded,
                  title: m.text('lesson_clip'),
                  subtitle: m.text('video_allowed'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _controller.sendVideo(
                      thread.id,
                      label: m.text('lesson_clip_file'),
                      duration: const Duration(seconds: 48),
                    );
                    if (mounted) {
                      _showDemoMediaSaved(m);
                      _scrollToEnd();
                    }
                  },
                ),
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

  void _openMedia(BuildContext context, MessagingMessage message) {
    final m = MessagingL10n.of(context);
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
                        else ...[
                          Icon(
                            message.kind == MessagingKind.image
                                ? Icons.image_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 96,
                          ),
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

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.thread,
    required this.subtitle,
    required this.onBack,
    required this.onSearch,
    required this.onProfile,
  });

  final MessagingThread thread;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSearch;
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
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: m.text('search_in_chat'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  tooltip: m.text('clear_search'),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              else
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
                                  onPressed: onRecordStart,
                                  icon: const Icon(Icons.mic_rounded),
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
    '😂',
    '😍',
    '🤩',
    '😊',
    '👍',
    '👏',
    '🙏',
    '💪',
    '✅',
    '🔥',
    '💡',
    '📚',
    '⭐',
    '🎉',
    '❤️',
    '🤝',
    '👀',
    '🙌',
    '📝',
  ];

  @override
  Widget build(BuildContext context) {
    final m = MessagingL10n.of(context);
    return SizedBox(
      height: 156,
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
  });

  final MessagingMessage message;
  final bool mine;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.76).clamp(
      220.0,
      390.0,
    );
    return Semantics(
      label:
          '${message.senderName}. ${m.preview(message)}. ${SfFormatters.time(message.sentAt)}',
      selected: selected,
      child: Align(
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
                _MessageContent(message: message, mine: mine && !selected),
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
  const _MessageContent({required this.message, required this.mine});

  final MessagingMessage message;
  final bool mine;

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
          child: Container(
            width: 230,
            height: 145,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accentSoft, c.primarySoft],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_rounded, size: 44, color: c.primary),
                const SizedBox(height: 8),
                Text(
                  message.mediaLabel ?? m.text('image'),
                  textAlign: TextAlign.center,
                  style: SfType.ui(
                    size: 12,
                    weight: FontWeight.w700,
                    color: c.primaryInk,
                  ),
                ),
              ],
            ),
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
                          message.mediaLabel ?? m.text('video'),
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
          child: _VoicePlayer(message: message, mine: mine),
        );
    }
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
  });

  final MessagingMessage message;
  final bool mine;
  final bool wide;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  Timer? _timer;
  double _progress = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
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

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final playing = _timer?.isActive ?? false;
    return SizedBox(
      width: widget.wide ? 330 : 225,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: playing ? m.text('stop') : m.text('listen'),
            onPressed: _toggle,
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MessagingWaveform(progress: _progress, barCount: 22),
                Text(
                  messagingDuration(
                    widget.message.mediaDuration ?? Duration.zero,
                  ),
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
    return Padding(
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
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
              style: SfType.mono(size: 9, color: c.muted),
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
