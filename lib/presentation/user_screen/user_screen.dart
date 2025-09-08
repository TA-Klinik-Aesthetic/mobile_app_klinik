// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/core/services/auth_service.dart';
import 'package:mobile_app_klinik/core/services/fcm_service.dart';
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
  String userGender = '';
  bool isLoading = true;
  bool isLoggedIn = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final isUserLoggedIn = await AuthService.isLoggedIn();
      
      if (isUserLoggedIn) {
        final userData = await AuthService.getUserData();
        final prefs = await SharedPreferences.getInstance();
        
        setState(() {
          userName = userData['userName'] ?? 'User';
          userEmail = userData['userEmail'] ?? 'user@example.com';
          phoneNumber = prefs.getString('no_telp') ?? '62xxxxxxx';
          userGender = prefs.getString('jenis_kelamin') ?? 'Laki-laki';
          isLoading = false;
          isLoggedIn = true;
        });

        // ✅ Debug print untuk melihat gender value
        print('DEBUG: User Gender = "$userGender"');
      } else {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
          userName = '';
          userEmail = '';
          phoneNumber = '';
          userGender = '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  // ✅ Remove unused _getAvatarWidget and related methods
  // Keep only the used _getSimpleAvatarWidget method

  // ✅ Main avatar widget: Use different background colors and icons based on gender
  Widget _getSimpleAvatarWidget({double size = 60}) {
    bool isFemale = userGender.toLowerCase().contains('perempuan') || 
                   userGender.toLowerCase().contains('wanita') ||
                   userGender.toLowerCase().contains('female');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isFemale 
              ? [Colors.pink.shade200, Colors.pink.shade400]
              : [Colors.blue.shade200, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Main icon
          Icon(
            Icons.person,
            size: size * 0.5,
            color: Colors.white,
          ),
          // Gender badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: isFemale ? Colors.pink.shade600 : Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                isFemale ? Icons.female : Icons.male,
                size: size * 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logout Function
  Future<void> _logout() async {
    try {
      final token = await AuthService.getToken();

      if (token != null) {
        await FCMService.unregisterToken();
        
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
      
      await AuthService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      setState(() {
        isLoggedIn = false;
        userName = '';
        userEmail = '';
        phoneNumber = '';
        userGender = '';
      });

      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Success!'),
          description: const Text("Berhasil keluar dari akun"),
          autoCloseDuration: const Duration(seconds: 3),
          backgroundColor: appTheme.lightGreen,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );

        NavigatorService.pushNamedAndRemoveUntil(AppRoutes.splashScreen);
      }
      
    } catch (e) {
      print('Logout error: $e');
      
      await AuthService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      setState(() {
        isLoggedIn = false;
        userName = '';
        userEmail = '';
        phoneNumber = '';
        userGender = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terjadi kesalahan, tetapi Anda berhasil keluar'))
        );

        NavigatorService.pushNamedAndRemoveUntil(AppRoutes.splashScreen);
      }
    }
  }

  // ✅ Fix unused variable warning
  void _goToLogin() async {
    try {
      // ✅ Remove unused variable and directly await the navigation
      await NavigatorService.pushNamed(AppRoutes.loginUserScreen);
      
      if (mounted) {
        loadUserData();
      }
    } catch (e) {
      print('Error navigating to login: $e');
      
      if (mounted) {
        // ✅ Remove unused variable here too
        await Navigator.of(context).pushNamed(AppRoutes.loginUserScreen);
        loadUserData();
      }
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
                    ).then((_) {
                      if (mounted) {
                        loadUserData();
                      }
                    });
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
                        // ✅ Use simple avatar with guaranteed gender indicator
                        _getSimpleAvatarWidget(size: 72),
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
                      // ✅ Use simple avatar for not logged in (default male)
                      _getSimpleAvatarWidget(size: 70),
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
                  onPressed: isLoggedIn ? _logout : _goToLogin,
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