import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../l10n/sf_l10n.dart';
import '../theme/sf_theme.dart';
import '../theme/tokens.dart';
import '../widgets/sf_adaptive_dialog.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_glass_surface.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _surfaceOpacity;
  double? _navigationOpacity;
  double? _motionIntensity;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final settings = app.settings;
    final c = SfTheme.colorsOf(context);
    _surfaceOpacity ??= settings.surfaceOpacity;
    _navigationOpacity ??= settings.navigationOpacity;
    _motionIntensity ??= settings.motionIntensity;

    if (session == null) {
      return SfScaffold(
        body: SfErrorState(
          title: _copy(
            context,
            uz: 'Sessiya topilmadi',
            ru: 'Сессия не найдена',
            en: 'Session not found',
          ),
          message: _copy(
            context,
            uz: 'Profil sozlamalarini ochish uchun qayta kiring.',
            ru: 'Войдите снова, чтобы открыть настройки профиля.',
            en: 'Sign in again to open profile settings.',
          ),
        ),
      );
    }

    void confirm(String message) => SfToast.show(
      context,
      title: _copy(context, uz: 'Saqlandi', ru: 'Сохранено', en: 'Saved'),
      message: message,
      tone: SfToastTone.success,
      motionEnabled: !settings.reducedMotion,
      glassEnabled: SfTheme.of(context).usesGlass,
    );

    return SfScaffold(
      top: SfNavBar(
        title: context.tr('settings'),
        leading: IconButton(
          tooltip: _copy(context, uz: 'Orqaga', ru: 'Назад', en: 'Back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 38),
        children: [
          _ProfileHero(
            session: session,
            onEdit: () => context.push('/settings/edit'),
          ),
          _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            title: context.tr('design_studio'),
            subtitle: _copy(
              context,
              uz: 'Ko‘rinish, qatlam va tipografiyani o‘zingizga moslang.',
              ru: 'Настройте стиль, поверхности и типографику.',
              en: 'Tune the style, surfaces and typography to feel like yours.',
            ),
          ),
          SfSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ControlLabel(
                  label: _copy(
                    context,
                    uz: 'YORUG‘LIK REJIMI',
                    ru: 'РЕЖИМ ЯРКОСТИ',
                    en: 'APPEARANCE MODE',
                  ),
                ),
                SfSegmentedControl<AppThemeMode>(
                  expanded: true,
                  value: settings.themeMode,
                  segments: [
                    SfSegment(
                      value: AppThemeMode.system,
                      label: context.tr('system'),
                      icon: Icons.brightness_auto_rounded,
                    ),
                    SfSegment(
                      value: AppThemeMode.light,
                      label: context.tr('light'),
                      icon: Icons.light_mode_rounded,
                    ),
                    SfSegment(
                      value: AppThemeMode.dark,
                      label: context.tr('dark'),
                      icon: Icons.dark_mode_rounded,
                    ),
                  ],
                  onChanged: (value) {
                    unawaited(app.setThemeMode(value));
                    confirm(
                      _copy(
                        context,
                        uz: 'Yorug‘lik rejimi yangilandi.',
                        ru: 'Режим оформления обновлён.',
                        en: 'Appearance mode updated.',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _ControlLabel(
                  label: _copy(
                    context,
                    uz: 'VIZUAL USLUB',
                    ru: 'ВИЗУАЛЬНЫЙ СТИЛЬ',
                    en: 'VISUAL STYLE',
                  ),
                  trailing: _copy(
                    context,
                    uz: 'Barcha ekranlarga qo‘llanadi',
                    ru: 'Для всех экранов',
                    en: 'Applies everywhere',
                  ),
                ),
                _VisualStylePicker(
                  value: settings.visualStyle,
                  onChanged: (value) {
                    unawaited(app.setVisualStyle(value));
                    if (value == AppVisualStyle.liquidGlass &&
                        !settings.liquidGlass) {
                      unawaited(app.setLiquidGlass(true));
                    }
                  },
                ),
                const SizedBox(height: 18),
                _ControlLabel(
                  label: _copy(
                    context,
                    uz: 'RANG TO‘PLAMI',
                    ru: 'ПАЛИТРА',
                    en: 'COLOR PALETTE',
                  ),
                ),
                _PalettePicker(
                  value: settings.palette,
                  onChanged: (value) => unawaited(app.setPalette(value)),
                ),
                const SizedBox(height: 18),
                _ControlLabel(
                  label: _copy(
                    context,
                    uz: 'SHRIFT',
                    ru: 'ШРИФТ',
                    en: 'TYPEFACE',
                  ),
                ),
                _FontPicker(
                  value: settings.fontChoice,
                  onChanged: (value) => unawaited(app.setFontChoice(value)),
                ),
                const SizedBox(height: 18),
                _ControlLabel(
                  label: _copy(
                    context,
                    uz: 'JOYLANISH ZICHLIGI',
                    ru: 'ПЛОТНОСТЬ ИНТЕРФЕЙСА',
                    en: 'LAYOUT DENSITY',
                  ),
                ),
                SfSegmentedControl<AppLayoutDensity>(
                  expanded: true,
                  value: settings.layoutDensity,
                  segments: [
                    SfSegment(
                      value: AppLayoutDensity.compact,
                      label: _copy(
                        context,
                        uz: 'Ixcham',
                        ru: 'Компактно',
                        en: 'Compact',
                      ),
                    ),
                    SfSegment(
                      value: AppLayoutDensity.comfortable,
                      label: _copy(
                        context,
                        uz: 'Qulay',
                        ru: 'Удобно',
                        en: 'Comfort',
                      ),
                    ),
                    SfSegment(
                      value: AppLayoutDensity.spacious,
                      label: _copy(
                        context,
                        uz: 'Keng',
                        ru: 'Просторно',
                        en: 'Spacious',
                      ),
                    ),
                  ],
                  onChanged: (value) => unawaited(app.setLayoutDensity(value)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SfSurfaceCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              children: [
                _SettingsSwitch(
                  icon: Icons.blur_on_rounded,
                  title: 'Liquid Glass',
                  subtitle: _copy(
                    context,
                    uz: 'iPhone’da haqiqiy blur, yorug‘ aks va chuqurlik beradi.',
                    ru: 'Настоящее размытие, блик и глубина на iPhone.',
                    en: 'Real iPhone blur, reflective highlights and depth.',
                  ),
                  value: settings.liquidGlass,
                  onChanged: (value) {
                    unawaited(app.setLiquidGlass(value));
                    confirm(
                      value
                          ? 'Liquid Glass ${_copy(context, uz: 'yoqildi', ru: 'включён', en: 'enabled')}'
                          : 'Liquid Glass ${_copy(context, uz: 'o‘chirildi', ru: 'выключен', en: 'disabled')}',
                    );
                  },
                ),
                const Divider(height: 18),
                _OpacitySlider(
                  icon: Icons.layers_outlined,
                  label: _copy(
                    context,
                    uz: 'Kartalar shaffofligi',
                    ru: 'Прозрачность карточек',
                    en: 'Card transparency',
                  ),
                  value: _surfaceOpacity!,
                  onChanged: (value) => setState(() => _surfaceOpacity = value),
                  onChangeEnd: (value) =>
                      unawaited(app.setSurfaceOpacity(value)),
                ),
                _OpacitySlider(
                  icon: Icons.dock_rounded,
                  label: _copy(
                    context,
                    uz: 'Navigatsiya shaffofligi',
                    ru: 'Прозрачность навигации',
                    en: 'Navigation transparency',
                  ),
                  value: _navigationOpacity!,
                  onChanged: (value) =>
                      setState(() => _navigationOpacity = value),
                  onChangeEnd: (value) =>
                      unawaited(app.setNavigationOpacity(value)),
                ),
                _TransparencyPreview(
                  surfaceOpacity: _surfaceOpacity!,
                  navigationOpacity: _navigationOpacity!,
                ),
              ],
            ),
          ),
          _SectionTitle(
            icon: Icons.translate_rounded,
            title: context.tr('language'),
            subtitle: _copy(
              context,
              uz: 'Tanlov ushbu qurilmada doimiy saqlanadi.',
              ru: 'Выбор постоянно сохраняется на этом устройстве.',
              en: 'Your choice is saved permanently on this device.',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _LanguageTile(
                  code: 'UZ',
                  label: 'O‘zbekcha',
                  selected: settings.locale == AppLocale.uz,
                  onTap: () => unawaited(app.setLocale(AppLocale.uz)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageTile(
                  code: 'RU',
                  label: 'Русский',
                  selected: settings.locale == AppLocale.ru,
                  onTap: () => unawaited(app.setLocale(AppLocale.ru)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageTile(
                  code: 'EN',
                  label: 'English',
                  selected: settings.locale == AppLocale.en,
                  onTap: () => unawaited(app.setLocale(AppLocale.en)),
                ),
              ),
            ],
          ),
          _SectionTitle(
            icon: Icons.animation_rounded,
            title: context.tr('accessibility'),
            subtitle: _copy(
              context,
              uz: 'Harakat sizga tabiiy va qulay tuyulishi kerak.',
              ru: 'Движение должно ощущаться естественно и комфортно.',
              en: 'Motion should always feel natural and comfortable.',
            ),
          ),
          SfSurfaceCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              children: [
                _OpacitySlider(
                  icon: Icons.speed_rounded,
                  label: _copy(
                    context,
                    uz: 'Animatsiya tempi',
                    ru: 'Темп анимации',
                    en: 'Animation tempo',
                  ),
                  value: _motionIntensity!,
                  min: .65,
                  max: 1.35,
                  percent: false,
                  valueLabel: _motionIntensity! < .9
                      ? _copy(context, uz: 'Tez', ru: 'Быстро', en: 'Fast')
                      : _motionIntensity! > 1.1
                      ? _copy(context, uz: 'Mayin', ru: 'Плавно', en: 'Gentle')
                      : _copy(
                          context,
                          uz: 'Tabiiy',
                          ru: 'Естественно',
                          en: 'Natural',
                        ),
                  onChanged: (value) =>
                      setState(() => _motionIntensity = value),
                  onChangeEnd: (value) =>
                      unawaited(app.setMotionIntensity(value)),
                ),
                const Divider(height: 8),
                _SettingsSwitch(
                  icon: Icons.motion_photos_off_outlined,
                  title: _copy(
                    context,
                    uz: 'Kamaytirilgan harakat',
                    ru: 'Уменьшение движения',
                    en: 'Reduced motion',
                  ),
                  subtitle: _copy(
                    context,
                    uz: 'Keraksiz o‘tish va effektlarni o‘chiradi.',
                    ru: 'Отключает необязательные переходы и эффекты.',
                    en: 'Disables non-essential transitions and effects.',
                  ),
                  value: settings.reducedMotion,
                  onChanged: (value) => unawaited(app.setReducedMotion(value)),
                ),
                const Divider(height: 8),
                _SettingsSwitch(
                  icon: Icons.vibration_rounded,
                  title: _copy(
                    context,
                    uz: 'Haptik javob',
                    ru: 'Тактильный отклик',
                    en: 'Haptic feedback',
                  ),
                  subtitle: _copy(
                    context,
                    uz: 'Muhim bosishlarda mayin tebranish.',
                    ru: 'Мягкая вибрация для важных действий.',
                    en: 'A subtle response for important actions.',
                  ),
                  value: settings.haptics,
                  onChanged: (value) => unawaited(app.setHaptics(value)),
                ),
                const Divider(height: 8),
                _SettingsSwitch(
                  icon: Icons.tips_and_updates_outlined,
                  title: _copy(
                    context,
                    uz: 'Kontekst yordamlar',
                    ru: 'Контекстные подсказки',
                    en: 'Contextual guidance',
                  ),
                  subtitle: _copy(
                    context,
                    uz: 'Murakkab joylarda qisqa va foydali ko‘rsatma.',
                    ru: 'Короткие подсказки в сложных местах.',
                    en: 'Short, useful guidance where an action is complex.',
                  ),
                  value: settings.coachMarks,
                  onChanged: (value) => unawaited(app.setCoachMarks(value)),
                ),
              ],
            ),
          ),
          _SectionTitle(
            icon: Icons.shield_outlined,
            title: _copy(
              context,
              uz: 'Hisob va ma’lumotlar',
              ru: 'Аккаунт и данные',
              en: 'Account and data',
            ),
            subtitle: session.email,
          ),
          SfSurfaceCard(
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.refresh_rounded,
                  title: _copy(
                    context,
                    uz: 'Demo ma’lumotlarini tiklash',
                    ru: 'Сбросить демо-данные',
                    en: 'Reset demo data',
                  ),
                  onTap: () async {
                    final approved = await showSfConfirmDialog(
                      context,
                      title: _copy(
                        context,
                        uz: 'Ma’lumotlar tiklansinmi?',
                        ru: 'Сбросить данные?',
                        en: 'Reset the data?',
                      ),
                      message: _copy(
                        context,
                        uz: 'Vazifa, davomat va xabarlar boshlang‘ich holatga qaytadi.',
                        ru: 'Задачи, посещаемость и сообщения вернутся к исходному виду.',
                        en: 'Tasks, attendance and messages return to their original demo state.',
                      ),
                      confirmLabel: _copy(
                        context,
                        uz: 'Tiklash',
                        ru: 'Сбросить',
                        en: 'Reset',
                      ),
                      destructive: true,
                    );
                    if (!approved || !context.mounted) return;
                    await app.resetDemoData();
                    if (context.mounted) {
                      confirm(
                        _copy(
                          context,
                          uz: 'Demo ma’lumotlari tiklandi.',
                          ru: 'Демо-данные сброшены.',
                          en: 'Demo data has been reset.',
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SfButton(
            label: _copy(
              context,
              uz: 'Hisobdan chiqish',
              ru: 'Выйти',
              en: 'Sign out',
            ),
            leading: Icons.logout_rounded,
            kind: SfButtonKind.danger,
            block: true,
            height: 52,
            onPressed: () async {
              final approved = await showSfConfirmDialog(
                context,
                title: _copy(
                  context,
                  uz: 'Hisobdan chiqilsinmi?',
                  ru: 'Выйти из аккаунта?',
                  en: 'Sign out?',
                ),
                message: _copy(
                  context,
                  uz: 'Keyingi kirishda login ma’lumotlari kerak bo‘ladi.',
                  ru: 'При следующем входе понадобятся данные аккаунта.',
                  en: 'You will need your account details the next time you sign in.',
                ),
                confirmLabel: _copy(
                  context,
                  uz: 'Chiqish',
                  ru: 'Выйти',
                  en: 'Sign out',
                ),
                destructive: true,
              );
              if (approved) await app.signOut();
            },
          ),
          const SizedBox(height: 14),
          Text(
            'StarForge Staff · 2.0 Experience Preview',
            textAlign: TextAlign.center,
            style: SfType.mono(size: 10, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.session, required this.onEdit});

  final StaffSession session;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SfAvatar(name: session.displayName, size: 64),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(
                    size: 18,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_roleLabel(context, session.role)} · ${session.branchName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(size: 12, color: c.muted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SfPressable(
            onPressed: onEdit,
            semanticLabel: context.tr('edit_profile'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.edit_rounded, color: c.primary, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 25, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: c.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SfType.ui(
                    size: 16,
                    weight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: SfType.ui(size: 11.5, color: c.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlLabel extends StatelessWidget {
  const _ControlLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: SfType.eyebrow(color: c.muted)),
          ),
          if (trailing != null)
            Text(trailing!, style: SfType.ui(size: 9.5, color: c.muted2)),
        ],
      ),
    );
  }
}

class _VisualStylePicker extends StatelessWidget {
  const _VisualStylePicker({required this.value, required this.onChanged});

  final AppVisualStyle value;
  final ValueChanged<AppVisualStyle> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: AppVisualStyle.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 9),
      itemBuilder: (context, index) {
        final style = AppVisualStyle.values[index];
        return _StyleTile(
          style: style,
          selected: style == value,
          onTap: () => onChanged(style),
        );
      },
    ),
  );
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AppVisualStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final label = switch (style) {
      AppVisualStyle.classic => 'Classic',
      AppVisualStyle.glassmorphism => 'Glass',
      AppVisualStyle.claymorphism => 'Clay',
      AppVisualStyle.liquidGlass => 'Liquid',
      AppVisualStyle.maximalism => 'Maximal',
    };
    return SizedBox(
      width: 88,
      child: SfPressable(
        onPressed: onTap,
        selected: selected,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: SfTheme.of(
            context,
          ).duration(const Duration(milliseconds: 240)),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : c.surface2.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _MiniStylePreview(style: style)),
              const SizedBox(height: 6),
              Text(
                label,
                style: SfType.ui(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: selected ? c.primary : c.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStylePreview extends StatelessWidget {
  const _MiniStylePreview({required this.style});

  final AppVisualStyle style;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    final decoration = switch (style) {
      AppVisualStyle.classic => BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      AppVisualStyle.glassmorphism => BoxDecoration(
        color: c.surface.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: .13), blurRadius: 8),
        ],
      ),
      AppVisualStyle.claymorphism => BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: c.ink.withValues(alpha: .18),
            offset: const Offset(3, 4),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .72),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      AppVisualStyle.liquidGlass => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .76),
            c.primarySoft.withValues(alpha: .38),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .92)),
        boxShadow: [
          BoxShadow(color: c.primary.withValues(alpha: .16), blurRadius: 10),
        ],
      ),
      AppVisualStyle.maximalism => BoxDecoration(
        gradient: LinearGradient(colors: [c.primarySoft, c.accentSoft]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.ink, width: 1.4),
        boxShadow: [BoxShadow(color: c.ink, offset: const Offset(3, 3))],
      ),
    };
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 5,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const Spacer(),
          Container(width: 48, height: 3, color: c.ink.withValues(alpha: .45)),
          const SizedBox(height: 3),
          Container(width: 34, height: 3, color: c.muted.withValues(alpha: .5)),
        ],
      ),
    );
  }
}

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.value, required this.onChanged});

  final AppPalette value;
  final ValueChanged<AppPalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <AppPalette, (String, SfPalette)>{
      AppPalette.daryo: ('Daryo', SfPalette.daryo),
      AppPalette.saroy: ('Saroy', SfPalette.saroy),
      AppPalette.marvarid: ('Marvarid', SfPalette.marvarid),
      AppPalette.samarqand: ('Samarqand', SfPalette.samarqand),
    };
    return Row(
      children: [
        for (final entry in entries.entries)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SfPressable(
                onPressed: () => onChanged(entry.key),
                selected: value == entry.key,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: SfMotion.resolve(
                        context,
                        const Duration(milliseconds: 220),
                      ),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            sfColorsFor(entry.value.$2).primary,
                            sfColorsFor(entry.value.$2).accent,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: value == entry.key
                              ? SfTheme.colorsOf(context).ink
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: value == entry.key
                            ? SfShadows.md
                            : SfShadows.sm,
                      ),
                      child: value == entry.key
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 19,
                            )
                          : null,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.value.$1,
                      style: SfType.ui(size: 9.5, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FontPicker extends StatelessWidget {
  const _FontPicker({required this.value, required this.onChanged});

  final AppFontChoice value;
  final ValueChanged<AppFontChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <AppFontChoice, String>{
      AppFontChoice.manrope: 'Manrope',
      AppFontChoice.system: 'System',
      AppFontChoice.editorial: 'Editorial',
      AppFontChoice.mono: 'Mono',
    };
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final choice in AppFontChoice.values)
          ChoiceChip(
            selected: value == choice,
            label: Text(
              labels[choice]!,
              style: TextStyle(
                fontFamily: switch (choice) {
                  AppFontChoice.manrope => 'Manrope',
                  AppFontChoice.system => null,
                  AppFontChoice.editorial => 'Instrument Serif',
                  AppFontChoice.mono => 'JetBrains Mono',
                },
              ),
            ),
            onSelected: (_) => onChanged(choice),
          ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Semantics(
      toggled: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: value ? c.primarySoft : c.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: value ? c.primary : c.muted),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SfType.ui(
                        size: 13,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: SfType.ui(
                        size: 10.5,
                        color: c.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.min = .45,
    this.max = 1,
    this.percent = true,
    this.valueLabel,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final double min;
  final double max;
  final bool percent;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: SfType.ui(size: 12, weight: FontWeight.w700),
                ),
              ),
              Text(
                valueLabel ??
                    (percent
                        ? '${(value * 100).round()}%'
                        : value.toStringAsFixed(2)),
                style: SfType.mono(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}

class _TransparencyPreview extends StatelessWidget {
  const _TransparencyPreview({
    required this.surfaceOpacity,
    required this.navigationOpacity,
  });

  final double surfaceOpacity;
  final double navigationOpacity;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      height: 84,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primarySoft, c.accentSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: SfGlassSurface(
              enabled: true,
              platformAdaptive: false,
              blurSigma: 8,
              tintColor: c.surface.withValues(alpha: surfaceOpacity),
              borderRadius: BorderRadius.circular(11),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Text(
                'Surface',
                style: SfType.ui(size: 10, weight: FontWeight.w800),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 150,
              height: 30,
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: navigationOpacity),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: .62)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.home_rounded, color: c.primary, size: 15),
                  Icon(Icons.task_alt_rounded, color: c.muted, size: 15),
                  Icon(Icons.chat_bubble_rounded, color: c.muted, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfPressable(
      onPressed: onTap,
      selected: selected,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: SfMotion.resolve(context, const Duration(milliseconds: 240)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              code,
              style: SfType.mono(
                size: 17,
                weight: FontWeight.w800,
                color: selected ? c.primary : c.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(
                size: 9.5,
                weight: FontWeight.w700,
                color: c.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c.primary, size: 19),
      ),
      title: Text(title, style: SfType.ui(size: 13, weight: FontWeight.w700)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
      onTap: onTap,
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

String _roleLabel(BuildContext context, StaffRole role) =>
    switch (Localizations.localeOf(context).languageCode) {
      'ru' => switch (role) {
        StaffRole.teacher => 'Учитель',
        StaffRole.assistant => 'Ассистент',
        StaffRole.methodist => 'Методист',
        StaffRole.reception => 'Сотрудник приёмной',
        StaffRole.auditor => 'Аудитор',
      },
      'en' => role.label,
      _ => role.uzLabel,
    };
