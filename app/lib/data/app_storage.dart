import 'package:shared_preferences/shared_preferences.dart';

/// Small persistence boundary used by [AppState].
///
/// Keeping this interface string-based makes every persisted value auditable,
/// JSON-safe, and easy to replace in tests or in a future secure store.
abstract interface class AppStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

final class SharedPreferencesAppStorage implements AppStorage {
  SharedPreferencesAppStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesAppStorage> create() async {
    return SharedPreferencesAppStorage(await SharedPreferences.getInstance());
  }

  /// One-time production migration that removes unscoped demo-era workspace
  /// caches. New server data is never written to these legacy keys.
  Future<void> migrateLegacyDemoData() async {
    const marker = 'starforge.staff.production_migration.v1';
    if (_preferences.getBool(marker) == true) return;
    const exactKeys = {
      'starforge.group_workspace.v1',
      'starforge.content_workspace.v1',
      'starforge.pending_recovery_request.v1',
    };
    final legacyKeys = _preferences.getKeys().where(
      (key) =>
          exactKeys.contains(key) ||
          key.startsWith('starforge.messaging.v1.') ||
          key.startsWith('starforge.assignments.v1.'),
    );
    for (final key in legacyKeys.toList(growable: false)) {
      await _preferences.remove(key);
    }
    await _preferences.setBool(marker, true);
  }

  @override
  Future<String?> read(String key) async => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final saved = await _preferences.setString(key, value);
    if (!saved) {
      throw StateError('Could not persist local app state.');
    }
  }

  @override
  Future<void> remove(String key) async {
    final removed = await _preferences.remove(key);
    if (!removed && _preferences.containsKey(key)) {
      throw StateError('Could not remove local app state.');
    }
  }
}

/// Deterministic storage intended for tests, previews, and widget catalogues.
final class MemoryAppStorage implements AppStorage {
  MemoryAppStorage([Map<String, String>? initialValues])
    : _values = {...?initialValues};

  final Map<String, String> _values;

  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
