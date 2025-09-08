// file: lib/widgets/notification_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notifikasi_model.dart';

class NotificationItem extends StatelessWidget {
  final NotifikasiModel notification;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  Color _getIconColor() {
    switch (notification.jenis) {
      case 'treatment':
        return Colors.blue;
      case 'konsultasi':
        return Colors.purple;
      case 'produk':
        return Colors.orange;
      case 'promo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconData() {
    switch (notification.jenis) {
      case 'treatment':
        return Icons.spa;
      case 'konsultasi':
        return Icons.medical_services;
      case 'produk':
        return Icons.shopping_bag;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(notification.tanggalNotifikasi);

    return Card(
      elevation: notification.status == 'unread' ? 3 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: notification.status == 'unread'
          ? Theme.of(context).colorScheme.surface
          : Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getIconColor().withOpacity(0.2),
                child: Icon(
                  _getIconData(),
                  color: _getIconColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.judul,
                            style: TextStyle(
                              fontWeight: notification.status == 'unread'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.status == 'unread')
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getIconColor(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.pesan,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: notification.status == 'unread'
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}