import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pill.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';
import '../widgets/sf_wordmark.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final settings = app.settings;
    final c = SfTheme.colorsOf(context);
    if (session == null) {
      return const SfScaffold(
        body: SfErrorState(
          title: 'Sessiya topilmadi',
          message: 'Profil sozlamalarini ochish uchun qayta kiring.',
        ),
      );
    }

    void confirm(String message) => SfToast.show(
      context,
      message: message,
      tone: SfToastTone.success,
      motionEnabled: !settings.reducedMotion,
      glassEnabled: settings.liquidGlass,
    );

    return SfScaffold(
      top: SfLargeAppBar(
        title: 'Profil',
        leading: IconButton(
          tooltip: 'Ortga',
          onPressed: Navigator.of(context).canPop()
              ? () => Navigator.of(context).maybePop()
              : null,
          icon: const Icon(SfIcons.arrowL),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          _ProfileCard(session: session),
          const SizedBox(height: 16),
          SfHintCard(
            tone: SfHintTone.info,
            title: '${session.role.uzLabel} rejimi',
            message:
                'Bu yerda faqat sizning rolingiz uchun ruxsat etilgan sozlamalar ko‘rsatiladi.',
            compact: true,
          ),
          _SectionTitle('Hisob'),
          SfSurfaceCard(
            child: Column(
              children: [
                _NavigationRow(
                  icon: SfIcons.user,
                  title: 'Shaxsiy ma’lumotlar',
                  value: session.displayName,
                  onTap: () => context.push('/settings/edit'),
                ),
                _ValueRow(
                  icon: SfIcons.shield,
                  title: 'Rol',
                  value: session.role.uzLabel,
                ),
                _ValueRow(
                  icon: SfIcons.globe,
                  title: 'Filial',
                  value: session.branchName,
                  last: true,
                ),
              ],
            ),
          ),
          _SectionTitle('Ko‘rinish'),
          SfSurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REJIM', style: SfType.eyebrow(color: c.muted)),
                const SizedBox(height: 8),
                SfSegmentedControl<AppThemeMode>(
                  expanded: true,
                  value: settings.themeMode,
                  onChanged: (value) {
                    app.setThemeMode(value);
                    confirm('Ko‘rinish rejimi saqlandi');
                  },
                  segments: const [
                    SfSegment(value: AppThemeMode.system, label: 'Tizim'),
                    SfSegment(value: AppThemeMode.light, label: 'Yorug‘'),
                    SfSegment(value: AppThemeMode.dark, label: 'Tungi'),
                  ],
                ),
                const SizedBox(height: 14),
                Text('RANG', style: SfType.eyebrow(color: c.muted)),
                const SizedBox(height: 8),
                SfSegmentedControl<AppPalette>(
                  expanded: true,
                  value: settings.palette,
                  onChanged: (value) {
                    app.setPalette(value);
                    confirm('Rang palitrasi saqlandi');
                  },
                  segments: const [
                    SfSegment(value: AppPalette.daryo, label: 'Daryo'),
                    SfSegment(value: AppPalette.saroy, label: 'Saroy'),
                    SfSegment(value: AppPalette.marvarid, label: 'Marvarid'),
                    SfSegment(value: AppPalette.samarqand, label: 'Samarqand'),
                  ],
                ),
              ],
            ),
          ),
          _SectionTitle('Qulaylik va harakat'),
          SfSurfaceCard(
            child: Column(
              children: [
                SfSwitchTile(
                  title: 'Liquid Glass',
                  subtitle:
                      'Qo‘llab-quvvatlanadigan iPhone qurilmalarida shaffof sirtlar',
                  leading: Icons.blur_on_rounded,
                  value: settings.liquidGlass,
                  onChanged: (value) {
                    app.setLiquidGlass(value);
                    confirm(
                      value
                          ? 'Liquid Glass yoqildi'
                          : 'Liquid Glass o‘chirildi',
                    );
                  },
                ),
                SfSwitchTile(
                  title: 'Kamaytirilgan harakat',
                  subtitle: 'O‘tishlar va bezak animatsiyalarini kamaytiradi',
                  leading: Icons.motion_photos_off_outlined,
                  value: settings.reducedMotion,
                  onChanged: (value) {
                    app.setReducedMotion(value);
                    confirm(
                      value
                          ? 'Harakat kamaytirildi'
                          : 'To‘liq animatsiya yoqildi',
                    );
                  },
                ),
                SfSwitchTile(
                  title: 'Haptik javob',
                  subtitle: 'Muhim bosishlarda yengil tebranish',
                  leading: Icons.vibration_rounded,
                  value: settings.haptics,
                  onChanged: (value) {
                    app.setHaptics(value);
                    confirm(
                      value
                          ? 'Haptik javob yoqildi'
                          : 'Haptik javob o‘chirildi',
                    );
                  },
                ),
                SfSwitchTile(
                  title: 'Kontekst yordamlar',
                  subtitle: 'Yangi yoki murakkab joylarda qisqa ko‘rsatmalar',
                  leading: Icons.tips_and_updates_outlined,
                  value: settings.coachMarks,
                  showDivider: false,
                  onChanged: (value) {
                    app.setCoachMarks(value);
                    confirm(
                      value ? 'Yordamlar yoqildi' : 'Yordamlar o‘chirildi',
                    );
                  },
                ),
              ],
            ),
          ),
          _SectionTitle('Til'),
          SfSurfaceCard(
            padding: const EdgeInsets.all(12),
            child: SfSegmentedControl<AppLocale>(
              expanded: true,
              value: settings.locale,
              onChanged: (value) {
                app.updateSettings(settings.copyWith(locale: value));
                confirm('Til tanlovi saqlandi');
              },
              segments: const [
                SfSegment(value: AppLocale.uz, label: 'O‘zbekcha'),
                SfSegment(value: AppLocale.ru, label: 'Русский'),
              ],
            ),
          ),
          if (session.can(StaffCapability.managePrintQueue) ||
              session.can(StaffCapability.viewAuditWorkspace)) ...[
            _SectionTitle('Ruxsat berilgan vositalar'),
            SfSurfaceCard(
              child: Column(
                children: [
                  if (session.can(StaffCapability.managePrintQueue))
                    _NavigationRow(
                      icon: SfIcons.printer,
                      title: 'Print navbatini boshqarish',
                      onTap: () => context.push('/print'),
                    ),
                  if (session.can(StaffCapability.viewAuditWorkspace))
                    const _ValueRow(
                      icon: Icons.fact_check_outlined,
                      title: 'Audit ish maydoni',
                      value: 'Ruxsat berilgan',
                      last: true,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          SfButton(
            kind: SfButtonKind.ghost,
            block: true,
            height: 50,
            label: 'Chiqish',
            leading: SfIcons.logout,
            overrideFg: c.danger,
            haptic: settings.haptics,
            motionEnabled: !settings.reducedMotion,
            onPressed: () async {
              await app.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 14),
          const Center(child: SfWordmark(size: 12)),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'v1.0.0 · staff',
              style: SfType.mono(size: 10, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return SfSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SfAvatar(name: session.displayName, size: 64, color: c.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: SfType.ui(
                    size: 18,
                    weight: FontWeight.w800,
                    color: c.ink,
                    letterSpacing: -0.36,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.role.uzLabel} · ${session.branchName}',
                  style: SfType.ui(size: 12, color: c.muted),
                ),
                const SizedBox(height: 8),
                SfPill(tone: SfPillTone.primary, label: session.role.uzLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      label.toUpperCase(),
      style: SfType.eyebrow(color: SfTheme.colorsOf(context).muted),
    ),
  );
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c.ink2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: SfType.ui(size: 13.5, color: c.ink)),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  overflow: TextOverflow.ellipsis,
                  style: SfType.ui(size: 12, color: c.muted),
                ),
              ),
            const SizedBox(width: 6),
            Icon(SfIcons.chevR, size: 17, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: c.ink2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: SfType.ui(size: 13.5, color: c.ink)),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: SfType.ui(size: 12, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}
