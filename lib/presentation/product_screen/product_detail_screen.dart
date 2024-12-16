import 'package:flutter/material.dart';

import '../../theme/theme_helper.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Padding(
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
                    image: NetworkImage(product['gambar_produk']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product['nama_produk'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
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
                    product['kategori']['nama_kategori'],
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
                      color: appTheme.lightGrey, // Warna border
                      width: 1.0, 
                    ),        
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${product['status_produk']} ${product['stok_produk']}",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Rp ${product['harga_produk']}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: appTheme.orange200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Deskripsi Produk",
              style: TextStyle(
                      color: appTheme.black900,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              product['deskripsi_produk'] ?? 'No description available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 36),
            Text(
              "Terakhir diupdate: ${product['updated_at']}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
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
        'Product Details',
        style: TextStyle(
          color: appTheme.orange200,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: appTheme.whiteA700,
      elevation: 0.0,
      centerTitle: true,
    );
  }
}
