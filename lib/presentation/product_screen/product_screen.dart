import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/product_screen/product_detail_screen.dart';

import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          return product['nama_produk'].toString().toLowerCase().contains(
              query);
        }).toList();
      }
    });
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse(ApiConstants.product));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        products = data['data'];
        filteredProducts =
            products; // Initialize filtered list with all products
      });
    } else {
      debugPrint('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                'Facial Product',
                style: TextStyle(
                  color: innerBoxIsScrolled ? appTheme.whiteA700 : appTheme
                      .black900,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(120), // Increased height
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 16, top: 24), // Added bottom padding
                  child: Container(
                    decoration: BoxDecoration(
                      color: appTheme.whiteA700,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: appTheme.black900, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari Produk...',
                        prefixIcon: Icon(
                            Icons.search, color: appTheme.lightGrey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
              backgroundColor: innerBoxIsScrolled
                  ? appTheme.lightGreenOld
                  : appTheme.whiteA700,
              elevation: 0.0,
              centerTitle: true,
              pinned: true,
              floating: true,
              expandedHeight: 120, // Added expandedHeight
            ),
          ];
        },
        body: SafeArea(
          // Rest of the body code remains the same
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Product Grid
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredProducts.isEmpty
                      ? Center(
                    child: Text(
                      "Produk tidak ditemukan",
                      style: TextStyle(
                        color: appTheme.black900,
                        fontSize: 16,
                      ),
                    ),
                  )
                      : GridView.builder(
                    itemCount: filteredProducts.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) =>
                        ProductCard(
                          product: filteredProducts[index],
                          onPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(
                                        product: filteredProducts[index]),
                              ),
                            );
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onPress,
  });

  final Map<String, dynamic> product;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.lightBadge100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appTheme.lightGrey, width: 1.0),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.02,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF979797).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['gambar_produk'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['nama_produk'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: appTheme.black900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "Rp ${product['harga_produk']}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: appTheme.orange200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}