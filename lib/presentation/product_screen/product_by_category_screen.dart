import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../theme/theme_helper.dart';
import '../../api/api_constant.dart';
import 'models/product_card.dart';
import 'product_detail_screen.dart';

class ProductByCategoryScreen extends StatefulWidget {
  final dynamic categoryId;
  final String categoryName;

  const ProductByCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ProductByCategoryScreen> createState() => _ProductByCategoryScreenState();
}

class _ProductByCategoryScreenState extends State<ProductByCategoryScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductsByCategory();
  }

  Future<void> fetchProductsByCategory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.product}/kategori/${widget.categoryId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(data['data'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products by category: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Kategori Produk',
              style: TextStyle(
                color: appTheme.orange200,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2, // Medium character spacing
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.categoryName,
              style: TextStyle(
                color: appTheme.black900,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(
        child: Text(
          'Tidak ada produk dalam kategori ini',
          style: TextStyle(
            fontSize: 16,
            color: appTheme.black900,
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product: products[index],
                    ),
                  ),
                ).then((_) {
                  fetchProductsByCategory();
                });
              },
            );
          },
        ),
      ),
    );
  }
}