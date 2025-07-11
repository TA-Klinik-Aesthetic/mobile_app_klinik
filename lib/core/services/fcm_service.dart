import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token and save locally (but DON'T register to backend yet)
    await _getFCMTokenAndSaveLocally();

    // Set up message handlers
    _setupMessageHandlers();
  }

  static Future<void> _getFCMTokenAndSaveLocally() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveTokenToPreferences(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  static Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // This method should ONLY be called after successful login
  static Future<void> registerTokenAfterLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      final userToken = prefs.getString('token'); // Auth token
      final userId = prefs.getInt('id_user'); // User ID
      
      if (fcmToken != null && userToken != null && userId != null) {
        await _registerTokenWithBackend(fcmToken, userToken, userId);
        print('FCM token registered successfully after login');
      } else {
        print('Missing required data for FCM registration: fcmToken=$fcmToken, userToken=$userToken, userId=$userId');
      }
    } catch (e) {
      print('Error registering FCM token after login: $e');
      throw e;
    }
  }

  static Future<void> _registerTokenWithBackend(String fcmToken, String authToken, int userId) async {
    try {
      final requestBody = {
        'id_user': userId,
        'device_token': fcmToken,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
      };

      print('Registering FCM with payload: $requestBody');
      print('FCM Register URL: ${ApiConstants.fcmRegister}');

      final response = await http.post(
        Uri.parse(ApiConstants.fcmRegister),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('FCM register response status: ${response.statusCode}');
      print('FCM register response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('FCM token registered with backend successfully');
          
          // Save registration status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('fcm_registered', true);
        } else {
          throw Exception('FCM registration failed: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to register FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error registering FCM token with backend: $e');
      throw e;
    }
  }

  // Call this when user logs out
  static Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      final authToken = prefs.getString('token');
      final userId = prefs.getInt('id_user');
      final isRegistered = prefs.getBool('fcm_registered') ?? false;
      
      if (fcmToken != null && authToken != null && userId != null && isRegistered) {
        // Unregister from backend
        final requestBody = {
          'id_user': userId,
          'device_token': fcmToken,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        };

        print('Unregistering FCM with payload: $requestBody');
        print('FCM Unregister URL: ${ApiConstants.fcmUnregister}');

        final response = await http.post(
          Uri.parse(ApiConstants.fcmUnregister),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(requestBody),
        );

        print('FCM unregister response status: ${response.statusCode}');
        print('FCM unregister response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            print('FCM token unregistered successfully: ${responseData['message']}');
          }
        }
      }
      
      // Clear FCM related data from preferences
      await prefs.remove('fcm_token');
      await prefs.remove('fcm_registered');
      
    } catch (e) {
      print('Error unregistering FCM token: $e');
      // Don't throw error on logout to prevent blocking logout process
    }
  }

  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.title}');
      print('Message data: ${message.data}');
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Handle messages when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('Handling notification tap: $data');
    // Add navigation logic here if needed
  }
}