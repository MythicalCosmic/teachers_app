import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/api/api_models.dart';
import '../../theme/sf_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

typedef PasswordResetRequest =
    Future<void> Function(String identifier, String accountType);
typedef PasswordResetConfirm =
    Future<void> Function(
      String identifier,
      String accountType,
      String code,
      String newPassword,
    );

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.requestReset, this.confirmReset});

  final PasswordResetRequest? requestReset;
  final PasswordResetConfirm? confirmReset;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ResetStep { request, verify, complete }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _requestKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  _ResetStep _step = _ResetStep.request;
  String _accountType = 'staff';
  bool _submitting = false;
  bool _obscure = true;
  int _resendSeconds = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _identifier.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _request({bool resend = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!resend && !(_requestKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final callback = widget.requestReset;
      if (callback != null) {
        await callback(_identifier.text.trim(), _accountType);
      } else {
        await AppScope.of(context).requestPasswordReset(
          identifier: _identifier.text,
          accountType: _accountType,
        );
      }
      if (!mounted) return;
      setState(() => _step = _ResetStep.verify);
      _startCooldown(60);
      HapticFeedback.lightImpact();
    } on Object catch (error) {
      if (!mounted) return;
      final retry = error is ApiException ? error.retryAfter?.inSeconds : null;
      if (retry != null) _startCooldown(retry);
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_confirmKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final callback = widget.confirmReset;
      if (callback != null) {
        await callback(
          _identifier.text.trim(),
          _accountType,
          _code.text.trim(),
          _newPassword.text,
        );
      } else {
        await AppScope.of(context).confirmPasswordReset(
          identifier: _identifier.text,
          accountType: _accountType,
          code: _code.text,
          newPassword: _newPassword.text,
        );
      }
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _step = _ResetStep.complete);
      HapticFeedback.mediumImpact();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _resendSeconds = seconds.clamp(1, 300));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return error.toString().replaceFirst(
      RegExp(r'^[A-Za-z]+Exception:\s*'),
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfScaffold(
      top: SfNavBar(
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(SfIcons.arrowL, size: 18),
          label: Text(_copy(context, uz: 'Kirish', ru: 'Вход', en: 'Sign in')),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
                child: SfStar(size: 240, color: c.primary),
              ),
            ),
          ),
          ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              24,
              28,
              24,
              30 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: switch (_step) {
                      _ResetStep.request => _requestForm(context),
                      _ResetStep.verify => _confirmForm(context),
                      _ResetStep.complete => _success(context),
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestForm(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Form(
      key: _requestKey,
      child: Column(
        key: const ValueKey('reset-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(
            title: _copy(
              context,
              uz: 'Parolni tiklash',
              ru: 'Сброс пароля',
              en: 'Reset password',
            ),
            subtitle: _copy(
              context,
              uz: 'Hisobingizga biriktirilgan telefon yoki emailga olti xonali kod yuboramiz.',
              ru: 'Мы отправим шестизначный код на телефон или email, привязанный к аккаунту.',
              en: 'We will send a six-digit code to the phone or email on your account.',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _copy(
              context,
              uz: 'Hisob turi',
              ru: 'Тип аккаунта',
              en: 'Account type',
            ),
            style: SfType.ui(size: 12, weight: FontWeight.w800, color: c.ink2),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'teacher',
                  icon: const Icon(Icons.school_outlined),
                  label: Text(
                    _copy(
                      context,
                      uz: 'O‘qituvchi',
                      ru: 'Учитель',
                      en: 'Teacher',
                    ),
                  ),
                ),
                ButtonSegment(
                  value: 'staff',
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(
                    _copy(context, uz: 'Xodim', ru: 'Сотрудник', en: 'Staff'),
                  ),
                ),
              ],
              selected: {_accountType},
              onSelectionChanged: _submitting
                  ? null
                  : (values) => setState(() => _accountType = values.first),
            ),
          ),
          const SizedBox(height: 18),
          SfTextField(
            key: const ValueKey('reset-identifier'),
            controller: _identifier,
            autofocus: true,
            label: _copy(
              context,
              uz: 'Telefon yoki email',
              ru: 'Телефон или email',
              en: 'Phone or email',
            ),
            hint: '+998 90 123 45 67',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _request(),
            validator: (value) {
              final clean = value?.trim() ?? '';
              if (clean.contains('@') ||
                  clean.replaceAll(RegExp(r'\D'), '').length >= 9) {
                return null;
              }
              return _copy(
                context,
                uz: 'To‘g‘ri telefon yoki email kiriting',
                ru: 'Введите корректный телефон или email',
                en: 'Enter a valid phone number or email',
              );
            },
          ),
          _errorBlock(context),
          const SizedBox(height: 22),
          SfButton(
            kind: SfButtonKind.primary,
            block: true,
            height: 54,
            label: _submitting
                ? _copy(
                    context,
                    uz: 'Yuborilmoqda…',
                    ru: 'Отправка…',
                    en: 'Sending…',
                  )
                : _copy(
                    context,
                    uz: 'Kod yuborish',
                    ru: 'Отправить код',
                    en: 'Send code',
                  ),
            trailing: _submitting ? null : SfIcons.arrowR,
            onPressed: _submitting ? null : _request,
          ),
          const SizedBox(height: 14),
          _PrivacyNote(colors: c),
        ],
      ),
    );
  }

  Widget _confirmForm(BuildContext context) {
    return Form(
      key: _confirmKey,
      child: Column(
        key: const ValueKey('reset-verify'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(
            title: _copy(
              context,
              uz: 'Kodni kiriting',
              ru: 'Введите код',
              en: 'Enter code',
            ),
            subtitle: _copy(
              context,
              uz: '${_identifier.text.trim()} manziliga kod so‘raldi. Hisob mavjudligi xavfsizlik sabab oshkor qilinmaydi.',
              ru: 'Код запрошен для ${_identifier.text.trim()}. Наличие аккаунта не раскрывается.',
              en: 'A code was requested for ${_identifier.text.trim()}. Account existence is never disclosed.',
            ),
          ),
          const SizedBox(height: 24),
          SfTextField(
            key: const ValueKey('reset-code'),
            controller: _code,
            autofocus: true,
            label: _copy(
              context,
              uz: '6 xonali kod',
              ru: '6-значный код',
              en: '6-digit code',
            ),
            hint: '000000',
            prefixIcon: Icons.password_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            validator: (value) =>
                RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                ? null
                : _copy(
                    context,
                    uz: 'Olti xonali kodni kiriting',
                    ru: 'Введите шестизначный код',
                    en: 'Enter the six-digit code',
                  ),
          ),
          const SizedBox(height: 12),
          SfTextField(
            key: const ValueKey('reset-new-password'),
            controller: _newPassword,
            label: _copy(
              context,
              uz: 'Yangi parol',
              ru: 'Новый пароль',
              en: 'New password',
            ),
            hint: _copy(
              context,
              uz: 'Kamida 10 belgi',
              ru: 'Не менее 10 символов',
              en: 'At least 10 characters',
            ),
            prefixIcon: SfIcons.shield,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (value) => (value?.length ?? 0) >= 10
                ? null
                : _copy(
                    context,
                    uz: 'Parol kamida 10 ta belgidan iborat bo‘lsin',
                    ru: 'Пароль должен содержать не менее 10 символов',
                    en: 'Password must contain at least 10 characters',
                  ),
          ),
          const SizedBox(height: 12),
          SfTextField(
            key: const ValueKey('reset-confirm-password'),
            controller: _confirmPassword,
            label: _copy(
              context,
              uz: 'Parolni takrorlang',
              ru: 'Повторите пароль',
              en: 'Confirm password',
            ),
            prefixIcon: Icons.verified_user_outlined,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            validator: (value) => value == _newPassword.text
                ? null
                : _copy(
                    context,
                    uz: 'Parollar bir xil emas',
                    ru: 'Пароли не совпадают',
                    en: 'Passwords do not match',
                  ),
          ),
          _errorBlock(context),
          const SizedBox(height: 22),
          SfButton(
            kind: SfButtonKind.primary,
            block: true,
            height: 54,
            label: _submitting
                ? _copy(
                    context,
                    uz: 'Tekshirilmoqda…',
                    ru: 'Проверка…',
                    en: 'Verifying…',
                  )
                : _copy(
                    context,
                    uz: 'Parolni yangilash',
                    ru: 'Обновить пароль',
                    en: 'Update password',
                  ),
            onPressed: _submitting ? null : _confirm,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _submitting || _resendSeconds > 0
                  ? null
                  : () => _request(resend: true),
              child: Text(
                _resendSeconds > 0
                    ? _copy(
                        context,
                        uz: 'Qayta yuborish · ${_resendSeconds}s',
                        ru: 'Отправить снова · $_resendSeconds с',
                        en: 'Resend · ${_resendSeconds}s',
                      )
                    : _copy(
                        context,
                        uz: 'Kodni qayta yuborish',
                        ru: 'Отправить код снова',
                        en: 'Resend code',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      key: const ValueKey('reset-success'),
      children: [
        const SizedBox(height: 34),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: c.successSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(SfIcons.check, size: 36, color: c.success),
        ),
        const SizedBox(height: 20),
        Text(
          _copy(
            context,
            uz: 'Parol yangilandi',
            ru: 'Пароль обновлён',
            en: 'Password updated',
          ),
          textAlign: TextAlign.center,
          style: SfType.ui(size: 26, weight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 8),
        Text(
          _copy(
            context,
            uz: 'Barcha eski sessiyalar yopildi. Yangi parol bilan qayta kiring.',
            ru: 'Все старые сессии завершены. Войдите с новым паролем.',
            en: 'All old sessions were ended. Sign in with your new password.',
          ),
          textAlign: TextAlign.center,
          style: SfType.ui(size: 14, color: c.muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        SfButton(
          kind: SfButtonKind.primary,
          block: true,
          label: _copy(
            context,
            uz: 'Kirishga qaytish',
            ru: 'Вернуться ко входу',
            en: 'Back to sign in',
          ),
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _errorBlock(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    child: _error == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: SfType.ui(
                  size: 12.5,
                  color: SfTheme.colorsOf(context).danger,
                  height: 1.4,
                ),
              ),
            ),
          ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SfType.display(size: 36, color: c.ink, height: 1.05),
        ),
        const SizedBox(height: 12),
        Text(subtitle, style: SfType.ui(size: 14, color: c.muted, height: 1.5)),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.colors});

  final SfColors colors;

  @override
  Widget build(BuildContext context) => SfSurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(SfIcons.shield, size: 19, color: colors.success),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _copy(
              context,
              uz: 'Xavfsizlik uchun hisob mavjud yoki yo‘qligi ko‘rsatilmaydi. Kod 5 noto‘g‘ri urinishdan keyin bloklanadi.',
              ru: 'В целях безопасности наличие аккаунта не раскрывается. Код блокируется после 5 неверных попыток.',
              en: 'For security, account existence is never disclosed. The code locks after 5 failed attempts.',
            ),
            style: SfType.ui(size: 12, color: colors.muted, height: 1.5),
          ),
        ),
      ],
    ),
  );
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
