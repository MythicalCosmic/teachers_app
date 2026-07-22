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
import '../widgets/sf_search_field.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';
import 'groups/group_workspace_store.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({
    super.key,
    this.groupId,
    this.studentId,
    this.controller,
  });

  final String? groupId;
  final String? studentId;
  final MessagingController? controller;

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

enum _ContactFilter { all, staff, students }

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _search = TextEditingController();
  final _message = TextEditingController();
  String? _contactId;
  bool _sending = false;
  _ContactFilter _filter = _ContactFilter.all;
  MessagingController? _activeController;

  MessagingController get _controller =>
      _activeController ?? MessagingController.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = widget.controller ?? AppScope.of(context).messagingController;
    if (identical(next, _activeController)) return;
    _activeController?.removeListener(_onControllerChanged);
    _activeController = next;
    next.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _activeController?.removeListener(_onControllerChanged);
    _search.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final contactId = _contactId;
    if (_sending || contactId == null) return;
    setState(() => _sending = true);
    try {
      final thread = await _controller.createOrOpenDirectThreadAsync(contactId);
      if (_message.text.trim().isNotEmpty) {
        await _controller.sendText(thread.id, _messageBody());
      }
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
      storageScope: app.messagingStorageScope,
    );
    if (_controller.isProduction &&
        !_controller.hasLoadedDirectory &&
        !_controller.isDirectoryLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.refreshDirectory();
      });
    }
    final query = _search.text.trim().toLowerCase();
    final permittedContacts = _controller.contacts
        .where((contact) => contact.kind != MessagingContactKind.unknown)
        .toList(growable: false);
    final contacts = permittedContacts
        .where((contact) {
          final matchesFilter = switch (_filter) {
            _ContactFilter.all =>
              contact.kind == MessagingContactKind.staff ||
                  contact.kind == MessagingContactKind.student,
            _ContactFilter.staff => contact.kind == MessagingContactKind.staff,
            _ContactFilter.students =>
              contact.kind == MessagingContactKind.student,
          };
          return matchesFilter &&
              (contact.name.toLowerCase().contains(query) ||
                  contact.username.toLowerCase().contains(query) ||
                  contact.role.toLowerCase().contains(query));
        })
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
            onPressed: _sending || selected == null ? null : _send,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _message.text.trim().isEmpty
                        ? m.text('open_chat')
                        : m.text('send'),
                  ),
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
            child: SfSearchField(
              key: const ValueKey('new-message-search'),
              controller: _search,
              autofocus: selected == null,
              hintText: m.text('search_contacts'),
              semanticLabel: m.text('search_contacts'),
              clearTooltip: m.text('clear'),
              clearButtonKey: const ValueKey('new-message-search-clear'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _ContactFilterBar(
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
              allLabel: m.text('contact_filter_all'),
              staffLabel: m.text('contact_filter_staff'),
              studentsLabel: m.text('contact_filter_students'),
            ),
          ),
          if (_controller.directoryError != null &&
              permittedContacts.isNotEmpty)
            _DirectoryNotice(
              message: _controller.directoryError!,
              retryLabel: m.text('retry'),
              onRetry: () => _controller.refreshDirectory(force: true),
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
            child: _controller.isDirectoryLoading && permittedContacts.isEmpty
                ? SfLoadingState(
                    key: const ValueKey('contact-directory-loading'),
                    label: m.text('contact_directory_loading'),
                    message: m.text('contact_directory_loading_help'),
                  )
                : _controller.directoryError != null &&
                      permittedContacts.isEmpty
                ? SfErrorState(
                    key: const ValueKey('contact-directory-error'),
                    title: m.text('contact_directory_error'),
                    message: _controller.directoryError,
                    retryLabel: m.text('retry'),
                    onRetry: () => _controller.refreshDirectory(force: true),
                  )
                : contacts.isEmpty
                ? SfEmptyState(
                    key: const ValueKey('contact-directory-empty'),
                    title: permittedContacts.isEmpty
                        ? m.text('no_permitted_contacts')
                        : m.text('contacts_not_found'),
                    message: permittedContacts.isEmpty
                        ? m.text('no_permitted_contacts_help')
                        : m.text('contact_search_help'),
                    icon: permittedContacts.isEmpty
                        ? Icons.forum_outlined
                        : SfIcons.search,
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
                        key: ValueKey('new-message-contact-${contact.id}'),
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

class _ContactFilterBar extends StatelessWidget {
  const _ContactFilterBar({
    required this.value,
    required this.onChanged,
    required this.allLabel,
    required this.staffLabel,
    required this.studentsLabel,
  });

  final _ContactFilter value;
  final ValueChanged<_ContactFilter> onChanged;
  final String allLabel;
  final String staffLabel;
  final String studentsLabel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('new-message-contact-filters'),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _ContactFilterChip(
            key: const ValueKey('contact-filter-all'),
            label: allLabel,
            icon: Icons.people_alt_outlined,
            selected: value == _ContactFilter.all,
            onSelected: () => onChanged(_ContactFilter.all),
          ),
          const SizedBox(width: 8),
          _ContactFilterChip(
            key: const ValueKey('contact-filter-staff'),
            label: staffLabel,
            icon: Icons.badge_outlined,
            selected: value == _ContactFilter.staff,
            onSelected: () => onChanged(_ContactFilter.staff),
          ),
          const SizedBox(width: 8),
          _ContactFilterChip(
            key: const ValueKey('contact-filter-students'),
            label: studentsLabel,
            icon: Icons.school_outlined,
            selected: value == _ContactFilter.students,
            onSelected: () => onChanged(_ContactFilter.students),
          ),
        ],
      ),
    );
  }
}

class _ContactFilterChip extends StatelessWidget {
  const _ContactFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      avatar: Icon(icon, size: 17),
      label: Text(label),
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _DirectoryNotice extends StatelessWidget {
  const _DirectoryNotice({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('contact-directory-notice'),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: c.warnSoft,
          border: Border.all(color: c.warn.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 19, color: c.warn),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: SfType.ui(size: 11, color: c.ink, height: 1.35),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    super.key,
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
    final m = MessagingL10n.of(context);
    final category = switch (contact.kind) {
      MessagingContactKind.staff => m.text('contact_filter_staff'),
      MessagingContactKind.student => m.text('contact_filter_students'),
      MessagingContactKind.unknown => m.text('existing_contact'),
    };
    final subtitle = <String>[
      category,
      if (contact.role.isNotEmpty &&
          contact.role.toLowerCase() != category.toLowerCase())
        contact.role,
      if (contact.username.isNotEmpty) contact.username,
    ].join(' · ');
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
          subtitle: Text(subtitle),
          trailing: selected
              ? Icon(Icons.check_circle_rounded, color: c.primary)
              : const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
