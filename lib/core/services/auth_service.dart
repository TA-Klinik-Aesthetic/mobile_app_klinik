import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userTokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // Save user data after login
  static Future<void> saveUserData({
    required String token,
    required String userId,
    String? userName,
    String? userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
    await prefs.setString(_userIdKey, userId);
    if (userName != null) await prefs.setString(_userNameKey, userName);
    if (userEmail != null) await prefs.setString(_userEmailKey, userEmail);
  }

  // Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  // Get saved user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get saved user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get saved user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final userId = await getUserId();
      
      // Both token and userId must be present and non-empty
      final hasValidToken = token != null && token.isNotEmpty;
      final hasValidUserId = userId != null && userId.isNotEmpty;
      
      print('🔑 Auth check - Token: $hasValidToken, UserId: $hasValidUserId');
      
      return hasValidToken && hasValidUserId;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }


  // Clear all user data (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  // Get all user data
  static Future<Map<String, String?>> getUserData() async {
    return {
      'token': await getToken(),
      'userId': await getUserId(),
      'userName': await getUserName(),
      'userEmail': await getUserEmail(),
    };
  }
}