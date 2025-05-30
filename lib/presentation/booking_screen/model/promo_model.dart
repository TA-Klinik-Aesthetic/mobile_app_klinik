// lib/presentation/booking_screen/model/promo_model.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../api/api_constant.dart';

class Promo {
  final int? idPromo;
  final String? namaPromo;
  final String? deskripsiPromo;
  final dynamic potonganHarga;
  final String? tanggalMulai;
  final String? tanggalBerakhir;
  final String? gambarPromo;
  final String? statusPromo;
  final String? createdAt;
  final String? updatedAt;

  Promo({
    this.idPromo,
    this.namaPromo,
    this.deskripsiPromo,
    this.potonganHarga,
    this.tanggalMulai,
    this.tanggalBerakhir,
    this.gambarPromo,
    this.statusPromo,
    this.createdAt,
    this.updatedAt,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      idPromo: json['id_promo'],
      namaPromo: json['nama_promo'],
      deskripsiPromo: json['deskripsi_promo'],
      potonganHarga: json['potongan_harga'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalBerakhir: json['tanggal_berakhir'],
      gambarPromo: json['gambar_promo'],
      statusPromo: json['status_promo'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  double calculateDiscount(double amount) {
    // Direct nominal discount from potonganHarga
    if (potonganHarga == null) return 0.0;

    double discountValue;
    if (potonganHarga is String) {
      discountValue = double.tryParse(potonganHarga) ?? 0.0;
    } else if (potonganHarga is int) {
      discountValue = potonganHarga.toDouble();
    } else if (potonganHarga is double) {
      discountValue = potonganHarga;
    } else {
      discountValue = 0.0;
    }

    return discountValue;
  }

  String formatPromoValue() {
    return 'Rp ${_formatPrice(potonganHarga)}';
  }

  String formatDate(String? dateString) {
    if (dateString == null) return "-";
    try {
      final date = DateTime.parse(dateString);
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
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

class PromoService {
  Future<List<Promo>> fetchPromos() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.promo));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];

          // Filter only active promos
          final activePromos = data.where((promo) =>
          promo['status_promo'] == 'Aktif').toList();

          return activePromos.map((promo) => Promo.fromJson(promo)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching promos: $e');
      return [];
    }
  }
}