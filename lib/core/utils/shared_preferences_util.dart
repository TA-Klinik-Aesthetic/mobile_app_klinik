// file: lib/utils/shared_preferences_util.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtil {
  static const String USER_KEY = 'user_data';
  static const String TOKEN_KEY = 'auth_token';
  static const String FCM_TOKEN_KEY = 'fcm_token';

  // Get auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  // Save auth token
  static Future<bool> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(TOKEN_KEY, token);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(USER_KEY);
    if (userData != null) {
      final map = json.decode(userData);
      return map['id_user'];
    }
    return null;
  }

  // Get FCM Token
  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(FCM_TOKEN_KEY);
  }

  // Save FCM Token
  static Future<bool> setFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(FCM_TOKEN_KEY, token);
  }
}