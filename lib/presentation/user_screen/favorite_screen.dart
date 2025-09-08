import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/booking_screen/detail_booking_consultation_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool isLoading = true;
  List<dynamic> favoriteDoctors = [];
  List<dynamic> favoriteProducts = [];
  List<dynamic> favoriteTreatments = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      fetchFavoriteDoctors(),
      fetchFavoriteProducts(),
      fetchFavoriteTreatments(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchFavoriteDoctors() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.viewDoctorFavorite.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          favoriteDoctors = jsonData['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching favorite doctors: $e');
    }
  }

  Future<void> fetchFavoriteProducts() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.viewProductFavorite.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          favoriteProducts = jsonData['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching favorite products: $e');
    }
  }

  Future<void> fetchFavoriteTreatments() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.viewTreatmentFavorite.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          favoriteTreatments = jsonData['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching favorite treatments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorit Saya',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchFavorites,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Dokter Favorit'),
              const SizedBox(height: 8),
              _buildDoctorList(),
              const SizedBox(height: 16),

              _buildSectionHeader('Produk Favorit'),
              const SizedBox(height: 8),
              _buildProductList(),
              const SizedBox(height: 16),

              _buildSectionHeader('Treatment Favorit'),
              const SizedBox(height: 8),
              _buildTreatmentList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          title,
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    if (favoriteDoctors.isEmpty) {
      return _buildEmptyPlaceholder('Belum ada dokter favorit');
    }

    return SizedBox(
      height: 215,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: favoriteDoctors.length,
        itemBuilder: (context, index) {
          final doctor = favoriteDoctors[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailBookingKonsultasi(dokter: doctor),
                ),
              ).then((_) => fetchFavorites());
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.whiteA700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: doctor['foto_dokter'] != null
                        ? FadeInImage.assetNetwork(
                      placeholder: 'assets/images/loading_placeholder.png', // Replace with your placeholder image
                      image: doctor['foto_dokter'],
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      placeholderFit: BoxFit.cover,
                      placeholderErrorBuilder: (context, error, stackTrace) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                    )
                        : Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor['nama_dokter'] ?? 'Unknown Doctor',
                    style: TextStyle(
                      color: appTheme.black900,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    if (favoriteProducts.isEmpty) {
      return _buildEmptyPlaceholder('Belum ada produk favorit');
    }

    return SizedBox(
      height: 215,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = favoriteProducts[index];
          return InkWell(
            onTap: () {
              // Debug print to check product data structure
              print('Favorite product data: $product');

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              ).then((_) => fetchFavorites());
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.whiteA700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Enhanced product image with ApiConstants.getImageUrl()
                  _buildFavoriteProductImage(product),
                  const SizedBox(height: 8),
                  
                  // Product name
                  Text(
                    product['nama_produk'] ?? 'Unknown Product',
                    style: TextStyle(
                      color: appTheme.black900,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // ✅ Add product price if available
                  if (product['harga_produk'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatPrice(product['harga_produk'])}',
                      style: TextStyle(
                        color: appTheme.orange200,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Add enhanced product image method
  Widget _buildFavoriteProductImage(dynamic product) {
    final imageUrl = product['gambar_produk'] ?? '';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 125, // 150 - 16 padding
        height: 125,
        decoration: BoxDecoration(
          color: appTheme.lightBadge100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageUrl.isNotEmpty
            ? Image.network(
                ApiConstants.getImageUrl(imageUrl), // ✅ Use getImageUrl
                width: 125,
                height: 125,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  
                  return Container(
                    width: 125,
                    height: 125,
                    color: appTheme.lightBadge100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: appTheme.orange200,
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: appTheme.lightGrey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  final fullUrl = ApiConstants.getImageUrl(imageUrl);
                  final productName = product['nama_produk'] ?? 'Unknown';
                  
                  print('❌ Favorite product image error:');
                  print('   Product: $productName');
                  print('   Original path: $imageUrl');
                  print('   Full URL: $fullUrl');
                  print('   Error: $error');
                  
                  return _buildFavoriteProductPlaceholder();
                },
              )
            : _buildFavoriteProductPlaceholder(),
      ),
    );
  }

  // ✅ Add placeholder for favorite products
  Widget _buildFavoriteProductPlaceholder() {
    return Container(
      width: 125,
      height: 125,
      decoration: BoxDecoration(
        color: appTheme.lightBadge100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appTheme.lightGrey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: appTheme.lightGrey,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              color: appTheme.lightGrey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentList() {
    if (favoriteTreatments.isEmpty) {
      return _buildEmptyPlaceholder('Belum ada treatment favorit');
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: favoriteTreatments.length,
        itemBuilder: (context, index) {
          final treatment = favoriteTreatments[index];
          return InkWell(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => DetailBookingTreatment(treatment: treatment),
              //   ),
              // ).then((_) => fetchFavorites());
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appTheme.whiteA700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: treatment['gambar_treatment'] != null
                        ? Image.network(
                      "https://klinikneshnavya.com/${treatment['gambar_treatment']}",
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    )
                        : Container(
                      width: 140,
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    treatment['nama_treatment'] ?? 'Unknown Treatment',
                    style: TextStyle(
                      color: appTheme.black900,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      height: 140,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
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
}