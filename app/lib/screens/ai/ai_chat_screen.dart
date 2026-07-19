import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/backend_services_api.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_ai_badge.dart';
import '../../widgets/sf_adaptive_dialog.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pressable.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';
import '../services/backend_ai_screens.dart';
import 'ai_workspace_data.dart';

enum _AiMenuAction { clear, help }

enum _AiMessageAuthor { user, assistant }

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  final _scroll = ScrollController();
  final List<_AiConversationMessage> _messages = [];

  late AiWorkspaceCopy _copy;
  late AiStaffGroup _group;
  bool _initialized = false;
  bool _thinking = false;
  int _sequence = 0;
  int _requestGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    if (AppScope.maybeOf(context)?.backendApi != null) return;

    // Query context is deliberately read from GoRouter here so every group
    // card opens the same reusable workspace with its own data scope.
    final uri = GoRouterState.of(context).uri;
    _copy = AiWorkspaceCopy.of(context);
    _group = _copy.groupForId(uri.queryParameters['group']);
    _messages.add(_assistantMessage(_welcomeText()));
    final initialPrompt = uri.queryParameters['prompt']?.trim();
    if (initialPrompt != null && initialPrompt.isNotEmpty) {
      _messages
        ..add(_userMessage(initialPrompt))
        ..add(_assistantMessage(_copy.localReply(_group, initialPrompt)));
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _requestGeneration++;
    _composer.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _welcomeText() => _copy.welcome(_group);

  _AiConversationMessage _userMessage(String text) => _AiConversationMessage(
    id: 'user-${_sequence++}',
    author: _AiMessageAuthor.user,
    text: text,
  );

  _AiConversationMessage _assistantMessage(String text) =>
      _AiConversationMessage(
        id: 'assistant-${_sequence++}',
        author: _AiMessageAuthor.assistant,
        text: text,
      );

  void _sendComposer() => _sendPrompt(_composer.text);

  void _sendPrompt(String rawPrompt) {
    final prompt = rawPrompt.trim();
    if (prompt.isEmpty || _thinking) return;
    _composer.clear();
    _composerFocus.unfocus();
    final generation = ++_requestGeneration;
    setState(() {
      _messages.add(_userMessage(prompt));
      _thinking = true;
    });
    _scrollToEnd();

    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _thinking = false;
        _messages.add(_assistantMessage(_copy.localReply(_group, prompt)));
      });
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: SfMotion.resolve(context, SfMotion.emphasized),
        curve: SfMotion.enter,
      );
    });
  }

  Future<void> _handleMenu(_AiMenuAction action) async {
    switch (action) {
      case _AiMenuAction.clear:
        await _clearConversation();
      case _AiMenuAction.help:
        await _showHelp();
    }
  }

  Future<void> _clearConversation() async {
    final approved = await showSfConfirmDialog(
      context,
      title: _copy.clearConversationTitle,
      message: _copy.clearConversationDescription,
      cancelLabel: _copy.cancel,
      confirmLabel: _copy.clear,
      destructive: true,
      confirmKey: const Key('ai-confirm-clear'),
    );
    if (!approved || !mounted) return;

    _requestGeneration++;
    setState(() {
      _thinking = false;
      _messages
        ..clear()
        ..add(_assistantMessage(_welcomeText()));
    });
    _scrollToEnd();
  }

  Future<void> _showHelp() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_copy.helpTitle),
      content: Text(_copy.helpDescription),
      actions: [
        FilledButton(
          key: const Key('ai-close-help'),
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(_copy.understood),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final backend = AppScope.maybeOf(context)?.backendApi;
    if (backend != null) {
      final requestId = int.tryParse(
        GoRouterState.of(context).uri.queryParameters['request'] ?? '',
      );
      return BackendAiRequestDetailScreen(
        api: BackendServicesApi.fromApi(backend),
        requestId: requestId,
      );
    }
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: _ChatHeader(
        copy: _copy,
        group: _group,
        thinking: _thinking,
        onBack: () => context.pop(),
        onPrompt: _thinking ? null : _sendPrompt,
        onMenu: _handleMenu,
      ),
      body: ListView.builder(
        key: const Key('ai-conversation-list'),
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
        itemCount: _messages.length + (_thinking ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 9),
              child: _ThinkingBubble(),
            );
          }
          final message = _messages[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 9),
            child: _AnimatedMessageEntry(
              key: ValueKey(message.id),
              message: message,
            ),
          );
        },
      ),
      bottom: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_iphone_rounded, size: 13, color: c.ai),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _copy.privacyFootnote,
                      style: SfType.mono(size: 8.5, color: c.muted),
                    ),
                  ),
                  Text(
                    '${_composer.text.length}/500',
                    style: SfType.mono(size: 8.5, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ai-composer'),
                      controller: _composer,
                      focusNode: _composerFocus,
                      enabled: !_thinking,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendComposer(),
                      decoration: InputDecoration(
                        hintText: _copy.composerHint(_group.name),
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: c.surface2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: c.ai, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox.square(
                    dimension: 46,
                    child: IconButton.filled(
                      key: const Key('ai-send'),
                      tooltip: _copy.sendQuestion,
                      onPressed: _composer.text.trim().isEmpty || _thinking
                          ? null
                          : _sendComposer,
                      icon: AnimatedSwitcher(
                        duration: SfMotion.resolve(context, SfMotion.quick),
                        child: _thinking
                            ? const SizedBox.square(
                                key: ValueKey('sending'),
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                SfIcons.send,
                                key: ValueKey('send'),
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.copy,
    required this.group,
    required this.thinking,
    required this.onBack,
    required this.onPrompt,
    required this.onMenu,
  });

  final AiWorkspaceCopy copy;
  final AiStaffGroup group;
  final bool thinking;
  final VoidCallback onBack;
  final ValueChanged<String>? onPrompt;
  final ValueChanged<_AiMenuAction> onMenu;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final accent = group.usesAccent ? c.accent : c.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 9),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  key: const Key('ai-chat-back'),
                  tooltip: copy.backToWorkspace,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const SfStar(size: 19, color: Color(0xFFFFFCF5)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name,
                              overflow: TextOverflow.ellipsis,
                              style: SfType.ui(
                                size: 13.5,
                                weight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SfAiBadge(label: copy.onDevice, compact: true),
                        ],
                      ),
                      Text(
                        thinking
                            ? copy.preparingReply
                            : copy.studentsAndSubject(group),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SfType.ui(size: 9.5, color: c.muted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_AiMenuAction>(
                  key: const Key('ai-more-menu'),
                  tooltip: copy.conversationActions,
                  onSelected: onMenu,
                  icon: const Icon(SfIcons.more),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _AiMenuAction.clear,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_sweep_outlined),
                        title: Text(copy.clearConversation),
                      ),
                    ),
                    PopupMenuItem(
                      value: _AiMenuAction.help,
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.help_outline_rounded),
                        title: Text(copy.help),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              scrollDirection: Axis.horizontal,
              itemCount: copy.quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final prompt = copy.quickPrompts[index];
                return SfPressable(
                  key: Key('ai-quick-$index'),
                  onPressed: onPrompt == null ? null : () => onPrompt!(prompt),
                  haptic: true,
                  semanticLabel: copy.sendPrompt(prompt),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: c.aiGradient,
                      border: Border.all(color: c.aiBorder),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      prompt,
                      style: SfType.ui(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: c.ai,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AiConversationMessage {
  const _AiConversationMessage({
    required this.id,
    required this.author,
    required this.text,
  });

  final String id;
  final _AiMessageAuthor author;
  final String text;
}

class _AnimatedMessageEntry extends StatefulWidget {
  const _AnimatedMessageEntry({super.key, required this.message});

  final _AiConversationMessage message;

  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    final curved = CurvedAnimation(parent: _controller, curve: SfMotion.enter);
    _fade = curved;
    _slide = Tween<Offset>(
      begin: widget.message.author == _AiMessageAuthor.user
          ? const Offset(.045, .05)
          : const Offset(-.045, .05),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.message.author == _AiMessageAuthor.user
        ? _UserBubble(text: widget.message.text)
        : _AssistantBubble(text: widget.message.text);
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: child),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.ink,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: SfType.ui(size: 13, color: c.bg, height: 1.42),
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            gradient: c.aiGradient,
            border: Border.all(color: c.aiBorder),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text('Ai', style: SfType.display(size: 14, color: c.ai)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SfAiBadge(
                  label: AiWorkspaceCopy.of(context).deviceDemo,
                  compact: true,
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: SfType.ui(size: 12.8, color: c.ink2, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            gradient: c.aiGradient,
            border: Border.all(color: c.aiBorder),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text('Ai', style: SfType.display(size: 14, color: c.ai)),
        ),
        const SizedBox(width: 8),
        Container(
          key: const Key('ai-thinking'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < 3; index++) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.ai.withValues(alpha: .45 + index * .2),
                    shape: BoxShape.circle,
                  ),
                ),
                if (index < 2) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
