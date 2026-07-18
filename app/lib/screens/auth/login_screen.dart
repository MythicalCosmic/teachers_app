import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_star.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'nigora.karimova');
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final app = AppScope.of(context);
      await app.signIn(
        username: _username.text,
        password: _password.text,
        persistSession: _rememberDevice,
      );
      if (!mounted) return;
      if (app.settings.haptics) HapticFeedback.mediumImpact();
      context.go(app.settings.hasCompletedWelcome ? '/home' : '/welcome');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
      SemanticsService.sendAnnouncement(
        View.of(context),
        _error!,
        Directionality.of(context),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -40,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: SfStar(size: 300, color: c.primary),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 120,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: SfStar(size: 200, color: c.accent),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 600 ? 40 : 24,
                  12,
                  constraints.maxWidth >= 600 ? 40 : 24,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 480,
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),
                            _Wordmark(colors: c),
                            const SizedBox(height: 52),
                            Text(
                              _copy(
                                context,
                                uz: 'Assalomu',
                                ru: 'Добро',
                                en: 'Welcome',
                              ),
                              style: SfType.display(
                                size: 38,
                                color: c.ink,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _copy(
                                context,
                                uz: 'alaykum.',
                                ru: 'пожаловать.',
                                en: 'back.',
                              ),
                              style: SfType.ui(
                                size: 36,
                                weight: FontWeight.w800,
                                color: c.ink,
                                letterSpacing: -1.26,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                _copy(
                                  context,
                                  uz: 'Xodim hisobingizga kiring. Huquqlar profilingizdan xavfsiz tarzda aniqlanadi.',
                                  ru: 'Войдите в аккаунт сотрудника. Доступ безопасно определяется вашим профилем.',
                                  en: 'Sign in to your staff account. Access is securely determined by your profile.',
                                ),
                                style: SfType.ui(
                                  size: 14,
                                  color: c.muted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SfTextField(
                              controller: _username,
                              label: _copy(
                                context,
                                uz: 'Foydalanuvchi nomi',
                                ru: 'Имя пользователя',
                                en: 'Username',
                              ),
                              hint: _copy(
                                context,
                                uz: 'ism.familiya',
                                ru: 'имя.фамилия',
                                en: 'name.surname',
                              ),
                              prefixIcon: SfIcons.user,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              onChanged: (_) => _clearError(),
                              validator: (value) {
                                final username = value?.trim() ?? '';
                                if (username.isEmpty) {
                                  return _copy(
                                    context,
                                    uz: 'Foydalanuvchi nomini kiriting',
                                    ru: 'Введите имя пользователя',
                                    en: 'Enter your username',
                                  );
                                }
                                if (username.length < 3) {
                                  return _copy(
                                    context,
                                    uz: 'Kamida 3 ta belgi kiriting',
                                    ru: 'Введите не менее 3 символов',
                                    en: 'Enter at least 3 characters',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            SfTextField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              label: _copy(
                                context,
                                uz: 'Parol',
                                ru: 'Пароль',
                                en: 'Password',
                              ),
                              hint: _copy(
                                context,
                                uz: 'Parolingiz',
                                ru: 'Ваш пароль',
                                en: 'Your password',
                              ),
                              prefixIcon: SfIcons.shield,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) => _clearError(),
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? _copy(
                                        context,
                                        uz: 'Parolni ko‘rsatish',
                                        ru: 'Показать пароль',
                                        en: 'Show password',
                                      )
                                    : _copy(
                                        context,
                                        uz: 'Parolni yashirish',
                                        ru: 'Скрыть пароль',
                                        en: 'Hide password',
                                      ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return _copy(
                                    context,
                                    uz: 'Parolni kiriting',
                                    ru: 'Введите пароль',
                                    en: 'Enter your password',
                                  );
                                }
                                if ((value ?? '').length < 6) {
                                  return _copy(
                                    context,
                                    uz: 'Parol kamida 6 ta belgidan iborat',
                                    ru: 'Пароль должен содержать не менее 6 символов',
                                    en: 'Password must contain at least 6 characters',
                                  );
                                }
                                return null;
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              _ErrorBanner(message: _error!),
                            ],
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final rememberTile = CheckboxListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    _copy(
                                      context,
                                      uz: 'Bu qurilmada eslab qol',
                                      ru: 'Запомнить на устройстве',
                                      en: 'Remember this device',
                                    ),
                                    style: SfType.ui(size: 13, color: c.ink2),
                                  ),
                                  value: _rememberDevice,
                                  activeColor: c.primary,
                                  onChanged: _submitting
                                      ? null
                                      : (value) => setState(
                                          () =>
                                              _rememberDevice = value ?? false,
                                        ),
                                );
                                final forgotButton = TextButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => context.push('/login/forgot'),
                                  child: Text(
                                    _copy(
                                      context,
                                      uz: 'Parolni unutdingizmi?',
                                      ru: 'Забыли пароль?',
                                      en: 'Forgot password?',
                                    ),
                                    style: SfType.ui(
                                      size: 11,
                                      color: c.primary,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                );
                                final stackActions =
                                    constraints.maxWidth < 360 ||
                                    MediaQuery.textScalerOf(context).scale(13) >
                                        17;

                                if (stackActions) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      rememberTile,
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: forgotButton,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: rememberTile),
                                    forgotButton,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            SfButton(
                              kind: SfButtonKind.primary,
                              block: true,
                              height: 54,
                              label: _submitting
                                  ? _copy(
                                      context,
                                      uz: 'Tekshirilmoqda…',
                                      ru: 'Проверка…',
                                      en: 'Signing in…',
                                    )
                                  : _copy(
                                      context,
                                      uz: 'Kirish',
                                      ru: 'Войти',
                                      en: 'Sign in',
                                    ),
                              trailing: _submitting ? null : SfIcons.arrowR,
                              fontSize: 16,
                              onPressed: _submitting ? null : _submit,
                            ),
                            const SizedBox(height: 14),
                            _CenterIdentity(colors: c),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                _copy(
                                  context,
                                  uz: 'Demo parol: demo2026 · Rol foydalanuvchi hisobidan aniqlanadi',
                                  ru: 'Демо-пароль: demo2026 · Роль определяется аккаунтом',
                                  en: 'Demo password: demo2026 · Your role comes from your account',
                                ),
                                textAlign: TextAlign.center,
                                style: SfType.ui(
                                  size: 11,
                                  color: c.muted,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.colors});

  final SfColors colors;

  @override
  Widget build(BuildContext context) {
    final scaledWordmarkSize = MediaQuery.textScalerOf(context).scale(15);

    return Semantics(
      container: true,
      label: _copy(
        context,
        uz: 'StarForge EDU, Xodimlar',
        ru: 'StarForge EDU, Сотрудники',
        en: 'StarForge EDU, Staff',
      ),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackBadge =
                constraints.maxWidth < 360 || scaledWordmarkSize > 20;
            final brand = Row(
              children: [
                SfStar(size: 28, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'StarForge',
                          style: SfType.ui(
                            size: 15,
                            weight: FontWeight.w800,
                            color: colors.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: ' · EDU',
                          style: SfType.ui(
                            size: 15,
                            weight: FontWeight.w500,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            );

            if (stackBadge) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  const SizedBox(height: 10),
                  SfPill(
                    label: _copy(
                      context,
                      uz: 'Xodimlar',
                      ru: 'Сотрудники',
                      en: 'Staff',
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: brand),
                const SizedBox(width: 12),
                SfPill(
                  label: _copy(
                    context,
                    uz: 'Xodimlar',
                    ru: 'Сотрудники',
                    en: 'Staff',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 19, color: c.danger),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: SfType.ui(
                  size: 12,
                  color: c.danger,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterIdentity extends StatelessWidget {
  const _CenterIdentity({required this.colors});

  final SfColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'D',
              style: SfType.display(size: 18, color: const Color(0xFFFFFCF5)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Akademiya',
                  style: SfType.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _copy(
                    context,
                    uz: 'Yunusobod filiali · staff.starforge.uz',
                    ru: 'Филиал Юнусабад · staff.starforge.uz',
                    en: 'Yunusobod branch · staff.starforge.uz',
                  ),
                  style: SfType.mono(size: 10, color: colors.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_outlined, size: 18, color: colors.success),
        ],
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
