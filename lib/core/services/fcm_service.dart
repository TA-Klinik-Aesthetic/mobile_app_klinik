import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/home_screen/detail_notification_screen.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Public init
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _initializeLocalNotifications();
      await _requestPermission();
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
      await _setupMessageHandlers();

      final token = await getToken();
      if (token != null) {
        await _saveTokenLocally(token);
        // Coba kirim ke server bila user sudah login
        await ensureServerHasLatestToken();
      }

      // Daftarkan listener refresh token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _saveTokenLocally(newToken);
        await ensureServerHasLatestToken();
      });

      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  // Kirim token ke server (ubah endpoint sesuai backend Anda)
  static Future<void> ensureServerHasLatestToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await getToken();
      final userId = await _readCurrentUserIdFromPrefs();
      if (token == null || userId == null) return;

      final baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final bearer = prefs.getString('token') ?? prefs.getString('access_token');

      final resp = await http.post(
        Uri.parse('$baseUrl/fcm/register-token'),
        headers: {
          'Content-Type': 'application/json',
          if (bearer != null) 'Authorization': 'Bearer $bearer',
        },
        body: jsonEncode({
          'user_id': userId,
          'device_token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        }),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        print('⚠️ Failed to sync FCM token: ${resp.statusCode} ${resp.body}');
      } else {
        print('✅ FCM token synced to server');
      }
    } catch (e) {
      print('⚠️ Token sync error: $e');
    }
  }

  static Future<int?> _readCurrentUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek beberapa key umum yang app Anda pakai
      int? uid =
          prefs.getInt('id_user') ??
          prefs.getInt('user_id') ??
          prefs.getInt('id');

      if (uid != null) return uid;

      // Coba baca dari String lalu parse
      final idStr =
          prefs.getString('id_user') ??
          prefs.getString('user_id') ??
          prefs.getString('id');
      if (idStr != null) {
        uid = int.tryParse(idStr);
        if (uid != null) return uid;
      }

      // Coba dari JSON 'user'
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final m = jsonDecode(userJson);
        final dynamic raw = m['id_user'] ?? m['id'] ?? m['user_id'];
        if (raw is int) return raw;
        return int.tryParse(raw?.toString() ?? '');
      }
    } catch (_) {}
    return null;
  }

  // Ekspose util untuk menampilkan notifikasi dari map (fallback polling)
  static Future<void> showLocalFromNotificationMap(Map<String, dynamic> map) async {
    // hanya unread
    final status = (map['status'] ?? 'unread').toString().toLowerCase();
    if (status != 'unread') return;

    const android = AndroidNotificationDetails(
      'navya_high_importance_channel',
      'NAVYA High Importance Notifications',
      channelDescription: 'Important notifications from NAVYA Hub',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true, sound: 'default',
    );
    const details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      (map['judul'] ?? 'NAVYA HUB').toString(),
      (map['pesan'] ?? 'Anda memiliki notifikasi baru').toString(),
      details,
      payload: jsonEncode(map),
    );
  }

  // Permissions
  static Future<void> _requestPermission() async {
    // Minta izin via FCM API (efektif di iOS; di Android < 13 auto-granted)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Android 13+ pakai permission_handler
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final res = await Permission.notification.request();
        debugPrint('🔔 Android notification permission result: $res');
      }
    } else if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    debugPrint('🔔 FCM Permission: ${settings.authorizationStatus}');
  }

  // Handlers
  static Future<void> _setupMessageHandlers() async {
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Opened from terminated
    _checkForInitialMessage();
  }

  static Future<void> _checkForInitialMessage() async {
    final RemoteMessage? initial = await _firebaseMessaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _handleNotificationTap(initial);
      });
    }
  }

  // Local notifications
  static Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'navya_high_importance_channel',
        'NAVYA High Importance Notifications',
        description: 'Important notifications from NAVYA Hub',
        importance: Importance.max,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Normalisasi payload agar sama dengan data di NotificationScreen
  // Kunci dipakai: id_notifikasi, jenis, judul, pesan, tanggal_notifikasi, status, id_referensi
  static Map<String, dynamic> _normalizeMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final nowIso = DateTime.now().toIso8601String();

    return <String, dynamic>{
      'id_notifikasi': data['id_notifikasi'] ??
          data['notification_id'] ??
          data['id'] ??
          message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'jenis': (data['jenis'] ?? data['type'] ?? 'umum').toString(),
      'judul': data['judul'] ??
          data['title'] ??
          message.notification?.title ??
          'NAVYA HUB',
      'pesan': data['pesan'] ??
          data['body'] ??
          message.notification?.body ??
          'Anda memiliki notifikasi baru',
      'tanggal_notifikasi':
          data['tanggal_notifikasi'] ?? data['timestamp'] ?? nowIso,
      'status': (data['status'] ?? 'unread').toString().toLowerCase(),
      'id_referensi': (data['id_referensi'] ?? data['reference_id'])?.toString(),
    };
  }

  // ✅ Hanya tampilkan push untuk status 'unread'
  static bool _shouldNotify(Map<String, dynamic> map) {
    final status = (map['status'] ?? 'unread').toString().toLowerCase();
    return status == 'unread';
  }

  // Foreground message -> tampilkan local notif + snackbar (opsional)
  static void _handleForegroundMessage(RemoteMessage message) async {
    final map = _normalizeMessage(message);
    if (!_shouldNotify(map)) {
      debugPrint('ℹ️ Skip push: status=${map['status']}');
      return;
    }

    await _showLocalNotification(message);

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final title = map['judul'] as String;
      final body = map['pesan'] as String;

      ScaffoldMessenger.of(ctx).clearSnackBars();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () => _navigateToDetail(map),
          ),
        ),
      );
    }
  }

  // Show local notification with normalized payload
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final map = _normalizeMessage(message);
    if (!_shouldNotify(map)) {
      debugPrint('ℹ️ Skip local notification: status=${map['status']}');
      return;
    }

    final title = map['judul'] as String;
    final body = map['pesan'] as String;

    const android = AndroidNotificationDetails(
      'navya_high_importance_channel',
      'NAVYA High Importance Notifications',
      channelDescription: 'Important notifications from NAVYA Hub',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );
    const details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: jsonEncode(map),
    );
  }

  // Tap dari notifikasi FCM (app background/terminated)
  static void _handleNotificationTap(RemoteMessage message) {
    final map = _normalizeMessage(message);
    _navigateToDetail(map);
  }

  // Tap dari local notification (payload JSON)
  static void _onLocalNotificationTap(NotificationResponse response) {
    try {
      if (response.payload != null && response.payload!.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(response.payload!);
        _navigateToDetail(map);
        return;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error parsing local payload: $e');
    }

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).pushNamed('/notifications'); // fallback
    }
  }

  // Navigasi ke halaman detail notifikasi dengan data lengkap
  static void _navigateToDetail(Map<String, dynamic> notif) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      // ignore: avoid_print
      print('❌ No context to navigate to detail');
      return;
    }
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => DetailNotificationScreen(notification: notif),
      ),
    );
  }

  // Token utils
  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // ignore: avoid_print
        print('🔔 FCM Token: ${token.substring(0, 50)}...');
      }
      return token;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error getToken: $e');
      return null;
    }
  }

  static Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_fcm_token', token);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error saving token: $e');
    }
  }

  static Future<void> unregisterToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      print('🔔 FCM token deleted from Firebase');
      
      await clearFCMToken();
    } catch (e) {
      print('❌ Error unregistering FCM token: $e');
      await clearFCMToken();
    }
  }

  // ✅ Clear FCM token
  static Future<void> clearFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_fcm_token');
      await prefs.remove('fcm_token');
      print('🔔 FCM tokens cleared from local storage');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }

  static Future<void> initializeNotificationListener() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  static Future<void> debugStatus() async {
    // ignore: avoid_print
    print('📋 FCM Debug: initialized=$_isInitialized');
    try {
      final t = await getToken();
      // ignore: avoid_print
      print('📋 Token present: ${t != null}');
    } catch (_) {}
  }
}

// Background handler (top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    await FCMService._initializeLocalNotifications();
    await FCMService._showLocalNotification(message);
    // ignore: avoid_print
    print('✅ [BG] Notification shown');
  } catch (e) {
    // ignore: avoid_print
    print('❌ [BG] Error showing notification: $e');
  }
}