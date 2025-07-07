// file: lib/services/notifikasi_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/notifikasi_model.dart';
import '../utils/shared_preferences_util.dart';

class NotifikasiService {
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';

  Future<Map<String, dynamic>> getUserNotifications(int userId) async {
    final token = await SharedPreferencesUtil.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] == true && data['data'] != null) {
        final List<NotifikasiModel> notifications = (data['data']['notifications'] as List)
            .map((item) => NotifikasiModel.fromJson(item))
            .toList();

        final int unreadCount = data['data']['unread_count'];

        return {
          'notifications': notifications,
          'unread_count': unreadCount,
        };
      } else {
        throw Exception('Invalid data format');
      }
    } else {
      throw Exception('Failed to load notifications: ${response.body}');
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    final token = await SharedPreferencesUtil.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/read/$notificationId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to mark notification as read: ${response.body}');
    }
  }

  Future<bool> markAllNotificationsAsRead(int userId) async {
    final token = await SharedPreferencesUtil.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/read-all/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('Failed to mark all notifications as read: ${response.body}');
    }
  }
}