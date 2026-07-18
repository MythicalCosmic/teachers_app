import 'dart:collection';

import 'package:flutter/foundation.dart';

enum StaffWorkspaceLoad { loading, ready, empty, failure }

enum QualityPeriod { week, month, term }

extension QualityPeriodLabel on QualityPeriod {
  String get label => switch (this) {
    QualityPeriod.week => '7 kun',
    QualityPeriod.month => '30 kun',
    QualityPeriod.term => 'Chorak',
  };
}

enum QualitySignalTone { positive, attention, urgent }

final class QualitySignalView {
  const QualitySignalView({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.tone,
    required this.teacherName,
  });

  final String id;
  final String title;
  final String subtitle;
  final String metric;
  final QualitySignalTone tone;
  final String teacherName;
}

final class ImmutableAuditEventView {
  const ImmutableAuditEventView({
    required this.id,
    required this.actor,
    required this.action,
    required this.entity,
    required this.occurredAt,
    required this.integrityHash,
  });

  final String id;
  final String actor;
  final String action;
  final String entity;
  final DateTime occurredAt;
  final String integrityHash;
}

String buildAuditCsv(Iterable<ImmutableAuditEventView> events) {
  String cell(Object? value) {
    final raw = value?.toString() ?? '';
    return '"${raw.replaceAll('"', '""')}"';
  }

  final rows = <List<Object?>>[
    const ['id', 'actor', 'action', 'entity', 'occurred_at', 'integrity_hash'],
    for (final event in events)
      [
        event.id,
        event.actor,
        event.action,
        event.entity,
        event.occurredAt.toUtc().toIso8601String(),
        event.integrityHash,
      ],
  ];
  return '${rows.map((row) => row.map(cell).join(',')).join('\r\n')}\r\n';
}

final class StaffWorkspaceRefreshStore extends ChangeNotifier {
  StaffWorkspaceRefreshStore({DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _lastUpdatedAt = _now();
  }

  final DateTime Function() _now;
  late DateTime _lastUpdatedAt;
  int _revision = 0;
  bool _refreshing = false;

  DateTime get lastUpdatedAt => _lastUpdatedAt;
  int get revision => _revision;
  bool get refreshing => _refreshing;

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 140));
    _lastUpdatedAt = _now();
    _revision += 1;
    _refreshing = false;
    notifyListeners();
  }
}

enum LeadStage { newLead, contacted, trialBooked, tested, enrolled, lost }

extension LeadStageLabel on LeadStage {
  String get label => switch (this) {
    LeadStage.newLead => 'Yangi',
    LeadStage.contacted => 'Bog\u2018lanildi',
    LeadStage.trialBooked => 'Sinov darsi',
    LeadStage.tested => 'Test qilindi',
    LeadStage.enrolled => 'Qabul qilindi',
    LeadStage.lost => 'Yopildi',
  };

  LeadStage? get next => switch (this) {
    LeadStage.newLead => LeadStage.contacted,
    LeadStage.contacted => LeadStage.trialBooked,
    LeadStage.trialBooked => LeadStage.tested,
    LeadStage.tested => LeadStage.enrolled,
    LeadStage.enrolled || LeadStage.lost => null,
  };
}

final class ReceptionLeadView {
  const ReceptionLeadView({
    required this.id,
    required this.studentName,
    required this.guardianName,
    required this.phone,
    required this.course,
    required this.source,
    required this.stage,
    required this.createdAt,
    required this.nextContactAt,
    this.assigneeName,
    this.note,
    this.lastContactAt,
  });

  final String id;
  final String studentName;
  final String guardianName;
  final String phone;
  final String course;
  final String source;
  final LeadStage stage;
  final DateTime createdAt;
  final DateTime nextContactAt;
  final String? assigneeName;
  final String? note;
  final DateTime? lastContactAt;

  ReceptionLeadView copyWith({
    LeadStage? stage,
    String? assigneeName,
    String? note,
    DateTime? nextContactAt,
    DateTime? lastContactAt,
  }) {
    return ReceptionLeadView(
      id: id,
      studentName: studentName,
      guardianName: guardianName,
      phone: phone,
      course: course,
      source: source,
      stage: stage ?? this.stage,
      createdAt: createdAt,
      nextContactAt: nextContactAt ?? this.nextContactAt,
      assigneeName: assigneeName ?? this.assigneeName,
      note: note ?? this.note,
      lastContactAt: lastContactAt ?? this.lastContactAt,
    );
  }
}

final class ReceptionLeadDraft {
  const ReceptionLeadDraft({
    required this.studentName,
    required this.guardianName,
    required this.phone,
    required this.course,
    this.source = 'Qo\u2018lda qo\u2018shildi',
  });

  final String studentName;
  final String guardianName;
  final String phone;
  final String course;
  final String source;
}

/// Temporary boundary for lead/admission data, which does not yet exist in
/// the shared [AppState] snapshot. Keeping it in this folder makes replacement
/// by an API-backed store mechanical and prevents demo data leaking elsewhere.
abstract class ReceptionWorkspaceStore extends ChangeNotifier {
  StaffWorkspaceLoad get loadState;
  String? get errorMessage;
  UnmodifiableListView<ReceptionLeadView> get leads;
  DateTime? get lastRefreshedAt;

  Future<void> refresh();
  Future<ReceptionLeadView> createLead(ReceptionLeadDraft draft);
  Future<void> recordCall(String leadId);
  Future<void> advanceLead(String leadId);
  Future<void> assignLead(String leadId, String assigneeName);
  Future<void> addLeadNote(String leadId, String note);
}

final class DemoReceptionWorkspaceStore extends ReceptionWorkspaceStore {
  DemoReceptionWorkspaceStore({
    StaffWorkspaceLoad initialState = StaffWorkspaceLoad.ready,
    Iterable<ReceptionLeadView>? seed,
    DateTime Function()? now,
  }) : _loadState = initialState,
       _leads = List.of(seed ?? _demoLeads),
       _now = now ?? DateTime.now;

  StaffWorkspaceLoad _loadState;
  String? _errorMessage;
  final List<ReceptionLeadView> _leads;
  final DateTime Function() _now;
  DateTime? _lastRefreshedAt;

  static final List<ReceptionLeadView> _demoLeads = [
    ReceptionLeadView(
      id: 'lead-01',
      studentName: 'Amirbek Qodirov',
      guardianName: 'Nodira Qodirova',
      phone: '+998 90 218 44 06',
      course: 'Ingliz tili · B1',
      source: 'Instagram',
      stage: LeadStage.newLead,
      createdAt: DateTime.utc(2026, 7, 17, 8, 10),
      nextContactAt: DateTime.utc(2026, 7, 17, 9, 30),
    ),
    ReceptionLeadView(
      id: 'lead-02',
      studentName: 'Madina Xasanova',
      guardianName: 'Ulug\u2018bek Xasanov',
      phone: '+998 93 540 12 77',
      course: 'Matematika · 9-sinf',
      source: 'Tavsiya',
      stage: LeadStage.contacted,
      createdAt: DateTime.utc(2026, 7, 16, 13, 25),
      nextContactAt: DateTime.utc(2026, 7, 17, 11, 0),
      assigneeName: 'Gulnora',
      note: 'Shanba kungi sinov darsini ma\u2018qul ko\u2018rdi.',
    ),
    ReceptionLeadView(
      id: 'lead-03',
      studentName: 'Samandar Tursunov',
      guardianName: 'Dilfuza Tursunova',
      phone: '+998 99 662 91 40',
      course: 'Fizika · intensiv',
      source: 'Veb-sayt',
      stage: LeadStage.trialBooked,
      createdAt: DateTime.utc(2026, 7, 15, 16, 40),
      nextContactAt: DateTime.utc(2026, 7, 18, 8, 30),
      assigneeName: 'Gulnora',
    ),
    ReceptionLeadView(
      id: 'lead-04',
      studentName: 'Zilola Kamolova',
      guardianName: 'Komil Kamolov',
      phone: '+998 97 440 28 11',
      course: 'IELTS Foundation',
      source: 'Telegram',
      stage: LeadStage.tested,
      createdAt: DateTime.utc(2026, 7, 14, 10, 15),
      nextContactAt: DateTime.utc(2026, 7, 17, 14, 0),
      assigneeName: 'Madinabonu',
      note: 'Daraja A2. B1 guruhiga tavsiya qilindi.',
    ),
  ];

  @override
  StaffWorkspaceLoad get loadState => _loadState;

  @override
  String? get errorMessage => _errorMessage;

  @override
  UnmodifiableListView<ReceptionLeadView> get leads =>
      UnmodifiableListView(_leads);

  @override
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  @override
  Future<void> refresh() async {
    _loadState = StaffWorkspaceLoad.loading;
    _errorMessage = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _loadState = _leads.isEmpty
        ? StaffWorkspaceLoad.empty
        : StaffWorkspaceLoad.ready;
    _lastRefreshedAt = _now();
    notifyListeners();
  }

  @override
  Future<ReceptionLeadView> createLead(ReceptionLeadDraft draft) async {
    final createdAt = _now();
    final lead = ReceptionLeadView(
      id: 'lead-${createdAt.microsecondsSinceEpoch}',
      studentName: draft.studentName.trim(),
      guardianName: draft.guardianName.trim(),
      phone: draft.phone.trim(),
      course: draft.course.trim(),
      source: draft.source.trim(),
      stage: LeadStage.newLead,
      createdAt: createdAt,
      nextContactAt: createdAt.add(const Duration(minutes: 15)),
    );
    _leads.insert(0, lead);
    _loadState = StaffWorkspaceLoad.ready;
    notifyListeners();
    return lead;
  }

  @override
  Future<void> recordCall(String leadId) async {
    final index = _leads.indexWhere((lead) => lead.id == leadId);
    if (index < 0) return;
    final lead = _leads[index];
    final calledAt = _now();
    _leads[index] = lead.copyWith(
      stage: lead.stage == LeadStage.newLead ? LeadStage.contacted : lead.stage,
      lastContactAt: calledAt,
      nextContactAt: calledAt.add(const Duration(days: 1)),
    );
    notifyListeners();
  }

  @override
  Future<void> advanceLead(String leadId) async {
    final index = _leads.indexWhere((lead) => lead.id == leadId);
    if (index < 0) return;
    final next = _leads[index].stage.next;
    if (next == null) return;
    _leads[index] = _leads[index].copyWith(stage: next);
    notifyListeners();
  }

  @override
  Future<void> assignLead(String leadId, String assigneeName) async {
    final index = _leads.indexWhere((lead) => lead.id == leadId);
    if (index < 0) return;
    _leads[index] = _leads[index].copyWith(assigneeName: assigneeName);
    notifyListeners();
  }

  @override
  Future<void> addLeadNote(String leadId, String note) async {
    final cleaned = note.trim();
    if (cleaned.isEmpty) return;
    final index = _leads.indexWhere((lead) => lead.id == leadId);
    if (index < 0) return;
    _leads[index] = _leads[index].copyWith(note: cleaned);
    notifyListeners();
  }
}

final ReceptionWorkspaceStore receptionWorkspaceStore =
    DemoReceptionWorkspaceStore();
final StaffWorkspaceRefreshStore staffTodayRefreshStore =
    StaffWorkspaceRefreshStore();
final StaffWorkspaceRefreshStore auditWorkspaceRefreshStore =
    StaffWorkspaceRefreshStore();
