import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransConfig {
  // Set to false for sandbox, true for production
  static bool get isProduction => false;
  
  static String get merchantId {
    try {
      return isProduction 
          ? dotenv.env['MIDTRANS_MERCHANT_ID_PRODUCTION'] ?? ''
          : dotenv.env['MIDTRANS_MERCHANT_ID'] ?? 'G050679237';
    } catch (e) {
      // Fallback if dotenv not loaded
      return isProduction ? '' : 'G050679237';
    }
  }
  
  static String get clientKey {
    try {
      return isProduction 
          ? dotenv.env['MIDTRANS_CLIENT_KEY_PRODUCTION'] ?? ''
          : dotenv.env['MIDTRANS_CLIENT_KEY'] ?? 'SB-Mid-client-qu6al6kLrIZkepp7';
    } catch (e) {
      // Fallback if dotenv not loaded
      return isProduction ? '' : 'SB-Mid-client-qu6al6kLrIZkepp7';
    }
  }
  
  static String get serverKey {
    try {
      return isProduction 
          ? dotenv.env['MIDTRANS_SERVER_KEY_PRODUCTION'] ?? ''
          : dotenv.env['MIDTRANS_SERVER_KEY'] ?? 'SB-Mid-server-09hC0lKm4AjstTnXdZK3dPwC';
    } catch (e) {
      // Fallback if dotenv not loaded
      return isProduction ? '' : 'SB-Mid-server-09hC0lKm4AjstTnXdZK3dPwC';
    }
  }
  
  static String get baseUrl {
    return isProduction 
        ? 'https://app.midtrans.com'
        : 'https://app.sandbox.midtrans.com';
  }
  
  static String get apiUrl {
    return isProduction 
        ? 'https://api.midtrans.com'
        : 'https://api.sandbox.midtrans.com';
  }
  
  static bool get isConfigured {
    return clientKey.isNotEmpty && serverKey.isNotEmpty && merchantId.isNotEmpty;
  }
}