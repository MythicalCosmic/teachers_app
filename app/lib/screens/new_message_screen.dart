import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _body = TextEditingController();
  String? _threadId;
  bool _sending = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    final threadId = _threadId;
    if (threadId == null) return;
    final app = AppScope.of(context);
    setState(() => _sending = true);
    try {
      await app.sendMessage(threadId, _body.text);
      if (!mounted) return;
      SfToast.show(
        context,
        message: 'Xabar yuborildi',
        tone: SfToastTone.success,
        glassEnabled: app.settings.liquidGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
      context.pop();
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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null || !session.can(StaffCapability.useStaffMessaging)) {
      return const SfScaffold(
        body: SfErrorState(title: 'Xabar yuborishga ruxsat yo‘q'),
      );
    }
    final threads = app.messageThreads
        .where((thread) => thread.participantIds.contains(session.userId))
        .toList(growable: false);
    if (threads.isNotEmpty &&
        !threads.any((thread) => thread.id == _threadId)) {
      _threadId = threads.first.id;
    }

    return SfScaffold(
      dismissKeyboardOnTap: true,
      top: SfNavBar(
        title: 'Yangi xabar',
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Bekor'),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : _send,
            child: const Text('Yuborish'),
          ),
        ],
      ),
      body: threads.isEmpty
          ? const SfEmptyState(
              title: 'Suhbat mavjud emas',
              message:
                  'Xabar yuborish uchun avval xodimlar guruhi yaratilishi kerak.',
              icon: SfIcons.chat,
            )
          : Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  const SfHintCard(
                    compact: true,
                    title: 'Xodimlararo kanal',
                    message: 'Faqat siz a’zo bo‘lgan suhbatlar ko‘rsatiladi.',
                  ),
                  const SizedBox(height: 18),
                  Text('KIMGA', style: SfType.eyebrow(color: c.muted)),
                  const SizedBox(height: 7),
                  SfSurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _threadId,
                        icon: const Icon(SfIcons.chevD),
                        items: [
                          for (final thread in threads)
                            DropdownMenuItem(
                              value: thread.id,
                              child: Text(thread.title),
                            ),
                        ],
                        onChanged: _sending
                            ? null
                            : (value) => setState(() => _threadId = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SfTextField(
                    controller: _body,
                    label: 'Xabar',
                    hint: 'Aniq va qisqa xabar yozing…',
                    minLines: 5,
                    maxLines: 9,
                    maxLength: 800,
                    textInputAction: TextInputAction.newline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Xabar matnini kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  SfButton(
                    block: true,
                    label: _sending ? 'Yuborilmoqda…' : 'Xabarni yuborish',
                    trailing: SfIcons.send,
                    haptic: app.settings.haptics,
                    motionEnabled: !app.settings.reducedMotion,
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
    );
  }
}
