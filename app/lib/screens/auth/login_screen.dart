import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../app/app_state.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_star.dart';

typedef LoginSubmit =
    Future<void> Function({
      required String username,
      required String password,
      required bool persistSession,
    });

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSignIn});

  /// Allows focused widget tests to exercise sign-in failure states without
  /// replacing the production [AppState]. Normal app routes leave this null.
  final LoginSubmit? onSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _submitting = false;
  bool _restoringSaved = false;
  _LoginFailure? _failure;

  bool get _busy => _submitting || _restoringSaved;

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
      _failure = null;
    });
    final app = AppScope.maybeOf(context);
    try {
      final override = widget.onSignIn;
      if (override != null) {
        await override(
          username: _username.text.trim(),
          password: _password.text,
          persistSession: _rememberDevice,
        );
      } else {
        if (app == null) {
          throw const AuthenticationException(
            'Sign-in service is not available.',
          );
        }
        await app.signIn(
          username: _username.text.trim(),
          password: _password.text,
          persistSession: _rememberDevice,
        );
      }
      if (!mounted) return;
      if (app?.settings.haptics ?? false) HapticFeedback.mediumImpact();
      context.go(
        (app?.settings.hasCompletedWelcome ?? true) ? '/home' : '/welcome',
      );
    } on AuthenticationException catch (error) {
      if (!mounted) return;
      final failure = _LoginFailure.fromAuthentication(
        context,
        error.message,
        invalidCredentials: app?.isProduction == true && app?.syncError == null,
      );
      setState(() {
        _failure = failure;
      });
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${failure.title}. ${failure.message}',
        Directionality.of(context),
      );
    } on Object {
      if (!mounted) return;
      final failure = _LoginFailure.unexpected(context);
      setState(() => _failure = failure);
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${failure.title}. ${failure.message}',
        Directionality.of(context),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retrySavedSession() async {
    final app = AppScope.maybeOf(context);
    if (app == null || _busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _restoringSaved = true;
      _failure = null;
    });
    await app.retryConnection();
    if (!mounted) return;
    setState(() => _restoringSaved = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final app = AppScope.maybeOf(context);
    final savedSessionPending =
        app?.isProduction == true &&
        app?.session == null &&
        app?.backendApi?.hasSession == true &&
        (_restoringSaved || app?.syncError != null);
    final savedSessionFailure = savedSessionPending
        ? _LoginFailure.fromAuthentication(
            context,
            app?.syncError ??
                _copy(
                  context,
                  uz: 'Saqlangan xavfsiz sessiya tekshirilmoqda…',
                  ru: 'Проверяется сохранённая безопасная сессия…',
                  en: 'Checking your saved secure session…',
                ),
            invalidCredentials: false,
          )
        : null;
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
                            if (savedSessionFailure != null) ...[
                              const SizedBox(height: 18),
                              _ErrorBanner(
                                failure: savedSessionFailure,
                                onRetry: _restoringSaved
                                    ? null
                                    : _retrySavedSession,
                              ),
                            ],
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
                              enabled: !_busy,
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
                              enabled: !_busy,
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
                            if (_failure != null) ...[
                              const SizedBox(height: 10),
                              _ErrorBanner(
                                failure: _failure!,
                                onRetry: _failure!.canRetry ? _submit : null,
                              ),
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
                                  onChanged: _busy
                                      ? null
                                      : (value) => setState(
                                          () =>
                                              _rememberDevice = value ?? false,
                                        ),
                                );
                                final forgotButton = TextButton(
                                  onPressed: _busy
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
                              label: _busy
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
                              trailing: _busy ? null : SfIcons.arrowR,
                              fontSize: 16,
                              onPressed: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 14),
                            _CenterIdentity(
                              colors: c,
                              production: app?.isProduction ?? false,
                              centerName: app?.centerName ?? '',
                              serverHost: app?.serverHost ?? '',
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
    if (_failure != null) setState(() => _failure = null);
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

enum _LoginFailureKind { credentials, network, throttled, server }

class _LoginFailure {
  const _LoginFailure({
    required this.kind,
    required this.title,
    required this.message,
  });

  factory _LoginFailure.fromAuthentication(
    BuildContext context,
    String backendMessage, {
    required bool invalidCredentials,
  }) {
    final message = backendMessage.trim();
    final normalized = message.toLowerCase();
    final throttled = _containsAny(normalized, const [
      '429',
      'too many',
      'rate limit',
      'thrott',
      'ko‘p urinish',
      "ko'p urinish",
      'kop urinish',
      'слишком часто',
      'много попыток',
      'подождите',
    ]);
    final network = _containsAny(normalized, const [
      'network',
      'internet',
      'connection',
      'connect',
      'offline',
      'socket',
      'timeout',
      'timed out',
      'bog‘lan',
      "bog'lan",
      'ulanish',
      'соедин',
      'сеть',
      'интернет',
      'тайм-аут',
    ]);
    final credentials =
        invalidCredentials ||
        _containsAny(normalized, const [
          'invalid credential',
          'incorrect username',
          'incorrect password',
          'username or password',
          'wrong password',
          'noto‘g‘ri',
          "noto'g'ri",
          'неверн',
          'логин или пароль',
        ]);

    final kind = throttled
        ? _LoginFailureKind.throttled
        : network
        ? _LoginFailureKind.network
        : credentials
        ? _LoginFailureKind.credentials
        : _LoginFailureKind.server;
    return _LoginFailure(
      kind: kind,
      title: switch (kind) {
        _LoginFailureKind.credentials => _copy(
          context,
          uz: 'Kirish ma’lumotlari qabul qilinmadi',
          ru: 'Данные для входа не приняты',
          en: 'Sign-in details not accepted',
        ),
        _LoginFailureKind.network => _copy(
          context,
          uz: 'Ulanishda muammo',
          ru: 'Проблема с подключением',
          en: 'Connection problem',
        ),
        _LoginFailureKind.throttled => _copy(
          context,
          uz: 'Urinishlar juda ko‘p',
          ru: 'Слишком много попыток',
          en: 'Too many attempts',
        ),
        _LoginFailureKind.server => _copy(
          context,
          uz: 'Kirishni yakunlab bo‘lmadi',
          ru: 'Не удалось завершить вход',
          en: 'Could not complete sign-in',
        ),
      },
      message: message.isNotEmpty
          ? message
          : _copy(
              context,
              uz: 'Qayta urinib ko‘ring. Muammo davom etsa, administrator bilan bog‘laning.',
              ru: 'Попробуйте ещё раз. Если проблема сохранится, обратитесь к администратору.',
              en: 'Try again. If the problem continues, contact your administrator.',
            ),
    );
  }

  factory _LoginFailure.unexpected(BuildContext context) => _LoginFailure(
    kind: _LoginFailureKind.server,
    title: _copy(
      context,
      uz: 'Kirishni yakunlab bo‘lmadi',
      ru: 'Не удалось завершить вход',
      en: 'Could not complete sign-in',
    ),
    message: _copy(
      context,
      uz: 'Xavfsiz ulanishni hozir yakunlab bo‘lmadi. Birozdan so‘ng qayta urinib ko‘ring.',
      ru: 'Не удалось завершить безопасное подключение. Повторите попытку чуть позже.',
      en: 'The secure connection could not be completed. Please try again shortly.',
    ),
  );

  final _LoginFailureKind kind;
  final String title;
  final String message;

  bool get canRetry =>
      kind == _LoginFailureKind.network || kind == _LoginFailureKind.server;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.failure, this.onRetry});

  final _LoginFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final warning =
        failure.kind == _LoginFailureKind.network ||
        failure.kind == _LoginFailureKind.throttled;
    final accent = warning ? c.warn : c.danger;
    final background = warning ? c.warnSoft : c.dangerSoft;
    final icon = switch (failure.kind) {
      _LoginFailureKind.credentials => Icons.lock_outline_rounded,
      _LoginFailureKind.network => Icons.wifi_off_rounded,
      _LoginFailureKind.throttled => Icons.hourglass_top_rounded,
      _LoginFailureKind.server => Icons.error_outline_rounded,
    };

    return Semantics(
      liveRegion: true,
      container: true,
      label: '${failure.title}. ${failure.message}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.38)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failure.title,
                    style: SfType.ui(
                      size: 12,
                      color: c.ink,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    failure.message,
                    style: SfType.ui(size: 11, color: c.ink2, height: 1.4),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          _copy(
                            context,
                            uz: 'Qayta urinish',
                            ru: 'Повторить',
                            en: 'Try again',
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterIdentity extends StatelessWidget {
  const _CenterIdentity({
    required this.colors,
    required this.production,
    required this.centerName,
    required this.serverHost,
  });

  final SfColors colors;
  final bool production;
  final String centerName;
  final String serverHost;

  @override
  Widget build(BuildContext context) {
    final cleanedName = centerName.trim();
    final title = cleanedName.isNotEmpty
        ? cleanedName
        : production
        ? 'StarForge EDU · Production'
        : 'StarForge EDU · Staff';
    final host = _displayHost(serverHost);
    final subtitle = host.isNotEmpty
        ? host
        : production
        ? _copy(
            context,
            uz: 'Xavfsiz ishlab chiqarish serveri',
            ru: 'Защищённый рабочий сервер',
            en: 'Secure production server',
          )
        : _copy(
            context,
            uz: 'Mahalliy ishlab chiqish muhiti',
            ru: 'Локальная среда разработки',
            en: 'Local development environment',
          );

    return Semantics(
      container: true,
      label: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.75)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.primaryHover],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                title.substring(0, 1).toUpperCase(),
                style: SfType.display(size: 18, color: const Color(0xFFFFFCF5)),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SfType.ui(
                      size: 12,
                      weight: FontWeight.w800,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        production
                            ? Icons.cloud_done_outlined
                            : Icons.developer_mode_rounded,
                        size: 13,
                        color: production ? colors.success : colors.muted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SfType.mono(size: 10, color: colors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              production ? Icons.verified_user_outlined : Icons.shield_outlined,
              size: 19,
              color: production ? colors.success : colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

bool _containsAny(String value, List<String> candidates) =>
    candidates.any(value.contains);

String _displayHost(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return '';
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.host.isNotEmpty) return uri.host;
  return raw
      .replaceFirst(RegExp(r'^https?://'), '')
      .split('/')
      .first
      .split('?')
      .first;
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
