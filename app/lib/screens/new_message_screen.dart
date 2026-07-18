import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../features/messaging/messaging_controller.dart';
import '../features/messaging/messaging_l10n.dart';
import '../features/messaging/messaging_models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';
import 'groups/group_workspace_store.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key, this.groupId, this.studentId});

  final String? groupId;
  final String? studentId;

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _search = TextEditingController();
  final _message = TextEditingController();
  String? _contactId;
  bool _sending = false;

  MessagingController get _controller => MessagingController.shared;

  @override
  void dispose() {
    _search.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final contactId = _contactId;
    if (_sending || contactId == null || _message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final thread = _controller.createOrOpenDirectThread(contactId);
      await _controller.sendText(thread.id, _messageBody());
      if (!mounted) return;
      context.pushReplacement(
        '/messages/chat?thread=${Uri.encodeQueryComponent(thread.id)}',
      );
    } on ArgumentError catch (error) {
      if (mounted) {
        SfToast.show(
          context,
          title: MessagingL10n.of(context).text('new_message'),
          message: MessagingL10n.of(context).error(error),
          tone: SfToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _messageBody() {
    final group = groupWorkspaceStore.tryGroup(widget.groupId);
    final student = groupWorkspaceStore.student(
      widget.studentId,
      groupId: group?.id,
    );
    final contextLine = switch ((group, student)) {
      (final TeacherGroup group, final GroupStudent student) =>
        '${group.name} · ${student.name}',
      (final TeacherGroup group, null) => group.name,
      _ => null,
    };
    final body = _message.text.trim();
    return contextLine == null ? body : '[$contextLine]\n$body';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final m = MessagingL10n.of(context);
    final session = app.session;
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return SfScaffold(
        body: SfErrorState(title: m.text('send_permission_denied')),
      );
    }
    _controller.initialize(
      userId: session.userId,
      userName: session.displayName,
      sourceThreads: app.messageThreads,
    );
    final query = _search.text.trim().toLowerCase();
    final contacts = _controller.contacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(query) ||
              contact.username.toLowerCase().contains(query) ||
              contact.role.toLowerCase().contains(query),
        )
        .toList(growable: false);
    final selected = _controller.contactById(_contactId);
    final c = SfTheme.colorsOf(context);
    final group = groupWorkspaceStore.tryGroup(widget.groupId);
    final student = groupWorkspaceStore.student(
      widget.studentId,
      groupId: group?.id,
    );

    return SfScaffold(
      dismissKeyboardOnTap: false,
      top: SfNavBar(
        title: m.text('new_message'),
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(m.text('cancel')),
        ),
        actions: [
          TextButton(
            onPressed:
                _sending || selected == null || _message.text.trim().isEmpty
                ? null
                : _send,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(m.text('send')),
          ),
        ],
      ),
      body: Column(
        children: [
          if (group != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SfSurfaceCard(
                key: const ValueKey('message-group-context'),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SfAvatar(name: student?.name ?? group.name, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.name ?? group.name,
                            style: SfType.ui(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            student == null
                                ? '${group.subject} · ${group.students.length}'
                                : '${group.name} · ${student.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SfType.ui(size: 10, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.link_rounded, size: 18, color: c.primary),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, group == null ? 12 : 10, 16, 10),
            child: SfTextField(
              controller: _search,
              autofocus: selected == null,
              hint: m.text('search_staff'),
              prefixIcon: SfIcons.search,
              onChanged: (_) => setState(() {}),
              suffix: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: m.text('clear'),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          if (selected != null)
            AnimatedContainer(
              duration: SfMotion.resolve(
                context,
                const Duration(milliseconds: 220),
              ),
              margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: c.primarySoft,
                border: Border.all(color: c.primary.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  SfAvatar(name: selected.name, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          style: SfType.ui(
                            weight: FontWeight.w800,
                            color: c.primaryInk,
                          ),
                        ),
                        Text(
                          selected.username,
                          style: SfType.ui(size: 11, color: c.primary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: m.text('remove_recipient'),
                    onPressed: () => setState(() => _contactId = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          Expanded(
            child: contacts.isEmpty
                ? SfEmptyState(
                    title: m.text('staff_not_found'),
                    message: m.text('staff_search_help'),
                    icon: SfIcons.search,
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 5),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _ContactTile(
                        contact: contact,
                        selected: contact.id == _contactId,
                        onTap: () {
                          setState(() => _contactId = contact.id);
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      );
                    },
                  ),
          ),
          AnimatedSize(
            duration: SfMotion.resolve(
              context,
              const Duration(milliseconds: 240),
            ),
            child: selected == null
                ? const SizedBox.shrink()
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: SfTextField(
                                controller: _message,
                                hint: m.text('message_to', {
                                  'name': selected.name,
                                }),
                                minLines: 1,
                                maxLines: 4,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: m.text('send'),
                              onPressed:
                                  _sending || _message.text.trim().isEmpty
                                  ? null
                                  : _send,
                              icon: const Icon(Icons.arrow_upward_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      safeBottom: false,
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final MessagingContact contact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return AnimatedContainer(
      duration: SfMotion.resolve(context, const Duration(milliseconds: 160)),
      decoration: BoxDecoration(
        color: selected ? c.primarySoft : c.surface,
        border: Border.all(color: selected ? c.primary : c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              SfAvatar(name: contact.name, size: 44),
              if (contact.isOnline)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: c.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            contact.name,
            style: SfType.ui(weight: FontWeight.w800, color: c.ink),
          ),
          subtitle: Text('${contact.role} · ${contact.username}'),
          trailing: selected
              ? Icon(Icons.check_circle_rounded, color: c.primary)
              : const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
