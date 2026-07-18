import 'package:flutter/widgets.dart';

/// Lightweight, dependency-free copy catalogue for the staff experience.
///
/// Domain data remains in its original language, while navigation, settings
/// and core actions immediately follow the persisted app language.
abstract final class SfL10n {
  static const _copy = <String, Map<String, String>>{
    'uz': {
      'today': 'Bugun',
      'groups': 'Guruhlar',
      'tasks': 'Vazifalar',
      'messages': 'Xabarlar',
      'more': 'Boshqa',
      'quality': 'Sifat',
      'leads': 'Lidlar',
      'reception': 'Qabul',
      'audit': 'Audit',
      'signals': 'Signallar',
      'cases': 'Holatlar',
      'alerts': 'Ogohlant.',
      'settings': 'Sozlamalar',
      'appearance': 'Ko‘rinish',
      'language': 'Til',
      'profile': 'Profil',
      'edit_profile': 'Profilni tahrirlash',
      'save': 'Saqlash',
      'cancel': 'Bekor qilish',
      'done': 'Tayyor',
      'search': 'Qidirish',
      'new_task': 'Yangi vazifa',
      'design_studio': 'Dizayn studiyasi',
      'accessibility': 'Qulaylik va harakat',
      'system': 'Tizim',
      'light': 'Yorug‘',
      'dark': 'Tungi',
    },
    'ru': {
      'today': 'Сегодня',
      'groups': 'Группы',
      'tasks': 'Задачи',
      'messages': 'Сообщения',
      'more': 'Ещё',
      'quality': 'Качество',
      'leads': 'Лиды',
      'reception': 'Приём',
      'audit': 'Аудит',
      'signals': 'Сигналы',
      'cases': 'Кейсы',
      'alerts': 'Оповещ.',
      'settings': 'Настройки',
      'appearance': 'Оформление',
      'language': 'Язык',
      'profile': 'Профиль',
      'edit_profile': 'Изменить профиль',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'done': 'Готово',
      'search': 'Поиск',
      'new_task': 'Новая задача',
      'design_studio': 'Студия дизайна',
      'accessibility': 'Комфорт и движение',
      'system': 'Система',
      'light': 'Светлая',
      'dark': 'Тёмная',
    },
    'en': {
      'today': 'Today',
      'groups': 'Groups',
      'tasks': 'Tasks',
      'messages': 'Messages',
      'more': 'More',
      'quality': 'Quality',
      'leads': 'Leads',
      'reception': 'Reception',
      'audit': 'Audit',
      'signals': 'Signals',
      'cases': 'Cases',
      'alerts': 'Alerts',
      'settings': 'Settings',
      'appearance': 'Appearance',
      'language': 'Language',
      'profile': 'Profile',
      'edit_profile': 'Edit profile',
      'save': 'Save',
      'cancel': 'Cancel',
      'done': 'Done',
      'search': 'Search',
      'new_task': 'New task',
      'design_studio': 'Design studio',
      'accessibility': 'Comfort and motion',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
    },
  };

  static String text(BuildContext context, String key) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'uz';
    return _copy[code]?[key] ?? _copy['uz']?[key] ?? key;
  }
}

extension SfLocalizedContext on BuildContext {
  String tr(String key) => SfL10n.text(this, key);
}
