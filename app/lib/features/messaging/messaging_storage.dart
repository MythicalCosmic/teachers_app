import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MessagingStorage {
  Future<String?> read(String userId);

  Future<void> write(String userId, String value);
}

final class SharedPreferencesMessagingStorage implements MessagingStorage {
  static const _prefix = 'starforge.messaging.v1.';

  @override
  Future<String?> read(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_prefix$userId');
  }

  @override
  Future<void> write(String userId, String value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString('$_prefix$userId', value);
    if (!saved) throw StateError('Messaging state could not be saved.');
  }
}

final class MemoryMessagingStorage implements MessagingStorage {
  MemoryMessagingStorage([Map<String, String>? values])
    : _values = {...?values};

  final Map<String, String> _values;
  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> read(String userId) async => _values[userId];

  @override
  Future<void> write(String userId, String value) async {
    _values[userId] = value;
  }
}
