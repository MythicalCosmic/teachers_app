import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/api/api_client.dart';
import 'package:starforge_staff/data/api/backend_core.dart';
import 'package:starforge_staff/data/api/backend_services_api.dart';
import 'package:starforge_staff/screens/services/backend_ai_screens.dart';
import 'package:starforge_staff/screens/services/backend_audit_log_screen.dart';
import 'package:starforge_staff/screens/services/backend_content_screen.dart';
import 'package:starforge_staff/screens/services/backend_print_screens.dart';
import 'package:starforge_staff/theme/sf_theme.dart';
import 'package:starforge_staff/theme/tokens.dart';

void main() {
  Future<void> pumpService(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final colors = sfColorsFor(SfPalette.daryo);
    await tester.pumpWidget(
      SfTheme(
        colors: colors,
        palette: SfPalette.daryo,
        dark: false,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('uz'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildMaterialTheme(colors, dark: false),
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('production AI is a request center, never a fake chat composer', (
    tester,
  ) async {
    final api = BackendServicesApi(_ServiceTransport());
    await pumpService(tester, BackendAiWorkspaceScreen(api: api));

    expect(find.text('Production AI contract'), findsOneWidget);
    expect(
      find.textContaining('does not expose a general-purpose chat'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ai-composer')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production print queue explains agent-owned lifecycle', (
    tester,
  ) async {
    final api = BackendServicesApi(_ServiceTransport());
    await pumpService(tester, BackendPrintScreen(api: api));

    expect(find.text('Agent-owned queue'), findsOneWidget);
    expect(find.textContaining('no cancel or retry action'), findsOneWidget);
    expect(find.text('Cancel job'), findsNothing);
    expect(find.text('Retry job'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content upload UI never claims a link uploaded a binary', (
    tester,
  ) async {
    final api = BackendServicesApi(_ServiceTransport());
    await pumpService(tester, BackendContentScreen(api: api));

    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('Presigned upload workflow'), findsOneWidget);
    expect(
      find.textContaining('does not mean the file was uploaded'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('production media exposes video and audio playback actions', (
    tester,
  ) async {
    final api = BackendServicesApi(_ServiceTransport());
    await pumpService(tester, BackendContentScreen(api: api));

    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('Watch video'), findsOneWidget);
    expect(find.text('Play audio'), findsOneWidget);
    expect(find.text('Print'), findsNothing);
    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();
    expect(find.text('Watch video'), findsOneWidget);
    expect(find.text('Play audio'), findsNothing);
  });

  testWidgets('server-disabled AI is formally blurred and blocked', (
    tester,
  ) async {
    final api = BackendServicesApi(_ServiceTransport(aiEnabled: false));
    await pumpService(tester, BackendAiWorkspaceScreen(api: api));

    expect(find.text('AI · PAUSED'), findsOneWidget);
    expect(find.textContaining('paused by an administrator'), findsOneWidget);
    final generate = tester.widget<IconButton>(
      find.byKey(const Key('backend-ai-generate-exam')),
    );
    expect(generate.onPressed, isNull);
  });

  testWidgets('audit screen identifies the real append-only server feed', (
    tester,
  ) async {
    final api = BackendServicesApi(_ServiceTransport());
    await pumpService(
      tester,
      BackendAuditLogScreen(api: api, baseUrl: 'https://tenant.example'),
    );

    expect(find.text('Append-only server feed'), findsOneWidget);
    expect(
      find.textContaining('not local anomaly or case cards'),
      findsOneWidget,
    );
    expect(find.text('No audit entries found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _ServiceTransport implements BackendTransport {
  const _ServiceTransport({this.aiEnabled = true});

  final bool aiEnabled;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, Object?> query = const {},
  }) async => switch (path) {
    '/api/v1/content/libraries/' => _page([
      {
        'id': 1,
        'name': 'Staff library',
        'visibility': 'tenant',
        'is_active': true,
      },
    ]),
    '/api/v1/content/files/' => _page([
      {
        'id': 41,
        'title': 'Algebra walkthrough',
        'content_type': 'video/mp4',
        'size_bytes': 4096,
        'status': 'clean',
        'version': 1,
        'is_approved_teacher': true,
        'is_approved_manager': true,
        'is_downloadable': true,
      },
      {
        'id': 42,
        'title': 'Pronunciation guide',
        'content_type': 'audio/mpeg',
        'size_bytes': 2048,
        'status': 'clean',
        'version': 1,
        'is_approved_teacher': true,
        'is_approved_manager': true,
        'is_downloadable': true,
      },
    ]),
    '/api/v1/content/courses/' ||
    '/api/v1/content/modules/' ||
    '/api/v1/content/lessons/' ||
    '/api/v1/content/folders/' ||
    '/api/v1/content/materials/' ||
    '/api/v1/printing/jobs/' ||
    '/api/v1/printing/printers/' ||
    '/api/v1/ai/requests/' => _page(const []),
    '/api/v1/ai/budget/' => _response({
      'daily_token_limit': 1000,
      'monthly_token_limit': 10000,
      'tokens_used_today': 0,
      'tokens_used_month': 0,
      'is_enabled': aiEnabled,
    }),
    '/api/v1/ai/usage-report/' => _response(const []),
    '/api/v1/audit/' => ApiResponse(
      data: const [],
      pagination: const {'next': null, 'previous': null},
      statusCode: 200,
      requestId: 'widget-test',
    ),
    _ => throw StateError('Unexpected GET $path'),
  };

  @override
  Future<ApiResponse> delete(String path, {Object? body}) =>
      throw StateError('Unexpected DELETE $path');

  @override
  Future<ApiResponse> patch(String path, {Object? body}) =>
      throw StateError('Unexpected PATCH $path');

  @override
  Future<ApiResponse> post(
    String path, {
    Object? body,
    String? idempotencyKey,
  }) => throw StateError('Unexpected POST $path');

  @override
  Future<ApiResponse> put(String path, {Object? body}) =>
      throw StateError('Unexpected PUT $path');
}

ApiResponse _page(List<Object?> values) => ApiResponse(
  data: values,
  pagination: {
    'total': values.length,
    'page': 1,
    'page_size': 100,
    'pages': 1,
    'has_next': false,
    'has_prev': false,
  },
  statusCode: 200,
  requestId: 'widget-test',
);

ApiResponse _response(Object? data) => ApiResponse(
  data: data,
  pagination: null,
  statusCode: 200,
  requestId: 'widget-test',
);
