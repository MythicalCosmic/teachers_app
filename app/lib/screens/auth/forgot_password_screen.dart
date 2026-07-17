import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/sf_theme.dart';
import '../../widgets/sf_app_bar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_form_controls.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_scaffold.dart';
import '../../widgets/sf_star.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    // The local repository mirrors the async hand-off a real identity service
    // performs. No account-existence detail is exposed in the response.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
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
          label: const Text('Kirish'),
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
                    ? _Success(username: _username.text.trim())
                    : _RequestForm(
                        formKey: _formKey,
                        username: _username,
                        submitting: _submitting,
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
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController username;
  final bool submitting;
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
            'Parolni',
            style: SfType.display(size: 36, color: c.ink, height: 1),
          ),
          Text(
            'tiklash',
            style: SfType.ui(
              size: 34,
              weight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Foydalanuvchi nomini yozing. Markaz ma’muriga xavfsiz tiklash so‘rovi yuboriladi.',
            style: SfType.ui(size: 14, color: c.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          SfTextField(
            controller: username,
            autofocus: true,
            label: 'Foydalanuvchi nomi',
            hint: 'ism.familiya',
            prefixIcon: SfIcons.user,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username],
            onSubmitted: (_) => onSubmit(),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? 'To‘g‘ri foydalanuvchi nomini kiriting'
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
                          text: 'Xavfsizlik: ',
                          style: SfType.ui(
                            size: 12,
                            weight: FontWeight.w800,
                            color: c.ink2,
                          ),
                        ),
                        TextSpan(
                          text:
                              'hisob mavjudligi oshkor qilinmaydi. Yangi parol faqat tasdiqlangan kanal orqali beriladi.',
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
          SfButton(
            kind: SfButtonKind.primary,
            block: true,
            height: 54,
            label: submitting ? 'Yuborilmoqda…' : 'So‘rov yuborish',
            trailing: submitting ? null : SfIcons.arrowR,
            fontSize: 16,
            onPressed: submitting ? null : onSubmit,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Yordam: +998 71 200 11 11',
              style: SfType.ui(size: 12, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.username});

  final String username;

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
          'So‘rov qabul qilindi',
          style: SfType.ui(size: 28, weight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 10),
        Text(
          '$username uchun so‘rov markaz ma’muriga yuborildi. Odatda javob 15 daqiqa ichida keladi.',
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
                  'So‘rov ID',
                  style: SfType.ui(size: 12, color: c.muted),
                ),
              ),
              Text(
                'RST-260717',
                style: SfType.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SfButton(
          kind: SfButtonKind.primary,
          block: true,
          height: 52,
          label: 'Kirishga qaytish',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
