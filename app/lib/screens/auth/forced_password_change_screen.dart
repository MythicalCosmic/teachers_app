import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/api/api_models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_scaffold.dart';

/// A blocking first-login step for staff accounts created with a temporary
/// password. The router keeps this screen isolated from the staff workspace
/// until the server confirms the password change and rotates the access token.
class ForcedPasswordChangeScreen extends StatefulWidget {
  const ForcedPasswordChangeScreen({super.key});

  @override
  State<ForcedPasswordChangeScreen> createState() =>
      _ForcedPasswordChangeScreenState();
}

class _ForcedPasswordChangeScreenState
    extends State<ForcedPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppScope.of(context).changePassword(
        oldPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _error = _copy(
            context,
            uz: 'Parol saqlanmadi. Ulanishni tekshirib, qayta urinib ko‘ring.',
            ru: 'Пароль не сохранён. Проверьте подключение и повторите попытку.',
            en: 'The password was not saved. Check your connection and retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = SfTheme.colorsOf(context);
    final session = app.session;
    return PopScope(
      canPop: false,
      child: SfScaffold(
        dismissKeyboardOnTap: true,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: c.primary.withValues(alpha: .2),
                        ),
                      ),
                      child: Icon(
                        Icons.password_rounded,
                        color: c.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _copy(
                      context,
                      uz: 'Yangi parol yarating',
                      ru: 'Создайте новый пароль',
                      en: 'Create a new password',
                    ),
                    textAlign: TextAlign.center,
                    style: SfType.ui(
                      size: 30,
                      weight: FontWeight.w800,
                      color: c.ink,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _copy(
                      context,
                      uz: '${session?.displayName ?? 'Xodim'}, bu vaqtinchalik parol. Ish maydonini ochishdan oldin uni faqat siz biladigan parolga almashtiring.',
                      ru: '${session?.displayName ?? 'Сотрудник'}, это временный пароль. Замените его перед входом в рабочее пространство.',
                      en: '${session?.displayName ?? 'Staff member'}, this is a temporary password. Replace it before entering your workspace.',
                    ),
                    textAlign: TextAlign.center,
                    style: SfType.ui(
                      size: 15,
                      weight: FontWeight.w500,
                      color: c.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SfSurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SfTextField(
                              controller: _currentPassword,
                              label: _copy(
                                context,
                                uz: 'Vaqtinchalik parol',
                                ru: 'Временный пароль',
                                en: 'Temporary password',
                              ),
                              prefixIcon: Icons.lock_clock_outlined,
                              obscureText: !_currentVisible,
                              enabled: !_saving,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.password],
                              suffix: IconButton(
                                tooltip: _currentVisible ? 'Hide' : 'Show',
                                onPressed: () => setState(
                                  () => _currentVisible = !_currentVisible,
                                ),
                                icon: Icon(
                                  _currentVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? _copy(
                                      context,
                                      uz: 'Joriy parolni kiriting',
                                      ru: 'Введите текущий пароль',
                                      en: 'Enter your current password',
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            SfTextField(
                              controller: _newPassword,
                              label: _copy(
                                context,
                                uz: 'Yangi parol',
                                ru: 'Новый пароль',
                                en: 'New password',
                              ),
                              helper: _copy(
                                context,
                                uz: 'Kamida 8 belgi; oson topiladigan parol ishlatmang.',
                                ru: 'Не менее 8 символов; не используйте простой пароль.',
                                en: 'At least 8 characters; avoid an easy-to-guess password.',
                              ),
                              prefixIcon: Icons.lock_reset_rounded,
                              obscureText: !_newVisible,
                              enabled: !_saving,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              suffix: IconButton(
                                tooltip: _newVisible ? 'Hide' : 'Show',
                                onPressed: () =>
                                    setState(() => _newVisible = !_newVisible),
                                icon: Icon(
                                  _newVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.length < 8) {
                                  return _copy(
                                    context,
                                    uz: 'Kamida 8 ta belgi kiriting',
                                    ru: 'Введите не менее 8 символов',
                                    en: 'Enter at least 8 characters',
                                  );
                                }
                                if (password == _currentPassword.text) {
                                  return _copy(
                                    context,
                                    uz: 'Yangi parol boshqacha bo‘lishi kerak',
                                    ru: 'Новый пароль должен отличаться',
                                    en: 'The new password must be different',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SfTextField(
                              controller: _confirmation,
                              label: _copy(
                                context,
                                uz: 'Yangi parolni tasdiqlang',
                                ru: 'Подтвердите новый пароль',
                                en: 'Confirm new password',
                              ),
                              prefixIcon: Icons.verified_user_outlined,
                              obscureText: !_newVisible,
                              enabled: !_saving,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              onSubmitted: (_) => _submit(),
                              validator: (value) => value != _newPassword.text
                                  ? _copy(
                                      context,
                                      uz: 'Parollar bir xil emas',
                                      ru: 'Пароли не совпадают',
                                      en: 'Passwords do not match',
                                    )
                                  : null,
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              child: _error == null
                                  ? const SizedBox(height: 20)
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: c.dangerSoft,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: c.danger,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: SfType.ui(
                                                  size: 13,
                                                  weight: FontWeight.w600,
                                                  color: c.danger,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            SfButton(
                              label: _copy(
                                context,
                                uz: _saving
                                    ? 'Saqlanmoqda…'
                                    : 'Parolni saqlash',
                                ru: _saving
                                    ? 'Сохранение…'
                                    : 'Сохранить пароль',
                                en: _saving ? 'Saving…' : 'Save password',
                              ),
                              leading: _saving
                                  ? null
                                  : Icons.arrow_forward_rounded,
                              block: true,
                              height: 54,
                              onPressed: _saving ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SfButton(
                    kind: SfButtonKind.ghost,
                    label: _copy(
                      context,
                      uz: 'Boshqa hisob bilan kirish',
                      ru: 'Войти с другой учётной записью',
                      en: 'Use another account',
                    ),
                    leading: Icons.logout_rounded,
                    block: true,
                    onPressed: _saving ? null : app.signOut,
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

String _copy(
  BuildContext context, {
  required String uz,
  required String ru,
  required String en,
}) => switch (Localizations.localeOf(context).languageCode) {
  'ru' => ru,
  'en' => en,
  _ => uz,
};
