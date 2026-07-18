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
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _search = TextEditingController();
  final Set<String> _selected = {};
  String? _folderId;
  bool _archived = false;

  MessagingController get _controller => MessagingController.shared;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final m = MessagingL10n.of(context);
    final session = app.session;
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return SfScaffold(
        body: SfErrorState(
          title: m.text('permission_denied'),
          message: m.text('permission_message'),
        ),
      );
    }
    _controller.initialize(
      userId: session.userId,
      userName: session.displayName,
      sourceThreads: app.messageThreads,
    );

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
        final threads = _controller.visibleThreads(
          query: _search.text,
          folderId: _folderId,
          archived: _archived,
        );
        return SfScaffold(
          top: AnimatedSwitcher(
            duration: SfMotion.resolve(
              context,
              const Duration(milliseconds: 220),
              enabled: !app.settings.reducedMotion,
            ),
            child: _selected.isEmpty
                ? _MessagesHeader(
                    key: const ValueKey('normal-header'),
                    unread: _controller.unreadCount,
                    onCompose: () => context.push('/messages/new'),
                  )
                : _SelectionHeader(
                    key: const ValueKey('selection-header'),
                    count: _selected.length,
                    onClose: _clearSelection,
                    onArchive: () {
                      _controller.setArchived(_selected, !_archived);
                      _clearSelection();
                    },
                    onRead: () {
                      _controller.markRead(_selected);
                      _clearSelection();
                    },
                    onMore: () => _showBulkActions(context),
                  ),
          ),
          body: Column(
            children: [
              _SearchAndFolders(
                search: _search,
                selectedFolderId: _folderId,
                archived: _archived,
                folders: _controller.folders,
                archivedCount: _controller.archivedCount,
                onSearchChanged: (_) => setState(() {}),
                onFolderSelected: (folderId, archived) => setState(() {
                  _folderId = folderId;
                  _archived = archived;
                  _selected.clear();
                }),
                onCreateFolder: () => _createFolder(context),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: SfMotion.resolve(
                    context,
                    const Duration(milliseconds: 240),
                    enabled: !app.settings.reducedMotion,
                  ),
                  child: threads.isEmpty
                      ? SfEmptyState(
                          key: ValueKey(
                            'empty-${_archived ? 'archive' : _folderId}-${_search.text}',
                          ),
                          title: _search.text.isNotEmpty
                              ? m.text('no_results')
                              : _archived
                              ? m.text('archive_empty')
                              : m.text('no_chats'),
                          message: _search.text.isNotEmpty
                              ? m.text('try_another_search')
                              : m.text('start_with_new_message'),
                          icon: _archived
                              ? Icons.archive_rounded
                              : SfIcons.chat,
                          actionLabel: _search.text.isNotEmpty
                              ? m.text('clear_search')
                              : m.text('new_message'),
                          onAction: _search.text.isNotEmpty
                              ? () {
                                  _search.clear();
                                  setState(() {});
                                }
                              : () => context.push('/messages/new'),
                        )
                      : ListView.builder(
                          key: ValueKey(
                            'threads-${_archived ? 'archive' : _folderId}',
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 28),
                          itemCount: threads.length,
                          itemBuilder: (context, index) {
                            final thread = threads[index];
                            return _SwipeableThreadTile(
                              key: ValueKey(thread.id),
                              thread: thread,
                              selected: _selected.contains(thread.id),
                              onTap: () {
                                if (_selected.isNotEmpty) {
                                  _toggleSelection(thread.id);
                                } else {
                                  _controller.markRead([thread.id]);
                                  context.push(
                                    '/messages/chat?thread=${Uri.encodeQueryComponent(thread.id)}',
                                  );
                                }
                              },
                              onLongPress: () => _toggleSelection(thread.id),
                              onArchived: () => _controller.setArchived([
                                thread.id,
                              ], !_archived),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createFolder(BuildContext context) async {
    final m = MessagingL10n.of(context);
    final text = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(m.text('new_folder')),
        content: TextField(
          controller: text,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: m.text('folder_name'),
            hintText: m.text('folder_example'),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(m.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, text.text),
            child: Text(m.text('create')),
          ),
        ],
      ),
    );
    text.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      final folder = _controller.createFolder(name);
      setState(() {
        _folderId = folder.id;
        _archived = false;
      });
    } on ArgumentError catch (error) {
      if (context.mounted) {
        SfToast.show(context, message: m.error(error), tone: SfToastTone.error);
      }
    }
  }

  Future<void> _showBulkActions(BuildContext context) async {
    final m = MessagingL10n.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(m.text('toggle_pin')),
              onTap: () => Navigator.pop(sheetContext, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(m.text('toggle_mute')),
              onTap: () => Navigator.pop(sheetContext, 'mute'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(m.text('add_to_folder')),
              onTap: () => Navigator.pop(sheetContext, 'folder'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
              title: Text(m.text('delete_chats')),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !context.mounted || choice == null) return;
    switch (choice) {
      case 'pin':
        _controller.togglePinned(_selected);
        _clearSelection();
      case 'mute':
        _controller.toggleMuted(_selected);
        _clearSelection();
      case 'folder':
        await _assignFolder(context);
      case 'delete':
        if (!context.mounted) return;
        await _deleteSelected(context);
    }
  }

  Future<void> _assignFolder(BuildContext context) async {
    final m = MessagingL10n.of(context);
    final folder = await showModalBottomSheet<MessagingFolder>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(m.text('choose_folder')),
              subtitle: Text(m.text('folder_selection_help')),
            ),
            for (final folder in _controller.folders)
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(m.folderName(folder)),
                onTap: () => Navigator.pop(sheetContext, folder),
              ),
          ],
        ),
      ),
    );
    if (folder == null) return;
    for (final id in _selected) {
      _controller.setFolder(id, folder.id, included: true);
    }
    _clearSelection();
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final m = MessagingL10n.of(context);
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(m.text('delete_chats_question')),
        content: Text(
          m.text('delete_chats_description', {'count': _selected.length}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(m.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(m.text('delete')),
          ),
        ],
      ),
    );
    if (approved != true || !mounted || !context.mounted) return;
    final deleted = _controller.deleteThreads(_selected);
    _clearSelection();
    SfToast.show(
      context,
      message: m.text('chats_deleted', {'count': deleted.length}),
      tone: SfToastTone.success,
      actionLabel: m.text('undo'),
      onAction: () => _controller.restoreThreads(deleted),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader({
    super.key,
    required this.unread,
    required this.onCompose,
  });

  final int unread;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final m = MessagingL10n.of(context);
    return SfLargeAppBar(
      title: m.text('messages'),
      subtitle: unread == 0
          ? m.text('all_read')
          : m.text('unread_chats', {'count': unread}),
      actions: [
        IconButton(
          tooltip: m.text('new_message'),
          onPressed: onCompose,
          icon: const Icon(Icons.edit_square),
        ),
      ],
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    super.key,
    required this.count,
    required this.onClose,
    required this.onArchive,
    required this.onRead,
    required this.onMore,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onArchive;
  final VoidCallback onRead;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final m = MessagingL10n.of(context);
    return SfNavBar(
      title: m.text('selected_count', {'count': count}),
      leading: IconButton(
        tooltip: m.text('close_selection'),
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
      ),
      actions: [
        IconButton(
          tooltip: m.text('archive_action'),
          onPressed: onArchive,
          icon: const Icon(Icons.archive_outlined),
        ),
        IconButton(
          tooltip: m.text('mark_read'),
          onPressed: onRead,
          icon: const Icon(Icons.mark_chat_read_outlined),
        ),
        IconButton(
          tooltip: m.text('more_actions'),
          onPressed: onMore,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }
}

class _SearchAndFolders extends StatelessWidget {
  const _SearchAndFolders({
    required this.search,
    required this.selectedFolderId,
    required this.archived,
    required this.folders,
    required this.archivedCount,
    required this.onSearchChanged,
    required this.onFolderSelected,
    required this.onCreateFolder,
  });

  final TextEditingController search;
  final String? selectedFolderId;
  final bool archived;
  final List<MessagingFolder> folders;
  final int archivedCount;
  final ValueChanged<String> onSearchChanged;
  final void Function(String? folderId, bool archived) onFolderSelected;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    return ColoredBox(
      color: c.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SfTextField(
              controller: search,
              hint: m.text('search_chats'),
              prefixIcon: SfIcons.search,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              suffix: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: m.text('clear_search'),
                      onPressed: () {
                        search.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              children: [
                _FolderChip(
                  label: m.text('all'),
                  selected: selectedFolderId == null && !archived,
                  onTap: () => onFolderSelected(null, false),
                ),
                for (final folder in folders)
                  _FolderChip(
                    label: m.folderName(folder),
                    selected: selectedFolderId == folder.id && !archived,
                    onTap: () => onFolderSelected(folder.id, false),
                  ),
                _FolderChip(
                  label: archivedCount == 0
                      ? m.text('archive')
                      : '${m.text('archive')} $archivedCount',
                  selected: archived,
                  icon: Icons.archive_outlined,
                  onTap: () => onFolderSelected(null, true),
                ),
                IconButton(
                  tooltip: m.text('new_folder'),
                  onPressed: onCreateFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ChoiceChip(
      selected: selected,
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      onSelected: (_) => onTap(),
    ),
  );
}

class _SwipeableThreadTile extends StatelessWidget {
  const _SwipeableThreadTile({
    super.key,
    required this.thread,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onArchived,
  });

  final MessagingThread thread;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onArchived;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final m = MessagingL10n.of(context);
    final last = thread.lastMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Dismissible(
        key: ValueKey('dismiss-${thread.id}'),
        direction: DismissDirection.endToStart,
        background: DecoratedBox(
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.archive_rounded, color: Colors.white),
                  const SizedBox(height: 3),
                  Text(
                    m.text('archive'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        onDismissed: (_) => onArchived(),
        child: AnimatedContainer(
          duration: SfMotion.resolve(
            context,
            const Duration(milliseconds: 180),
          ),
          decoration: BoxDecoration(
            color: selected
                ? c.primarySoft
                : !thread.isRead
                ? c.surface
                : c.surface.withValues(alpha: 0.72),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SfAvatar(name: thread.title, size: 50),
                      if (thread.contact.isOnline)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: c.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.surface, width: 2),
                            ),
                          ),
                        ),
                      if (selected)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.78),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded, color: c.surface),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (thread.isPinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: c.primary,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                thread.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SfType.ui(
                                  size: 14,
                                  weight: thread.isRead
                                      ? FontWeight.w700
                                      : FontWeight.w900,
                                  color: c.ink,
                                ),
                              ),
                            ),
                            if (last != null)
                              Text(
                                m.relativeTime(last.sentAt),
                                style: SfType.mono(
                                  size: 9,
                                  color: thread.isRead ? c.muted : c.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.preview(last),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SfType.ui(size: 12.5, color: c.muted),
                              ),
                            ),
                            if (thread.isMuted)
                              Icon(
                                Icons.notifications_off_rounded,
                                size: 15,
                                color: c.muted,
                              ),
                            if (!thread.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
