import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:mobile_app_klinik/core/models/promo_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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