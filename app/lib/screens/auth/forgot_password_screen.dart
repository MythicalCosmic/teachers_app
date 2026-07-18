import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';
import '../../widgets/sf_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _storageKey = 'starforge.pending_recovery_request.v1';

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _requestId;
  DateTime? _requestedAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_restorePendingRequest());
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _restorePendingRequest() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final username = json['username'] as String?;
      final requestId = json['requestId'] as String?;
      final requestedAt = DateTime.tryParse(
        json['requestedAt'] as String? ?? '',
      );
      if (username == null || requestId == null || requestedAt == null) return;
      if (!mounted) return;
      _username.text = username;
      setState(() {
        _requestId = requestId;
        _requestedAt = requestedAt;
        _submitted = true;
      });
    } on Object {
      // A malformed local draft is ignored; the user can prepare a fresh one.
    }
  }

  String _requestText() {
    final requestedAt = _requestedAt ?? DateTime.now();
    return 'StarForge Staff password recovery\n'
        'Request ID: ${_requestId ?? '-'}\n'
        'Username: ${_username.text.trim()}\n'
        'Created: ${requestedAt.toIso8601String()}\n'
        'Please verify my identity through the approved staff channel.';
  }

  Future<bool> _copyRequest({bool showFeedback = false}) async {
    try {
      await Clipboard.setData(ClipboardData(text: _requestText()));
    } on Object {
      if (mounted && showFeedback) {
        SfToast.show(
          context,
          title: _copy(
            context,
            uz: 'Nusxalab bo‘lmadi',
            ru: 'Не удалось скопировать',
            en: 'Could not copy',
          ),
          message: _copy(
            context,
            uz: 'So‘rov kartasidan ID va foydalanuvchi nomini qo‘lda yuboring.',
            ru: 'Отправьте ID и имя пользователя с карточки вручную.',
            en: 'Send the request ID and username from the card manually.',
          ),
          tone: SfToastTone.error,
        );
      }
      return false;
    }
    if (!mounted || !showFeedback) return true;
    SfToast.show(
      context,
      title: _copy(
        context,
        uz: 'So‘rov nusxalandi',
        ru: 'Запрос скопирован',
        en: 'Request copied',
      ),
      message: _copy(
        context,
        uz: 'Uni tasdiqlangan administrator kanaliga yuboring.',
        ru: 'Отправьте его через подтверждённый канал администратора.',
        en: 'Send it through your verified administrator channel.',
      ),
      tone: SfToastTone.success,
    );
    return true;
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final requestId =
        'RST-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    var stored = false;
    var copied = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      stored = await preferences.setString(
        _storageKey,
        jsonEncode({
          'username': _username.text.trim(),
          'requestId': requestId,
          'requestedAt': now.toIso8601String(),
        }),
      );
    } on Object {
      stored = false;
    }
    _requestId = requestId;
    _requestedAt = now;
    copied = await _copyRequest();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = stored || copied;
      _error = stored || copied
          ? null
          : _copy(
              context,
              uz: 'So‘rovni saqlash yoki nusxalashning iloji bo‘lmadi.',
              ru: 'Не удалось сохранить или скопировать запрос.',
              en: 'The request could not be saved or copied.',
            );
    });
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
              28,
              30,
              28,
              30 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                child: _submitted
                    ? _Success(
                        username: _username.text.trim(),
                        requestId: _requestId!,
                        requestedAt: _requestedAt!,
                        onCopy: () =>
                            unawaited(_copyRequest(showFeedback: true)),
                      )
                    : _RequestForm(
                        formKey: _formKey,
                        username: _username,
                        submitting: _submitting,
                        error: _error,
                        onSubmit: _send,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.formKey,
    required this.username,
    required this.submitting,
    required this.error,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController username;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Form(
      key: formKey,
      child: Column(
        key: const ValueKey('reset-form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy(context, uz: 'Parolni', ru: 'Сброс', en: 'Reset'),
            style: SfType.display(size: 36, color: c.ink, height: 1),
          ),
          Text(
            _copy(context, uz: 'tiklash', ru: 'пароля', en: 'password'),
            style: SfType.ui(
              size: 34,
              weight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _copy(
              context,
              uz: 'Foydalanuvchi nomini yozing. Ilova xavfsiz so‘rov shablonini qurilmada saqlaydi va nusxalaydi; uni tasdiqlangan administrator kanaliga o‘zingiz yuborasiz.',
              ru: 'Введите имя пользователя. Приложение сохранит на устройстве и скопирует безопасный шаблон; отправьте его администратору через подтверждённый канал.',
              en: 'Enter your username. The app saves and copies a secure request template on this device; send it through your verified administrator channel.',
            ),
            style: SfType.ui(size: 14, color: c.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          SfTextField(
            controller: username,
            autofocus: true,
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => onSubmit(),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? _copy(
                    context,
                    uz: 'To‘g‘ri foydalanuvchi nomini kiriting',
                    ru: 'Введите корректное имя пользователя',
                    en: 'Enter a valid username',
                  )
                : null,
          ),
          const SizedBox(height: 18),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(SfIcons.shield, size: 19, color: c.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _copy(
                            context,
                            uz: 'Xavfsizlik: ',
                            ru: 'Безопасность: ',
                            en: 'Security: ',
                          ),
                          style: SfType.ui(
                            size: 12,
                            weight: FontWeight.w800,
                            color: c.ink2,
                          ),
                        ),
                        TextSpan(
                          text: _copy(
                            context,
                            uz: 'hisob mavjudligi oshkor qilinmaydi. Yangi parol faqat tasdiqlangan kanal orqali beriladi.',
                            ru: 'существование аккаунта не раскрывается. Новый пароль передаётся только через подтверждённый канал.',
                            en: 'account existence is never disclosed. A new password is only delivered through a verified channel.',
                          ),
                          style: SfType.ui(
                            size: 12,
                            color: c.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (error != null) ...[
            Text(
              error!,
              style: SfType.ui(size: 12, color: c.danger, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],
          SfButton(
            kind: SfButtonKind.primary,
            block: true,
            height: 54,
            label: submitting
                ? _copy(
                    context,
                    uz: 'Tayyorlanmoqda…',
                    ru: 'Подготовка…',
                    en: 'Preparing…',
                  )
                : _copy(
                    context,
                    uz: 'So‘rovni tayyorlash',
                    ru: 'Подготовить запрос',
                    en: 'Prepare request',
                  ),
            trailing: submitting ? null : SfIcons.arrowR,
            fontSize: 16,
            onPressed: submitting ? null : onSubmit,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '${_copy(context, uz: 'Yordam', ru: 'Помощь', en: 'Help')}: +998 71 200 11 11',
              style: SfType.ui(size: 12, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({
    required this.username,
    required this.requestId,
    required this.requestedAt,
    required this.onCopy,
  });

  final String username;
  final String requestId;
  final DateTime requestedAt;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Column(
      key: const ValueKey('reset-success'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: c.successSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(SfIcons.check, size: 30, color: c.success),
        ),
        const SizedBox(height: 22),
        Text(
          _copy(
            context,
            uz: 'So‘rov tayyor',
            ru: 'Запрос подготовлен',
            en: 'Request prepared',
          ),
          style: SfType.ui(size: 28, weight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 10),
        Text(
          _copy(
            context,
            uz: '$username uchun shablon qurilmada saqlandi va almashish uchun nusxalandi. Ilova identity serveriga ulanmagan — uni tasdiqlangan administrator kanaliga yuboring.',
            ru: 'Шаблон для $username сохранён на устройстве и скопирован. Приложение не подключено к серверу идентификации — отправьте его через подтверждённый канал.',
            en: 'The template for $username is saved on this device and copied for sharing. The app is not connected to the identity server—send it through your verified administrator channel.',
          ),
          style: SfType.ui(size: 14, color: c.muted, height: 1.55),
        ),
        const SizedBox(height: 22),
        SfSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _copy(
                    context,
                    uz: 'So‘rov ID',
                    ru: 'ID запроса',
                    en: 'Request ID',
                  ),
                  style: SfType.ui(size: 12, color: c.muted),
                ),
              ),
              Text(
                requestId,
                style: SfType.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _copy(
            context,
            uz: 'Tayyorlangan vaqt: ${_formatRecoveryTime(requestedAt)}',
            ru: 'Подготовлено: ${_formatRecoveryTime(requestedAt)}',
            en: 'Prepared: ${_formatRecoveryTime(requestedAt)}',
          ),
          style: SfType.ui(size: 11, color: c.muted),
        ),
        const SizedBox(height: 28),
        SfButton(
          kind: SfButtonKind.ghost,
          block: true,
          height: 50,
          label: _copy(
            context,
            uz: 'So‘rovni yana nusxalash',
            ru: 'Скопировать запрос снова',
            en: 'Copy request again',
          ),
          leading: Icons.copy_all_rounded,
          onPressed: onCopy,
        ),
        const SizedBox(height: 10),
        SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 52,
          label: _copy(
            context,
            uz: 'Kirishga qaytish',
            ru: 'Вернуться ко входу',
            en: 'Back to sign in',
          ),
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

String _formatRecoveryTime(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

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
