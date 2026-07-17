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
                              'Assalomu',
                              style: SfType.display(
                                size: 38,
                                color: c.ink,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'alaykum.',
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
                                'Xodim hisobingizga kiring. Huquqlar profilingizdan xavfsiz tarzda aniqlanadi.',
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
                              label: 'Foydalanuvchi nomi',
                              hint: 'ism.familiya',
                              prefixIcon: SfIcons.user,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              onChanged: (_) => _clearError(),
                              validator: (value) {
                                final username = value?.trim() ?? '';
                                if (username.isEmpty) {
                                  return 'Foydalanuvchi nomini kiriting';
                                }
                                if (username.length < 3) {
                                  return 'Kamida 3 ta belgi kiriting';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            SfTextField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              label: 'Parol',
                              hint: 'Parolingiz',
                              prefixIcon: SfIcons.shield,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) => _clearError(),
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Parolni ko‘rsatish'
                                    : 'Parolni yashirish',
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
                                  return 'Parolni kiriting';
                                }
                                if ((value ?? '').length < 6) {
                                  return 'Parol kamida 6 ta belgidan iborat';
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
                                    'Bu qurilmada eslab qol',
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
                                    'Parolni unutdingizmi?',
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
                              label: _submitting ? 'Tekshirilmoqda…' : 'Kirish',
                              trailing: _submitting ? null : SfIcons.arrowR,
                              fontSize: 16,
                              onPressed: _submitting ? null : _submit,
                            ),
                            const SizedBox(height: 14),
                            _CenterIdentity(colors: c),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Demo parol: demo2026 · Rol foydalanuvchi hisobidan aniqlanadi',
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
      label: 'StarForge EDU, Xodimlar',
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
                  const SfPill(label: 'Xodimlar'),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: brand),
                const SizedBox(width: 12),
                const SfPill(label: 'Xodimlar'),
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
                  'Yunusobod filiali · staff.starforge.uz',
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
