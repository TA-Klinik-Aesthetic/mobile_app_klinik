// file: lib/widgets/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifikasi_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int userId;

  const NotificationBadge({
    Key? key,
    required this.child,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotifikasiProvider>(
      builder: (context, notifikasiProvider, _) {
        // Initialize notification data if needed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!notifikasiProvider.isLoading && notifikasiProvider.notifications.isEmpty) {
            notifikasiProvider.fetchNotifications(userId);
          }
        });

        return Stack(
          alignment: Alignment.center,
          children: [
            child,
            if (notifikasiProvider.unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notifikasiProvider.unreadCount > 99
                        ? '99+'
                        : notifikasiProvider.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}