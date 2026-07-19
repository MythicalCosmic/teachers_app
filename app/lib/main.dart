import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_scope.dart';
import 'app/app_state.dart';
import 'data/models.dart';
import 'data/api/starforge_api.dart';
import 'router.dart';
import 'screens/groups/group_workspace_store.dart';
import 'theme/sf_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final appState = await AppState.bootstrap(api: StarforgeApi());
  runApp(StarForgeStaffApp(appState: appState));
}

class StarForgeStaffApp extends StatefulWidget {
  const StarForgeStaffApp({super.key, required this.appState});

  final AppState appState;

  @override
  State<StarForgeStaffApp> createState() => _StarForgeStaffAppState();
}

class _StarForgeStaffAppState extends State<StarForgeStaffApp>
    with WidgetsBindingObserver {
  late final _router = buildRouter(widget.appState);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.appState.resumeRealtime();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.appState.pauseRealtime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final settings = widget.appState.settings;
        final palette = _palette(settings.palette);
        final lightColors = sfColorsFor(palette);
        final darkColors = sfColorsFor(palette, dark: true);
        return AppScope(
          notifier: widget.appState,
          child: MaterialApp.router(
            title: 'StarForge EDU Staff',
            debugShowCheckedModeBanner: false,
            theme: buildMaterialTheme(
              lightColors,
              dark: false,
              fontChoice: settings.fontChoice,
              layoutDensity: settings.layoutDensity,
            ),
            darkTheme: buildMaterialTheme(
              darkColors,
              dark: true,
              fontChoice: settings.fontChoice,
              layoutDensity: settings.layoutDensity,
            ),
            themeMode: _themeMode(settings.themeMode),
            themeAnimationDuration: settings.reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            themeAnimationCurve: Curves.easeOutCubic,
            locale: Locale(settings.locale.name),
            supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              final dark = Theme.of(context).brightness == Brightness.dark;
              final colors = dark ? darkColors : lightColors;
              final overlay = SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
              );
              return SfTheme(
                colors: colors,
                palette: palette,
                dark: dark,
                visualStyle: settings.visualStyle,
                fontChoice: settings.fontChoice,
                layoutDensity: settings.layoutDensity,
                surfaceOpacity: settings.surfaceOpacity,
                navigationOpacity: settings.navigationOpacity,
                motionIntensity: settings.motionIntensity,
                liquidGlass: settings.liquidGlass,
                reducedMotion: settings.reducedMotion,
                child: SfMotionConfiguration(
                  enabled: !settings.reducedMotion,
                  intensity: settings.motionIntensity,
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: overlay,
                    child: _PersistenceAwareBody(
                      appState: widget.appState,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PersistenceAwareBody extends StatelessWidget {
  const _PersistenceAwareBody({required this.appState, required this.child});

  final AppState appState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!appState.isInitialized) {
      return _SessionRestoreSurface(appState: appState);
    }
    return ListenableBuilder(
      listenable: appState.messagingController,
      builder: (context, _) => ListenableBuilder(
        listenable: groupWorkspaceStore,
        builder: (context, _) {
          final issue = appState.persistenceError != null
              ? _PersistenceIssue(
                  message: appState.persistenceError!,
                  retry: appState.retryPersistence,
                  dismiss: appState.clearPersistenceError,
                )
              : appState.messagingController.persistenceError != null
              ? _PersistenceIssue(
                  message: appState.messagingController.persistenceError!,
                  retry: appState.messagingController.retryPersistence,
                  dismiss: appState.messagingController.clearPersistenceError,
                )
              : !appState.isProduction &&
                    groupWorkspaceStore.persistenceError != null
              ? _PersistenceIssue(
                  message: groupWorkspaceStore.persistenceError!,
                  retry: groupWorkspaceStore.retryPersistence,
                  dismiss: groupWorkspaceStore.clearPersistenceError,
                )
              : null;
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (issue != null)
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Material(
                        elevation: 10,
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: Semantics(
                          container: true,
                          liveRegion: true,
                          label: issue.message,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.cloud_off_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          issue.message,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Semantics(
                                        button: true,
                                        label:
                                            switch (appState.settings.locale) {
                                              AppLocale.uz => 'Yopish',
                                              AppLocale.ru => 'Закрыть',
                                              AppLocale.en => 'Dismiss',
                                            },
                                        child: IconButton(
                                          key: const Key(
                                            'persistence-error-dismiss',
                                          ),
                                          onPressed: issue.dismiss,
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => unawaited(issue.retry()),
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        switch (appState.settings.locale) {
                                          AppLocale.uz => 'Qayta urinish',
                                          AppLocale.ru => 'Повторить',
                                          AppLocale.en => 'Retry',
                                        },
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
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionRestoreSurface extends StatelessWidget {
  const _SessionRestoreSurface({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final colors = SfTheme.colorsOf(context);
    return ColoredBox(
      color: colors.bg,
      child: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: switch (appState.settings.locale) {
              AppLocale.uz => 'Xavfsiz sessiya tekshirilmoqda',
              AppLocale.ru => 'Проверяется безопасная сессия',
              AppLocale.en => 'Checking secure session',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'STARFORGE STAFF',
                  style: SfType.mono(
                    size: 12,
                    weight: FontWeight.w800,
                    color: colors.ink,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersistenceIssue {
  const _PersistenceIssue({
    required this.message,
    required this.retry,
    required this.dismiss,
  });

  final String message;
  final Future<void> Function() retry;
  final VoidCallback dismiss;
}

SfPalette _palette(AppPalette value) => switch (value) {
  AppPalette.daryo => SfPalette.daryo,
  AppPalette.saroy => SfPalette.saroy,
  AppPalette.marvarid => SfPalette.marvarid,
  AppPalette.samarqand => SfPalette.samarqand,
};

ThemeMode _themeMode(AppThemeMode value) => switch (value) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};
