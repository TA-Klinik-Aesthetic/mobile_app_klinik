import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/product_screen/purchase_product_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../api/api_constant.dart';
import '../booking_screen/model/promo_model.dart';

class PurchaseCartScreen extends StatefulWidget {
  const PurchaseCartScreen({super.key});

  @override
  State<PurchaseCartScreen> createState() => _PurchaseCartScreenState();
}

class _PurchaseCartScreenState extends State<PurchaseCartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0;

  // Promo related variables
  List<Promo> _promos = [];
  Promo? _selectedPromo;
  bool _isLoadingPromos = false;
  final PromoService _promoService = PromoService();

  // Controllers for quantity inputs
  Map<int, TextEditingController> quantityControllers = {};
  Map<int, int> originalQuantities = {};

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    _fetchPromos();
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (var controller in quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPromos() async {
    setState(() {
      _isLoadingPromos = true;
    });

    try {
      final promos = await _promoService.fetchPromos();
      setState(() {
        // Filter promos to only include "Produk" type
        _promos = promos.where((promo) => promo.jenisPromo == "Produk").toList();
        _isLoadingPromos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPromos = false;
      });
      print('Error fetching promos: $e');
    }
  }

  Widget _buildPromoList() {
    return ListView.builder(
      itemCount: _promos.length,
      itemBuilder: (context, index) {
        final promo = _promos[index];
        bool isSelected = _selectedPromo != null && _selectedPromo!.idPromo == promo.idPromo;

        // Check if cart total meets minimum spending requirement
        double minBelanja = double.tryParse(promo.minimalBelanja ?? '0') ?? 0;
        bool isEligible = totalPrice >= minBelanja;
        double amountNeeded = minBelanja - totalPrice;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? appTheme.orange200 : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: isEligible ? () {
              setState(() {
                _selectedPromo = promo;
              });
              Navigator.pop(context);
            } : null,
            child: Opacity(
              opacity: isEligible ? 1.0 : 0.7,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          promo.namaPromo ?? 'Promo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEligible ? appTheme.black900 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          promo.formatPromoValue(),
                          style: TextStyle(
                            fontSize: 16,
                            color: isEligible ? appTheme.orange200 : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      promo.deskripsiPromo ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEligible ? Colors.grey.shade600 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Minimal belanja: Rp ${_formatPrice(minBelanja)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isEligible ? appTheme.orange200 : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Periode: ${promo.formatDate(promo.tanggalMulai)} - ${promo.formatDate(promo.tanggalBerakhir)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: appTheme.lightGrey,
                          ),
                        ),
                      ],
                    ),

                    // Show missing amount if not eligible
                    if (!isEligible) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "Belanja Rp ${_formatPrice(amountNeeded)} lagi untuk menggunakan promo ini",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchCartItems() async {
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

      final response = await http.get(
        Uri.parse(ApiConstants.cartUser.replaceFirst('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          cartItems = data;

          // Initialize quantities
          for (var item in cartItems) {
            final id = item['id_keranjang_pembelian'];
            final qty = int.tryParse(item['jumlah'].toString()) ?? 1;
            originalQuantities[id] = qty;
            quantityControllers[id] = TextEditingController(text: qty.toString());
          }

          // Calculate total
          calculateTotal();
          isLoading = false;
        });
      } else {
        _showMessage('Gagal memuat data keranjang');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isQuantityChanged(int cartId, int currentQty) {
    return originalQuantities[cartId] != currentQty;
  }

  void _updateItemQuantity(int cartId, int newQuantity, int maxStock) {
    if (newQuantity < 1 || newQuantity > maxStock) return;

    setState(() {
      for (var i = 0; i < cartItems.length; i++) {
        if (cartItems[i]['id_keranjang_pembelian'] == cartId) {
          cartItems[i]['jumlah'] = newQuantity;
          quantityControllers[cartId]?.text = newQuantity.toString();
          calculateTotal();
          break;
        }
      }
    });
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

  double _calculateTax() {
    double discount = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
    double afterDiscount = totalPrice - discount;
    double besaranPajak = (afterDiscount * 0.10).clamp(0, double.infinity);
    return besaranPajak;
  }

  double _calculateFinalPrice() {
    double discount = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
    double afterDiscount = totalPrice - discount;
    double tax = _calculateTax();
    return max(afterDiscount + tax, 0.0);
  }


  Future<void> updateQuantity(int cartId, int newQuantity, int maxStock) async {
    if (newQuantity < 1 || newQuantity > maxStock) {
      _showMessage(newQuantity < 1
          ? 'Jumlah minimal adalah 1'
          : 'Jumlah melebihi stok yang tersedia');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.cart}/$cartId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jumlah': newQuantity,
        }),
      );

      if (response.statusCode == 200) {
        // Update local data and original quantity
        setState(() {
          for (var i = 0; i < cartItems.length; i++) {
            if (cartItems[i]['id_keranjang_pembelian'] == cartId) {
              cartItems[i]['jumlah'] = newQuantity;
              originalQuantities[cartId] = newQuantity; // Update original quantity
              break;
            }
          }
          calculateTotal();
          isLoading = false;
        });
        _showMessage('Jumlah produk berhasil diubah');
      } else {
        _showMessage('Gagal mengubah jumlah produk');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> removeItem(int cartId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConstants.cart}/$cartId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Remove local data and controller
        setState(() {
          cartItems.removeWhere((item) => item['id_keranjang_pembelian'] == cartId);
          quantityControllers[cartId]?.dispose();
          quantityControllers.remove(cartId);
          calculateTotal();
          isLoading = false;
        });
        _showMessage('Produk berhasil dihapus dari keranjang');
      } else {
        _showMessage('Gagal menghapus produk dari keranjang');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, int cartId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Yakin ingin menghapus produk ini dari keranjang?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                removeItem(cartId);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
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

  void _showPromoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPromoBottomSheet(),
    );
  }

  Widget _buildPromoBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Promo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedPromo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: appTheme.lightGreen, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedPromo!.namaPromo} berhasil diterapkan',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoadingPromos
                ? const Center(child: CircularProgressIndicator())
                : _promos.isEmpty
                ? _buildEmptyPromoState()
                : _buildPromoList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromoState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada promo tersedia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoButton() {
    return InkWell(
      onTap: _showPromoBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: appTheme.lightGrey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.discount_outlined, color: appTheme.orange200),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedPromo != null
                    ? 'Promo ${_selectedPromo!.namaPromo} diterapkan'
                    : 'Gunakan Promo',
                style: TextStyle(
                  color: _selectedPromo != null ? appTheme.black900 : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCart(String token, int userId) async {
    try {
      // Store cart IDs before clearing them
      List<int> cartIds = cartItems.map<int>((item) => item['id_keranjang_pembelian'] as int).toList();

      // Delete each item from the cart
      for (int cartId in cartIds) {
        await http.delete(
          Uri.parse('${ApiConstants.cart}/$cartId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Clear local cart data
      setState(() {
        cartItems.clear();
        calculateTotal();
      });
    } catch (e) {
      print('Error clearing cart: $e');
      // Continue with checkout even if cart clearing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Keranjang Belanja',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
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
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Keranjang belanja Anda kosong',
              style: TextStyle(
                fontSize: 18,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mulai Belanja',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Cart items
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchCartItems,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final product = item['produk'];
                  final cartId = item['id_keranjang_pembelian'];
                  final maxStock = int.tryParse(product['stok_produk'].toString()) ?? 0;
                  final price = double.tryParse(product['harga_produk'].toString()) ?? 0;
                  final quantity = int.tryParse(item['jumlah'].toString()) ?? 0;

                  // Ensure controller exists
                  if (!quantityControllers.containsKey(cartId)) {
                    quantityControllers[cartId] = TextEditingController(text: quantity.toString());
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: appTheme.whiteA700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['gambar_produk'] ?? '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product name and delete button in a row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Kolom teks nama produk dan harga
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Nama produk
                                          Text(
                                            product['nama_produk'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // Harga produk
                                          Text(
                                            'Rp ${_formatPrice(price)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: appTheme.orange200,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Updated delete button to match detail booking treatment style
                                    InkWell(
                                      onTap: () => _showDeleteConfirmation(context, cartId),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: appTheme.darkCherry.withAlpha((0.6 * 255).toInt()),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close, size: 16, color: appTheme.whiteA700),
                                      ),
                                    ),
                                  ],
                                ),


                                const SizedBox(height: 8),

                                // Quantity and subtotal in a row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Quantity controls
                                    // Quantity controls
                                    Row(
                                      children: [
                                        // Item counter
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
                                                  color: quantity > 1 ? appTheme.orange200 : appTheme.lightGrey,
                                                ),
                                                onPressed: () {
                                                  if (quantity > 1) {
                                                    _updateItemQuantity(cartId, quantity - 1, maxStock);
                                                  }
                                                },
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(),
                                                iconSize: 20,
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: Text(
                                                  quantity.toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
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
                                                onPressed: () {
                                                  if (quantity < maxStock) {
                                                    _updateItemQuantity(cartId, quantity + 1, maxStock);
                                                  }
                                                },
                                                padding: const EdgeInsets.all(4),
                                                constraints: const BoxConstraints(),
                                                iconSize: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Only show save button when quantity changed
                                        if (_isQuantityChanged(cartId, quantity))
                                          ElevatedButton(
                                            onPressed: () {
                                              updateQuantity(cartId, quantity, maxStock);
                                              // After successful update, update original quantity
                                              if (originalQuantities.containsKey(cartId)) {
                                                setState(() {
                                                  originalQuantities[cartId] = quantity;
                                                });
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: appTheme.lightGreen,
                                              minimumSize: const Size(36, 36),
                                              padding: const EdgeInsets.all(0),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: appTheme.whiteA700,
                                              size: 24,
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Subtotal aligned with quantity input
                                    Text(
                                      'Rp ${_formatPrice(price * quantity)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: appTheme.orange200,
                                      ),
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
          ),

          // Promo and Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Promo button
                _buildPromoButton(),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                    Text(
                      'Rp ${_formatPrice(totalPrice)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                if (_selectedPromo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Diskon',
                            style: TextStyle(
                              fontSize: 16,
                              color: appTheme.black900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: appTheme.orange200.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedPromo!.namaPromo ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: appTheme.orange200,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '- Rp ${_formatPrice(_selectedPromo!.calculateDiscount(totalPrice))}',
                        style: TextStyle(
                          fontSize: 16,
                          color: appTheme.lightGreen,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // Always show tax row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pajak (10%)', style: TextStyle(fontSize: 14,color: appTheme.black900)),
                    Text(
                      '+ Rp ${_formatPrice(_calculateTax())}',
                      style: TextStyle(fontSize: 16, color: appTheme.darkCherry),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appTheme.black900,
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(_calculateFinalPrice())}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appTheme.orange200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Checkout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartItems.isNotEmpty ? () async {
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

                        // Format products array from cart items
                        List<Map<String, dynamic>> products = cartItems.map((item) {
                          return {
                            "id_produk": item['produk']['id_produk'],
                            "jumlah_produk": int.parse(item['jumlah'].toString())
                          };
                        }).toList();

                        double potonganHarga = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
                        double besaranPajak = _calculateTax();

                        // Prepare request body
                        Map<String, dynamic> requestBody = {
                          'id_user': userId,
                          'produk': products,
                          'potongan_harga': potonganHarga.toStringAsFixed(2),
                          'besaran_pajak': besaranPajak.toStringAsFixed(2),
                        };

                        // Add promo if selected
                        if (_selectedPromo != null) {
                          requestBody['id_promo'] = _selectedPromo!.idPromo;
                        }

                        final response = await http.post(
                          Uri.parse(ApiConstants.penjualanProduk),
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(requestBody),
                        );

                        if (response.statusCode == 200 || response.statusCode == 201) {
                          final responseData = jsonDecode(response.body);

                          if (responseData['success'] == true) {
                            int purchaseId = responseData['data']['id_penjualan_produk'];

                            // Clear cart after successful checkout
                            await _clearCart(token, userId);

                            // Navigate to purchase product screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PurchaseProductScreen(
                                  purchaseId: purchaseId,
                                ),
                              ),
                            );
                          } else {
                            setState(() {
                              isLoading = false;
                            });
                            _showMessage('Gagal melakukan checkout: ${responseData['message']}');
                          }
                        } else {
                          setState(() {
                            isLoading = false;
                          });
                          _showMessage('Gagal melakukan checkout. Silakan coba lagi.');
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });
                        _showMessage('Error: $e');
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.orange200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ) : Text(
                      'CHECKOUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.whiteA700,
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