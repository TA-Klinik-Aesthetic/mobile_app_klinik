import 'package:flutter/material.dart';

import '../../core/app_export.dart';

class DetailPromoScreen extends StatelessWidget {
  final Map<String, dynamic> promo;

  const DetailPromoScreen({
    super.key,
    required this.promo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Promo',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promo Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                promo['gambar_promo'],
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: appTheme.lightBadge100,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: appTheme.lightGrey,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: appTheme.lightBadge100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: appTheme.orange200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: appTheme.orange200,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: appTheme.black900, fontSize: 14),
                              children: [
                                const TextSpan(
                                  text: 'Periode Promo: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '${_formatDate(promo['tanggal_mulai'])} - ${_formatDate(promo['tanggal_berakhir'])}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Promo Name
                  Text(
                    promo['nama_promo'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Discount amount
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.lightGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    // Display discount or price reduction
                    child: Text(
                      promo['tipe_potongan'] == "Diskon"
                          ? "Diskon ${double.parse(promo['potongan_harga'].toString()).toStringAsFixed(0)}%"
                          : "Potongan Rp${_formatCurrency(promo['potongan_harga'])}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: appTheme.whiteA700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description Title
                  Text(
                    'Deskripsi Promo',
                    style: TextStyle(
                      color: appTheme.black900,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Promo Description
                  Text(
                    promo['deskripsi_promo'],
                    style: TextStyle(
                      fontSize: 16,
                      color: appTheme.black900.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Minimal Transaction indicator
                  Text(
                    'Minimal Transaksi: ${_formatPrice(promo['minimal_belanja'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    double priceDouble;
    if (price is int) {
      priceDouble = price.toDouble();
    } else if (price is String) {
      priceDouble = double.tryParse(price) ?? 0.0;
    } else if (price is double) {
      priceDouble = price;
    } else {
      return '0';
    }

    final String priceString = priceDouble.toStringAsFixed(0);
    final StringBuffer formattedPrice = StringBuffer();
    int count = 0;
    for (int i = priceString.length - 1; i >= 0; i--) {
      formattedPrice.write(priceString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        formattedPrice.write('.');
      }
    }
    return formattedPrice.toString().split('').reversed.join('');
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];

      final String day = date.day.toString();
      final String month = months[date.month - 1];
      final String year = date.year.toString();

      return "$day $month $year";
    } catch (e) {
      return "Unknown Date";
    }
  }

  String _formatCurrency(dynamic price) {
    try {
      double numericPrice = double.parse(price.toString());
      return numericPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.');
    } catch (e) {
      return price.toString();
    }
  }
}