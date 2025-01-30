import 'package:shared_preferences/shared_preferences.dart';

class UserCacheService {
  static const String _usernameKey = 'cached_username';
  static const String _userIdKey = 'cached_user_id';
  static const String _premiumLevelKey = 'cached_premium_level';

  // Save user data to cache
  static Future<void> cacheUserData({
    required String username,
    required String userId,
    String premiumLevel = 'none',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_premiumLevelKey, premiumLevel.toLowerCase());
  }

  // Get cached username
  static Future<String?> getCachedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Get cached premium level
  static Future<String> getCachedPremiumLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_premiumLevelKey) ?? 'none';
  }

  // Update premium level
  static Future<void> updatePremiumLevel(String premiumLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_premiumLevelKey, premiumLevel.toLowerCase());
  }

  // Clear cache on logout
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_premiumLevelKey);
  }
}
