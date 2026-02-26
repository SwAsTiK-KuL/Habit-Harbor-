import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // ─── Access Token ────────────────────────────────────────
  Future<void> saveToken(String token) async {
    await _prefs.setString(_accessTokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  // ─── Refresh Token ───────────────────────────────────────
  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  // ─── User Data ───────────────────────────────────────────
  Future<void> saveUserData(String userData) async {
    await _prefs.setString(_userKey, userData);
  }

  String? getUserData() {
    return _prefs.getString(_userKey);
  }

  // ─── Clear ───────────────────────────────────────────────
  Future<void> clearAll() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey); // ✅ also clears refresh token
    await _prefs.remove(_userKey);
  }

  bool get hasToken => _prefs.containsKey(_accessTokenKey);
}
