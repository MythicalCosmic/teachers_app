import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_models.dart';

abstract interface class SessionVault {
  Future<StoredSession?> read();

  Future<String?> readDeviceId();

  Future<void> write(StoredSession session);

  Future<void> writeDeviceId(String deviceId);

  Future<void> clear();
}

final class SecureSessionVault implements SessionVault {
  SecureSessionVault({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _key = 'starforge.staff.secure_session.v1';
  static const _deviceKey = 'starforge.staff.device_id.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return StoredSession.decode(raw);
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<String?> readDeviceId() => _storage.read(key: _deviceKey);

  @override
  Future<void> write(StoredSession session) =>
      _storage.write(key: _key, value: session.encode());

  @override
  Future<void> writeDeviceId(String deviceId) =>
      _storage.write(key: _deviceKey, value: deviceId);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

final class MemorySessionVault implements SessionVault {
  MemorySessionVault([this.value]);

  StoredSession? value;
  String? deviceId;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<StoredSession?> read() async => value;

  @override
  Future<String?> readDeviceId() async => deviceId ?? value?.deviceId;

  @override
  Future<void> write(StoredSession session) async => value = session;

  @override
  Future<void> writeDeviceId(String value) async => deviceId = value;
}
