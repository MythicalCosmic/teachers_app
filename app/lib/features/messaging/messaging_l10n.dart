import 'package:flutter/widgets.dart';

import 'messaging_models.dart';

/// Messaging-only copy catalogue. It intentionally reads Flutter's active
/// locale so the persisted [AppLocale] selected by the app is reflected on
/// every messaging route without coupling the feature repository to UI copy.
final class MessagingL10n {
  MessagingL10n._(this.languageCode);

  final String languageCode;

  static MessagingL10n of(BuildContext context) => MessagingL10n._(
    Localizations.maybeLocaleOf(context)?.languageCode ?? 'uz',
  );

  String text(String key, [Map<String, Object> values = const {}]) {
    var value = _copy[languageCode]?[key] ?? _copy['uz']?[key] ?? key;
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }

  String preview(MessagingMessage? message) {
    if (message == null) return text('start_chat');
    return switch (message.kind) {
      MessagingKind.text => message.body,
      MessagingKind.image => '📷 ${message.mediaLabel ?? text('image')}',
      MessagingKind.video => '🎬 ${message.mediaLabel ?? text('video')}',
      MessagingKind.voice => '🎙 ${text('voice_message')}',
    };
  }

  String folderName(MessagingFolder folder) => switch (folder.id) {
    'folder-work' => text('folder_work'),
    'folder-important' => text('folder_important'),
    _ => folder.name,
  };

  String relativeTime(DateTime value, {DateTime? now}) {
    final local = value.toLocal();
    final delta = (now ?? DateTime.now()).difference(local);
    if (delta.isNegative) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    if (delta.inMinutes < 1) return text('time_now');
    if (delta.inMinutes < 60) {
      return text('minutes_ago', {'count': delta.inMinutes});
    }
    if (delta.inHours < 24) return text('hours_ago', {'count': delta.inHours});
    if (delta.inDays < 7) return text('days_ago', {'count': delta.inDays});
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}';
  }

  String error(Object error) {
    final raw = error is ArgumentError ? '${error.message}' : '$error';
    if (raw.contains('Video 1 daqiqadan')) return text('video_too_long');
    if (raw.contains('Ovozli xabar juda qisqa')) return text('voice_too_short');
    if (raw.contains('Ovozli xabar 0.5')) return text('voice_duration_invalid');
    if (raw.contains('Jild nomini')) return text('folder_name_required');
    if (raw.contains('jild allaqachon')) return text('folder_exists');
    if (raw.contains('Xodim topilmadi')) return text('staff_not_found');
    if (raw.contains('Xabar matni')) return text('message_required');
    return raw;
  }
}

const _copy = <String, Map<String, String>>{
  'uz': {
    'back': 'Ortga',
    'cancel': 'Bekor',
    'close': 'Yopish',
    'clear': 'Tozalash',
    'send': 'Yuborish',
    'create': 'Yaratish',
    'delete': 'O‘chirish',
    'undo': 'Qaytarish',
    'more_actions': 'Boshqa amallar',
    'permission_denied': 'Xabarlarga ruxsat yo‘q',
    'permission_message': 'Bu bo‘lim xodimlararo yozishma uchun.',
    'send_permission_denied': 'Xabar yuborishga ruxsat yo‘q',
    'messages': 'Xabarlar',
    'all_read': 'Hammasi o‘qilgan',
    'unread_chats': '{count} ta o‘qilmagan suhbat',
    'new_message': 'Yangi xabar',
    'no_results': 'Natija topilmadi',
    'archive_empty': 'Arxiv bo‘sh',
    'no_chats': 'Suhbat yo‘q',
    'try_another_search': 'Boshqa so‘z yoki ism bilan qidiring.',
    'start_with_new_message':
        'Yangi xabar orqali hamkasbingiz bilan suhbatni boshlang.',
    'empty_message_count': '0 ta suhbat',
    'empty_archive_message':
        'Arxivlangan suhbatlar shu yerda ko‘rinadi. Hozircha hech narsa yashirilmagan.',
    'empty_folder_message': 'Bu jildda hali suhbat yo‘q.',
    'empty_motivation_label': 'Kichik eslatma',
    'empty_motivation_1':
        'Yaxshi hamkorlik ko‘pincha bitta samimiy xabardan boshlanadi.',
    'empty_motivation_2': 'Aniq va mehrli muloqot kuchli jamoani quradi.',
    'empty_motivation_3':
        'Bir daqiqalik suhbat butun kunlik ishni yengillashtirishi mumkin.',
    'empty_motivation_4':
        'Savol berish ham, yordam taklif qilish ham jamoaviy kuchdir.',
    'empty_motivation_5':
        'Bugungi kichik aloqa ertangi katta natijaga aylanishi mumkin.',
    'empty_quick_actions': 'Tezkor boshlash',
    'empty_compose_help': 'Ism yoki username orqali hamkasbingizni toping.',
    'empty_folder_help': 'Kelajakdagi suhbatlar uchun tartibli joy yarating.',
    'empty_back_to_all': 'Barcha suhbatlar',
    'empty_back_to_all_help': 'Asosiy xabarlar ro‘yxatiga qayting.',
    'empty_refresh': 'Yangilash',
    'empty_refresh_help': 'Serverdan eng yangi suhbatlarni tekshiring.',
    'clear_search': 'Qidiruvni tozalash',
    'close_search': 'Qidiruvni yopish',
    'new_folder': 'Yangi jild',
    'folder_name': 'Jild nomi',
    'folder_example': 'Masalan: 9-B guruhi',
    'toggle_pin': 'Qadash / olib tashlash',
    'toggle_mute': 'Ovozni o‘chirish / yoqish',
    'add_to_folder': 'Jildga qo‘shish',
    'delete_chats': 'Suhbatlarni o‘chirish',
    'choose_folder': 'Jildni tanlang',
    'folder_selection_help': 'Tanlangan suhbatlar shu jildga qo‘shiladi.',
    'delete_chats_question': 'Suhbatlar o‘chirilsinmi?',
    'delete_chats_description': '{count} ta suhbat ro‘yxatdan olib tashlanadi.',
    'chats_deleted': '{count} ta suhbat o‘chirildi',
    'selected_count': '{count} ta tanlandi',
    'close_selection': 'Tanlashni yopish',
    'archive': 'Arxiv',
    'archive_action': 'Arxivlash',
    'mark_read': 'O‘qilgan qilish',
    'search_chats': 'Ism, username yoki xabarni qidiring',
    'all': 'Barchasi',
    'folder_work': 'Ish',
    'folder_important': 'Muhim',
    'device_local_organization':
        'Jild, pin, mute va arxiv faqat shu qurilmada saqlanadi.',
    'start_chat': 'Suhbatni boshlang',
    'chat': 'Suhbat',
    'chat_not_found': 'Suhbat topilmadi',
    'send_first_message': 'Matn, rasm, qisqa video yoki ovozli xabar yuboring.',
    'message_not_found': 'Xabar topilmadi',
    'change_search': 'Qidiruv so‘zini o‘zgartirib ko‘ring.',
    'online_now': 'hozir onlayn',
    'notifications_muted': 'bildirishnomalar o‘chiq',
    'staff_coordination': 'xodimlar koordinatsiyasi',
    'staff_chat': 'xodimlar suhbati',
    'attach': 'Biriktirish',
    'attachment_help':
        'Bu qurilmadagi fayl emas: suhbat oqimini sinash uchun demo media. Videolar 1 daqiqagacha.',
    'demo_media_badge': 'DEMO MEDIA',
    'demo_media_sent':
        'Demo biriktirma suhbatda saqlandi. Bu build kamera yoki galereyani o‘qimaydi.',
    'voice_demo_notice':
        'Ovozli xabar prototipi davomiylikni saqlaydi; bu build mikrofon audiosini yozmaydi.',
    'board_photo': 'Dars doskasi rasmi',
    'board_photo_file': 'Dars doskasi.jpg',
    'image_size': 'Rasm · 2.4 MB',
    'lesson_clip': 'Dars lavhasi',
    'lesson_clip_file': 'Dars lavhasi.mp4',
    'video_allowed': 'Video · 00:48 · ruxsat etilgan',
    'seminar_recording': 'Seminar yozuvi',
    'seminar_file': 'Seminar yozuvi.mp4',
    'video_over_limit': 'Video · 01:14 · limitdan uzun',
    'messages_copied': 'Xabarlar nusxalandi',
    'delete_messages_question': 'Xabarlar o‘chirilsinmi?',
    'delete_messages_description': '{count} ta xabar suhbatdan o‘chiriladi.',
    'delete_messages_device_description':
        '{count} ta xabar faqat ushbu qurilmadagi ko‘rinishdan yashiriladi. Serverdagi rasmiy yozuv saqlanadi.',
    'messages_deleted': '{count} ta xabar olib tashlandi',
    'search_in_chat': 'Suhbatda qidirish',
    'profile': 'Profil',
    'cancel_recording': 'Yozuvni bekor qilish',
    'emoji': 'Emoji',
    'write_message': 'Xabar yozing…',
    'attach_media': 'Media biriktirish',
    'record_voice': 'Ovozli xabar yozish',
    'voice_progress': 'Ovoz ijrosi {percent} foiz',
    'voice_message': 'Ovozli xabar',
    'image': 'Rasm',
    'video': 'Video',
    'listen': 'Eshitish',
    'stop': 'To‘xtatish',
    'reaction': 'Reaksiya {emoji}',
    'copy': 'Nusxalash',
    'search_staff': 'Xodimni qidiring',
    'search_contacts': 'Xodim yoki o\u2018quvchini qidiring',
    'contact_filter_all': 'Barchasi',
    'contact_filter_staff': 'Xodimlar',
    'contact_filter_students': 'O\u2018quvchilar',
    'existing_contact': 'Mavjud suhbat',
    'open_chat': 'Suhbatni ochish',
    'retry': 'Qayta urinish',
    'contact_directory_loading': 'Kontaktlar yuklanmoqda\u2026',
    'contact_directory_loading_help':
        'Faqat sizga ruxsat berilgan xodim va o\u2018quvchilar olinmoqda.',
    'contact_directory_error': 'Kontaktlarni yuklab bo\u2018lmadi',
    'no_permitted_contacts': 'Hozircha kontakt yo\u2018q',
    'no_permitted_contacts_help':
        'Sizga ruxsat berilgan kontaktlar paydo bo\u2018lganda shu yerda ko\u2018rinadi.',
    'contacts_not_found': 'Kontakt topilmadi',
    'contact_search_help': 'Boshqa ism, lavozim yoki username bilan qidiring.',
    'remove_recipient': 'Qabul qiluvchini olib tashlash',
    'staff_not_found': 'Xodim topilmadi',
    'staff_search_help': 'Ism, lavozim yoki username bilan qidiring.',
    'message_to': '{name}ga xabar…',
    'contact_profile': 'Xodim profili',
    'contact_not_found': 'Kontakt topilmadi',
    'message_action': 'Xabar',
    'call': 'Qo‘ng‘iroq',
    'search': 'Qidirish',
    'turn_on': 'Yoqish',
    'turn_off': 'O‘chirish',
    'contact_copied': 'Kontakt ma’lumotlari nusxalandi',
    'username': 'Username',
    'phone': 'Telefon',
    'role': 'Lavozim',
    'about': 'HAQIDA',
    'media_files': 'Media va fayllar',
    'attachments_count': '{count} ta biriktirma',
    'share_contact': 'Kontaktni ulashish',
    'copy_to_clipboard': 'Ma’lumotni tizim buferiga nusxalash',
    'microphone': 'Mikrofon',
    'sound': 'Ovoz',
    'end_call': 'Qo‘ng‘iroqni yakunlash',
    'call_preview_notice':
        'Xavfsiz qo‘ng‘iroq prototipi. U mobil operatorga ulanmaydi.',
    'microphone_on': 'Mikrofon yoqildi',
    'microphone_off': 'Mikrofon o‘chirildi',
    'speaker_on': 'Karnay yoqildi',
    'speaker_off': 'Karnay o‘chirildi',
    'restoring_messages': 'Saqlangan suhbatlar tiklanmoqda…',
    'video_too_long': 'Video 1 daqiqadan oshmasligi kerak.',
    'voice_too_short': 'Ovozli xabar juda qisqa.',
    'voice_duration_invalid':
        'Ovozli xabar 0.5 soniyadan 1 daqiqagacha bo‘lishi kerak.',
    'voice_capture_failed':
        'Ovoz yozilmadi. Mikrofon ruxsati va qurilma sozlamalarini tekshiring.',
    'voice_permission_denied':
        'Mikrofonga ruxsat berilmadi. Telefon sozlamalaridan StarForge Staff uchun mikrofonni yoqing.',
    'voice_unsupported':
        'Bu qurilma xavfsiz ovoz yozish formatini qo‘llamaydi.',
    'voice_send_failed':
        'Ovozli xabar yuborilmadi. Internetni tekshirib qayta urinib ko‘ring.',
    'voice_play_failed':
        'Ovozli xabar ochilmadi. Havolani yangilab qayta urinib ko‘ring.',
    'folder_name_required': 'Jild nomini kiriting.',
    'folder_exists': 'Bu nomdagi jild allaqachon mavjud.',
    'message_required': 'Xabar matni bo‘sh bo‘lmasin.',
    'time_now': 'hozir',
    'minutes_ago': '{count} daqiqa oldin',
    'hours_ago': '{count} soat oldin',
    'days_ago': '{count} kun oldin',
  },
  'ru': {
    'back': 'Назад',
    'cancel': 'Отмена',
    'close': 'Закрыть',
    'clear': 'Очистить',
    'send': 'Отправить',
    'create': 'Создать',
    'delete': 'Удалить',
    'undo': 'Вернуть',
    'more_actions': 'Другие действия',
    'permission_denied': 'Нет доступа к сообщениям',
    'permission_message': 'Этот раздел предназначен для переписки сотрудников.',
    'send_permission_denied': 'Нет доступа к отправке сообщений',
    'messages': 'Сообщения',
    'all_read': 'Всё прочитано',
    'unread_chats': 'Непрочитанных чатов: {count}',
    'new_message': 'Новое сообщение',
    'no_results': 'Ничего не найдено',
    'archive_empty': 'Архив пуст',
    'no_chats': 'Нет чатов',
    'try_another_search': 'Попробуйте другое слово или имя.',
    'start_with_new_message':
        'Начните разговор с коллегой через новое сообщение.',
    'empty_message_count': '0 чатов',
    'empty_archive_message':
        'Архивированные чаты появятся здесь. Сейчас ничего не скрыто.',
    'empty_folder_message': 'В этой папке пока нет чатов.',
    'empty_motivation_label': 'Небольшая мысль',
    'empty_motivation_1':
        'Хорошее сотрудничество часто начинается с одного искреннего сообщения.',
    'empty_motivation_2':
        'Ясное и доброжелательное общение создаёт сильную команду.',
    'empty_motivation_3':
        'Минутный разговор может сделать весь рабочий день легче.',
    'empty_motivation_4':
        'Задать вопрос и предложить помощь — одинаково сильные командные шаги.',
    'empty_motivation_5':
        'Небольшой контакт сегодня может стать большим результатом завтра.',
    'empty_quick_actions': 'Быстрый старт',
    'empty_compose_help': 'Найдите коллегу по имени или username.',
    'empty_folder_help': 'Подготовьте порядок для будущих разговоров.',
    'empty_back_to_all': 'Все чаты',
    'empty_back_to_all_help': 'Вернитесь к основному списку сообщений.',
    'empty_refresh': 'Обновить',
    'empty_refresh_help': 'Проверьте новые чаты на сервере.',
    'clear_search': 'Очистить поиск',
    'close_search': 'Закрыть поиск',
    'new_folder': 'Новая папка',
    'folder_name': 'Название папки',
    'folder_example': 'Например: группа 9-Б',
    'toggle_pin': 'Закрепить / открепить',
    'toggle_mute': 'Выключить / включить звук',
    'add_to_folder': 'Добавить в папку',
    'delete_chats': 'Удалить чаты',
    'choose_folder': 'Выберите папку',
    'folder_selection_help': 'Выбранные чаты будут добавлены в эту папку.',
    'delete_chats_question': 'Удалить чаты?',
    'delete_chats_description': 'Будет удалено чатов: {count}.',
    'chats_deleted': 'Удалено чатов: {count}',
    'selected_count': 'Выбрано: {count}',
    'close_selection': 'Закрыть выбор',
    'archive': 'Архив',
    'archive_action': 'Архивировать',
    'mark_read': 'Пометить прочитанным',
    'search_chats': 'Поиск по имени, username или сообщению',
    'all': 'Все',
    'folder_work': 'Работа',
    'folder_important': 'Важное',
    'device_local_organization':
        'Папки, закрепление, звук и архив хранятся только на этом устройстве.',
    'start_chat': 'Начните разговор',
    'chat': 'Чат',
    'chat_not_found': 'Чат не найден',
    'send_first_message':
        'Отправьте текст, фото, короткое видео или голосовое.',
    'message_not_found': 'Сообщение не найдено',
    'change_search': 'Измените поисковый запрос.',
    'online_now': 'сейчас в сети',
    'notifications_muted': 'уведомления выключены',
    'staff_coordination': 'координация сотрудников',
    'staff_chat': 'чат сотрудников',
    'attach': 'Прикрепить',
    'attachment_help':
        'Это не файл с устройства: выберите демо-медиа для проверки чата. Видео — до 1 минуты.',
    'demo_media_badge': 'ДЕМО-МЕДИА',
    'demo_media_sent':
        'Демо-вложение сохранено в чате. Эта сборка не читает камеру или галерею.',
    'voice_demo_notice':
        'Прототип голосового сообщения сохраняет длительность, но не записывает звук микрофона.',
    'board_photo': 'Фото классной доски',
    'board_photo_file': 'Фото доски.jpg',
    'image_size': 'Фото · 2,4 МБ',
    'lesson_clip': 'Фрагмент урока',
    'lesson_clip_file': 'Фрагмент урока.mp4',
    'video_allowed': 'Видео · 00:48 · разрешено',
    'seminar_recording': 'Запись семинара',
    'seminar_file': 'Запись семинара.mp4',
    'video_over_limit': 'Видео · 01:14 · превышает лимит',
    'messages_copied': 'Сообщения скопированы',
    'delete_messages_question': 'Удалить сообщения?',
    'delete_messages_description': 'Сообщений будет удалено: {count}.',
    'delete_messages_device_description':
        'Сообщений будет скрыто на этом устройстве: {count}. Официальная серверная запись сохранится.',
    'messages_deleted': 'Удалено сообщений: {count}',
    'search_in_chat': 'Поиск в чате',
    'profile': 'Профиль',
    'cancel_recording': 'Отменить запись',
    'emoji': 'Эмодзи',
    'write_message': 'Введите сообщение…',
    'attach_media': 'Прикрепить медиа',
    'record_voice': 'Записать голосовое',
    'voice_progress': 'Воспроизведено {percent} процентов',
    'voice_message': 'Голосовое сообщение',
    'image': 'Фото',
    'video': 'Видео',
    'listen': 'Слушать',
    'stop': 'Остановить',
    'reaction': 'Реакция {emoji}',
    'copy': 'Копировать',
    'search_staff': 'Найти сотрудника',
    'search_contacts': 'Найти сотрудника или ученика',
    'contact_filter_all': 'Все',
    'contact_filter_staff': 'Сотрудники',
    'contact_filter_students': 'Ученики',
    'existing_contact': 'Текущий чат',
    'open_chat': 'Открыть чат',
    'retry': 'Повторить',
    'contact_directory_loading': 'Загрузка контактов\u2026',
    'contact_directory_loading_help':
        'Загружаются только разрешённые вам сотрудники и ученики.',
    'contact_directory_error': 'Не удалось загрузить контакты',
    'no_permitted_contacts': 'Контактов пока нет',
    'no_permitted_contacts_help': 'Разрешённые вам контакты появятся здесь.',
    'contacts_not_found': 'Контакт не найден',
    'contact_search_help': 'Попробуйте другое имя, должность или username.',
    'remove_recipient': 'Удалить получателя',
    'staff_not_found': 'Сотрудник не найден',
    'staff_search_help': 'Ищите по имени, должности или username.',
    'message_to': 'Сообщение для {name}…',
    'contact_profile': 'Профиль сотрудника',
    'contact_not_found': 'Контакт не найден',
    'message_action': 'Сообщение',
    'call': 'Позвонить',
    'search': 'Поиск',
    'turn_on': 'Включить',
    'turn_off': 'Выключить',
    'contact_copied': 'Контактные данные скопированы',
    'username': 'Имя пользователя',
    'phone': 'Телефон',
    'role': 'Должность',
    'about': 'О СЕБЕ',
    'media_files': 'Медиа и файлы',
    'attachments_count': 'Вложений: {count}',
    'share_contact': 'Поделиться контактом',
    'copy_to_clipboard': 'Скопировать данные в буфер обмена',
    'microphone': 'Микрофон',
    'sound': 'Звук',
    'end_call': 'Завершить звонок',
    'call_preview_notice':
        'Безопасный прототип звонка. Он не подключается к мобильной сети.',
    'microphone_on': 'Микрофон включён',
    'microphone_off': 'Микрофон выключен',
    'speaker_on': 'Динамик включён',
    'speaker_off': 'Динамик выключен',
    'restoring_messages': 'Восстанавливаем сохранённые чаты…',
    'video_too_long': 'Видео не должно превышать 1 минуту.',
    'voice_too_short': 'Голосовое сообщение слишком короткое.',
    'voice_duration_invalid':
        'Голосовое сообщение должно длиться от 0,5 секунды до 1 минуты.',
    'voice_capture_failed':
        'Не удалось записать звук. Проверьте доступ к микрофону и настройки устройства.',
    'voice_permission_denied':
        'Нет доступа к микрофону. Разрешите микрофон для StarForge Staff в настройках телефона.',
    'voice_unsupported':
        'Это устройство не поддерживает безопасный формат записи голоса.',
    'voice_send_failed':
        'Не удалось отправить голосовое. Проверьте интернет и попробуйте снова.',
    'voice_play_failed':
        'Не удалось открыть голосовое. Обновите ссылку и попробуйте снова.',
    'folder_name_required': 'Введите название папки.',
    'folder_exists': 'Папка с таким названием уже существует.',
    'message_required': 'Введите текст сообщения.',
    'time_now': 'сейчас',
    'minutes_ago': '{count} мин. назад',
    'hours_ago': '{count} ч. назад',
    'days_ago': '{count} дн. назад',
  },
  'en': {
    'back': 'Back',
    'cancel': 'Cancel',
    'close': 'Close',
    'clear': 'Clear',
    'send': 'Send',
    'create': 'Create',
    'delete': 'Delete',
    'undo': 'Undo',
    'more_actions': 'More actions',
    'permission_denied': 'Messaging unavailable',
    'permission_message': 'This workspace is for staff messaging.',
    'send_permission_denied': 'You cannot send staff messages',
    'messages': 'Messages',
    'all_read': 'All caught up',
    'unread_chats': '{count} unread conversations',
    'new_message': 'New message',
    'no_results': 'No results',
    'archive_empty': 'Archive is empty',
    'no_chats': 'No conversations',
    'try_another_search': 'Try another word or staff name.',
    'start_with_new_message': 'Start a conversation with a colleague.',
    'empty_message_count': '0 conversations',
    'empty_archive_message':
        'Archived conversations will appear here. Nothing is hidden yet.',
    'empty_folder_message': 'This folder has no conversations yet.',
    'empty_motivation_label': 'A small reminder',
    'empty_motivation_1':
        'Good collaboration often begins with one thoughtful message.',
    'empty_motivation_2':
        'Clear, kind communication is how strong teams are built.',
    'empty_motivation_3':
        'A one-minute conversation can make the whole workday easier.',
    'empty_motivation_4':
        'Asking a question and offering help are both signs of a strong team.',
    'empty_motivation_5':
        'A small connection today can become a meaningful result tomorrow.',
    'empty_quick_actions': 'Quick start',
    'empty_compose_help': 'Find a colleague by name or username.',
    'empty_folder_help': 'Create a tidy place for future conversations.',
    'empty_back_to_all': 'All conversations',
    'empty_back_to_all_help': 'Return to the main message list.',
    'empty_refresh': 'Refresh',
    'empty_refresh_help': 'Check the server for the latest conversations.',
    'clear_search': 'Clear search',
    'close_search': 'Close search',
    'new_folder': 'New folder',
    'folder_name': 'Folder name',
    'folder_example': 'For example: Group 9-B',
    'toggle_pin': 'Pin / unpin',
    'toggle_mute': 'Mute / unmute',
    'add_to_folder': 'Add to folder',
    'delete_chats': 'Delete conversations',
    'choose_folder': 'Choose a folder',
    'folder_selection_help': 'Selected conversations will be added here.',
    'delete_chats_question': 'Delete conversations?',
    'delete_chats_description': '{count} conversations will be removed.',
    'chats_deleted': '{count} conversations deleted',
    'selected_count': '{count} selected',
    'close_selection': 'Close selection',
    'archive': 'Archive',
    'archive_action': 'Archive',
    'mark_read': 'Mark as read',
    'search_chats': 'Search name, username, or message',
    'all': 'All',
    'folder_work': 'Work',
    'folder_important': 'Important',
    'device_local_organization':
        'Folders, pins, mute, and archive are stored on this device only.',
    'start_chat': 'Start the conversation',
    'chat': 'Chat',
    'chat_not_found': 'Conversation not found',
    'send_first_message':
        'Send text, an image, a short video, or a voice note.',
    'message_not_found': 'No message found',
    'change_search': 'Try a different search phrase.',
    'online_now': 'online now',
    'notifications_muted': 'notifications muted',
    'staff_coordination': 'staff coordination',
    'staff_chat': 'staff conversation',
    'attach': 'Attach',
    'attachment_help':
        'These are not device files. Choose demo media to exercise the conversation flow; videos can be up to one minute.',
    'demo_media_badge': 'DEMO MEDIA',
    'demo_media_sent':
        'The demo attachment was saved in this conversation. This build does not access the camera or gallery.',
    'voice_demo_notice':
        'The voice-note prototype saves timing only; this build does not capture microphone audio.',
    'board_photo': 'Classroom board photo',
    'board_photo_file': 'Classroom board.jpg',
    'image_size': 'Image · 2.4 MB',
    'lesson_clip': 'Lesson clip',
    'lesson_clip_file': 'Lesson clip.mp4',
    'video_allowed': 'Video · 00:48 · allowed',
    'seminar_recording': 'Seminar recording',
    'seminar_file': 'Seminar recording.mp4',
    'video_over_limit': 'Video · 01:14 · over the limit',
    'messages_copied': 'Messages copied',
    'delete_messages_question': 'Delete messages?',
    'delete_messages_description': '{count} messages will be deleted.',
    'delete_messages_device_description':
        '{count} messages will only be hidden on this device. The official server record is retained.',
    'messages_deleted': '{count} messages removed',
    'search_in_chat': 'Search conversation',
    'profile': 'Profile',
    'cancel_recording': 'Discard recording',
    'emoji': 'Emoji',
    'write_message': 'Write a message…',
    'attach_media': 'Attach media',
    'record_voice': 'Record a voice message',
    'voice_progress': 'Voice playback {percent} percent',
    'voice_message': 'Voice message',
    'image': 'Image',
    'video': 'Video',
    'listen': 'Play',
    'stop': 'Pause',
    'reaction': 'React {emoji}',
    'copy': 'Copy',
    'search_staff': 'Search staff',
    'search_contacts': 'Search staff or students',
    'contact_filter_all': 'All',
    'contact_filter_staff': 'Staff',
    'contact_filter_students': 'Students',
    'existing_contact': 'Existing chat',
    'open_chat': 'Open chat',
    'retry': 'Retry',
    'contact_directory_loading': 'Loading contacts\u2026',
    'contact_directory_loading_help':
        'Only staff and students you are permitted to contact are being loaded.',
    'contact_directory_error': 'Could not load contacts',
    'no_permitted_contacts': 'No contacts yet',
    'no_permitted_contacts_help':
        'Contacts you are permitted to message will appear here.',
    'contacts_not_found': 'No contact found',
    'contact_search_help': 'Try another name, role, or username.',
    'remove_recipient': 'Remove recipient',
    'staff_not_found': 'Staff member not found',
    'staff_search_help': 'Search by name, role, or username.',
    'message_to': 'Message {name}…',
    'contact_profile': 'Staff profile',
    'contact_not_found': 'Contact not found',
    'message_action': 'Message',
    'call': 'Call',
    'search': 'Search',
    'turn_on': 'Unmute',
    'turn_off': 'Mute',
    'contact_copied': 'Contact details copied',
    'username': 'Username',
    'phone': 'Phone',
    'role': 'Role',
    'about': 'ABOUT',
    'media_files': 'Media and files',
    'attachments_count': '{count} attachments',
    'share_contact': 'Share contact',
    'copy_to_clipboard': 'Copy details to the system clipboard',
    'microphone': 'Microphone',
    'sound': 'Speaker',
    'end_call': 'End call',
    'call_preview_notice':
        'Safe in-app call prototype. It does not connect to a carrier or VoIP service.',
    'microphone_on': 'Microphone on',
    'microphone_off': 'Microphone muted',
    'speaker_on': 'Speaker on',
    'speaker_off': 'Speaker off',
    'restoring_messages': 'Restoring saved conversations…',
    'video_too_long': 'Videos must be one minute or shorter.',
    'voice_too_short': 'That voice message is too short.',
    'voice_duration_invalid':
        'Voice messages must be between 0.5 seconds and one minute.',
    'voice_capture_failed':
        'Audio could not be recorded. Check microphone access and device settings.',
    'voice_permission_denied':
        'Microphone access is off. Enable it for StarForge Staff in phone settings.',
    'voice_unsupported':
        'This device does not support the secure voice recording format.',
    'voice_send_failed':
        'The voice message was not sent. Check your connection and try again.',
    'voice_play_failed':
        'The voice message could not be opened. Refresh the link and try again.',
    'folder_name_required': 'Enter a folder name.',
    'folder_exists': 'A folder with this name already exists.',
    'message_required': 'Enter a message.',
    'time_now': 'now',
    'minutes_ago': '{count}m ago',
    'hours_ago': '{count}h ago',
    'days_ago': '{count}d ago',
  },
};
