import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _keySessionKey = 'session_key';
  static const _keyTableId = 'table_id';

  Future<void> saveSession({required String sessionKey, required int tableId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionKey, sessionKey);
    await prefs.setInt(_keyTableId, tableId);
  }

  Future<String?> getSessionKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionKey);
    await prefs.remove(_keyTableId);
  }
}