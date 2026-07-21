import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';
import 'package:starforge_staff/data/api/starforge_api.dart';
import 'package:starforge_staff/features/operations/staff_operations_controller.dart';

const _connection = TenantConnection(
  slug: 'staff',
  name: 'Staff tenant',
  baseUrl: 'https://staff.example',
  wsUrl: '',
  locale: 'en',
);

Future<StarforgeApi> _api(
  Future<http.Response> Function(http.Request request) handler,
) async {
  final api = StarforgeApi(
    vault: MemorySessionVault(
      const StoredSession(
        accessToken: 'staff-token',
        connection: _connection,
        deviceId: 'device-1',
      ),
    ),
    client: ApiClient(httpClient: MockClient(handler)),
  );
  await api.restore();
  return api;
}

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _me() => _json(200, {
  'success': true,
  'data': {'id': 4, 'principal_kind': 'teacher', 'full_name': 'Teacher'},
});

void main() {
  test(
    'refresh and load-more preserve page order and de-duplicate records',
    () async {
      final requests = <http.Request>[];
      final api = await _api((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/users/me/') return _me();
        final page = request.url.queryParameters['page'];
        return _json(200, {
          'success': true,
          'data': page == '2'
              ? [
                  {'id': 2, 'title': 'Duplicate'},
                  {'id': 3, 'title': 'Third'},
                ]
              : [
                  {'id': 1, 'title': 'First'},
                  {'id': 2, 'title': 'Second'},
                ],
          'pagination': {
            'page': int.tryParse(page ?? '') ?? 1,
            'page_size': 2,
            'total': 3,
            'pages': 2,
            'has_next': page != '2',
            'has_prev': page == '2',
          },
        });
      });
      final controller = StaffOperationsController(
        api: api,
        module: staffOperationModuleById('students')!,
      );

      await controller.refresh();
      expect(controller.records.map((record) => record['id']), [1, 2]);
      expect(controller.hasNext, isTrue);

      await controller.loadMore();
      expect(controller.records.map((record) => record['id']), [1, 2, 3]);
      expect(controller.hasNext, isFalse);
      expect(
        requests.where((request) => request.url.path == '/api/v1/students/'),
        hasLength(2),
      );
    },
  );

  test(
    'action uses the exact record endpoint and refreshes server state',
    () async {
      final requests = <http.Request>[];
      final api = await _api((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/users/me/') return _me();
        if (request.method == 'POST') {
          return _json(200, {
            'success': true,
            'data': {'id': 7, 'status': 'scheduled'},
          });
        }
        return _json(200, {
          'success': true,
          'data': [
            {'id': 7, 'title': 'Weekly sync', 'status': 'scheduled'},
          ],
        });
      });
      final controller = StaffOperationsController(
        api: api,
        module: staffOperationModuleById('meetings')!,
      );
      final action = controller.module.actions.first;

      await controller.perform({'id': 7, 'status': 'scheduled'}, action);

      final post = requests.singleWhere((request) => request.method == 'POST');
      expect(post.url.path, '/api/v1/meetings/7/respond/');
      expect(jsonDecode(post.body), {'response': 'accepted'});
      expect(controller.records.single['id'], 7);
    },
  );

  test(
    'unwraps nested results instead of rendering pagination as a record',
    () async {
      final api = await _api((request) async {
        if (request.url.path == '/api/v1/users/me/') return _me();
        return _json(200, {
          'success': true,
          'data': {
            'count': 1,
            'page_size': 20,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 81,
                'student_name': 'Aziza Karimova',
                'risk_level': 'medium',
              },
            ],
          },
        });
      });
      final controller = StaffOperationsController(
        api: api,
        module: staffOperationModuleById('risk')!,
      );

      await controller.refresh();

      expect(controller.records, hasLength(1));
      expect(controller.records.single['student_name'], 'Aziza Karimova');
      expect(controller.records.single.containsKey('count'), isFalse);
      expect(controller.hasNext, isFalse);
    },
  );

  test('role-denied module is isolated as unavailable', () async {
    final api = await _api((request) async {
      if (request.url.path == '/api/v1/users/me/') return _me();
      return _json(403, {
        'success': false,
        'code': 'permission_denied',
        'message': 'Not allowed for this role.',
      });
    });
    final controller = StaffOperationsController(
      api: api,
      module: staffOperationModuleById('reports')!,
    );

    await controller.refresh();

    expect(controller.available, isFalse);
    expect(controller.accessDenied, isTrue);
    expect(controller.records, isEmpty);
    expect(controller.error, 'Not allowed for this role.');
  });

  test('lifecycle-aware actions hide impossible buttons', () {
    final api = StarforgeApi(vault: MemorySessionVault());
    final cover = StaffOperationsController(
      api: api,
      module: staffOperationModuleById('cover')!,
    );
    final meeting = StaffOperationsController(
      api: api,
      module: staffOperationModuleById('meetings')!,
    );
    final approvals = StaffOperationsController(
      api: api,
      module: staffOperationModuleById('approvals')!,
    );
    final cashierApprovals = StaffOperationsController(
      api: api,
      module: staffOperationModuleById('approvals')!,
      accountTypeSlug: 'cashier',
    );

    expect(
      cover
          .actionsFor({'id': 1, 'status': 'open', 'pool': false})
          .map((action) => action.id),
      ['cancel'],
    );
    expect(
      cover
          .actionsFor({'id': 1, 'status': 'open', 'pool': true})
          .map((action) => action.id),
      ['claim', 'cancel'],
    );
    expect(cover.actionsFor({'id': 1, 'status': 'approved'}), isEmpty);
    expect(meeting.actionsFor({'id': 2, 'status': 'cancelled'}), isEmpty);
    expect(approvals.actionsFor({'id': 3, 'status': 'approved'}), isEmpty);
    expect(
      approvals
          .actionsFor({'id': 3, 'status': 'pending'})
          .map((action) => action.id),
      ['cancel'],
    );
    expect(
      cashierApprovals.actionsFor({'id': 3, 'status': 'pending'}),
      isEmpty,
    );
  });
}
