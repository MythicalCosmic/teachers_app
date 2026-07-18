import 'package:flutter/widgets.dart';

@immutable
final class AiStaffGroup {
  const AiStaffGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.schedule,
    required this.studentCount,
    required this.attendance,
    required this.upCards,
    required this.downCards,
    required this.preview,
    required this.focusStudents,
    this.usesAccent = false,
  });

  final String id;
  final String name;
  final String subject;
  final String schedule;
  final int studentCount;
  final int attendance;
  final int upCards;
  final int downCards;
  final String preview;
  final List<String> focusStudents;
  final bool usesAccent;

  String get searchableText => [
    name,
    subject,
    schedule,
    preview,
    ...focusStudents,
  ].join(' ').toLowerCase();
}

/// Copy and local demo data owned by the AI workspace.
///
/// Uzbek remains the existing default. English is complete, and is also the
/// deliberate fallback for Russian and any future unsupported locale so this
/// workspace never leaks Uzbek chrome into a non-Uzbek session.
@immutable
final class AiWorkspaceCopy {
  const AiWorkspaceCopy._({required this.isUzbek});

  final bool isUzbek;

  static AiWorkspaceCopy of(BuildContext context) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'uz';
    return AiWorkspaceCopy._(isUzbek: code == 'uz');
  }

  String pick(String uzbek, String english) => isUzbek ? uzbek : english;

  List<AiStaffGroup> get staffGroups =>
      isUzbek ? _uzbekStaffGroups : _englishStaffGroups;

  AiStaffGroup get allGroups => isUzbek ? _uzbekAllGroups : _englishAllGroups;

  List<String> get generalPrompts =>
      isUzbek ? _uzbekGeneralPrompts : _englishGeneralPrompts;

  List<String> get quickPrompts =>
      isUzbek ? _uzbekQuickPrompts : _englishQuickPrompts;

  AiStaffGroup groupForId(String? id) {
    if (id == allGroups.id) return allGroups;
    return staffGroups.firstWhere(
      (group) => group.id == id,
      orElse: () => staffGroups.first,
    );
  }

  String get searchHint => pick(
    'Guruh, mavzu yoki tavsiyani izlang…',
    'Search groups, topics, or suggestions…',
  );
  String get clearSearch => pick('Qidiruvni tozalash', 'Clear search');
  String get deviceDemo => pick('Qurilmadagi demo', 'Device-local demo');
  String get noServer => pick('SERVER YO‘Q', 'NO SERVER');
  String get privacyDescription => pick(
    'Javoblar o‘rnatilgan demo ma’lumotlardan tuziladi. Savollar va javoblar serverga yuborilmaydi.',
    'Replies use demo data installed with the app. Questions and replies are never sent to a server.',
  );
  String get myGroups => pick('MENING GURUHLARIM', 'MY GROUPS');
  String get generalQuestions => pick('UMUMIY SAVOLLAR', 'GENERAL QUESTIONS');
  String get assistant => pick('Yordamchi', 'Assistant');
  String get workspaceTitle => pick('AI ish maydoni', 'AI workspace');
  String get workspaceSubtitle => pick(
    'Guruh kontekstini tanlang yoki umumiy savol bering',
    'Choose a group context or ask a general question',
  );
  String get closeSearch => pick('Qidiruvni yopish', 'Close search');
  String get searchWorkspace =>
      pick('AI ish maydonidan izlash', 'Search AI workspace');
  String openGroup(String name) =>
      pick('$name AI suhbatini ochish', 'Open the $name AI conversation');
  String studentsAndSchedule(AiStaffGroup group) => pick(
    '${group.studentCount} o‘quvchi · ${group.schedule}',
    '${group.studentCount} students · ${group.schedule}',
  );
  String get latestSummary =>
      pick('QURILMADAGI OXIRGI XULOSA', 'LATEST DEVICE SUMMARY');
  String attendance(int value) => pick('Davomat $value%', 'Attendance $value%');
  String openQuestion(String prompt) =>
      pick('$prompt savolini ochish', 'Open the question: $prompt');
  String get noMatches =>
      pick('Mos guruh yoki savol topilmadi', 'No matching groups or questions');
  List<String> get navigationLabels => [
    pick('Bugun', 'Today'),
    pick('Guruhlar', 'Groups'),
    pick('Vazifa', 'Tasks'),
    'AI',
    'Print',
  ];

  String welcome(AiStaffGroup group) => pick(
    'Men ${group.name} uchun qurilmadagi demo yordamchiman. Haftalik xulosa, diqqat talab qilayotgan o‘quvchilar yoki ota-ona uchun qoralama haqida so‘rashingiz mumkin.',
    'I am the device-local demo assistant for ${group.name}. Ask for a weekly summary, students who need support, or a draft parent message.',
  );
  String get clearConversationTitle =>
      pick('Suhbat tozalansinmi?', 'Clear this conversation?');
  String get clearConversationDescription => pick(
    'Faqat ushbu qurilmadagi joriy demo suhbat o‘chiriladi.',
    'Only this device-local demo conversation will be removed.',
  );
  String get cancel => pick('Bekor qilish', 'Cancel');
  String get clear => pick('Tozalash', 'Clear');
  String get helpTitle =>
      pick('Qurilmadagi AI haqida', 'About device-local AI');
  String get helpDescription => pick(
    'Bu xavfsiz demo yordamchi. U faqat ilovaga o‘rnatilgan namunaviy guruh ma’lumotlaridan javob tuzadi. Savollar serverga yuborilmaydi va javoblar haqiqiy o‘quvchi qarori o‘rnini bosmaydi.',
    'This is a safe demo assistant. It only uses sample group data installed with the app. Questions are never sent to a server, and replies do not replace real student decisions.',
  );
  String get understood => pick('Tushundim', 'Got it');
  String get privacyFootnote => pick(
    'Qurilmadagi demo · serverga yuborilmaydi',
    'Device-local demo · never sent to a server',
  );
  String composerHint(String groupName) =>
      pick('$groupName haqida savol bering…', 'Ask about $groupName…');
  String get sendQuestion => pick('Savolni yuborish', 'Send question');
  String get backToWorkspace =>
      pick('AI ish maydoniga qaytish', 'Back to AI workspace');
  String get onDevice => pick('Qurilmada', 'On device');
  String get preparingReply =>
      pick('Demo javob tayyorlanmoqda…', 'Preparing a demo reply…');
  String studentsAndSubject(AiStaffGroup group) => pick(
    '${group.studentCount} o‘quvchi · ${group.subject}',
    '${group.studentCount} students · ${group.subject}',
  );
  String get conversationActions =>
      pick('AI suhbat amallari', 'AI conversation actions');
  String get clearConversation =>
      pick('Suhbatni tozalash', 'Clear conversation');
  String get help => pick('Yordam', 'Help');
  String sendPrompt(String prompt) =>
      pick('$prompt so‘rovini yuborish', 'Send the prompt: $prompt');

  String localReply(AiStaffGroup group, String prompt) {
    final normalized = prompt.toLowerCase();
    final focus = group.focusStudents.join(isUzbek ? ' va ' : ' and ');

    if (isUzbek) {
      if (normalized.contains('ota-ona') ||
          normalized.contains('xat') ||
          normalized.contains('parent')) {
        return 'Demo xat: Assalomu alaykum. ${group.name} guruhida '
            '${group.subject.toLowerCase()} bo‘yicha ish davom etmoqda. '
            'Farzandingizning uy mashqlarini qisqa takrorlashiga yordam bersangiz, '
            'keyingi darsga yanada ishonchli keladi. Bu matn faqat qoralama; '
            'hech kimga yuborilmadi.';
      }
      if (normalized.contains('qiynal') ||
          normalized.contains('diqqat') ||
          normalized.contains('kim')) {
        return 'Qurilmadagi demo qaydlarda $focus ko‘proq e’tibor talab qilmoqda. '
            'Tavsiya: 5 daqiqalik takrorlash, bitta namunaviy misol va dars oxirida '
            'qisqa tekshiruv.';
      }
      if (normalized.contains('karta') ||
          normalized.contains('nomzod') ||
          normalized.contains('eng yaxshi')) {
        return '${group.name} uchun demo karta ko‘rinishi: ${group.upCards} ta '
            'ijobiy va ${group.downCards} ta ogohlantirish qaydi bor. '
            '${group.focusStudents.first} bilan individual o‘sish maqsadini '
            'belgilash mumkin.';
      }
      if (normalized.contains('hafta') ||
          normalized.contains('xulosa') ||
          normalized.contains('qanday')) {
        return '${group.name} haftalik demo xulosasi: davomat ${group.attendance}%, '
            '${group.studentCount} o‘quvchi va mavzu — ${group.subject}. '
            '${group.preview} Bu javob faqat qurilmadagi demo ma’lumotlardan tuzildi.';
      }
      return '${group.name} bo‘yicha qurilmadagi demo yordamchi savolingizni qabul '
          'qildi: “${prompt.trim()}”. Hozirgi ko‘rinishda davomat '
          '${group.attendance}% va asosiy mavzu ${group.subject.toLowerCase()}. '
          'Aniqroq natija uchun haftalik xulosa, qiynalayotganlar yoki karta '
          'nomzodlari haqida so‘rashingiz mumkin.';
    }

    if (normalized.contains('parent') ||
        normalized.contains('message') ||
        normalized.contains('draft')) {
      return 'Demo message: Hello. ${group.name} is continuing work on '
          '${group.subject.toLowerCase()}. A short review at home can help your '
          'child arrive at the next lesson with more confidence. This is a draft '
          'only; nothing was sent.';
    }
    if (normalized.contains('support') ||
        normalized.contains('struggl') ||
        normalized.contains('attention') ||
        normalized.startsWith('who')) {
      return 'In the device-local demo notes, $focus may need more support. '
          'Suggested next step: a five-minute review, one worked example, and a '
          'short check at the end of the lesson.';
    }
    if (normalized.contains('card') ||
        normalized.contains('candidate') ||
        normalized.contains('top') ||
        normalized.contains('best')) {
      return 'Demo card view for ${group.name}: ${group.upCards} positive cards '
          'and ${group.downCards} warning cards are recorded. Consider setting an '
          'individual growth goal with ${group.focusStudents.first}.';
    }
    if (normalized.contains('week') ||
        normalized.contains('summary') ||
        normalized.contains('how')) {
      return '${group.name} weekly demo summary: ${group.attendance}% attendance, '
          '${group.studentCount} students, and the current topic is '
          '${group.subject}. ${group.preview} This reply only uses device-local '
          'demo data.';
    }
    return 'The device-local demo assistant received your question about '
        '${group.name}: “${prompt.trim()}”. Current attendance is '
        '${group.attendance}%, and the main topic is ${group.subject.toLowerCase()}. '
        'For a more focused reply, ask for a weekly summary, students who need '
        'support, or card candidates.';
  }
}

const _uzbekStaffGroups = <AiStaffGroup>[
  AiStaffGroup(
    id: '9-b-algebra',
    name: '9-B Algebra',
    subject: 'Kvadrat tenglamalar',
    schedule: 'Mar / Pays / Juma',
    studentCount: 24,
    attendance: 94,
    upCards: 8,
    downCards: 2,
    preview:
        'Bu hafta guruh barqaror. Ikki o‘quvchiga qisqa takrorlash foydali.',
    focusStudents: ['Eshmatov Otabek', 'Bakirov Sherzod'],
  ),
  AiStaffGroup(
    id: 'algebra-mid',
    name: 'Algebra · Mid',
    subject: 'Funksiyalar va grafiklar',
    schedule: 'Du / Chor / Pay',
    studentCount: 21,
    attendance: 96,
    upCards: 6,
    downCards: 0,
    preview: 'Davronova Sevinch va Halimova Zilola murakkab mashqlarga tayyor.',
    focusStudents: ['Karimov Samandar', 'Umarova Nilufar'],
  ),
  AiStaffGroup(
    id: '10-v-geometriya',
    name: '10-V Geometriya',
    subject: 'Trapetsiya va yuzalar',
    schedule: 'Du / Pay',
    studentCount: 19,
    attendance: 88,
    upCards: 4,
    downCards: 1,
    preview:
        'Trapetsiya mavzusi yaxshi ketmoqda. 11-misol uchun qo‘shimcha izoh kerak.',
    focusStudents: ['Nazarov Javohir', 'Yoqubova Maftuna'],
    usesAccent: true,
  ),
];

const _englishStaffGroups = <AiStaffGroup>[
  AiStaffGroup(
    id: '9-b-algebra',
    name: '9-B Algebra',
    subject: 'Quadratic equations',
    schedule: 'Tue / Thu / Fri',
    studentCount: 24,
    attendance: 94,
    upCards: 8,
    downCards: 2,
    preview:
        'The group is steady this week. Two students would benefit from a short review.',
    focusStudents: ['Eshmatov Otabek', 'Bakirov Sherzod'],
  ),
  AiStaffGroup(
    id: 'algebra-mid',
    name: 'Algebra · Intermediate',
    subject: 'Functions and graphs',
    schedule: 'Mon / Wed / Thu',
    studentCount: 21,
    attendance: 96,
    upCards: 6,
    downCards: 0,
    preview:
        'Davronova Sevinch and Halimova Zilola are ready for advanced exercises.',
    focusStudents: ['Karimov Samandar', 'Umarova Nilufar'],
  ),
  AiStaffGroup(
    id: '10-v-geometriya',
    name: '10-V Geometry',
    subject: 'Trapezoids and area',
    schedule: 'Mon / Thu',
    studentCount: 19,
    attendance: 88,
    upCards: 4,
    downCards: 1,
    preview:
        'The trapezoid topic is progressing well. Exercise 11 needs an extra explanation.',
    focusStudents: ['Nazarov Javohir', 'Yoqubova Maftuna'],
    usesAccent: true,
  ),
];

const _uzbekAllGroups = AiStaffGroup(
  id: 'all-groups',
  name: 'Barcha guruhlar',
  subject: 'Umumiy o‘qituvchi ko‘rinishi',
  schedule: 'Haftalik jamlama',
  studentCount: 64,
  attendance: 93,
  upCards: 18,
  downCards: 3,
  preview: 'Uch guruh bo‘yicha qurilmadagi demo jamlama.',
  focusStudents: ['Eshmatov Otabek', 'Nazarov Javohir'],
);

const _englishAllGroups = AiStaffGroup(
  id: 'all-groups',
  name: 'All groups',
  subject: 'Overall teacher view',
  schedule: 'Weekly digest',
  studentCount: 64,
  attendance: 93,
  upCards: 18,
  downCards: 3,
  preview: 'A device-local demo digest across three groups.',
  focusStudents: ['Eshmatov Otabek', 'Nazarov Javohir'],
);

const _uzbekGeneralPrompts = <String>[
  'Ushbu hafta eng yaxshi 5 o‘quvchini ko‘rsat',
  'Ota-onaga yuboriladigan haftalik xulosa tuz',
  'Kim oxirgi 2 haftada karta olmadi?',
];

const _englishGeneralPrompts = <String>[
  'Show the top 5 students this week',
  'Draft a weekly update for parents',
  'Who has not received a card in the last 2 weeks?',
];

const _uzbekQuickPrompts = <String>[
  'Haftalik xulosa',
  'Kim qiynalmoqda?',
  'Up karta nomzodlari',
  'Ota-ona uchun xat',
];

const _englishQuickPrompts = <String>[
  'Weekly summary',
  'Who needs support?',
  'Up card candidates',
  'Parent message',
];

String aiChatLocation(AiStaffGroup group, {String? prompt}) => Uri(
  path: '/ai/chat',
  queryParameters: {
    'group': group.id,
    if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
  },
).toString();
