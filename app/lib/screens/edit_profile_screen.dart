import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _role = TextEditingController();
  final _branch = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final session = AppScope.of(context).session;
    if (session != null) {
      _name.text = session.displayName;
      _email.text = session.email;
      _role.text = session.role.uzLabel;
      _branch.text = session.branchName;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _role.dispose();
    _branch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.updateProfile(displayName: _name.text, email: _email.text);
      if (!mounted) return;
      SfToast.show(
        context,
        title: 'Profil saqlandi',
        message: 'Ism va pochta qurilmaga saqlandi.',
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null) {
      return const SfScaffold(body: SfErrorState(title: 'Sessiya topilmadi'));
    }

    return SfScaffold(
      dismissKeyboardOnTap: true,
      top: SfNavBar(
        title: 'Profilni tahrirlash',
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('Bekor'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Saqlash'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SfAvatar(name: _name.text, size: 96, color: c.primary),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.bg, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Icon(SfIcons.edit, size: 17, color: c.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SfHintCard(
              compact: true,
              title: session.role.uzLabel,
              message:
                  'Rol va filial xavfsizlik sabab faqat ma’mur tomonidan o‘zgartiriladi.',
            ),
            const SizedBox(height: 18),
            SfTextField(
              controller: _name,
              label: 'Ism va familiya',
              hint: 'To‘liq ismingiz',
              prefixIcon: SfIcons.user,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Kamida 3 ta belgi kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SfTextField(
              controller: _email,
              label: 'Pochta',
              hint: 'name@example.uz',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _save(),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (!text.contains('@') || !text.contains('.')) {
                  return 'To‘g‘ri pochta manzilini kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SfTextField(
              label: 'Rol',
              controller: _role,
              prefixIcon: SfIcons.shield,
              readOnly: true,
            ),
            const SizedBox(height: 14),
            SfTextField(
              label: 'Filial',
              controller: _branch,
              prefixIcon: SfIcons.brand,
              readOnly: true,
            ),
            const SizedBox(height: 22),
            SfButton(
              block: true,
              label: _saving ? 'Saqlanmoqda…' : 'O‘zgarishlarni saqlash',
              leading: SfIcons.check,
              haptic: app.settings.haptics,
              motionEnabled: !app.settings.reducedMotion,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
