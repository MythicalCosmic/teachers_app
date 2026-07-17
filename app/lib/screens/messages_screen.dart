import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../utils/formatters.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return const SfScaffold(
        body: SfErrorState(
          title: 'Xabarlarga ruxsat yo‘q',
          message:
              'Bu bo‘lim faqat xodimlararo yozishma ruxsati bo‘lgan rollar uchun.',
        ),
      );
    }

    final query = _search.text.trim().toLowerCase();
    final threads =
        app.messageThreads
            .where((thread) {
              if (!thread.participantIds.contains(session.userId)) return false;
              if (query.isEmpty) return true;
              return thread.title.toLowerCase().contains(query) ||
                  thread.messages.any(
                    (message) => message.body.toLowerCase().contains(query),
                  );
            })
            .toList(growable: false)
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
            return (b.lastActivity ?? DateTime(0)).compareTo(
              a.lastActivity ?? DateTime(0),
            );
          });

    return SfScaffold(
      top: Column(
        children: [
          SfLargeAppBar(
            title: 'Xabarlar',
            subtitle: '${app.unreadMessageCount} ta o‘qilmagan',
            leading: IconButton(
              tooltip: 'Ortga',
              onPressed: context.canPop() ? () => context.pop() : null,
              icon: const Icon(SfIcons.arrowL),
            ),
            actions: [
              IconButton(
                tooltip: 'Yangi xabar',
                onPressed: () => context.push('/messages/new'),
                icon: const Icon(SfIcons.edit),
              ),
            ],
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: SfTextField(
              controller: _search,
              hint: 'Suhbat yoki xabarni izlang',
              prefixIcon: SfIcons.search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              suffix: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Tozalash',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(SfIcons.x),
                    ),
            ),
          ),
        ],
      ),
      body: threads.isEmpty
          ? SfEmptyState(
              title: query.isEmpty ? 'Suhbat yo‘q' : 'Natija topilmadi',
              message: query.isEmpty
                  ? 'Yangi xabar orqali mavjud xodimlar guruhiga yozing.'
                  : 'Boshqa so‘z bilan qidirib ko‘ring.',
              icon: SfIcons.chat,
              actionLabel: query.isEmpty ? 'Yangi xabar' : 'Qidiruvni tozalash',
              onAction: query.isEmpty
                  ? () => context.push('/messages/new')
                  : () {
                      _search.clear();
                      setState(() {});
                    },
            )
          : ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: threads.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final last = thread.messages.lastOrNull;
                final unread = thread.unreadCountFor(session.userId);
                return InkWell(
                  onTap: () => context.push(
                    '/messages/chat?thread=${Uri.encodeQueryComponent(thread.id)}',
                  ),
                  child: Container(
                    color: unread > 0 ? c.surface : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SfAvatar(name: thread.title, size: 46),
                            if (thread.isPinned)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: c.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    SfIcons.pin,
                                    size: 9,
                                    color: c.surface,
                                  ),
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
                                  Expanded(
                                    child: Text(
                                      thread.title,
                                      style: SfType.ui(
                                        size: 14,
                                        weight: unread > 0
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: c.ink,
                                      ),
                                    ),
                                  ),
                                  if (last != null)
                                    Text(
                                      SfFormatters.relativeUz(last.sentAt),
                                      style: SfType.mono(
                                        size: 9.5,
                                        color: c.muted,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                last?.body ?? 'Hali xabar yo‘q',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SfType.ui(size: 12.5, color: c.muted),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(height: 6),
                                SfPill(
                                  tone: SfPillTone.primary,
                                  label: '$unread ta yangi',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
