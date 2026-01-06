import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  Future<void> saveUserData(String userData) async {
    await _prefs.setString(_userKey, userData);
  }

  String? getUserData() {
    return _prefs.getString(_userKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  bool get hasToken => _prefs.containsKey(_tokenKey);
}
