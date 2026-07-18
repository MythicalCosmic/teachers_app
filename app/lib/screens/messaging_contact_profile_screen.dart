import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../features/messaging/messaging_controller.dart';
import '../features/messaging/messaging_l10n.dart';
import '../features/messaging/messaging_models.dart';
import '../features/messaging/messaging_widgets.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

/// Rich staff contact profile. Register it at `/messages/contact` and pass a
/// `thread` query parameter, mirroring the chat route.
class MessagingContactProfileScreen extends StatefulWidget {
  const MessagingContactProfileScreen({super.key});

  @override
  State<MessagingContactProfileScreen> createState() =>
      _MessagingContactProfileScreenState();
}

class _MessagingContactProfileScreenState
    extends State<MessagingContactProfileScreen> {
  Timer? _callTimer;
  Timer? _shareTimer;
  Duration _callDuration = Duration.zero;
  bool _shared = false;
  bool _microphoneMuted = false;
  bool _speakerEnabled = true;

  MessagingController get _controller => MessagingController.shared;

  @override
  void dispose() {
    _callTimer?.cancel();
    _shareTimer?.cancel();
    super.dispose();
  }

  MessagingThread? _thread(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    if (session != null) {
      _controller.initialize(
        userId: session.userId,
        userName: session.displayName,
        sourceThreads: app.messageThreads,
      );
    }
    final id = GoRouterState.of(context).uri.queryParameters['thread'];
    return _controller.threadById(id);
  }

  void _startCall(MessagingThread thread) {
    final m = MessagingL10n.of(context);
    _controller.startCall(thread.id);
    _callTimer?.cancel();
    _callDuration = Duration.zero;
    _microphoneMuted = false;
    _speakerEnabled = true;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration += const Duration(seconds: 1));
    });
    setState(() {});
    SfToast.show(
      context,
      title: m.text('call'),
      message: m.text('call_preview_notice'),
      tone: SfToastTone.info,
    );
  }

  void _endCall() {
    _callTimer?.cancel();
    _controller.endCall();
    setState(() => _callDuration = Duration.zero);
  }

  void _toggleMicrophone() {
    final m = MessagingL10n.of(context);
    HapticFeedback.selectionClick();
    setState(() => _microphoneMuted = !_microphoneMuted);
    SfToast.show(
      context,
      message: m.text(_microphoneMuted ? 'microphone_off' : 'microphone_on'),
    );
  }

  void _toggleSpeaker() {
    final m = MessagingL10n.of(context);
    HapticFeedback.selectionClick();
    setState(() => _speakerEnabled = !_speakerEnabled);
    SfToast.show(
      context,
      message: m.text(_speakerEnabled ? 'speaker_on' : 'speaker_off'),
    );
  }

  void _share(MessagingContact contact) {
    unawaited(
      Clipboard.setData(
        ClipboardData(
          text:
              '${contact.name}\n${contact.role}\n${contact.username}\n${contact.phone}',
        ),
      ),
    );
    setState(() => _shared = true);
    _shareTimer?.cancel();
    _shareTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _shared = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = MessagingL10n.of(context);
    _thread(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isRestoring) {
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
        final thread = _thread(context);
        if (thread == null) {
          return SfScaffold(
            top: SfNavBar(
              title: m.text('profile'),
              leading: IconButton(
                tooltip: m.text('back'),
                onPressed: () => context.pop(),
                icon: const Icon(SfIcons.arrowL),
              ),
            ),
            body: SfEmptyState(
              title: m.text('contact_not_found'),
              icon: Icons.person_search_rounded,
            ),
          );
        }
        final refreshed = _controller.threadById(thread.id) ?? thread;
        final callActive = _controller.activeCallThreadId == refreshed.id;
        if (callActive) {
          return _CallView(
            thread: refreshed,
            onEnd: _endCall,
            duration: _callDuration,
            microphoneMuted: _microphoneMuted,
            speakerEnabled: _speakerEnabled,
            onMicrophone: _toggleMicrophone,
            onSpeaker: _toggleSpeaker,
          );
        }
        return _ProfileView(
          thread: refreshed,
          shared: _shared,
          onBack: () => context.pop(),
          onMessage: () => context.pushReplacement(
            '/messages/chat?thread=${Uri.encodeQueryComponent(refreshed.id)}',
          ),
          onSearch: () => context.pushReplacement(
            '/messages/chat?thread=${Uri.encodeQueryComponent(refreshed.id)}&search=1',
          ),
          onCall: () => _startCall(refreshed),
          onMute: () => _controller.toggleMuted([refreshed.id]),
          onShare: () => _share(refreshed.contact),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.thread,
    required this.shared,
    required this.onBack,
    required this.onMessage,
    required this.onSearch,
    required this.onCall,
    required this.onMute,
    required this.onShare,
  });

  final MessagingThread thread;
  final bool shared;
  final VoidCallback onBack;
  final VoidCallback onMessage;
  final VoidCallback onSearch;
  final VoidCallback onCall;
  final VoidCallback onMute;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final contact = thread.contact;
    final mediaCount = thread.messages
        .where((message) => message.kind != MessagingKind.text)
        .length;
    return SfScaffold(
      top: SfNavBar(
        title: m.text('contact_profile'),
        leading: IconButton(
          tooltip: m.text('back'),
          onPressed: onBack,
          icon: const Icon(SfIcons.arrowL),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Center(
            child: Hero(
              tag: 'message-contact-${contact.id}',
              child: SfAvatar(name: contact.name, size: 92),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            contact.name,
            textAlign: TextAlign.center,
            style: SfType.ui(size: 24, weight: FontWeight.w900, color: c.ink),
          ),
          const SizedBox(height: 3),
          Text(
            contact.isOnline ? m.text('online_now') : contact.role,
            textAlign: TextAlign.center,
            style: SfType.ui(
              size: 13,
              weight: FontWeight.w600,
              color: contact.isOnline ? c.success : c.muted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ProfileAction(
                icon: Icons.chat_bubble_rounded,
                label: m.text('message_action'),
                onTap: onMessage,
              ),
              _ProfileAction(
                icon: Icons.call_rounded,
                label: m.text('call'),
                onTap: onCall,
              ),
              _ProfileAction(
                icon: Icons.search_rounded,
                label: m.text('search'),
                onTap: onSearch,
              ),
              _ProfileAction(
                icon: thread.isMuted
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                label: thread.isMuted ? m.text('turn_on') : m.text('turn_off'),
                onTap: onMute,
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: SfMotion.resolve(
              context,
              const Duration(milliseconds: 220),
            ),
            child: shared
                ? Container(
                    key: const ValueKey('shared'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.successSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: c.success),
                        const SizedBox(width: 9),
                        Expanded(child: Text(m.text('contact_copied'))),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          SfSurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: m.text('username'),
                  value: contact.username,
                  onTap: () =>
                      Clipboard.setData(ClipboardData(text: contact.username)),
                ),
                Divider(height: 1, indent: 58, color: c.border),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: m.text('phone'),
                  value: contact.phone,
                  onTap: () =>
                      Clipboard.setData(ClipboardData(text: contact.phone)),
                ),
                Divider(height: 1, indent: 58, color: c.border),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: m.text('role'),
                  value: contact.role,
                ),
              ],
            ),
          ),
          if (contact.bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            SfSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.text('about'), style: SfType.eyebrow(color: c.muted)),
                  const SizedBox(height: 7),
                  Text(
                    contact.bio,
                    style: SfType.ui(size: 14, height: 1.45, color: c.ink),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SfSurfaceCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.perm_media_outlined),
                  title: Text(m.text('media_files')),
                  subtitle: Text(
                    m.text('attachments_count', {'count': mediaCount}),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onSearch,
                ),
                Divider(height: 1, indent: 58, color: c.border),
                ListTile(
                  leading: const Icon(Icons.ios_share_rounded),
                  title: Text(m.text('share_contact')),
                  subtitle: Text(m.text('copy_to_clipboard')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(icon, color: c.primary),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: c.ink,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(value),
    subtitle: Text(label),
    trailing: onTap == null ? null : const Icon(Icons.copy_rounded, size: 18),
    onTap: onTap,
  );
}

class _CallView extends StatelessWidget {
  const _CallView({
    required this.thread,
    required this.onEnd,
    required this.duration,
    required this.microphoneMuted,
    required this.speakerEnabled,
    required this.onMicrophone,
    required this.onSpeaker,
  });

  final MessagingThread thread;
  final VoidCallback onEnd;
  final Duration duration;
  final bool microphoneMuted;
  final bool speakerEnabled;
  final VoidCallback onMicrophone;
  final VoidCallback onSpeaker;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return Scaffold(
      backgroundColor: c.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              SfAvatar(name: thread.contact.name, size: 108),
              const SizedBox(height: 22),
              Text(
                thread.contact.name,
                textAlign: TextAlign.center,
                style: SfType.ui(
                  size: 26,
                  weight: FontWeight.w900,
                  color: c.surface,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                messagingDuration(duration),
                style: SfType.mono(size: 15, color: c.muted2),
              ),
              const SizedBox(height: 12),
              Text(
                m.text('call_preview_notice'),
                textAlign: TextAlign.center,
                style: SfType.ui(size: 11.5, color: c.muted2, height: 1.4),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallControl(
                    icon: microphoneMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: m.text('microphone'),
                    active: !microphoneMuted,
                    onTap: onMicrophone,
                  ),
                  _CallControl(
                    icon: speakerEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: m.text('sound'),
                    active: speakerEnabled,
                    onTap: onSpeaker,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Semantics(
                button: true,
                label: m.text('end_call'),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEnd,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: c.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.call_end_rounded,
                      color: c.surface,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      button: true,
      toggled: active,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: SfMotion.resolve(
                context,
                const Duration(milliseconds: 180),
              ),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: active ? c.primary : c.surface.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? c.primary : c.surface.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, color: c.surface),
            ),
            const SizedBox(height: 7),
            Text(label, style: SfType.ui(size: 11, color: c.surface)),
          ],
        ),
      ),
    );
  }
}
