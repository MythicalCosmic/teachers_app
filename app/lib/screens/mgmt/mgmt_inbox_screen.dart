import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_hint_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_state_view.dart';

class MgmtInboxScreen extends StatelessWidget {
  const MgmtInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return const SfScaffold(
        body: SfErrorState(title: 'Xodimlar kanaliga ruxsat yo‘q'),
      );
    }
    final channels =
        app.messageThreads
            .where((thread) {
              if (!thread.participantIds.contains(session.userId)) return false;
              final title = thread.title.toLowerCase();
              return thread.isPinned ||
                  title.contains('metod') ||
                  title.contains('yordamchi') ||
                  title.contains('navbatchi');
            })
            .toList(growable: false)
          ..sort(
            (a, b) => (b.lastActivity ?? DateTime(0)).compareTo(
              a.lastActivity ?? DateTime(0),
            ),
          );

    return SfScaffold(
      top: SfLargeAppBar(
        title: 'Xodimlar kanallari',
        subtitle: 'Metodika va navbatchi jamoalar',
        leading: IconButton(
          tooltip: 'Ortga',
          onPressed: context.canPop() ? () => context.pop() : null,
          icon: const Icon(SfIcons.arrowL),
        ),
      ),
      body: channels.isEmpty
          ? const SfEmptyState(
              title: 'Xodimlar kanali yo‘q',
              message: 'Siz a’zo bo‘lgan ishchi suhbat topilmadi.',
              icon: SfIcons.shield,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                const SfHintCard(
                  compact: true,
                  tone: SfHintTone.info,
                  title: 'Ichki yozishma',
                  message:
                      'Bu bo‘lim metodist, o‘qituvchi va yordamchilarning ishchi muloqoti uchun.',
                ),
                const SizedBox(height: 12),
                for (final thread in channels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push(
                        '/mgmt/chat?thread=${Uri.encodeQueryComponent(thread.id)}',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            SfAvatar(name: thread.title, size: 44),
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
                                            weight: FontWeight.w800,
                                            color: c.ink,
                                          ),
                                        ),
                                      ),
                                      if (thread.isPinned)
                                        const SfPill(
                                          tone: SfPillTone.accent,
                                          label: 'Muhim',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    thread.messages.lastOrNull?.body ??
                                        'Xabar yo‘q',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SfType.ui(
                                      size: 12.5,
                                      color: c.muted,
                                    ),
                                  ),
                                  if (thread.lastActivity != null) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      SfFormatters.relativeUz(
                                        thread.lastActivity!,
                                      ),
                                      style: SfType.mono(
                                        size: 9.5,
                                        color: c.muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
