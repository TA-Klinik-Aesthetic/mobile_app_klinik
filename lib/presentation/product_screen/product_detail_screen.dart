import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../theme/theme_helper.dart';
import '../../api/api_constant.dart';
import 'models/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  final Map<String, dynamic> product;

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 0;
  bool isLoading = false;
  bool isFavorite = false;
  List<Map<String, dynamic>> recommendedProducts = [];

  @override
  void initState() {
    super.initState();
    checkFavoriteStatus();
    fetchRecommendedProducts();
  }

  // Fetch recommended products
  Future<void> fetchRecommendedProducts() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.product));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> allProducts = List<Map<String, dynamic>>.from(data['data'] ?? []);

        // Filter out the current product
        allProducts.removeWhere((product) =>
        product['id_produk'].toString() == widget.product['id_produk'].toString()
        );

        // Randomly select up to 5 products
        if (allProducts.length > 5) {
          allProducts.shuffle();
          allProducts = allProducts.sublist(0, 5);
        }

        setState(() {
          recommendedProducts = allProducts;
        });
      }
    } catch (e) {
      print('Error fetching recommended products: $e');
    }
  }

  // Check if product is already favorited
  Future<void> checkFavoriteStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) return;

      // Fetch favorite products
      final response = await http.get(
        Uri.parse(ApiConstants.viewProductFavorite.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> favoriteProducts = jsonData['data'] ?? [];

        // Check if current product is in favorites
        setState(() {
          isFavorite = favoriteProducts.any(
                  (product) => product['id_produk'].toString() == widget.product['id_produk'].toString()
          );
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        _showMessage('Silakan login untuk menambahkan favorit');
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.addProductFavorite),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_user': userId,
          'id_produk': widget.product['id_produk'],
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          isFavorite = jsonData['is_favorited'] ?? !isFavorite;
        });

        // Show success message
        _showMessage(jsonData['message'] ?? 'Status favorit diperbarui');
      } else {
        _showMessage('Gagal memperbarui status favorit');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      _showMessage('Error: $e');
    }
  }

  void updateQuantity(int newQuantity) {
    final stockValue = widget.product['stok_produk'];
    final maxStock = stockValue != null ? int.tryParse(stockValue.toString()) ?? 0 : 0;

    if (newQuantity >= 0 && newQuantity <= maxStock) {
      setState(() {
        quantity = newQuantity;
      });
    }
  }

  Future<void> addToCart() async {
    if (quantity <= 0) return;

    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final productId = int.parse(widget.product['id_produk'].toString());

      final response = await http.post(
        Uri.parse(ApiConstants.cart),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_user': userId,
          'id_produk': productId,
          'jumlah': quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Produk berhasil ditambahkan ke keranjang');
        setState(() {
          quantity = 0; // Reset counter after adding
        });
      } else {
        _showMessage('Gagal menambahkan produk ke keranjang');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: appTheme.orange200,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 24px from bottom
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockValue = widget.product['stok_produk'];
    final maxStock = stockValue != null ? int.tryParse(stockValue.toString()) ?? 0 : 0;

    return Scaffold(
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: NetworkImage(widget.product['gambar_produk']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.product['nama_produk'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              // Fix the category display in the Row widget
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.lightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      // Use the nested path with null safety
                      widget.product['kategori']['nama_kategori'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.whiteA700,
                      border: Border.all(
                        color: appTheme.lightGrey,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      // Add null safety here too
                      "${widget.product['status_produk'] ?? 'In Stock'} ${widget.product['stok_produk'] ?? '0'}",
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Rp ${_formatPrice(widget.product['harga_produk'])}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: appTheme.orange200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Deskripsi Produk",
                style: TextStyle(
                  color: appTheme.black900,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.product['deskripsi_produk'] ?? 'No description available.',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                "Terakhir diupdate: ${_formatDate(widget.product['updated_at'])}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              const SizedBox(height: 24),
              // Add recommended products section
              Text(
                "Rekomendasi Produk Lainnya",
                style: TextStyle(
                  color: appTheme.black900,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: recommendedProducts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendedProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 160,
                      child: ProductCard(
                        product: recommendedProducts[index],
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: recommendedProducts[index],
                              ),
                            ),
                          ).then((_) {
                            // Refresh recommendations when returning to this page
                            fetchRecommendedProducts();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Text
                Text(
                  "Tambah ke Keranjang",
                  style: TextStyle(
                    color: appTheme.black900,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Right side - Counter
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove,
                          color: quantity > 0 ? appTheme.orange200 : appTheme.lightGrey,
                        ),
                        onPressed: () => updateQuantity(quantity - 1),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: appTheme.black900,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          color: quantity < maxStock ? appTheme.orange200 : appTheme.lightGrey,
                        ),
                        onPressed: () => updateQuantity(quantity + 1),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Button - Only show when quantity > 0
            if (quantity > 0)
              ElevatedButton(
                onPressed: isLoading ? null : addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.orange200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'TAMBAH',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text(
        'Detail Produk',
        style: TextStyle(
          color: appTheme.orange200,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: appTheme.whiteA700,
      elevation: 0.0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? appTheme.darkCherry : appTheme.black900,
            size: 35, // Membesarkan ukuran ikon favorite
          ),
          onPressed: toggleFavorite,
        ),
      ],
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