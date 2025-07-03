// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/user_screen/history_complaint_screen.dart';
import 'package:toastification/toastification.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import 'package:mobile_app_klinik/presentation/user_screen/edit_user_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String userName = '';
  String userEmail = '';
  String phoneNumber = '';
  String userProfilePhoto = ''; // Added missing variable
  bool isLoading = true;
  bool isLoggedIn = true; // Track login status

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
      return;
    }

    setState(() {
      userName = prefs.getString('nama_user') ?? 'User';
      userEmail = prefs.getString('email') ?? 'user@example.com';
      phoneNumber = prefs.getString('no_telp') ?? '62xxxxxxx';
      userProfilePhoto = prefs.getString('foto_profil') ?? ''; // Load profile photo URL
      isLoading = false;
      isLoggedIn = true;
    });
  }

  // Logout Function
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      // Hapus semua data user dari SharedPreferences
      await prefs.clear();

      setState(() {
        isLoggedIn = false;
        userName = '';
        userEmail = '';
        phoneNumber = '';
        userProfilePhoto = '';
      });

      toastification.show(
        context: context,
        title: const Text('Success!'),
        description: const Text("Berhasil keluar dari akun"),
        autoCloseDuration: const Duration(seconds: 3),
        backgroundColor: appTheme.lightGreen,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Kembali ke HomeScreen dan hapus semua rute sebelumnya
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
            (route) => false,
      );

    } catch (e) {
      print('Logout error: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      setState(() {
        isLoggedIn = false;
        userName = '';
        userEmail = '';
        phoneNumber = '';
        userProfilePhoto = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan, tetapi Anda berhasil keluar'))
      );

      // Kembali ke HomeScreen dan hapus semua rute sebelumnya
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeScreen,
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Section - Show only if logged in
              if (isLoggedIn) ...[
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((_) => loadUserData());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: appTheme.whiteA700,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: appTheme.black900, width: 1),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Profile Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appTheme.lightGrey,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: ClipOval(
                            child: userProfilePhoto.isNotEmpty
                                ? Image.network(
                              userProfilePhoto,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 40,
                                  color: appTheme.black900.withOpacity(0.6),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                                : Icon(
                              Icons.person,
                              size: 40,
                              color: appTheme.black900.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: appTheme.black900,
                                ),
                              ),
                              Text(
                                phoneNumber,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: appTheme.black900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: appTheme.black900,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Menu Options - Show only if logged in
                _buildMenuOption(
                  title: 'Favorit',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppRoutes.routes[AppRoutes.favoriteUserScreen]!(context),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  title: 'Riwayat Pembelian',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppRoutes.routes[AppRoutes.historyPurchaseScreen]!(context),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  title: 'Riwayat Kunjungan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppRoutes.routes[AppRoutes.historyConsultationScreen]!(context),
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  title: 'Pengajuan Komplain',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryComplaintScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),
              ] else ...[
                // Message when not logged in
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: appTheme.whiteA700,
                    border: Border.all(color: appTheme.black900, width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 70,
                        color: appTheme.orange200,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Anda belum login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan login untuk mengakses profil dan fitur lainnya',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],

              // Dynamic Login/Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoggedIn
                      ? _logout
                      : () {
                    try {
                      // Tambahkan log untuk debugging
                      print('Mencoba navigasi ke halaman login');

                      // Gunakan Navigator.pushNamed biasa untuk troubleshooting
                      Navigator.pushNamed(context, AppRoutes.loginUserScreen)
                          .then((_) {
                        // Refresh data setelah kembali dari halaman login
                        loadUserData();
                        print('Kembali dari halaman login');
                      })
                          .catchError((error) {
                        print('Error navigasi: $error');
                        // Tampilkan pesan error
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal membuka halaman login: $error'))
                        );
                      });
                    } catch (e) {
                      print('Exception saat navigasi: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Terjadi kesalahan: $e'))
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoggedIn ? appTheme.darkCherry : appTheme.lightGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Text(
                    isLoggedIn ? 'KELUAR' : 'LOGIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: appTheme.whiteA700,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appTheme.black900, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}