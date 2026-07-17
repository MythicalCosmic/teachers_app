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
