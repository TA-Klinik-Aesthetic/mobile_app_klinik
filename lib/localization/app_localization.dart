import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_export.dart';
import 'en_us/en_us_translations.dart';
import 'id/id_translation.dart';

extension LocalizationExtension on String {
  String get tr {
    try {
      return AppLocalization.getTranslation(this);
    } catch (e) {
      return this; // Fallback to original string
    }
  }
}

class AppLocalization {
  AppLocalization(this.locale);

  Locale locale;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enUs,
    'id': idID,
  };

  static String _currentLanguage = 'en';

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static String getTranslation(String key) {
    final translation = _localizedValues[_currentLanguage]?[key] ?? 
                       _localizedValues['en']?[key] ?? 
                       key;
    
    print('🌐 Translation for "$key" in $_currentLanguage: "$translation"');
    return translation;
  }

  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? 'en';
    print('📱 Loaded saved language: $_currentLanguage');
  }

  static Future<void> setLanguage(String languageCode) async {
    print('🔄 Setting language to: $languageCode (was: $_currentLanguage)');
    _currentLanguage = languageCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    
    print('✅ Language successfully set to: $_currentLanguage');
  }

  static String getCurrentLanguage() {
    return _currentLanguage;
  }

  static Locale getCurrentLocale() {
    return Locale(_currentLanguage);
  }

  String getString(String text) =>
      _localizedValues[locale.languageCode]?[text] ?? 
      _localizedValues['en']?[text] ?? 
      text;
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) {
    return SynchronousFuture<AppLocalization>(AppLocalization(locale));
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}