import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import 'detail_promo_screen.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  List<Map<String, dynamic>> promoList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPromos();
  }

  Future<void> fetchPromos() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.promo));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];

          // Filter only active promos
          final activePromos = data.where((promo) =>
          promo['status_promo'] == 'Aktif').toList();

          setState(() {
            promoList = List<Map<String, dynamic>>.from(activePromos);
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load promos');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching promos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Promo',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : promoList.isEmpty
          ? _buildEmptyState()
          : _buildPromoList(),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: appTheme.orange200,
      onRefresh: fetchPromos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.discount_outlined,
                    size: 80,
                    color: appTheme.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada promo yang tersedia saat ini',
                    style: TextStyle(
                      fontSize: 16,
                      color: appTheme.black900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tarik ke bawah untuk memuat ulang',
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoList() {
    return RefreshIndicator(
      color: appTheme.orange200,
      onRefresh: fetchPromos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promoList.length,
        itemBuilder: (context, index) {
          final promo = promoList[index];
          return _buildPromoCard(promo);
        },
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: appTheme.black900, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPromoScreen(promo: promo),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promo Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  ApiConstants.getImageUrl(promo['gambar_promo'] ?? ''), // ✅ Use getImageUrl
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: appTheme.lightBadge100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: appTheme.orange200,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading promo image: ${promo['gambar_promo']} - $error');
                    return Container(
                      color: appTheme.lightBadge100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              color: appTheme.lightGrey,
                              size: 50,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gambar tidak tersedia',
                              style: TextStyle(
                                color: appTheme.lightGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Promo Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo Name
                  Text(
                    promo['nama_promo'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Promo Description
                  Text(
                    promo['deskripsi_promo'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.black900.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Period Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.orange200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Periode: ${_formatDate(promo['tanggal_mulai'])} - ${_formatDate(promo['tanggal_berakhir'])}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: appTheme.whiteA700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}