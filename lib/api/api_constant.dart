class ApiConstants {
  static const String baseUrl = "https://klinikneshnavya.com/api";
  static const String imageBaseUrl = "https://klinikneshnavya.com/";
  //static const String baseUrl = "http://10.0.2.2:8000/api";

  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";
  static const String emailForgotPassword = "$baseUrl/password/email";
  static const String resetPassword = "$baseUrl/password/reset";
  static const String updateUserPassword = "$baseUrl/user/{id_user}/password";
  static const String logout = "$baseUrl/logout";
  static const String profile = "$baseUrl/profile";
  static const String product = "$baseUrl/produk";
  static const String kategori = "$baseUrl/kategori";
  static const String promo = "$baseUrl/promo";
  static const String cart = "$baseUrl/keranjang";
  static const String cartUser = "$baseUrl/keranjang/user/{id_user}";
  static const String cartSum = "$baseUrl/keranjang/user/{id_user}/total";
  static const String penjualanProduk = "$baseUrl/penjualan-produk";
  static const String penjualanProdukUser = "$baseUrl/penjualan-produk/user/{id_user}";
  static const String pembayaranProduk = "$baseUrl/pembayaran-produk";
  static const String pembayaranMidtransProduk = "$baseUrl/midtrans/product";
  static const String pembayaranMidtransTreatment = "$baseUrl/midtrans/treatment";
  static const String refreshPembayaranMidtrans = "$baseUrl/midtrans/check/{id_pembayaran}";
  static const String jadwalDokter = "$baseUrl/jadwal-dokter"; 
  static const String bookingKonsultasi = "$baseUrl/konsultasi";
  static const String detailBookingKonsultasi = "$baseUrl/detail-konsultasi";
  static const String feedbackKonsultasi = "$baseUrl/feedbackKonsultasi";  
  static const String feedbackTreatment = "$baseUrl/feedbackTreatment";  
  static const String bookingTreatment = "$baseUrl/bookingTreatment";
  static const String detailBookingTreatment = "$baseUrl/bookingTreatment";
  static const String jadwalTreatment = '$baseUrl/jadwal-treatment';
  static const String dokter = "$baseUrl/dokter";
  static const String jenisTreatment = "$baseUrl/jenisTreatment";
  static const String beautician = "$baseUrl/beautician";
  static const String treatment = "$baseUrl/treatment";
  static const String addDoctorFavorite = "$baseUrl/doctors/toggle-favorite";
  static const String addProductFavorite = "$baseUrl/products/toggle-favorite";
  static const String addTreatmentFavorite = "$baseUrl/treatments/toggle-favorite";
  static const String viewDoctorFavorite = "$baseUrl/favorites/user/{id_user}/doctors";
  static const String viewProductFavorite = "$baseUrl/favorites/user/{id_user}/products";
  static const String viewTreatmentFavorite = "$baseUrl/favorites/user/{id_user}/treatments";
  static const String kompensasiUser = "$baseUrl/kompensasi-diberikan";
  static const String fcmRegister = '$baseUrl/fcm/register';
  static const String fcmUnregister = '$baseUrl/fcm/unregister';
  static const String notifications = '$baseUrl/notifications/';

  // ✅ Helper method to get full image URL
  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    
    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // Remove leading slash if present to avoid double slashes
    String cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    
    return '$imageBaseUrl$cleanPath';
  }
}
