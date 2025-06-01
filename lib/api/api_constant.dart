class ApiConstants {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Ganti dengan URL server Anda jika sudah online.
  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";
  static const String logout = "$baseUrl/logout";
  static const String profile = "$baseUrl/users";
  static const String product = "$baseUrl/produk";
  static const String kategori = "$baseUrl/kategori";
  static const String promo = "$baseUrl/promos";
  static const String cart = "$baseUrl/keranjang";
  static const String cartUser = "$baseUrl/keranjang/user/{id_user}";
  static const String cartSum = "$baseUrl/keranjang/user/{id_user}/total";
  static const String jadwalDokter = "$baseUrl/jadwal-dokter"; 
  static const String bookingKonsultasi = "$baseUrl/konsultasi";
  static const String detailBookingKonsultasi = "$baseUrl/detail-konsultasi";
  static const String feedbackKonsultasi = "$baseUrl/feedbacks";  
  static const String bookingTreatment = "$baseUrl/bookingTreatments";
  static const String detailBookingTreatment = "$baseUrl/detailBookingTreatments";
  static const String dokter = "$baseUrl/dokters";
  static const String jenisTreatment = "$baseUrl/jenisTreatments";
  static const String beautician = "$baseUrl/beauticians";
  static const String treatment = "$baseUrl/treatments";
}
