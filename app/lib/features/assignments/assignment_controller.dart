import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'assignment_models.dart';
import 'assignment_storage.dart';

class AssignmentController extends ChangeNotifier {
  AssignmentController({AssignmentStorage? storage, DateTime Function()? clock})
    : _storage = storage ?? SharedPreferencesAssignmentStorage(),
      _clock = clock ?? DateTime.now;

  static final AssignmentController shared = AssignmentController();

  final AssignmentStorage _storage;
  final DateTime Function() _clock;
  final List<StaffAssignment> _assignments = [];
  final List<AssignmentSubmission> _submissions = [];

  String? _ownerId;
  bool _initialized = false;
  bool _isRestoring = false;
  Object? _restoreError;
  int _restoreVersion = 0;
  int _sequence = 0;
  Future<void> _restored = Future<void>.value();
  Future<void> _writeQueue = Future<void>.value();

  String? get ownerId => _ownerId;
  bool get isRestoring => _isRestoring;
  Object? get restoreError => _restoreError;
  Future<void> get restored => _restored;
  List<StaffAssignment> get assignments => List.unmodifiable(_assignments);
  List<AssignmentSubmission> get submissions => List.unmodifiable(_submissions);
  List<AssignmentCohort> get availableCohorts => _cohorts;

  void initialize({required String ownerId}) {
    final cleanOwner = ownerId.trim().isEmpty ? 'demo-teacher' : ownerId.trim();
    if (_initialized && _ownerId == cleanOwner) return;
    _initialized = true;
    _ownerId = cleanOwner;
    _restoreVersion++;
    _restoreError = null;
    _isRestoring = true;
    _loadSeed(cleanOwner);
    notifyListeners();
    _restored = _restore(cleanOwner, _restoreVersion);
  }

  Future<void> retryRestore() async {
    final owner = _ownerId;
    if (owner == null || _isRestoring) return;
    _restoreVersion++;
    _restoreError = null;
    _isRestoring = true;
    notifyListeners();
    _restored = _restore(owner, _restoreVersion);
    await _restored;
  }

  StaffAssignment? assignmentById(String? id) {
    if (id == null) return null;
    return _assignments.where((item) => item.id == id).firstOrNull;
  }

  AssignmentSubmission? submissionById(
    String? assignmentId,
    String? studentId,
  ) {
    if (assignmentId == null || studentId == null) return null;
    return _submissions
        .where(
          (item) =>
              item.assignmentId == assignmentId && item.studentId == studentId,
        )
        .firstOrNull;
  }

  List<AssignmentSubmission> submissionsFor(String assignmentId) => _submissions
      .where((item) => item.assignmentId == assignmentId)
      .toList(growable: false);

  StaffAssignment? get featuredAssignment {
    if (_assignments.isEmpty) return null;
    return _assignments.firstWhere(
      (item) => progressFor(item.id) == AssignmentProgressState.needsFeedback,
      orElse: () => _assignments.first,
    );
  }

  int submittedCount(String assignmentId) =>
      submissionsFor(assignmentId).where((item) => item.isSubmitted).length;

  int feedbackCompleteCount(String assignmentId) =>
      submissionsFor(assignmentId).where((item) => item.hasFeedback).length;

  int needsFeedbackCount(String assignmentId) =>
      submissionsFor(assignmentId).where((item) => item.needsFeedback).length;

  int? averageGrade(String assignmentId) {
    final grades = submissionsFor(
      assignmentId,
    ).map((item) => item.grade).whereType<int>().toList();
    if (grades.isEmpty) return null;
    return (grades.reduce((a, b) => a + b) / grades.length).round();
  }

  AssignmentProgressState progressFor(String assignmentId) {
    final entries = submissionsFor(assignmentId);
    if (entries.any((item) => item.needsFeedback)) {
      return AssignmentProgressState.needsFeedback;
    }
    if (entries.isNotEmpty && entries.every((item) => item.hasFeedback)) {
      return AssignmentProgressState.complete;
    }
    return AssignmentProgressState.collecting;
  }

  Future<StaffAssignment> createAssignment({
    required String title,
    required String instructions,
    required String cohortId,
    required AssignmentResponseType responseType,
    required DateTime dueAt,
  }) async {
    _ensureReady();
    final cleanTitle = title.trim();
    final cleanInstructions = instructions.trim();
    if (cleanTitle.length < 4) {
      throw ArgumentError('Assignment title is too short.');
    }
    if (cleanInstructions.length < 8) {
      throw ArgumentError('Assignment instructions are too short.');
    }
    final cohort = _cohorts.where((item) => item.id == cohortId).firstOrNull;
    if (cohort == null) throw ArgumentError('Unknown cohort.');
    if (!dueAt.isAfter(_clock())) {
      throw ArgumentError('The due date must be in the future.');
    }
    final now = _clock();
    final assignment = StaffAssignment(
      id: 'assignment-${now.microsecondsSinceEpoch}-${_sequence++}',
      ownerId: _ownerId!,
      title: cleanTitle,
      instructions: cleanInstructions,
      cohortId: cohort.id,
      cohortName: cohort.name,
      responseType: responseType,
      dueAt: dueAt,
      createdAt: now,
    );
    _assignments.insert(0, assignment);
    _submissions.addAll([
      for (final student in cohort.students)
        AssignmentSubmission(
          assignmentId: assignment.id,
          studentId: student.id,
          studentName: student.name,
          status: AssignmentSubmissionStatus.notSubmitted,
        ),
    ]);
    notifyListeners();
    await _persist();
    return assignment;
  }

  Future<void> sendReminder({
    required String assignmentId,
    required String studentId,
  }) async {
    _ensureReady();
    final index = _submissionIndex(assignmentId, studentId);
    final current = _submissions[index];
    if (current.status != AssignmentSubmissionStatus.notSubmitted) {
      throw StateError('Only students who have not submitted can be reminded.');
    }
    _submissions[index] = current.copyWith(reminderSentAt: _clock());
    notifyListeners();
    await _persist();
  }

  Future<void> saveFeedback({
    required String assignmentId,
    required String studentId,
    required String feedback,
    required AssignmentFeedbackStep step,
    required int grade,
  }) async {
    _ensureReady();
    final cleanFeedback = feedback.trim();
    if (cleanFeedback.length < 8) {
      throw ArgumentError('Feedback is too short.');
    }
    if (grade < 0 || grade > 100) {
      throw RangeError.range(grade, 0, 100, 'grade');
    }
    final index = _submissionIndex(assignmentId, studentId);
    final current = _submissions[index];
    if (!current.isSubmitted) {
      throw StateError('Feedback cannot be sent before a submission exists.');
    }
    final status = switch (step) {
      AssignmentFeedbackStep.ready => AssignmentSubmissionStatus.feedbackShared,
      AssignmentFeedbackStep.revise =>
        AssignmentSubmissionStatus.revisionRequested,
      AssignmentFeedbackStep.conference =>
        AssignmentSubmissionStatus.conferenceRequested,
    };
    _submissions[index] = current.copyWith(
      status: status,
      feedback: cleanFeedback,
      feedbackStep: step,
      feedbackSentAt: _clock(),
      grade: grade,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> flushPersistence() async {
    await _restored;
    await _writeQueue;
  }

  int _submissionIndex(String assignmentId, String studentId) {
    final index = _submissions.indexWhere(
      (item) =>
          item.assignmentId == assignmentId && item.studentId == studentId,
    );
    if (index < 0) throw StateError('Submission not found.');
    return index;
  }

  void _ensureReady() {
    if (!_initialized || _ownerId == null) {
      throw StateError('Assignment workspace is not initialized.');
    }
    if (_isRestoring) {
      throw StateError('Assignments are still restoring saved data.');
    }
    if (_restoreError != null) {
      throw StateError('Assignment data could not be restored.');
    }
  }

  Future<void> _restore(String ownerId, int version) async {
    try {
      final raw = await _storage.read(ownerId);
      if (_ownerId != ownerId || _restoreVersion != version) return;
      if (raw == null || raw.trim().isEmpty) {
        await _persist();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Invalid assignment data.');
      }
      final snapshot = AssignmentWorkspaceSnapshot.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (snapshot.assignments.isEmpty) {
        throw const FormatException('Assignment data is empty.');
      }
      _assignments
        ..clear()
        ..addAll(snapshot.assignments);
      _submissions
        ..clear()
        ..addAll(snapshot.submissions);
    } on Object catch (error) {
      if (_ownerId == ownerId && _restoreVersion == version) {
        _restoreError = error;
      }
    } finally {
      if (_ownerId == ownerId && _restoreVersion == version) {
        _isRestoring = false;
        notifyListeners();
      }
    }
  }

  Future<void> _persist() {
    final owner = _ownerId;
    if (owner == null) return Future<void>.value();
    final payload = jsonEncode(
      AssignmentWorkspaceSnapshot(
        assignments: _assignments,
        submissions: _submissions,
      ).toJson(),
    );
    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _storage.write(owner, payload));
    return _writeQueue;
  }

  void _loadSeed(String ownerId) {
    final now = _clock();
    _assignments
      ..clear()
      ..addAll(_seedAssignments(ownerId, now));
    _submissions
      ..clear()
      ..addAll(_seedSubmissions(now));
  }
}

const _cohorts = [
  AssignmentCohort(
    id: 'cohort-9b-algebra',
    name: '9-B Algebra',
    students: [
      AssignmentStudent(id: 'student-akmal-akbarov', name: 'Akbarov Akmal'),
      AssignmentStudent(id: 'student-madina-azizova', name: 'Azizova Madina'),
      AssignmentStudent(id: 'student-sherzod-bakirov', name: 'Bakirov Sherzod'),
      AssignmentStudent(
        id: 'student-sevinch-davronova',
        name: 'Davronova Sevinch',
      ),
      AssignmentStudent(id: 'student-otabek-eshmatov', name: 'Eshmatov Otabek'),
      AssignmentStudent(id: 'student-zilola-halimova', name: 'Halimova Zilola'),
    ],
  ),
  AssignmentCohort(
    id: 'cohort-9a-algebra',
    name: '9-A Algebra',
    students: [
      AssignmentStudent(id: 'student-zarina-halimova', name: 'Halimova Zarina'),
      AssignmentStudent(id: 'student-diyor-nazarov', name: 'Nazarov Diyor'),
      AssignmentStudent(id: 'student-lola-saidova', name: 'Saidova Lola'),
      AssignmentStudent(id: 'student-kamron-umarov', name: 'Umarov Kamron'),
      AssignmentStudent(id: 'student-malika-yusupova', name: 'Yusupova Malika'),
    ],
  ),
  AssignmentCohort(
    id: 'cohort-10v-geometry',
    name: '10-V Geometriya',
    students: [
      AssignmentStudent(id: 'student-aziza-aliyeva', name: 'Aliyeva Aziza'),
      AssignmentStudent(id: 'student-bekzod-erkinov', name: 'Erkinov Bekzod'),
      AssignmentStudent(
        id: 'student-shahnoza-olimova',
        name: 'Olimova Shahnoza',
      ),
      AssignmentStudent(id: 'student-jasur-rahimov', name: 'Rahimov Jasur'),
      AssignmentStudent(
        id: 'student-samira-tursunova',
        name: 'Tursunova Samira',
      ),
    ],
  ),
  AssignmentCohort(
    id: 'cohort-11b-prep',
    name: '11-B Tayyorlov',
    students: [
      AssignmentStudent(
        id: 'student-miraziz-abdullayev',
        name: 'Abdullayev Miraziz',
      ),
      AssignmentStudent(
        id: 'student-nilufar-hasanova',
        name: 'Hasanova Nilufar',
      ),
      AssignmentStudent(id: 'student-sardor-karimov', name: 'Karimov Sardor'),
      AssignmentStudent(id: 'student-sevara-qodirova', name: 'Qodirova Sevara'),
    ],
  ),
];

List<StaffAssignment> _seedAssignments(String ownerId, DateTime now) => [
  StaffAssignment(
    id: 'assignment-quadratic-9b',
    ownerId: ownerId,
    title: 'Kvadrat tenglamalar',
    instructions:
        '1–12-mashqlarni yeching va har bir yechim qadamini izohlang.',
    cohortId: 'cohort-9b-algebra',
    cohortName: '9-B Algebra',
    responseType: AssignmentResponseType.document,
    dueAt: now.add(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(days: 3)),
  ),
  StaffAssignment(
    id: 'assignment-functions-9a',
    ownerId: ownerId,
    title: 'Funksiyalar grafigi',
    instructions:
        'Grafik xususiyatlarini matnda tushuntiring va xulosani yozing.',
    cohortId: 'cohort-9a-algebra',
    cohortName: '9-A Algebra',
    responseType: AssignmentResponseType.text,
    dueAt: now.add(const Duration(days: 3)),
    createdAt: now.subtract(const Duration(days: 2)),
  ),
  StaffAssignment(
    id: 'assignment-geometry-10v',
    ownerId: ownerId,
    title: 'Yozma ish · Geometriya',
    instructions:
        'Chizmani aniq belgilang va tayyor ishning suratini yuboring.',
    cohortId: 'cohort-10v-geometry',
    cohortName: '10-V Geometriya',
    responseType: AssignmentResponseType.photo,
    dueAt: now.add(const Duration(days: 2)),
    createdAt: now.subtract(const Duration(days: 4)),
  ),
  StaffAssignment(
    id: 'assignment-olympiad-11b',
    ownerId: ownerId,
    title: 'Olimpiada mashqlari',
    instructions: 'Tanlangan uch masala yechimini bitta PDF faylda topshiring.',
    cohortId: 'cohort-11b-prep',
    cohortName: '11-B Tayyorlov',
    responseType: AssignmentResponseType.document,
    dueAt: now.subtract(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(days: 8)),
  ),
];

List<AssignmentSubmission> _seedSubmissions(DateTime now) => [
  AssignmentSubmission(
    assignmentId: 'assignment-quadratic-9b',
    studentId: 'student-akmal-akbarov',
    studentName: 'Akbarov Akmal',
    status: AssignmentSubmissionStatus.feedbackNeeded,
    submittedAt: now.subtract(const Duration(hours: 2)),
    responseText:
        'Diskriminant usuli qo‘llandi. 4-misoldagi ishora almashishi yechim varaqasida izohlangan.',
    attachment: const AssignmentAttachment(
      fileName: 'akmal_kvadrat_tenglamalar.pdf',
      mediaType: 'application/pdf',
      byteSize: 284672,
      pageCount: 3,
      summary: 'Uch sahifalik skanerlangan yechim varaqasi.',
    ),
  ),
  AssignmentSubmission(
    assignmentId: 'assignment-quadratic-9b',
    studentId: 'student-madina-azizova',
    studentName: 'Azizova Madina',
    status: AssignmentSubmissionStatus.feedbackShared,
    submittedAt: now.subtract(const Duration(days: 1, hours: 2)),
    responseText: 'Barcha 12 mashq yechildi va tekshirildi.',
    feedback: 'Yechimlar aniq. 8-misoldagi qisqa tekshiruv ayniqsa foydali.',
    feedbackStep: AssignmentFeedbackStep.ready,
    feedbackSentAt: now.subtract(const Duration(hours: 8)),
    grade: 94,
  ),
  AssignmentSubmission(
    assignmentId: 'assignment-quadratic-9b',
    studentId: 'student-sherzod-bakirov',
    studentName: 'Bakirov Sherzod',
    status: AssignmentSubmissionStatus.submitted,
    submittedAt: now.subtract(const Duration(hours: 3)),
    responseText: 'Yechimlar PDF faylga jamlandi.',
    attachment: const AssignmentAttachment(
      fileName: 'sherzod_algebra.pdf',
      mediaType: 'application/pdf',
      byteSize: 198144,
      pageCount: 2,
      summary: 'Ikki sahifalik qo‘lda yozilgan yechimlar.',
    ),
  ),
  AssignmentSubmission(
    assignmentId: 'assignment-quadratic-9b',
    studentId: 'student-sevinch-davronova',
    studentName: 'Davronova Sevinch',
    status: AssignmentSubmissionStatus.feedbackShared,
    submittedAt: now.subtract(const Duration(days: 1, hours: 4)),
    responseText: '12 mashqdan 11 tasi bajarildi.',
    feedback:
        'Mantiqiy qadamlar yaxshi. Qoldirilgan 11-mashqni keyingi darsda ko‘ramiz.',
    feedbackStep: AssignmentFeedbackStep.ready,
    feedbackSentAt: now.subtract(const Duration(hours: 10)),
    grade: 88,
  ),
  AssignmentSubmission(
    assignmentId: 'assignment-quadratic-9b',
    studentId: 'student-otabek-eshmatov',
    studentName: 'Eshmatov Otabek',
    status: AssignmentSubmissionStatus.notSubmitted,
  ),
  AssignmentSubmission(
    assignmentId: 'assignment-quadratic-9b',
    studentId: 'student-zilola-halimova',
    studentName: 'Halimova Zilola',
    status: AssignmentSubmissionStatus.feedbackNeeded,
    submittedAt: now.subtract(const Duration(hours: 1)),
    responseText: 'Mashqlar yechildi, tekshirish qismi matnda yozildi.',
  ),
  ..._seedCollecting(
    assignmentId: 'assignment-functions-9a',
    cohort: _cohorts[1],
    now: now,
    responseType: AssignmentResponseType.text,
  ),
  ..._seedCollecting(
    assignmentId: 'assignment-geometry-10v',
    cohort: _cohorts[2],
    now: now,
    responseType: AssignmentResponseType.photo,
  ),
  for (final student in _cohorts[3].students)
    AssignmentSubmission(
      assignmentId: 'assignment-olympiad-11b',
      studentId: student.id,
      studentName: student.name,
      status: AssignmentSubmissionStatus.feedbackShared,
      submittedAt: now.subtract(const Duration(days: 2)),
      responseText: 'Uchta olimpiada masalasi yechimi.',
      feedback: 'Yechim qabul qilindi. Strategiya va izohlar aniq.',
      feedbackStep: AssignmentFeedbackStep.ready,
      feedbackSentAt: now.subtract(const Duration(days: 1)),
      grade: 90,
    ),
];

List<AssignmentSubmission> _seedCollecting({
  required String assignmentId,
  required AssignmentCohort cohort,
  required DateTime now,
  required AssignmentResponseType responseType,
}) => [
  for (final entry in cohort.students.asMap().entries)
    AssignmentSubmission(
      assignmentId: assignmentId,
      studentId: entry.value.id,
      studentName: entry.value.name,
      status: entry.key < 3
          ? AssignmentSubmissionStatus.feedbackShared
          : AssignmentSubmissionStatus.notSubmitted,
      submittedAt: entry.key < 3
          ? now.subtract(Duration(hours: 10 + entry.key))
          : null,
      responseText: entry.key < 3
          ? responseType == AssignmentResponseType.text
                ? 'Grafikning o‘sish va kamayish oraliqlari matnda izohlandi.'
                : 'Chizma va yechim bosqichlari ilova tavsifida berilgan.'
          : '',
      attachment: entry.key < 3 && responseType == AssignmentResponseType.photo
          ? AssignmentAttachment(
              fileName: 'geometry_${entry.value.id}.jpg',
              mediaType: 'image/jpeg',
              byteSize: 720000 + entry.key * 18000,
              summary: 'Demo chizma surati metadata ko‘rinishida.',
            )
          : null,
      feedback: entry.key < 3
          ? 'Ish qabul qilindi va asosiy qadamlar tekshirildi.'
          : '',
      feedbackStep: entry.key < 3 ? AssignmentFeedbackStep.ready : null,
      feedbackSentAt: entry.key < 3
          ? now.subtract(Duration(hours: 4 + entry.key))
          : null,
      grade: entry.key < 3 ? 86 + entry.key * 3 : null,
    ),
];
