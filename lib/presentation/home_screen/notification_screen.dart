import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_app_klinik/core/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import 'detail_notification_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  int unreadCount = 0;
  bool isLoading = true;
  String? errorMessage;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await _getCurrentUserId();
    if (currentUserId != null) {
      await _fetchNotifications();
    } else {
      setState(() {
        errorMessage = 'User belum login';
        isLoading = false;
      });
    }
  }

  Future<void> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ Try multiple ways to get user ID
      int? userId = prefs.getInt('id_user');
      
      if (userId == null) {
        // Try as string and convert
        final userIdString = prefs.getString('id_user');
        if (userIdString != null) {
          userId = int.tryParse(userIdString);
        }
      }

      print('🔍 Debug: Current user ID = $userId');
      print('🔍 Debug: All SharedPrefs keys = ${prefs.getKeys()}');
      
      setState(() {
        currentUserId = userId;
      });

      // If no user ID found, redirect to login
      if (userId == null) {
        final token = prefs.getString('token');
        if (token == null) {
          // No token, definitely not logged in
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              AppRoutes.loginUserScreen, 
              (route) => false
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      setState(() {
        errorMessage = 'Error mengambil data user: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchNotifications() async {
    if (currentUserId == null) {
      setState(() {
        errorMessage = 'User ID tidak ditemukan';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            AppRoutes.loginUserScreen, 
            (route) => false
          );
        }
        return;
      }

      final url = '${ApiConstants.baseUrl}/notifications/$currentUserId';
      print('📡 Fetching notifications from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final notificationsData = data['data']['notifications'] as List;
          final unreadCountData = data['data']['unread_count'] ?? 0;

          // Set state dulu
          setState(() {
            notifications = List<Map<String, dynamic>>.from(notificationsData);
            unreadCount = unreadCountData;
            isLoading = false;
            errorMessage = null;
          });

          // Fallback push lokal: tampilkan push untuk item UNREAD baru sejak fetch terakhir
          try {
            final lastKey = 'last_seen_notif_id_${currentUserId!}';
            final lastSeenId = prefs.getInt(lastKey) ?? 0;

            final newUnread = notifications.where((n) {
              final id = int.tryParse(n['id_notifikasi'].toString()) ?? 0;
              final status = (n['status'] ?? 'unread').toString().toLowerCase();
              return status == 'unread' && id > lastSeenId;
            }).toList();

            if (newUnread.isNotEmpty) {
              print('🔔 Fallback push for ${newUnread.length} new unread items');
              for (final n in newUnread) {
                await FCMService.showLocalFromNotificationMap(n);
              }
            }

            // Simpan maksimum id_notifikasi yang ada sekarang agar tidak double push
            final maxId = notifications.fold<int>(lastSeenId, (acc, n) {
              final id = int.tryParse(n['id_notifikasi'].toString()) ?? 0;
              return id > acc ? id : acc;
            });
            await prefs.setInt(lastKey, maxId);
          } catch (e) {
            print('⚠️ Fallback push error: $e');
          }

          print('✅ Notifications loaded: ${notifications.length} items, $unreadCount unread');
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch notifications');
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            AppRoutes.loginUserScreen, 
            (route) => false
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      // ✅ Use correct full URL
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/read/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('✅ Mark as read response: ${response.statusCode}');

      if (response.statusCode == 200) {
        setState(() {
          final index = notifications.indexWhere(
            (notif) => notif['id_notifikasi'] == notificationId
          );
          if (index != -1 && notifications[index]['status'] == 'unread') {
            notifications[index]['status'] = 'read';
            unreadCount = (unreadCount - 1).clamp(0, notifications.length);
          }
        });
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      // ✅ Use correct full URL
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/read-all/$currentUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var notification in notifications) {
            notification['status'] = 'read';
          }
          unreadCount = 0;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua notifikasi telah dibaca')),
          );
        }
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Baru saja';
          }
          return '${difference.inMinutes} menit yang lalu';
        }
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  // ✅ Simple method that returns Icon directly
  Icon _getNotificationIcon(String jenis) {
    print('🔍 Notification jenis: "$jenis"');
    
    switch (jenis.toLowerCase().trim()) {
      case 'produk':
      case 'product':
        return Icon(Icons.shopping_bag, color: appTheme.orange200, size: 24);
      case 'treatment':
        return Icon(Icons.spa, color: appTheme.lightGreen, size: 24);
      case 'konsultasi':
        return Icon(Icons.medical_services, color: Color.fromARGB(255, 92, 158, 213), size: 24);
      case 'promo':
        return Icon(Icons.local_offer, color: appTheme.darkCherry, size: 24);
      default:
        print('⚠️ Unknown notification type: "$jenis"');
        return Icon(Icons.notifications, color: Colors.grey, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all, color: appTheme.orange200),
              tooltip: 'Tandai semua telah dibaca',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: appTheme.orange200),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat notifikasi...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${currentUserId ?? "Loading..."}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi kesalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'User ID: ${currentUserId ?? "Tidak ditemukan"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeAndFetch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.orange200,
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (currentUserId == null)
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context, 
                              AppRoutes.loginUserScreen, 
                              (route) => false
                            );
                          },
                          child: Text(
                            'Login Ulang',
                            style: TextStyle(color: appTheme.orange200),
                          ),
                        ),
                    ],
                  ),
                )
              : notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: appTheme.orange200,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off, 
                                       size: 64, 
                                       color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada notifikasi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'User ID: ${currentUserId ?? "Tidak ditemukan"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: appTheme.orange200,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final isUnread = notification['status'] == 'unread';
                          
                          // ✅ Debug the notification data
                          print('🔍 Notification $index: ${notification['jenis']} - ${notification['judul']}');
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isUnread 
                                  ? Colors.white
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isUnread 
                                    ? appTheme.orange200.withOpacity(0.3)
                                    : Colors.grey.shade300,
                                width: isUnread ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  // ✅ Use the icon method directly
                                  color: _getNotificationIcon(notification['jenis'] ?? '').color!
                                      .withOpacity(isUnread ? 0.2 : 0.1),
                                  shape: BoxShape.circle,
                                ),
                                // ✅ Use the icon method directly
                                child: _getNotificationIcon(notification['jenis'] ?? ''),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification['judul'] ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isUnread 
                                            ? FontWeight.bold 
                                            : FontWeight.w500,
                                        color: isUnread 
                                            ? appTheme.black900 
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: appTheme.orange200,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['pesan'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isUnread 
                                          ? Colors.grey[600] 
                                          : Colors.grey[500],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(notification['tanggal_notifikasi'] ?? ''),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUnread 
                                              ? appTheme.orange200 
                                              : Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // ✅ Show notification type for debugging (remove in production)
                                      if (true) // Set to false in production
                                        Text(
                                          '(${notification['jenis'] ?? 'unknown'})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade400,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (isUnread) {
                                  _markAsRead(notification['id_notifikasi']);
                                }
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailNotificationScreen(
                                      notification: notification,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}