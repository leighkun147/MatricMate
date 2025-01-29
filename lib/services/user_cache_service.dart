import 'package:shared_preferences/shared_preferences.dart';

class UserCacheService {
  static const String _usernameKey = 'cached_username';
  static const String _userIdKey = 'cached_user_id';

  // Save user data to cache
  static Future<void> cacheUserData({
    required String username,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_userIdKey, userId);
  }

  // Get cached username
  static Future<String?> getCachedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Clear cache on logout
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
  }
}
