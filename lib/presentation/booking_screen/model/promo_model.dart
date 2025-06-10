// lib/presentation/booking_screen/model/promo_model.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/api_constant.dart';

class Promo {
  final int? idPromo;
  final String? namaPromo;
  final String? jenisPromo;
  final String? deskripsiPromo;
  final String? tipePotongan;
  final String? potonganHarga;
  final String? pajak;
  final String? minimalBelanja;
  final String? tanggalMulai;
  final String? tanggalBerakhir;
  final String? gambarPromo;
  final String? statusPromo;

  Promo({
    this.idPromo,
    this.namaPromo,
    this.jenisPromo,
    this.deskripsiPromo,
    this.tipePotongan,
    this.potonganHarga,
    this.pajak,
    this.minimalBelanja,
    this.tanggalMulai,
    this.tanggalBerakhir,
    this.gambarPromo,
    this.statusPromo,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      idPromo: json['id_promo'],
      namaPromo: json['nama_promo'],
      jenisPromo: json['jenis_promo'],
      deskripsiPromo: json['deskripsi_promo'],
      tipePotongan: json['tipe_potongan'],
      potonganHarga: json['potongan_harga'],
      minimalBelanja: json['minimal_belanja'],
      tanggalMulai: json['tanggal_mulai'],
      tanggalBerakhir: json['tanggal_berakhir'],
      gambarPromo: json['gambar_promo'],
      statusPromo: json['status_promo'],
    );
  }

  String formatPromoValue() {
    if (tipePotongan == "Diskon") {
      return "$potonganHarga%";
    } else {
      // Default to Rupiah format
      double value = double.tryParse(potonganHarga ?? '0') ?? 0;
      return "Rp ${_formatPrice(value)}";
    }
  }

  double calculateDiscount(double totalPrice) {
    double minBelanja = double.tryParse(minimalBelanja ?? '0') ?? 0;

    // Check if total price meets minimum spending requirement
    if (totalPrice < minBelanja) return 0;

    if (tipePotongan == "Diskon") {
      // Calculate percentage discount
      double percentage = double.tryParse(potonganHarga ?? '0') ?? 0;
      return (totalPrice * percentage / 100);
    } else {
      // Direct Rupiah discount
      return double.tryParse(potonganHarga ?? '0') ?? 0;
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _formatPrice(double price) {
    final String priceString = price.toStringAsFixed(0);
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiConstants.promo),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((item) => Promo.fromJson(item)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load promos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching promos: $e');
    }
  }
}