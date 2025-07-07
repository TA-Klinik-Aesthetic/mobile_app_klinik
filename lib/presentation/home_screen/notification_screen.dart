// file: lib/screens/notifikasi_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app_klinik/core/providers/notifikasi_provider.dart';
import 'package:mobile_app_klinik/core/utils/shared_preferences_util.dart';
import 'package:mobile_app_klinik/core/widgets/notification_item.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late int userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SharedPreferencesUtil.getUserId();
    if (id != null) {
      setState(() {
        userId = id;
        isLoading = false;
      });
      _refreshNotifications();
    } else {
      // Handle case when user is not logged in
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _refreshNotifications() async {
    if (!isLoading) {
      await Provider.of<NotifikasiProvider>(context, listen: false).fetchNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Tandai semua telah dibaca',
              onPressed: () async {
                await Provider.of<NotifikasiProvider>(context, listen: false).markAllAsRead(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua notifikasi telah dibaca')),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<NotifikasiProvider>(
        builder: (context, notifikasiProvider, child) {
          if (notifikasiProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifikasiProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(notifikasiProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshNotifications,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (notifikasiProvider.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada notifikasi',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.builder(
              itemCount: notifikasiProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notifikasiProvider.notifications[index];
                return NotificationItem(
                  notification: notification,
                  onTap: () {
                    if (notification.status == 'unread') {
                      notifikasiProvider.markAsRead(notification.idNotifikasi);
                    }
                    _navigateToDetail(notification);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(notification) {
    // Navigate based on notification type
    final jenis = notification.jenis;
    final idReferensi = notification.idReferensi;

    if (idReferensi == null) return;

    switch (jenis) {
      case 'treatment':
        Navigator.of(context).pushNamed('/treatment-detail', arguments: idReferensi);
        break;
      case 'konsultasi':
        Navigator.of(context).pushNamed('/konsultasi-detail', arguments: idReferensi);
        break;
      case 'produk':
        Navigator.of(context).pushNamed('/produk-detail', arguments: idReferensi);
        break;
      case 'promo':
        Navigator.of(context).pushNamed('/promo-detail', arguments: idReferensi);
        break;
    }
  }
}