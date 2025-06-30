import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/product_screen/product_by_category_screen.dart';
import 'package:mobile_app_klinik/presentation/product_screen/product_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/product_card.dart';
import 'purchase_cart_screen.dart';

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
  List<dynamic> categories = [];
  TextEditingController searchController = TextEditingController();
  int cartItemCount = 0;
  bool isLoadingCategories = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCategories();
    fetchCartCount();
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
          return product['nama_produk'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _resetSearch() {
    searchController.clear();
    _filterProducts();
  }

  Future<void> fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    try {
      final response = await http.get(Uri.parse(ApiConstants.kategori));

      if (response.statusCode == 200) {
        // Parse as a direct list since the response is an array
        final List<dynamic> categoriesData = jsonDecode(response.body);
        setState(() {
          categories = categoriesData;
          isLoadingCategories = false;
        });
        debugPrint('Categories loaded: ${categories.length}');
      } else {
        debugPrint('Failed to load categories: ${response.statusCode}');
        setState(() {
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> fetchCartCount() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token != null && userId != null) {
        final response = await http.get(
          Uri.parse(ApiConstants.cartSum.replaceAll('{id_user}', userId.toString())),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            cartItemCount = int.tryParse(data['total_produk'].toString()) ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
    }
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(ApiConstants.product));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data['data'];
          filteredProducts = products;
          isLoading = false;
        });
      } else {
        debugPrint('Failed to load products');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
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
                  color: innerBoxIsScrolled ? appTheme.whiteA700 : appTheme.black900,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(140),
                child: Column(
                  children: [
                    // Search Box with Reset button
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16, top: 36),
                      child: Container(
                        decoration: BoxDecoration(
                          color: appTheme.whiteA700,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: appTheme.lightGrey, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari Produk...',
                            prefixIcon: Icon(Icons.search, color: appTheme.lightGrey),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _resetSearch,
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              backgroundColor: innerBoxIsScrolled
                  ? appTheme.lightGreen
                  : appTheme.whiteA700,
              elevation: 0.0,
              centerTitle: true,
              pinned: true,
              floating: true,
              expandedHeight: 100,
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchProducts();
              await fetchCartCount();
            },
            color: appTheme.orange200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories list
                  SizedBox(
                    height: 40,
                    child: isLoadingCategories
                        ? const Center(child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                        : categories.isEmpty
                        ? Center(
                      child: Text(
                        "Tidak ada kategori",
                        style: TextStyle(color: appTheme.black900),
                      ),
                    )
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductByCategoryScreen(
                                    categoryId: categories[index]['id_kategori'],
                                    categoryName: categories[index]['nama_kategori'],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appTheme.whiteA700,
                              side: BorderSide(color: appTheme.lightGrey, width: 1),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              categories[index]['nama_kategori'],
                              style: TextStyle(color: appTheme.black900),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: appTheme.lightGrey),
                  ),
                  const SizedBox(height: 16),

                  // Product Grid
                  Expanded(
                    child: isLoading
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
                      itemBuilder: (context, index) => ProductCard(
                        product: filteredProducts[index],
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: appTheme.orange200,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PurchaseCartScreen(),
            ),
          ).then((_) => fetchCartCount());
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            if (cartItemCount > 0)
              Positioned(
                right: -5,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: appTheme.darkCherry,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}