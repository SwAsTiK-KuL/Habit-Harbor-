import 'dart:convert';

import '../../core/exceptions/exception.dart';
import '../../core/storage/storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> getCachedToken();
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService storageService;

  AuthLocalDataSourceImpl(this.storageService);

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
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached user: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storageService.clearAll();
    } catch (e) {
      throw CacheException('Failed to clear cache: ${e.toString()}');
    }
  }
}
