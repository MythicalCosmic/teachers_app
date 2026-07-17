import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../utils/formatters.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
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
  final _focus = FocusNode();
  final _scroll = ScrollController();
  String? _markedThreadId;
  bool _sending = false;

  @override
  void dispose() {
    _composer.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  MessageThread? _resolveThread(BuildContext context) {
    final app = AppScope.of(context);
    final requested = GoRouterState.of(context).uri.queryParameters['thread'];
    for (final thread in app.messageThreads) {
      if (thread.id == requested) return thread;
    }
    final session = app.session;
    return app.messageThreads
        .where(
          (thread) =>
              session == null || thread.participantIds.contains(session.userId),
        )
        .firstOrNull;
  }

  void _markRead(MessageThread thread) {
    if (_markedThreadId == thread.id) return;
    _markedThreadId = thread.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).markThreadRead(thread.id);
    });
  }

  Future<void> _send(MessageThread thread) async {
    if (_sending || _composer.text.trim().isEmpty) return;
    final app = AppScope.of(context);
    setState(() => _sending = true);
    try {
      await app.sendMessage(thread.id, _composer.text);
      _composer.clear();
      if (!mounted) return;
      _focus.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToEnd(app.settings.reducedMotion),
      );
    } on Object catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        message: error.toString(),
        tone: SfToastTone.error,
        glassEnabled: app.settings.liquidGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd(bool reducedMotion) {
    if (!_scroll.hasClients) return;
    if (reducedMotion) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    } else {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final thread = _resolveThread(context);
    final c = SfTheme.colorsOf(context);
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return const SfScaffold(
        body: SfErrorState(title: 'Xabarlarga ruxsat yo‘q'),
      );
    }
    if (thread == null) {
      return SfScaffold(
        top: SfNavBar(
          title: 'Suhbat',
          leading: IconButton(
            tooltip: 'Ortga',
            onPressed: () => context.pop(),
            icon: const Icon(SfIcons.arrowL),
          ),
        ),
        body: const SfEmptyState(title: 'Suhbat topilmadi', icon: SfIcons.chat),
      );
    }
    _markRead(thread);

    return SfScaffold(
      dismissKeyboardOnTap: false,
      top: SfNavBar(
        title: thread.title,
        subtitle: widget.managementMode
            ? 'Xodimlar koordinatsiyasi'
            : 'Xodimlar suhbati',
        leading: IconButton(
          tooltip: 'Ortga',
          onPressed: () => context.pop(),
          icon: const Icon(SfIcons.arrowL),
        ),
        actions: [
          IconButton(
            tooltip: 'Suhbat ma’lumoti',
            onPressed: () => SfToast.show(
              context,
              message:
                  '${thread.participantIds.length} nafar xodim qatnashmoqda',
              glassEnabled: app.settings.liquidGlass,
              motionEnabled: !app.settings.reducedMotion,
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: thread.messages.isEmpty
          ? const SfEmptyState(
              title: 'Suhbatni boshlang',
              message: 'Birinchi xabarni quyidagi maydonga yozing.',
              icon: SfIcons.chat,
            )
          : ListView.separated(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              itemCount: thread.messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = thread.messages[index];
                final mine = message.senderId == session.userId;
                return _MessageBubble(message: message, mine: mine);
              },
            ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox.square(
              dimension: 44,
              child: SfButton(
                kind: SfButtonKind.soft,
                semanticLabel: 'Fayl biriktirish',
                tooltip: 'Fayl biriktirish',
                padding: EdgeInsets.zero,
                child: const Icon(SfIcons.attach),
                onPressed: () => SfToast.show(
                  context,
                  message:
                      'Fayl biriktirish keyingi sinxronizatsiya bilan ishlaydi.',
                  glassEnabled: app.settings.liquidGlass,
                  motionEnabled: !app.settings.reducedMotion,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SfTextField(
                controller: _composer,
                focusNode: _focus,
                hint: 'Xabar yozing…',
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 44,
              child: SfButton(
                semanticLabel: 'Yuborish',
                tooltip: 'Yuborish',
                padding: EdgeInsets.zero,
                haptic: app.settings.haptics,
                motionEnabled: !app.settings.reducedMotion,
                onPressed: _sending || _composer.text.trim().isEmpty
                    ? null
                    : () => _send(thread),
                child: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(SfIcons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      label:
          '${message.senderName}. ${message.body}. ${SfFormatters.time(message.sentAt)}',
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) ...[
              SfAvatar(name: message.senderName, size: 28),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: mine ? c.primary : c.surface,
                  border: mine ? null : Border.all(color: c.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 5),
                    bottomRight: Radius.circular(mine ? 5 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!mine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          message.senderName,
                          style: SfType.ui(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: c.primary,
                          ),
                        ),
                      ),
                    Text(
                      message.body,
                      style: SfType.ui(
                        size: 13.5,
                        color: mine ? c.surface : c.ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      SfFormatters.time(message.sentAt),
                      style: SfType.mono(
                        size: 9.5,
                        color: mine
                            ? c.surface.withValues(alpha: 0.72)
                            : c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
