import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_export.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static String _currentLanguage = 'en';

  static String get currentLanguage => _currentLanguage;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    
    // Update AppLocalization current language
    await AppLocalization.setLanguage(_currentLanguage);
  }

  static Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Update app localization
    await AppLocalization.setLanguage(languageCode);
  }

  static Locale getCurrentLocale() {
    return Locale(_currentLanguage);
  }

  static List<LanguageModel> getSupportedLanguages() {
    return [
      LanguageModel(
        code: 'en',
        name: 'English (America)',
        flag: '🇺🇸',
        countryCode: 'US',
      ),
      LanguageModel(
        code: 'id',
        name: 'Bahasa (Indonesia)',
        flag: '🇮🇩',
        countryCode: 'ID',
      ),
    ];
  }
}

class LanguageModel {
  final String code;
  final String name;
  final String flag;
  final String countryCode;

  LanguageModel({
    required this.code,
    required this.name,
    required this.flag,
    required this.countryCode,
  });
}