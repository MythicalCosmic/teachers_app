import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../theme/sf_theme.dart';
import '../../widgets/sf_avatar.dart';
import '../../widgets/sf_button.dart';
import '../../widgets/sf_card.dart';
import '../../widgets/sf_icons.dart';
import '../../widgets/sf_pill.dart';
import '../../widgets/sf_star.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    if (session == null) return const SizedBox.shrink();
    final c = SfTheme.colorsOf(context);
    final profile = _profileFor(session.role);
    final firstName = session.displayName.split(' ').first;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 1.2,
                  colors: [c.accentSoft, Colors.transparent],
                  stops: const [0, 0.58],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 124,
                              height: 124,
                              decoration: BoxDecoration(
                                color: c.accentSoft,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SfAvatar(
                              name: session.displayName,
                              size: 92,
                              color: c.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Xush kelibsiz,',
                          style: SfType.display(size: 22, color: c.ink2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firstName,
                          style: SfType.ui(
                            size: 27,
                            weight: FontWeight.w800,
                            color: c.ink,
                            letterSpacing: -0.65,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${session.role.uzLabel} · ${session.branchName}',
                          style: SfType.ui(size: 12, color: c.muted),
                        ),
                        const SizedBox(height: 22),
                        SfSurfaceCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                alignment: Alignment.center,
                                child: const SfStar(
                                  size: 23,
                                  color: Color(0xFFFFFCF5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.branchName,
                                      style: SfType.ui(
                                        size: 13,
                                        weight: FontWeight.w800,
                                        color: c.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      profile.description,
                                      style: SfType.ui(
                                        size: 11,
                                        color: c.muted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(SfIcons.shield, size: 22, color: c.success),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (
                              var index = 0;
                              index < profile.tags.length;
                              index++
                            )
                              SfPill(
                                tone: index.isEven
                                    ? SfPillTone.primary
                                    : SfPillTone.accent,
                                label: profile.tags[index],
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            for (final stat in profile.stats)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 74,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          stat.$1,
                                          style: SfType.mono(
                                            size: 21,
                                            weight: FontWeight.w700,
                                            color: c.primary,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          stat.$2.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: SfType.eyebrow(
                                            color: c.muted,
                                            size: 9.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(height: 28),
                        SfButton(
                          kind: SfButtonKind.primary,
                          block: true,
                          height: 54,
                          label: 'Ish maydonini ochish',
                          trailing: SfIcons.arrowR,
                          fontSize: 16,
                          onPressed: () async {
                            await app.completeWelcome();
                            if (context.mounted) context.go('/home');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeProfile {
  const _WelcomeProfile(this.description, this.tags, this.stats);

  final String description;
  final List<String> tags;
  final List<(String, String)> stats;
}

_WelcomeProfile _profileFor(StaffRole role) => switch (role) {
  StaffRole.teacher => const _WelcomeProfile(
    'Sizga biriktirilgan guruh, dars va o‘quvchi oqimlari tayyor.',
    ['Algebra', 'Geometriya'],
    [('3', 'Guruh'), ('58', 'O‘quvchi'), ('12', 'Dars / hafta')],
  ),
  StaffRole.assistant => const _WelcomeProfile(
    'Dars yordami, davomat qoralamalari va kundalik vazifalar bir joyda.',
    ['Dars yordami', 'Davomat'],
    [('2', 'Guruh'), ('41', 'O‘quvchi'), ('9', 'Dars / hafta')],
  ),
  StaffRole.methodist => const _WelcomeProfile(
    'Ta’lim sifati, ustoz signallari va metodik vazifalar tayyor.',
    ['Sifat', 'Metodika'],
    [('16', 'Ustoz'), ('28', 'Guruh'), ('3', 'Signal')],
  ),
  StaffRole.reception => const _WelcomeProfile(
    'Lidlar, sinov darslari va qabul jarayoni navbatga qo‘yilgan.',
    ['Lidlar', 'Qabul'],
    [('34', 'Lid'), ('6', 'Aloqa'), ('4', 'Test')],
  ),
  StaffRole.auditor => const _WelcomeProfile(
    'O‘zgarmas manbalar, anomaliyalar va audit holatlari tayyor.',
    ['Nazorat', 'Holatlar'],
    [('12', 'Signal'), ('8', 'Holat'), ('4', 'Filial')],
  ),
};
