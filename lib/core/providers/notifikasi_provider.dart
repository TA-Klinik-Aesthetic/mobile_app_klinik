// file: lib/providers/notifikasi_provider.dart

import 'package:flutter/material.dart';
import '../models/notifikasi_model.dart';
import '../services/notifikasi_service.dart';

class NotifikasiProvider with ChangeNotifier {
  final NotifikasiService _notifikasiService = NotifikasiService();
  List<NotifikasiModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotifikasiModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _notifikasiService.getUserNotifications(userId);
      _notifications = result['notifications'];
      _unreadCount = result['unread_count'];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _notifikasiService.markNotificationAsRead(notificationId);
      if (success) {
        final index = _notifications.indexWhere(
                (notification) => notification.idNotifikasi == notificationId
        );

        if (index != -1) {
          final updatedNotification = NotifikasiModel(
            idNotifikasi: _notifications[index].idNotifikasi,
            idUser: _notifications[index].idUser,
            judul: _notifications[index].judul,
            pesan: _notifications[index].pesan,
            jenis: _notifications[index].jenis,
            idReferensi: _notifications[index].idReferensi,
            status: 'read',
            gambar: _notifications[index].gambar,
            tanggalNotifikasi: _notifications[index].tanggalNotifikasi,
            createdAt: _notifications[index].createdAt,
            updatedAt: DateTime.now(),
          );

          _notifications[index] = updatedNotification;
          if (_unreadCount > 0) _unreadCount--;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(int userId) async {
    try {
      final success = await _notifikasiService.markAllNotificationsAsRead(userId);
      if (success) {
        _notifications = _notifications.map((notification) {
          return NotifikasiModel(
            idNotifikasi: notification.idNotifikasi,
            idUser: notification.idUser,
            judul: notification.judul,
            pesan: notification.pesan,
            jenis: notification.jenis,
            idReferensi: notification.idReferensi,
            status: 'read',
            gambar: notification.gambar,
            tanggalNotifikasi: notification.tanggalNotifikasi,
            createdAt: notification.createdAt,
            updatedAt: DateTime.now(),
          );
        }).toList();

        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}