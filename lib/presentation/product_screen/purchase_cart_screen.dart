import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class PurchaseCartScreen extends StatefulWidget {
  const PurchaseCartScreen({super.key});

  @override
  State<PurchaseCartScreen> createState() => _PurchaseCartScreenState();
}

class _PurchaseCartScreenState extends State<PurchaseCartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse(ApiConstants.cart),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            cartItems = data['data'] ?? [];
            calculateTotal();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showErrorMessage('Gagal memuat keranjang');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorMessage('Silakan login terlebih dahulu');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorMessage('Error: $e');
    }
  }

  void calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      double price = double.tryParse(item['produk']['harga_produk'].toString()) ?? 0;
      int quantity = int.tryParse(item['jumlah'].toString()) ?? 0;
      total += price * quantity;
    }
    setState(() {
      totalPrice = total;
    });
  }

  Future<void> updateQuantity(int itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token != null) {
        final response = await http.put(
          Uri.parse('${ApiConstants.cart}/$itemId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'jumlah': newQuantity,
          }),
        );

        if (response.statusCode == 200) {
          fetchCartItems(); // Refresh cart after update
        } else {
          _showErrorMessage('Gagal mengubah jumlah produk');
        }
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token != null) {
        final response = await http.delete(
          Uri.parse('${ApiConstants.cart}/$itemId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          fetchCartItems(); // Refresh cart after deletion
        } else {
          _showErrorMessage('Gagal menghapus produk dari keranjang');
        }
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Keranjang Anda kosong',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Belanja Sekarang'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final product = item['produk'];
                final quantity = int.tryParse(item['jumlah'].toString()) ?? 0;
                final price = double.tryParse(product['harga_produk'].toString()) ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['gambar_produk'] ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['nama_produk'] ?? 'Product Name',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp ${_formatPrice(price)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: appTheme.orange200,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quantity controls
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 16),
                                          onPressed: () {
                                            if (quantity > 1) {
                                              updateQuantity(item['id_keranjang'], quantity - 1);
                                            }
                                          },
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            quantity.toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 16),
                                          onPressed: () {
                                            updateQuantity(item['id_keranjang'], quantity + 1);
                                          },
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Hapus Produk'),
                                          content: const Text(
                                              'Apakah Anda yakin ingin menghapus produk ini dari keranjang?'
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                removeItem(item['id_keranjang']);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Checkout section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(totalPrice)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appTheme.orange200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartItems.isEmpty ? null : () {
                      // TODO: Implement checkout logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur checkout belum tersedia')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.orange200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}