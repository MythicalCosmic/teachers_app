import 'package:flutter/foundation.dart';

import '../../data/api/api_models.dart';
import '../../data/api/backend_core.dart';
import '../../data/api/starforge_api.dart';

@immutable
class StaffOperationModule {
  const StaffOperationModule({
    required this.id,
    required this.title,
    required this.description,
    required this.path,
    required this.iconCodePoint,
    this.actions = const [],
  });

  final String id;
  final String title;
  final String description;
  final String path;
  final int iconCodePoint;
  final List<StaffRecordAction> actions;
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
  ),
  StaffOperationModule(
    id: 'rewards',
    title: 'Rewards',
    description: 'Reward grants assigned to your staff account.',
    path: '/api/v1/rewards/grants/mine/',
    iconCodePoint: 0xe8b1,
  ),
  StaffOperationModule(
    id: 'loans',
    title: 'Staff loans',
    description: 'Loan balances, terms, and repayments in your scope.',
    path: '/api/v1/loans/',
    iconCodePoint: 0xe926,
  ),
  StaffOperationModule(
    id: 'procurement',
    title: 'Procurement',
    description: 'Purchase requests and their current status.',
    path: '/api/v1/procurement/',
    iconCodePoint: 0xe8cc,
  ),
  StaffOperationModule(
    id: 'exams',
    title: 'Exams',
    description: 'Exams that are visible to your teaching role.',
    path: '/api/v1/academics/exams/',
    iconCodePoint: 0xe80c,
  ),
  StaffOperationModule(
    id: 'grades',
    title: 'Grades',
    description: 'Published and working grades in your scope.',
    path: '/api/v1/academics/grades/',
    iconCodePoint: 0xef6e,
  ),
  StaffOperationModule(
    id: 'warnings',
    title: 'Academic warnings',
    description: 'Students who may need timely teaching support.',
    path: '/api/v1/academics/warnings/',
    iconCodePoint: 0xe002,
  ),
  StaffOperationModule(
    id: 'honor-roll',
    title: 'Honor roll',
    description: 'High-performing students in the visible scope.',
    path: '/api/v1/academics/honor-roll/',
    iconCodePoint: 0xea23,
  ),
  StaffOperationModule(
    id: 'students',
    title: 'Student directory',
    description: 'Role-scoped student records for teaching and reception.',
    path: '/api/v1/students/',
    iconCodePoint: 0xe7fb,
  ),
  StaffOperationModule(
    id: 'teachers',
    title: 'Teacher directory',
    description: 'Teacher contacts and teaching records in your scope.',
    path: '/api/v1/teachers/',
    iconCodePoint: 0xe80c,
  ),
  StaffOperationModule(
    id: 'payments',
    title: 'Payment status',
    description: 'Reception-safe payment records exposed by the server.',
    path: '/api/v1/payments/',
    iconCodePoint: 0xef63,
  ),
  StaffOperationModule(
    id: 'reports',
    title: 'Reports',
    description: 'Generated reports and scheduled runs in your scope.',
    path: '/api/v1/reports/runs/',
    iconCodePoint: 0xe24d,
  ),
  StaffOperationModule(
    id: 'risk',
    title: 'Student risk signals',
    description: 'Server-computed intervention signals for authorized staff.',
    path: '/api/v1/intelligence/risk/',
    iconCodePoint: 0xe6e1,
  ),
  StaffOperationModule(
    id: 'placement',
    title: 'Placement proposals',
    description: 'Placement recommendations awaiting staff follow-up.',
    path: '/api/v1/placement/proposals/',
    iconCodePoint: 0xe55f,
  ),
  StaffOperationModule(
    id: 'campaigns',
    title: 'Campaigns',
    description: 'Reception and outreach campaigns in your scope.',
    path: '/api/v1/campaigns/',
    iconCodePoint: 0xe3f4,
  ),
  StaffOperationModule(
    id: 'sales',
    title: 'Sales',
    description: 'Role-scoped sales records and statuses.',
    path: '/api/v1/sales/',
    iconCodePoint: 0xe8d1,
  ),
  StaffOperationModule(
    id: 'card-scans',
    title: 'Card scans',
    description: 'Recent access and attendance card scans.',
    path: '/api/v1/cards/scans/',
    iconCodePoint: 0xe870,
  ),
];

StaffOperationModule? staffOperationModuleById(String id) =>
    staffOperationModules.where((item) => item.id == id).firstOrNull;

class StaffOperationsController extends ChangeNotifier {
  StaffOperationsController({required this.api, required this.module});

  final StarforgeApi api;
  final StaffOperationModule module;
  final List<BackendJson> _records = [];

  bool _loading = false;
  bool _loadingMore = false;
  bool _available = true;
  String? _error;
  int _page = 1;
  bool _hasNext = false;

  List<BackendJson> get records => List.unmodifiable(_records);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get available => _available;
  String? get error => _error;
  bool get hasNext => _hasNext;

  /// Keeps actions that are already impossible for the record's current
  /// lifecycle state out of the UI. Ownership and permission are still
  /// re-checked by the server when the action is submitted.
  List<StaffRecordAction> actionsFor(BackendJson record) {
    final status = backendString(record['status']).toLowerCase();
    return List.unmodifiable(
      module.actions.where((action) {
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
      _hasNext = backendBool(backendMap(result.pagination)['has_next']);
      _available = true;
    } on ApiException catch (error) {
      _available = error.statusCode != 403 && error.statusCode != 404;
      _error = error.message;
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
      _hasNext = backendBool(backendMap(result.pagination)['has_next']);
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> perform(BackendJson record, StaffRecordAction action) async {
    final id = backendNullableInt(record['id']);
    if (id == null) throw StateError('This record has no server id.');
    await api.post(
      _actionPath(module, id, action.pathSuffix),
      body: action.body,
    );
    await refresh();
  }

  static List<BackendJson> _recordsFrom(Object? data) {
    if (data is List) return backendMaps(data);
    if (data is Map) return [backendMap(data)];
    return const [];
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
