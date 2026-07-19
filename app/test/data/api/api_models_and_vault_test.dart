import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_staff/data/api/api_models.dart';
import 'package:starforge_staff/data/api/session_vault.dart';

void main() {
  test('StoredSession round-trips the token, tenant, and stable device id', () {
    const original = StoredSession(
      accessToken: 'opaque-access-token',
      deviceId: 'stable-device-id',
      connection: TenantConnection(
        slug: 'staff-center',
        name: 'Staff Center',
        baseUrl: 'https://staff-center.example',
        wsUrl: 'wss://staff-center.example/ws/notifications/',
        locale: 'en',
        logoUrl: 'https://cdn.example/logo.png',
      ),
    );

    final restored = StoredSession.decode(original.encode());

    expect(restored.accessToken, original.accessToken);
    expect(restored.deviceId, original.deviceId);
    expect(restored.connection.slug, 'staff-center');
    expect(restored.connection.baseUrl, 'https://staff-center.example');
    expect(
      restored.connection.wsUrl,
      'wss://staff-center.example/ws/notifications/',
    );
    expect(restored.connection.logoUrl, 'https://cdn.example/logo.png');
  });

  test(
    'MemorySessionVault clears the session but preserves device identity',
    () async {
      final vault = MemorySessionVault();
      await vault.writeDeviceId('stable-device-id');
      await vault.write(
        const StoredSession(
          accessToken: 'token',
          deviceId: 'stable-device-id',
          connection: TenantConnection(
            slug: 'tenant',
            name: 'Tenant',
            baseUrl: 'https://tenant.example',
            wsUrl: 'wss://tenant.example/ws/notifications/',
            locale: 'uz',
          ),
        ),
      );

      await vault.clear();

      expect(await vault.read(), isNull);
      expect(await vault.readDeviceId(), 'stable-device-id');
    },
  );

  test('ApiPage reads the production standard pagination envelope', () {
    final page = ApiPage<Map<String, Object?>>.fromEnvelope(
      [
        {'id': 1},
        {'id': 2},
      ],
      {
        'total': 8,
        'page': 2,
        'page_size': 2,
        'has_next': true,
        'has_prev': true,
      },
      (json) => json,
    );

    expect(page.items, hasLength(2));
    expect(page.page, 2);
    expect(page.pageSize, 2);
    expect(page.total, 8);
    expect(page.hasNext, isTrue);
    expect(page.hasPrevious, isTrue);
  });
}
