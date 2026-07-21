import 'package:flutter/foundation.dart';

import '../../data/api/api_models.dart';
import '../../data/api/backend_core.dart';
import '../../data/api/starforge_api.dart';
import '../../data/models.dart';

@immutable
class StaffOperationModule {
  const StaffOperationModule({
    required this.id,
    required this.title,
    required this.description,
    required this.path,
    required this.iconCodePoint,
    required this.requiredCapability,
    this.actions = const [],
  });

  final String id;
  final String title;
  final String description;
  final String path;
  final int iconCodePoint;
  final StaffCapability requiredCapability;
  final List<StaffRecordAction> actions;

  bool isVisibleFor(StaffRole role) => role.can(requiredCapability);
}

@immutable
class StaffRecordAction {
  const StaffRecordAction({
    required this.id,
    required this.label,
    required this.pathSuffix,
    this.body = const {},
    this.destructive = false,
  });

  final String id;
  final String label;
  final String pathSuffix;
  final BackendJson body;
  final bool destructive;
}

/// Staff-facing modules that exist in the production backend but do not need a
/// bespoke mobile workflow. The server remains authoritative: opening a module
/// can return a calm role-unavailable state without affecting other modules.
const staffOperationModules = <StaffOperationModule>[
  StaffOperationModule(
    id: 'rules',
    title: 'Rules to acknowledge',
    description: 'Read and acknowledge policies assigned to you.',
    path: '/api/v1/rulebook/rules/pending/',
    iconCodePoint: 0xe873,
    requiredCapability: StaffCapability.acknowledgeStaffRules,
    actions: [
      StaffRecordAction(
        id: 'acknowledge',
        label: 'Acknowledge',
        pathSuffix: 'acknowledge/',
      ),
    ],
  ),
  StaffOperationModule(
    id: 'cover',
    title: 'Lesson cover',
    description: 'View cover requests and claim an open lesson.',
    path: '/api/v1/cover/',
    iconCodePoint: 0xf04bb,
    requiredCapability: StaffCapability.viewLessonCover,
    actions: [
      StaffRecordAction(
        id: 'claim',
        label: 'Claim lesson',
        pathSuffix: 'claim/',
      ),
      StaffRecordAction(
        id: 'cancel',
        label: 'Cancel request',
        pathSuffix: 'cancel/',
        destructive: true,
      ),
    ],
  ),
  StaffOperationModule(
    id: 'meetings',
    title: 'Meetings',
    description: 'Upcoming staff meetings and your RSVP.',
    path: '/api/v1/meetings/upcoming/',
    iconCodePoint: 0xf233,
    requiredCapability: StaffCapability.viewStaffMeetings,
    actions: [
      StaffRecordAction(
        id: 'accept',
        label: 'Accept',
        pathSuffix: 'respond/',
        body: {'response': 'accepted'},
      ),
      StaffRecordAction(
        id: 'decline',
        label: 'Decline',
        pathSuffix: 'respond/',
        body: {'response': 'declined'},
      ),
    ],
  ),
  StaffOperationModule(
    id: 'approvals',
    title: 'My requests',
    description: 'Track approval and reimbursement requests.',
    path: '/api/v1/approvals/requests/',
    iconCodePoint: 0xf56f,
    requiredCapability: StaffCapability.viewOwnRequests,
    actions: [
      StaffRecordAction(
        id: 'cancel',
        label: 'Cancel my request',
        pathSuffix: 'cancel/',
        destructive: true,
      ),
    ],
  ),
  StaffOperationModule(
    id: 'achievements',
    title: 'Achievements',
    description: 'Your approved recognition and progress.',
    path: '/api/v1/achievements/mine/',
    iconCodePoint: 0xe8f6,
    requiredCapability: StaffCapability.viewAchievements,
  ),
  StaffOperationModule(
    id: 'rewards',
    title: 'Rewards',
    description: 'Reward grants assigned to your staff account.',
    path: '/api/v1/rewards/grants/mine/',
    iconCodePoint: 0xe8b1,
    requiredCapability: StaffCapability.viewRewards,
  ),
  StaffOperationModule(
    id: 'loans',
    title: 'Staff loans',
    description: 'Loan balances, terms, and repayments in your scope.',
    path: '/api/v1/loans/',
    iconCodePoint: 0xe926,
    requiredCapability: StaffCapability.viewStaffLoans,
  ),
  StaffOperationModule(
    id: 'procurement',
    title: 'Procurement',
    description: 'Purchase requests and their current status.',
    path: '/api/v1/procurement/',
    iconCodePoint: 0xe8cc,
    requiredCapability: StaffCapability.viewProcurement,
  ),
  StaffOperationModule(
    id: 'exams',
    title: 'Exams',
    description: 'Exams that are visible to your teaching role.',
    path: '/api/v1/academics/exams/',
    iconCodePoint: 0xe80c,
    requiredCapability: StaffCapability.viewAcademicRecords,
  ),
  StaffOperationModule(
    id: 'grades',
    title: 'Grades',
    description: 'Published and working grades in your scope.',
    path: '/api/v1/academics/grades/',
    iconCodePoint: 0xef6e,
    requiredCapability: StaffCapability.viewAcademicRecords,
  ),
  StaffOperationModule(
    id: 'warnings',
    title: 'Academic warnings',
    description: 'Students who may need timely teaching support.',
    path: '/api/v1/academics/warnings/',
    iconCodePoint: 0xe002,
    requiredCapability: StaffCapability.viewAcademicRecords,
  ),
  StaffOperationModule(
    id: 'honor-roll',
    title: 'Honor roll',
    description: 'High-performing students in the visible scope.',
    path: '/api/v1/academics/honor-roll/',
    iconCodePoint: 0xea23,
    requiredCapability: StaffCapability.viewAcademicRecords,
  ),
  StaffOperationModule(
    id: 'students',
    title: 'Student directory',
    description: 'Role-scoped student records for teaching and reception.',
    path: '/api/v1/students/',
    iconCodePoint: 0xe7fb,
    requiredCapability: StaffCapability.viewStudentDirectory,
  ),
  StaffOperationModule(
    id: 'teachers',
    title: 'Teacher directory',
    description: 'Teacher contacts and teaching records in your scope.',
    path: '/api/v1/teachers/',
    iconCodePoint: 0xe80c,
    requiredCapability: StaffCapability.viewTeacherDirectory,
  ),
  StaffOperationModule(
    id: 'payments',
    title: 'Payment status',
    description: 'Reception-safe payment records exposed by the server.',
    path: '/api/v1/payments/',
    iconCodePoint: 0xef63,
    requiredCapability: StaffCapability.viewPaymentStatus,
  ),
  StaffOperationModule(
    id: 'reports',
    title: 'Reports',
    description: 'Generated reports and scheduled runs in your scope.',
    path: '/api/v1/reports/runs/',
    iconCodePoint: 0xe24d,
    requiredCapability: StaffCapability.viewReports,
  ),
  StaffOperationModule(
    id: 'risk',
    title: 'Student risk signals',
    description: 'Server-computed intervention signals for authorized staff.',
    path: '/api/v1/intelligence/risk/',
    iconCodePoint: 0xe6e1,
    requiredCapability: StaffCapability.viewStudentRiskSignals,
  ),
  StaffOperationModule(
    id: 'placement',
    title: 'Placement proposals',
    description: 'Placement recommendations awaiting staff follow-up.',
    path: '/api/v1/placement/proposals/',
    iconCodePoint: 0xe55f,
    requiredCapability: StaffCapability.viewPlacementProposals,
  ),
  StaffOperationModule(
    id: 'campaigns',
    title: 'Campaigns',
    description: 'Reception and outreach campaigns in your scope.',
    path: '/api/v1/campaigns/',
    iconCodePoint: 0xe3f4,
    requiredCapability: StaffCapability.viewCampaigns,
  ),
  StaffOperationModule(
    id: 'sales',
    title: 'Sales',
    description: 'Role-scoped sales records and statuses.',
    path: '/api/v1/sales/',
    iconCodePoint: 0xe8d1,
    requiredCapability: StaffCapability.viewSales,
  ),
  StaffOperationModule(
    id: 'card-scans',
    title: 'Card scans',
    description: 'Recent access and attendance card scans.',
    path: '/api/v1/cards/scans/',
    iconCodePoint: 0xe870,
    requiredCapability: StaffCapability.viewCardScans,
  ),
];

StaffOperationModule? staffOperationModuleById(String id) =>
    staffOperationModules.where((item) => item.id == id).firstOrNull;

class StaffOperationsController extends ChangeNotifier {
  StaffOperationsController({
    required this.api,
    required this.module,
    this.accountTypeSlug = '',
  });

  final StarforgeApi api;
  final StaffOperationModule module;
  final String accountTypeSlug;
  final List<BackendJson> _records = [];

  bool _loading = false;
  bool _loadingMore = false;
  bool _available = true;
  String? _error;
  int? _errorStatusCode;
  int _page = 1;
  bool _hasNext = false;

  List<BackendJson> get records => List.unmodifiable(_records);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get available => _available;
  String? get error => _error;
  bool get accessDenied => _errorStatusCode == 403;
  bool get endpointUnavailable => _errorStatusCode == 404;
  bool get hasNext => _hasNext;

  /// Keeps actions that are already impossible for the record's current
  /// lifecycle state out of the UI. Ownership and permission are still
  /// re-checked by the server when the action is submitted.
  List<StaffRecordAction> actionsFor(BackendJson record) {
    final status = backendString(record['status']).toLowerCase();
    return List.unmodifiable(
      module.actions.where((action) {
        if (module.id == 'approvals' &&
            action.id == 'cancel' &&
            accountTypeSlug.toLowerCase().contains('cashier')) {
          return false;
        }
        return switch (module.id) {
          'cover' =>
            status == 'open' &&
                (action.id != 'claim' || backendBool(record['pool'])),
          'meetings' => status == 'scheduled',
          'approvals' => status == 'pending',
          _ => true,
        };
      }),
    );
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _errorStatusCode = null;
    notifyListeners();
    try {
      final result = await api.get(
        module.path,
        query: const {'page': 1, 'page_size': 100},
      );
      _records
        ..clear()
        ..addAll(_recordsFrom(result.data));
      _page = 1;
      _hasNext = _hasNextFrom(result.data, result.pagination);
      _available = true;
    } on ApiException catch (error) {
      _errorStatusCode = error.statusCode;
      _available = error.statusCode != 403 && error.statusCode != 404;
      _error = error.message;
      if (error.statusCode == 403) {
        _records.clear();
        _hasNext = false;
      }
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final result = await api.get(
        module.path,
        query: {'page': nextPage, 'page_size': 100},
      );
      final known = {for (final item in _records) _recordIdentity(item): true};
      for (final item in _recordsFrom(result.data)) {
        if (!known.containsKey(_recordIdentity(item))) _records.add(item);
      }
      _page = nextPage;
      _hasNext = _hasNextFrom(result.data, result.pagination);
    } on ApiException catch (error) {
      _errorStatusCode = error.statusCode;
      _available = error.statusCode != 403 && error.statusCode != 404;
      _error = error.message;
      if (error.statusCode == 403) {
        _records.clear();
        _hasNext = false;
      }
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> perform(BackendJson record, StaffRecordAction action) async {
    final id = backendNullableInt(record['id']);
    if (id == null) throw StateError('This record has no server id.');
    try {
      await api.post(
        _actionPath(module, id, action.pathSuffix),
        body: action.body,
      );
    } on ApiException catch (error) {
      _errorStatusCode = error.statusCode;
      _available = error.statusCode != 403 && error.statusCode != 404;
      _error = error.message;
      if (error.statusCode == 403) {
        _records.clear();
        _hasNext = false;
      }
      notifyListeners();
      rethrow;
    }
    await refresh();
  }

  static List<BackendJson> _recordsFrom(Object? data) {
    if (data is List) return backendMaps(data);
    if (data is Map) {
      final map = backendMap(data);
      for (final key in const ['results', 'items', 'records']) {
        final nested = map[key];
        if (nested is List) return backendMaps(nested);
      }
      final nestedData = map['data'];
      if (nestedData is List || nestedData is Map) {
        return _recordsFrom(nestedData);
      }
      if (_isPaginationOnly(map)) return const [];
      return [map];
    }
    return const [];
  }

  static bool _hasNextFrom(Object? data, Object? pagination) {
    final normalizedPagination = backendMap(pagination);
    if (normalizedPagination.containsKey('has_next')) {
      return backendBool(normalizedPagination['has_next']);
    }
    final map = backendMap(data);
    if (map.containsKey('has_next')) return backendBool(map['has_next']);
    final next = map['next'];
    if (next is String) return next.trim().isNotEmpty;
    return next != null && next != false;
  }

  static bool _isPaginationOnly(BackendJson map) {
    const metadata = {
      'count',
      'page',
      'page_size',
      'pages',
      'next',
      'previous',
      'has_next',
      'has_previous',
      'results',
      'items',
      'records',
    };
    return map.keys.every(metadata.contains);
  }
}

String _recordIdentity(BackendJson record) =>
    backendString(record['id'], fallback: record.toString());

String _actionPath(StaffOperationModule module, int id, String suffix) {
  final collection = switch (module.id) {
    'rules' => '/api/v1/rulebook/rules/',
    'cover' => '/api/v1/cover/',
    'meetings' => '/api/v1/meetings/',
    'approvals' => '/api/v1/approvals/requests/',
    _ => module.path,
  };
  return '$collection$id/$suffix';
}
