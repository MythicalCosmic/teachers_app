import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../features/connectivity/backend_reachability.dart';
import '../theme/sf_theme.dart';
import 'sf_glass_surface.dart';
import 'sf_star.dart';
import 'sf_wordmark.dart';

/// Replaces every interactive route with a non-dismissible production gate
/// until the configured backend is reachable again.
class SfConnectivityGate extends StatelessWidget {
  const SfConnectivityGate({
    super.key,
    required this.controller,
    required this.locale,
    required this.child,
  });

  final BackendReachabilityController controller;
  final AppLocale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.blocksApp) return child;
        return _ConnectivityBlocker(
          key: ValueKey(controller.status),
          status: controller.status,
          retrying: controller.isChecking,
          locale: locale,
          onRetry: controller.retry,
        );
      },
    );
  }
}

class _ConnectivityBlocker extends StatelessWidget {
  const _ConnectivityBlocker({
    super.key,
    required this.status,
    required this.retrying,
    required this.locale,
    required this.onRetry,
  });

  final BackendReachabilityStatus status;
  final bool retrying;
  final AppLocale locale;
  final Future<void> Function() onRetry;

  bool get _isInitialCheck => status == BackendReachabilityStatus.checking;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final sf = SfTheme.of(context);
    final platform = Theme.of(context).platform;
    final apple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final copy = _ConnectivityCopy.forLocale(locale);

    return PopScope(
      canPop: false,
      child: ColoredBox(
        key: const Key('production-connectivity-gate'),
        color: c.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.72, -0.92),
                    radius: 1.22,
                    colors: [
                      c.primarySoft.withValues(alpha: sf.dark ? 0.42 : 0.82),
                      c.bg.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -92,
              bottom: -84,
              child: ExcludeSemantics(
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accentSoft.withValues(
                      alpha: sf.dark ? 0.18 : 0.46,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: _isInitialCheck
                          ? '${copy.checkingTitle}. ${copy.checkingBody}'
                          : '${copy.offlineTitle}. ${copy.offlineBody}',
                      child: SfGlassSurface(
                        enabled: sf.liquidGlass,
                        blurSigma: apple ? 28 : 16,
                        borderRadius: BorderRadius.circular(32),
                        tintColor: c.surface.withValues(
                          alpha: sf.dark ? 0.78 : 0.82,
                        ),
                        fallbackColor: c.surface,
                        shadows: [
                          BoxShadow(
                            color: c.ink.withValues(
                              alpha: sf.dark ? 0.28 : 0.10,
                            ),
                            blurRadius: 38,
                            offset: const Offset(0, 18),
                          ),
                        ],
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: SfWordmark(size: 15),
                            ),
                            const SizedBox(height: 34),
                            _ConnectivityMark(
                              checking: _isInitialCheck,
                              apple: apple,
                            ),
                            const SizedBox(height: 22),
                            Text(
                              _isInitialCheck
                                  ? copy.checkingTitle
                                  : copy.offlineTitle,
                              textAlign: TextAlign.center,
                              style: SfType.ui(
                                size: 24,
                                weight: FontWeight.w800,
                                color: c.ink,
                                letterSpacing: -0.55,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isInitialCheck
                                  ? copy.checkingBody
                                  : copy.offlineBody,
                              textAlign: TextAlign.center,
                              style: SfType.ui(
                                size: 14,
                                color: c.muted,
                                height: 1.5,
                              ),
                            ),
                            if (!_isInitialCheck) ...[
                              const SizedBox(height: 20),
                              _NetworkHint(text: copy.hint),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: _AdaptiveRetryButton(
                                  apple: apple,
                                  busy: retrying,
                                  label: copy.retry,
                                  onPressed: retrying ? null : onRetry,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 24),
                              _PlatformLoader(apple: apple, compact: false),
                            ],
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
}

class _ConnectivityMark extends StatelessWidget {
  const _ConnectivityMark({required this.checking, required this.apple});

  final bool checking;
  final bool apple;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primarySoft, c.surface2],
        ),
        border: Border.all(color: c.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.13),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: checking
          ? SfStar(size: 36, color: c.primary)
          : Icon(
              apple ? CupertinoIcons.wifi_slash : Icons.wifi_off_rounded,
              size: 34,
              color: c.primary,
            ),
    );
  }
}

class _NetworkHint extends StatelessWidget {
  const _NetworkHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface2.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 19, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: SfType.ui(size: 12.5, color: c.ink2, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveRetryButton extends StatelessWidget {
  const _AdaptiveRetryButton({
    required this.apple,
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool apple;
  final bool busy;
  final String label;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final content = busy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlatformLoader(apple: apple, compact: true),
              const SizedBox(width: 10),
              Text(label),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                apple ? CupertinoIcons.refresh : Icons.refresh_rounded,
                size: 19,
              ),
              const SizedBox(width: 9),
              Text(label),
            ],
          );

    if (apple) {
      return CupertinoButton.filled(
        key: const Key('connectivity-retry'),
        onPressed: onPressed == null ? null : () => onPressed!(),
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        disabledColor: c.primary.withValues(alpha: 0.56),
        child: DefaultTextStyle(
          style: SfType.ui(
            size: 15,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: content,
          ),
        ),
      );
    }

    return FilledButton(
      key: const Key('connectivity-retry'),
      onPressed: onPressed == null ? null : () => onPressed!(),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: SfType.ui(size: 15, weight: FontWeight.w700),
      ),
      child: content,
    );
  }
}

class _PlatformLoader extends StatelessWidget {
  const _PlatformLoader({required this.apple, required this.compact});

  final bool apple;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    if (apple) {
      return CupertinoActivityIndicator(
        radius: compact ? 9 : 13,
        color: compact ? Colors.white : c.primary,
      );
    }
    return SizedBox.square(
      dimension: compact ? 18 : 28,
      child: CircularProgressIndicator(
        strokeWidth: compact ? 2.4 : 3,
        strokeCap: StrokeCap.round,
        color: compact ? Colors.white : c.primary,
        backgroundColor: compact
            ? Colors.white.withValues(alpha: 0.22)
            : c.primarySoft,
      ),
    );
  }
}

final class _ConnectivityCopy {
  const _ConnectivityCopy({
    required this.checkingTitle,
    required this.checkingBody,
    required this.offlineTitle,
    required this.offlineBody,
    required this.hint,
    required this.retry,
  });

  final String checkingTitle;
  final String checkingBody;
  final String offlineTitle;
  final String offlineBody;
  final String hint;
  final String retry;

  static _ConnectivityCopy forLocale(AppLocale locale) => switch (locale) {
    AppLocale.uz => const _ConnectivityCopy(
      checkingTitle: 'Xavfsiz aloqa tekshirilmoqda',
      checkingBody:
          'StarForge serveri bilan himoyalangan ulanish tayyorlanmoqda.',
      offlineTitle: 'Internet aloqasi kerak',
      offlineBody:
          'Ma’lumotlaringizni to‘g‘ri va xavfsiz saqlash uchun ilova internetga ulangan holda ishlaydi.',
      hint:
          'Wi-Fi yoki mobil internetni yoqing. Ilova internet qaytganda avtomatik tekshiradi.',
      retry: 'Qayta tekshirish',
    ),
    AppLocale.ru => const _ConnectivityCopy(
      checkingTitle: 'Проверяем защищённое соединение',
      checkingBody:
          'Подготавливаем безопасное подключение к серверу StarForge.',
      offlineTitle: 'Требуется интернет',
      offlineBody:
          'Приложение работает онлайн, чтобы данные сохранялись правильно и безопасно.',
      hint:
          'Включите Wi-Fi или мобильный интернет. Приложение проверит соединение автоматически.',
      retry: 'Проверить снова',
    ),
    AppLocale.en => const _ConnectivityCopy(
      checkingTitle: 'Checking secure connection',
      checkingBody: 'Preparing a protected connection to the StarForge server.',
      offlineTitle: 'Internet connection required',
      offlineBody:
          'This app works online so your school data stays accurate and secure.',
      hint:
          'Turn on Wi-Fi or mobile data. The app will also retry automatically when the connection returns.',
      retry: 'Check again',
    ),
  };
}
