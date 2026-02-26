import 'dart:convert';

import '../../core/exceptions/exception.dart';
import '../../core/storage/storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getCachedToken();
  Future<void> cacheRefreshToken(String token); // ✅ new
  Future<String?> getCachedRefreshToken(); // ✅ new
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService storageService;

  AuthLocalDataSourceImpl(this.storageService);

  // ─── Access Token ────────────────────────────────────────

  @override
  Future<void> cacheToken(String token) async {
    try {
      await storageService.saveToken(token);
    } catch (e) {
      throw CacheException('Failed to cache token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getCachedToken() async {
    try {
      return storageService.getToken();
    } catch (e) {
      throw CacheException('Failed to get cached token: ${e.toString()}');
    }
  }

  // ─── Refresh Token ───────────────────────────────────────

  @override
  Future<void> cacheRefreshToken(String token) async {
    try {
      await storageService.saveRefreshToken(token);
    } catch (e) {
      throw CacheException('Failed to cache refresh token: ${e.toString()}');
    }
  }

  @override
  Future<String?> getCachedRefreshToken() async {
    try {
      return storageService.getRefreshToken();
    } catch (e) {
      throw CacheException(
        'Failed to get cached refresh token: ${e.toString()}',
      );
    }
  }

  // ─── User ─────────────────────────────────────────────────

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await storageService.saveUserData(userJson);
    } catch (e) {
      throw CacheException('Failed to cache user: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = storageService.getUserData();
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached user: ${e.toString()}');
    }
  }

  // ─── Clear ───────────────────────────────────────────────

  @override
  Future<void> clearCache() async {
    try {
      await storageService.clearAll(); // ✅ clears both tokens + user
    } catch (e) {
      throw CacheException('Failed to clear cache: ${e.toString()}');
    }
  }
}
