import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get FCM token
    await _registerFCMToken();

    // Set up message handlers
    _setupMessageHandlers();
  }

  static Future<void> _registerFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");

      if (token != null) {
        await _saveTokenToPreferences(token);
        await _registerTokenWithBackend(token);
      }

      // Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print("FCM Token refreshed: $newToken");
        await _saveTokenToPreferences(newToken);
        await _registerTokenWithBackend(newToken);
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  static Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id_user');
      final userToken = prefs.getString('token');

      if (userId == null || userToken == null) {
        print('User not logged in. FCM token will be registered after login.');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.fcmRegister),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({
          'id_user': userId,
          'fcm_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FCM Token registered with backend successfully');
      } else {
        print('Failed to register FCM Token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data);
    });

    // Handle messages when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state');
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTap(message.data);
        });
      }
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    // This will be handled by the global navigator key
    print('Handling notification tap: $data');
    // You can add navigation logic here if needed
  }

  static Future<void> registerTokenAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
  }

  static Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id_user');
      final userToken = prefs.getString('token');

      if (userId == null || userToken == null) {
        print('User data not available for unregistering token');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.fcmUnregister),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({
          'id_user': userId,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM Token unregistered successfully');
      } else {
        print('Failed to unregister FCM Token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error unregistering FCM token: $e');
    }
  }
}