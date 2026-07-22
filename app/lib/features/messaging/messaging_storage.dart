import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MessagingStorage {
  Future<String?> read(String sessionKey);

  Future<void> write(String sessionKey, String value);

  Future<void> remove(String sessionKey);

  Future<void> removeScope(String storageScope);

  Future<void> clearAll();
}

final class SharedPreferencesMessagingStorage implements MessagingStorage {
  static const _prefix = 'starforge.messaging.v1.';

  @override
  Future<String?> read(String sessionKey) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_prefix$sessionKey');
  }

  @override
  Future<void> write(String sessionKey, String value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString('$_prefix$sessionKey', value);
    if (!saved) throw StateError('Messaging state could not be saved.');
  }

  @override
  Future<void> remove(String sessionKey) async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove('$_prefix$sessionKey');
    if (!removed && preferences.containsKey('$_prefix$sessionKey')) {
      throw StateError('Messaging state could not be removed.');
    }
  }

  @override
  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith(_prefix))
        .toList(growable: false);
    for (final key in keys) {
      final removed = await preferences.remove(key);
      if (!removed && preferences.containsKey(key)) {
        throw StateError('Messaging state could not be removed.');
      }
    }
  }

  @override
  Future<void> removeScope(String storageScope) async {
    final preferences = await SharedPreferences.getInstance();
    final scopedPrefix = '$_prefix${Uri.encodeComponent(storageScope)}::';
    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith(scopedPrefix))
        .toList(growable: false);
    for (final key in keys) {
      final removed = await preferences.remove(key);
      if (!removed && preferences.containsKey(key)) {
        throw StateError('Messaging state could not be removed.');
      }
    }
  }
}

final class MemoryMessagingStorage implements MessagingStorage {
  MemoryMessagingStorage([Map<String, String>? values])
    : _values = {...?values};

  final Map<String, String> _values;
  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> read(String sessionKey) async => _values[sessionKey];

  @override
  Future<void> write(String sessionKey, String value) async {
    _values[sessionKey] = value;
  }

  @override
  Future<void> remove(String sessionKey) async {
    _values.remove(sessionKey);
  }

  @override
  Future<void> removeScope(String storageScope) async {
    final scopedPrefix = '${Uri.encodeComponent(storageScope)}::';
    _values.removeWhere((key, _) => key.startsWith(scopedPrefix));
  }

  @override
  Future<void> clearAll() async {
    _values.clear();
  }
}
