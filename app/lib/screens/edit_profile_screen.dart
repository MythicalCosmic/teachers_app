import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../l10n/sf_l10n.dart';
import '../theme/sf_theme.dart';
import '../widgets/sf_app_bar.dart';
import '../widgets/sf_avatar.dart';
import '../widgets/sf_button.dart';
import '../widgets/sf_card.dart';
import '../widgets/sf_form_controls.dart';
import '../widgets/sf_hint_card.dart';
import '../widgets/sf_icons.dart';
import '../widgets/sf_pressable.dart';
import '../widgets/sf_scaffold.dart';
import '../widgets/sf_state_view.dart';
import '../widgets/sf_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  int _avatarColorValue = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = AppScope.of(context);
    final session = app.session;
    if (session != null) {
      _name.text = session.displayName;
      _email.text = session.email;
      _username.text = session.username.isEmpty
          ? session.email.split('@').first
          : session.username;
      _phone.text = session.phone;
      _bio.text = app.isProduction
          ? session.bio
          : session.bio.isEmpty
          ? _copy(
              context,
              uz: 'O‘quvchilarning o‘sishi uchun aniq, iliq va ishonchli ta’lim muhitini yarataman.',
              ru: 'Создаю ясную, тёплую и надёжную среду для роста учеников.',
              en: 'Creating a clear, warm and dependable space where students can grow.',
            )
          : session.bio;
      _avatarColorValue = session.avatarColorValue;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _username.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = AppScope.of(context);
    setState(() => _saving = true);
    try {
      await app.updateProfile(
        displayName: _name.text,
        email: _email.text,
        username: _username.text,
        phone: _phone.text,
        bio: _bio.text,
        avatarColorValue: _avatarColorValue,
      );
      if (!mounted) return;
      SfToast.show(
        context,
        title: _copy(
          context,
          uz: 'Profil saqlandi',
          ru: 'Профиль сохранён',
          en: 'Profile saved',
        ),
        message: app.isProduction
            ? _copy(
                context,
                uz: 'Ism, email va telefon serverda saqlandi.',
                ru: 'Имя, почта и телефон сохранены на сервере.',
                en: 'Name, email, and phone were saved on the server.',
              )
            : _copy(
                context,
                uz: 'Kontaktlar, bio va uslub qurilmaga saqlandi.',
                ru: 'Контакты, описание и стиль сохранены.',
                en: 'Your contacts, bio and profile style are saved.',
              ),
        tone: SfToastTone.success,
        glassEnabled: SfTheme.of(context).usesGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
      context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      SfToast.show(
        context,
        message: error.toString(),
        tone: SfToastTone.error,
        glassEnabled: SfTheme.of(context).usesGlass,
        motionEnabled: !app.settings.reducedMotion,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final session = app.session;
    final c = SfTheme.colorsOf(context);
    if (session == null) {
      return SfScaffold(
        body: SfErrorState(
          title: _copy(
            context,
            uz: 'Sessiya topilmadi',
            ru: 'Сессия не найдена',
            en: 'Session not found',
          ),
        ),
      );
    }

    final completed = app.tasks
        .where((task) => task.status == TaskStatus.done)
        .length;
    final submittedAttendance = app.attendanceSheets
        .where((sheet) => sheet.isSubmitted)
        .length;
    final avatarColor = _avatarColorValue == 0
        ? c.primary
        : Color(_avatarColorValue);

    return SfScaffold(
      dismissKeyboardOnTap: true,
      top: SfNavBar(
        title: context.tr('profile'),
        leading: IconButton(
          tooltip: context.tr('cancel'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(context.tr('save')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
          children: [
            SfSurfaceCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: SfMotion.resolve(
                          context,
                          const Duration(milliseconds: 280),
                        ),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: SfAvatar(
                          key: ValueKey('${_name.text}$_avatarColorValue'),
                          name: _name.text,
                          size: 96,
                          color: avatarColor,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Icon(SfIcons.edit, size: 16, color: c.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    _name.text.isEmpty ? session.displayName : _name.text,
                    textAlign: TextAlign.center,
                    style: SfType.ui(
                      size: 21,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_roleLabel(context, session.role)} · ${session.branchName}',
                    textAlign: TextAlign.center,
                    style: SfType.ui(size: 12, color: c.muted),
                  ),
                  const SizedBox(height: 15),
                  if (!app.isProduction) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 9,
                      children: [
                        for (final color in [
                          c.primary,
                          const Color(0xFF346D91),
                          const Color(0xFF8D4F7B),
                          const Color(0xFFB55F35),
                          const Color(0xFF4B7D64),
                        ])
                          SfPressable(
                            onPressed: () => setState(
                              () => _avatarColorValue = color.toARGB32(),
                            ),
                            selected:
                                avatarColor.toARGB32() == color.toARGB32(),
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedContainer(
                              duration: SfMotion.resolve(
                                context,
                                const Duration(milliseconds: 200),
                              ),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      avatarColor.toARGB32() == color.toARGB32()
                                      ? c.ink
                                      : c.surface,
                                  width: 2.5,
                                ),
                              ),
                              child: avatarColor.toARGB32() == color.toARGB32()
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 17),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMetric(
                          value: '$completed',
                          label: _copy(
                            context,
                            uz: 'vazifa',
                            ru: 'задач',
                            en: 'tasks',
                          ),
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                      Expanded(
                        child: _ProfileMetric(
                          value: '$submittedAttendance',
                          label: _copy(
                            context,
                            uz: 'davomat',
                            ru: 'посещ.',
                            en: 'attendance',
                          ),
                          icon: Icons.fact_check_outlined,
                        ),
                      ),
                      Expanded(
                        child: _ProfileMetric(
                          value: '${app.cards.length}',
                          label: _copy(
                            context,
                            uz: 'e’tirof',
                            ru: 'наград',
                            en: 'recognitions',
                          ),
                          icon: Icons.workspace_premium_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _copy(
                context,
                uz: 'SHAXSIY MA’LUMOTLAR',
                ru: 'ЛИЧНЫЕ ДАННЫЕ',
                en: 'PERSONAL DETAILS',
              ),
              style: SfType.eyebrow(color: c.muted),
            ),
            const SizedBox(height: 8),
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  SfTextField(
                    controller: _name,
                    label: _copy(
                      context,
                      uz: 'Ism va familiya',
                      ru: 'Имя и фамилия',
                      en: 'Full name',
                    ),
                    hint: _copy(
                      context,
                      uz: 'To‘liq ismingiz',
                      ru: 'Ваше полное имя',
                      en: 'Your full name',
                    ),
                    prefixIcon: SfIcons.user,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    onChanged: (_) => setState(() {}),
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? _copy(
                            context,
                            uz: 'Kamida 3 ta belgi kiriting',
                            ru: 'Введите не менее 3 символов',
                            en: 'Enter at least 3 characters',
                          )
                        : null,
                  ),
                  const SizedBox(height: 13),
                  SfTextField(
                    controller: _username,
                    enabled: !app.isProduction,
                    label: _copy(
                      context,
                      uz: 'Foydalanuvchi nomi',
                      ru: 'Имя пользователя',
                      en: 'Username',
                    ),
                    hint: 'nigora.karimova',
                    prefixIcon: Icons.alternate_email_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? _copy(
                            context,
                            uz: 'Nom juda qisqa',
                            ru: 'Имя слишком короткое',
                            en: 'Username is too short',
                          )
                        : null,
                  ),
                  const SizedBox(height: 13),
                  SfTextField(
                    controller: _email,
                    label: _copy(
                      context,
                      uz: 'Pochta',
                      ru: 'Эл. почта',
                      en: 'Email',
                    ),
                    hint: 'name@example.uz',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (!text.contains('@') || !text.contains('.')) {
                        return _copy(
                          context,
                          uz: 'To‘g‘ri pochta manzilini kiriting',
                          ru: 'Введите корректный адрес',
                          en: 'Enter a valid email address',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  SfTextField(
                    controller: _phone,
                    label: _copy(
                      context,
                      uz: 'Telefon',
                      ru: 'Телефон',
                      en: 'Phone',
                    ),
                    hint: '+998 90 123 45 67',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),
                  const SizedBox(height: 13),
                  SfTextField(
                    controller: _bio,
                    enabled: !app.isProduction,
                    label: _copy(
                      context,
                      uz: 'Men haqimda',
                      ru: 'О себе',
                      en: 'About me',
                    ),
                    hint: _copy(
                      context,
                      uz: 'Hamkasblar uchun qisqa bio',
                      ru: 'Краткое описание для коллег',
                      en: 'A short bio for colleagues',
                    ),
                    prefixIcon: Icons.notes_rounded,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 260,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SfHintCard(
              compact: true,
              title: _copy(
                context,
                uz: 'Xavfsiz rol',
                ru: 'Защищённая роль',
                en: 'Protected role',
              ),
              message: _copy(
                context,
                uz: app.isProduction
                    ? 'Login, bio, profil uslubi, ${session.role.uzLabel} roli va ${session.branchName} filiali vakolatli administrator tomonidan boshqariladi.'
                    : '${session.role.uzLabel} roli va ${session.branchName} filiali faqat vakolatli administrator tomonidan o‘zgartiriladi.',
                ru: app.isProduction
                    ? 'Логин, описание, стиль профиля, роль ${session.role.label} и филиал ${session.branchName} меняет уполномоченный администратор.'
                    : 'Роль ${session.role.label} и филиал ${session.branchName} меняет только уполномоченный администратор.',
                en: app.isProduction
                    ? 'Your username, bio, profile style, ${session.role.label} role, and ${session.branchName} branch are managed by an authorized administrator.'
                    : 'Your ${session.role.label} role and ${session.branchName} branch can only be changed by an authorized administrator.',
              ),
            ),
            const SizedBox(height: 20),
            SfSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [c.accent, c.primary]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _copy(
                            context,
                            uz: 'Ishonchli mentor',
                            ru: 'Надёжный наставник',
                            en: 'Trusted mentor',
                          ),
                          style: SfType.ui(
                            size: 13.5,
                            weight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _copy(
                            context,
                            uz: 'Profil yutug‘i · faoliyat va davomat intizomi uchun',
                            ru: 'Достижение за активность и дисциплину',
                            en: 'Profile achievement for activity and attendance discipline',
                          ),
                          style: SfType.ui(
                            size: 10.5,
                            color: c.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SfButton(
              block: true,
              height: 52,
              label: _saving
                  ? _copy(
                      context,
                      uz: 'Saqlanmoqda…',
                      ru: 'Сохранение…',
                      en: 'Saving…',
                    )
                  : _copy(
                      context,
                      uz: 'Profilni saqlash',
                      ru: 'Сохранить профиль',
                      en: 'Save profile',
                    ),
              leading: SfIcons.check,
              haptic: app.settings.haptics,
              motionEnabled: !app.settings.reducedMotion,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SfTheme.colorsOf(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: c.surface2.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: c.primary),
          const SizedBox(height: 3),
          Text(
            value,
            style: SfType.mono(size: 15, weight: FontWeight.w800, color: c.ink),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SfType.ui(size: 8.5, color: c.muted),
          ),
        ],
      ),
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
