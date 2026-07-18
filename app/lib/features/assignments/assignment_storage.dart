import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AssignmentStorage {
  Future<String?> read(String ownerId);

  Future<void> write(String ownerId, String value);
}

final class SharedPreferencesAssignmentStorage implements AssignmentStorage {
  static const _prefix = 'starforge.assignments.v1.';

  @override
  Future<String?> read(String ownerId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_prefix$ownerId');
  }

  @override
  Future<void> write(String ownerId, String value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString('$_prefix$ownerId', value);
    if (!saved) throw StateError('Assignment state could not be saved.');
  }
}

final class MemoryAssignmentStorage implements AssignmentStorage {
  MemoryAssignmentStorage([Map<String, String>? values])
    : _values = {...?values};

  final Map<String, String> _values;

  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> read(String ownerId) async => _values[ownerId];

  @override
  Future<void> write(String ownerId, String value) async {
    _values[ownerId] = value;
  }
}
