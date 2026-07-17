import 'models.dart';

/// Stable, hand-authored fixture data used for the offline-first demo.
///
/// No value depends on the device clock or random numbers, so screenshots,
/// tests, and first-run behavior remain reproducible.
abstract final class DemoSeed {
  static final DateTime anchor = DateTime.utc(2026, 5, 20, 8);

  static const String demoPassword = 'demo2026';

  static const Map<String, StaffSession> demoAccounts = {
    'nigora.karimova': StaffSession(
      userId: 'staff-teacher-001',
      displayName: 'Nigora Karimova',
      role: StaffRole.teacher,
      branchId: 'branch-yunusobod',
      branchName: 'Yunusobod filiali',
      email: 'nigora.karimova@demo.starforge.uz',
    ),
    'sardor.aliyev': StaffSession(
      userId: 'staff-assistant-001',
      displayName: 'Sardor Aliyev',
      role: StaffRole.assistant,
      branchId: 'branch-yunusobod',
      branchName: 'Yunusobod filiali',
      email: 'sardor.aliyev@demo.starforge.uz',
    ),
    'rano.karimova': StaffSession(
      userId: 'staff-methodist-001',
      displayName: 'Ra’no Karimova',
      role: StaffRole.methodist,
      branchId: 'branch-yunusobod',
      branchName: 'Yunusobod filiali',
      email: 'rano.karimova@demo.starforge.uz',
    ),
    'malika.qodirova': StaffSession(
      userId: 'staff-reception-001',
      displayName: 'Malika Qodirova',
      role: StaffRole.reception,
      branchId: 'branch-yunusobod',
      branchName: 'Yunusobod filiali',
      email: 'malika.qodirova@demo.starforge.uz',
    ),
    'aziz.audit': StaffSession(
      userId: 'staff-auditor-001',
      displayName: 'Aziz Rahimov',
      role: StaffRole.auditor,
      branchId: 'branch-yunusobod',
      branchName: 'Yunusobod filiali',
      email: 'aziz.audit@demo.starforge.uz',
    ),
  };

  static StaffSession? authenticate(String username, String password) {
    if (password != demoPassword) return null;
    var normalized = username.trim().toLowerCase();
    for (final suffix in const ['@demo', '@demo.starforge.uz']) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
        break;
      }
    }
    return demoAccounts[normalized];
  }

  static AppSnapshot snapshot() => AppSnapshot(
    session: null,
    settings: const AppSettings(),
    tasks: _tasks(),
    attendanceSheets: [_attendance()],
    cards: _cards(),
    messageThreads: _threads(),
    notifications: _notifications(),
    surveys: _surveys(),
    printJobs: _printJobs(),
    auditAnomalies: _anomalies(),
    auditCases: _cases(),
  );

  static List<StaffTask> _tasks() => [
    StaffTask(
      id: 'task-001',
      title: 'May oyi yakuniy hisobotini topshirish',
      description:
          'Davomat, o‘quv natijalari va kartalar bo‘yicha qisqa jamlama.',
      status: TaskStatus.inProgress,
      priority: TaskPriority.urgent,
      creatorId: 'staff-methodist-001',
      creatorName: 'Ra’no Karimova',
      assigneeId: 'staff-teacher-001',
      assigneeName: 'Nigora Karimova',
      dueAt: DateTime.utc(2026, 5, 21, 18),
      createdAt: DateTime.utc(2026, 5, 18, 9),
      checklist: const [
        TaskChecklistItem(
          id: 'task-001-step-1',
          title: 'Davomat jamlamasi',
          isDone: true,
        ),
        TaskChecklistItem(
          id: 'task-001-step-2',
          title: 'Kartalar tahlili',
          isDone: true,
        ),
        TaskChecklistItem(id: 'task-001-step-3', title: 'Xulosa yozish'),
        TaskChecklistItem(id: 'task-001-step-4', title: 'Tekshiruvga yuborish'),
      ],
    ),
    StaffTask(
      id: 'task-002',
      title: 'Kvadrat tenglamalar slaydlarini yangilash',
      description: '9-B uchun misollar va vizual izohlarni yangilang.',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      creatorId: 'staff-teacher-001',
      creatorName: 'Nigora Karimova',
      assigneeId: 'staff-teacher-001',
      assigneeName: 'Nigora Karimova',
      dueAt: DateTime.utc(2026, 5, 23, 18),
      createdAt: DateTime.utc(2026, 5, 19, 7, 45),
      checklist: const [
        TaskChecklistItem(
          id: 'task-002-step-1',
          title: 'Eski slaydlarni ko‘rib chiqish',
        ),
        TaskChecklistItem(
          id: 'task-002-step-2',
          title: 'Yangi misollar qo‘shish',
        ),
      ],
    ),
    StaffTask(
      id: 'task-003',
      title: 'AI sifat so‘rovnomasini yakunlash',
      description: 'Haftalik tajriba haqida fikr bildiring.',
      status: TaskStatus.inReview,
      priority: TaskPriority.medium,
      creatorId: 'staff-methodist-001',
      creatorName: 'Ra’no Karimova',
      assigneeId: 'staff-teacher-001',
      assigneeName: 'Nigora Karimova',
      dueAt: DateTime.utc(2026, 5, 22, 17),
      createdAt: DateTime.utc(2026, 5, 17, 12),
      checklist: const [
        TaskChecklistItem(
          id: 'task-003-step-1',
          title: 'Savollarga javob berish',
          isDone: true,
        ),
      ],
    ),
    StaffTask(
      id: 'task-004',
      title: 'Olimpiada tayyorgarligi uchun reja',
      description: '11-B guruhining ikki haftalik rejasini yozing.',
      status: TaskStatus.done,
      priority: TaskPriority.low,
      creatorId: 'staff-methodist-001',
      creatorName: 'Ra’no Karimova',
      assigneeId: 'staff-teacher-001',
      assigneeName: 'Nigora Karimova',
      dueAt: DateTime.utc(2026, 5, 18, 16),
      createdAt: DateTime.utc(2026, 5, 14, 8),
      checklist: const [
        TaskChecklistItem(
          id: 'task-004-step-1',
          title: 'Mavzularni tanlash',
          isDone: true,
        ),
      ],
    ),
  ];

  static AttendanceSheet _attendance() => AttendanceSheet(
    id: 'attendance-9b-2026-05-20',
    cohortId: 'cohort-9b-algebra',
    cohortName: '9-B',
    lessonName: 'Algebra',
    lessonAt: DateTime.utc(2026, 5, 20, 8, 30),
    entries: const [
      AttendanceEntry(
        studentId: 'DEMO-2026-00042',
        studentName: 'Akbarov Akmal',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00043',
        studentName: 'Azizova Madina',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00044',
        studentName: 'Bakirov Sherzod',
        status: AttendanceStatus.late,
        note: '8 daqiqa',
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00045',
        studentName: 'Davronova Sevinch',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00046',
        studentName: 'Eshmatov Otabek',
        status: AttendanceStatus.absent,
        note: 'Kasal',
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00047',
        studentName: 'Fayzullayev Diyor',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00048',
        studentName: 'G‘aniyev Jasur',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00049',
        studentName: 'Halimova Zilola',
        status: AttendanceStatus.excused,
        note: 'Olimpiada',
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00050',
        studentName: 'Ibragimov Sardor',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00051',
        studentName: 'Jo‘rayeva Nilufar',
        status: AttendanceStatus.present,
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00052',
        studentName: 'Karimov Rustam',
      ),
      AttendanceEntry(
        studentId: 'DEMO-2026-00053',
        studentName: 'Latipova Shahnoza',
      ),
    ],
  );

  static List<RecognitionCard> _cards() => [
    RecognitionCard(
      id: 'card-001',
      studentId: 'DEMO-2026-00042',
      studentName: 'Akbarov Akmal',
      cohortName: '9-B Algebra',
      kind: CardKind.praise,
      label: 'Yulduz karta',
      reason: 'Mustaqil yechim: 3-misol',
      issuedById: 'staff-teacher-001',
      issuedByName: 'Nigora Karimova',
      issuedAt: DateTime.utc(2026, 5, 20, 9, 42),
    ),
    RecognitionCard(
      id: 'card-002',
      studentId: 'DEMO-2026-00049',
      studentName: 'Halimova Zilola',
      cohortName: '9-B Algebra',
      kind: CardKind.praise,
      label: 'Faollik',
      reason: 'Sinfdoshlariga yordam berdi',
      issuedById: 'staff-teacher-001',
      issuedByName: 'Nigora Karimova',
      issuedAt: DateTime.utc(2026, 5, 20, 9, 38),
    ),
    RecognitionCard(
      id: 'card-003',
      studentId: 'DEMO-2026-00046',
      studentName: 'Eshmatov Otabek',
      cohortName: '9-B Algebra',
      kind: CardKind.warning,
      label: 'Ogohlantirish',
      reason: 'Uy ishi tayyor emas',
      issuedById: 'staff-teacher-001',
      issuedByName: 'Nigora Karimova',
      issuedAt: DateTime.utc(2026, 5, 20, 9, 12),
    ),
  ];

  static List<MessageThread> _threads() => [
    MessageThread(
      id: 'thread-methodist',
      title: 'Metodika jamoasi',
      participantIds: const ['staff-teacher-001', 'staff-methodist-001'],
      isPinned: true,
      messages: [
        ChatMessage(
          id: 'message-001',
          senderId: 'staff-methodist-001',
          senderName: 'Ra’no Karimova',
          body: 'Ertangi ochiq dars rejasi tayyormi?',
          sentAt: DateTime.utc(2026, 5, 20, 7, 50),
          readBy: const ['staff-methodist-001'],
        ),
        ChatMessage(
          id: 'message-002',
          senderId: 'staff-teacher-001',
          senderName: 'Nigora Karimova',
          body: 'Ha, tushdan keyin yakuniy nusxani yuboraman.',
          sentAt: DateTime.utc(2026, 5, 20, 7, 54),
          readBy: const ['staff-teacher-001', 'staff-methodist-001'],
        ),
      ],
    ),
    MessageThread(
      id: 'thread-assistants',
      title: '9-B yordamchilar',
      participantIds: const ['staff-teacher-001', 'staff-assistant-001'],
      messages: [
        ChatMessage(
          id: 'message-003',
          senderId: 'staff-assistant-001',
          senderName: 'Sardor Aliyev',
          body: 'Ikki o‘quvchi uchun qo‘shimcha varaq tayyorladim.',
          sentAt: DateTime.utc(2026, 5, 19, 15, 20),
          readBy: const ['staff-assistant-001'],
        ),
      ],
    ),
  ];

  static List<StaffNotification> _notifications() => [
    StaffNotification(
      id: 'notification-001',
      category: NotificationCategory.task,
      title: 'Muhim vazifa muddati yaqin',
      body: 'May oyi hisoboti ertaga soat 18:00 gacha.',
      createdAt: DateTime.utc(2026, 5, 20, 8, 5),
      route: '/tasks/detail',
    ),
    StaffNotification(
      id: 'notification-002',
      category: NotificationCategory.print,
      title: 'Print tayyor',
      body: 'Algebra ish varaqalari chiqarildi.',
      createdAt: DateTime.utc(2026, 5, 20, 7, 40),
      route: '/print',
    ),
    StaffNotification(
      id: 'notification-003',
      category: NotificationCategory.message,
      title: 'Yangi xabar',
      body: '9-B yordamchilari guruhida yangi xabar bor.',
      createdAt: DateTime.utc(2026, 5, 19, 15, 20),
      route: '/messages',
    ),
    StaffNotification(
      id: 'notification-004',
      category: NotificationCategory.survey,
      title: 'So‘rovnoma',
      body: 'Haftalik dars tajribasi so‘rovnomasini yakunlang.',
      createdAt: DateTime.utc(2026, 5, 19, 10),
      route: '/surveys',
      isRead: true,
    ),
  ];

  static List<SurveyAssignment> _surveys() => [
    SurveyAssignment(
      id: 'survey-001',
      title: 'Haftalik dars tajribasi',
      summary: 'Dars jarayoni va vositalar haqida 3 ta qisqa savol.',
      dueAt: DateTime.utc(2026, 5, 22, 18),
      questions: [
        SurveyQuestion(
          id: 'survey-001-q1',
          prompt: 'Bu hafta darslar qanchalik samarali bo‘ldi?',
          kind: SurveyQuestionKind.rating,
          options: const ['1', '2', '3', '4', '5'],
        ),
        SurveyQuestion(
          id: 'survey-001-q2',
          prompt: 'Eng foydali vosita qaysi bo‘ldi?',
          kind: SurveyQuestionKind.singleChoice,
          options: const ['Doska', 'Slaydlar', 'Kartalar', 'AI yordamchi'],
        ),
        SurveyQuestion(
          id: 'survey-001-q3',
          prompt: 'Keyingi hafta nimani yaxshilamoqchisiz?',
          kind: SurveyQuestionKind.freeText,
          options: const [],
        ),
      ],
      answers: const {'survey-001-q1': '4'},
    ),
    SurveyAssignment(
      id: 'survey-002',
      title: 'AI yordamchi sifati',
      summary: 'Yangi yordamchi funksiyalarini baholang.',
      dueAt: DateTime.utc(2026, 5, 25, 18),
      questions: [
        SurveyQuestion(
          id: 'survey-002-q1',
          prompt: 'Takliflar amaliy jihatdan foydalimi?',
          kind: SurveyQuestionKind.singleChoice,
          options: const ['Ha', 'Ba’zan', 'Yo‘q'],
        ),
      ],
      answers: const {},
    ),
  ];

  static List<PrintJob> _printJobs() => [
    PrintJob(
      id: 'print-001',
      documentName: 'Algebra ish varaqalari.pdf',
      printerId: 'printer-library',
      printerName: 'Kutubxona printeri',
      requestedById: 'staff-teacher-001',
      requestedAt: DateTime.utc(2026, 5, 20, 7, 32),
      copies: 12,
      pageCount: 2,
      status: PrintJobStatus.completed,
      progress: 1,
    ),
    PrintJob(
      id: 'print-002',
      documentName: 'Ochiq dars rejasi.pdf',
      printerId: 'printer-staff',
      printerName: 'O‘qituvchilar xonasi',
      requestedById: 'staff-teacher-001',
      requestedAt: DateTime.utc(2026, 5, 20, 8, 12),
      copies: 2,
      pageCount: 6,
      status: PrintJobStatus.printing,
      progress: .55,
    ),
    PrintJob(
      id: 'print-003',
      documentName: '9-B qo‘shimcha mashqlar.pdf',
      printerId: 'printer-staff',
      printerName: 'O‘qituvchilar xonasi',
      requestedById: 'staff-assistant-001',
      requestedAt: DateTime.utc(2026, 5, 19, 15, 5),
      copies: 4,
      pageCount: 3,
      status: PrintJobStatus.failed,
      progress: .2,
      failureReason: 'Qog‘oz tugagan',
    ),
  ];

  static List<AuditAnomaly> _anomalies() => [
    AuditAnomaly(
      id: 'anomaly-001',
      title: 'Davomat kech saqlandi',
      description: '9-B davomat varaqasi darsdan 5 soat keyin yuborilgan.',
      entityLabel: '9-B · Algebra',
      severity: AuditSeverity.medium,
      status: AnomalyStatus.open,
      detectedAt: DateTime.utc(2026, 5, 19, 14, 5),
    ),
    AuditAnomaly(
      id: 'anomaly-002',
      title: 'Takroriy ogohlantirish kartasi',
      description: 'Bir o‘quvchiga 24 soatda uchta ogohlantirish berilgan.',
      entityLabel: 'DEMO-2026-00046',
      severity: AuditSeverity.high,
      status: AnomalyStatus.linked,
      detectedAt: DateTime.utc(2026, 5, 18, 16, 40),
      acknowledgedById: 'staff-auditor-001',
    ),
    AuditAnomaly(
      id: 'anomaly-003',
      title: 'Print hajmi odatdagidan katta',
      description: 'Bitta topshiriq bo‘yicha 240 sahifa navbatga qo‘yilgan.',
      entityLabel: 'Kutubxona printeri',
      severity: AuditSeverity.low,
      status: AnomalyStatus.acknowledged,
      detectedAt: DateTime.utc(2026, 5, 17, 11, 15),
      acknowledgedById: 'staff-auditor-001',
    ),
  ];

  static List<AuditCase> _cases() => [
    AuditCase(
      id: 'audit-case-001',
      title: 'Ogohlantirish kartalarini tekshirish',
      description: 'Takroriy kartalarning sabab va vaqtlarini tekshirish.',
      severity: AuditSeverity.high,
      status: AuditCaseStatus.investigating,
      openedById: 'staff-auditor-001',
      openedAt: DateTime.utc(2026, 5, 18, 17),
      anomalyIds: const ['anomaly-002'],
      notes: const ['Dars jadvali va karta izohlari solishtirilmoqda.'],
    ),
  ];
}
