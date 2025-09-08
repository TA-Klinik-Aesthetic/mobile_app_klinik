import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';

class DetailNotificationScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const DetailNotificationScreen({
    super.key,
    required this.notification,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Icon _getNotificationIcon(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'produk':
        return Icon(Icons.shopping_bag, color: appTheme.orange200, size: 48);
      case 'treatment':
        return Icon(Icons.spa, color: appTheme.lightGreen, size: 48);
      case 'konsultasi':
        return Icon(Icons.chat, color: appTheme.lightBlue, size: 48);
      case 'promo':
        return Icon(Icons.local_offer, color: appTheme.darkCherry, size: 48);
      default:
        return Icon(Icons.notifications, color: Colors.grey, size: 48);
    }
  }

  String _getTypeDisplayName(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'produk':
        return 'Pembelian Produk';
      case 'treatment':
        return 'Booking Treatment';
      case 'konsultasi':
        return 'Konsultasi';
      case 'promo':
        return 'Promo';
      default:
        return jenis.toUpperCase();
    }
  }

  void _navigateToRelatedPage(BuildContext context) {
    final jenis = notification['jenis'];
    final idReferensi = notification['id_referensi'];

    if (idReferensi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka detail')),
      );
      return;
    }

    try {
      final int refId = int.parse(idReferensi.toString());
      
      switch (jenis.toLowerCase()) {
        case 'produk':
          Navigator.pushNamed(
            context, 
            AppRoutes.historyPurchaseScreen,
            arguments: refId,
          );
          break;
        case 'treatment':
          Navigator.pushNamed(
            context, 
            AppRoutes.bookingTreatmentScreen,
            arguments: refId,
          );
          break;
        case 'konsultasi':
          Navigator.pushNamed(
            context, 
            AppRoutes.bookingConsultationScreen,
            arguments: refId,
          );
          break;
        case 'promo':
          Navigator.pushNamed(
            context, 
            AppRoutes.promoScreen,
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jenis notifikasi tidak dikenal')),
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error membuka detail')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Detail Notifikasi',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and type
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getNotificationIcon(notification['jenis']).color!.withOpacity(0.1),
                    _getNotificationIcon(notification['jenis']).color!.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getNotificationIcon(notification['jenis']).color!.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _getNotificationIcon(notification['jenis']),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getNotificationIcon(notification['jenis']).color!,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTypeDisplayName(notification['jenis']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification['judul'] ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appTheme.black900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date
                  Text(
                    _formatDate(notification['tanggal_notifikasi'] ?? ''),
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.orange200,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message
                  Text(
                    'Pesan:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: appTheme.black900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification['pesan'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Status
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: appTheme.black900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: notification['status'] == 'unread'
                              ? appTheme.orange200.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification['status'] == 'unread' ? 'Belum Dibaca' : 'Sudah Dibaca',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: notification['status'] == 'unread'
                                ? appTheme.orange200
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action button - only if has reference ID
            if (notification['id_referensi'] != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToRelatedPage(context),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.orange200,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}